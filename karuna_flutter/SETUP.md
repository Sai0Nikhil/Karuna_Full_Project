# Karuṇā Flutter App – Setup Guide

## Project Structure
```
karuna_flutter/
├── lib/
│   ├── main.dart                  ← App entry + routing
│   ├── config/
│   │   └── api_config.dart        ← 🔧 CHANGE BASE URL HERE
│   ├── models/                    ← Data models
│   ├── services/                  ← HTTP API calls
│   ├── providers/                 ← State management (Provider)
│   ├── screens/
│   │   ├── splash_screen.dart
│   │   ├── auth/                  ← Login, Register
│   │   ├── citizen/               ← Home, Report, MyCases, Donate, Adopt
│   │   └── ngo/                   ← Dashboard, CaseList, CaseDetail
│   ├── widgets/                   ← Reusable components
│   └── utils/                     ← Theme, Colors
└── pubspec.yaml
```

## Step 1 – Configure Backend URL

Open `lib/config/api_config.dart` and set your backend URL:

| Scenario | URL |
|---|---|
| Android Emulator (local) | `http://10.0.2.2:8081/api` |
| Physical device (same WiFi) | `http://192.168.x.x:8081/api` |
| ngrok tunnel | `https://xxxx.ngrok-free.app/api` |
| Production | `https://api.yourserver.com/api` |

## Step 2 – Install Dependencies

```bash
cd karuna_flutter
flutter pub get
```

## Step 3 – Start the Backend

```bash
cd karuna-backend
./mvnw spring-boot:run
# Backend starts at http://localhost:8081
```

## Step 4 – Run the Flutter App

```bash
# Emulator
flutter run

# Physical device
flutter run --release
```

## How Role-Based Routing Works

- Login → backend returns `role: "citizen"` or `role: "ngo"`
- `AuthProvider` reads the role and redirects to `/citizen` or `/ngo`
- Citizens see: Home, Report, Donate, Adopt, My Cases
- NGO staff see: Dashboard, All Cases (with assign/status update)

## API Endpoints Used

| Screen | Endpoint |
|---|---|
| Login | `POST /api/auth/login` |
| Register | `POST /api/auth/register` |
| Home feed | `GET /api/cases/open` |
| My Reports | `GET /api/cases/my` |
| Report Animal | `POST /api/cases` |
| Case Detail | `GET /api/cases/:id` |
| Donate | `POST /api/donations/case/:id` |
| Adopt | `POST /api/adoptions/case/:id/apply` |
| NGO – All Cases | `GET /api/cases` |
| NGO – Assign | `POST /api/cases/:id/assign` |
| NGO – Update Status | `POST /api/cases/:id/advance` |
| NGO – Add Note | `POST /api/cases/:id/notes` |
