import 'dart:async';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:permission_handler/permission_handler.dart';

class HeartRateService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();

  static final Uuid _heartRateService = Uuid.parse(
    '0000180d-0000-1000-8000-00805f9b34fb',
  );

  static final Uuid _heartRateMeasurement = Uuid.parse(
    '00002a37-0000-1000-8000-00805f9b34fb',
  );

  StreamSubscription<DiscoveredDevice>? _scanSubscription;
  StreamSubscription<ConnectionStateUpdate>? _connectionSubscription;
  StreamSubscription<List<int>>? _heartRateSubscription;

  final StreamController<int?> _heartRateController =
      StreamController<int?>.broadcast();

  final StreamController<String> _statusController =
      StreamController<String>.broadcast();

  Stream<int?> get heartRate => _heartRateController.stream;

  Stream<String> get status => _statusController.stream;

  String? _deviceId;

  Timer? _staleTimer;
  Timer? _reconnectTimer;

  bool _stopping = false;

  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<void> start() async {
    _stopping = false;

    await stop(keepStoppingState: false);

    await _startScan();
  }

  Future<void> _startScan() async {
    final permitted = await requestPermissions();

    if (!permitted) {
      _statusController.add('Bluetooth-Berechtigung fehlt');
      return;
    }

    _statusController.add('Suche Herzfrequenzsensor …');

    await _scanSubscription?.cancel();

    _scanSubscription = _ble
        .scanForDevices(
          withServices: [_heartRateService],
          scanMode: ScanMode.lowLatency,
        )
        .listen(
          _handleDevice,
          onError: (Object error) {
            _statusController.add('BLE-Scan fehlgeschlagen: $error');
          },
        );
  }

  Future<void> _handleDevice(DiscoveredDevice device) async {
    if (_deviceId != null) {
      return;
    }

    _deviceId = device.id;

    _statusController.add(
      device.name.isNotEmpty
          ? 'Gefunden: ${device.name}'
          : 'Herzfrequenzsensor gefunden',
    );

    await _scanSubscription?.cancel();
    _scanSubscription = null;

    _connect(device);
  }

  void _connect(DiscoveredDevice device) {
    _statusController.add(
      'Verbinde ${device.name.isNotEmpty ? device.name : 'HF-Sensor'} …',
    );

    _connectionSubscription = _ble
        .connectToDevice(
          id: device.id,
          connectionTimeout: const Duration(seconds: 10),
        )
        .listen(
          (update) {
            switch (update.connectionState) {
              case DeviceConnectionState.connected:
                _statusController.add(
                  device.name.isNotEmpty
                      ? '${device.name} verbunden'
                      : 'HF-Sensor verbunden',
                );

                _subscribeToHeartRate(device.id);

              case DeviceConnectionState.connecting:
                break;

              case DeviceConnectionState.disconnecting:
                break;

              case DeviceConnectionState.disconnected:
                _statusController.add('HF-Sensor getrennt');

                _heartRateController.add(null);

                _staleTimer?.cancel();
                _deviceId = null;

                _scheduleReconnect();
            }
          },
          onError: (Object error) {
            _statusController.add('BLE-Verbindung fehlgeschlagen: $error');

            _heartRateController.add(null);
            _staleTimer?.cancel();
            _deviceId = null;

            _scheduleReconnect();
          },
        );
  }

  void _scheduleReconnect() {
    if (_stopping) {
      return;
    }

    _reconnectTimer?.cancel();

    _reconnectTimer = Timer(const Duration(seconds: 2), () async {
      if (_stopping || _deviceId != null) {
        return;
      }

      await _connectionSubscription?.cancel();
      _connectionSubscription = null;

      await _heartRateSubscription?.cancel();
      _heartRateSubscription = null;

      await _startScan();
    });
  }

  Future<void> _subscribeToHeartRate(String deviceId) async {
    await _heartRateSubscription?.cancel();
    _heartRateSubscription = null;
    final characteristic = QualifiedCharacteristic(
      serviceId: _heartRateService,
      characteristicId: _heartRateMeasurement,
      deviceId: deviceId,
    );

    _heartRateSubscription = _ble
        .subscribeToCharacteristic(characteristic)
        .listen(
          (data) {
            final bpm = _parseHeartRate(data);

            if (bpm != null) {
              _heartRateController.add(bpm);
              _restartStaleTimer();
            }
          },
          onError: (Object error) {
            _statusController.add('HF-Datenfehler: $error');

            _heartRateController.add(null);
            _staleTimer?.cancel();
            _deviceId = null;

            _scheduleReconnect();
          },
        );
  }

  int? _parseHeartRate(List<int> data) {
    if (data.length < 2) {
      return null;
    }

    final flags = data[0];

    final is16Bit = (flags & 0x01) != 0;

    if (!is16Bit) {
      return data[1];
    }

    if (data.length < 3) {
      return null;
    }

    return data[1] | (data[2] << 8);
  }

  void _restartStaleTimer() {
    _staleTimer?.cancel();

    _staleTimer = Timer(const Duration(seconds: 5), () {
      if (_stopping) {
        return;
      }

      _heartRateController.add(null);

      _statusController.add('Keine aktuellen HF-Daten');

      _deviceId = null;

      _scheduleReconnect();
    });
  }

  Future<void> stop({bool keepStoppingState = true}) async {
    _stopping = keepStoppingState;

    _staleTimer?.cancel();
    _reconnectTimer?.cancel();

    await _scanSubscription?.cancel();
    await _heartRateSubscription?.cancel();
    await _connectionSubscription?.cancel();

    _scanSubscription = null;
    _heartRateSubscription = null;
    _connectionSubscription = null;

    _deviceId = null;

    if (keepStoppingState) {
      _heartRateController.add(null);
    }
  }

  Future<void> dispose() async {
    await stop();

    await _heartRateController.close();
    await _statusController.close();
  }
}
