import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

import '../hr/ble_hr_source.dart' show bluetoothRefused, bluetoothSupported;
import '../platform/phone_system.dart';

/// Bluetooth Cycling Speed and Cadence (0x1816 / measurement 0x2A5B) and
/// Cycling Power (0x1818 / measurement 0x2A63) – standard sensors on bikes,
/// cranks, pedals and indoor trainers.
final cscService = Uuid.parse('1816');
final cscMeasurement = Uuid.parse('2A5B');
final powerService = Uuid.parse('1818');
final powerMeasurement = Uuid.parse('2A63');

/// A typical road wheel (700 × 25c) in millimetres.
const defaultWheelMm = 2105;

/// Cumulative revolutions and the time of the last one (in 1/1024 s, or
/// 1/2048 s for a power meter's wheel data).
typedef RevData = ({int revs, int time});

/// A decoded speed/cadence or power notification.
class BikeReading {
  const BikeReading({this.wheel, this.crank, this.power});

  final RevData? wheel;
  final RevData? crank;

  /// Watts right now (power meters only).
  final int? power;
}

int _u16(List<int> d, int i) => d[i] | (d[i + 1] << 8);
int _u32(List<int> d, int i) => d[i] | (d[i + 1] << 8) | (d[i + 2] << 16) | (d[i + 3] << 24);

/// CSC Measurement: flags (bit 0 = wheel data: uint32 revs + uint16 time,
/// bit 1 = crank data: uint16 revs + uint16 time). Null if too short.
BikeReading? parseCsc(List<int> d) {
  if (d.isEmpty) return null;
  final flags = d[0];
  var i = 1;
  RevData? wheel, crank;
  if (flags & 0x01 != 0) {
    if (d.length < i + 6) return null;
    wheel = (revs: _u32(d, i), time: _u16(d, i + 4));
    i += 6;
  }
  if (flags & 0x02 != 0) {
    if (d.length < i + 4) return null;
    crank = (revs: _u16(d, i), time: _u16(d, i + 2));
  }
  return BikeReading(wheel: wheel, crank: crank);
}

/// Cycling Power Measurement: uint16 flags, sint16 watts, then optional
/// fields in order – pedal balance (bit 0, 1 byte), accumulated torque (bit 2,
/// 2 bytes), wheel data (bit 4, uint32 + uint16 in 1/2048 s), crank data
/// (bit 5, uint16 + uint16 in 1/1024 s). Null if too short.
BikeReading? parsePower(List<int> d) {
  if (d.length < 4) return null;
  final flags = _u16(d, 0);
  var watts = _u16(d, 2);
  if (watts >= 0x8000) watts -= 0x10000;
  var i = 4;
  if (flags & 0x01 != 0) i += 1;
  if (flags & 0x04 != 0) i += 2;
  RevData? wheel, crank;
  if (flags & 0x10 != 0) {
    if (d.length < i + 6) return BikeReading(power: watts);
    // wheel time is in 1/2048 s here – halve it to the CSC unit
    wheel = (revs: _u32(d, i), time: _u16(d, i + 4) ~/ 2);
    i += 6;
  }
  if (flags & 0x20 != 0 && d.length >= i + 4) crank = (revs: _u16(d, i), time: _u16(d, i + 2));
  return BikeReading(wheel: wheel, crank: crank, power: watts < 0 ? 0 : watts);
}

/// Turns cumulative revolutions into revolutions per second, handling the
/// counters rolling over. Reads 0 when nothing turned for [stopAfter].
class RevCounter {
  RevCounter({required this.revBits});

  /// 32 for wheel revolutions, 16 for crank revolutions.
  final int revBits;
  static const stopAfter = Duration(seconds: 3);

  RevData? _last;
  DateTime? _lastTurn;
  double _rate = 0;

  /// Revolutions counted since the first reading.
  int total = 0;

  double rateAt(DateTime now) {
    final t = _lastTurn;
    return t == null || now.difference(t) > stopAfter ? 0 : _rate;
  }

