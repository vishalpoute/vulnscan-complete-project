# 🛡️ VulnScan - Vulnerability Scanning & Analysis Platform

![VulnScan Banner](https://img.shields.io/badge/VulnScan-Security%20Scanning-red)
![Flutter](https://img.shields.io/badge/Flutter-3.10+-blue)
![Python](https://img.shields.io/badge/Python-3.12+-green)
![License](https://img.shields.io/badge/License-MIT-yellow)

## 📋 Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Who Benefits](#who-benefits)
- [Project Structure](#project-structure)
- [System Requirements](#system-requirements)
- [Installation Guide](#installation-guide)
- [Backend Setup](#backend-setup)
- [Frontend Setup](#frontend-setup)
- [Running the Application](#running-the-application)
- [API Documentation](#api-documentation)
- [Development Workflow](#development-workflow)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)

---

## 🎯 Overview

**VulnScan** is a comprehensive vulnerability scanning and analysis platform built with **Flutter** (frontend) and **FastAPI** (backend). It enables developers, security teams, and organizations to identify, analyze, and remediate security vulnerabilities in their applications and systems.

The platform provides:
- 🔍 **Real-time vulnerability scanning** across multiple platforms
- 📊 **Detailed security reports** with actionable insights
- 🚀 **Multi-platform support** (Android, iOS, Windows, Linux, macOS, Web)
- ☁️ **Cloud-based backend** with MongoDB database
- 🔐 **Firebase authentication** for secure access
- 📈 **Advanced analytics** and trend analysis

---

## ✨ Features

### Frontend (Flutter)
- Cross-platform mobile and desktop UI
- Real-time scanning status updates
- Interactive vulnerability reports
- PDF export functionality
- User authentication & profile management
- Payment integration for premium features
- Dark/Light theme support

### Backend (FastAPI)
- RESTful API with comprehensive endpoints
- Asynchronous processing for high performance
- MongoDB integration for scalable storage
- Firebase Admin SDK integration for auth
- AI-powered vulnerability analysis (Claude API)
- Integration with third-party security tools (MobSF, OpenAI)
- Advanced filtering and search capabilities

---

## 🎯 Who Benefits

This project is designed for:

| User Type | Benefits |
|-----------|----------|
| **Developers** | Identify and fix vulnerabilities during development |
| **Security Teams** | Monitor and manage security across multiple projects |
| **DevOps Engineers** | Automate security scanning in CI/CD pipelines |
| **Organizations** | Centralized vulnerability management and compliance tracking |
| **Enterprises** | Comprehensive security intelligence and reporting |

---

## 📁 Project Structure

```
vulnscan/
├── lib/                          # Flutter frontend code
│   ├── main.dart                 # App entry point
│   ├── config/                   # Configuration & routing
│   │   ├── constants/            # App constants
│   │   ├── routing/              # Navigation routes
│   │   └── theme/                # UI themes
│   ├── data/                     # Data layer
│   │   ├── datasources/          # API calls & local storage
│   │   ├── models/               # Data models
│   │   └── repositories/         # Business logic
│   ├── domain/                   # Domain layer
│   │   ├── entities/             # Core business objects
│   │   ├── failures.dart         # Error handling
│   │   └── usecases/             # Use cases
│   ├── presentation/             # UI layer
│   │   ├── providers/            # State management (Riverpod)
│   │   ├── screens/              # UI screens
│   │   └── widgets/              # Reusable components
│   ├── services/                 # Core services
│   │   ├── http_client_service.dart  # API client
│   │   └── pdf_export_service.dart   # PDF export
│   └── utils/                    # Utilities
│       ├── extensions/           # Dart extensions
│       ├── formatters/           # Data formatters
│       └── validators/           # Input validators
│
├── test/                         # Flutter tests
│   └── widget_test.dart          # Widget tests
│
├── android/                      # Android-specific code
├── ios/                          # iOS-specific code
├── windows/                      # Windows desktop code
├── linux/                        # Linux desktop code
├── macos/                        # macOS desktop code
├── web/                          # Web build configuration
│
├── pubspec.yaml                  # Flutter dependencies & config
├── analysis_options.yaml         # Dart linting rules
└── README.md                     # This file

vulnscan-backend/                 # Backend folder (separate)
├── main.py                       # FastAPI app entry point
├── requirements.txt              # Python dependencies
├── .env                          # Environment variables
├── .env.example                  # Example env file
├── routes/                       # API endpoints
├── models/                       # Data models
├── services/                     # Business logic
└── utils/                        # Helper utilities
```

---

## 🖥️ System Requirements

### Frontend (Flutter)
- **OS**: Windows 10+, macOS 10.15+, Linux (Ubuntu 18.04+), iOS 11+, Android 5.0+
- **Flutter SDK**: 3.10.8 or higher
- **Dart SDK**: 3.10.8 or higher
- **RAM**: Minimum 4GB (8GB recommended)
- **Disk Space**: 2GB free space

### Backend (Python FastAPI)
- **OS**: Windows, macOS, Linux
- **Python**: 3.12 or higher
- **MongoDB**: 4.6 or higher (local or cloud)
- **RAM**: Minimum 2GB (4GB recommended)
- **Disk Space**: 1GB free space

### Required Services
- **Firebase Project** - For authentication
- **MongoDB Database** - For data storage
- **Claude API Key** - For AI-powered analysis
- **OpenAI API Key** (optional) - For additional analysis
- **MobSF API** (optional) - For mobile app scanning

---

## 📦 Installation Guide

### Prerequisites Installation

#### 1. **Install Flutter**

**Windows:**
```powershell
# Download Flutter from https://flutter.dev/docs/get-started/install/windows
# Add to PATH and verify installation
flutter --version
```

**macOS:**
```bash
brew install flutter
flutter --version
```

**Linux (Ubuntu):**
```bash
sudo apt-get update
sudo apt-get install -y curl git xz-utils zip libglu1-mesa clang cmake ninja-build pkg-config libgtk-3-dev
# Download and extract Flutter from https://flutter.dev/docs/get-started/install/linux
flutter --version
```

#### 2. **Install Python 3.12**

**Windows:**
```powershell
# Download from https://www.python.org/downloads/
# During installation, CHECK "Add Python to PATH"
python --version
```

**macOS:**
```bash
brew install python@3.12
python3.12 --version
```

**Linux (Ubuntu):**
```bash
sudo apt-get update
sudo apt-get install -y python3.12 python3.12-venv python3.12-dev
python3.12 --version
```

#### 3. **Install MongoDB**

**Option A: Local Installation**
- Download from https://www.mongodb.com/try/download/community
- Follow installation guide for your OS
- Verify: `mongod --version`

**Option B: MongoDB Atlas (Cloud)**
- Create account at https://www.mongodb.com/cloud/atlas
- Create a cluster and get connection string
- Update MongoDB URI in `.env` file

#### 4. **Get API Keys**
- **Firebase**: https://console.firebase.google.com/
- **Claude API**: https://console.anthropic.com/
- **OpenAI** (optional): https://platform.openai.com/

---

## 🚀 Backend Setup

### Step 1: Navigate to Backend Directory
```powershell
# Windows
cd "c:\final year\VulnScan Backend\vulnscan-backend"

# macOS/Linux
cd ~/path-to/vulnscan-backend
```

### Step 2: Create Python Virtual Environment
```bash
# Windows
python3.12 -m venv venv
.\venv\Scripts\Activate.ps1

# macOS/Linux
python3.12 -m venv venv
source venv/bin/activate
```

### Step 3: Install Dependencies
```bash
pip install -r requirements.txt
```

**Note**: If you get pydantic-core errors, ensure you're using Python 3.12 (not 3.14). Python 3.14 lacks pre-built wheels.

### Step 4: Configure Environment Variables
```bash
# Copy example file
cp .env.example .env

# Edit .env with your credentials:
```

Edit `.env` file with your actual credentials:
```ini
# Firebase Configuration
FIREBASE_PROJECT_ID=vulnscan-finalyear
FIREBASE_PRIVATE_KEY=<your-private-key>
FIREBASE_CLIENT_EMAIL=<your-client-email>

# MongoDB Configuration
MONGODB_URI=mongodb://localhost:27017
MONGODB_DB_NAME=vulnscan

# API Keys
CLAUDE_API_KEY=<your-claude-api-key>
OPENAI_API_KEY=<your-openai-key>
MOBSF_API_KEY=<your-mobsf-key>

# Server Configuration
DEBUG=true
HOST=0.0.0.0
PORT=8000
TEMP_DIR=/tmp/vulnscan
```

### Step 5: Start MongoDB
```bash
# If running locally:
mongod

# If using MongoDB Atlas, ensure URI in .env is correct
```

### Step 6: Run Backend Server
```bash
python3.12 -m uvicorn main:app --reload --port 8000
```

Expected output:
```
INFO:     Uvicorn running on http://0.0.0.0:8000
INFO:     Application startup complete
```

### Step 7: Verify Backend
```bash
# In new terminal
curl http://localhost:8000/
curl http://localhost:8000/docs   # SwaggerUI documentation
```

---

## 📱 Frontend Setup

### Step 1: Navigate to Frontend Directory
```bash
cd c:\final year\VulnScan Desktop\vulnscan
```

### Step 2: Get Flutter Dependencies
```bash
flutter pub get
```

### Step 3: Check Connected Devices
```bash
flutter devices
```

Example output:
```
2 connected devices:

AOSP on IA Emulator (emulator-5554) • emulator-5554 • android-x86    • Android 11 (API 30)
Chrome (web)                         • chrome        • web-javascript • unknown
```

### Step 4: Run Code Analysis
```bash
flutter analyze
```

### Step 5: Run Tests
```bash
flutter test
flutter test --coverage      # With coverage report
```

---

## 🎮 Running the Application

### Mobile (Android)
```bash
flutter run -d emulator-5554
```

### Mobile (iOS - macOS only)
```bash
flutter run -d <device-id>
```

### Desktop (Windows)
```bash
flutter run -d windows
```

### Desktop (Linux)
```bash
flutter run -d linux
```

### Desktop (macOS)
```bash
flutter run -d macos
```

### Web
```bash
flutter run -d chrome
```

### Release Build
```bash
# Android APK
flutter build apk --release

# iOS App
flutter build ios --release

# Windows Desktop
flutter build windows --release

# Web
flutter build web --release

# Linux Desktop
flutter build linux --release
```

---

## 📚 API Documentation

Once the backend is running, access:

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- **OpenAPI JSON**: http://localhost:8000/openapi.json

### Main API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/auth/login` | User login |
| POST | `/auth/register` | User registration |
| POST | `/scans/` | Create new scan |
| GET | `/scans/` | List all scans |
| GET | `/scans/{id}` | Get scan details |
| GET | `/scans/{id}/report` | Download report |
| POST | `/admin/users` | Manage users |
| GET | `/health` | Health check |

---

## 💻 Development Workflow

### Backend Development
```bash
# Activate virtual environment
source venv/bin/activate  # macOS/Linux
.\venv\Scripts\Activate.ps1  # Windows

# Install new package
pip install package-name
pip freeze > requirements.txt

# Run server with auto-reload
python3.12 -m uvicorn main:app --reload --port 8000

# Run tests
pytest

# Code quality checks
pylint main.py
black main.py
```

### Frontend Development
```bash
# Get dependencies
flutter pub get

# Run with hot reload
flutter run

# Format code
flutter format .

# Analyze code
flutter analyze

# Generate build files
flutter pub run build_runner build

# Create release build
flutter build apk --release
```

### Git Workflow
```bash
# Create feature branch
git checkout -b feature/your-feature

# Make changes and commit
git add .
git commit -m "feat: add new feature"

# Push to remote
git push origin feature/your-feature

# Create Pull Request on GitHub
```

---

## 🐛 Troubleshooting

### Backend Issues

**Problem**: `No module named uvicorn`
```bash
# Solution: Install dependencies
pip install -r requirements.txt
```

**Problem**: `pydantic-core compilation error`
```bash
# Solution: Use Python 3.12 instead of 3.14
python3.12 -m pip install -r requirements.txt
```

**Problem**: `MongoDB connection refused`
```bash
# Solution: Start MongoDB locally
mongod

# Or update .env with correct MongoDB Atlas URI
MONGODB_URI=mongodb+srv://user:pass@cluster.mongodb.net/
```

**Problem**: Firebase credentials error
```bash
# Solution: Verify .env file has correct Firebase credentials
# Download service account key from Firebase Console
```

### Frontend Issues

**Problem**: `Flutter not found`
```bash
# Solution: Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"  # macOS/Linux
```

**Problem**: Device not detected
```bash
# Solution: 
flutter devices
flutter config --android-sdk /path/to/sdk
```

**Problem**: Build cache issues
```bash
# Solution: Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## 🤝 Contributing

We welcome contributions! Here's how:

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Commit changes**: `git commit -m "Add amazing feature"`
4. **Push to branch**: `git push origin feature/amazing-feature`
5. **Open a Pull Request**

### Contribution Guidelines
- Follow the existing code style
- Add tests for new features
- Update documentation
- Keep commits atomic and well-described
- Ensure code passes analysis: `flutter analyze`, `pylint`, `black`

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 👥 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/yourname/vulnscan/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourname/vulnscan/discussions)
- **Email**: your-email@example.com

---

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- FastAPI for the high-performance backend
- Firebase for authentication services
- MongoDB for database solutions
- Claude AI for vulnerability analysis

---

## 📊 Project Statistics

- **Frontend**: Flutter + Dart
- **Backend**: FastAPI + Python 3.12
- **Database**: MongoDB
- **Authentication**: Firebase
- **Platforms**: Android, iOS, Windows, Linux, macOS, Web
- **Status**: Active Development

---

**Last Updated**: April 2026
**Version**: 1.0.0

Made with ❤️ for security-conscious developers
