import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

final biometricAuthServiceProvider = Provider<BiometricAuthService>((ref) {
  return BiometricAuthService();
});

class BiometricAuthService {
  final LocalAuthentication _localAuthentication = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuthentication.canCheckBiometrics;
      final isSupported = await _localAuthentication.isDeviceSupported();
      if (!canCheck || !isSupported) {
        return false;
      }

      final availableBiometrics = await _localAuthentication.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    try {
      return await _localAuthentication.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
