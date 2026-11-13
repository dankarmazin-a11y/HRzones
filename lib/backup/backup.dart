import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show compute;

import '../data/database.dart';

/// Backup file format: gzip-compressed JSON with every table of the local
/// database, read and written with plain SQL so it does not depend on the
/// Dart classes (old backups keep working after schema changes).
///
/// Format 2 stores each table compactly (column names once, then rows as
/// lists) – a run has thousands of GPS points, and repeating every column
/// name per point made big backups slow and heavy. Format 1 (one map per
/// row) still restores.
///
/// ```json
/// {"app": "hrzones", "format": 2, "schemaVersion": 15, "createdAt": "…",
///  "tables": {"workouts": {"columns": ["id", "name", …], "rows": [["…", "…"], …]}, …}}
/// ```
const backupFormat = 2;
const backupExtension = 'hrzbackup';

/// Settings that belong to this phone, not to the backup.
const _localOnlySettings = {'lastBackupAt'};

/// Rows read from the database per query while building a backup.
const _pageSize = 5000;

/// Rows written per INSERT while restoring (well under SQLite's variable limit).
const _insertChunk = 100;

class BackupException implements Exception {
  BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// What a backup contains (shown before restoring).
class BackupInfo {
  const BackupInfo({required this.createdAt, required this.workouts, required this.templates});

  final DateTime? createdAt;
  final int workouts;
  final int templates;
}

/// Builds the backup file. Tables are read page by page and the file is
/// packed on a background isolate, so the app doesn't freeze on big backups.
Future<Uint8List> createBackup(AppDatabase db) async {
  final tables = <String, Map<String, Object?>>{};
  for (final t in db.allTables) {
    final name = t.actualTableName;
    final columns = [for (final c in t.$columns) c.name];
    final keyCol = name == 'settings' ? columns.indexOf('key') : -1;
    final rows = <List<Object?>>[];
    for (var offset = 0; ; offset += _pageSize) {
      final page = await db.customSelect('SELECT * FROM "$name" LIMIT $_pageSize OFFSET $offset', readsFrom: {t}).get();
      for (final r in page) {
        final row = [for (final c in columns) _encode(r.data[c])];
        if (keyCol >= 0 && _localOnlySettings.contains(row[keyCol])) continue;
        rows.add(row);
      }
      if (page.length < _pageSize) break;
    }
    tables[name] = {'columns': columns, 'rows': rows};
  }
  final backup = {
    'app': 'hrzones',
    'format': backupFormat,
    'schemaVersion': db.schemaVersion,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'tables': tables,
  };
  return compute(_pack, backup);
}

Uint8List _pack(Map<String, Object?> backup) =>
    Uint8List.fromList(const GZipEncoder().encodeBytes(utf8.encode(jsonEncode(backup))));

/// Rows of one table of a backup as maps, for both formats.
List<Map<String, dynamic>> _rowsOf(Object? table) {
  if (table is List) return table.cast<Map<String, dynamic>>(); // format 1
  if (table is Map && table['columns'] is List && table['rows'] is List) {
    final columns = (table['columns'] as List).cast<String>();
    return [
      for (final r in (table['rows'] as List).cast<List<dynamic>>())
        {for (var i = 0; i < columns.length && i < r.length; i++) columns[i]: r[i]},
    ];
  }
  return const [];
}

/// How many rows a table of a backup has (both formats).
int _countOf(Object? table) =>
    table is List ? table.length : (table is Map ? (table['rows'] as List?)?.length ?? 0 : 0);

/// Reads a backup file (gzip or plain JSON). Throws [BackupException] if it
/// is not a valid HR Zones backup.
Map<String, dynamic> readBackup(List<int> bytes) {
  try {
    final isGzip = bytes.length > 2 && bytes[0] == 0x1f && bytes[1] == 0x8b;
    final text = utf8.decode(isGzip ? const GZipDecoder().decodeBytes(bytes) : bytes);
    final map = jsonDecode(text) as Map<String, dynamic>;
    if (map['app'] != 'hrzones' || map['tables'] is! Map) throw BackupException('This is not an HR Zones backup.');
    if ((map['format'] as int? ?? 0) > backupFormat) {
      throw BackupException('This backup is from a newer version of HR Zones. Update the app first.');
    }
    return map;
  } on BackupException {
    rethrow;
  } catch (_) {
    throw BackupException('This file is not an HR Zones backup (or it is damaged).');
  }
}

BackupInfo backupInfo(Map<String, dynamic> backup) {
  final tables = backup['tables'] as Map<String, dynamic>;
  int count(String t) => _countOf(tables[t]);
  return BackupInfo(
    createdAt: DateTime.tryParse(backup['createdAt'] as String? ?? '')?.toLocal(),
    workouts: count('workouts'),
    templates: count('templates'),
  );
}

/// Replaces everything in the database with the backup's contents (one
/// transaction: on any error nothing changes). Columns the current app no
/// longer has are skipped; new columns get their defaults.
Future<void> restoreBackup(AppDatabase db, Map<String, dynamic> backup) async {
  final tables = backup['tables'] as Map<String, dynamic>;
  await db.transaction(() async {
    // Rows reference each other (sets → workouts…): check that only at the end.
    await db.customStatement('PRAGMA defer_foreign_keys = ON');
    for (final t in db.allTables) {
      final name = t.actualTableName;
      if (name == 'settings') {
        await db.customStatement(
          'DELETE FROM settings WHERE key NOT IN (${_localOnlySettings.map((_) => '?').join(',')})',
          _localOnlySettings.toList(),
        );
      } else {
        await db.customStatement('DELETE FROM "$name"');
      }
    }
    for (final t in db.allTables) {
      final name = t.actualTableName;
      final rows = _rowsOf(tables[name]);
      if (rows.isEmpty) continue;
      final known = {for (final c in t.$columns) c.name};
      // Rows with the same columns are written together, many per INSERT
      // (one INSERT per GPS point made restoring a big backup very slow).
      final groups = <String, List<Map<String, dynamic>>>{};
      for (final row in rows) {
        if (name == 'settings' && _localOnlySettings.contains(row['key'])) continue;
        final cols = row.keys.where(known.contains).toList();
        if (cols.isEmpty) continue;
        (groups[cols.join('\u0000')] ??= []).add(row);
      }
      for (final group in groups.values) {
        final cols = group.first.keys.where(known.contains).toList();
        final one = '(${List.filled(cols.length, '?').join(',')})';
        for (var i = 0; i < group.length; i += _insertChunk) {
          final chunk = group.sublist(i, i + _insertChunk > group.length ? group.length : i + _insertChunk);
          await db.customInsert(
            'INSERT OR REPLACE INTO "$name" (${cols.map((c) => '"$c"').join(',')}) '
            'VALUES ${List.filled(chunk.length, one).join(',')}',
            variables: [
              for (final row in chunk)
                for (final c in cols) Variable(_decode(row[c])),
            ],
          );
        }
      }
    }
  });
  // Raw SQL doesn't tell the open screens: refresh every list.
  db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
}

Object? _encode(Object? v) => v is Uint8List ? {r'$b64': base64Encode(v)} : v;

Object? _decode(Object? v) => v is Map && v[r'$b64'] is String ? base64Decode(v[r'$b64'] as String) : v;
