# 🚀 Karuṇā – Full Deployment Guide

## Architecture
```
📱 APK (Flutter)  →  ☁️ Render.com (Spring Boot)  →  🗄️ Neon.tech (PostgreSQL)
     free                  free                           free
```

---

## PHASE 1 — Database on Neon (5 min)

1. Go to **https://neon.tech** → Sign up (GitHub login works)
2. Click **"New Project"** → Name: `karuna` → Create
3. On the dashboard, click **"Connect"** → copy the connection string:
   ```
   postgresql://neondb_owner:xxxx@ep-xxx.us-east-1.aws.neon.tech/neondb?sslmode=require
   ```
4. Note down separately:
   - **Host:** `ep-xxx.us-east-1.aws.neon.tech`
   - **User:** `neondb_owner`
   - **Password:** `xxxx`
   - **Database:** `neondb`

---

## PHASE 2 — Push Backend to GitHub (3 min)

> Render deploys directly from GitHub. You need to push your code first.

```bash
cd C:\Karuna_GAS\karuna-backend

git init
git add .
git commit -m "Karuna backend v1.0 - hackathon"

# Create a repo on github.com, then:
git remote add origin https://github.com/YOUR_USERNAME/karuna-backend.git
git push -u origin main
```

---

## PHASE 3 — Deploy Backend on Render (5 min)

1. Go to **https://render.com** → Sign up with GitHub
2. Click **"New +"** → **"Web Service"**
3. Connect your `karuna-backend` GitHub repo
4. Fill in settings:
   - **Name:** `karuna-backend`
   - **Runtime:** `Java`
   - **Build Command:** `./mvnw clean package -DskipTests`
   - **Start Command:** `java -jar target/karuna-backend-*.jar`
   - **Instance Type:** Free

5. Click **"Advanced"** → **"Add Environment Variables"** → Add these:

   | Key | Value |
   |-----|-------|
   | `SPRING_DATASOURCE_URL` | `jdbc:postgresql://ep-xxx.neon.tech/neondb?sslmode=require` |
   | `SPRING_DATASOURCE_USERNAME` | `neondb_owner` |
   | `SPRING_DATASOURCE_PASSWORD` | `your-neon-password` |
   | `KARUNA_JWT_SECRET` | `KaruNa2026SecReTKeyForJWTTokenGenerationMustBeLongEnough256Bits!!` |
   | `AI_PROVIDER` | `claude` (or `gemini`) |
   | `CLAUDE_API_KEY` | `sk-ant-your-key` |
   | `GEMINI_API_KEY` | `AIza-your-key` |

6. Click **"Create Web Service"**
7. Wait ~3 minutes for build. Your URL will be:
   ```
   https://karuna-backend.onrender.com
   ```

8. Test it works:
   ```
   https://karuna-backend.onrender.com/api/auth/health
   ```
   Should return: `{"status":"UP","app":"Karuṇā Backend"}`

> ⚠️ Free Render tier sleeps after 15 min of no traffic.
> First request after sleep takes ~30 sec to wake up.
> For hackathon demo: ping it once before presenting!

---

## PHASE 4 — Update Flutter with Production URL (1 min)

Open `karuna_flutter/lib/config/api_config.dart`:

```dart
// Change this line:
static const String baseUrl = 'https://karuna-backend.onrender.com/api';
```

Replace `karuna-backend` with your actual Render service name.

---

## PHASE 5 — Build the APK (3 min)

```bash
cd C:\Karuna_GAS\karuna_flutter

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# Your APK is here:
# build\app\outputs\flutter-apk\app-release.apk
```

To install on a phone directly:
```bash
flutter install   # installs on connected phone via USB
```

Or share the APK file — anyone can install it on Android!

---

## PHASE 6 — Share the APK

**Option A — USB / WhatsApp / Google Drive**
Just share the file: `build\app\outputs\flutter-apk\app-release.apk`

**Option B — QR Code for judges**
Upload to https://appetize.io (free) → get a link → show QR code

**Option C — Android emulator demo**
Keep `baseUrl = 'https://karuna-backend.onrender.com/api'`
Run `flutter run` on any emulator — it will hit the live server.

---

## Switching AI keys (when Claude expires)

```bash
# In Render dashboard → Environment → Edit:
AI_PROVIDER = gemini
GEMINI_API_KEY = AIza...your-key

# Click "Save Changes" → Render auto-restarts backend
# Done! No code changes, no redeploy needed.
```

---

## Quick checklist before demo

- [ ] `https://karuna-backend.onrender.com/api/auth/health` returns UP
- [ ] Can register a new citizen account from the app
- [ ] Can report an animal → AI auto-fills the fields
- [ ] NGO portal can see and update the case
- [ ] Vet portal loads the dashboard
- [ ] APK installs cleanly on demo phone

---

## Cost summary

| Service | Cost |
|---------|------|
| Neon PostgreSQL | **Free** (0.5 GB storage) |
| Render Web Service | **Free** (sleeps when idle) |
| Flutter APK | **Free** |
| Gemini API | **Free** (15 req/min) |
| Claude API | $5 credit (lasts days) |
| **Total** | **₹0** |
