
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../auth/auth.dart';
import '../services/vault_storage.dart';
import 'add_password_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color background = Color(0xFF08110E);
  static const Color surface = Color(0xFF111E19);
  static const Color green = Color(0xFF10B981);
  static const Color muted = Color(0xFF91A39A);

  List<Map<String, dynamic>> _passwords = [];
  List<Map<String, dynamic>> _folders = [];

  bool _isLoading = true;

  String? _selectedFolderId;
  String _searchQuery = '';

  final TextEditingController _searchController =
  TextEditingController();

  static const String uncategorizedId = '__uncategorized__';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }


  Future<bool> _authenticate(String reason) async {
    return AuthService.authenticateForSensitiveAction(
      context,
      reason: reason,
    );
  }


  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        VaultStorage.getPasswords(),
        VaultStorage.getFolders(),
      ]);

      if (!mounted) return;

      setState(() {
        _passwords =
        results[0] as List<Map<String, dynamic>>;

        _folders =
        results[1] as List<Map<String, dynamic>>;

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      _message('Unable to load vault data: $e');
    }
  }

  void _message(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1C3028),
      ),
    );
  }

  List<MapEntry<int, Map<String, dynamic>>>
  get _filteredPasswords {
    final query = _searchQuery.trim().toLowerCase();

    return _passwords.asMap().entries.where((entry) {
      final password = entry.value;

      final service =
      (password['service'] ?? '').toString().toLowerCase();

      final username =
      (password['username'] ?? '').toString().toLowerCase();

      final matchesSearch =
          query.isEmpty ||
              service.contains(query) ||
              username.contains(query);

      final folderId = password['folderId']?.toString();

      final matchesFolder =
          _selectedFolderId == null ||
              (_selectedFolderId == uncategorizedId
                  ? folderId == null ||
                  folderId.isEmpty ||
                  !_folders.any(
                        (f) => f['id'].toString() == folderId,
                  )
                  : folderId == _selectedFolderId);

      return matchesSearch && matchesFolder;
    }).toList();
  }

  int _folderCount(String folderId) {
    return _passwords.where((password) {
      return password['folderId']?.toString() == folderId;
    }).length;
  }

  int get _uncategorizedCount {
    return _passwords.where((password) {
      final id = password['folderId']?.toString();

      return id == null ||
          id.isEmpty ||
          !_folders.any((folder) => folder['id'] == id);
    }).length;
  }

  Future<void> _addPassword() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddPasswordScreen(),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _editPassword(
      int index,
      Map<String, dynamic> password,
      ) async {

    final authenticated = await _authenticate(
      'Authenticate to edit this password.',
    );

    if (!authenticated || !mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddPasswordScreen(
          existingPassword: password,
          index: index,
        ),
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  Future<void> _deletePassword(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Password?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this password? This action cannot be undone.',
          style: TextStyle(color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final authenticated = await _authenticate(
      'Authenticate to delete this password.',
    );

    if (!authenticated || !mounted) return;

    try {
      final updated = List<Map<String, dynamic>>.from(_passwords);

      updated.removeAt(index);

      await VaultStorage.savePasswords(updated);

      if (!mounted) return;

      setState(() {
        _passwords = updated;
      });

      _message('Password deleted successfully');
    } catch (e) {
      _message('Unable to delete password: $e');
    }
  }

  Future<void> _showPasswordDetails(
      int index,
      Map<String, dynamic> password,
      ) async {
    bool revealed = false;

    final service = password['service']?.toString() ?? 'Password';
    final username = password['username']?.toString() ?? '';
    final secret = password['password']?.toString() ?? '';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: Row(
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    color: green,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      service,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLabel('USERNAME / EMAIL'),
                  const SizedBox(height: 6),
                  SelectableText(
                    username.isEmpty ? 'Not provided' : username,
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 22),
                  _detailLabel('PASSWORD'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            revealed ? secret : '••••••••••••',
                            style: const TextStyle(
                              color: Colors.white,
                              letterSpacing: 1.5,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (revealed)
                          IconButton(
                            tooltip: 'Copy password',
                            onPressed: () async {
                              final authenticated = await AuthService
                                  .authenticateForSensitiveAction(
                                dialogContext,
                                reason: 'Authenticate to copy this password.',
                              );

                              if (!authenticated || !dialogContext.mounted) return;

                              await Clipboard.setData(
                                ClipboardData(text: secret),
                              );

                              if (dialogContext.mounted) {
                                ScaffoldMessenger.of(dialogContext).showSnackBar(
                                  const SnackBar(
                                    content: Text('Password copied'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.copy_rounded,
                              color: green,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () async {
                        if (revealed) {
                          setDialogState(() {
                            revealed = false;
                          });
                          return;
                        }

                        final authenticated =
                        await AuthService
                            .authenticateForSensitiveAction(
                          dialogContext,
                        );

                        if (!authenticated ||
                            !dialogContext.mounted) {
                          return;
                        }

                        setDialogState(() {
                          revealed = true;
                        });
                      },
                      icon: Icon(
                        revealed
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      label: Text(
                        revealed
                            ? 'Hide Password'
                            : 'Authenticate & Reveal',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _editPassword(index, password);
                  },
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    _deletePassword(index);
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(color: Colors.redAccent),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _detailLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: muted,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }


  Future<String?> _folderNameDialog({
    String? initialName,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _FolderNameDialog(
        initialName: initialName,
      ),
    );
  }

  Future<void> _createFolder() async {
    final name = await _folderNameDialog();

    if (name == null || !mounted) return;

    if (_folders.any(
          (folder) =>
      folder['name'].toString().toLowerCase() ==
          name.toLowerCase(),
    )) {
      _message('A folder with this name already exists');
      return;
    }

    final authenticated = await _authenticate(
      'Authenticate to create this folder.',
    );

    if (!authenticated || !mounted) return;

    final folder = {
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'name': name,
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      final updated = [..._folders, folder];

      await VaultStorage.saveFolders(updated);

      if (!mounted) return;

      setState(() => _folders = updated);

      _message('Folder created');
    } catch (e) {
      _message('Unable to create folder: $e');
    }
  }

  Future<void> _renameFolder(
      Map<String, dynamic> folder,
      ) async {
    final name = await _folderNameDialog(
      initialName: folder['name'].toString(),
    );

    if (name == null || !mounted) return;

    if (_folders.any(
          (f) =>
      f['id'] != folder['id'] &&
          f['name'].toString().toLowerCase() ==
              name.toLowerCase(),
    )) {
      _message('A folder with this name already exists');
      return;
    }

    final authenticated = await _authenticate(
      'Authenticate to rename this folder.',
    );

    if (!authenticated || !mounted) return;

    final updated = _folders.map((f) {
      if (f['id'] == folder['id']) {
        return {...f, 'name': name};
      }

      return f;
    }).toList();

    try {
      await VaultStorage.saveFolders(updated);

      if (!mounted) return;

      setState(() => _folders = updated);

      _message('Folder renamed');
    } catch (e) {
      _message('Unable to rename folder: $e');
    }
  }

  Future<void> _deleteFolder(
      Map<String, dynamic> folder,
      ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Folder?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          'Passwords in this folder will be moved to Uncategorized. '
              'They will not be deleted.',
          style: TextStyle(color: muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: muted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete Folder'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final authenticated = await _authenticate(
      'Authenticate to delete this folder.',
    );

    if (!authenticated || !mounted) return;

    try {
      final folderId = folder['id'].toString();

      final updatedFolders = _folders
          .where((f) => f['id'] != folder['id'])
          .toList();

      final updatedPasswords = _passwords.map((password) {
        if (password['folderId']?.toString() == folderId) {
          final updated = Map<String, dynamic>.from(password);
          updated.remove('folderId');
          return updated;
        }

        return Map<String, dynamic>.from(password);
      }).toList();

      await VaultStorage.savePasswords(updatedPasswords);
      await VaultStorage.saveFolders(updatedFolders);

      if (!mounted) return;

      setState(() {
        _folders = updatedFolders;
        _passwords = updatedPasswords;

        if (_selectedFolderId == folderId) {
          _selectedFolderId = null;
        }
      });

      _message('Folder deleted. Passwords were preserved.');
    } catch (e) {
      _message('Unable to delete folder: $e');
    }
  }

  Future<void> _showFolderManager() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: surface,
              title: const Text(
                'Manage Folders',
                style: TextStyle(color: Colors.white),
              ),
              content: SizedBox(
                width: double.maxFinite,
                height: 350,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          for (final folder in _folders)
                            ListTile(
                              leading: const Icon(
                                Icons.folder_rounded,
                                color: green,
                              ),
                              title: Text(
                                folder['name'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                              subtitle: Text(
                                '${_folderCount(folder['id'].toString())} passwords',
                                style: const TextStyle(color: muted),
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) async {
                                  Navigator.pop(dialogContext);

                                  if (value == 'rename') {
                                    await _renameFolder(folder);
                                  } else if (value == 'delete') {
                                    await _deleteFolder(folder);
                                  }

                                  if (mounted) {
                                    _showFolderManager();
                                  }
                                },
                                itemBuilder: (_) => const [
                                  PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename'),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    await _createFolder();

                    if (mounted) {
                      _showFolderManager();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('New Folder'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: green.withOpacity(0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: green,
              size: 25,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SECURE VAULT',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your passwords. One safe place.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Manage folders',
            onPressed: _showFolderManager,
            icon: const Icon(
              Icons.folder_copy_outlined,
              color: Colors.white,
            ),
          ),
          IconButton(
            tooltip: 'Lock vault',
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                    (route) => false,
              );
            },
            icon: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 18),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF126B4D),
            Color(0xFF0D382B),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: green.withOpacity(0.10),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR PASSWORD VAULT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const Icon(
                Icons.verified_user_outlined,
                color: Colors.white70,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${_passwords.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Text(
            'Saved passwords',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              _overviewStat(
                Icons.folder_rounded,
                '${_folders.length}',
                'Folders',
              ),
              const SizedBox(width: 28),
              _overviewStat(
                Icons.inbox_rounded,
                '$_uncategorizedCount',
                'Uncategorized',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewStat(
      IconData icon,
      String value,
      String label,
      ) {
    return Row(
      children: [
        Icon(icon, size: 19, color: Colors.white70),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search passwords or usernames...',
          hintStyle: const TextStyle(
            color: muted,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: muted,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
            icon: const Icon(Icons.close, color: muted),
          )
              : null,
          filled: true,
          fillColor: surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildFolders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR FOLDERS',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              TextButton(
                onPressed: _showFolderManager,
                child: const Text(
                  'Manage',
                  style: TextStyle(color: green),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 43,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _folderChip(
                'All',
                null,
                _passwords.length,
                Icons.grid_view_rounded,
              ),
              ..._folders.map(
                    (folder) => _folderChip(
                  folder['name'].toString(),
                  folder['id'].toString(),
                  _folderCount(folder['id'].toString()),
                  Icons.folder_rounded,
                ),
              ),
              _folderChip(
                'Uncategorized',
                uncategorizedId,
                _uncategorizedCount,
                Icons.inbox_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _folderChip(
      String name,
      String? id,
      int count,
      IconData icon,
      ) {
    final selected = _selectedFolderId == id;

    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) {
          setState(() => _selectedFolderId = id);
        },
        avatar: Icon(
          icon,
          size: 16,
          color: selected ? Colors.white : muted,
        ),
        label: Text('$name ($count)'),
        labelStyle: TextStyle(
          color: selected ? Colors.white : muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
        backgroundColor: surface,
        selectedColor: const Color(0xFF126B4D),
        side: BorderSide(
          color: selected ? green : Colors.white10,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildPasswordList() {
    final entries = _filteredPasswords;

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off_rounded
                  : Icons.lock_outline_rounded,
              color: muted,
              size: 45,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching passwords'
                  : 'No passwords in this folder',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a password to get started.',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      itemCount: entries.length,
      itemBuilder: (context, position) {
        final entry = entries[position];
        final index = entry.key;
        final password = entry.value;

        final service =
            password['service']?.toString() ?? 'Unknown';

        final username =
            password['username']?.toString() ?? '';

        return Container(
          margin: const EdgeInsets.only(bottom: 11),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withOpacity(0.04)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 7,
            ),
            onTap: () => _showPasswordDetails(index, password),
            leading: Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.language_rounded,
                color: green,
              ),
            ),
            title: Text(
              service,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                username.isEmpty ? 'No username' : username,
                style: const TextStyle(
                  color: muted,
                  fontSize: 11,
                ),
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: muted,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPassword,
        backgroundColor: green,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Add Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
          child: CircularProgressIndicator(color: green),
        )
            : Column(
          children: [
            _buildHeader(),
            _buildOverview(),
            _buildSearch(),
            _buildFolders(),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                20,
                22,
                20,
                8,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'SAVED PASSWORDS',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Text(
                    '${_filteredPasswords.length} items',
                    style: const TextStyle(
                      color: muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildPasswordList()),
          ],
        ),
      ),
    );
  }
}

class _FolderNameDialog extends StatefulWidget {
  final String? initialName;

  const _FolderNameDialog({
    this.initialName,
  });

  @override
  State<_FolderNameDialog> createState() =>
      _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller;

  static const Color background = Color(0xFF08110E);
  static const Color surface = Color(0xFF111E19);
  static const Color green = Color(0xFF10B981);
  static const Color muted = Color(0xFF91A39A);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialName ?? '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final name = _controller.text.trim();

    if (name.isEmpty) return;

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialName != null;

    return AlertDialog(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        isEditing ? 'Rename Folder' : 'Create Folder',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 30,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Enter folder name',
          hintStyle: const TextStyle(color: muted),
          counterStyle: const TextStyle(color: muted),
          filled: true,
          fillColor: background,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: green),
          ),
        ),
        onSubmitted: (_) => _save(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(color: muted),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}