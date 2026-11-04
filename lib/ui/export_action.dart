import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../app_services.dart';
import '../export/export_data.dart';

/// Builds the spreadsheet and opens the share sheet (save to Files, mail…).
/// In the web preview it downloads the file.
Future<void> exportAndShare(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final box = context.findRenderObject() as RenderBox?;
  try {
    final bytes = await exportWorkbook(Services.of(context).db);
    final d = DateTime.now();
    final name = 'hrzones-${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}.xlsx';
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            name: name,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        fileNameOverrides: [name],
        subject: 'HR Zones export',
        // iPad needs an anchor for the share popover.
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
  }
}
