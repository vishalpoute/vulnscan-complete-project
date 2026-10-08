import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(subscriptionProvider);
            },
          ),
          // Admin panel button (only for admin user)
          authState.maybeWhen(
            data: (user) => user?.email == 'vishupoute154@gmail.com'
                ? IconButton(
                    icon: const Icon(Icons.admin_panel_settings),
                    tooltip: 'Admin Panel',
                    onPressed: () =>
                        AppNavigator.pushNamed(AppRoutes.admin),
                  )
                : const SizedBox.shrink(),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => AppNavigator.pushNamed(AppRoutes.settings),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (context.mounted) {
                AppNavigator.pushNamedAndRemoveUntil(AppRoutes.login);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            authState.maybeWhen(
              data: (user) => user != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user.displayName ?? user.email}!',
                          style: Theme.of(context).textTheme.headlineLarge,
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox(),
              orElse: () => const SizedBox(),
            ),

            // Quota indicator
            subscriptionState.maybeWhen(
              data: (subscription) => subscription != null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (subscription.isOffline)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.amber[100],
                              border: Border.all(color: Colors.amber[700]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info,
                                  color: Colors.amber[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Using default plan. Connect to update your subscription.',
                                    style: TextStyle(
                                      color: Colors.amber[900],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Monthly Quota',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: subscription.canCreateScan
                                            ? AppColors.success
                                            : AppColors.error,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        subscription.tier.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value:
                                        subscription.scansUsed /
                                        subscription.scansLimit,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation(
                                      subscription.canCreateScan
                                          ? AppColors.success
                                          : AppColors.error,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '${subscription.scansUsed} of ${subscription.scansLimit} scans used this month',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    )
                  : const SizedBox(),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => const SizedBox(),
              orElse: () => const SizedBox(),
            ),

            // Scan history section
            Text('Recent Scans', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FutureBuilder(
              future: api.getUserScans(limit: 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Failed to load scans: ${snapshot.error}'),
                  );
                }

                final scans = snapshot.data ?? [];
                if (scans.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.folder_open, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(
                            'No scans yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                AppNavigator.pushNamed(AppRoutes.newScan),
                            child: const Text('Start First Scan'),
                          ),
                        ],
                      ),
                    ),
                  );
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
                  children: [
                    // Severity breakdown chart
                    if (totalCritical + totalHigh + totalMedium + totalLow > 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vulnerability Breakdown',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 200,
                                child: PieChart(
                                  PieChartData(
                                    sections: [
                                      if (totalCritical > 0)
                                        PieChartSectionData(
                                          value: totalCritical.toDouble(),
                                          color: AppColors.severityCritical,
                                          title: '$totalCritical',
                                        ),
                                      if (totalHigh > 0)
                                        PieChartSectionData(
                                          value: totalHigh.toDouble(),
                                          color: AppColors.severityHigh,
                                          title: '$totalHigh',
                                        ),
                                      if (totalMedium > 0)
                                        PieChartSectionData(
                                          value: totalMedium.toDouble(),
                                          color: AppColors.severityMedium,
                                          title: '$totalMedium',
                                        ),
                                      if (totalLow > 0)
                                        PieChartSectionData(
                                          value: totalLow.toDouble(),
                                          color: AppColors.severityLow,
                                          title: '$totalLow',
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _SeverityBadge(
                                    label: 'Critical',
                                    count: totalCritical,
                                    color: AppColors.severityCritical,
                                  ),
                                  _SeverityBadge(
                                    label: 'High',
                                    count: totalHigh,
                                    color: AppColors.severityHigh,
                                  ),
                                  _SeverityBadge(
                                    label: 'Medium',
                                    count: totalMedium,
                                    color: AppColors.severityMedium,
                                  ),
                                  _SeverityBadge(
                                    label: 'Low',
                                    count: totalLow,
                                    color: AppColors.severityLow,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Scans list
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: scans.length,
                      itemBuilder: (context, index) {
                        final scan = scans[index];
                        return Card(
                          child: ListTile(
                            title: Text(scan.repositoryUrl.split('/').last),
                            subtitle: Text(
                              DateFormat('MMM dd, yyyy').format(scan.createdAt),
                            ),
                            trailing: _StatusChip(status: scan.status),
                            onTap: () => AppNavigator.pushNamed(
                              AppRoutes.scanReport,
                              arguments: scan.id,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => AppNavigator.pushNamed(AppRoutes.newScan),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _SeverityBadge extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SeverityBadge({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Center(
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

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
      case 'scanning':
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
        backgroundColor = Colors.grey;
        textColor = Colors.white;
        icon = Icons.schedule;
    }

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: TextStyle(color: textColor, fontSize: 12),
      ),
      backgroundColor: backgroundColor,
      avatar: Icon(icon, color: textColor, size: 16),
    );
  }
}
