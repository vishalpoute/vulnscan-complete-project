# VulnScan

A vulnerability-assessment project with a Flutter client, an admin interface and a FastAPI backend. The backend orchestrates security tools and supports AI-assisted explanations of findings.

## Repository structure

| Directory | Purpose |
| --- | --- |
| `VulnScan Desktop/vulnscan` | Current Flutter client: Riverpod, Firebase Auth, scan progress, subscriptions and reports |
| `VulnScan Admin/vulnscan-admin` | Flutter administration interface |
| `VulnScan Backend/vulnscan-backend` | FastAPI scanning backend |
| `VulnScan Research/paper` | Research materials |

## Run locally

Start with the component READMEs. The Flutter client needs your own Firebase configuration and a running backend:

```sh
cd "VulnScan Desktop/vulnscan"
flutter pub get
flutter run --dart-define-from-file=firebase.local.json
```

See the client's [configuration guide](VulnScan%20Desktop/vulnscan/SECURITY.md) and the backend [README](VulnScan%20Backend/vulnscan-backend/README.md). Keep privileged provider credentials on the server. Scan only code and systems you are authorized to assess.

## Project status

Academic project under development. The latest standalone Flutter client has been consolidated here. Portfolio screenshots use explicitly labeled sample findings, rather than a live assessment.

## Author

[Vishal Poute](https://github.com/vishalpoute) · [Portfolio](https://heyvishal.antideploy.app)
