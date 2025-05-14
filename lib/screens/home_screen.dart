import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Passwords'),
        actions: [
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
            MaterialPageRoute(builder: (context) => const AddPasswordScreen()),
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
                        _showPasswordDetails(item);
                      },
                    );
                  },
                ),
    );
  }

  void _showPasswordDetails(Map<String, String> password) {
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
