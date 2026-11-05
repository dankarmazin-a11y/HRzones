import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Route drawn on the map: one line per segment (pauses / app restarts split
/// the route so no straight line is drawn across the gap).
typedef RouteSegments = List<List<LatLng>>;

/// Splits points into segments by their segment number.
RouteSegments routeSegments(Iterable<({double lat, double lon, int segment})> points) {
  final out = <List<LatLng>>[];
  int? current;
  for (final p in points) {
    if (p.segment != current || out.isEmpty) {
      out.add([]);
      current = p.segment;
    }
    out.last.add(LatLng(p.lat, p.lon));
  }
  return out..removeWhere((s) => s.isEmpty);
}

const routeColor = Color(0xFFFF5722);

/// OpenStreetMap with the route. Tiles are cached on the phone (flutter_map's
/// built-in cache), so a map seen once loads without data the next time.
class RunMap extends StatelessWidget {
  const RunMap({
    super.key,
    required this.segments,
    this.controller,
    this.current,
    this.interactive = true,
    this.fitRoute = true,
    this.onUserMove,
    this.onReady,
    this.colored,
  });

  /// Drawn instead of the plain route (e.g. coloured by heart-rate zone).
  final List<(List<LatLng>, Color)>? colored;

  final RouteSegments segments;
  final MapController? controller;

  /// Where the runner is now (live map); null on a finished run.
  final LatLng? current;
  final bool interactive;

  /// Start zoomed to the whole route (summary); otherwise centred on [current].
  final bool fitRoute;

  /// Called when the user drags/zooms the map (the live map stops following).
  final VoidCallback? onUserMove;

  /// The controller can be used from now on.
  final VoidCallback? onReady;

  /// Off in tests (no network).
  static bool loadTiles = true;

  /// Where the map opens when there is no route yet.
  static const fallbackCenter = LatLng(32.0853, 34.7818);

  List<LatLng> get _all => [for (final s in segments) ...s];

  @override
  Widget build(BuildContext context) {
    final all = _all;
    final start = all.isEmpty ? null : all.first;
    final end = all.isEmpty || current != null ? null : all.last;
    final bounds = all.length >= 2 ? LatLngBounds.fromPoints(all) : null;
    // A route that never moved has no area to fit.
    final canFit = fitRoute && bounds != null && bounds.northWest != bounds.southEast;
    return FlutterMap(
      mapController: controller,
      options: MapOptions(
        initialCenter: current ?? start ?? fallbackCenter,
        initialZoom: 16,
        initialCameraFit: canFit
            ? CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(32), maxZoom: 17)
            : null,
        maxZoom: 19,
        interactionOptions: InteractionOptions(
          flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
        ),
        onMapReady: onReady,
        onPositionChanged: (_, hasGesture) {
          if (hasGesture) onUserMove?.call();
        },
      ),
      children: [
        if (loadTiles)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.hrzones.app',
            maxNativeZoom: 19,
          )
        else
          const ColoredBox(color: Color(0xFFE8E4DA), child: SizedBox.expand()),
        PolylineLayer(
          polylines: [
            for (final (s, color) in colored ?? [for (final s in segments) (s, routeColor)])
              if (s.length >= 2)
                Polyline(points: s, strokeWidth: 5, color: color, borderStrokeWidth: 1.5, borderColor: Colors.white),
          ],
        ),
        MarkerLayer(
          markers: [
            if (start != null) _dot(start, const Color(0xFF2E7D32), 'start'),
            if (end != null) _dot(end, const Color(0xFFC62828), 'end'),
            if (current != null) _dot(current!, const Color(0xFF1E88E5), 'current', size: 20),
          ],
        ),
        const SimpleAttributionWidget(source: Text('OpenStreetMap contributors')),
      ],
    );
  }

  Marker _dot(LatLng at, Color color, String name, {double size = 16}) => Marker(
    key: Key('mapMarker_$name'),
    point: at,
    width: size,
    height: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.black38)],
      ),
    ),
  );
}

/// The route of a finished run in full screen (pinch to zoom, drag).
class RunMapScreen extends StatelessWidget {
  const RunMapScreen({super.key, required this.segments, required this.title, this.colored});

  final RouteSegments segments;
  final String title;
  final List<(List<LatLng>, Color)>? colored;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: RunMap(segments: segments, colored: colored),
  );
}
