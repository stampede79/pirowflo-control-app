import 'dart:async';
import 'dart:convert';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'screens/workout_screen.dart';
import 'models/workout.dart';
import 'services/workout_parser.dart';

import 'services/nextcloud_calendar_service.dart';
import 'screens/home_screen.dart';
import 'models/scheduled_workout.dart';

void main() {
  runApp(const PiRowFloApp());
}

class PiRowFloApp extends StatelessWidget {
  const PiRowFloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiRowFlo Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const ControlPage(),
    );
  }
}

class ControlPage extends StatefulWidget {
  const ControlPage({super.key});

  @override
  State<ControlPage> createState() => _ControlPageState();
}

class _ControlPageState extends State<ControlPage> {
  static const storage = FlutterSecureStorage();

  final serverController = TextEditingController();
  final apiKeyController = TextEditingController();
  final calendarUrlController = TextEditingController(
    text: 'https://cloud.roderwieser.com/remote.php/dav/calendars/admin/rudertraining/',
  );
  final nextcloudUserController = TextEditingController();
  final nextcloudPasswordController = TextEditingController();

  String? calendarTestResult;
  int selectedPage = 0;

  bool loading = false;
  bool configured = false;
  String? error;

  Map<String, String> states = {
    'combined': 'UNKNOWN',
    'bluetooth': 'UNKNOWN',
    'ant': 'UNKNOWN',
  };

  // SmartRow-Status
  bool smartRowAvailable = false;
  bool smartRowConnected = false;
  bool smartRowReady = false;
  String? smartRowAdapter;

  Timer? statusTimer;

  Workout? todaysWorkout;
  bool calendarLoading = false;
  String? calendarError;
  ScheduledWorkout? nextWorkout;

  @override
  void initState() {
    super.initState();
    loadConfiguration();
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    serverController.dispose();
    apiKeyController.dispose();
    calendarUrlController.dispose();
    nextcloudUserController.dispose();
    nextcloudPasswordController.dispose();
    super.dispose();
  }

  Future<void> loadConfiguration() async {
    final server = await storage.read(key: 'server');
    final apiKey = await storage.read(key: 'apiKey');
    final calendarUrl = await storage.read(key: 'calendarUrl');
    final nextcloudUser = await storage.read(key: 'nextcloudUser');
    final nextcloudPassword = await storage.read(key: 'nextcloudPassword');

    if (!mounted) return;

    serverController.text = server ?? '';
    apiKeyController.text = apiKey ?? '';
    if (calendarUrl != null && calendarUrl.isNotEmpty) {
      calendarUrlController.text = calendarUrl;
    }

    nextcloudUserController.text = nextcloudUser ?? '';
    nextcloudPasswordController.text = nextcloudPassword ?? '';

    setState(() {
      configured =
          serverController.text.isNotEmpty && apiKeyController.text.isNotEmpty;
    });

    if (configured) {
      await refreshStatus();
      startStatusTimer();
    } else {
      statusTimer?.cancel();
    }
    await loadTodaysWorkout();
    await loadNextWorkout();
  }

  Future<void> saveConfiguration() async {
    var server = serverController.text.trim();

    if (server.endsWith('/')) {
      server = server.substring(0, server.length - 1);
    }

    serverController.text = server;

    await storage.write(key: 'server', value: server);

    await storage.write(key: 'apiKey', value: apiKeyController.text.trim());

    await storage.write(
      key: 'calendarUrl',
      value: calendarUrlController.text.trim(),
    );

    await storage.write(
      key: 'nextcloudUser',
      value: nextcloudUserController.text.trim(),
    );

    await storage.write(
      key: 'nextcloudPassword',
      value: nextcloudPasswordController.text,
    );

    if (!mounted) return;

    setState(() {
      configured = server.isNotEmpty && apiKeyController.text.trim().isNotEmpty;
      error = null;
    });

    if (configured) {
      await refreshStatus();
      startStatusTimer();
    } else {
      statusTimer?.cancel();
    }
    await loadTodaysWorkout();
    await loadNextWorkout();
  }

  Map<String, String> get headers => {
    'X-API-Key': apiKeyController.text.trim(),
  };

