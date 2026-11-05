import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import 'geo.dart';

/// Whether the app may use the location.
enum LocationAccess { granted, denied, deniedForever, serviceOff }

/// Where GPS fixes come from: the phone's GPS, or a simulated runner (web
/// preview, tests).
abstract class LocationSource {
  /// Asks for permission if needed.
  Future<LocationAccess> ensureAccess();

  /// Fixes until [stop]. GPS only runs while listened to (battery).
  Stream<GeoFix> start();
  Future<void> stop();

  /// Opens the iPhone settings for this app (location denied).
  Future<void> openSettings() async {}

  bool get isSimulated => false;

  static LocationSource create() => kIsWeb ? SimulatedLocationSource() : DeviceLocationSource();
}

/// The phone's GPS (geolocator). On iOS it keeps recording with the screen
/// locked: background location updates + the blue location pill.
class DeviceLocationSource extends LocationSource {
  StreamSubscription<Position>? _sub;
  StreamController<GeoFix>? _out;

  @override
  Future<LocationAccess> ensureAccess() async {
    if (!await Geolocator.isLocationServiceEnabled()) return LocationAccess.serviceOff;
    var p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
    return switch (p) {
      LocationPermission.always || LocationPermission.whileInUse => LocationAccess.granted,
      LocationPermission.deniedForever => LocationAccess.deniedForever,
      _ => LocationAccess.denied,
    };
  }

  LocationSettings get _settings => defaultTargetPlatform == TargetPlatform.iOS
      ? AppleSettings(
          accuracy: LocationAccuracy.best,
          activityType: ActivityType.fitness,
          distanceFilter: 0,
          pauseLocationUpdatesAutomatically: false,
          allowBackgroundLocationUpdates: true,
          showBackgroundLocationIndicator: true,
        )
      : const LocationSettings(accuracy: LocationAccuracy.best);

  @override
  Stream<GeoFix> start() {
    _sub?.cancel();
    _out?.close();
    final out = _out = StreamController<GeoFix>();
    _sub = Geolocator.getPositionStream(locationSettings: _settings).listen(
      (p) => out.add(
        GeoFix(
          time: p.timestamp,
          lat: p.latitude,
          lon: p.longitude,
          accuracy: p.accuracy,
          altitude: p.altitude,
          speed: p.speed < 0 ? null : p.speed,
        ),
      ),
      onError: (Object e) => debugPrint('GPS error: $e'),
    );
    return out.stream;
  }

  @override
  Future<void> stop() async {
    await _sub?.cancel();
    _sub = null;
    await _out?.close();
    _out = null;
  }

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}

/// A pretend runner going round a 400 m-ish loop, one fix per second. Used in
/// the web preview (no GPS when the phone is locked there) and in tests.
class SimulatedLocationSource extends LocationSource {
  SimulatedLocationSource({this.paceSecPerKm = 330, this.startLat = 32.0970, this.startLon = 34.8090});

  /// Speed of the pretend runner (changeable while running).
  double paceSecPerKm;
  final double startLat;
  final double startLon;

  /// When true no fixes arrive (like losing GPS in a tunnel).
  bool signalLost = false;

  Timer? _timer;
  StreamController<GeoFix>? _out;
  double _angle = 0;

  static const _radiusM = 64.0; // ≈ 400 m loop

  @override
  bool get isSimulated => true;

  @override
  Future<LocationAccess> ensureAccess() async => LocationAccess.granted;

  GeoFix _fix() {
    final dLat = _radiusM * math.sin(_angle) / 111320;
    final dLon = _radiusM * (math.cos(_angle) - 1) / (111320 * math.cos(startLat * math.pi / 180));
    return GeoFix(time: DateTime.now(), lat: startLat + dLat, lon: startLon + dLon, accuracy: 5);
  }

  @override
  Stream<GeoFix> start() {
    _timer?.cancel();
    _out?.close();
    final out = _out = StreamController<GeoFix>();
    out.add(_fix());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _angle += (1000 / paceSecPerKm) / _radiusM; // metres per second / radius
      if (!signalLost) out.add(_fix());
    });
    return out.stream;
  }

  @override
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    await _out?.close();
    _out = null;
  }
}
