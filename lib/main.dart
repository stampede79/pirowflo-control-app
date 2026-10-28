import 'dart:async';
import 'dart:convert';

import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'screens/workout_screen.dart';
import 'models/workout.dart';

import 'screens/home_screen.dart';
import 'models/scheduled_workout.dart';
import 'screens/training_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'theme/pirowflo_theme.dart';
import 'widgets/pirowflo_drawer.dart';
import 'services/endurain_service.dart';
import 'models/endurain_summary.dart';
import 'models/endurain_activity.dart';
import 'screens/rowing_statistics_screen.dart';
import 'screens/welcome_screen.dart';
import 'utils/user_friendly_error.dart';
import 'models/recent_workout_match.dart';
import 'services/recent_workout_matcher.dart';
import 'models/training_history_entry.dart';
import 'services/training_history_merger.dart';
import 'models/training_plan_draft.dart';
import 'services/training_plan_service.dart';
import 'models/training_plan_review.dart';
import 'screens/coach_screen.dart';
import 'models/coach_overview.dart';
import 'services/workout_service.dart';
import 'models/workout_analysis.dart';
import 'services/training_history_service.dart';
import 'screens/control_screen.dart';
import 'screens/heart_rate_test_screen.dart';

void main() {
  runApp(const PiRowFloApp());
}

class PiRowFloApp extends StatelessWidget {
  const PiRowFloApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PiRow Coach',
      debugShowCheckedModeBanner: false,
      theme: PiRowFloTheme.light,
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

  final endurainServerController = TextEditingController(
    text: 'https://endurain.roderwieser.com',
  );
  final endurainUserController = TextEditingController();
  final endurainPasswordController = TextEditingController();

  bool endurainConnected = false;
  bool endurainLoading = false;
  String? endurainStatus;
  EndurainSummary? rowingSummary;
  CoachOverview? coachOverview;
  bool coachOverviewLoading = false;
  String? coachOverviewError;
  bool rowingStatisticsLoading = false;
  String? rowingStatisticsError;
  EndurainSummaryPeriod rowingStatisticsPeriod = EndurainSummaryPeriod.week;
  List<EndurainActivity> recentRowingActivities = [];
  List<RecentWorkoutMatch> recentWorkoutMatches = [];
  List<ScheduledWorkout> workoutHistory = [];
  List<EndurainActivity> historyActivities = [];
  List<TrainingHistoryEntry> trainingHistory = [];
  Map<int, WorkoutAnalysis> historyAnalyses = {};
  int historyDays = 30;
  bool historyLoadingMore = false;
  bool historyHasMore = true;
  TrainingPlanDraft? trainingPlanDraft;
  bool trainingPlanDraftLoading = false;
  String? trainingPlanDraftError;
  TrainingPlanReview? trainingPlanReview;
  bool trainingPlanReviewLoading = false;
  String? trainingPlanReviewError;

  String? calendarTestResult;
  int selectedPage = 0;

  bool loading = false;
  bool configured = false;
  String? error;

  bool appReady = false;

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

  // PiRowFlo-Hardwarestatus
  bool smartRowBluetoothAvailable = false;
  bool smartRowBluetoothPowered = false;
  bool smartRowBluetoothSoftBlocked = false;
  bool smartRowBluetoothHardBlocked = false;
  String? smartRowBluetoothAdapter;

  bool antAvailable = false;

  Timer? statusTimer;

  List<ScheduledWorkout> todaysWorkouts = [];
  bool calendarLoading = false;
  String? calendarError;
  List<ScheduledWorkout> upcomingWorkouts = [];
  List<ScheduledWorkout> recentWorkouts = [];

  ScheduledWorkout? get nextWorkout =>
      upcomingWorkouts.isEmpty ? null : upcomingWorkouts.first;
  @override
  void initState() {
    super.initState();
    initializeApp();
  }

  Future<void> loadHistoryAnalyses() async {
    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (server.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        historyAnalyses = {};
      });

