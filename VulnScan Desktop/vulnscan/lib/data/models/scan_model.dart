class Scan {
  final String id;
  final String repositoryUrl;
  final String scanType; // 'web', 'android', 'ios'
  final String status; // 'created', 'scanning', 'completed', 'failed'
  final DateTime createdAt;
  final DateTime? completedAt;
  final int? criticalVulnCount;
  final int? highVulnCount;
  final int? mediumVulnCount;
  final int? lowVulnCount;
  final String? errorMessage;

  Scan({
    required this.id,
    required this.repositoryUrl,
    required this.scanType,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.criticalVulnCount,
    this.highVulnCount,
    this.mediumVulnCount,
    this.lowVulnCount,
    this.errorMessage,
  });

  int get totalVulns => (criticalVulnCount ?? 0) + (highVulnCount ?? 0) + (mediumVulnCount ?? 0) + (lowVulnCount ?? 0);

  factory Scan.fromJson(Map<String, dynamic> json) {
    return Scan(
      id: json['id'] as String,
      repositoryUrl: json['url_or_repo'] as String,
      scanType: json['scan_type'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      criticalVulnCount: json['critical_vuln_count'] as int?,
      highVulnCount: json['high_vuln_count'] as int?,
      mediumVulnCount: json['medium_vuln_count'] as int?,
      lowVulnCount: json['low_vuln_count'] as int?,
      errorMessage: json['error_message'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'repository_url': repositoryUrl,
        'scan_type': scanType,
        'status': status,
        'created_at': createdAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'critical_vuln_count': criticalVulnCount,
        'high_vuln_count': highVulnCount,
        'medium_vuln_count': mediumVulnCount,
        'low_vuln_count': lowVulnCount,
        'error_message': errorMessage,
      };
}
