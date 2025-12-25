
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/main_tab_page.dart';
import 'pages/auth_page.dart';
import 'services/fb_auth.dart';

// Entry point of the application.
void main() {
  // We no longer need WidgetsFlutterBinding.ensureInitialized() here,
  // as it will be called within our new initializer widget.
  runApp(const AppInitializer());
}

// A data class to hold information about each initialization step.
class _LogEntry {
  final String message;
  final LogStatus status;
  final String? error;

  _LogEntry(this.message, {this.status = LogStatus.pending, this.error});
}

// Enum to represent the status of a log entry.
enum LogStatus { pending, running, success, failure }

// AppInitializer: A new root widget that handles the initialization process
// and displays a real-time, scrollable log.
class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  final List<_LogEntry> _logs = [];
  bool _initializationFailed = false;
  Key _key = UniqueKey(); // Used to force a re-run of the initialization.

  // This method runs the initialization sequence.
  Future<void> _runInitialization() async {
    // --- Step 1: Initialize Flutter Binding ---
    _addLog('Initializing Flutter Engine...', status: LogStatus.running);
    try {
      WidgetsFlutterBinding.ensureInitialized();
      _updateLog(0, status: LogStatus.success);
    } catch (e) {
      _updateLog(0, status: LogStatus.failure, error: e.toString());
      setState(() => _initializationFailed = true);
      return; // Stop initialization on failure.
    }

    // --- Step 2: Load Environment Variables ---
    _addLog('Loading .env file...');
    await _runStep(
      () => dotenv.load(fileName: '.env'),
      'Loaded .env file successfully.',
      'Failed to load .env file.',
    );
    if (_initializationFailed) return;

    // --- Step 3: Initialize Firebase ---
    _addLog('Initializing Firebase...');
    await _runStep(
      () async {
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
        } else {
          // This case should ideally not happen with the check, but we log it.
          debugPrint("Firebase app already initialized.");
        }
      },
      'Firebase initialized successfully.',
      'Failed to initialize Firebase.',
    );
    if (_initializationFailed) return;

    // --- Step 4: Request Photo Permissions ---
    _addLog('Requesting photo library permissions...');
    await _runStep(
      () => PhotoManager.requestPermissionExtend(),
      'Photo library permissions granted.',
      'Failed to get photo library permissions.',
    );
    if (_initializationFailed) return;

    // --- All steps succeeded: Navigate to the main app ---
    if (!_initializationFailed) {
      _addLog('All initializations complete. Starting app...', status: LogStatus.success);
      // A short delay to allow the user to see the final success message.
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MyApp()),
        );
      }
    }
  }

  // Helper method to run an individual async step and update logs.
  Future<void> _runStep(
    Future<void> Function() step,
    String successMessage,
    String failureMessage,
  ) async {
    final logIndex = _logs.length - 1;
    setState(() => _logs[logIndex] = _LogEntry(failureMessage, status: LogStatus.running));
    try {
      await step();
      setState(() => _logs[logIndex] = _LogEntry(successMessage, status: LogStatus.success));
    } catch (e) {
      setState(() {
        _logs[logIndex] = _LogEntry(failureMessage, status: LogStatus.failure, error: e.toString());
        _initializationFailed = true;
      });
    }
  }

  // Helper methods to manage the log list.
  void _addLog(String message, {LogStatus status = LogStatus.pending}) {
    setState(() => _logs.add(_LogEntry(message, status: status)));
  }

  void _updateLog(int index, {required LogStatus status, String? error}) {
    setState(() => _logs[index] = _LogEntry(_logs[index].message, status: status, error: error));
  }

  void _retryInitialization() {
    setState(() {
      _logs.clear();
      _initializationFailed = false;
      _key = UniqueKey(); // Changing the key will re-create and re-run the FutureBuilder
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FutureBuilder(
          key: _key,
          future: _runInitialization(),
          builder: (context, snapshot) {
            // Even if the future is done, we build the UI based on the log state.
            // This handles both in-progress and failed states.
            return SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // You can add a logo here if you have one
                        // const FlutterLogo(size: 40),
                        // const SizedBox(width: 16),
                        Text(
                          'Starting Phohotty2...',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  // Scrollable Log View
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return _LogTile(log: log);
                      },
                    ),
                  ),
                  // Retry Button
                  if (_initializationFailed)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry Initialization'),
                        onPressed: _retryInitialization,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// A dedicated widget to display a single log entry.
class _LogTile extends StatelessWidget {
  final _LogEntry log;
  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    Widget icon;
    Color color;

    switch (log.status) {
      case LogStatus.pending:
        icon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey));
        color = Colors.grey;
        break;
      case LogStatus.running:
        icon = const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2));
        color = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
        break;
      case LogStatus.success:
        icon = const Icon(Icons.check_circle, color: Colors.green, size: 18);
        color = Colors.green;
        break;
      case LogStatus.failure:
        icon = const Icon(Icons.error, color: Colors.red, size: 18);
        color = Colors.red;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 12),
              Expanded(
                child: Text(log.message, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          if (log.status == LogStatus.failure && log.error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, left: 30.0),
              child: Text(
                log.error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

// The original MyApp widget. It is now only built and displayed after
// a successful initialization.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<FbUser?>(
        stream: FbAuth.instance.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: Something went wrong with Firebase authentication. \n\n${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          final user = snapshot.data;
          if (user == null) {
            return const AuthPage();
          } else {
            return const MainTabPage();
          }
        },
      ),
    );
  }
}
