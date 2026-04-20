import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/api_provider.dart';
import 'widgets/analytics_card.dart';
import 'widgets/users_table.dart';
import 'widgets/scans_table.dart';
import 'widgets/feedback_list.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      appBar: AppBar(
        title: const Text('VulnScan Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(logoutProvider.future).then((_) {
                // Will redirect to login screen via auth provider
              });
            },
          ),
        ],
      ),
      body: Row(
        children: [
          if (!isMobile)
            NavigationRail(
              selectedIndex: _selectedTab,
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.dashboard),
                  label: Text('Overview'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.people),
                  label: Text('Users'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.search),
                  label: Text('Scans'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.feedback),
                  label: Text('Feedback'),
                ),
              ],
            ),
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      bottomNavigationBar: isMobile
          ? BottomNavigationBar(
              currentIndex: _selectedTab,
              onTap: (index) {
                setState(() {
                  _selectedTab = index;
                });
              },
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
                BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Users'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Scans'),
                BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
              ],
            )
          : null,
    );
  }

  Widget _buildContent() {
    switch (_selectedTab) {
      case 0:
        return const _OverviewTab();
      case 1:
        return const UsersTable();
      case 2:
        return const ScansTable();
      case 3:
        return const FeedbackList();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(analyticsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          analyticsAsync.when(
            data: (analytics) {
              return Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      AnalyticsCard(
                        title: 'Total Users',
                        value: '${analytics['total_users'] ?? 0}',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      AnalyticsCard(
                        title: 'Total Scans',
                        value: '${analytics['total_scans'] ?? 0}',
                        icon: Icons.search,
                        color: Colors.green,
                      ),
                      AnalyticsCard(
                        title: 'Scans Today',
                        value: '${analytics['scans_today'] ?? 0}',
                        icon: Icons.today,
                        color: Colors.orange,
                      ),
                      AnalyticsCard(
                        title: 'Critical Vulns',
                        value: '${analytics['vuln_breakdown']?['critical'] ?? 0}',
                        icon: Icons.warning,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (err, stack) => Text('Error: $err'),
          ),
        ],
      ),
    );
  }
}