      resolveTrainingHistory();
      return;
    }

    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final start = today.subtract(Duration(days: historyDays));
      final end = today.add(const Duration(days: 1));

      final service = TrainingHistoryService(server: server, apiKey: apiKey);

      final analyses = await service.getAnalyses(start: start, end: end);

      if (!mounted) return;

      setState(() {
        historyAnalyses = analyses;
      });

      resolveTrainingHistory();
    } catch (e, stackTrace) {
      debugPrint('loadHistoryAnalyses failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> applyTrainingPlanReview() async {
    final service = TrainingPlanService(
      server: serverController.text.trim(),
      apiKey: apiKeyController.text.trim(),
    );

    await service.applyReview();

    await Future.wait([
      loadTrainingPlanReview(),
      loadTodaysWorkout(),
      loadUpcomingWorkouts(),
      loadRecentWorkouts(),
    ]);
  }

  Future<void> loadTrainingPlanReview() async {
    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (!configured || server.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        trainingPlanReview = null;
        trainingPlanReviewError = null;
        trainingPlanReviewLoading = false;
      });

      return;
    }

    setState(() {
      trainingPlanReviewLoading = true;
      trainingPlanReviewError = null;
    });

    try {
      final service = TrainingPlanService(server: server, apiKey: apiKey);

      final review = await service.getReview();

      if (!mounted) return;

      setState(() {
        trainingPlanReview = review;
        trainingPlanReviewError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        trainingPlanReview = null;
        trainingPlanReviewError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          trainingPlanReviewLoading = false;
        });
      }
    }
  }

  Future<void> loadMoreHistory() async {
    if (historyLoadingMore || !historyHasMore) {
      return;
    }

    final previousCount = trainingHistory.length;

    setState(() {
      historyLoadingMore = true;
    });

    try {
      const stepDays = 30;
      const maxStepsPerLoad = 12;

      var foundOlderEntries = false;

      for (var step = 0; step < maxStepsPerLoad; step++) {
        historyDays += stepDays;

        await Future.wait([
          loadWorkoutHistory(),
          loadHistoryActivities(),
          loadHistoryAnalyses(),
        ]);

        if (!mounted) return;

        if (trainingHistory.length > previousCount) {
          foundOlderEntries = true;
          break;
        }
      }

      if (!mounted) return;

      setState(() {
        historyHasMore = foundOlderEntries;
      });
    } finally {
      if (mounted) {
        setState(() {
          historyLoadingMore = false;
        });
      }
    }
  }

  Future<void> loadTrainingPlanDraft() async {
    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (!configured || server.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        trainingPlanDraft = null;
        trainingPlanDraftError = null;
        trainingPlanDraftLoading = false;
      });

      return;
    }

    setState(() {
      trainingPlanDraftLoading = true;
      trainingPlanDraftError = null;
    });

    try {
      final service = TrainingPlanService(server: server, apiKey: apiKey);

      final draft = await service.getDraft();

      if (!mounted) return;

      setState(() {
        trainingPlanDraft = draft;
        trainingPlanDraftError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        trainingPlanDraft = null;
        trainingPlanDraftError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          trainingPlanDraftLoading = false;
        });
      }
    }
  }

  Future<void> loadHistoryActivities() async {
    final server = endurainServerController.text.trim();

    if (!endurainConnected || server.isEmpty) {
      if (!mounted) return;

      setState(() {
        historyActivities = [];
      });
      resolveTrainingHistory();

      return;
    }

    try {
      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final start = today.subtract(Duration(days: historyDays));
      final end = today.add(const Duration(days: 1));

      final service = EndurainService(server: server);

      final activities = await service.getRowingActivitiesForRange(start, end);

      if (!mounted) return;

      setState(() {
        historyActivities = activities;
      });
      resolveTrainingHistory();
    } catch (_) {
      // Historie darf den normalen App-Refresh nicht blockieren.
    }
  }

  Future<void> initializeApp() async {
    final minimumDisplayTime = Future<void>.delayed(
      const Duration(milliseconds: 1600),
    );

    try {
      await Future.wait([loadConfiguration(), minimumDisplayTime]);
    } finally {
      if (mounted) {
        setState(() {
          appReady = true;
        });
      }
    }
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    serverController.dispose();
    apiKeyController.dispose();
    endurainServerController.dispose();
    endurainUserController.dispose();
    endurainPasswordController.dispose();
    super.dispose();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      refreshStatus(),
      loadTodaysWorkout(),
      loadUpcomingWorkouts(),
      loadRecentWorkouts(),
      loadRecentActivitiesForMatching(),
      loadWorkoutHistory(),
      loadHistoryActivities(),
    ]);
  }

  Future<void> linkWorkoutToActivity(
    ScheduledWorkout scheduled,
    EndurainActivity activity,
  ) async {
    final workoutId = scheduled.id;

    if (workoutId == null) {
      throw Exception('Training besitzt keine PiRowFlo-ID.');
    }

    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (server.isEmpty || apiKey.isEmpty) {
      throw Exception('PiRowFlo-Konfiguration unvollständig.');
    }

    final response = await http
        .post(
          Uri.parse(
            '$server/api/workouts/'
            '$workoutId/activity-link',
          ),
          headers: {'X-API-Key': apiKey, 'Content-Type': 'application/json'},
          body: jsonEncode({'endurain_activity_id': activity.id}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${response.body}',
      );
    }

    await Future.wait([
      loadTodaysWorkout(),
      loadRecentWorkouts(),
      loadWorkoutHistory(),
    ]);

    resolveRecentWorkoutMatches();
    resolveTrainingHistory();
  }

  Future<void> loadWorkoutHistory() async {
    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (server.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        workoutHistory = [];
      });

      resolveTrainingHistory();
      return;
    }

    try {
      final service = WorkoutService(server: server, apiKey: apiKey);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final start = today.subtract(Duration(days: historyDays));

      final end = today.add(const Duration(days: 1));

      final workouts = await service.getScheduledWorkouts(
        start: start,
        end: end,
      );

      workouts.sort((a, b) => b.start.compareTo(a.start));

      if (!mounted) return;

      setState(() {
        workoutHistory = workouts;
      });

      resolveTrainingHistory();
    } catch (e, stackTrace) {
      debugPrint('loadWorkoutHistory failed: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> loadRecentWorkouts() async {
    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (server.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        recentWorkouts = [];
      });

      resolveRecentWorkoutMatches();
      return;
    }

    try {
      final service = WorkoutService(server: server, apiKey: apiKey);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final start = today.subtract(const Duration(days: 7));

      final end = today.add(const Duration(days: 1));

      final workouts = await service.getScheduledWorkouts(
        start: start,
        end: end,
      );

      workouts.sort((a, b) => b.start.compareTo(a.start));

      if (!mounted) return;

      setState(() {
        recentWorkouts = workouts;
      });

      resolveRecentWorkoutMatches();
    } catch (_) {
      // Recent-Matching darf die App nicht blockieren.
    }
  }

  Future<void> loadConfiguration() async {
    final server = await storage.read(key: 'server');
    final apiKey = await storage.read(key: 'apiKey');
    final endurainServer = await storage.read(key: 'endurainServer');
    final endurainUser = await storage.read(key: 'endurainUser');
    final endurainAccessToken = await storage.read(key: 'endurainAccessToken');
    final endurainRefreshToken = await storage.read(
      key: 'endurainRefreshToken',
    );

    if (!mounted) return;

    serverController.text = server ?? '';
    apiKeyController.text = apiKey ?? '';

    if (endurainServer != null && endurainServer.isNotEmpty) {
      endurainServerController.text = endurainServer;
    }

    endurainUserController.text = endurainUser ?? '';

    endurainConnected =
        endurainAccessToken != null &&
        endurainAccessToken.isNotEmpty &&
        endurainRefreshToken != null &&
        endurainRefreshToken.isNotEmpty;

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
    await loadUpcomingWorkouts();
    await loadRecentWorkouts();
    await loadRecentActivitiesForMatching();
    await loadWorkoutHistory();
    await loadHistoryActivities();
    await loadTrainingPlanDraft();
    await loadTrainingPlanReview();
    await loadHistoryAnalyses();
  }

  Future<void> saveConfiguration() async {
    var server = serverController.text.trim();

    if (server.endsWith('/')) {
      server = server.substring(0, server.length - 1);
    }

    serverController.text = server;

    await storage.write(key: 'server', value: server);

    await storage.write(key: 'apiKey', value: apiKeyController.text.trim());

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
    await loadUpcomingWorkouts();
    await loadRecentWorkouts();
    await loadRecentActivitiesForMatching();
    await loadWorkoutHistory();
    await loadHistoryActivities();
    await loadTrainingPlanDraft();
    await loadTrainingPlanReview();
    await loadHistoryAnalyses();
  }

  Map<String, String> get headers => {
    'X-API-Key': apiKeyController.text.trim(),
  };

  void resolveRecentWorkoutMatches() {
    final matches = RecentWorkoutMatcher.resolve(
      recentWorkouts,
      recentRowingActivities,
    );

    if (!mounted) return;

    setState(() {
      recentWorkoutMatches = matches;
    });
  }

  void resolveTrainingHistory() {
    final history = TrainingHistoryMerger.merge(
      workoutHistory,
      historyActivities,
      analyses: historyAnalyses,
    );

    if (!mounted) return;

    setState(() {
      trainingHistory = history;
    });
  }

  Future<void> loadCoachOverview() async {
    if (!configured) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      coachOverviewLoading = true;
      coachOverviewError = null;
    });

    try {
      final response = await http
          .get(
            Uri.parse('${serverController.text}/api/coach/overview'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw const FormatException('Ungültige Coach-Antwort');
      }

      final overview = CoachOverview.fromJson(data);

      if (!mounted) {
        return;
      }

      setState(() {
        coachOverview = overview;
        coachOverviewError = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        coachOverviewError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          coachOverviewLoading = false;
        });
      }
    }
  }

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

      final hardware = data['hardware'];
      final smartRowBluetooth = hardware?['smartrow_bluetooth'];
      final antHardware = hardware?['ant'];

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

        smartRowBluetoothAvailable = smartRowBluetooth?['available'] == true;
        smartRowBluetoothPowered = smartRowBluetooth?['powered'] == true;
        smartRowBluetoothSoftBlocked =
            smartRowBluetooth?['soft_blocked'] == true;
        smartRowBluetoothHardBlocked =
            smartRowBluetooth?['hard_blocked'] == true;
        smartRowBluetoothAdapter = smartRowBluetooth?['adapter']?.toString();

        antAvailable = antHardware?['available'] == true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = UserFriendlyError.piRowFlo(e);
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

      final hardware = data['hardware'];
      final smartRowBluetooth = hardware?['smartrow_bluetooth'];
      final antHardware = hardware?['ant'];

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

        smartRowBluetoothAvailable = smartRowBluetooth?['available'] == true;
        smartRowBluetoothPowered = smartRowBluetooth?['powered'] == true;
        smartRowBluetoothSoftBlocked =
            smartRowBluetooth?['soft_blocked'] == true;
        smartRowBluetoothHardBlocked =
            smartRowBluetooth?['hard_blocked'] == true;
        smartRowBluetoothAdapter = smartRowBluetooth?['adapter']?.toString();

        antAvailable = antHardware?['available'] == true;
      });
    } catch (_) {
      // Hintergrund-Refresh soll die Oberfläche nicht mit Fehlern fluten.
    }
  }

  Future<void> connectEndurain() async {
    var server = endurainServerController.text.trim();
    final username = endurainUserController.text.trim();
    final password = endurainPasswordController.text;

    if (server.endsWith('/')) {
      server = server.substring(0, server.length - 1);
    }

    if (server.isEmpty || username.isEmpty || password.isEmpty) {
      setState(() {
        endurainStatus = 'Server, Benutzername und Passwort werden benötigt.';
      });
      return;
    }

    setState(() {
      endurainLoading = true;
      endurainStatus = null;
    });

    try {
      final service = EndurainService(server: server);

      final session = await service.login(
        username: username,
        password: password,
      );

      await service.saveSession(session);

      // Passwort nach erfolgreichem Login sofort verwerfen.
      endurainPasswordController.clear();

      if (!mounted) return;

      setState(() {
        endurainServerController.text = server;
        endurainConnected = true;
        endurainStatus = 'Mit Endurain verbunden.';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        endurainConnected = false;
        endurainStatus = 'Endurain-Verbindung fehlgeschlagen: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          endurainLoading = false;
        });
      }
    }
  }

  Future<void> disconnectEndurain() async {
    await storage.delete(key: 'endurainAccessToken');
    await storage.delete(key: 'endurainRefreshToken');
    await storage.delete(key: 'endurainSessionId');

    endurainPasswordController.clear();

    if (!mounted) return;

    setState(() {
      endurainConnected = false;
      endurainStatus = 'Endurain-Verbindung getrennt.';
    });
  }

  Future<void> loadRecentActivitiesForMatching() async {
    final server = endurainServerController.text.trim();

    if (!endurainConnected || server.isEmpty) {
      if (!mounted) return;

      setState(() {
        recentRowingActivities = [];
      });

      resolveRecentWorkoutMatches();
      return;
    }

    try {
      final service = EndurainService(server: server);

      final activities = await service.getRecentRowingActivities(limit: 20);

      if (!mounted) return;

      setState(() {
        recentRowingActivities = activities;
      });

      resolveRecentWorkoutMatches();
    } catch (_) {
      // Matching darf den normalen App-Refresh nicht blockieren.
      // Die Statistikseite zeigt ihre eigenen Endurain-Fehler weiterhin separat.
    }
  }

  Future<void> loadRowingStatistics() async {
    final server = endurainServerController.text.trim();

    if (!endurainConnected || server.isEmpty) {
      if (!mounted) return;

      setState(() {
        rowingStatisticsError = 'Endurain ist noch nicht verbunden.';
      });

      return;
    }

    setState(() {
      rowingStatisticsLoading = true;
      rowingStatisticsError = null;
    });

    try {
      final service = EndurainService(server: server);

      final results = await Future.wait([
        service.getRowingSummary(rowingStatisticsPeriod),
        service.getRecentRowingActivities(),
      ]);

      final summary = results[0] as EndurainSummary;
      final activities = results[1] as List<EndurainActivity>;

      if (!mounted) return;

      setState(() {
        rowingSummary = summary;
        recentRowingActivities = activities;
        rowingStatisticsError = null;
        resolveRecentWorkoutMatches();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        rowingStatisticsError = UserFriendlyError.endurain(e);
      });
    } finally {
      if (mounted) {
        setState(() {
          rowingStatisticsLoading = false;
        });
      }
    }
  }

  Future<void> openWorkoutDetail(ScheduledWorkout scheduled) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutDetailScreen(
          workout: scheduled.workout,
          scheduledDate: scheduled.start,
        ),
      ),
    );
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
      return '${smartRowBluetoothAdapter!} bereit';
    }

    return 'Bereit';
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

  Future<void> decideCoachRecommendation(
    int recommendationId,
    String decision,
  ) async {
    final response = await http
        .post(
          Uri.parse(
            '${serverController.text}'
            '/api/coach/recommendations/'
            '$recommendationId/decision',
          ),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({'decision': decision}),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${response.body}',
      );
    }

    await loadCoachOverview();
  }

  Future<void> loadTodaysWorkout() async {
    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (server.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        todaysWorkouts = [];
      });

      return;
    }

    setState(() {
      calendarLoading = true;
      calendarError = null;
    });

    try {
      final service = WorkoutService(server: server, apiKey: apiKey);

      final now = DateTime.now();

      final today = DateTime(now.year, now.month, now.day);

      final tomorrow = today.add(const Duration(days: 1));

      final workouts = await service.getScheduledWorkouts(
        start: today,
        end: tomorrow,
      );

      if (!mounted) return;

      setState(() {
        todaysWorkouts = workouts;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        calendarError =
            'Trainingsdaten konnten nicht '
            'geladen werden: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          calendarLoading = false;
        });
      }
    }
  }

  Future<void> loadUpcomingWorkouts() async {
    final server = serverController.text.trim();
    final apiKey = apiKeyController.text.trim();

    if (server.isEmpty || apiKey.isEmpty) {
      if (!mounted) return;

      setState(() {
        upcomingWorkouts = [];
      });

      return;
    }

    try {
      final service = WorkoutService(server: server, apiKey: apiKey);

      final now = DateTime.now();

      // Kommende Trainings beginnen morgen.
      final start = DateTime(now.year, now.month, now.day + 1);

      // Bis zum Ende des Folgemonats laden.
      final end = now.month == 12
          ? DateTime(now.year + 1, 2, 1)
          : now.month == 11
          ? DateTime(now.year + 1, 1, 1)
          : DateTime(now.year, now.month + 2, 1);

      final workouts = await service.getScheduledWorkouts(
        start: start,
        end: end,
      );

      if (!mounted) return;

      setState(() {
        upcomingWorkouts = workouts;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        upcomingWorkouts = [];
      });
    }
  }

  Future<void> startTrainingFromHome() async {
    final availableToday = todaysWorkouts
        .where(
          (scheduled) =>
              !scheduled.isCompleted &&
              !scheduled.isSkipped &&
              !scheduled.isMissed,
        )
        .toList();

    if (availableToday.isEmpty) {
      await startFreeWorkout();
      return;
    }

    final scheduled = availableToday.first;

    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Training starten',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Für heute ist „${scheduled.workout.name}“ geplant.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context, 'planned'),
                icon: const Icon(Icons.event_available_outlined),
                label: Text('${scheduled.workout.name} starten'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context, 'free'),
                icon: const Icon(Icons.rowing),
                label: const Text('Freies Training starten'),
              ),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Abbrechen'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    switch (choice) {
      case 'planned':
        await startWorkout(scheduled.workout);
      case 'free':
        await startFreeWorkout();
    }
  }

  Future<void> startFreeWorkout() async {
    await startWorkout(Workout.free());
  }

  Future<void> startWorkout(Workout workout) async {
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
          workout: workout,
          server: serverController.text,
          apiKey: apiKeyController.text,
        ),
      ),
    );
  }

  Future<void> changeRowingStatisticsPeriod(
    EndurainSummaryPeriod period,
  ) async {
    if (period == rowingStatisticsPeriod) {
      return;
    }

    setState(() {
      rowingStatisticsPeriod = period;
      rowingSummary = null;
    });

    await loadRowingStatistics();
  }

  Future<void> applyTrainingPlanDraft() async {
    final service = TrainingPlanService(
      server: serverController.text.trim(),
      apiKey: apiKeyController.text.trim(),
    );

    await service.applyDraft();

    await Future.wait([
      loadTrainingPlanDraft(),
      loadTrainingPlanReview(),
      loadTodaysWorkout(),
      loadUpcomingWorkouts(),
      loadWorkoutHistory(),
    ]);
  }

  Future<void> answerAvailability(int recommendationId, String status) async {
    final response = await http
        .post(
          Uri.parse(
            '${serverController.text}'
            '/api/coach/recommendations/'
            '$recommendationId/availability',
          ),
          headers: {...headers, 'Content-Type': 'application/json'},
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 10));

    if (response.statusCode != 200) {
      throw Exception(
        'HTTP ${response.statusCode}: '
        '${response.body}',
      );
    }

    await loadCoachOverview();
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

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Endurain',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: endurainServerController,
                  decoration: const InputDecoration(
                    labelText: 'Endurain-Server',
                    hintText: 'https://endurain.example.com',
                  ),
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                ),

                const SizedBox(height: 12),

                TextField(
                  controller: endurainUserController,
                  decoration: const InputDecoration(
                    labelText: 'Endurain-Benutzer',
                  ),
                  autocorrect: false,
                ),

                const SizedBox(height: 12),

                if (!endurainConnected)
                  TextField(
                    controller: endurainPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Endurain-Passwort',
                    ),
                    obscureText: true,
                    autocorrect: false,
                  ),

                const SizedBox(height: 16),

                if (endurainConnected)
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Mit Endurain verbunden',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(
                        Icons.circle_outlined,
                        color: Theme.of(context).colorScheme.outline,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Nicht verbunden',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: endurainConnected
                      ? OutlinedButton.icon(
                          onPressed: endurainLoading
                              ? null
                              : () async {
                                  await disconnectEndurain();
                                },
                          icon: const Icon(Icons.link_off),
                          label: const Text('Verbindung trennen'),
                        )
                      : FilledButton.icon(
                          onPressed: endurainLoading
                              ? null
                              : () async {
                                  await connectEndurain();
                                },
                          icon: endurainLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.link),
                          label: Text(
                            endurainLoading
                                ? 'Verbinde …'
                                : 'Mit Endurain verbinden',
                          ),
                        ),
                ),

                if (endurainStatus != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    endurainStatus!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
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
    if (!appReady) {
      return const WelcomeScreen();
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (selectedPage) {
          0 => 'PiRow Coach',
          1 => 'Training',
          2 => 'Coach',
          3 => 'Statistiken',
          4 => 'Steuerung',
          _ => 'PiRow Coach',
        }),
        actions: [
          IconButton(
            onPressed:
                loading || rowingStatisticsLoading || coachOverviewLoading
                ? null
                : switch (selectedPage) {
                    2 => loadCoachOverview,
                    3 => loadRowingStatistics,
                    _ => refreshAll,
                  },
            icon: const Icon(Icons.refresh),
            tooltip: 'Aktualisieren',
          ),
        ],
      ),
      drawer: PiRowFloDrawer(
        selectedPage: selectedPage,
        onSelectPage: (page) {
          Navigator.pop(context);

          setState(() {
            selectedPage = page;
          });

          if (page == 2) {
            loadCoachOverview();
          }

          if (page == 3) {
            loadRowingStatistics();
          }
        },
        onSettings: () {
          Navigator.pop(context);
          showSettings();
        },
        onHeartRateTest: () {
          Navigator.pop(context);

          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const HeartRateTestScreen()),
          );
        },
      ),
      body: switch (selectedPage) {
        0 => HomeScreen(
          running: running,
          activeMode: activeMode,
          smartRowConnected: smartRowConnected,
          smartRowReady: smartRowReady,
          calendarLoading: calendarLoading,
          calendarError: calendarError,
          todaysWorkouts: todaysWorkouts,
          nextWorkout: nextWorkout,
          onStartTraining: startTrainingFromHome,
          onOpenWorkout: openWorkoutDetail,
        ),

        1 => TrainingScreen(
          todaysWorkouts: todaysWorkouts,
          upcomingWorkouts: upcomingWorkouts,
          trainingHistory: trainingHistory,
          calendarLoading: calendarLoading,
          calendarError: calendarError,
          endurainServer: endurainServerController.text.trim(),
          server: serverController.text.trim(),
          apiKey: apiKeyController.text.trim(),
          onStartWorkout: startWorkout,
          historyLoadingMore: historyLoadingMore,
          onLoadMoreHistory: loadMoreHistory,
          historyHasMore: historyHasMore,
          onOpenWorkout: openWorkoutDetail,
          onApplyTrainingPlan: applyTrainingPlanDraft,
          onLinkWorkout: (match) async {
            final activity = match.candidate?.activity;

            if (activity == null) {
              return;
            }

            await linkWorkoutToActivity(match.scheduledWorkout, activity);
          },
          trainingPlanDraft: trainingPlanDraft,
          trainingPlanDraftLoading: trainingPlanDraftLoading,
          trainingPlanReview: trainingPlanReview,
          trainingPlanReviewLoading: trainingPlanReviewLoading,
          onApplyTrainingPlanReview: applyTrainingPlanReview,
        ),

        2 => CoachScreen(
          overview: coachOverview,
          loading: coachOverviewLoading,
          error: coachOverviewError,
          onRefresh: loadCoachOverview,
          onAnswerAvailability: answerAvailability,
          onDecideRecommendation: decideCoachRecommendation,
        ),

        3 => RowingStatisticsScreen(
          summary: rowingSummary,
          loading: rowingStatisticsLoading,
          error: rowingStatisticsError,
          period: rowingStatisticsPeriod,
          onPeriodChanged: changeRowingStatisticsPeriod,
          onRefresh: loadRowingStatistics,
        ),
        4 => ControlScreen(
          configured: configured,
          running: running,
          activeMode: activeMode,
          smartRowConnected: smartRowConnected,
          smartRowReady: smartRowReady,
          smartRowBluetoothStatusText: smartRowBluetoothStatusText,
          smartRowBluetoothHealthy: smartRowBluetoothHealthy,
          bluetoothRequired: bluetoothRequired,
          antAvailable: antAvailable,
          antRequired: antRequired,
          loading: loading,
          error: error,
          states: states,
          onSettings: showSettings,
          onPost: post,
        ),
        _ => const SizedBox.shrink(),
      },
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
