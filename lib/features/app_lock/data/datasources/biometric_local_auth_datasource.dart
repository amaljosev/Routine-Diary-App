import 'dart:developer';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricLocalAuthDataSource {
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
      return false;
    } catch (e) {
      log(e.toString());
      return false;
    }
  }
}