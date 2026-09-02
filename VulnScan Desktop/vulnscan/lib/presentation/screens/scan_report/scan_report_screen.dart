import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Report saved to $filePath')));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export PDF'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'PDF Export — Pro Feature',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'PDF export is only available for Pro and Enterprise users.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
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
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.article_outlined,
              color: AppColors.accentGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Scan Report',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          subscriptionState.maybeWhen(
            data: (subscription) => IconButton(
              icon: _isExporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accentGreen,
                      ),
                    )
                  : const Icon(Icons.download_outlined),
              tooltip: 'Export PDF',
              onPressed: _isExporting ? null : () {},
            ),
            orElse: () => const SizedBox(),
          ),
        ],
      ),
      body: FutureBuilder<ScanReport>(
        future: _reportFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accentGreen),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: AppColors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load report',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          final report = snapshot.data!;
          final filteredVulns = report.filterBySeverity(
            _selectedSeverity == 'all' ? null : _selectedSeverity,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              SingleChildScrollView(
                child: _buildSummarySection(report, context, subscriptionState),
              ),
              // Severity filter
              _buildSeverityFilter(report),
              // Vuln list
              Expanded(
                child: filteredVulns.isEmpty
                    ? _buildEmptyState()
                    : subscriptionState.maybeWhen(
                        data: (subscription) => _buildVulnList(
                          filteredVulns,
                          subscription?.tier ?? 'free',
                          report,
                        ),
                        orElse: () =>
                            _buildVulnList(filteredVulns, 'free', report),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummarySection(
    ScanReport report,
    BuildContext context,
    AsyncValue<SubscriptionInfo?> subscriptionState,
  ) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.folder_outlined,
                          size: 16,
                          color: AppColors.accentBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          report.repositoryName,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat(
                        'MMM dd, yyyy – hh:mm a',
                      ).format(report.scanDate),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              subscriptionState.maybeWhen(
                data: (subscription) => IconButton(
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentGreen,
                          ),
                        )
                      : const Icon(
                          Icons.download_outlined,
                          color: AppColors.textSecondary,
                        ),
                  tooltip: 'Export as PDF',
                  onPressed: _isExporting
                      ? null
                      : () => _handleExportPdf(
                          report,
                          subscription?.tier ?? 'free',
                        ),
                ),
                orElse: () => const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _SummaryCount(
                label: 'Total',
                count: report.totalVulnerabilities,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 12),
              _SummaryCount(
                label: 'Critical',
                count: report.criticalCount,
                color: AppColors.severityCritical,
              ),
              const SizedBox(width: 12),
              _SummaryCount(
                label: 'High',
                count: report.highCount,
                color: AppColors.severityHigh,
              ),
              const SizedBox(width: 12),
              _SummaryCount(
                label: 'Medium',
                count: report.mediumCount,
                color: AppColors.severityMedium,
              ),
              const SizedBox(width: 12),
              _SummaryCount(
                label: 'Low',
                count: report.lowCount,
                color: AppColors.severityLow,
              ),
            ],
          ),
          if (report.scanDuration != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 13,
                  color: AppColors.textSubtle,
                ),
                const SizedBox(width: 6),
                Text(
                  'Scan duration: ${report.scanDuration!.inMinutes}m ${report.scanDuration!.inSeconds % 60}s',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeverityFilter(ScanReport report) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _filterTab('All', 'all', report.totalVulnerabilities),
          const SizedBox(width: 8),
          _filterTab(
            'Critical',
            'critical',
            report.criticalCount,
            color: AppColors.severityCritical,
          ),
          const SizedBox(width: 8),
          _filterTab(
            'High',
            'high',
            report.highCount,
            color: AppColors.severityHigh,
          ),
          const SizedBox(width: 8),
          _filterTab(
            'Medium',
            'medium',
            report.mediumCount,
            color: AppColors.severityMedium,
          ),
          const SizedBox(width: 8),
          _filterTab(
            'Low',
            'low',
            report.lowCount,
            color: AppColors.severityLow,
          ),
        ],
      ),
    );
  }

  Widget _filterTab(String label, String severity, int count, {Color? color}) {
    final isSelected = _selectedSeverity == severity;
    final c = color ?? AppColors.textSecondary;
    return GestureDetector(
      onTap: () => setState(() => _selectedSeverity = severity),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? c.withValues(alpha: 0.15) : AppColors.bgPrimary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? c : AppColors.borderDefault,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? c : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            size: 56,
            color: AppColors.accentGreen,
          ),
          const SizedBox(height: 16),
          Text(
            'No vulnerabilities found!',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.accentGreen,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This repository appears to be secure.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVulnList(
    List<Vulnerability> vulnerabilities,
    String userTier,
    ScanReport report,
  ) {
    final isPro = userTier == 'pro' || userTier == 'enterprise';
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: vulnerabilities.length,
      itemBuilder: (context, index) {
        final vuln = vulnerabilities[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _VulnCard(vuln: vuln, isPro: isPro),
        );
      },
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SummaryCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryCount({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VulnCard extends StatefulWidget {
  final Vulnerability vuln;
  final bool isPro;

  const _VulnCard({required this.vuln, required this.isPro});

  @override
  State<_VulnCard> createState() => _VulnCardState();
}

class _VulnCardState extends State<_VulnCard> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.vuln.severity) {
      case 'critical':
        return AppColors.severityCritical;
      case 'high':
        return AppColors.severityHigh;
      case 'medium':
        return AppColors.severityMedium;
      case 'low':
        return AppColors.severityLow;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left-colored severity border
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                color: _severityColor,
                gradient: LinearGradient(
                  colors: [
                    _severityColor,
                    _severityColor.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ),

          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vuln.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: AppColors.textSubtle,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${widget.vuln.filePath}:${widget.vuln.lineNumber}',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 11,
                                  color: AppColors.textSubtle,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _SeverityBadge(severity: widget.vuln.severity),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // CVE badge (always visible if present)
          if (widget.vuln.cveId != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.severityCritical.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: AppColors.severityCritical.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                    child: Text(
                      'CVE: ${widget.vuln.cveId}',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.severityCritical,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Expandable content
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.borderDefault),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Code snippet
                  _CodeBlock(code: widget.vuln.codeSnippet),

                  // AI Explanation
                  if (widget.vuln.aiExplanation != null) ...[
                    const SizedBox(height: 12),
                    widget.isPro
                        ? _AiPanel(
                            title: 'AI Explanation',
                            content: widget.vuln.aiExplanation!,
                            icon: Icons.lightbulb_outline,
                            color: AppColors.accentBlue,
                          )
                        : _LockedProPanel(label: 'AI Explanation'),
                  ],

                  // AI Fix
                  if (widget.vuln.aiFixSuggestion != null) ...[
                    const SizedBox(height: 12),
                    widget.isPro
                        ? _AiPanel(
                            title: 'AI Fix Suggestion',
                            content: widget.vuln.aiFixSuggestion!,
                            icon: Icons.build_outlined,
                            color: AppColors.accentGreen,
                          )
                        : _LockedProPanel(label: 'AI Fix Suggestion'),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String severity;

  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (severity) {
      case 'critical':
        color = AppColors.severityCritical;
        break;
      case 'high':
        color = AppColors.severityHigh;
        break;
      case 'medium':
        color = AppColors.severityMedium;
        break;
      case 'low':
        color = AppColors.severityLow;
        break;
      default:
        color = AppColors.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        severity.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  final String code;

  const _CodeBlock({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF010409),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SelectableText(
          code,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            color: AppColors.textCode,
          ),
        ),
      ),
    );
  }
}

class _AiPanel extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  final Color color;

  const _AiPanel({
    required this.title,
    required this.content,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.accentPurple.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  'AI ✦',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: AppColors.accentPurple,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedProPanel extends StatelessWidget {
  final String label;

  const _LockedProPanel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 14, color: AppColors.textSubtle),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label — Pro Feature',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSubtle,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => AppNavigator.pushNamed(AppRoutes.subscription),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGreenDim,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Upgrade',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
