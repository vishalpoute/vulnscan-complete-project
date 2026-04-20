import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/api_provider.dart';

class ScansTable extends ConsumerStatefulWidget {
  const ScansTable({Key? key}) : super(key: key);

  @override
  ConsumerState<ScansTable> createState() => _ScansTableState();
}

class _ScansTableState extends ConsumerState<ScansTable> {
  String _filterStatus = 'all';

  @override
  Widget build(BuildContext context) {
    final scansAsync = ref.watch(scansProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Scans',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          DropdownButton<String>(
            value: _filterStatus,
            onChanged: (String? value) {
              setState(() {
                _filterStatus = value ?? 'all';
              });
            },
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Scans')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'scanning', child: Text('Scanning')),
              DropdownMenuItem(value: 'completed', child: Text('Completed')),
              DropdownMenuItem(value: 'failed', child: Text('Failed')),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: scansAsync.when(
              data: (scans) {
                final filtered = _filterStatus == 'all'
                    ? scans
                    : scans.where((scan) => scan['status'] == _filterStatus).toList();

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Repository')),
                      DataColumn(label: Text('Type')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Critical')),
                      DataColumn(label: Text('High')),
                      DataColumn(label: Text('Created')),
                    ],
                    rows: filtered
                        .map((scan) => DataRow(cells: [
                              DataCell(Text(scan['url_or_repo'] ?? 'N/A')),
                              DataCell(Text(scan['scan_type'] ?? 'N/A')),
                              DataCell(
                                Chip(
                                  label: Text(scan['status'] ?? 'N/A'),
                                  backgroundColor: _getStatusColor(scan['status']),
                                  labelStyle: const TextStyle(color: Colors.white),
                                ),
                              ),
                              DataCell(Text('${scan['critical_count'] ?? 0}')),
                              DataCell(Text('${scan['high_count'] ?? 0}')),
                              DataCell(Text(scan['created_at'] != null
                                  ? scan['created_at'].toString().split('.')[0]
                                  : 'N/A')),
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

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'scanning':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
