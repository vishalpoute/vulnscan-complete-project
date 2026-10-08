# VulnScan Flutter Client

The current Flutter interface for the [VulnScan project](../../README.md), using Riverpod for state management, Firebase authentication and HTTP communication with the scanning backend.

## Main areas

- Sign-in and account flows
- Scan submission, progress and finding reports
- Dashboard and subscription interface

## Run locally

Install Flutter, configure Firebase for your own project and start the backend before using scan features.

```sh
flutter pub get
```

Copy `firebase.example.json` to the ignored `firebase.local.json`, fill in your platform configuration, then run:

```sh
flutter run --dart-define-from-file=firebase.local.json
```

See [SECURITY.md](SECURITY.md) for platform configuration. Review the API provider in `lib/` to match your backend URL.

## Web build

```sh
flutter build web --dart-define-from-file=firebase.local.json
```

## Status

Academic project under development. Backend connectivity, Firebase configuration and third-party scanning services must be configured separately. Portfolio images show labeled sample findings and do not establish a live scan result.
