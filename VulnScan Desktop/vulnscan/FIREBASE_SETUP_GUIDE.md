# Firebase Configuration Guide for VulnScan

## ✅ Current Status
- **Project ID**: `vulnscan-finalyear`
- **Authentication**: ✅ Configured (Email/Password)
- **All Platforms**: Web, Android, iOS, Windows, macOS configured

---

## 🔥 Firebase Features - RECOMMENDED SETUP

### 1. **Authentication** ✅ (REQUIRED - Already Enabled)
**Current Status**: Email/Password login configured
- Location: Firebase Console > Authentication > Sign-in method
- **Action**: ✅ Already enabled
- Users can register and login with email/password

### 2. **Cloud Firestore** 🔴 (MUST ENABLE)
**Current Status**: NOT enabled yet
- **Why**: Store user profiles, scan data, vulnerability reports
- **Action Required**:
  ```
  Go to: Firebase Console > Firestore Database
  1. Click "Create Database"
  2. Select: "Start in Test mode" (for development)
  3. Select Region: asia-south1 (India - closest to you)
  4. Click "Create"
  ```
- **Collection Structure** (will auto-create):
  ```
  users/
    ├── {userId}/
    │   ├── email: string
    │   ├── displayName: string
    │   ├── subscription: string (free/premium)
    │   └── createdAt: timestamp
  
  scans/
    ├── {scanId}/
    │   ├── userId: string
    │   ├── appUrl: string
    │   ├── status: string (pending/running/completed)
    │   ├── results: array
    │   └── createdAt: timestamp
  ```

### 3. **Cloud Storage** 🟡 (RECOMMENDED)
**Current Status**: Not yet configured
- **Why**: Store PDF reports, scan logs, app files
- **Action Required**:
  ```
  Go to: Firebase Console > Storage
  1. Click "Get Started"
  2. Select: "Start in Test mode"
  3. Select Region: asia-south1
  4. Click "Done"
  ```
- **Bucket Structure**:
  ```
  vulnscan-finalyear.appspot.com/
  ├── reports/
  │   └── {userId}/{scanId}/report.pdf
  ├── logs/
  │   └── {userId}/{scanId}/scan.log
  └── temp/
      └── {userId}/{appFile}
  ```

### 4. **Cloud Functions** 🟢 (OPTIONAL - Advanced)
**Current Status**: Not needed initially
- **Use Case**: Async scan processing, email notifications
- **Enable when**: You need background processing
- **Setup**:
  ```
  Firebase Console > Cloud Functions > Create New Function
  - Trigger: Firestore, Cloud Storage
  - Runtime: Python/Node.js
  ```

### 5. **Realtime Database** ⚪ (OPTIONAL)
**Current Status**: Not needed
- **Use Case**: Real-time scan progress updates
- **Recommendation**: Use Firestore instead (more modern)

### 6. **Analytics** 🟢 (OPTIONAL - For tracking)
**Current Status**: Can be enabled
- **Use Case**: Track user behavior, crashes
- **Setup**: Firebase Console > Analytics > Enable
- **Benefit**: Monitor app usage patterns

---

## 🔐 Security Rules (After Enabling Firestore & Storage)

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Users can only read/write their own scans
    match /scans/{document=**} {
      allow read, write: if request.auth.uid == resource.data.userId;
      allow create: if request.auth.uid == request.resource.data.userId;
    }
  }
}
```

### Cloud Storage Security Rules
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only access their own files
    match /reports/{userId}/{allPaths=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    match /logs/{userId}/{allPaths=**} {
      allow read, write: if request.auth.uid == userId;
    }
  }
}
```

---

## 📋 Setup Checklist

- [ ] **Phase 1 - Authentication** ✅
  - [x] Email/Password enabled
  - [x] Frontend configured
  
- [ ] **Phase 2 - Core Data** (DO THIS NOW)
  - [ ] Enable Cloud Firestore
  - [ ] Create collections
  - [ ] Set up security rules
  
- [ ] **Phase 3 - Storage** (After Phase 2)
  - [ ] Enable Cloud Storage
  - [ ] Configure CORS
  - [ ] Set up security rules
  
- [ ] **Phase 4 - Enhancement** (Later)
  - [ ] Enable Analytics
  - [ ] Setup Cloud Functions
  - [ ] Configure notifications

---

## 🚀 IMMEDIATE ACTION REQUIRED

### Enable These NOW (takes 5 minutes):
1. **Cloud Firestore** - Essential for app to work
2. **Cloud Storage** - For report exports

### Go To:
```
https://console.firebase.google.com/project/vulnscan-finalyear/overview
```

### Steps:
1. Click "Firestore Database" in left menu
2. Click "Create Database"
3. Select "Test Mode" + "asia-south1" region
4. Repeat for "Storage"
5. Copy security rules from above into each console

---

## 📱 App Integration Status

- ✅ Firebase Core: Initialized
- ✅ Authentication: Email/Password ready
- ⚠️ Firestore: Waiting to be enabled
- ⚠️ Storage: Waiting to be enabled
- ✅ Web: Ready to use
- ✅ Android: Ready to use
- ✅ iOS: Ready to use
- ✅ Windows: Ready to use

---

## ⚠️ Important Notes

1. **Test Mode**: Current "Test Mode" security rules allow anyone to read/write
   - **BEFORE PRODUCTION**: Change to strict rules above
   
2. **Billing**: Enable billing if you exceed free tier limits
   - Free tier: 1GB storage, 50K reads/day
   
3. **Region**: asia-south1 selected for lowest latency from India
   
4. **APIs Enabled** (already done):
   - Cloud Firestore API
   - Cloud Storage API
   - Cloud Functions API (optional)

---

## 🔗 Quick Links

- Firebase Console: https://console.firebase.google.com/project/vulnscan-finalyear
- Firestore: https://console.firebase.google.com/project/vulnscan-finalyear/firestore
- Storage: https://console.firebase.google.com/project/vulnscan-finalyear/storage
- Authentication: https://console.firebase.google.com/project/vulnscan-finalyear/authentication
