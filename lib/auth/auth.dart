import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
// import 'package:local_auth_ios/local_auth_ios.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<({bool available, List types})> checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      final available = canCheck || isSupported;
      final types = available ? await _auth.getAvailableBiometrics() : [];

      return (available: available, types: types);
    } on PlatformException catch (e) {
      print('Biometric check error: ${e.message}');
      return (available: false, types: []);
    }
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Authenticate to access your passwords',
        authMessages: [
          const AndroidAuthMessages(
            signInTitle: 'Authentication required',
            biometricHint: '',
            cancelButton: 'Cancel',
          ),
          // const IOSAuthMessages(
          //   cancelButton: 'Cancel',
          //   lockOut: 'Please authenticate to continue',
          // ),
        ],
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Authentication error: ${e.message}');
      if (e.code == 'NotAvailable') {
        throw Exception('Biometric authentication not available');
      } else if (e.code == 'NotEnrolled') {
        throw Exception('No biometrics enrolled on this device');
      } else if (e.code == 'LockedOut') {
        throw Exception('Too many failed attempts. Try again later.');
      }
      return false;
    }
  }
}