  Future<void> refreshStatus() async {
    if (!configured) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('${serverController.text}/api/status'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final profiles = data['profiles'];
      final smartrow = data['smartrow'];

      if (!mounted) return;

      setState(() {
        states['combined'] =
            profiles['combined']?['state']?.toString() ?? 'UNKNOWN';
        states['bluetooth'] =
            profiles['bluetooth']?['state']?.toString() ?? 'UNKNOWN';
        states['ant'] = profiles['ant']?['state']?.toString() ?? 'UNKNOWN';

        smartRowAvailable = smartrow?['available'] == true;
        smartRowConnected = smartrow?['connected'] == true;
        smartRowReady = smartrow?['services_resolved'] == true;
        smartRowAdapter = smartrow?['adapter']?.toString();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'PiRowFlo nicht erreichbar: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  Future<void> refreshStatusSilent() async {
    if (!configured) return;

    try {
      final response = await http
          .get(
            Uri.parse('${serverController.text}/api/status'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);
      final profiles = data['profiles'];
      final smartrow = data['smartrow'];

      if (!mounted) return;

      setState(() {
        states['combined'] =
            profiles['combined']?['state']?.toString() ?? 'UNKNOWN';
        states['bluetooth'] =
            profiles['bluetooth']?['state']?.toString() ?? 'UNKNOWN';
        states['ant'] = profiles['ant']?['state']?.toString() ?? 'UNKNOWN';

        smartRowAvailable = smartrow?['available'] == true;
        smartRowConnected = smartrow?['connected'] == true;
        smartRowReady = smartrow?['services_resolved'] == true;
        smartRowAdapter = smartrow?['adapter']?.toString();
      });
    } catch (_) {
      // Hintergrund-Refresh soll die Oberfläche nicht mit Fehlern fluten.
    }
  }

  void startStatusTimer() {
    statusTimer?.cancel();

    statusTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => refreshStatusSilent(),
    );
  }

  Future<void> post(String path) async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final response = await http
          .post(Uri.parse('${serverController.text}$path'), headers: headers)
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      await Future.delayed(const Duration(milliseconds: 700));
      await refreshStatus();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = 'Aktion fehlgeschlagen: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

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

  bool get running =>
      states.values.any((state) => state.toUpperCase() == 'RUNNING');

  Widget statusRow(String title, String state) {
    final isRunning = state == 'RUNNING';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isRunning ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isRunning ? Colors.green : Colors.grey,
      ),
      title: Text(title),
      trailing: Text(state),
    );
  }

  Future<void> scanConfiguration() async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerPage()),
    );

    if (result == null) {
      return;
    }

    serverController.text = result['server'] ?? '';
    apiKeyController.text = result['apiKey'] ?? '';

    await saveConfiguration();
  }

  Future<void> testNextcloudCalendar() async {
    final calendarUrl = calendarUrlController.text.trim();
    final username = nextcloudUserController.text.trim();
    final password = nextcloudPasswordController.text;

    if (calendarUrl.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        calendarTestResult = 'Nextcloud-Konfiguration unvollständig';
      });
      return;
    }

    setState(() {
      calendarTestResult = 'Kalender wird geprüft …';
    });

    try {
      final service = NextcloudCalendarService(
        calendarUrl: calendarUrl,
        username: username,
        appPassword: password,
      );

      final events = await service.getEventsForDay(DateTime.now());

      if (!mounted) return;

      setState(() {
        if (events.isEmpty) {
          calendarTestResult = 'Verbindung erfolgreich – heute kein Termin';
        } else {
          calendarTestResult =
              'Verbindung erfolgreich – heute: ${events.first.summary}';
        }
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        calendarTestResult = 'Kalenderfehler: $e';
      });
    }
  }

  Future<void> loadTodaysWorkout() async {
    final calendarUrl = calendarUrlController.text.trim();
    final username = nextcloudUserController.text.trim();
    final password = nextcloudPasswordController.text;

    if (calendarUrl.isEmpty || username.isEmpty || password.isEmpty) {
      return;
    }

    setState(() {
      calendarLoading = true;
      calendarError = null;
    });

    try {
      final service = NextcloudCalendarService(
        calendarUrl: calendarUrl,
        username: username,
        appPassword: password,
      );

      final events = await service.getEventsForDay(DateTime.now());

      Workout? foundWorkout;

      for (final event in events) {
        final workout = WorkoutParser.parse(
          name: event.summary,
          description: event.description,
        );

        if (workout != null) {
          foundWorkout = workout;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        todaysWorkout = foundWorkout;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        calendarError = 'Trainingskalender nicht erreichbar: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          calendarLoading = false;
        });
      }
    }
  }

  Future<void> loadNextWorkout() async {
    final calendarUrl = calendarUrlController.text.trim();
    final username = nextcloudUserController.text.trim();
    final password = nextcloudPasswordController.text;

    if (calendarUrl.isEmpty || username.isEmpty || password.isEmpty) {
      return;
    }

    try {
      final service = NextcloudCalendarService(
        calendarUrl: calendarUrl,
        username: username,
        appPassword: password,
      );

      final now = DateTime.now();

      // Morgen 00:00 bis einschließlich der folgenden 14 Tage.
      final start = DateTime(now.year, now.month, now.day + 1);

      final end = start.add(const Duration(days: 14));

      final events = await service.getEventsForRange(start, end);

      ScheduledWorkout? found;

      events.sort((a, b) => a.start.compareTo(b.start));

      for (final event in events) {
        final eventDate = event.start.toLocal();

        final eventDay = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
        );

        if (eventDay.isBefore(start)) {
          continue;
        }

        final workout = WorkoutParser.parse(
          name: event.summary,
          description: event.description,
        );

        if (workout != null) {
          found = ScheduledWorkout(start: eventDate, workout: workout);
          break;
        }
      }
      if (!mounted) return;

      setState(() {
        nextWorkout = found;
      });
    } catch (_) {
      // Das nächste Training ist eine Zusatzinformation.
      // Ein Fehler soll die heutige Trainingsanzeige nicht beeinträchtigen.
      if (!mounted) return;

      setState(() {
        nextWorkout = null;
      });
    }
  }

  Future<void> startWorkout() async {
    if (todaysWorkout == null) {
      return;
    }

    if (!smartRowReady) {
      final startAnyway = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('SmartRow nicht verbunden'),
          content: const Text(
            'SmartRow ist noch nicht vollständig verbunden. '
            'Das Training kann gestartet werden, aber es stehen '
            'möglicherweise keine Live-Daten zur Verfügung.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Trotzdem starten'),
            ),
          ],
        ),
      );

      if (startAnyway != true || !mounted) {
        return;
      }
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutScreen(
          workout: todaysWorkout!,
          server: serverController.text,
          apiKey: apiKeyController.text,
        ),
      ),
    );
  }

  void showSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verbindung'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: serverController,
                  decoration: const InputDecoration(
                    labelText: 'Server',
                    hintText: 'http://192.168.178.xxx:8090',
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: apiKeyController,
                  decoration: const InputDecoration(labelText: 'API-Key'),
                  obscureText: true,
                  autocorrect: false,
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    scanConfiguration();
                  },
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('QR-Code scannen'),
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Trainingskalender',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: calendarUrlController,
                  decoration: const InputDecoration(labelText: 'CalDAV-URL'),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: nextcloudUserController,
                  decoration: const InputDecoration(
                    labelText: 'Nextcloud-Benutzer',
                  ),
                  autocorrect: false,
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: nextcloudPasswordController,
                  decoration: const InputDecoration(labelText: 'App-Passwort'),
                  obscureText: true,
                  autocorrect: false,
                ),

                const SizedBox(height: 16),

                OutlinedButton.icon(
                  onPressed: testNextcloudCalendar,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Kalender testen'),
                ),

                if (calendarTestResult != null) ...[
                  const SizedBox(height: 12),
                  Text(calendarTestResult!),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(context);
                await saveConfiguration();
              },
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedPage == 0 ? 'Übersicht' : 'PiRowFlo-Steuerung'),
        actions: [
          IconButton(
            onPressed: loading ? null : refreshStatus,
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              const ListTile(
                leading: Icon(Icons.rowing),
                title: Text(
                  'PiRowFlo Control',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Übersicht'),
                selected: selectedPage == 0,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedPage = 0;
                  });
                },
              ),

              ListTile(
                leading: const Icon(Icons.settings_remote),
                title: const Text('PiRowFlo-Steuerung'),
                selected: selectedPage == 1,
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    selectedPage = 1;
                  });
                },
              ),

              const Spacer(),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.settings),
                title: const Text('Einstellungen'),
                onTap: () {
                  Navigator.pop(context);
                  showSettings();
                },
              ),
            ],
          ),
        ),
      ),
      body: selectedPage == 0
          ? HomeScreen(
              running: running,
              activeMode: activeMode,
              smartRowConnected: smartRowConnected,
              smartRowReady: smartRowReady,
              calendarLoading: calendarLoading,
              calendarError: calendarError,
              todaysWorkout: todaysWorkout,
              nextWorkout: nextWorkout,
              onStartWorkout: startWorkout,
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: !configured
                    ? Center(
                        child: FilledButton.icon(
                          onPressed: showSettings,
                          icon: const Icon(Icons.settings),
                          label: const Text('Verbindung einrichten'),
                        ),
                      )
                    : ListView(
                        children: [
                          Text(
                            'Betriebsmodi',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          statusRow(
                            'BLE + ANT+',
                            states['combined'] ?? 'UNKNOWN',
                          ),
                          statusRow(
                            'Bluetooth',
                            states['bluetooth'] ?? 'UNKNOWN',
                          ),
                          statusRow('ANT+', states['ant'] ?? 'UNKNOWN'),
                          if (error != null) ...[
                            const SizedBox(height: 16),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  error!,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          FilledButton.icon(
                            onPressed:
                                loading || states['combined'] == 'RUNNING'
                                ? null
                                : () => post('/api/start/combined'),
                            icon: Icon(
                              states['combined'] == 'RUNNING'
                                  ? Icons.check_circle
                                  : Icons.bluetooth_connected,
                            ),
                            label: Text(
                              states['combined'] == 'RUNNING'
                                  ? 'BLE + ANT+ aktiv'
                                  : 'BLE + ANT+ starten',
                            ),
                          ),
                          const SizedBox(height: 12),

                          FilledButton.tonalIcon(
                            onPressed:
                                loading || states['bluetooth'] == 'RUNNING'
                                ? null
                                : () => post('/api/start/bluetooth'),
                            icon: Icon(
                              states['bluetooth'] == 'RUNNING'
                                  ? Icons.check_circle
                                  : Icons.bluetooth,
                            ),
                            label: Text(
                              states['bluetooth'] == 'RUNNING'
                                  ? 'Bluetooth aktiv'
                                  : 'Nur Bluetooth starten',
                            ),
                          ),
                          const SizedBox(height: 12),

                          FilledButton.tonalIcon(
                            onPressed: loading || states['ant'] == 'RUNNING'
                                ? null
                                : () => post('/api/start/ant'),
                            icon: Icon(
                              states['ant'] == 'RUNNING'
                                  ? Icons.check_circle
                                  : Icons.watch,
                            ),
                            label: Text(
                              states['ant'] == 'RUNNING'
                                  ? 'ANT+ aktiv'
                                  : 'Nur ANT+ starten',
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton.icon(
                            onPressed: loading || !running
                                ? null
                                : () => post('/api/restart'),
                            icon: const Icon(Icons.restart_alt),
                            label: const Text('Neu starten'),
                          ),
                          const SizedBox(height: 12),

                          OutlinedButton.icon(
                            onPressed:
                                loading || !smartRowConnected || !smartRowReady
                                ? null
                                : () => post('/api/reset'),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Training zurücksetzen'),
                          ),
                          const SizedBox(height: 12),

                          OutlinedButton.icon(
                            onPressed: loading || !running
                                ? null
                                : () => post('/api/stop'),
                            icon: const Icon(Icons.stop),
                            label: const Text('Stoppen'),
                          ),

                          if (loading) ...[
                            const SizedBox(height: 24),
                            const Center(child: CircularProgressIndicator()),
                          ],
                        ],
                      ),
              ),
            ),
    );
  }
}

class QrScannerPage extends StatefulWidget {
  const QrScannerPage({super.key});

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  bool handled = false;

  void handleBarcode(BarcodeCapture capture) {
    if (handled || capture.barcodes.isEmpty) {
      return;
    }

    final value = capture.barcodes.first.rawValue;

    if (value == null) {
      return;
    }

    try {
      final data = jsonDecode(value);

      final server = data['server']?.toString();
      final apiKey = data['apiKey']?.toString();

      if (server == null ||
          server.isEmpty ||
          apiKey == null ||
          apiKey.isEmpty) {
        throw const FormatException();
      }

      handled = true;

      Navigator.pop(context, {'server': server, 'apiKey': apiKey});
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kein gültiger PiRowFlo QR-Code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PiRowFlo verbinden')),
      body: MobileScanner(onDetect: handleBarcode),
    );
  }
}
