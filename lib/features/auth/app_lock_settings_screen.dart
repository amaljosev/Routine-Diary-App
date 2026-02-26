import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockSettingsScreen extends StatefulWidget {
  const AppLockSettingsScreen({super.key});

  @override
  State<AppLockSettingsScreen> createState() =>
      _AppLockSettingsScreenState();
}

class _AppLockSettingsScreenState extends State<AppLockSettingsScreen> {
  final LocalAuthentication _auth = LocalAuthentication();

  static const String _prefKey = "app_lock_enabled";

  bool _isEnabled = false;
  bool _isLoading = true;
  bool _deviceSupported = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final isSupported = await _auth.isDeviceSupported();
    final canCheck = await _auth.canCheckBiometrics;
    final biometrics = await _auth.getAvailableBiometrics();

    setState(() {
      _isEnabled = prefs.getBool(_prefKey) ?? false;
      _deviceSupported = isSupported;
      _biometricAvailable = canCheck && biometrics.isNotEmpty;
      _isLoading = false;
    });
  }

 Future<bool> _authenticate() async {
  try {
    final isSupported = await _auth.isDeviceSupported();
    if (!isSupported) {
      _showMessage("Device not supported");
      return false;
    }

    final result = await _auth.authenticate(
      localizedReason: "Authenticate to enable App Lock",
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );

    return result;
  } catch (e) {
    log(e.toString());
    _showMessage("Auth error: $e");
    return false;
  }
}

  Future<void> _onToggle(bool value) async {
    if (!_deviceSupported) {
      _showMessage("Device authentication not supported");
      return;
    }

    if (value) {
      final success = await _authenticate();

      if (!success) {
        _showMessage("Authentication failed");
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);

    setState(() {
      _isEnabled = value;
    });

    _showMessage(
      value ? "App Lock Enabled" : "App Lock Disabled",
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _testAuthentication() async {
    final success = await _authenticate();

    _showMessage(
      success ? "Authentication successful" : "Authentication failed",
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("App Lock Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _isEnabled,
            onChanged: _onToggle,
            title: const Text("Enable App Lock"),
            subtitle: const Text(
              "Require authentication when app resumes",
            ),
          ),

          const SizedBox(height: 10),

          if (!_deviceSupported)
            const Text(
              "Device authentication not supported.",
              style: TextStyle(color: Colors.red),
            ),

          if (_deviceSupported && !_biometricAvailable)
            const Text(
              "No biometrics enrolled. You can still use device PIN/password.",
              style: TextStyle(color: Colors.orange),
            ),

          if (_isEnabled) ...[
            const Divider(),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _testAuthentication,
              icon: const Icon(Icons.fingerprint),
              label: const Text("Test Authentication"),
            ),
          ],
        ],
      ),
    );
  }
}