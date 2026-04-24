import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vulnscan/config/theme/colors.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() =>
      _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;

  Future<void> _upgradeToRazorpay(String planId, double amount) async {
    if (planId == 'free') return;

    setState(() => _isLoading = true);

    try {
      final planName = planId == 'pro' ? 'VulnScan Pro' : 'VulnScan Enterprise';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Redirecting to payment for $planName (\$$amount)...'),
          backgroundColor: AppColors.accentBlue,
          duration: const Duration(seconds: 2),
        ),
      );

      const razorpayUrl = 'https://rzp.io/i/w2CEwbJ1';
      final uri = Uri.parse(razorpayUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch payment link';
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.workspace_premium_outlined,
                color: AppColors.accentGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'Plans & Pricing',
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Choose Your Plan',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Start free and scale as your security needs grow.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),

              // Plan cards
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _PlanCard(
                      name: 'Free',
                      price: '₹0',
                      period: 'forever',
                      description: 'For individual developers getting started.',
                      features: const [
                        '5 scans / month',
                        'Web & Mobile scanning',
                        'Severity reports',
                        'Basic support',
                      ],
                      lockedFeatures: const [
                        'AI Explanations',
                        'PDF Export',
                        'Priority support',
                      ],
                      planId: 'free',
                      isPopular: false,
                      isCurrent: true,
                      isLoading: _isLoading,
                      onUpgrade: _upgradeToRazorpay,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PlanCard(
                      name: 'Pro',
                      price: '₹829',
                      period: 'per month',
                      description: 'For professional developers and small teams.',
                      features: const [
                        '100 scans / month',
                        'Web & Mobile scanning',
                        'AI explanations & fixes',
                        'PDF report export',
                        'Priority support',
                        'Shareable report links',
                      ],
                      lockedFeatures: const [],
                      planId: 'pro',
                      isPopular: true,
                      isCurrent: false,
                      isLoading: _isLoading,
                      onUpgrade: _upgradeToRazorpay,
                      amount: 9.99,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PlanCard(
                      name: 'Enterprise',
                      price: '₹8,299',
                      period: 'per month',
                      description: 'For teams that need unlimited security coverage.',
                      features: const [
                        'Unlimited scans',
                        'All Pro features',
                        'Team collaboration',
                        'Role-based access',
                        'Dedicated support',
                        'Custom integrations',
                        'Scheduled auto-scans',
                      ],
                      lockedFeatures: const [],
                      planId: 'enterprise',
                      isPopular: false,
                      isCurrent: false,
                      isLoading: _isLoading,
                      onUpgrade: _upgradeToRazorpay,
                      amount: 99.99,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Feature comparison note
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgPrimary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.borderDefault),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppColors.accentBlue,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'All plans include isolated Docker containers ensuring your code is never permanently stored. Payments are secured by Razorpay.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Plan Card ────────────────────────────────────────────────────────────────

class _PlanCard extends StatelessWidget {
  final String name;
  final String price;
  final String period;
  final String description;
  final List<String> features;
  final List<String> lockedFeatures;
  final String planId;
  final bool isPopular;
  final bool isCurrent;
  final bool isLoading;
  final Future<void> Function(String, double) onUpgrade;
  final double amount;

  const _PlanCard({
    required this.name,
    required this.price,
    required this.period,
    required this.description,
    required this.features,
    required this.lockedFeatures,
    required this.planId,
    required this.isPopular,
    required this.isCurrent,
    required this.isLoading,
    required this.onUpgrade,
    this.amount = 0,
  });

  Color get _accentColor {
    switch (planId) {
      case 'pro':
        return AppColors.accentBlue;
      case 'enterprise':
        return AppColors.accentPurple;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(0),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPopular ? AppColors.accentBlue : AppColors.borderDefault,
          width: isPopular ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top accent bar (only for popular)
          if (isPopular)
            Container(
              height: 3,
              decoration: const BoxDecoration(
                color: AppColors.accentBlue,
                borderRadius: BorderRadius.vertical(top: Radius.circular(7)),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + badge
                Row(
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isPopular)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accentBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accentBlue.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'Popular',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentBlue,
                          ),
                        ),
                      ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgSecondary,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.borderDefault),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                // Price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: _accentColor == AppColors.textSecondary
                            ? AppColors.textPrimary
                            : _accentColor,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        period,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: AppColors.borderDefault),
                const SizedBox(height: 16),

                // Features
                ...features.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check,
                          size: 14,
                          color: AppColors.accentGreen,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Locked features
                ...lockedFeatures.map(
                  (f) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 13,
                          color: AppColors.textSubtle,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textSubtle,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: AppColors.textSubtle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // CTA button
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: planId == 'free'
                      ? OutlinedButton(
                          onPressed: null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSubtle,
                            side: const BorderSide(
                              color: AppColors.borderDefault,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            'Current Plan',
                            style: GoogleFonts.inter(fontSize: 13),
                          ),
                        )
                      : ElevatedButton(
                          onPressed: isLoading
                              ? null
                              : () => onUpgrade(planId, amount),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPopular
                                ? AppColors.accentBlue
                                : AppColors.accentGreenDim,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Upgrade to $name',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
