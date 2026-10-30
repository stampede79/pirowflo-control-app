import 'package:flutter_test/flutter_test.dart';
import 'package:pirowflo_control/models/pirowflo_status.dart';

void main() {
  group('PiRowFloStatus', () {
    test('parses running combined profile and healthy hardware', () {
      final status = PiRowFloStatus.fromJson({
        'profiles': {
          'combined': {'state': 'RUNNING'},
          'bluetooth': {'state': 'STOPPED'},
          'ant': {'state': 'STOPPED'},
        },
        'smartrow': {
          'available': true,
          'connected': true,
          'services_resolved': true,
          'adapter': 'hci1',
        },
        'hardware': {
          'smartrow_bluetooth': {
            'available': true,
            'adapter': 'hci1',
            'powered': true,
            'soft_blocked': false,
            'hard_blocked': false,
          },
          'ant': {'available': true},
        },
      });

      expect(status.running, isTrue);
      expect(status.activeMode, 'BLE + ANT+');
      expect(status.bluetoothRequired, isTrue);
      expect(status.antRequired, isTrue);

      expect(status.smartRowAvailable, isTrue);
      expect(status.smartRowConnected, isTrue);
      expect(status.smartRowReady, isTrue);
      expect(status.smartRowAdapter, 'hci1');

      expect(status.smartRowBluetoothHealthy, isTrue);
      expect(status.smartRowBluetoothStatusText, 'hci1 bereit');

      expect(status.antAvailable, isTrue);
    });

    test('reports blocked Bluetooth adapter', () {
      final status = PiRowFloStatus.fromJson({
        'profiles': {
          'combined': {'state': 'STOPPED'},
          'bluetooth': {'state': 'RUNNING'},
          'ant': {'state': 'STOPPED'},
        },
        'smartrow': {
          'available': false,
          'connected': false,
          'services_resolved': false,
        },
        'hardware': {
          'smartrow_bluetooth': {
            'available': true,
            'powered': true,
            'soft_blocked': true,
            'hard_blocked': false,
          },
          'ant': {'available': true},
        },
      });

      expect(status.running, isTrue);
      expect(status.activeMode, 'Nur Bluetooth');
      expect(status.bluetoothRequired, isTrue);
      expect(status.antRequired, isFalse);

      expect(status.smartRowBluetoothHealthy, isFalse);
      expect(status.smartRowBluetoothStatusText, 'Adapter blockiert');
    });

    test('handles missing status fields safely', () {
      final status = PiRowFloStatus.fromJson({});

      expect(status.running, isFalse);
      expect(status.activeMode, 'Gestoppt');

      expect(status.states['combined'], 'UNKNOWN');
      expect(status.states['bluetooth'], 'UNKNOWN');
      expect(status.states['ant'], 'UNKNOWN');

      expect(status.smartRowAvailable, isFalse);
      expect(status.smartRowConnected, isFalse);
      expect(status.smartRowReady, isFalse);

      expect(status.smartRowBluetoothAvailable, isFalse);
      expect(status.smartRowBluetoothHealthy, isFalse);
      expect(status.smartRowBluetoothStatusText, 'Adapter nicht gefunden');

      expect(status.antAvailable, isFalse);
    });

    test('reports hard blocked Bluetooth adapter', () {
      final status = PiRowFloStatus.fromJson({
        'hardware': {
          'smartrow_bluetooth': {
            'available': true,
            'powered': true,
            'soft_blocked': false,
            'hard_blocked': true,
          },
        },
      });

      expect(status.smartRowBluetoothHealthy, isFalse);
      expect(status.smartRowBluetoothStatusText, 'Hardwareseitig blockiert');
    });
  });
}
