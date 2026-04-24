# 🚀 VulnScan - Full Stack Running Guide

## ✅ What Has Been Done

### 1. **Backend Server - Running on Port 8000** ✓
- **Status**: ✅ Running
- **Framework**: FastAPI (Python)
- **Port**: 8000
- **URL**: `http://localhost:8000`
- **Health Check**: `http://localhost:8000/health`

**Backend Features**:
- RESTful API endpoints
- MongoDB integration
- Firebase authentication
- Auto-reload enabled for development

### 2. **Frontend Flutter App - Desktop (Windows)** ⏳
- **Status**: Building...
- **Target**: Windows Desktop
- **Framework**: Flutter 3.10+
- **Entry Point**: `lib/main.dart`

### 3. **Backend Status Dashboard Screen** ✓
- **Status**: ✅ Created
- **Route**: `/backend-status`
- **Features**:
  - Real-time server health monitoring
  - Server status indicator with live animation
  - API endpoint documentation
  - Configuration display
  - Network timeout info
  - Refresh capability
  - Dark/Light theme support

---

## 📋 How to Access Features

### 1. **Backend API**
```
Base URL: http://localhost:8000

Health Check Endpoint:
GET http://localhost:8000/health

Common Endpoints:
- GET  /api/scans              - List all scans
- POST /api/scans              - Create new scan
- GET  /api/vulnerabilities    - List vulnerabilities
- GET  /api/reports            - Get scan reports
```

### 2. **Backend Status Dashboard**
Once the app launches:
1. Log in to the application
2. Navigate to the Backend Status page via the menu
3. View real-time API health status
4. See all available endpoints
5. Check current configuration

### 3. **Managing Both Services**

#### Terminal 1 - Backend (Already Running)
```
cd "c:\final year\VulnScan Backend\vulnscan-backend"
python -m uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

#### Terminal 2 - Frontend
```
cd "c:\final year\VulnScan Desktop\vulnscan"
flutter run -d windows
```

---

## 🔍 Monitoring & Debugging

### Check Backend Health
```bash
# In PowerShell
Invoke-WebRequest -Uri "http://localhost:8000/health"

# Or in browser
http://localhost:8000/health
```

### View Backend Logs
The backend terminal will show:
- Request/Response logs
- Error messages
- Auto-reload notifications
- Database connection status

### View Frontend Logs
The Flutter terminal will show:
- Build progress
- Hot reload notifications
- App lifecycle events
- Console output

---

## 📁 Project Structure

```
VulnScan (Full Stack)
├── vulnscan/                 (Frontend - Flutter)
│   ├── lib/
│   │   ├── main.dart
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   │   ├── backend_status/    ← NEW!
│   │   │   │   ├── dashboard/
│   │   │   │   ├── settings/
│   │   │   │   └── ...
│   │   ├── services/
│   │   │   └── http_client_service.dart  (with health check)
│   │   └── config/
│   │       └── routing/
│   │           └── app_router.dart (with new route)
│   └── pubspec.yaml
│
└── vulnscan-backend/         (Backend - FastAPI)
    ├── main.py
    ├── core/
    ├── routers/
    ├── services/
    ├── models/
    └── requirements.txt
```

---

## 🎯 Next Steps

### For Development
1. ✅ Keep both services running
2. Edit frontend code and use Hot Reload (R key)
3. Edit backend code - auto-reload enabled
4. Monitor Backend Status Dashboard for connectivity

### Testing the Integration
1. Open Backend Status page in the app
2. Verify "Server Status: Online" ✓
3. Try making API calls from the dashboard
4. Check scan creation/listing functionality

### Building for Release
```bash
# Frontend
flutter build windows --release

# Backend
# Build Docker image or package with PyInstaller
```

---

## ⚙️ Configuration

### Frontend (.env)
```
API_BASE_URL=http://localhost:8000
NETWORK_TIMEOUT=30s
```

### Backend (.env)
```
DATABASE_URL=mongodb://localhost:27017
FIREBASE_CREDENTIALS=firebase_adminsdk.json
DEBUG=True
```

---

## 🆘 Troubleshooting

### Backend Won't Start
```bash
# Check if port 8000 is in use
netstat -ano | findstr :8000

# Kill process if needed
taskkill /PID <PID> /F
```

### Frontend Build Fails
```bash
# Clean build
flutter clean
flutter pub get
flutter run -d windows
```

### Backend Status Shows "Unreachable"
1. Verify backend terminal is running
2. Check if port 8000 is accessible: `http://localhost:8000/health`
3. Check firewall settings
4. Verify API_BASE_URL in .env file

### Hot Reload Not Working
Press `R` in the Flutter terminal to trigger hot reload
Or `r` for hot restart

---

## 📊 Testing API Endpoints

### Using PowerShell
```powershell
# Check health
Invoke-WebRequest -Uri "http://localhost:8000/health" -Method Get

# Create a scan (with auth token)
$headers = @{"Authorization" = "Bearer YOUR_TOKEN"}
Invoke-WebRequest -Uri "http://localhost:8000/api/scans" `
  -Method Post `
  -Headers $headers `
  -Body '{"target": "example.com"}' `
  -ContentType "application/json"
```

### Using cURL (if available)
```bash
curl http://localhost:8000/health
curl -X POST http://localhost:8000/api/scans \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"target": "example.com"}'
```

---

## 📱 Access Points

| Service | URL | Status | Purpose |
|---------|-----|--------|---------|
| Backend API | `http://localhost:8000` | Running ✓ | FastAPI server |
| Health Check | `http://localhost:8000/health` | Running ✓ | Backend status |
| Flutter App | `localhost` (desktop) | Building ⏳ | Main UI |
| Status Dashboard | `/backend-status` route | Ready ✓ | Monitor backend |

---

## 🎓 Learning Resources

- [Flutter Desktop Documentation](https://flutter.dev/multi-platform/desktop)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Riverpod State Management](https://riverpod.dev/)
- [Dio HTTP Client](https://pub.dev/packages/dio)

---

**Last Updated**: April 22, 2026
**Project**: VulnScan Full Stack
**Version**: 1.0.0
