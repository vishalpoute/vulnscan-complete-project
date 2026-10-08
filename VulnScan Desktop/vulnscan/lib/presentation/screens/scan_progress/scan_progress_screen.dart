import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vulnscan/config/routing/app_router.dart';
import 'package:vulnscan/config/theme/colors.dart';
import 'package:vulnscan/data/datasources/api_datasource.dart';
import 'package:vulnscan/data/models/scan_progress_model.dart';
import 'package:vulnscan/services/http_client_service.dart';

/// Stream provider for scan progress polling
final scanProgressProvider = StreamProvider.family<ScanProgress, String>((ref, scanId) async* {
  final httpClient = HttpClientService();
  final api = ApiDatasource(dio: httpClient.dio);

  // Initial fetch
  try {
    yield await api.getScanProgressDetailed(scanId);
  } catch (e) {
    yield* Stream.error(e);
  }

  // Poll every 3 seconds
  final timer = Timer.periodic(const Duration(seconds: 3), (_) {
    // Polling handled by stream creation below
  });

  await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
    try {
      final progress = await api.getScanProgressDetailed(scanId);
      yield progress;

      // Stop polling if completed or failed
      if (progress.isCompleted || progress.isFailed) {
        timer.cancel();
        break;
      }
    } catch (e) {
      yield* Stream.error(e);
      timer.cancel();
      break;
    }
  }
});

class ScanProgressScreen extends ConsumerStatefulWidget {
  final String scanId;

  const ScanProgressScreen({super.key, required this.scanId});

  @override
  ConsumerState<ScanProgressScreen> createState() => _ScanProgressScreenState();
}

class _ScanProgressScreenState extends ConsumerState<ScanProgressScreen> {
  bool _navigationTriggered = false;

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(scanProgressProvider(widget.scanId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Progress'),
        leading: _navigationTriggered
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: progressAsync.when(
        data: (progress) {
          // Auto-navigate when completed
          if (progress.isCompleted && !_navigationTriggered) {
            _navigationTriggered = true;
            Future.microtask(() {
              if (mounted) {
                AppNavigator.pushReplacementNamed(
                  AppRoutes.scanReport,
                  arguments: progress.scanId,
                );
              }
            });
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Overall progress
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Overall Progress', style: Theme.of(context).textTheme.titleMedium),
                            Text(
                              '${progress.progressPercentage}%',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progress.progressPercentage / 100,
                            minHeight: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _getStatusText(progress.status),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(progress.status),
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tool progress
                Text('Security Tools', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...progress.toolProgress.map((tool) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _getToolDisplayName(tool.toolName),
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  if (tool.vulnerabilitiesFound != null)
                                    Text(
                                      '${tool.vulnerabilitiesFound} vulnerabilities found',
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                ],
                              ),
                              _ToolStatusChip(
                                status: tool.status,
                                toolName: tool.toolName,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )),
                const SizedBox(height: 24),

                // Error message if present
                if (progress.errorMessage != null)
                  Card(
                    color: AppColors.error.withValues(alpha: 0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Error',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.error),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            progress.errorMessage!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Cancel button (only show if still scanning)
                if (progress.isScanning)
                  ElevatedButton(
                    onPressed: () => _handleCancelScan(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                    ),
                    child: const Text('Cancel Scan'),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text(
                  'Failed to load scan progress',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(scanProgressProvider(widget.scanId));
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCancelScan() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Scan'),
        content: const Text('Are you sure you want to cancel this scan?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final httpClient = HttpClientService();
        final api = ApiDatasource(dio: httpClient.dio);
        await api.cancelScan(widget.scanId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Scan cancelled')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e'), backgroundColor: AppColors.error),
          );
        }
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'scanning':
        return 'Scanning in progress...';
      case 'completed':
        return 'Scan completed!';
      case 'failed':
        return 'Scan failed';
      default:
        return 'Initializing...';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'scanning':
        return AppColors.info;
      case 'completed':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return Colors.grey;
    }
  }

  String _getToolDisplayName(String toolName) {
    switch (toolName) {
      case 'semgrep':
        return 'Semgrep (SAST)';
      case 'trufflehog':
        return 'TruffleHog (Secrets)';
      case 'npm_audit':
        return 'npm Audit (Dependencies)';
      case 'mobsf':
        return 'MobSF (Mobile)';
      default:
        return toolName;
    }
  }
}

class _ToolStatusChip extends StatelessWidget {
  final String status;
  final String toolName;

  const _ToolStatusChip({
    required this.status,
    required this.toolName,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'completed':
        backgroundColor = AppColors.success;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'running':
        backgroundColor = AppColors.info;
        textColor = Colors.white;
        icon = Icons.hourglass_bottom;
        break;
      case 'failed':
        backgroundColor = AppColors.error;
        textColor = Colors.white;
        icon = Icons.cancel;
        break;
      default:
        backgroundColor = Colors.grey[300]!;
        textColor = Colors.grey[800]!;
        icon = Icons.schedule;
    }

    return Chip(
      label: Text(status.toUpperCase(), style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.bold)),
      backgroundColor: backgroundColor,
      avatar: Icon(icon, color: textColor, size: 16),
      padding: EdgeInsets.zero,
    );
  }
}
