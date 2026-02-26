import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:routine/features/auth/lock_screen.dart';

class AppWrapper extends StatefulWidget {
  final Widget child;
  /// If true, the wrapper will NOT show lock overlay immediately even if lock is enabled.
  final bool initiallyUnlocked;

  const AppWrapper({
    super.key,
    required this.child,
    this.initiallyUnlocked = false,
  });

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper>
    with WidgetsBindingObserver {
  static const String _prefKey = "app_lock_enabled";

  bool _isLocked = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLockState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _loadLockState() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_prefKey) ?? false;

    if (!mounted) return;

    setState(() {
      _isLocked = false; // DO NOT auto lock on load
      _loading = false;
    });
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _isLocked = false;
      _loading = false;
    });
  }
}

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    // Re-check preference on resume. This enforces lock when app returns from background.
    if (state == AppLifecycleState.resumed) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final enabled = prefs.getBool(_prefKey) ?? false;
        if (!mounted) return;
        setState(() => _isLocked = enabled);
      } catch (_) {
        // ignore
      }
    }
  }

  void _unlock() {
    if (!mounted) return;
    setState(() => _isLocked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        
      ],
    );
  }
}