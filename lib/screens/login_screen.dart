import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _secureStorage = const FlutterSecureStorage();
  bool _isLoading = false;
  bool _biometricAvailable = false;
  bool _useBiometrics = false;
  String _biometricType = '';

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _biometricLogin() async {
    setState(() => _isLoading = true);
    try {
      final result = await AuthService.authenticate();
      if (result) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on PlatformException catch (e) {
      String errorMessage = 'Authentication failed';
      switch (e.code) {
        case 'NotAvailable':
          errorMessage = 'Biometrics not available';
          break;
        case 'NotEnrolled':
          errorMessage = 'No biometrics enrolled on this device';
          break;
        case 'LockedOut':
          errorMessage = 'Too many attempts. Try again later.';
          break;
        case 'PermanentlyLockedOut':
          errorMessage = 'Biometrics permanently locked. Use password.';
          break;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _checkBiometrics() async {
    try {
      final (available: available, types: types) =
          await AuthService.checkBiometrics();
      if (available && types.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          _biometricAvailable = available;
          _useBiometrics = prefs.getBool('use_biometrics') ?? available;
          _biometricType = types.first;
        });
      }
    } catch (e) {
      print('Biometric check error: $e');
    }
  }

  String _getBiometricName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Scan';
      default:
        return 'Biometric';
    }
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        final storedPassword =
            await _secureStorage.read(key: 'master_password');
        if (_passwordController.text == storedPassword) {
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Incorrect password')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Master Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Enter your password' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Login'),
                ),
              ),
              if (_biometricAvailable) ...[
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: Icon(_biometricType.contains('Face')
                        ? Icons.face
                        : Icons.fingerprint),
                    label: Text('Use $_biometricType'),
                    onPressed: _isLoading ? null : _biometricLogin,
                  ),
                ),
              ],
              const Spacer(),
              TextButton(
                onPressed: () {
                  // Add password recovery flow later
                },
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
