import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vulnscan/services/http_client_service.dart';
import 'package:vulnscan/config/constants/app_constants.dart';
import 'package:vulnscan/config/theme/colors.dart';

// Provider for backend health check
final backendHealthProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final httpClient = HttpClientService();
  return await httpClient.checkBackendHealth();
});

/// Backend Status Dashboard Screen
class BackendStatusScreen extends ConsumerStatefulWidget {
  const BackendStatusScreen({super.key});

  @override
  ConsumerState<BackendStatusScreen> createState() =>
      _BackendStatusScreenState();
}

class _BackendStatusScreenState extends ConsumerState<BackendStatusScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final healthData = ref.watch(backendHealthProvider);

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.monitor_heart_outlined,
              color: AppColors.accentGreen,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'Backend Status',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(backendHealthProvider),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(backendHealthProvider),
        color: AppColors.accentGreen,
        backgroundColor: AppColors.bgPrimary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Server info
                _ServerInfoCard(),
                const SizedBox(height: 16),

                // Health status
                healthData.when(
                  data: (data) => _HealthCard(
                    data: data,
                    pulseController: _pulseController,
                  ),
                  loading: () => _LoadingCard(),
                  error: (error, stack) => _ErrorCard(error: error.toString()),
                ),
                const SizedBox(height: 16),

                // Endpoints
                _EndpointsCard(),
                const SizedBox(height: 16),

                // Configuration
                _ConfigCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Sub-widgets ─────────────────────────────────────────────────────────────

class _ServerInfoCard extends StatelessWidget {
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
          Row(
            children: [
              const Icon(
                Icons.cloud_outlined,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                'Backend Server',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderDefault),
          const SizedBox(height: 12),
          SelectableText(
            AppConstants.baseApiUrl,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 13,
              color: AppColors.textCode,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _InfoChip(label: 'Framework', value: 'FastAPI'),
              const SizedBox(width: 8),
              _InfoChip(label: 'Port', value: '8000'),
              const SizedBox(width: 8),
              _InfoChip(label: 'Runtime', value: 'Python 3.11'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HealthCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final AnimationController pulseController;

  const _HealthCard({required this.data, required this.pulseController});

  @override
  Widget build(BuildContext context) {
    final isHealthy = data['status'] == 'healthy';
    final statusColor = isHealthy
        ? AppColors.accentGreen
        : AppColors.severityHigh;

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
            children: [
              AnimatedBuilder(
                animation: pulseController,
                builder: (context, _) {
                  final scale =
                      1.0 +
                      (isHealthy ? 0.15 : 0.0) *
                          (0.5 + 0.5 * pulseController.value);
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 10),
              Text(
                'Server Health',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: statusColor.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy
                      ? '✓  Server is Online'
                      : '⚠  Server is Unreachable',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
                if (data['message'] != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    data['message'],
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: statusColor.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                if (data['timestamp'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 12,
                        color: AppColors.textSubtle,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Last checked: ${data['timestamp']}',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.bgPrimary,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          const CircularProgressIndicator(color: AppColors.accentGreen),
          const SizedBox(height: 14),
          Text(
            'Checking backend health...',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;

  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '✗  Backend Unreachable',
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.error.withValues(alpha: 0.8),
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

class _EndpointsCard extends StatelessWidget {
  final _endpoints = const [
    {'path': '/health', 'method': 'GET', 'desc': 'Check server health'},
    {'path': '/api/scans', 'method': 'GET', 'desc': 'List all scans'},
    {'path': '/api/scans', 'method': 'POST', 'desc': 'Create new scan'},
    {
      'path': '/api/vulnerabilities',
      'method': 'GET',
      'desc': 'List vulnerabilities',
    },
  ];

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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'API Endpoints',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderDefault),
          ..._endpoints.asMap().entries.map((entry) {
            final ep = entry.value;
            final isLast = entry.key == _endpoints.length - 1;
            final isGet = ep['method'] == 'GET';
            final methodColor = isGet
                ? AppColors.accentGreen
                : AppColors.accentBlue;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: isLast
                  ? null
                  : const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: AppColors.borderDefault),
                      ),
                    ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    decoration: BoxDecoration(
                      color: methodColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: methodColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        ep['method']!,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: methodColor,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ep['path']!,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: AppColors.textCode,
                          ),
                        ),
                        Text(
                          ep['desc']!,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ConfigCard extends StatelessWidget {
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
          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Configuration',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.borderDefault),
          _ConfigRow(
            label: 'API Base URL',
            value: AppConstants.baseApiUrl,
            mono: true,
          ),
          const Divider(height: 1, color: AppColors.borderDefault),
          _ConfigRow(
            label: 'Network Timeout',
            value: '${AppConstants.networkTimeout.inSeconds}s',
            mono: true,
          ),
          const Divider(height: 1, color: AppColors.borderDefault),
          _ConfigRow(label: 'Environment', value: 'Development', mono: false),
        ],
      ),
    );
  }
}

class _ConfigRow extends StatelessWidget {
  final String label;
  final String value;
  final bool mono;

  const _ConfigRow({
    required this.label,
    required this.value,
    required this.mono,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          SelectableText(
            value,
            style: mono
                ? GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.textCode,
                  )
                : GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgSecondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSubtle),
          ),
          Text(
            value,
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: AppColors.textCode,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
