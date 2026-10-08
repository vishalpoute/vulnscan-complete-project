# VulnScan Backend

FastAPI service for authentication, scan orchestration, finding reports, users, administration and payment-related routes.

## Architecture

| Directory | Purpose |
| --- | --- |
| `core/` | Configuration, Firebase verification and database connections |
| `routers/` | HTTP endpoints registered under `/api` |
| `services/` | Scanner integrations and AI-assisted reporting |
| `models/` | Request, response and finding models |
| `utils/` | Repository cloning and report utilities |

## Run locally

Create a Python virtual environment and activate it for your operating system. Install the dependencies:

```sh
python -m pip install -r requirements.txt
```

Copy `.env.example` to a local `.env` and configure Firebase service credentials, database connections and any scanner or AI provider you intend to use. Keep privileged credentials outside Git.

```sh
python -m uvicorn main:app --reload
```

Open `http://localhost:8000/docs` for the generated API reference. The root `/` endpoint exposes service health; application routes use the `/api` prefix.

## Authentication and integrations

Protected routes verify Firebase ID tokens. Scanner tools and external services need their own installation or credentials. Inspect the relevant service implementation and environment template before enabling an integration.

## Status

Academic development project. Payment-related routes and provider integrations are implementation areas, not evidence of a validated production service. Review CORS settings, authorization, scanner isolation and deployment configuration before public deployment.

See the [complete project](../../README.md) for client and admin setup.
