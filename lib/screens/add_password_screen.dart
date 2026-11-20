
import 'package:flutter/material.dart';

import '../services/vault_storage.dart';
import '../auth/auth.dart';

class AddPasswordScreen extends StatefulWidget {
  final Map<String, dynamic>? existingPassword;
  final int? index;

  const AddPasswordScreen({
    Key? key,
    this.existingPassword,
    this.index,
  }) : super(key: key);

  @override
  State<AddPasswordScreen> createState() =>
      _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  static const Color background = Color(0xFF08110E);
  static const Color surface = Color(0xFF111E19);
  static const Color green = Color(0xFF10B981);
  static const Color muted = Color(0xFF91A39A);

  final _formKey = GlobalKey<FormState>();

  final _serviceController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  List<Map<String, dynamic>> _folders = [];

  String? _selectedFolderId;

  bool _isSaving = false;
  bool _obscurePassword = true;

  bool get _isEditing => widget.index != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingPassword;

    if (existing != null) {
      _serviceController.text =
          existing['service']?.toString() ?? '';

      _usernameController.text =
          existing['username']?.toString() ?? '';

      _passwordController.text =
          existing['password']?.toString() ?? '';

      _selectedFolderId =
          existing['folderId']?.toString();
    }

    _loadFolders();
  }

  Future<void> _loadFolders() async {
    try {
      final folders = await VaultStorage.getFolders();

      if (!mounted) return;

      // Keep only folders with unique, non-empty IDs.
      final uniqueFolders = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      for (final folder in folders) {
        final id = folder['id']?.toString();

        if (id == null || id.isEmpty || !seenIds.add(id)) {
          continue;
        }

        uniqueFolders.add(folder);
      }

      setState(() {
        _folders = uniqueFolders;

        if (_selectedFolderId != null &&
            !_folders.any(
                  (folder) =>
              folder['id'].toString() == _selectedFolderId,
            )) {
          _selectedFolderId = null;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load folders: $e'),
        ),
      );
    }
  }

  Future<void> _savePassword() async {

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authenticated =
    await AuthService.authenticateForSensitiveAction(
      context,
      reason: _isEditing
          ? 'Authenticate to update this password.'
          : 'Authenticate to save this password.',
    );

    if (!authenticated || !mounted) return;

    setState(() => _isSaving = true);


    try {
      final passwords = await VaultStorage.getPasswords();

      final now = DateTime.now().toIso8601String();

      final updatedPassword = <String, dynamic>{
        ...?widget.existingPassword,
        'service': _serviceController.text.trim(),
        'username': _usernameController.text.trim(),
        'password': _passwordController.text,
        'folderId': _selectedFolderId,
        'createdAt':
        widget.existingPassword?['createdAt'] ?? now,
        'updatedAt': now,
      };

      if (_isEditing) {
        if (widget.index! >= passwords.length) {
          throw Exception('Password record no longer exists');
        }

        passwords[widget.index!] = updatedPassword;
      } else {
        passwords.add(updatedPassword);
      }

      await VaultStorage.savePasswords(passwords);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Password updated successfully'
                : 'Password saved successfully',
          ),
          backgroundColor: const Color(0xFF126B4D),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save password: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: muted),
      labelStyle: const TextStyle(color: muted),
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: green),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _isEditing ? 'Edit Password' : 'Add Password',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_rounded,
                      color: green,
                      size: 32,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Password Details',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Store your credentials securely in your vault.',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'SERVICE INFORMATION',
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 13),

              TextFormField(
                controller: _serviceController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  label: 'Service / Website',
                  icon: Icons.language_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Service name is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  label: 'Username / Email',
                  icon: Icons.person_outline_rounded,
                ),
              ),

              const SizedBox(height: 26),

              const Text(
                'SECURITY DETAILS',
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 13),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  label: 'Password',
                  icon: Icons.key_rounded,
                ).copyWith(
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: muted,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 26),

              const Text(
                'ORGANIZE YOUR PASSWORD',
                style: TextStyle(
                  color: muted,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 13),

              DropdownButtonFormField<String>(
                value: _selectedFolderId,
                dropdownColor: surface,
                style: const TextStyle(color: Colors.white),
                decoration: _decoration(
                  label: 'Select Folder',
                  icon: Icons.folder_outlined,
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('Uncategorized'),
                  ),
                  ..._folders.map(
                        (folder) => DropdownMenuItem<String>(
                      value: folder['id'].toString(),
                      child: Text(folder['name'].toString()),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFolderId = value;
                  });
                },
              ),

              const SizedBox(height: 35),

              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                    height: 19,
                    width: 19,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _isSaving
                        ? 'Saving...'
                        : _isEditing
                        ? 'Update Password'
                        : 'Save Password',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();

    super.dispose();
  }
}
