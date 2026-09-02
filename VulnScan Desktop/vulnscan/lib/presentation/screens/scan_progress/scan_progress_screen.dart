import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vulnscan/config/routing/app_router.dart';
import 'package:vulnscan/config/theme/colors.dart';
import 'package:vulnscan/data/datasources/api_datasource.dart';
import 'package:vulnscan/data/models/scan_progress_model.dart';
import 'package:vulnscan/domain/failures.dart';
import 'package:vulnscan/services/http_client_service.dart';

// ── Error classification helper ──────────────────────────────────────────────

class _ScanError {
  final String title;
  final String detail;
  final String? hint;
  final Color color;
  final IconData icon;

  const _ScanError({
    required this.title,
    required this.detail,
    this.hint,
    required this.color,
    required this.icon,
  });

  static _ScanError from(Object error) {
    if (error is NetworkFailure) {
      return _ScanError(
        title: 'Network Error',
        detail: error.message,
        hint: 'Check your internet connection and that the backend is running.',
        color: AppColors.severityHigh,
        icon: Icons.wifi_off_outlined,
      );
    }
    if (error is AuthFailure) {
      return _ScanError(
        title: 'Authentication Error',
        detail: error.message,
        hint: 'Your session may have expired. Try signing out and back in.',
        color: AppColors.severityCritical,
        icon: Icons.lock_outline,
      );
    }
    if (error is SubscriptionFailure) {
      return _ScanError(
        title: 'Subscription / Quota Error',
        detail: error.message,
        hint:
            'You may have exceeded your monthly scan limit. Upgrade your plan.',
        color: AppColors.severityMedium,
        icon: Icons.workspace_premium_outlined,
      );
    }
    if (error is ServerFailure) {
      final code = error.statusCode;
      String hint;
      if (code == 500) {
        hint =
            'Internal server error. The backend crashed or the database is unreachable.';
      } else if (code == 503)
        hint =
            'Backend service unavailable. It may be starting up or overloaded.';
      else if (code == 404)
        hint =
            'Scan not found. It may have been deleted or the scan ID is invalid.';
      else if (code == 422)
        hint =
            'Invalid request data sent to the server. Check the repository URL.';
      else
        hint = 'An unexpected server error occurred (HTTP $code).';
      return _ScanError(
        title: 'Server Error${code != null ? " (HTTP $code)" : ""}',
        detail: error.message,
        hint: hint,
        color: AppColors.severityCritical,
        icon: Icons.dns_outlined,
      );
    }
    // Generic / connection refused
    final msg = error.toString();
    if (msg.contains('connection') ||
        msg.contains('SocketException') ||
        msg.contains('refused')) {
      return _ScanError(
        title: 'Backend Unreachable',
        detail: 'Cannot connect to localhost:8000',
        hint:
            'The FastAPI backend is not running. Start it with: uvicorn main:app --reload',
        color: AppColors.severityHigh,
        icon: Icons.cloud_off_outlined,
      );
    }
    if (msg.contains('database') ||
        msg.contains('mongo') ||
        msg.contains('DB')) {
      return _ScanError(
        title: 'Database Error',
        detail: msg,
        hint: 'The backend database (MongoDB) may be down or misconfigured.',
        color: AppColors.severityCritical,
        icon: Icons.storage_outlined,
      );
    }
    return _ScanError(
      title: 'Unexpected Error',
      detail: msg,
      hint: 'An unknown error occurred. Check the backend logs for details.',
      color: AppColors.error,
      icon: Icons.bug_report_outlined,
    );
  }
}

// ── Stream provider ───────────────────────────────────────────────────────────

final scanProgressProvider = StreamProvider.family<ScanProgress, String>((
  ref,
  scanId,
) async* {
  final api = ApiDatasource(dio: HttpClientService().dio);

  // First fetch
  yield await api.getScanProgressDetailed(scanId);

  // Poll every 3 s
  await for (final _ in Stream.periodic(const Duration(seconds: 3))) {
    final progress = await api.getScanProgressDetailed(scanId);
    yield progress;
    if (progress.isCompleted || progress.isFailed) break;
  }
});

// ── Screen ────────────────────────────────────────────────────────────────────

