/// Application-wide constants
class AppConstants {
  /// API Configuration
  static const String baseApiUrl = 'http://localhost:8000'; // Change in .env
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration networkTimeout = Duration(seconds: 60);

  /// Polling Configuration
  static const Duration scanProgressPollInterval = Duration(seconds: 2);
  static const int maxRetries = 3;

  /// Subscription Tiers
  static const String tierFree = 'free';
  static const String tierPro = 'pro';
  static const String tierEnterprise = 'enterprise';

  /// Scan Types
  static const String scanTypeWeb = 'web';
  static const String scanTypeAndroid = 'android';
  static const String scanTypeIos = 'ios';

  /// Severity Levels
  static const String severityCritical = 'critical';
  static const String severityHigh = 'high';
  static const String severityMedium = 'medium';
  static const String severityLow = 'low';
  static const String severityInfo = 'info';

  /// Storage Keys
  static const String storageKeyAuthToken = 'auth_token';
  static const String storageKeyRefreshToken = 'refresh_token';
  static const String storageKeyUserId = 'user_id';
  static const String storageKeySubscriptionTier = 'subscription_tier';
  static const String storageKeyThemeMode = 'theme_mode';
  static const String storageKeyLastScanHistory = 'last_scan_history';

  /// Cache Duration
  static const Duration subscriptionCacheDuration = Duration(hours: 1);
  static const Duration dashboardCacheDuration = Duration(minutes: 5);

  /// UI Constants
  static const double desktopMinWidth = 1000;
  static const double desktopMinHeight = 600;

  /// Message Durations
  static const Duration toastDuration = Duration(seconds: 3);
  static const Duration errorDialogDuration = Duration(seconds: 5);
}

/// Error Messages
class ErrorMessages {
  static const String networkError =
      'Network connection failed. Please check your internet.';
  static const String serverError = 'Server error. Please try again later.';
  static const String authError = 'Authentication failed. Please login again.';
  static const String invalidUrl = 'Invalid GitHub repository URL.';
  static const String subscriptionError =
      'Your current plan does not support this scan type.';
  static const String quotaExceeded =
      'You have reached your scan quota for this month.';
  static const String unauthorized =
      'You are not authorized to perform this action.';
  static const String unknown = 'Something went wrong. Please try again.';
}

/// Success Messages
class SuccessMessages {
  static const String scanCreated = 'Scan started successfully';
  static const String profileUpdated = 'Profile updated';
  static const String logoutSuccess = 'Logged out successfully';
  static const String exportSuccess = 'Report exported successfully';
}
