import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app_services.dart';
import '../backup/backup.dart';
import '../data/workout_repository.dart';

/// Backups older than this get a reminder on Home.
const backupReminderAfter = Duration(days: 7);

String _date(DateTime d) => '${d.day}.${d.month}.${d.year}';

/// "today", "yesterday", "9 days ago", "never".
String lastBackupText(DateTime? at, {DateTime? now}) {
  if (at == null) return 'never';
  final today = DateUtils.dateOnly(now ?? DateTime.now());
  final days = today.difference(DateUtils.dateOnly(at)).inDays;
  return days <= 0 ? 'today' : (days == 1 ? 'yesterday' : '$days days ago');
}

/// Creates a backup file and opens the share sheet (Save to Files → iCloud
/// Drive, Google Drive, mail…). The web preview downloads it.
Future<void> backUpNow(BuildContext context) async {
  final s = Services.of(context);
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  try {
    await s.session.flush();
    final bytes = await createBackup(s.db);
    final d = DateTime.now();
    final name =
        'HRzones-backup-${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}'
        '.$backupExtension';
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, name: name, mimeType: 'application/octet-stream')],
        fileNameOverrides: [name],
        subject: 'HR Zones backup',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
    // Closing the share sheet without saving doesn't count as a backup.
    if (result.status != ShareResultStatus.dismissed) {
      await s.setLastBackupAt(DateTime.now());
      messenger.showSnackBar(const SnackBar(content: Text('Backup saved')));
    }
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Backup failed: $e')));
  }
}

/// Picks a backup file and, after asking, replaces all data with it.
Future<void> restoreFromBackup(BuildContext context) async {
  final s = Services.of(context);
  final messenger = ScaffoldMessenger.of(context);
  if (s.session.active != null) {
    messenger.showSnackBar(const SnackBar(content: Text('Finish or discard the running workout first.')));
    return;
  }
  try {
    final file = await FilePicker.pickFile(dialogTitle: 'Choose an HR Zones backup');
    if (file == null) return;
    final backup = readBackup(await file.readAsBytes());
    final info = backupInfo(backup);
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          '${info.createdAt == null ? 'Backup' : 'Backup from ${_date(info.createdAt!)}'}: '
          '${info.workouts} workouts, ${info.templates} templates.\n\n'
          'Everything currently in the app is replaced by the backup.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            key: const Key('confirmRestore'),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await restoreBackup(s.db, backup);
    await s.reloadAfterRestore();
    messenger.showSnackBar(SnackBar(content: Text('Restored ${info.workouts} workouts')));
  } on BackupException catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Restore failed: $e')));
  }
}

/// Profile › Your data: back up and restore.
class BackupTiles extends StatelessWidget {
  const BackupTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return ValueListenableBuilder<DateTime?>(
      valueListenable: s.lastBackupAt,
      builder: (context, last, _) => Column(
        children: [
          ListTile(
            key: const Key('backUp'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Back up'),
            subtitle: Text(
              'Last backup: ${lastBackupText(last)}. Save the file to iCloud Drive or Google Drive to keep it safe.',
            ),
            onTap: () => backUpNow(context),
          ),
          ListTile(
            key: const Key('restore'),
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.settings_backup_restore),
            title: const Text('Restore from backup'),
            subtitle: const Text('Replaces everything in the app with a backup file'),
            onTap: () => restoreFromBackup(context),
          ),
        ],
      ),
    );
  }
}

/// Home: reminder when there are workouts and no backup for a week.
class BackupReminder extends StatelessWidget {
  const BackupReminder({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Services.of(context);
    return StreamBuilder<List<WorkoutListItem>>(
      stream: s.workouts.watchFinished(),
      builder: (context, snap) => ValueListenableBuilder<DateTime?>(
        valueListenable: s.lastBackupAt,
        builder: (context, last, _) {
          final hasWorkouts = (snap.data ?? const []).isNotEmpty;
          final due = last == null || DateTime.now().difference(last) > backupReminderAfter;
          if (!hasWorkouts || !due) return const SizedBox.shrink();
          return Card(
            key: const Key('backupReminder'),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: const Text('Back up your workouts'),
              subtitle: Text('Last backup: ${lastBackupText(last)}'),
              trailing: FilledButton.tonal(onPressed: () => backUpNow(context), child: const Text('Back up')),
            ),
          );
        },
      ),
    );
  }
}
