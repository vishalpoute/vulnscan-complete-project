# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**VulnScan** is a Flutter application that supports multiple platforms (Android, iOS, Windows, Linux, macOS, Web). It follows the standard Flutter project structure with Dart as the primary language.

## Common Development Commands

### Dependency Management
```bash
flutter pub get              # Install/update dependencies
flutter pub upgrade          # Upgrade all dependencies to latest compatible versions
flutter pub outdated         # Check for outdated packages
```

### Code Quality
```bash
flutter analyze              # Run the Dart analyzer to check for errors and lints
flutter analyze --fatal-infos # Analyze and treat info-level issues as fatal
```

### Testing
```bash
flutter test                 # Run all tests
flutter test test/widget_test.dart  # Run a specific test file
flutter test --coverage      # Run tests with coverage report
```

### Running the App
```bash
flutter devices              # List available devices
flutter run                  # Run on default device
flutter run -d <device-id>   # Run on specific device
flutter run --debug          # Debug mode (default)
flutter run --release        # Release mode
```

### Building
```bash
flutter build apk            # Build Android APK
flutter build ios            # Build iOS app
flutter build windows        # Build Windows desktop app
flutter build linux          # Build Linux desktop app
flutter build macos          # Build macOS desktop app
flutter build web            # Build web version
```

## Project Structure

- **lib/** - Main application code
  - `main.dart` - Application entry point and root widgets
- **test/** - Widget and integration tests
- **android/**, **ios/**, **windows/**, **linux/**, **macos/**, **web/** - Platform-specific code and configuration
- **pubspec.yaml** - Project dependencies and configuration
- **analysis_options.yaml** - Dart analyzer and linting rules

## Architecture Guidelines

### Code Organization
- Keep widget code modular and separate concerns into different files
- Use State for stateful widgets that manage mutable state
- Prefer composition over deep widget hierarchies

### Dependencies
- Project uses `flutter_lints` for code quality enforcement (see `analysis_options.yaml`)
- Material Design is the default UI framework (`uses-material-design: true`)
- Currently minimal dependencies - new packages should be added thoughtfully

### Linting and Analysis
- Linting rules are configured in `analysis_options.yaml` and extend `package:flutter_lints/flutter.yaml`
- Always run `flutter analyze` before committing changes
- Suppress lints only when necessary using `// ignore: rule_name` comments

## Platform-Specific Notes

The project is configured for multi-platform deployment:
- **Mobile** (Android/iOS): Core Flutter widgets work across both
- **Desktop** (Windows/Linux/macOS): Use `flutter_desktop_tools` when needed
- **Web**: May require additional dependencies like `web` package

## Testing Strategy

- Widget tests are the primary testing approach (see `test/widget_test.dart`)
- Use `WidgetTester` for UI interactions (tap, scroll, etc.)
- Test files should mirror the structure of app code
- Run tests frequently during development to catch regressions early
