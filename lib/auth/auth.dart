import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const Color background = Color(0xFF08110E);
  static const Color surface = Color(0xFF111E19);
  static const Color green = Color(0xFF10B981);
  static const Color muted = Color(0xFF91A39A);

  static Future<({bool available, List<BiometricType> types})>
  checkBiometrics() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) {
        return (available: false, types: <BiometricType>[]);
      }

      final types = await _auth.getAvailableBiometrics();

      return (available: types.isNotEmpty, types: types);
    } on PlatformException catch (e) {
      debugPrint('Biometric check failed: ${e.message}');
      return (available: false, types: <BiometricType>[]);
    }
  }

  static Future<bool> authenticate({
    String reason = 'Authenticate to continue',
  }) async {
    return _auth.authenticate(
      localizedReason: reason,
      authMessages: const [
        AndroidAuthMessages(
          signInTitle: 'Vault Authentication',
          biometricHint: 'Verify your identity',
          cancelButton: 'Cancel',
        ),
      ],
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
  }

  static Future<bool> verifyMasterPassword(String password) async {
    try {
      final storedPassword =
      await _storage.read(key: 'master_password');

      return storedPassword != null &&
          storedPassword == password;
    } catch (e) {
      debugPrint('Master password verification failed: $e');
      return false;
    }
  }

  static Future<bool> authenticateForSensitiveAction(
      BuildContext context, {
        String reason = 'Enter your master password to continue.',
      }) async {
    final prefs = await SharedPreferences.getInstance();
    final useBiometrics =
        prefs.getBool('use_biometrics') ?? false;

    if (useBiometrics) {
      final biometric = await checkBiometrics();

      if (biometric.available) {
        try {
          final success = await authenticate(reason: reason);
          if (success) return true;
        } catch (e) {
          debugPrint('Biometric authentication failed: $e');
        }
      }

      if (!context.mounted) return false;

      return _showMasterPasswordDialog(
        context,
        message: 'Biometric authentication was not completed. '
            'Use your master password to continue.',
      );
    }

    return _showMasterPasswordDialog(
      context,
      message: reason,
    );
  }

  static Future<bool> _showMasterPasswordDialog(
      BuildContext context, {
        required String message,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _MasterPasswordDialog(message: message),
    );

    return result ?? false;
  }
}

class _MasterPasswordDialog extends StatefulWidget {
  final String message;

  const _MasterPasswordDialog({
    required this.message,
  });

  @override
  State<_MasterPasswordDialog> createState() =>
      _MasterPasswordDialogState();
}

class _MasterPasswordDialogState
    extends State<_MasterPasswordDialog> {
  final TextEditingController _controller = TextEditingController();

  bool _obscure = true;
  bool _verifying = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_verifying) return;

    setState(() {
      _verifying = true;
      _errorText = null;
    });

    final valid = await AuthService.verifyMasterPassword(
      _controller.text,
    );

    if (!mounted) return;

    if (valid) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _verifying = false;
        _errorText = 'Incorrect master password';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AuthService.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Icon(Icons.lock_outline, color: AuthService.green),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Vault Authentication',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.message,
            style: const TextStyle(color: AuthService.muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            onSubmitted: (_) => _verify(),
            decoration: InputDecoration(
              labelText: 'Master Password',
              labelStyle: const TextStyle(color: AuthService.muted),
              errorText: _errorText,
              filled: true,
              fillColor: AuthService.background,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.white12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AuthService.green),
              ),
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _obscure = !_obscure);
                },
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                  color: AuthService.muted,
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _verifying
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: AuthService.muted),
          ),
        ),
        ElevatedButton(
          onPressed: _verifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AuthService.green,
            foregroundColor: Colors.white,
          ),
          child: _verifying
              ? const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : const Text('Authenticate'),
        ),
      ],
    );
  }
}
