import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _useBiometrics = false;
  bool _isCreating = false;

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _completeSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      // Store master password securely
      await _secureStorage.write(
        key: 'master_password',
        value: _passwordController.text,
      );

      // Set biometric preference
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('use_biometrics', _useBiometrics);
      await prefs.setBool('first_run', false);

      // Navigate to main app
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Setup failed: ${e.toString()}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Elegant Forest/Cyber Security Palette
    const cyberGreen = Color(0xFF10B981);
    const glowTeal = Color(0xFF00E5FF);

    // Apply dark, immersive overlay for status and nav bars
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF040B07),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF040B07),
      body: Stack(
        children: [
          // 1. Dark, Rich Forest Cyber-Security Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/setup_bg.png', // The custom password manager asset
              fit: BoxFit.cover,
            ),
          ),

          // Gradient veil to enhance contrast and centralize UI presence
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF040B07).withOpacity(0.65),
                    const Color(0xFF040B07).withOpacity(0.4),
                    const Color(0xFF000000).withOpacity(0.85),
                  ],
                ),
              ),
            ),
          ),

          // 2. Centralized Form Content via Custom Scroll & Glass Card
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Lock & Leaf Icon Group
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cyberGreen.withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: cyberGreen.withOpacity(0.4),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: cyberGreen.withOpacity(0.15),
                            blurRadius: 25,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 40,
                        color: glowTeal,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Title section
                    const Text(
                      'SECURE VAULT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.8,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'ESTABLISH YOUR MASTER CREDENTIALS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Centralized Translucent Glassmorphic Card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
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
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Form Section Header
                              Row(
                                children: [
                                  const Icon(
                                    Icons.lock_reset_rounded,
                                    color: cyberGreen,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CREATE MASTER PASSWORD',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Master Password Input
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                cursorColor: cyberGreen,
                                decoration: _buildInputDecoration(
                                  labelText: 'Master Password',
                                  hintText: 'Minimum 8 characters',
                                  prefixIcon: Icons.lock_outline_rounded,
                                  isObscured: _obscurePassword,
                                  onToggleObscure: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                  activeColor: cyberGreen,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a password';
                                  }
                                  if (value.length < 8) {
                                    return 'Password must be at least 8 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),

                              // Confirm Password Input
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                cursorColor: cyberGreen,
                                decoration: _buildInputDecoration(
                                  labelText: 'Confirm Password',
                                  hintText: 'Re-enter your master password',
                                  prefixIcon: Icons.lock_clock_outlined,
                                  isObscured: _obscureConfirmPassword,
                                  onToggleObscure: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                    });
                                  },
                                  activeColor: cyberGreen,
                                ),
                                validator: (value) {
                                  if (value != _passwordController.text) {
                                    return 'Passwords do not match';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Modernized Bio Authenticaton Toggle
                              Theme(
                                data: ThemeData(
                                  useMaterial3: true,
                                ).copyWith(
                                  hoverColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                ),
                                child: SwitchListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Biometric Authentication',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Enable fingerprint or facial recognition',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.4),
                                      fontSize: 10,
                                    ),
                                  ),
                                  value: _useBiometrics,
                                  activeColor: glowTeal,
                                  activeTrackColor: glowTeal.withOpacity(0.2),
                                  inactiveThumbColor:
                                  Colors.white.withOpacity(0.6),
                                  inactiveTrackColor:
                                  Colors.white.withOpacity(0.08),
                                  onChanged: (value) =>
                                      setState(() => _useBiometrics = value),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Submission button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cyberGreen.withOpacity(0.25),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isCreating ? null : _completeSetup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cyberGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            cyberGreen.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isCreating
                              ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            'Complete Setup',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Cryptographic assurance signature
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.vpn_key_outlined,
                          size: 13,
                          color: Colors.white.withOpacity(0.35),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'YOUR PRIVATE KEYS ARE SECURED OFFLINE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.35),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Consistent glassmorphic text input style builder
  InputDecoration _buildInputDecoration({
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    required bool isObscured,
    required VoidCallback onToggleObscure,
    required Color activeColor,
  }) {
    final baseBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: Colors.white.withOpacity(0.12),
        width: 1.2,
      ),
    );

    return InputDecoration(
      labelText: labelText,
      labelStyle: TextStyle(
        color: Colors.white.withOpacity(0.5),
        fontSize: 13,
      ),
      floatingLabelStyle: TextStyle(
        color: activeColor,
        fontWeight: FontWeight.w600,
      ),
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.25),
        fontSize: 12,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: Colors.white.withOpacity(0.4),
        size: 20,
      ),
      suffixIcon: IconButton(
        icon: Icon(
          isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.white.withOpacity(0.4),
          size: 20,
        ),
        onPressed: onToggleObscure,
      ),
      filled: true,
      fillColor: Colors.black.withOpacity(0.25),
      border: baseBorder,
      enabledBorder: baseBorder,
      focusedBorder: baseBorder.copyWith(
        borderSide: BorderSide(color: activeColor, width: 1.4),
      ),
      errorBorder: baseBorder.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
      focusedErrorBorder: baseBorder.copyWith(
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}