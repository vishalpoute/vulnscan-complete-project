class GitHubUrlValidator {
  /// Validates GitHub URL format and extracts owner/repo
  /// Returns (owner, repo) tuple if valid, null otherwise
  static ({String owner, String repo})? parseGitHubUrl(String url) {
    try {
      // Normalize: remove trailing slashes and whitespace
      String normalized = url.trim().replaceAll(RegExp(r'/+$'), '');

      // Check if it's a GitHub URL
      if (!normalized.startsWith('https://github.com/')) {
        return null;
      }

      // Extract path after domain
      const githubPrefix = 'https://github.com/';
      final path = normalized.substring(githubPrefix.length);

      // Split into parts
      final parts = path.split('/');

      // Should have exactly 2 parts: owner/repo
      if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
        return null;
      }

      final owner = parts[0];
      final repo = parts[1];

      // Validate characters (GitHub allows alphanumeric, hyphens, underscores)
      final validPattern = RegExp(r'^[a-zA-Z0-9._-]+$');
      if (!validPattern.hasMatch(owner) || !validPattern.hasMatch(repo)) {
        return null;
      }

      return (owner: owner, repo: repo);
    } catch (_) {
      return null;
    }
  }

  /// Simple validation - returns true if URL is valid GitHub format
  static bool isValid(String url) {
    return parseGitHubUrl(url) != null;
  }

  /// Get user-friendly error message
  static String getErrorMessage(String url) {
    if (url.isEmpty) {
      return 'GitHub URL is required';
    }

    if (!url.contains('github.com')) {
      return 'Must be a GitHub URL';
    }

    if (!url.startsWith('https://')) {
      return 'Must use HTTPS protocol';
    }

    if (parseGitHubUrl(url) == null) {
      return 'Invalid format. Use: https://github.com/owner/repo';
    }

    return 'Invalid GitHub URL';
  }
}
