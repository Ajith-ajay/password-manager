import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'add_password_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _secureStorage = const FlutterSecureStorage();
  List<Map<String, String>> _passwords = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

// Update the _loadPasswords method
  Future<void> _loadPasswords() async {
    try {
      final passwords = await _secureStorage.read(key: 'passwords');
      if (passwords != null) {
        final decoded = json.decode(passwords) as List<dynamic>;
        setState(() {
          _passwords = decoded
              .map((item) =>
                  Map<String, String>.from(item as Map<String, dynamic>))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() => _passwords = []);
        _isLoading = false;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading passwords: $e')),
      );
    }
  }

  Future<void> _logout() async {
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> _savePasswordsToFile() async {
    if (_passwords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved passwords to export')),
      );
      return;
    }

    try {
      // Request permission (Android 13+ uses manage external storage)
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      // Use the public Downloads directory
      final downloadsDir = Directory('/storage/emulated/0/Download');

      if (!await downloadsDir.exists()) {
        throw Exception('Downloads folder not found');
      }

      // Save file in Downloads
      final file = File('${downloadsDir.path}/passwords_backup.json');

      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert(_passwords),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Passwords exported to Downloads: ${file.path}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting: $e')),
      );
    }
  }

  Future<void> _deletePassword(int index) async {
    setState(() {
      _passwords.removeAt(index);
    });
    await _secureStorage.write(
      key: 'passwords',
      value: json.encode(_passwords),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password deleted')),
    );
  }

  Future<void> _editPassword(int index, Map<String, String> password) async {
    final updatedPassword = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPasswordScreen(
          existingPassword: password,
          index: index,
        ),
      ),
    );

    if (updatedPassword == true) {
      _loadPasswords(); // refresh after edit
    }

    if (updatedPassword != null) {
      setState(() {
        _passwords[index] = Map<String, String>.from(updatedPassword);
      });

      await _secureStorage.write(
        key: 'passwords',
        value: json.encode(_passwords),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Passwords'),
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.download),
          //   tooltip: 'Export Passwords',
          //   onPressed: _savePasswordsToFile,
          // ),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddPasswordScreen(
                      existingPassword: {},
                    )),
          );
          _loadPasswords();
        },
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _passwords.isEmpty
              ? const Center(child: Text('No passwords saved yet'))
              : ListView.builder(
                  itemCount: _passwords.length,
                  itemBuilder: (context, index) {
                    final item = _passwords[index];
                    return ListTile(
                      leading: const Icon(Icons.lock),
                      title: Text(item['service'] ?? 'Unknown'),
                      subtitle: Text(item['username'] ?? ''),
                      onTap: () {
                        // Show password details
                        _showPasswordDetails(item, index);
                      },
                    );
                  },
                ),
    );
  }

  void _showPasswordDetails(Map<String, String> password, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(password['service'] ?? 'Password Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Username: ${password['username']}'),
            const SizedBox(height: 10),
            Text('Password: •••••••••'),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Reveal Password'),
              onPressed: () {
                // Show actual password after authentication
                _revealPassword(password['password'] ?? '');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => _editPassword(index, password),
              child: const Text('Edit', style: TextStyle(color: Colors.blue))),
          TextButton(
              onPressed: () => _deletePassword(index),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _revealPassword(String password) {
    // In a real app, you would decrypt the password here
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Your Password'),
        content: SelectableText(password),
        actions: [
          TextButton(
            child: const Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: password));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password copied to clipboard')),
              );
              Navigator.pop(context);
            },
          ),
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}
