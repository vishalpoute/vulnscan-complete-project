# VulnScan Backend API

FastAPI backend for the VulnScan vulnerability scanning application.

## Project Structure

```
vulnscan-backend/
├── main.py                      # FastAPI application entry point
├── requirements.txt             # Python dependencies
├── .env.example                 # Environment variables template
│
├── core/                        # Core configuration and setup
│   ├── config.py               # Environment settings (pydantic)
│   ├── security.py             # Firebase token verification
│   └── database.py             # MongoDB Motor connection
│
├── models/                      # Pydantic data models
│   ├── scan.py                 # Scan request/response models
│   ├── user.py                 # User profile and subscription models
│   └── vulnerability.py        # Vulnerability and finding models
│
├── routers/                     # API endpoint routes
│   ├── auth.py                 # POST /auth/verify (no auth required)
│   ├── scans.py                # Scan CRUD endpoints
│   ├── users.py                # User profile and account endpoints
│   └── payments.py             # Payment/subscription endpoints
│
├── services/                    # Business logic and tool integrations
│   ├── scan_orchestrator.py    # Parallel scan execution
│   ├── semgrep_service.py      # Semgrep SAST scanner
│   ├── trufflehog_service.py   # Secret scanner
│   ├── npm_audit_service.py    # Dependency audit
│   ├── mobsf_service.py        # Mobile app scanner
│   └── ai_service.py           # Claude/GPT integration
│
└── utils/                       # Utility functions
    ├── github_cloner.py        # GitHub repo cloning
    └── report_builder.py       # Result aggregation
```

## API Endpoints

### Authentication (No Token Required)
- `POST /auth/verify` - Verify Firebase token

### Scans (Requires Firebase Token)
- `POST /scans` - Create new scan
- `GET /scans` - List user's scans
- `GET /scans/{scan_id}/status` - Check scan progress
- `GET /scans/{scan_id}/report` - Get full scan report
- `DELETE /scans/{scan_id}` - Delete scan

### Users (Requires Firebase Token)
- `GET /user/subscription` - Get subscription info
- `DELETE /user/account` - Delete account

### Payments (Requires Firebase Token)
- `POST /payments/create-order` - Create payment order

## Setup

1. Create `.env` from `.env.example`:
```bash
cp .env.example .env
```

2. Fill in required environment variables:
   - Firebase credentials
   - MongoDB connection string
   - API keys (optional)

3. Install dependencies:
```bash
pip install -r requirements.txt
```

4. Run the server:
```bash
python main.py
```

Or with uvicorn directly:
```bash
uvicorn main:app --reload
```

## Authentication

All endpoints except `/auth/verify` require a Firebase ID token in the Authorization header:

```
Authorization: Bearer <firebase_id_token>
```

The token is verified using Firebase Admin SDK. The user's `uid` is extracted and used to filter data from MongoDB.

## Database

MongoDB with Motor async driver:
- Connects on startup
- Verifies connection with ping
- Closes gracefully on shutdown

## Implementation Status

- [x] Project structure and configuration
- [x] Pydantic models
- [x] Route stubs with 501 responses
- [ ] Service implementations (Semgrep, TruffleHog, etc.)
- [ ] Background task scanning
- [ ] Result aggregation and deduplication
- [ ] AI analysis integration
