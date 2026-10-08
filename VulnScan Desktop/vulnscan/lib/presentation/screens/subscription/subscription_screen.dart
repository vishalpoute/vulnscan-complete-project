import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _isLoading = false;

  /// Redirect directly to Razorpay - NO DIALOGS
  Future<void> _upgradeToRazorpay(String planId, double amount) async {
    if (planId == 'free') return;

    setState(() => _isLoading = true);

    try {
      final planName = planId == 'pro' ? 'VulnScan Pro' : 'VulnScan Enterprise';
      
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔄 Redirecting to Razorpay for $planName (\$$amount)...'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );

      // Razorpay payment link - Replace with your actual link
      const razorpayUrl = 'https://rzp.io/i/w2CEwbJ1';
      
      // Open Razorpay in external browser/app
      try {
        final uri = Uri.parse(razorpayUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch Razorpay link';
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error opening Razorpay: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upgrade Your Plan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Choose Your Plan',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildPlanCard(
            context: context,
            name: 'Free',
            price: '0',
            period: 'Forever',
            features: ['5 scans', 'Basic support'],
            planId: 'free',
            isPopular: false,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            context: context,
            name: 'Pro',
            price: '9.99',
            period: 'Monthly',
            features: ['100 scans', 'Priority support', 'API access'],
            planId: 'pro',
            isPopular: true,
            amount: 9.99,
          ),
          const SizedBox(height: 16),
          _buildPlanCard(
            context: context,
            name: 'Enterprise',
            price: '99.99',
            period: 'Monthly',
            features: ['Unlimited scans', 'Dedicated support', 'Custom integration'],
            planId: 'enterprise',
            isPopular: false,
            amount: 99.99,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String name,
    required String price,
    required String period,
    required List<String> features,
    required String planId,
    required bool isPopular,
    double amount = 0,
  }) {
    return Card(
      elevation: isPopular ? 8 : 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Popular',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (planId == 'free')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Current',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '\$$price / $period',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
            ),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Colors.green, size: 16),
                  const SizedBox(width: 8),
                  Text(f),
                ],
              ),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: planId == 'free' ? Colors.grey : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: planId == 'free'
                    ? null
                    : () => _upgradeToRazorpay(planId, amount),
                child: _isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        planId == 'free' ? 'Current Plan' : 'Upgrade',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

