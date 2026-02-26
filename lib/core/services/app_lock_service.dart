import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class AppLockService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// Returns true if device supports any authentication (biometric or device credential)
  Future<bool> canAuthenticate() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      final biometrics = await _auth.getAvailableBiometrics();
      return canCheck || biometrics.isNotEmpty;
    } catch (e) {
      // Log if you want
      return false;
    }
  }

  /// Attempt authentication. Returns true on success, false on failure or error.
  Future<bool> authenticate({String reason = 'Authenticate to continue'}) async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;

      final result = await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
       
      );

      return result;
    } on PlatformException catch (e) {
      log(e.toString());
      // handle platform-specific issues gracefully
      // e.code may be 'NotAvailable', 'LockedOut', 'PermanentlyLockedOut', 'UserCancelled', 'PasscodeNotSet', 'NotEnrolled'
      // You can map these codes to user-friendly messages in the UI.
      // print('LocalAuth platform error: ${e.code} ${e.message}');
      return false;
    } catch (e) {
       log(e.toString());
      // generic failure
      // print('LocalAuth unknown error: $e');
      return false;
    }
  }
}