
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class VaultStorage {
  VaultStorage._();

  static const FlutterSecureStorage _storage =
  FlutterSecureStorage();

  static const String _passwordsKey = 'passwords';
  static const String _foldersKey = 'folders';

  static Future<List<Map<String, dynamic>>> getPasswords() async {
    final raw = await _storage.read(key: _passwordsKey);

    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  static Future<void> savePasswords(
      List<Map<String, dynamic>> passwords,
      ) async {
    await _storage.write(
      key: _passwordsKey,
      value: jsonEncode(passwords),
    );
  }

  static Future<List<Map<String, dynamic>>> getFolders() async {
    final raw = await _storage.read(key: _foldersKey);

    if (raw != null) {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    // Initial default folders.
    final folders = [
      _createFolder('Social Media'),
      _createFolder('Banking'),
      _createFolder('Work'),
      _createFolder('Shopping'),
      _createFolder('Personal'),
    ];

    await saveFolders(folders);

    return folders;
  }

  static Map<String, dynamic> _createFolder(String name) {
    return {
      'id': DateTime.now().microsecondsSinceEpoch.toString() +
          name.hashCode.toString(),
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }

  static Future<void> saveFolders(
      List<Map<String, dynamic>> folders,
      ) async {
    await _storage.write(
      key: _foldersKey,
      value: jsonEncode(folders),
    );
  }
}
