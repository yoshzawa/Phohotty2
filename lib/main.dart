
import 'dart:async';
import 'dart:ui'; // Required for PlatformDispatcher
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart'; // Import Crashlytics
import 'firebase_options.dart';
import 'pages/main_tab_page.dart';
import 'pages/auth_page.dart';
import 'services/fb_auth.dart';

// Entry point of the application.
void main() {
  // Use runZonedGuarded to catch all errors, including async ones
  runZonedGuarded<Future<void>>(() async {
    // --- Step 1: Initialize Flutter Binding ---
    WidgetsFlutterBinding.ensureInitialized();
    
    // --- Step 2: Initialize Firebase ---
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // --- Step 3: Initialize Crashlytics ---
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true; // Mark as handled
    };

    // --- Step 4: Run the app ---
    runApp(const AppInitializer());
  }, 
  // This is the error handler for the zone.
  (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}


// Data class for log entries
class _LogEntry {
  final String message;
  final LogStatus status;
  final String? error;

  _LogEntry(this.message, {this.status = LogStatus.pending, this.error});
}

// Enum for log status
enum LogStatus { pending, running, success, failure }

// The root widget that handles the initialization process
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  late final Future<bool> _initializationFuture;

  final List<_LogEntry> _logs = [];
  bool _initializationFailed = false;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _runInitialization();
  }

  // This method now returns a boolean indicating success or failure.
  Future<bool> _runInitialization() async {
    setState(() {
      _logs.clear();
      _initializationFailed = false;
    });

    // NOTE: Firebase and WidgetBinding are now initialized in main() before this widget runs.
    _addLog('Flutter Engine and Firebase Core initialized.', status: LogStatus.success);

    // --- Step 1: Load Environment Variables ---

    if (!await _runStep(
      'Loading .env file...',
      () async => await dotenv.load(fileName: '.env'),
    )) return false;

    // --- Step 2: Request Photo Permissions ---

    if (!await _runStep(
      'Requesting photo library permissions...',
      () async => await PhotoManager.requestPermissionExtend(),
    )) return false;

    // --- All steps succeeded ---

    _addLog('All initializations complete. Starting app...', status: LogStatus.success);
    return true;
  }

  // Helper method to run an individual step and update logs.
  Future<bool> _runStep(String message, Future<void> Function() step) async {
    final logIndex = _addLog(message, status: LogStatus.running);
    try {
      await step();
      _updateLog(logIndex, status: LogStatus.success);
      return true;
    } catch (e, s) {
      _updateLog(logIndex, status: LogStatus.failure, error: e.toString());
      // Report this specific initialization error to Crashlytics
      FirebaseCrashlytics.instance.recordError(e, s, reason: 'A step in _runInitialization failed');
      setState(() => _initializationFailed = true);
      return false;
    }
  }

  int _addLog(String message, {LogStatus status = LogStatus.pending}) {
    final entry = _LogEntry(message, status: status);
    setState(() => _logs.add(entry));
    return _logs.length - 1;
  }

  void _updateLog(int index, {required LogStatus status, String? error}) {
    setState(() => _logs[index] = _LogEntry(_logs[index].message, status: status, error: error));
  }

  void _retryInitialization() {
    setState(() {
      _initializationFuture = _runInitialization();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: FutureBuilder<bool>(
            future: _initializationFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                final success = snapshot.data ?? false;
                if (success) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                       Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyApp()),
                      );
                    }
                  });
                }
              }
              
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text('Starting Phohotty2...', style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) => _LogTile(log: _logs[index]),
                    ),
                  ),
                  if (_initializationFailed)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Initialization'),
                        onPressed: _retryInitialization,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// UI widget for a single log entry
class _LogTile extends StatelessWidget {
  final _LogEntry log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    Widget icon;
    switch (log.status) {
      case LogStatus.running:
        icon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
        break;
      case LogStatus.success:
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
        break;
      case LogStatus.failure:
        icon = const Icon(Icons.error, color: Colors.red, size: 18);
        break;
      default:
        icon = const Icon(Icons.hourglass_empty, color: Colors.grey, size: 18);
        break;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [icon, const SizedBox(width: 12), Expanded(child: Text(log.message))]),
          if (log.status == LogStatus.failure && log.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 30.0),
              child: Text(log.error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
            ),
        ],
      ),
    );
  }
}


// The original MyApp widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<FbUser?>(
        stream: FbAuth.instance.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasError) {
            return Scaffold(body: Center(child: Text('Error: ${snapshot.error}')));
          }
          return snapshot.hasData ? const MainTabPage() : const AuthPage();
        },
      ),
    );
  }
}
