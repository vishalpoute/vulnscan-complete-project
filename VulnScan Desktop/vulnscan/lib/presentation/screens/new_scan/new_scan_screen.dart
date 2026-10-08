import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vulnscan/config/routing/app_router.dart';
import 'package:vulnscan/config/theme/colors.dart';
import 'package:vulnscan/data/datasources/api_datasource.dart';
import 'package:vulnscan/presentation/providers/subscription_provider.dart';
import 'package:vulnscan/services/http_client_service.dart';
import 'package:vulnscan/utils/validators/github_url_validator.dart';

class NewScanScreen extends ConsumerStatefulWidget {
  const NewScanScreen({super.key});

  @override
  ConsumerState<NewScanScreen> createState() => _NewScanScreenState();
}

class _NewScanScreenState extends ConsumerState<NewScanScreen> {
  late TextEditingController _urlController;
  String _selectedScanType = 'web'; // 'web', 'android', 'ios'
  bool _isLoading = false;
  String? _urlError;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _validateUrl(String value) {
    setState(() {
      if (value.isEmpty) {
        _urlError = null;
      } else if (!GitHubUrlValidator.isValid(value)) {
        _urlError = GitHubUrlValidator.getErrorMessage(value);
      } else {
        _urlError = null;
      }
    });
  }

  Future<void> _handleStartScan() async {
    final url = _urlController.text.trim();

    // Validate URL
    if (!GitHubUrlValidator.isValid(url)) {
      _showError(GitHubUrlValidator.getErrorMessage(url));
      return;
    }

    // Check quota
    final subscriptionState = ref.read(subscriptionProvider);
    final canCreate = subscriptionState.maybeWhen(
      data: (sub) => sub?.canCreateScan ?? false,
      orElse: () => false,
    );

    if (!canCreate) {
      await _showUpgradeDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final httpClient = HttpClientService();
      final api = ApiDatasource(dio: httpClient.dio);

      // Create scan
      final scan = await api.createScan(repositoryUrl: url, scanType: _selectedScanType);

      // Navigate to progress screen
      if (mounted) {
        AppNavigator.pushReplacementNamed(
          AppRoutes.scanProgress,
          arguments: scan.id,
        );
      }
    } catch (e) {
      if (mounted) {
        _showError('Failed to create scan: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showUpgradeDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quota Exceeded'),
        content: const Text('You have reached your monthly scan limit. Upgrade your plan to continue scanning.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Theme.of(context).colorScheme.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionState = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // GitHub URL section
                Text(
                  'GitHub Repository',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  onChanged: _validateUrl,
                  decoration: InputDecoration(
                    labelText: 'Repository URL',
                    prefixIcon: const Icon(Icons.link),
                    hintText: 'https://github.com/owner/repo',
                    errorText: _urlError,
                    errorMaxLines: 2,
                    enabled: !_isLoading,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 24),

                // Scan type selector
                Text(
                  'Scan Type',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'web',
                      label: Text('Web App'),
                      icon: Icon(Icons.language),
                    ),
                    ButtonSegment(
                      value: 'android',
                      label: Text('Android'),
                      icon: Icon(Icons.android),
                    ),
                    ButtonSegment(
                      value: 'ios',
                      label: Text('iOS'),
                      icon: Icon(Icons.phone_iphone),
                    ),
                  ],
                  selected: {_selectedScanType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() => _selectedScanType = newSelection.first);
                  },
                ),
                const SizedBox(height: 24),

                // Quota info
                subscriptionState.maybeWhen(
                  data: (subscription) => subscription != null
                      ? Card(
                          color: subscription.canCreateScan
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Monthly Quota',
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${subscription.scansUsed} / ${subscription.scansLimit} scans',
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                    if (!subscription.canCreateScan)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.error,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Limit Reached',
                                          style: TextStyle(color: Colors.white, fontSize: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox(),
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: CircularProgressIndicator(),
                  ),
                  orElse: () => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // Start scan button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleStartScan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start Scan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
