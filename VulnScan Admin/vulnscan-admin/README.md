# VulnScan Admin - Flutter Web

Admin dashboard for VulnScan vulnerability management system.

## Features

- User management (view, delete users)
- Scan history and status tracking
- Analytics and vulnerability reports
- User feedback management
- Admin-only access with Firebase authentication

## Getting Started

### Prerequisites

- Flutter 3.0+
- Web support enabled: `flutter config --enable-web`
- Firebase project configured

### Installation

```bash
flutter pub get
```

### Running

```bash
flutter run -d chrome
```

### Building for Production

```bash
flutter build web --release
```

## Architecture

- **Firebase Auth**: Admin-only authentication
- **Riverpod**: State management
- **Dio**: HTTP client for backend API communication
- **Material 3**: UI framework

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart     # Firebase config
├── providers/
│   ├── auth_provider.dart   # Authentication state
│   └── api_provider.dart    # Backend API communication
└── screens/
    ├── login_screen.dart
    ├── dashboard_screen.dart
    └── widgets/
        ├── analytics_card.dart
        ├── users_table.dart
        ├── scans_table.dart
        └── feedback_list.dart
```

## API Integration

Connects to VulnScan backend at `http://localhost:8000` with endpoints:
- `GET /admin/users` - List users
- `GET /admin/scans` - List scans
- `GET /admin/analytics` - Dashboard metrics
- `DELETE /admin/users/{uid}` - Delete user
- `GET /feedback` - List feedback

All requests include Firebase auth token in Authorization header.
