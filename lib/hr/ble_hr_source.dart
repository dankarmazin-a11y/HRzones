import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import 'heart_rate_source.dart';

/// Standard Bluetooth Heart Rate Profile (chest straps, arm bands, watches
/// in broadcast mode): service 0x180D, measurement characteristic 0x2A37.
final hrService = Uuid.parse('180D');
final hrMeasurement = Uuid.parse('2A37');

/// Decodes a Heart Rate Measurement value: flags byte, then bpm as uint8
/// (flag bit 0 = 0) or little-endian uint16 (bit 0 = 1). Null if invalid.
int? parseHeartRateMeasurement(List<int> data) {
  if (data.length < 2) return null;
  final wide = data[0] & 0x01 == 1;
  if (wide) {
    if (data.length < 3) return null;
    return data[1] | (data[2] << 8);
  }
  return data[1];
}

/// A strap found while scanning.
class HrDevice {
  const HrDevice({required this.id, required this.name, this.rssi});

  final String id;
  final String name;
  final int? rssi;
}

/// Bluetooth is not available in the web preview.
bool get bluetoothSupported =>
    !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);

FlutterReactiveBle? _ble;
FlutterReactiveBle get _bleInstance => _ble ??= FlutterReactiveBle();

/// Scans for heart-rate devices (deduplicated by id).
Stream<List<HrDevice>> scanHrDevices() {
  final found = <String, HrDevice>{};
  return _bleInstance.scanForDevices(withServices: [hrService], requireLocationServicesEnabled: false).map((d) {
    found[d.id] = HrDevice(id: d.id, name: d.name.isEmpty ? 'Heart-rate sensor' : d.name, rssi: d.rssi);
    return found.values.toList()..sort((a, b) => (b.rssi ?? -999).compareTo(a.rssi ?? -999));
  });
}

/// Live heart rate from a Bluetooth strap. Reconnects automatically while
/// started (e.g. strap out of range for a moment).
class BleHrSource implements HeartRateSource {
  BleHrSource({required this.deviceId, required this.deviceName});

  final String deviceId;
  final String deviceName;

  /// "Connecting…", "Connected", "Reconnecting…" – shown in the UI.
  final status = ValueNotifier<String>('Not connected');

  final _controller = StreamController<HrReading>.broadcast();
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _values;
  Timer? _retry;
  bool _started = false;

  @override
  HrSourceKind get kind => HrSourceKind.bluetooth;

  @override
  String get displayName => deviceName;

  @override
  Stream<HrReading> get readings => _controller.stream;

  @override
  Future<void> start() async {
    if (_started) return;
    _started = true;
    _connect();
  }

  void _connect() {
    if (!_started) return;
    status.value = 'Connecting…';
    _connection?.cancel();
    _connection = _bleInstance
        .connectToDevice(
          id: deviceId,
          servicesWithCharacteristicsToDiscover: {
            hrService: [hrMeasurement],
          },
          connectionTimeout: const Duration(seconds: 15),
        )
        .listen(
          (update) {
            switch (update.connectionState) {
              case DeviceConnectionState.connected:
                status.value = 'Connected';
                _subscribe();
              case DeviceConnectionState.disconnected:
                _scheduleRetry();
              case DeviceConnectionState.connecting || DeviceConnectionState.disconnecting:
                break;
            }
          },
          onError: (Object e) {
            debugPrint('BLE connect error: $e');
            _scheduleRetry();
          },
        );
  }

  void _subscribe() {
    _values?.cancel();
    final characteristic = QualifiedCharacteristic(
      serviceId: hrService,
      characteristicId: hrMeasurement,
      deviceId: deviceId,
    );
    _values = _bleInstance
        .subscribeToCharacteristic(characteristic)
        .listen(
          (data) {
            final bpm = parseHeartRateMeasurement(data);
            if (bpm != null && bpm > 0 && !_controller.isClosed) {
              _controller.add(HrReading(bpm: bpm, time: DateTime.now(), source: kind));
            }
          },
          onError: (Object e) {
            debugPrint('BLE notify error: $e');
            _scheduleRetry();
          },
        );
  }

  void _scheduleRetry() {
    _values?.cancel();
    if (!_started) return;
    status.value = 'Reconnecting…';
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), _connect);
  }

  @override
  Future<void> stop() async {
    _started = false;
    _retry?.cancel();
    await _values?.cancel();
    await _connection?.cancel(); // cancelling the connection stream disconnects
    _values = null;
    _connection = null;
    status.value = 'Not connected';
  }

  @override
  void dispose() {
    stop();
    _controller.close();
    status.dispose();
  }
}
