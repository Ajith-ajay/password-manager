import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddPasswordScreen extends StatefulWidget {
  final Map<String, dynamic>? existingPassword; // for editing
  final int? index; // index of the password in storage

  const AddPasswordScreen({Key? key, this.existingPassword, this.index})
      : super(key: key);

  @override
  _AddPasswordScreenState createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _secureStorage = const FlutterSecureStorage();
  final _serviceController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingPassword != null) {
      // Pre-fill fields if editing
      _serviceController.text = widget.existingPassword!['service'] ?? '';
      _usernameController.text = widget.existingPassword!['username'] ?? '';
      _passwordController.text = widget.existingPassword!['password'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingPassword != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Password' : 'Add New Password'),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _deletePassword,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _serviceController,
                decoration: const InputDecoration(
                  labelText: 'Service/Website',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username/Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required field' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _savePassword,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? 'Update Password' : 'Save Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _savePassword() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isSaving = true);

      try {
        final updatedPassword = <String, String>{
          'service': _serviceController.text,
          'username': _usernameController.text,
          'password': _passwordController.text,
          'createdAt': widget.existingPassword?['createdAt'] ??
              DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        // Get existing passwords
        final existing = await _secureStorage.read(key: 'passwords');
        final List<Map<String, dynamic>> passwords = existing != null
            ? List<Map<String, dynamic>>.from(json.decode(existing))
            : [];

        if (widget.index != null) {
          // Edit mode: update the password at index
          passwords[widget.index!] = updatedPassword;
        } else {
          // Add mode
          passwords.add(updatedPassword);
        }

        await _secureStorage.write(
          key: 'passwords',
          value: json.encode(passwords),
        );

        Navigator.pop(context, true); // return true to refresh list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving password: $e')),
        );
      } finally {
        if (mounted) setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deletePassword() async {
    try {
      final existing = await _secureStorage.read(key: 'passwords');
      if (existing != null) {
        final List<Map<String, dynamic>> passwords =
            List<Map<String, dynamic>>.from(json.decode(existing));

        if (widget.index != null) {
          passwords.removeAt(widget.index!);

          await _secureStorage.write(
            key: 'passwords',
            value: json.encode(passwords),
          );

          Navigator.pop(context, true); // refresh list
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting password: $e')),
      );
    }
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
