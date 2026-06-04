# 🚀 Karuṇā – Launch Guide (Hackathon Edition)

## What you need installed
- Java 17+
- Maven (or use the included `mvnw`)
- Flutter SDK (3.x)
- PostgreSQL 14+
- Android Studio (for emulator) OR a physical Android device

---

## Step 1 — Start PostgreSQL
Make sure PostgreSQL is running and the `karuna` database exists.

```sql
-- Run once in pgAdmin or psql
CREATE DATABASE karuna;
```

The backend auto-creates tables on first run (`spring.jpa.hibernate.ddl-auto=update`).

---

## Step 2 — Add your Gemini API key
Open `karuna-backend/src/main/resources/application.properties`
and replace the placeholder:

```properties
gemini.api.key=YOUR_GEMINI_API_KEY_HERE
```

Get a free key at: https://aistudio.google.com/apikey

---

## Step 3 — Start the Spring Boot backend

```bash
cd karuna-backend
./mvnw spring-boot:run
```

✅ Backend is ready when you see:
```
Started KarunaApplication on port 8081
```

---

## Step 4 — Set the Flutter API URL

Open `karuna_flutter/lib/config/api_config.dart` and set:

| Your device | URL to use |
|---|---|
| Android Emulator | `http://10.0.2.2:8081/api` ← default |
| Physical phone (same WiFi) | `http://192.168.X.X:8081/api` |
| ngrok (public URL) | `https://xxxx.ngrok-free.app/api` |

---

## Step 5 — Run the Flutter app

```bash
cd karuna_flutter
flutter pub get
flutter run
```

To run on a specific device:
```bash
flutter devices          # list connected devices
flutter run -d emulator  # run on emulator
flutter run -d <id>      # run on specific device
```

---

## Step 6 — Create test accounts

Use the app's Register screen OR call the API directly:

```bash
# Citizen account
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Sai Nikhil","email":"citizen@test.com","password":"pass123","role":"citizen"}'

# NGO account
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Priya NGO","email":"ngo@test.com","password":"pass123","role":"ngo","ngoName":"PawGuard Trust"}'

# Vet account
curl -X POST http://localhost:8081/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"Dr. Neha","email":"vet@test.com","password":"pass123","role":"vet","clinicName":"PawCare Clinic"}'
```

---

## 3 Portals, 3 logins

| Role | What they see |
|---|---|
| `citizen` | Report animal → AI analyzes → My Cases → Donate → Adopt |
| `ngo` | Dashboard → All cases → Assign volunteers → Update status |
| `vet` | Emergency requests → Slots → Treatment tracking → Clinic profile |

---

## Build APK for demo

```bash
cd karuna_flutter
flutter build apk --release
# APK will be at: build/outputs/flutter-apk/app-release.apk
```

---

## Quick troubleshooting

| Problem | Fix |
|---|---|
| `Connection refused` on device | Use your machine's LAN IP, not localhost |
| `Connection refused` on emulator | Use `10.0.2.2`, not `localhost` |
| Backend won't start | Check PostgreSQL is running on port 5432 |
| Flutter pub get fails | Run `flutter upgrade` first |
| Gemini AI not working | Check your API key in application.properties |
