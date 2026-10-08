# Configuration and security

Firebase client API keys identify a project; they do not grant database access by themselves. This repository omits concrete API-key values to separate local environments from source control.

Supply platform keys with `--dart-define-from-file=firebase.local.json`. Copy `firebase.example.json` to that ignored file and obtain the configuration for your own Firebase project. Other Firebase project identifiers in `firebase_options.dart` must also match your project; use `flutterfire configure` when setting up a new environment.

For native Android builds, download your own `google-services.json` into `android/app/`. Configure Apple platforms with your own Firebase files when required. These local configuration files are ignored.

Firebase client keys remain visible in compiled applications. Protect data using Firebase Security Rules and App Check, and restrict keys to required Firebase APIs. Never ship service-account private keys or backend provider tokens in client apps.

Keep backend credentials in environment variables or a deployment secret store. If a privileged credential has been published, revoke or rotate it with the provider first. Deleting a file does not invalidate a credential or erase previous Git commits.

Official guidance: https://firebase.google.com/docs/projects/api-keys
