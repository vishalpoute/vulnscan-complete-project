import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:vulnscan/config/routing/app_router.dart';
import 'package:vulnscan/config/theme/colors.dart';
import 'package:vulnscan/data/datasources/api_datasource.dart';
import 'package:vulnscan/presentation/providers/auth_provider.dart';
import 'package:vulnscan/presentation/providers/subscription_provider.dart';
import 'package:vulnscan/services/http_client_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final httpClient = HttpClientService();
    final api = ApiDatasource(dio: httpClient.dio);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: _buildAppBar(context, authState),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            authState.maybeWhen(
              data: (user) {
                if (user == null) return const SizedBox();
                // Friendly name: displayName > email username > full email
                final friendlyName = user.displayName?.isNotEmpty == true
                    ? user.displayName!
                    : (user.email.contains('@')
                          ? user.email.split('@').first
                          : user.email);
                final initial = friendlyName.isNotEmpty
                    ? friendlyName.substring(0, 1).toUpperCase()
                    : '?';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.accentGreen.withValues(
                              alpha: 0.15,
                            ),
                            border: Border.all(
                              color: AppColors.accentGreen.withValues(
                                alpha: 0.5,
                              ),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.jetBrainsMono(
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back, $friendlyName 👋',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
              orElse: () => const SizedBox(),
            ),

            // Quota card
            subscriptionState.maybeWhen(
              data: (subscription) => subscription != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subscription.isOffline)
                          _GitHubAlert(
                            icon: Icons.cloud_off_outlined,
                            color: AppColors.warning,
                            message:
                                'Using offline defaults. Connect to sync your subscription.',
                          ),
                        _QuotaCard(subscription: subscription),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox(),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.accentGreen,
                  ),
                ),
              ),
              error: (e, s) => const SizedBox(),
              orElse: () => const SizedBox(),
            ),

            // Scans section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Scans',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                _CyberButton(
                  label: 'New Scan',
                  icon: Icons.add,
                  onTap: () => AppNavigator.pushNamed(AppRoutes.newScan),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Scans list
            FutureBuilder(
              future: api.getUserScans(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.accentGreen,
                      ),
                    ),
                  );
                }
                if (snapshot.hasError) {
                  return _ErrorCard(
                    message: 'Failed to load scans: ${snapshot.error}',
                  );
                }

                final scans = snapshot.data ?? [];
                if (scans.isEmpty) {
                  return _EmptyScansState();
                }

                int totalCritical = 0;
                int totalHigh = 0;
                int totalMedium = 0;
                int totalLow = 0;

                for (final scan in scans) {
                  if (scan.status == 'completed') {
                    totalCritical += scan.criticalVulnCount ?? 0;
                    totalHigh += scan.highVulnCount ?? 0;
                    totalMedium += scan.mediumVulnCount ?? 0;
                    totalLow += scan.lowVulnCount ?? 0;
                  }
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat cards row
                    _StatCardsRow(
                      critical: totalCritical,
                      high: totalHigh,
                      medium: totalMedium,
                      low: totalLow,
                    ),
                    const SizedBox(height: 20),

                    // Pie chart
                    if (totalCritical + totalHigh + totalMedium + totalLow >
                        0) ...[
                      _VulnPieChart(
                        critical: totalCritical,
                        high: totalHigh,
                        medium: totalMedium,
                        low: totalLow,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Scans table
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.bgPrimary,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.borderDefault),
                      ),
                      child: Column(
                        children: [
                          // Table header
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.bgSecondary,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(6),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Repository',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'Date',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Status',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Rows
                          ...scans.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final scan = entry.value;
                            return _ScanRow(
                              scan: scan,
                              isLast: idx == scans.length - 1,
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AsyncValue<User?> authState,
  ) {
    return AppBar(
      title: Row(
        children: [
          const Icon(
            Icons.shield_outlined,
            color: AppColors.accentGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'VulnScan',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_outlined),
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(subscriptionProvider),
        ),
        authState.maybeWhen(
          data: (user) => user?.email == 'vishupoute154@gmail.com'
              ? IconButton(
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  tooltip: 'Admin Panel',
                  onPressed: () => AppNavigator.pushNamed(AppRoutes.admin),
                )
              : const SizedBox.shrink(),
          orElse: () => const SizedBox.shrink(),
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Settings',
          onPressed: () => AppNavigator.pushNamed(AppRoutes.settings),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                AppNavigator.pushNamedAndRemoveUntil(AppRoutes.login);
              }
            },
          ),
        ),
      ],
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _GitHubAlert extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _GitHubAlert({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuotaCard extends StatelessWidget {
  final dynamic subscription;

  const _QuotaCard({required this.subscription});

  @override
  Widget build(BuildContext context) {
    final used = subscription.scansUsed as int;
    final limit = subscription.scansLimit as int;
    final progress = limit > 0 ? used / limit : 0.0;
    final tier = subscription.tier as String;

    Color tierColor;
    switch (tier.toLowerCase()) {
      case 'pro':
        tierColor = AppColors.accentBlue;
        break;
      case 'enterprise':
        tierColor = AppColors.accentPurple;
        break;
      default:
        tierColor = AppColors.textSecondary;
    }

    return Container(
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
              Text(
                'Monthly Quota',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: tierColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: tierColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  tier.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: tierColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.bgSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8
                    ? AppColors.severityCritical
                    : AppColors.accentGreen,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$used of $limit scans used this month',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCardsRow extends StatelessWidget {
  final int critical, high, medium, low;

  const _StatCardsRow({
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
  });

  @override
  Widget build(BuildContext context) {
    final total = critical + high + medium + low;
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Total',
            value: total,
            color: AppColors.accentBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Critical',
            value: critical,
            color: AppColors.severityCritical,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'High',
            value: high,
            color: AppColors.severityHigh,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Medium',
            value: medium,
            color: AppColors.severityMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Low',
            value: low,
            color: AppColors.severityLow,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _VulnPieChart extends StatelessWidget {
  final int critical, high, medium, low;

  const _VulnPieChart({
    required this.critical,
    required this.high,
    required this.medium,
    required this.low,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vulnerability Breakdown',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      if (critical > 0)
                        PieChartSectionData(
                          value: critical.toDouble(),
                          color: AppColors.severityCritical,
                          title: '$critical',
                          titleStyle: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          radius: 50,
                        ),
                      if (high > 0)
                        PieChartSectionData(
                          value: high.toDouble(),
                          color: AppColors.severityHigh,
                          title: '$high',
                          titleStyle: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          radius: 50,
                        ),
                      if (medium > 0)
                        PieChartSectionData(
                          value: medium.toDouble(),
                          color: AppColors.severityMedium,
                          title: '$medium',
                          titleStyle: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                          radius: 50,
                        ),
                      if (low > 0)
                        PieChartSectionData(
                          value: low.toDouble(),
                          color: AppColors.severityLow,
                          title: '$low',
                          titleStyle: GoogleFonts.jetBrainsMono(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          radius: 50,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LegendItem(
                    label: 'Critical',
                    count: critical,
                    color: AppColors.severityCritical,
                  ),
                  const SizedBox(height: 10),
                  _LegendItem(
                    label: 'High',
                    count: high,
                    color: AppColors.severityHigh,
                  ),
                  const SizedBox(height: 10),
                  _LegendItem(
                    label: 'Medium',
                    count: medium,
                    color: AppColors.severityMedium,
                  ),
                  const SizedBox(height: 10),
                  _LegendItem(
                    label: 'Low',
                    count: low,
                    color: AppColors.severityLow,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _LegendItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          '$count',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _ScanRow extends StatelessWidget {
  final dynamic scan;
  final bool isLast;

  const _ScanRow({required this.scan, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          AppNavigator.pushNamed(AppRoutes.scanReport, arguments: scan.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(color: AppColors.borderDefault),
                ),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  const Icon(
                    Icons.folder_outlined,
                    size: 15,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      scan.repositoryUrl.split('/').last,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM dd, yyyy').format(scan.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            _StatusBadge(status: scan.status),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'completed':
        color = AppColors.accentGreen;
        icon = Icons.check_circle_outline;
        break;
      case 'scanning':
        color = AppColors.accentBlue;
        icon = Icons.hourglass_bottom_outlined;
        break;
      case 'failed':
        color = AppColors.error;
        icon = Icons.cancel_outlined;
        break;
      default:
        color = AppColors.textSecondary;
        icon = Icons.schedule_outlined;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyScansState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.borderDefault,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.shield_outlined,
            size: 48,
            color: AppColors.textSubtle,
          ),
          const SizedBox(height: 16),
          Text(
            'No scans yet',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Paste a GitHub URL to start scanning for vulnerabilities.',
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSubtle),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          _CyberButton(
            label: 'Start First Scan',
            icon: Icons.add,
            onTap: () => AppNavigator.pushNamed(AppRoutes.newScan),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _CyberButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _CyberButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.accentGreenDim,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.accentGreenDim),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
