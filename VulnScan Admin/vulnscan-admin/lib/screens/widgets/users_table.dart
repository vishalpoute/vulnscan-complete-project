import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/api_provider.dart';

class UsersTable extends ConsumerStatefulWidget {
  const UsersTable({Key? key}) : super(key: key);

  @override
  ConsumerState<UsersTable> createState() => _UsersTableState();
}

class _UsersTableState extends ConsumerState<UsersTable> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users Management',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search users by email...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 24),
          Expanded(
            child: usersAsync.when(
              data: (users) {
                final filtered = users
                    .where((user) =>
                        (user['email'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        (user['uid'] ?? '')
                            .toString()
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()))
                    .toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Tier')),
                      DataColumn(label: Text('Scans')),
                      DataColumn(label: Text('Last Active')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: filtered
                        .map((user) => DataRow(cells: [
                              DataCell(Text(user['email'] ?? 'N/A')),
                              DataCell(Text(user['subscription_tier'] ?? 'free')),
                              DataCell(Text('${user['scan_count'] ?? 0}')),
                              DataCell(Text(user['last_active'] != null
                                  ? user['last_active'].toString().split('.')[0]
                                  : 'Never')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showDeleteConfirmation(user['uid']);
                                  },
                                ),
                              ),
                            ]))
                        .toList(),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure you want to delete this user and all their scans?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(deleteUserProvider(userId).future).then((_) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('User deleted successfully')),
                );
              }).catchError((e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              });
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