class ScanProgressScreen extends ConsumerStatefulWidget {
  final String scanId;
  const ScanProgressScreen({super.key, required this.scanId});

  @override
  ConsumerState<ScanProgressScreen> createState() => _ScanProgressScreenState();
}

class _ScanProgressScreenState extends ConsumerState<ScanProgressScreen> {
  bool _navigationTriggered = false;

  @override
  Widget build(BuildContext context) {
    final progressAsync = ref.watch(scanProgressProvider(widget.scanId));

    return Scaffold(
      backgroundColor: AppColors.bgCanvas,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.radar, color: AppColors.accentGreen, size: 18),
            const SizedBox(width: 8),
            Text(
              'Scan Progress',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        leading: _navigationTriggered
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: progressAsync.when(
        data: (progress) {
          // Auto-navigate on completion
          if (progress.isCompleted && !_navigationTriggered) {
            _navigationTriggered = true;
            Future.microtask(() {
              if (mounted) {
                AppNavigator.pushReplacementNamed(
                  AppRoutes.scanReport,
                  arguments: progress.scanId,
                );
              }
            });
          }
          return _buildProgressBody(progress);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accentGreen),
        ),
        error: (error, stack) => _buildErrorBody(error, stack),
      ),
    );
  }

  // ── Progress body ───────────────────────────────────────────────────────────

  Widget _buildProgressBody(ScanProgress progress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OverallProgressCard(progress: progress),
            const SizedBox(height: 20),

            // Tool rows
            Text(
              'Security Tools',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Column(
                children: progress.toolProgress.asMap().entries.map((e) {
                  return _ToolRow(
                    tool: e.value,
                    isLast: e.key == progress.toolProgress.length - 1,
                  );
                }).toList(),
              ),
            ),

            // Scan-level error from API response
            if (progress.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ScanLevelError(message: progress.errorMessage!),
            ],

            // Terminal
            const SizedBox(height: 20),
            _TerminalPanel(status: progress.status, scanId: widget.scanId),

            // Cancel
            if (progress.isScanning) ...[
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: _handleCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Cancel Scan',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Full-page error body ─────────────────────────────────────────────────────

  Widget _buildErrorBody(Object error, StackTrace? stack) {
    final err = _ScanError.from(error);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main error card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: err.color.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top strip
                  Container(
                    height: 3,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: err.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(err.icon, color: err.color, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        err.title,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: err.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Detail
                  Text(
                    'Error Detail',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF010409),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.borderDefault),
                    ),
                    child: SelectableText(
                      err.detail,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.error,
                      ),
                    ),
                  ),

                  // Hint
                  if (err.hint != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.accentBlue.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.accentBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 15,
                            color: AppColors.accentBlue,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              err.hint!,
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

                  // Stack trace (collapsible)
                  if (stack != null) ...[
                    const SizedBox(height: 14),
                    _CollapsibleStack(stack: stack.toString()),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Scan ID badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.bgPrimary,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.borderDefault),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.fingerprint,
                    size: 14,
                    color: AppColors.textSubtle,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scan ID: ',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      widget.scanId,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: AppColors.textCode,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.copy_outlined,
                      size: 14,
                      color: AppColors.textSubtle,
                    ),
                    tooltip: 'Copy scan ID',
                    onPressed: () =>
                        Clipboard.setData(ClipboardData(text: widget.scanId)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_outlined, size: 16),
                    label: const Text('Retry'),
                    onPressed: () =>
                        ref.invalidate(scanProgressProvider(widget.scanId)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accentGreen,
                      side: const BorderSide(color: AppColors.accentGreen),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back_outlined, size: 16),
                    label: const Text('Go Back'),
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.borderDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Scan',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to cancel this scan?',
          style: GoogleFonts.inter(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      try {
        await ApiDatasource(
          dio: HttpClientService().dio,
        ).cancelScan(widget.scanId);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cancel failed: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _OverallProgressCard extends StatelessWidget {
  final ScanProgress progress;
  const _OverallProgressCard({required this.progress});

  Color get _color {
    switch (progress.status) {
      case 'scanning':
        return AppColors.accentBlue;
      case 'completed':
        return AppColors.accentGreen;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${progress.progressPercentage}%',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: _color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.progressPercentage / 100,
              minHeight: 8,
              backgroundColor: AppColors.bgSecondary,
              valueColor: AlwaysStoppedAnimation<Color>(_color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _color.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              Text(
                progress.status == 'scanning'
                    ? 'Scanning in progress...'
                    : progress.status == 'completed'
                    ? '✓  Scan completed successfully'
                    : progress.status == 'failed'
                    ? '✗  Scan failed'
                    : 'Initializing...',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: _color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolRow extends StatelessWidget {
  final dynamic tool;
  final bool isLast;
  const _ToolRow({required this.tool, required this.isLast});

  Color get _color {
    switch (tool.status as String) {
      case 'completed':
        return AppColors.accentGreen;
      case 'running':
        return AppColors.accentBlue;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.textSubtle;
    }
  }

  String get _name {
    const names = {
      'semgrep': 'Semgrep',
      'trufflehog': 'TruffleHog',
      'npm_audit': 'npm Audit',
      'mobsf': 'MobSF',
      'bandit': 'Bandit',
    };
    return names[tool.toolName as String] ?? (tool.toolName as String);
  }

  String get _desc {
    const descs = {
      'semgrep': 'Static Analysis (SAST)',
      'trufflehog': 'Secret Detection',
      'npm_audit': 'Dependency Scanning',
      'mobsf': 'Mobile Security',
      'bandit': 'Python Security',
    };
    return descs[tool.toolName as String] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.borderDefault),
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: _color,
                  shape: BoxShape.circle,
                  boxShadow: tool.status == 'running'
                      ? [
                          BoxShadow(
                            color: _color.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      _desc,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 10,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
              if (tool.vulnerabilitiesFound != null)
                Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSecondary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tool.vulnerabilitiesFound} found',
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              _StatusBadge(status: tool.status as String, color: _color),
            ],
          ),
          // Tool-level error message
          if (tool.status == 'failed' && tool.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: AppColors.error,
                    size: 13,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SelectableText(
                      tool.errorMessage as String,
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;
  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _TerminalPanel extends StatelessWidget {
  final String status;
  final String scanId;
  const _TerminalPanel({required this.status, required this.scanId});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF010409),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _dot(const Color(0xFFFF5F57)),
              const SizedBox(width: 6),
              _dot(const Color(0xFFFFBD2E)),
              const SizedBox(width: 6),
              _dot(const Color(0xFF28C840)),
              const SizedBox(width: 12),
              Text(
                'vulnscan-scanner — scan: $scanId',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _line(r'$ docker run --rm vulnscan/scanner', AppColors.accentGreen),
          const SizedBox(height: 3),
          _line(
            '> Cloning repository into isolated container...',
            AppColors.textSecondary,
          ),
          const SizedBox(height: 3),
          _line(
            '> Running security tools in parallel...',
            AppColors.textSecondary,
          ),
          const SizedBox(height: 3),
          if (status == 'scanning')
            _line('> ▌ Scanning... (polling every 3s)', AppColors.accentGreen)
          else if (status == 'completed')
            _line(
              '> ✓ Scan complete. Container destroyed.',
              AppColors.accentGreen,
            )
          else if (status == 'failed')
            _line('> ✗ Scan failed. Check errors above.', AppColors.error)
          else
            _line('> Initializing...', AppColors.textSubtle),
        ],
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
  );

  Widget _line(String text, Color color) =>
      Text(text, style: GoogleFonts.jetBrainsMono(fontSize: 12, color: color));
}

class _ScanLevelError extends StatelessWidget {
  final String message;
  const _ScanLevelError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scan Error',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  message,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 12,
                    color: AppColors.error.withValues(alpha: 0.85),
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

class _CollapsibleStack extends StatefulWidget {
  final String stack;
  const _CollapsibleStack({required this.stack});

  @override
  State<_CollapsibleStack> createState() => _CollapsibleStackState();
}

class _CollapsibleStackState extends State<_CollapsibleStack> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 15,
                color: AppColors.textSubtle,
              ),
              const SizedBox(width: 6),
              Text(
                _expanded ? 'Hide stack trace' : 'Show stack trace',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF010409),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.borderDefault),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                widget.stack,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: AppColors.textSubtle,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