  void add(RevData d, DateTime now) {
    final last = _last;
    _last = d;
    if (last == null) return;
    final revs = (d.revs - last.revs) & ((1 << revBits) - 1);
    final ticks = (d.time - last.time) & 0xFFFF;
    if (revs == 0 || ticks == 0) return;
    if (revs > 1000) return; // a reset sensor, not real turns
    total += revs;
    _rate = revs / (ticks / 1024);
    _lastTurn = now;
  }

  void reset() {
    _last = null;
    _lastTurn = null;
    _rate = 0;
    total = 0;
  }
}

enum BikeSensorType { speedCadence, power }

/// A saved sensor (setting `bikeSensors`, JSON list).
class BikeSensor {
  const BikeSensor({required this.id, required this.name, required this.type});

  final String id;
  final String name;
  final BikeSensorType type;

  Map<String, Object> toJson() => {'id': id, 'name': name, 'type': type.name};

  static BikeSensor? fromJson(Object? j) {
    if (j is! Map) return null;
    final type = BikeSensorType.values.where((t) => t.name == j['type']).firstOrNull;
    final id = j['id'], name = j['name'];
    if (type == null || id is! String || name is! String) return null;
    return BikeSensor(id: id, name: name, type: type);
  }

  static List<BikeSensor> decodeList(String? json) {
    if (json == null || json.isEmpty) return const [];
    try {
      return [for (final j in jsonDecode(json) as List) ?BikeSensor.fromJson(j)];
    } catch (_) {
      return const [];
    }
  }

  static String encodeList(List<BikeSensor> list) => jsonEncode([for (final s in list) s.toJson()]);
}

/// Live numbers from the bike's sensors while a ride records. The Bluetooth
/// side calls [onCsc] / [onPower]; tests call them directly.
class BikeSensorHub {
  BikeSensorHub({DateTime Function()? clock}) : now = clock ?? DateTime.now;

  final DateTime Function() now;

  /// Saved sensors (setting `bikeSensors`).
  List<BikeSensor> sensors = const [];

  /// Wheel circumference in mm (setting `wheelMm`).
  int wheelMm = defaultWheelMm;

  final _wheel = RevCounter(revBits: 32);
  final _crank = RevCounter(revBits: 16);
  int? _watts;
  DateTime? _wattsAt;

  /// "Connected" / "Connecting…" per sensor id (UI).
  final status = ValueNotifier<Map<String, String>>({});

  bool get hasPower => _wattsAt != null;
  bool get hasCadence => _crank.total > 0 || _crankSeen;
  bool get hasSpeed => _wheelSeen;
  bool _crankSeen = false, _wheelSeen = false;

  /// Watts now (0 when the power meter went quiet for 3 s); null without one.
  int? get power {
    final at = _wattsAt;
    if (at == null) return null;
    return now().difference(at) > RevCounter.stopAfter ? 0 : _watts;
  }

  /// Pedal turns per minute; null without a cadence sensor.
  double? get cadence => _crankSeen ? _crank.rateAt(now()) * 60 : null;

  /// Wheel speed in m/s; null without a speed sensor.
  double? get speedMs => _wheelSeen ? _wheel.rateAt(now()) * wheelMm / 1000 : null;

  /// Metres from wheel turns since [start].
  double get wheelDistanceM => _wheel.total * wheelMm / 1000;

  void onCsc(List<int> data) => _apply(parseCsc(data));
  void onPower(List<int> data) => _apply(parsePower(data));

  void _apply(BikeReading? r) {
    if (r == null) return;
    final t = now();
    if (r.wheel != null) {
      _wheelSeen = true;
      _wheel.add(r.wheel!, t);
    }
    if (r.crank != null) {
      _crankSeen = true;
      _crank.add(r.crank!, t);
    }
    if (r.power != null) {
      _watts = r.power;
      _wattsAt = t;
    }
  }

