
import 'dart:ui';

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
  bool _obscurePassword = true;

  BiometricType? _biometricType;

  static const cyberGreen = Color(0xFF10B981);
  static const glowTeal = Color(0xFF00E5FF);
  static const background = Color(0xFF040B07);

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometrics() async {
    try {
      final result = await AuthService.checkBiometrics();

      if (!mounted) return;

      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        _biometricAvailable =
            result.available && result.types.isNotEmpty;

        _useBiometrics =
            prefs.getBool('use_biometrics') ?? false;

        if (result.types.isNotEmpty) {
          _biometricType = result.types.first;
        }
      });
    } catch (e) {
      debugPrint('Biometric check error: $e');
    }
  }

  String _getBiometricName(BiometricType? type) {
    switch (type) {
      case BiometricType.face:
        return 'Face Recognition';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris Recognition';
      default:
        return 'Biometric Authentication';
    }
  }

  IconData _getBiometricIcon(BiometricType? type) {
    switch (type) {
      case BiometricType.face:
        return Icons.face_rounded;
      case BiometricType.fingerprint:
        return Icons.fingerprint_rounded;
      case BiometricType.iris:
        return Icons.remove_red_eye_outlined;
      default:
        return Icons.fingerprint_rounded;
    }
  }

  Future<void> _biometricLogin() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final result = await AuthService.authenticate();

      if (!mounted) return;

      if (result) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

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
          errorMessage = 'Biometrics locked. Use your password.';
          break;
      }

      _showMessage(errorMessage);
    } catch (e) {
      if (!mounted) return;
      _showMessage('Authentication error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _login() async {
    if (_isLoading) return;

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final storedPassword =
      await _secureStorage.read(key: 'master_password');

      if (!mounted) return;

      if (storedPassword != null &&
          _passwordController.text == storedPassword) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        _showMessage('Incorrect password. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to access secure storage.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF17251E),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  InputDecoration _buildInputDecoration() {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withOpacity(0.12),
        width: 1.2,
      ),
    );

    return InputDecoration(
      labelText: 'Master Password',
      hintText: 'Enter your master password',
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 12,
      ),
      prefixIcon: Icon(
        Icons.lock_outline_rounded,
        color: Colors.white.withOpacity(0.4),
      ),
      suffixIcon: IconButton(
        onPressed: () {
          setState(() => _obscurePassword = !_obscurePassword);
        },
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.white.withOpacity(0.4),
        ),
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.25),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: const BorderSide(
          color: cyberGreen,
          width: 1.4,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/setup_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Dark overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    background.withOpacity(0.65),
                    background.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
            ),
          ),

          // Login content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 30,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Login-specific icon
                      Container(
                        padding: const EdgeInsets.all(19),
                        decoration: BoxDecoration(
                          color: glowTeal.withOpacity(0.08),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: glowTeal.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: glowTeal.withOpacity(0.12),
                              blurRadius: 30,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          size: 46,
                          color: glowTeal,
                        ),
                      ),

                      const SizedBox(height: 22),

                      const Text(
                        'WELCOME BACK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.5,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'YOUR SECURE VAULT IS WAITING',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.6,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Authentication card
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 16,
                            sigmaY: 16,
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.07),
                                  Colors.white.withOpacity(0.02),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.12),
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.verified_user_outlined,
                                      color: cyberGreen,
                                      size: 19,
                                    ),
                                    const SizedBox(width: 9),
                                    Text(
                                      'VAULT AUTHENTICATION',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                Text(
                                  'Enter your credentials to securely '
                                      'access your stored passwords.',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.45),
                                    fontSize: 11,
                                    height: 1.6,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                  ),
                                  cursorColor: cyberGreen,
                                  decoration: _buildInputDecoration(),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your master password';
                                    }
                                    return null;
                                  },
                                  onFieldSubmitted: (_) => _login(),
                                ),

                                const SizedBox(height: 22),

                                // Unlock button
                                SizedBox(
                                  height: 52,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: cyberGreen.withOpacity(0.2),
                                          blurRadius: 16,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: _isLoading ? null : _login,
                                      icon: _isLoading
                                          ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                          : const Icon(
                                        Icons.lock_open_rounded,
                                        size: 19,
                                      ),
                                      label: Text(
                                        _isLoading
                                            ? 'AUTHENTICATING...'
                                            : 'UNLOCK VAULT',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: cyberGreen,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                        cyberGreen.withOpacity(0.4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.circular(16),
                                        ),
                                        elevation: 0,
                                      ),
                                    ),
                                  ),
                                ),

                                // Biometric section
                                if (_biometricAvailable && _useBiometrics) ...[
                                  const SizedBox(height: 24),

                                  Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withOpacity(0.12),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                        ),
                                        child: Text(
                                          'OR USE BIOMETRICS',
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.4),
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          color: Colors.white.withOpacity(0.12),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 20),

                                  // Distinct biometric action
                                  OutlinedButton(
                                    onPressed: _isLoading
                                        ? null
                                        : _biometricLogin,
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: glowTeal,
                                      side: BorderSide(
                                        color: glowTeal.withOpacity(0.4),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 15,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getBiometricIcon(_biometricType),
                                          size: 23,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'UNLOCK WITH ${_getBiometricName(_biometricType).toUpperCase()}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Security footer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            size: 14,
                            color: cyberGreen.withOpacity(0.6),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'YOUR VAULT. YOUR PRIVACY. YOUR CONTROL.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
