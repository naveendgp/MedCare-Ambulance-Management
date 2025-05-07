# 🚑 MedCare – Ambulance Management System

MedCare is a full-featured **Flutter** app built with **Firebase** to provide real-time ambulance booking, tracking, and emergency coordination. Designed to prioritize urgent care and reduce response time, this system supports users, drivers, and admin workflows.

---

## 🧩 Features Overview

### ✅ 1. Project Setup and Configuration
- Flutter project initialized with structured folders:
  - `/lib/app/`, `/lib/components/`, `/lib/firebase/`, etc.
- Dependencies:
  - `firebase_auth`, `cloud_firestore`, `geolocator`, `google_maps_flutter`
  - `flutter_riverpod` or `provider` for state management
  - `flutter_dotenv` for environment configuration

---

### 🔐 2. Authentication Module
- **Firebase Auth** integration
- Email/Password Login & Signup
- Error handling (invalid credentials, user not found)
- Role-based navigation post-login (User, Driver, Admin)

Screens:
- `LoginScreen`
- `SignupScreen`

---

### 🧭 3. User Dashboard
- Central dashboard with navigation options:
  - Book Ambulance
  - View Booking History
  - Track Live Ambulance
- Navigation handled via `go_router` or `flutter_navigation_2.0`

---

### 📝 4. Booking Module
- Ambulance Booking Form:
  - Location input (manual or auto via GPS)
  - Select priority (Emergency, Non-Emergency, Inter-Hospital)
  - Submit booking → Stored in Firebase Firestore
- Real-time Firestore updates enabled

---

### 📜 5. Booking History
- Fetch all previous bookings for the user
- Display:
  - Date, Priority, Status, Destination
- Clean ListView with basic styling

---

### 📍 6. Tracking Module (Simulated)
- Real-time location with **Google Maps Flutter**
- Show user and simulated ambulance location
- Display ambulance status (`On the way`, `Arrived`, `Completed`)

---

### 🏥 7. Hospital Suggestion (Mock)
- Static list of nearby hospitals (mocked for now)
- Automatically suggest nearest based on booking priority
- Future Scope: Integrate with real hospital bed APIs

---

### 🧪 8. Polishing & Testing
- Responsive UI for both Android and iOS
- Manual testing on emulator + real devices
- Functionality Tests:
  - Auth flow
  - Booking creation
  - Map & location rendering
  - Firestore data syncing

---

### 🚀 9. (Optional) Advanced Features – For Future
- Push Notifications (FCM)
- SMS Alerts (Twilio / Firebase Functions)
- Admin Panel with Analytics
- AI-Powered Route Optimization

---


