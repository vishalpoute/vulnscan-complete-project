import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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
  String _selectedScanType = 'web';
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

    if (!GitHubUrlValidator.isValid(url)) {
      _showError(GitHubUrlValidator.getErrorMessage(url));
      return;
    }

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
      final scan = await api.createScan(
        repositoryUrl: url,
        scanType: _selectedScanType,
      );
      if (mounted) {
        AppNavigator.pushReplacementNamed(
          AppRoutes.scanProgress,
          arguments: scan.id,
        );
      }
    } catch (e) {
      if (mounted) _showError('Failed to create scan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showUpgradeDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Quota Exceeded',
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'You have reached your monthly scan limit. Upgrade your plan to continue scanning.',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
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
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
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
            const Icon(Icons.radar, color: AppColors.accentGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'New Scan',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Page description
                Text(
                  'Scan a GitHub Repository',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Paste a public GitHub URL to detect vulnerabilities across your codebase.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Repository URL card
                _ScanFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'GitHub Repository URL'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _urlController,
                        onChanged: _validateUrl,
                        enabled: !_isLoading,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'https://github.com/owner/repo',
                          hintStyle: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: AppColors.textSubtle,
                          ),
                          prefixIcon: const Icon(
                            Icons.link,
                            size: 18,
                            color: AppColors.textSubtle,
                          ),
                          errorText: _urlError,
                          errorMaxLines: 2,
                          errorStyle: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                      if (_urlError == null &&
                          _urlController.text.isNotEmpty &&
                          GitHubUrlValidator.isValid(_urlController.text)) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 14,
                              color: AppColors.accentGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Valid GitHub URL',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.accentGreen,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Scan type card
                _ScanFormCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FieldLabel(label: 'Scan Type'),
                      const SizedBox(height: 4),
                      Text(
                        'Choose what type of application to scan',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _ScanTypeButton(
                            value: 'web',
                            selected: _selectedScanType,
                            icon: Icons.language_outlined,
                            label: 'Web App',
                            description: 'Semgrep · npm audit',
                            onTap: (v) => setState(() => _selectedScanType = v),
                          ),
                          const SizedBox(width: 10),
                          _ScanTypeButton(
                            value: 'android',
                            selected: _selectedScanType,
                            icon: Icons.android_outlined,
                            label: 'Android',
                            description: 'MobSF · Bandit',
                            onTap: (v) => setState(() => _selectedScanType = v),
                          ),
                          const SizedBox(width: 10),
                          _ScanTypeButton(
                            value: 'ios',
                            selected: _selectedScanType,
                            icon: Icons.phone_iphone_outlined,
                            label: 'iOS',
                            description: 'MobSF · Semgrep',
                            onTap: (v) => setState(() => _selectedScanType = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quota
                subscriptionState.maybeWhen(
                  data: (subscription) => subscription != null
                      ? _ScanFormCard(
                          child: Row(
                            children: [
                              Icon(
                                subscription.canCreateScan
                                    ? Icons.check_circle_outline
                                    : Icons.error_outline,
                                size: 16,
                                color: subscription.canCreateScan
                                    ? AppColors.accentGreen
                                    : AppColors.error,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Monthly Quota',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${subscription.scansUsed} / ${subscription.scansLimit} scans used',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!subscription.canCreateScan)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppColors.error.withValues(
                                        alpha: 0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    'Limit Reached',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                  loading: () => const SizedBox(),
                  orElse: () => const SizedBox(),
                ),
                const SizedBox(height: 24),

                // Start scan button
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleStartScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentGreenDim,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.radar,
                                size: 18,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Start Security Scan',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),

                const SizedBox(height: 16),
                // Info note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 12,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Code runs in isolated Docker containers and is never stored permanently.',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSubtle,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScanFormCard extends StatelessWidget {
  final Widget child;

  const _ScanFormCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: child,
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ScanTypeButton extends StatelessWidget {
  final String value;
  final String selected;
  final IconData icon;
  final String label;
  final String description;
  final void Function(String) onTap;

  const _ScanTypeButton({
    required this.value,
    required this.selected,
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accentGreen.withValues(alpha: 0.1)
                : AppColors.bgSecondary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected
                  ? AppColors.accentGreen
                  : AppColors.borderDefault,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? AppColors.accentGreen
                    : AppColors.textSecondary,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? AppColors.accentGreen
                      : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 9,
                  color: AppColors.textSubtle,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
