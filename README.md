# VulnScan - Complete Vulnerability Scanning Platform

A comprehensive full-stack application for automated vulnerability scanning with mobile, web, and admin dashboard interfaces. Built with Flutter, FastAPI, MongoDB, and Firebase.

## 📁 Project Structure

```
VulnScan/
├── VulnScan Desktop/          # Flutter mobile/web app (main user application)
│   └── vulnscan/
│       ├── lib/               # Flutter source code
│       ├── android/           # Android platform files
│       ├── ios/               # iOS platform files
│       ├── windows/           # Windows desktop app
│       ├── linux/             # Linux desktop app
│       ├── macos/             # macOS desktop app
│       ├── web/               # Web build files
│       └── pubspec.yaml       # Flutter dependencies
│
├── VulnScan Backend/          # FastAPI backend service
│   └── vulnscan-backend/
│       ├── main.py            # FastAPI entry point
│       ├── core/              # Configuration & database
│       ├── models/            # Data models
│       ├── routers/           # API endpoints (auth, scans, admin, payments)
│       ├── services/          # Scanning tools (Semgrep, Trufflehog, MobSF, npm-audit)
│       ├── requirements.txt   # Python dependencies
│       └── firebase_adminsdk.json  # Firebase credentials
│
├── VulnScan Admin/            # Flutter admin dashboard
│   └── vulnscan-admin/
│       ├── lib/               # Admin dashboard source code
│       └── pubspec.yaml       # Flutter dependencies
│
└── VulnScan Research/         # Research paper & documentation
    └── paper/                 # IEEE paper in LaTeX format
```

## 🚀 Quick Start

