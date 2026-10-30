class PiRowFloStatus {
  final Map<String, String> states;

  final bool smartRowAvailable;
  final bool smartRowConnected;
  final bool smartRowReady;
  final String? smartRowAdapter;

  final bool smartRowBluetoothAvailable;
  final bool smartRowBluetoothPowered;
  final bool smartRowBluetoothSoftBlocked;
  final bool smartRowBluetoothHardBlocked;
  final String? smartRowBluetoothAdapter;

  final bool antAvailable;

  const PiRowFloStatus({
    required this.states,
    required this.smartRowAvailable,
    required this.smartRowConnected,
    required this.smartRowReady,
    required this.smartRowAdapter,
    required this.smartRowBluetoothAvailable,
    required this.smartRowBluetoothPowered,
    required this.smartRowBluetoothSoftBlocked,
    required this.smartRowBluetoothHardBlocked,
    required this.smartRowBluetoothAdapter,
    required this.antAvailable,
  });

  factory PiRowFloStatus.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'];
    final smartRow = json['smartrow'];
    final hardware = json['hardware'];

    final smartRowBluetooth = hardware is Map<String, dynamic>
        ? hardware['smartrow_bluetooth']
        : null;

    final antHardware = hardware is Map<String, dynamic>
        ? hardware['ant']
        : null;

    String profileState(String name) {
      if (profiles is! Map<String, dynamic>) {
        return 'UNKNOWN';
      }

      final profile = profiles[name];

      if (profile is! Map<String, dynamic>) {
        return 'UNKNOWN';
      }

      return profile['state']?.toString() ?? 'UNKNOWN';
    }

    return PiRowFloStatus(
      states: {
        'combined': profileState('combined'),
        'bluetooth': profileState('bluetooth'),
        'ant': profileState('ant'),
      },
      smartRowAvailable:
          smartRow is Map<String, dynamic> && smartRow['available'] == true,
      smartRowConnected:
          smartRow is Map<String, dynamic> && smartRow['connected'] == true,
      smartRowReady:
          smartRow is Map<String, dynamic> &&
          smartRow['services_resolved'] == true,
      smartRowAdapter: smartRow is Map<String, dynamic>
          ? smartRow['adapter']?.toString()
          : null,
      smartRowBluetoothAvailable:
          smartRowBluetooth is Map<String, dynamic> &&
          smartRowBluetooth['available'] == true,
      smartRowBluetoothPowered:
          smartRowBluetooth is Map<String, dynamic> &&
          smartRowBluetooth['powered'] == true,
      smartRowBluetoothSoftBlocked:
          smartRowBluetooth is Map<String, dynamic> &&
          smartRowBluetooth['soft_blocked'] == true,
      smartRowBluetoothHardBlocked:
          smartRowBluetooth is Map<String, dynamic> &&
          smartRowBluetooth['hard_blocked'] == true,
      smartRowBluetoothAdapter: smartRowBluetooth is Map<String, dynamic>
          ? smartRowBluetooth['adapter']?.toString()
          : null,
      antAvailable:
          antHardware is Map<String, dynamic> &&
          antHardware['available'] == true,
    );
  }

  bool get running =>
      states.values.any((state) => state.toUpperCase() == 'RUNNING');

  String get activeMode {
    if (states['combined'] == 'RUNNING') {
      return 'BLE + ANT+';
    }

    if (states['bluetooth'] == 'RUNNING') {
      return 'Nur Bluetooth';
    }

    if (states['ant'] == 'RUNNING') {
      return 'Nur ANT+';
    }

    return 'Gestoppt';
  }

  bool get bluetoothRequired =>
      states['combined'] == 'RUNNING' || states['bluetooth'] == 'RUNNING';

  bool get antRequired =>
      states['combined'] == 'RUNNING' || states['ant'] == 'RUNNING';

  bool get smartRowBluetoothHealthy =>
      smartRowBluetoothAvailable &&
      smartRowBluetoothPowered &&
      !smartRowBluetoothSoftBlocked &&
      !smartRowBluetoothHardBlocked;

  String get smartRowBluetoothStatusText {
    if (!smartRowBluetoothAvailable) {
      return 'Adapter nicht gefunden';
    }

    if (smartRowBluetoothHardBlocked) {
      return 'Hardwareseitig blockiert';
    }

    if (smartRowBluetoothSoftBlocked) {
      return 'Adapter blockiert';
    }

    if (!smartRowBluetoothPowered) {
      return 'Adapter ausgeschaltet';
    }

    if (smartRowBluetoothAdapter != null) {
      return '$smartRowBluetoothAdapter bereit';
    }

    return 'Bereit';
  }
}