  final _links = <_BleLink>[];

  /// Connects to every saved sensor (a ride starts) and clears the counts.
  void start() {
    stop();
    _wheel.reset();
    _crank.reset();
    _watts = null;
    _wattsAt = null;
    _crankSeen = false;
    _wheelSeen = false;
    if (!bluetoothSupported) return;
    for (final s in sensors) {
      _links.add(
        _BleLink(
          sensor: s,
          onData: s.type == BikeSensorType.power ? onPower : onCsc,
          onStatus: (v) => status.value = {...status.value, s.id: v},
        )..connect(),
      );
    }
  }

  /// Disconnects (the ride ended).
  void stop() {
    for (final l in _links) {
      l.close();
    }
    _links.clear();
    status.value = {};
  }
}

FlutterReactiveBle? _ble;
FlutterReactiveBle get _bleInstance => _ble ??= FlutterReactiveBle();

/// Scans for speed/cadence and power sensors (deduplicated by id).
Stream<List<BikeSensor>> scanBikeSensors() {
  final found = <String, (BikeSensor, int)>{};
  return Stream.fromFuture(PhoneSystem.bluetooth()).asyncExpand((allowed) {
    if (!allowed) return Stream<List<BikeSensor>>.error(bluetoothRefused);
    return _bleInstance
        .scanForDevices(withServices: [cscService, powerService], requireLocationServicesEnabled: false)
        .map((d) {
          final power = d.serviceUuids.contains(powerService);
          found[d.id] = (
            BikeSensor(
              id: d.id,
              name: d.name.isEmpty ? (power ? 'Power meter' : 'Speed / cadence sensor') : d.name,
              type: power ? BikeSensorType.power : BikeSensorType.speedCadence,
            ),
            d.rssi,
          );
          final list = found.values.toList()..sort((a, b) => b.$2.compareTo(a.$2));
          return [for (final x in list) x.$1];
        });
  });
}

/// One sensor's connection; reconnects every 3 s while open.
class _BleLink {
  _BleLink({required this.sensor, required this.onData, required this.onStatus});

  final BikeSensor sensor;
  final void Function(List<int>) onData;
  final void Function(String) onStatus;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  StreamSubscription<List<int>>? _values;
  Timer? _retry;
  bool _open = true;

  Uuid get _service => sensor.type == BikeSensorType.power ? powerService : cscService;
  Uuid get _char => sensor.type == BikeSensorType.power ? powerMeasurement : cscMeasurement;

  Future<void> connect() async {
    if (!_open) return;
    if (!await PhoneSystem.bluetooth(ask: false)) {
      onStatus('Bluetooth not allowed');
      return;
    }
    if (!_open) return;
    onStatus('Connecting…');
    _connection?.cancel();
    _connection = _bleInstance
        .connectToDevice(
          id: sensor.id,
          servicesWithCharacteristicsToDiscover: {
            _service: [_char],
          },
          connectionTimeout: const Duration(seconds: 15),
        )
        .listen((u) {
          switch (u.connectionState) {
            case DeviceConnectionState.connected:
              onStatus('Connected');
              _values?.cancel();
              _values = _bleInstance
                  .subscribeToCharacteristic(
                    QualifiedCharacteristic(serviceId: _service, characteristicId: _char, deviceId: sensor.id),
                  )
                  .listen(onData, onError: (Object _) => _again());
            case DeviceConnectionState.disconnected:
              _again();
            case DeviceConnectionState.connecting || DeviceConnectionState.disconnecting:
              break;
          }
        }, onError: (Object _) => _again());
  }

  void _again() {
    _values?.cancel();
    if (!_open) return;
    onStatus('Reconnecting…');
    _retry?.cancel();
    _retry = Timer(const Duration(seconds: 3), () => connect());
  }

  void close() {
    _open = false;
    _retry?.cancel();
    _values?.cancel();
    _connection?.cancel();
  }
}
