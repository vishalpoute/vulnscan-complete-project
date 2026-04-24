import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vulnscan/config/routing/app_router.dart';
import 'package:vulnscan/config/theme/colors.dart';
import 'package:vulnscan/data/models/subscription_model.dart';
import 'package:vulnscan/presentation/providers/auth_provider.dart';
import 'package:vulnscan/presentation/providers/subscription_provider.dart';
import 'package:vulnscan/presentation/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final subscriptionState = ref.watch(subscriptionProvider);
    final themeMode = ref.watch(themeNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.settings_outlined, color: AppColors.accentGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'Settings',
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile section
                _SectionHeader(title: 'Profile'),
                const SizedBox(height: 12),
                _ProfileCard(authState: authState),
                const SizedBox(height: 28),

                // Subscription section
                _SectionHeader(title: 'Subscription'),
                const SizedBox(height: 12),
                _SubscriptionCard(subscriptionState: subscriptionState),
                const SizedBox(height: 28),

                // Appearance
                _SectionHeader(title: 'Appearance'),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.dark_mode_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Dark Mode',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: themeMode == ThemeMode.dark,
                        onChanged: (_) =>
                            ref.read(themeNotifierProvider.notifier).toggle(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Security
                _SectionHeader(title: 'Security'),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Change Password',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'A password reset link will be sent to your email address.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Password reset sent to email'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.lock_reset_outlined, size: 16),
                        label: const Text('Send Reset Link'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textPrimary,
                          side: const BorderSide(color: AppColors.borderDefault),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // About / Backend
                _SectionHeader(title: 'About'),
                const SizedBox(height: 12),
                _SettingsCard(
                  child: Column(
                    children: [
                      _InfoRow(
                        label: 'Version',
                        value: 'v1.0.0',
                        mono: true,
                      ),
                      const Divider(height: 20, color: AppColors.borderDefault),
                      _InfoRow(label: 'Backend', value: 'FastAPI + Python', mono: false),
                      const Divider(height: 20, color: AppColors.borderDefault),
                      InkWell(
                        onTap: () =>
                            AppNavigator.pushNamed(AppRoutes.backendStatus),
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Backend Status',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    'View →',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: AppColors.accentBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Danger zone
                _SectionHeader(title: 'Danger Zone', isDanger: true),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.error.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delete Account',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Permanently delete your account and all associated data. This action cannot be undone.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton(
                        onPressed: () => _showDeleteDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        child: Text(
                          'Delete Account',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete Account',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Account deletion initiated')),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDanger;

  const _SectionHeader({required this.title, this.isDanger = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDanger ? AppColors.error : AppColors.textPrimary,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;

  const _SettingsCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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

class _ProfileCard extends StatelessWidget {
  final AsyncValue<User?> authState;

  const _ProfileCard({required this.authState});

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      child: authState.when(
        data: (user) {
          if (user == null) return const SizedBox();
          return Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentGreen.withOpacity(0.15),
                  border: Border.all(
                    color: AppColors.accentGreen.withOpacity(0.4),
                  ),
                ),
                child: Center(
                  child: Text(
                    (() {
                      final name = (user.displayName?.isNotEmpty == true ? user.displayName! : user.email);
                      return name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?';
                    })(),
                    style: GoogleFonts.jetBrainsMono(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName ?? 'User',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const CircularProgressIndicator(
          color: AppColors.accentGreen,
        ),
        error: (e, s) =>
            Text('Error: $e', style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final AsyncValue<SubscriptionInfo?> subscriptionState;

  const _SubscriptionCard({required this.subscriptionState});

  @override
  Widget build(BuildContext context) {
    return subscriptionState.when(
      data: (sub) {
        if (sub == null) return const SizedBox();
        final progress = sub.scansLimit > 0 ? sub.scansUsed / sub.scansLimit : 0.0;
        final tierColor = _tierColor(sub.tier);

        return _SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Current Plan',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: tierColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: tierColor.withOpacity(0.5)),
                    ),
                    child: Text(
                      sub.tier.toUpperCase(),
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
                    progress > 0.8 ? AppColors.error : tierColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${sub.scansUsed} / ${sub.scansLimit} scans used',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (sub.tier == 'free') ...[
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        AppNavigator.pushNamed(AppRoutes.subscription),
                    child: const Text('Upgrade Plan'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.accentGreen),
      ),
      error: (e, s) => const SizedBox(),
    );
  }

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'pro':
        return AppColors.accentBlue;
      case 'enterprise':
        return AppColors.accentPurple;
      default:
        return AppColors.textSecondary;
    }
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _InfoRow({required this.label, required this.value, required this.mono});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: mono
              ? GoogleFonts.jetBrainsMono(
                  fontSize: 13,
                  color: AppColors.textCode,
                )
              : GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
        ),
      ],
    );
  }
}
