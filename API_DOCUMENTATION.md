# VulnScan Backend - Available APIs Documentation

## Project Repository
**GitHub:** https://github.com/vishalpoute/vulnscan-complete-project

---

## 🔌 Available API Endpoints

### 1. Authentication APIs
- `POST /api/auth/register` - User registration with email & password
- `POST /api/auth/login` - User login  
- `POST /api/auth/logout` - User logout
- `GET /api/auth/me` - Get current user profile

### 2. Scan APIs
- `GET /api/scans` - List all user scans
- `POST /api/scans/create` - Start new vulnerability scan
  - Parameters: URL/GitHub link of repository to scan
- `GET /api/scans/{scan_id}` - Get detailed scan results
- `GET /api/scans/{scan_id}/progress` - Real-time scan progress tracking

### 3. Payment APIs
- `POST /api/payments/verify-razorpay` - Verify Razorpay payment
- `GET /api/payments/subscription-status` - Check user subscription tier

### 4. User APIs
- `GET /api/users/profile` - Get user profile information
- `PUT /api/users/profile` - Update user profile
- `GET /api/users/subscription` - Get subscription details

### 5. Admin APIs (Restricted to Admin Users)
- `POST /api/admin/upgrade-user` - Upgrade user subscription tier
  - Parameters: user_email, tier (free/pro/enterprise)
- `POST /api/admin/reset-scans` - Reset user scan count
  - Parameters: user_email
- `GET /api/admin/users` - Get all users list
- `GET /api/admin/analytics` - System analytics & statistics

### 6. Feedback APIs
- `POST /api/feedback` - Submit user feedback
- `GET /api/feedback` - Get all feedback (admin only)

---

## 🛠️ Security Scanning Tools Integrated

| Tool | Purpose | Scan Type |
|------|---------|-----------|
| **Semgrep** | Static Application Security Testing (SAST) | Code Analysis |
| **Trufflehog** | Secret Detection | Secret Scanning |
| **MobSF** | Mobile App Security Analysis | Mobile Security |
| **npm-audit** | JavaScript/Node.js Vulnerabilities | Dependency Check |
| **Claude AI** | Intelligent Vulnerability Analysis | AI-Powered Analysis |

---

## 📊 Database & Infrastructure

**Databases Used:**
- MongoDB - Main data storage (Users, Scans, Results)
- Firebase Firestore - Cross-platform data synchronization
- Firebase Authentication - User authentication

**Backend Framework:** FastAPI (Python)
**Server:** Uvicorn on localhost:8000
**Documentation:** Swagger UI at `http://localhost:8000/docs`

---

## 🔄 API Response Format

All APIs return JSON responses:

```json
{
  "status": "success",
  "message": "Operation successful",
  "data": {
    "user_id": "123",
    "scan_id": "scan_001",
    ...
  }
}
```

---

## ✅ Key Features

✅ **Real-time Scanning** - Live vulnerability detection from GitHub repositories
✅ **Multi-Scanner Integration** - Combine results from 5+ security tools
✅ **User Subscriptions** - Free, Pro, and Enterprise tiers
✅ **Payment Integration** - Razorpay for secure payments
✅ **Admin Dashboard** - Manage users and system analytics
✅ **Cross-Platform** - Web & Mobile applications
✅ **Detailed Reports** - AI-powered vulnerability analysis and fixes
✅ **Firebase Sync** - Real-time data synchronization

---

## 🚀 API Testing

### Using cURL
```bash
# Register new user
curl -X POST http://localhost:8000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"password123"}'

# Start a scan
curl -X POST http://localhost:8000/api/scans/create \
  -H "Content-Type: application/json" \
  -d '{"url":"https://github.com/user/repo"}'

# Check scan status
curl http://localhost:8000/api/scans/scan_001
```

### Using Postman
1. Open Postman
2. Import: `http://localhost:8000/docs`
3. All endpoints available with auto-generated documentation

---

## 📱 Frontend Applications

**VulnScan Desktop** - Flutter web/mobile app
- User registration & authentication
- Repository scanning interface
- Real-time progress tracking
- Subscription management
- Payment integration (Razorpay)

**VulnScan Admin** - Admin dashboard
- User management
- Scan analytics
- System statistics
- Feedback management

---

## 📧 Support
For issues and inquiries: **vishupoute154@gmail.com**

---

**Project Status:** ✅ Production Ready
**Version:** 1.0.0
**Last Updated:** April 20, 2026
