import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';

import '../data/database.dart';

/// Backup file format: gzip-compressed JSON with every table of the local
/// database, read and written with plain SQL so it does not depend on the
/// Dart classes (old backups keep working after schema changes).
///
/// ```json
/// {"app": "hrzones", "format": 1, "schemaVersion": 5, "createdAt": "…",
///  "tables": {"workouts": [{"id": "…", "name": "…", …}, …], …}}
/// ```
const backupFormat = 1;
const backupExtension = 'hrzbackup';

/// Settings that belong to this phone, not to the backup.
const _localOnlySettings = {'lastBackupAt'};

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

/// Builds the backup file.
Future<Uint8List> createBackup(AppDatabase db) async {
  final tables = <String, List<Map<String, Object?>>>{};
  for (final t in db.allTables) {
    final name = t.actualTableName;
    final rows = await db.customSelect('SELECT * FROM "$name"').get();
    tables[name] = [
      for (final r in rows)
        {
          for (final e in r.data.entries)
            if (!(name == 'settings' && _localOnlySettings.contains(r.data['key']))) e.key: _encode(e.value),
        },
    ]..removeWhere((row) => row.isEmpty);
  }
  final json = jsonEncode({
    'app': 'hrzones',
    'format': backupFormat,
    'schemaVersion': db.schemaVersion,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'tables': tables,
  });
  return const GZipEncoder().encodeBytes(utf8.encode(json));
}

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
  int count(String t) => (tables[t] as List?)?.length ?? 0;
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
      final rows = (tables[name] as List?)?.cast<Map<String, dynamic>>() ?? const [];
      if (rows.isEmpty) continue;
      final known = {for (final c in t.$columns) c.name};
      for (final row in rows) {
        if (name == 'settings' && _localOnlySettings.contains(row['key'])) continue;
        final cols = row.keys.where(known.contains).toList();
        if (cols.isEmpty) continue;
        await db.customInsert(
          'INSERT OR REPLACE INTO "$name" (${cols.map((c) => '"$c"').join(',')}) '
          'VALUES (${List.filled(cols.length, '?').join(',')})',
          variables: [for (final c in cols) Variable(_decode(row[c]))],
        );
      }
    }
  });
  // Raw SQL doesn't tell the open screens: refresh every list.
  db.notifyUpdates({for (final t in db.allTables) TableUpdate.onTable(t)});
}

Object? _encode(Object? v) => v is Uint8List ? {r'$b64': base64Encode(v)} : v;

Object? _decode(Object? v) => v is Map && v[r'$b64'] is String ? base64Decode(v[r'$b64'] as String) : v;