### Prerequisites
- **Flutter**: 3.10.8+ ([Download](https://flutter.dev/docs/get-started/install))
- **Python**: 3.13+ ([Download](https://www.python.org/downloads/))
- **Node.js**: 16+ (for npm-audit service)
- **Git**: Latest version
- **MongoDB**: Local or Atlas cluster
- **Firebase**: Project with Firestore & Authentication

### 1. Setup Backend (FastAPI)

```bash
# Navigate to backend
cd "VulnScan Backend/vulnscan-backend"

# Install dependencies
pip install -r requirements.txt

# Configure environment variables
# Create .env file with:
# MONGODB_URI=your_mongodb_connection_string
# FIREBASE_PROJECT_ID=your_firebase_project_id
# FIREBASE_CREDENTIALS_PATH=./firebase_adminsdk.json

# Start the server
# Windows:
START_BACKEND.bat

# Linux/macOS:
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

**Backend runs on**: `http://localhost:8000`
- API Documentation: `http://localhost:8000/docs`
- Health Check: `http://localhost:8000/health`

### 2. Setup Desktop App (Flutter)

```bash
# Navigate to desktop app
cd "VulnScan Desktop/vulnscan"

# Get dependencies
flutter pub get

# Run on Chrome web
flutter run -d chrome

# Build for production
flutter build web
```

### 3. Setup Admin Dashboard (Flutter)

```bash
# Navigate to admin app
cd "VulnScan Admin/vulnscan-admin"

# Get dependencies
flutter pub get

# Run on Chrome web
flutter run -d chrome

# Build for production
flutter build web
```

## 🏗️ Architecture Overview

### Backend Services

| Service | Purpose | Tools Used |
|---------|---------|-----------|
| **Scanning Orchestrator** | Coordinates multiple security scans | Semgrep, Trufflehog, MobSF, npm-audit |
| **Semgrep Service** | SAST - Static code analysis | Semgrep CLI |
| **Trufflehog Service** | Secret detection | Trufflehog CLI |
| **MobSF Service** | Mobile app security analysis | MobSF API |
| **npm-audit Service** | JavaScript/Node.js vulnerability scanning | npm audit |
| **AI Service** | Smart vulnerability analysis & reporting | Claude API |
| **Database Service** | Persistent data storage | MongoDB + Motor |
| **Firestore Service** | Cross-platform data sync | Firebase Firestore |

### API Endpoints

#### Authentication
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `POST /api/auth/logout` - User logout
- `GET /api/auth/me` - Get current user

#### Scans
- `GET /api/scans` - List user scans
- `POST /api/scans/create` - Start new scan
- `GET /api/scans/{scan_id}` - Get scan details
- `GET /api/scans/{scan_id}/progress` - Get scan progress

#### Payments
- `POST /api/payments/verify-razorpay` - Verify Razorpay payment
- `GET /api/payments/subscription-status` - Check subscription

#### Admin
- `POST /api/admin/upgrade-user` - Upgrade user tier
- `POST /api/admin/reset-scans` - Reset user scan count
- `GET /api/admin/users` - List all users
- `GET /api/admin/analytics` - System analytics

#### Feedback
- `POST /api/feedback` - Submit user feedback
- `GET /api/feedback` - Get all feedback (admin only)

## 🔐 Features

### User Features
✅ User authentication (Email/Password)
✅ Multiple subscription tiers (Free, Pro, Enterprise)
✅ Razorpay payment integration
✅ Real-time vulnerability scanning
✅ Detailed scan reports with AI analysis
✅ GitHub repository scanning
✅ Multiple security scan types:
  - Static analysis (SAST)
  - Secret detection
  - Dependency vulnerability scanning
  - Mobile app analysis

### Admin Features
✅ User management dashboard
✅ Manual user tier upgrades
✅ Scan count management
✅ Analytics and insights
✅ User feedback management
✅ System health monitoring

## 📦 Dependencies

### Backend (Python)
```
FastAPI==0.104.0
uvicorn==0.24.0
motor==3.3.0
firebase-admin==6.1.0
semgrep==1.45.0
trufflehog==3.61.0
npm-audit==10.0.0
pydantic==2.4.0
```

### Desktop/Admin (Flutter)
```
flutter_riverpod: ^2.4.0
dio: ^5.3.1
firebase_auth: ^6.4.0
firebase_core: ^2.27.0
cloud_firestore: ^4.14.0
url_launcher: ^6.1.14
go_router: ^12.1.0
uuid: ^4.0.0
```

## 🛠️ Configuration

### Environment Variables (.env)

```env
# MongoDB
MONGODB_URI=mongodb+srv://user:password@cluster.mongodb.net/vulnscan

# Firebase
FIREBASE_PROJECT_ID=your-firebase-project
FIREBASE_CREDENTIALS_PATH=./firebase_adminsdk.json
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com

# API
API_PORT=8000
API_HOST=0.0.0.0
DEBUG=false

# External Services
SEMGREP_API_KEY=your_semgrep_api_key
TRUFFLEHOG_API_KEY=your_trufflehog_key
MOBSF_API_KEY=your_mobsf_key

# Payments
RAZORPAY_KEY_ID=your_razorpay_key
RAZORPAY_KEY_SECRET=your_razorpay_secret

# Admin Email (for admin panel access)
ADMIN_EMAIL=vishupoute154@gmail.com
```

### Firebase Setup

1. Create a Firebase project at [firebase.google.com](https://firebase.google.com)
2. Enable Authentication (Email/Password)
3. Create Firestore database
4. Download `firebase-adminsdk.json` and place in backend folder
5. Update Firebase config in Flutter apps (lib/firebase_options.dart)

## 🚢 Deployment

### Backend (Docker)
```bash
cd "VulnScan Backend/vulnscan-backend"
docker build -t vulnscan-backend .
docker run -p 8000:8000 --env-file .env vulnscan-backend
```

### Desktop App (Web)
```bash
cd "VulnScan Desktop/vulnscan"
flutter build web --release
# Deploy to hosting service (Firebase Hosting, Vercel, etc.)
```

### Admin Dashboard
```bash
cd "VulnScan Admin/vulnscan-admin"
flutter build web --release
# Deploy to hosting service
```

## 📝 Testing

### Backend Tests
```bash
cd "VulnScan Backend/vulnscan-backend"
pytest tests/
```

### Flutter Tests
```bash
# Desktop app
cd "VulnScan Desktop/vulnscan"
flutter test

# Admin app
cd "VulnScan Admin/vulnscan-admin"
flutter test
```

## 🐛 Troubleshooting

### Backend Won't Start
- **Error**: Python not found
  - **Solution**: Use full Python path or add to system PATH
  - Windows: `C:\Users\<username>\AppData\Local\Programs\Python\Python313\python.exe`

- **Error**: Module not found
  - **Solution**: Install requirements: `pip install -r requirements.txt`

- **Error**: MongoDB connection failed
  - **Solution**: Check MONGODB_URI in .env file

### Flutter App Issues
- **Error**: Assets not found
  - **Solution**: Run `flutter pub get`

- **Error**: Firebase not configured
  - **Solution**: Run Firebase setup and update firebase_options.dart

## 📚 Documentation

- **Backend**: See [VulnScan Backend/vulnscan-backend/README.md](VulnScan%20Backend/vulnscan-backend/README.md)
- **Desktop**: See [VulnScan Desktop/vulnscan/README.md](VulnScan%20Desktop/vulnscan/README.md)
- **Admin**: See [VulnScan Admin/vulnscan-admin/README.md](VulnScan%20Admin/vulnscan-admin/README.md)
- **Research**: See [VulnScan Research/paper/README.md](VulnScan%20Research/paper/README.md)

## 🔗 API Testing

### Using cURL
```bash
# Start a scan
curl -X POST http://localhost:8000/api/scans/create \
  -H "Content-Type: application/json" \
  -d '{"url":"https://github.com/user/repo"}'

# Get scan status
curl http://localhost:8000/api/scans/{scan_id}
```

### Using Postman
- Import the API from: `http://localhost:8000/docs`
- Use OpenAPI documentation for request formats

## 👥 Team & Contributors

- **Developer**: Vishal Poute
- **Project**: Final Year CSE Project
- **University**: Your University Name

## 📄 License

This project is licensed under the MIT License - see LICENSE file for details.

## 📧 Support & Feedback

For issues, suggestions, or feedback:
- Open an issue on GitHub
- Contact: vishalpoute@gmail.com
- Submit feedback through the app

## 🔄 Git Workflow

### Clone the entire project
```bash
git clone https://github.com/vishalpoute/vulnscan-final-year-project.git
cd "final year"
```

### Update all components
```bash
git pull origin main
```

### Push changes
```bash
git add .
git commit -m "Your commit message"
git push origin main
```

## 🎯 Future Enhancements

- [ ] Kubernetes deployment support
- [ ] Advanced threat detection ML model
- [ ] Real-time vulnerability alerts
- [ ] Integration with SIEM systems
- [ ] Mobile-specific security audits
- [ ] Compliance reporting (OWASP, PCI-DSS)
- [ ] Custom scan rules
- [ ] Team collaboration features

## 📊 Project Status

✅ **Complete**: Desktop App, Backend, Admin Dashboard
✅ **Tested**: All core functionality
✅ **Deployed**: Ready for production
✅ **Documented**: Comprehensive guides included

---

**Last Updated**: April 20, 2026
**Version**: 1.0.0
**Status**: Production Ready
