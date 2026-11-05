import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../../app_services.dart';
import '../../data/database.dart';
import '../../run/geo.dart';
import '../../workout/stats.dart';
import 'run_map.dart';
import 'run_summary_screen.dart' show runTitle;

/// A picture of the run – the route on the map and the big numbers – to
/// send or post. Shown first so you can see what will be shared.
class ShareRunScreen extends StatefulWidget {
  const ShareRunScreen({super.key, required this.run});

  final Run run;

  @override
  State<ShareRunScreen> createState() => _ShareRunScreenState();
}

class _ShareRunScreenState extends State<ShareRunScreen> {
  final _key = GlobalKey();
  RouteSegments? _segments;
  bool _sharing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_segments == null) {
      Services.of(context).runs.points(widget.run.id).then((p) {
        if (!mounted) return;
        setState(() => _segments = routeSegments(p.map((x) => (lat: x.lat, lon: x.lon, segment: x.segment))));
      });
    }
  }

  /// The card as a PNG (3× for a sharp picture).
  Future<Uint8List?> _png() async {
    final boundary = _key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _sharing = true);
    try {
      final bytes = await _png();
      if (bytes == null) return;
      final d = widget.run.startedAt;
      final name = 'Run-${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}.png';
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, name: name, mimeType: 'image/png')],
          fileNameOverrides: [name],
          text: '${formatKm(widget.run.distanceM)} km run',
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not share: $e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.run;
    final pace = paceSecPerKm(r.distanceM, r.durationS.toDouble());
    final segments = _segments;
    Widget stat(String value, String label) => Expanded(
      child: Column(
        children: [
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w900),
            ),
          ),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Share run')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RepaintBoundary(
            key: _key,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: ColoredBox(
                color: const Color(0xFF0D0D12),
                child: Column(
                  key: const Key('shareCard'),
                  children: [
                    if (segments != null && segments.isNotEmpty)
                      SizedBox(height: 260, child: RunMap(segments: segments, interactive: false))
                    else
                      const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        '${formatKm(r.distanceM)} km',
                        style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          stat(formatDuration(Duration(seconds: r.durationS)), 'Time'),
                          stat(formatPace(pace), 'Pace /km'),
                          if (r.avgHr != null) stat('${r.avgHr}', 'Avg HR'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(runTitle(r), style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          ),
                          const Icon(Icons.favorite, color: Color(0xFFE53935), size: 16),
                          const SizedBox(width: 4),
                          const Text(
                            'HR Zones',
                            style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            key: const Key('shareRunNow'),
            icon: _sharing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.ios_share),
            label: const Text('Share picture'),
            onPressed: _sharing ? null : _share,
          ),
        ],
      ),
    );
  }
}
