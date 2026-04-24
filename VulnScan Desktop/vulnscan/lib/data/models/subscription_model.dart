class SubscriptionInfo {
  final String tier; // 'free', 'pro', 'enterprise'
  final int scansUsed;
  final int scansLimit;
  final List<String>?
  allowedScanTypes; // ['web'], ['web', 'android', 'ios'], etc.
  final DateTime? expiresAt;
  final DateTime cachedAt;
  final bool isOffline; // Flag for offline/cached data

  SubscriptionInfo({
    required this.tier,
    required this.scansUsed,
    required this.scansLimit,
    this.allowedScanTypes,
    this.expiresAt,
    required this.cachedAt,
    this.isOffline = false,
  });

  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);
  bool get canCreateScan => scansUsed < scansLimit;
  bool get canScanType => (allowedScanTypes?.isNotEmpty ?? false);

  /// Create a default free subscription for offline use
  factory SubscriptionInfo.defaultFree() {
    return SubscriptionInfo(
      tier: 'free',
      scansUsed: 0,
      scansLimit: 5,
      allowedScanTypes: ['web'],
      expiresAt: null,
      cachedAt: DateTime.now(),
      isOffline: true,
    );
  }

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      tier: json['tier'] as String,
      scansUsed: json['scans_used'] as int? ?? 0,
      scansLimit: json['scans_limit'] as int? ?? 0,
      allowedScanTypes: List<String>.from(
        json['allowed_scan_types'] as List? ?? [],
      ),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      cachedAt: DateTime.now(),
      isOffline: false,
    );
  }

  Map<String, dynamic> toJson() => {
    'tier': tier,
    'scans_used': scansUsed,
    'scans_limit': scansLimit,
    'allowed_scan_types': allowedScanTypes,
    'expires_at': expiresAt?.toIso8601String(),
    'cached_at': cachedAt.toIso8601String(),
  };
}
