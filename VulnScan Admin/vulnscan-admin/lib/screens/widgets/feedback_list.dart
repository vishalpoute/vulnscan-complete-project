import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/api_provider.dart';

class FeedbackList extends ConsumerStatefulWidget {
  const FeedbackList({Key? key}) : super(key: key);

  @override
  ConsumerState<FeedbackList> createState() => _FeedbackListState();
}

class _FeedbackListState extends ConsumerState<FeedbackList> {
  String _filterType = 'all';

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(feedbackProvider);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Feedback',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          DropdownButton<String>(
            value: _filterType,
            onChanged: (String? value) {
              setState(() {
                _filterType = value ?? 'all';
              });
            },
            items: const [
              DropdownMenuItem(value: 'all', child: Text('All Feedback')),
              DropdownMenuItem(value: 'bug', child: Text('Bug Reports')),
              DropdownMenuItem(value: 'feature', child: Text('Feature Requests')),
              DropdownMenuItem(value: 'general', child: Text('General')),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: feedbackAsync.when(
              data: (feedback) {
                final filtered = _filterType == 'all'
                    ? feedback
                    : feedback.where((f) => f['type'] == _filterType).toList();

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Chip(
                                        label: Text(item['type'] ?? 'N/A'),
                                        backgroundColor: _getTypeColor(item['type']),
                                        labelStyle: const TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Rating: ${item['rating']} / 5',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  item['created_at'] != null
                                      ? item['created_at'].toString().split('T')[0]
                                      : 'N/A',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              item['message'] ?? 'N/A',
                              style: const TextStyle(fontSize: 14),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'bug':
        return Colors.red;
      case 'feature':
        return Colors.green;
      case 'general':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
