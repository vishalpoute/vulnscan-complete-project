class ToolProgress {
  final String toolName; // 'semgrep', 'trufflehog', 'npm_audit', 'mobsf'
  final String status; // 'pending', 'running', 'completed', 'failed'
  final String? errorMessage;
  final int? vulnerabilitiesFound;

  ToolProgress({
    required this.toolName,
    required this.status,
    this.errorMessage,
    this.vulnerabilitiesFound,
  });

  factory ToolProgress.fromJson(Map<String, dynamic> json) {
    return ToolProgress(
      toolName: json['tool_name'] as String,
      status: json['status'] as String,
      errorMessage: json['error_message'] as String?,
      vulnerabilitiesFound: json['vulnerabilities_found'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'tool_name': toolName,
        'status': status,
        'error_message': errorMessage,
        'vulnerabilities_found': vulnerabilitiesFound,
      };
}

class ScanProgress {
  final String scanId;
  final String status; // 'created', 'scanning', 'completed', 'failed'
  final int progressPercentage; // 0-100
  final List<ToolProgress> toolProgress;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String? errorMessage;

  ScanProgress({
    required this.scanId,
    required this.status,
    required this.progressPercentage,
    required this.toolProgress,
    required this.startedAt,
    this.completedAt,
    this.errorMessage,
  });

  bool get isScanning => status == 'scanning';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  factory ScanProgress.fromJson(Map<String, dynamic> json) {
    return ScanProgress(
      scanId: json['id'] as String,
      status: json['status'] as String,
      progressPercentage: json['progress'] as int? ?? 0,
      toolProgress: (json['tool_progress'] as List?)
              ?.map((e) => ToolProgress.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at'] as String) : DateTime.now(),
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      errorMessage: json['error'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'scan_id': scanId,
        'status': status,
        'progress_percentage': progressPercentage,
        'tool_progress': toolProgress.map((e) => e.toJson()).toList(),
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'error_message': errorMessage,
      };
}
