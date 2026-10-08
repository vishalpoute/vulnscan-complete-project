import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:vulnscan/config/theme/colors.dart';
import 'package:vulnscan/config/routing/app_router.dart';
import 'package:vulnscan/data/datasources/api_datasource.dart';
import 'package:vulnscan/data/models/vulnerability_model.dart';
import 'package:vulnscan/data/models/subscription_model.dart';
import 'package:vulnscan/presentation/providers/subscription_provider.dart';
import 'package:vulnscan/services/http_client_service.dart';
import 'package:vulnscan/services/pdf_export_service.dart';

class ScanReportScreen extends ConsumerStatefulWidget {
  final String scanId;

  const ScanReportScreen({super.key, required this.scanId});

  @override
  ConsumerState<ScanReportScreen> createState() => _ScanReportScreenState();
}

class _ScanReportScreenState extends ConsumerState<ScanReportScreen> {
  late Future<ScanReport> _reportFuture;
  String _selectedSeverity = 'all';
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    final httpClient = HttpClientService();
    final api = ApiDatasource(dio: httpClient.dio);
    _reportFuture = api.getReport(widget.scanId);
  }

  Future<void> _handleExportPdf(ScanReport report, String userTier) async {
    // Check if user is on free tier
    if (userTier == 'free') {
      _showUpgradeDialog();
      return;
    }

    setState(() => _isExporting = true);

    try {
      final filePath = await PdfExportService.exportReport(
        report: report,
        userTier: userTier,
      );

      if (filePath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report saved to $filePath')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export PDF'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Export'),
        content: const Text('PDF export is only available for Pro and Enterprise users. Upgrade your plan to access this feature.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AppNavigator.pushNamed(AppRoutes.subscription);
            },
            child: const Text('Upgrade'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Report'),
        actions: [
          subscriptionState.maybeWhen(
            data: (subscription) => IconButton(
              icon: const Icon(Icons.file_download),
              onPressed: _isExporting ? null : () {
                // Get report first
              },
              tooltip: 'Export PDF',
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: FutureBuilder<ScanReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load report',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final report = snapshot.data!;
          final filteredVulns = report.filterBySeverity(_selectedSeverity == 'all' ? null : _selectedSeverity);

          return Column(
            children: [
              // Header and summary
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummarySection(report, context, subscriptionState),
                    _buildSeverityFilterTabs(report, context),
                  ],
                ),
              ),
              // Vulnerability list
              Expanded(
                child: filteredVulns.isEmpty
                    ? _buildEmptyState(context)
                    : subscriptionState.maybeWhen(
                        data: (subscription) => _buildVulnerabilityList(
                          filteredVulns,
                          subscription?.tier ?? 'free',
                          context,
                          report,
                        ),
                        orElse: () => _buildVulnerabilityList(filteredVulns, 'free', context, report),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(ScanReport report, BuildContext context, AsyncValue<SubscriptionInfo?> subscriptionState) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(report.repositoryName, style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('MMM dd, yyyy – hh:mm a').format(report.scanDate),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  subscriptionState.maybeWhen(
                    data: (subscription) => IconButton(
                      icon: _isExporting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.file_download),
                      onPressed: _isExporting
                          ? null
                          : () => _handleExportPdf(report, subscription?.tier ?? 'free'),
                      tooltip: 'Export as PDF',
                    ),
                    orElse: () => const SizedBox(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryItem('Total', report.totalVulnerabilities.toString()),
                  _buildSummaryItem('Critical', report.criticalCount.toString(), color: AppColors.severityCritical),
                  _buildSummaryItem('High', report.highCount.toString(), color: AppColors.severityHigh),
                  _buildSummaryItem('Medium', report.mediumCount.toString(), color: AppColors.severityMedium),
                  _buildSummaryItem('Low', report.lowCount.toString(), color: AppColors.severityLow),
                ],
              ),
              if (report.scanDuration != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Scan Duration: ${report.scanDuration!.inMinutes}m ${report.scanDuration!.inSeconds % 60}s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(color: color),
        ),
      ],
    );
  }

  Widget _buildSeverityFilterTabs(ScanReport report, BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _buildFilterChip('All', 'all', report.totalVulnerabilities),
            const SizedBox(width: 8),
            _buildFilterChip('Critical', 'critical', report.criticalCount, color: AppColors.severityCritical),
            const SizedBox(width: 8),
            _buildFilterChip('High', 'high', report.highCount, color: AppColors.severityHigh),
            const SizedBox(width: 8),
            _buildFilterChip('Medium', 'medium', report.mediumCount, color: AppColors.severityMedium),
            const SizedBox(width: 8),
            _buildFilterChip('Low', 'low', report.lowCount, color: AppColors.severityLow),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String severity, int count, {Color? color}) {
    final isSelected = _selectedSeverity == severity;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _selectedSeverity = severity);
      },
      backgroundColor: color?.withValues(alpha: 0.2),
      selectedColor: color,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: AppColors.success),
          const SizedBox(height: 16),
          Text(
            'No vulnerabilities found!',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppColors.success),
          ),
          const SizedBox(height: 8),
          Text(
            'This repository appears to be secure.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildVulnerabilityList(
    List<Vulnerability> vulnerabilities,
    String userTier,
    BuildContext context,
    ScanReport report,
  ) {
    final isPro = userTier == 'pro' || userTier == 'enterprise';

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: vulnerabilities.length,
      itemBuilder: (context, index) {
        final vuln = vulnerabilities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vuln.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      _SeverityBadge(severity: vuln.severity),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${vuln.filePath}:${vuln.lineNumber}',
                          style: Theme.of(context).textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (vuln.cveId != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'CVE: ${vuln.cveId}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.error),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Text(
                        vuln.codeSnippet,
                        style: const TextStyle(fontFamily: 'Courier', fontSize: 12),
                      ),
                    ),
                  ),
                  if (vuln.aiExplanation != null) ...[
                    const SizedBox(height: 12),
                    if (isPro)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb, size: 16, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Explanation',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.blue),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              vuln.aiExplanation!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Explanation (Pro Feature)',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  AppNavigator.pushNamed(AppRoutes.subscription);
                                },
                                child: const Text('Unlock Pro Features'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                  if (vuln.aiFixSuggestion != null) ...[
                    const SizedBox(height: 12),
                    if (isPro)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.build, size: 16, color: Colors.green),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Fix Suggestion',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.green),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              vuln.aiFixSuggestion!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lock, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  'AI Fix Suggestion (Pro Feature)',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.grey),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  AppNavigator.pushNamed(AppRoutes.subscription);
                                },
                                child: const Text('Unlock Pro Features'),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color textColor;

    switch (severity) {
      case 'critical':
        backgroundColor = AppColors.severityCritical;
        textColor = Colors.white;
        break;
      case 'high':
        backgroundColor = AppColors.severityHigh;
        textColor = Colors.white;
        break;
      case 'medium':
        backgroundColor = AppColors.severityMedium;
        textColor = Colors.black;
        break;
      case 'low':
        backgroundColor = AppColors.severityLow;
        textColor = Colors.black;
        break;
      default:
        backgroundColor = Colors.grey;
        textColor = Colors.white;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
