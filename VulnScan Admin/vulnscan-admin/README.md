# VulnScan Admin Interface

Flutter web interface for VulnScan administration, using Firebase Auth, Riverpod and Dio.

## Interface areas

User management, scan history, analytics and feedback screens. These require a running backend and appropriately authorized accounts.

## Run locally

Configure your Firebase project using `firebase.example.json` and the [security guide](SECURITY.md), then run:

```sh
flutter pub get
flutter run -d chrome --dart-define-from-file=firebase.local.json
```

## Backend configuration

Review `lib/providers/api_provider.dart` before running. Its current base URL is `http://localhost:8000`, while the backend registers routes under `/api`. Align the URL and route paths with your running backend; the default values require correction for direct integration.

## Build

```sh
flutter build web --release --dart-define-from-file=firebase.local.json
```

## Status

Development interface. Admin access must be enforced by the backend; hiding interface controls is insufficient authorization.

See the [complete project](../../README.md) for the other components.
