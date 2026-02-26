import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routine/core/services/app_lock_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;

  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final AppLockService _lockService = AppLockService();

  static const String _prefKey = "app_lock_enabled";

  bool _isAuthenticating = false;
  bool _lockEnabled = false;
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefKey) ?? false;
    if (!mounted) return;
    setState(() {
      _lockEnabled = enabled;
      _loading = false;
    });

    // if (_lockEnabled) {
    //   await _authenticate();
    // } else {
    //   widget.onUnlocked();
    // }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || !_lockEnabled) return;

    setState(() {
      _isAuthenticating = true;
      _errorMessage = null;
    });

    final success = await _lockService.authenticate(
      reason: 'Authenticate to unlock the app',
    ).catchError((e) {
      // in case authenticate throws unexpectedly
      return false;
    });

    if (!mounted) return;

    setState(() => _isAuthenticating = false);

    if (success) {
      widget.onUnlocked();
    } else {
      // show user-friendly message — they can retry or go back
      setState(() {
        _errorMessage = 'Authentication failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return WillPopScope(
      // block back button while locked
      onWillPop: () async => true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  "App Locked",
                  style: TextStyle(fontSize: 22, color: Colors.white),
                ),
                const SizedBox(height: 20),
                if (_isAuthenticating)
                  const CircularProgressIndicator(color: Colors.white)
                else
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: const Text("Unlock"),
                  ),
                const SizedBox(height: 12),
                if (_errorMessage != null) ...[
                  Text(_errorMessage!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                ],
                TextButton(
                  onPressed: () async {
                    // optional: user can disable lock from here if they know device is not working
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool(_prefKey, false);
                    if (!mounted) return;
                    widget.onUnlocked();
                  },
                  child: const Text('Disable App Lock', style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}