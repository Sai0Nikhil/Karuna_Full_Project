# Karuna — Frontend Reorganization Progress Tracker
> LAST UPDATED: 2026-07-07 10:31 IST
> STATUS: REORGANIZATION COMPLETE
> Workspace: c:\Karuna_GAS

---

## GOAL (COMPLETED)
Reorganize all frontends into:
- c:\Karuna_GAS\website\      DONE - web frontend (citizen + ngo + shared)
- c:\Karuna_GAS\flutter\      DONE - Flutter mobile app
- c:\Karuna_GAS\karuna-backend\  UNTOUCHED - Java backend

---

## FINAL PROJECT STRUCTURE

c:\Karuna_GAS\
├── .git/
├── .gitignore                    [CREATED] covers secrets, build artifacts
├── temp_work.md                  [THIS FILE]
├── karuna-backend/               [UNTOUCHED] Java Spring Boot backend
│   ├── src/main/java/com/karuna/
│   │   ├── controller/ (6 controllers: Auth, Case, Adoption, Donation, AI, User)
│   │   ├── service/ (8 services: Auth, Case, Adoption, Donation, AI, Claude, Gemini, GeminiService)
│   │   ├── entity/ (4 JPA entities: User, Case, Donation, AdoptionApplication)
│   │   ├── dto/, repository/, config/
│   │   └── KarunaApplication.java
│   ├── src/main/resources/application.properties  [FIXED: no hardcoded creds]
│   ├── .env.example              [CREATED]
│   ├── pom.xml
│   └── schema.sql, seed.sql
├── website/                      [NEW] Web frontends
│   ├── README.md                 [CREATED]
│   ├── citizen/                  Citizen portal (from karuna-citizen/)
│   │   ├── src/
│   │   │   ├── components/: LandingPage, LoginPage, ReportFlow, CaseList, DonatePage, AdoptPage
│   │   │   ├── App.tsx, api.ts, main.tsx
│   │   ├── index.html, package.json, vite.config.ts, tsconfig.json
│   │   ├── .env.example, .env.production
│   │   └── public/
│   ├── ngo/                      NGO portal (from karuna-ngo/)
│   │   ├── src/
│   │   │   ├── components/: Dashboard, CaseList, CaseDetail, LoginPage
│   │   │   ├── App.tsx, api.ts, main.tsx
│   │   ├── index.html, package.json, vite.config.ts, tsconfig.json
│   │   └── .env.example, .env.production
│   └── shared/                   Unique assets from old Karuna- monorepo
│       ├── components/: StatsView, SitaLive, AnalysisResult, AutoDispatchPanel, ImageUploader, Loader, shared
│       ├── services/: api.ts, claudeService.ts, geminiService.ts, dispatch.ts, realtime.ts
│       ├── store/: StoreProvider, caseStore, remoteCaseStore, router
│       ├── types.ts
│       └── constants.ts
└── flutter/                      [NEW] Flutter mobile app (from karuna_app/)
    ├── README.md                 [CREATED]
    ├── lib/
    │   ├── main.dart             (routing, providers setup)
    │   ├── screens/
    │   │   ├── auth/: choose_role, login, register
    │   │   ├── citizen/: home, report_flow, case_detail, donate, adopt, first_aid, sita_chat, my_cases
    │   │   ├── ngo/: home, dashboard, case_list, case_detail, map_routing
    │   │   └── vet/: home, cases, clinic, slots, tracking
    │   ├── providers/: auth_provider, case_provider
    │   ├── services/: api, ai, auth, case, donation, adoption
    │   ├── models/: case, user, donation, adoption
    │   ├── widgets/: case_card, loading_button, status_badge
    │   └── utils/: app_theme
    ├── pubspec.yaml, pubspec.lock
    ├── android/, ios/, web/, linux/, macos/, windows/
    └── assets/images/

---

## COMPLETED STEPS (ALL DONE)
[x] Cleanup phase (see history above)
[x] Created website/ with citizen/ and ngo/ sub-folders
[x] Moved karuna-citizen/ -> website/citizen/ (excluding node_modules)
[x] Moved karuna-ngo/ -> website/ngo/ (excluding node_modules)
[x] Moved karuna_app/ -> flutter/ (excluding build/, .dart_tool/)
[x] Salvaged unique Karuna- assets to website/shared/
    - StatsView, SitaLive, AnalysisResult, AutoDispatchPanel, ImageUploader, Loader, shared.tsx
    - claudeService, geminiService, dispatch, realtime, api services
    - store (caseStore, remoteCaseStore, StoreProvider, router)
    - types.ts, constants.ts
[x] Deleted old Karuna-/ monorepo (all unique parts salvaged first)
[x] Deleted karuna-citizen/, karuna-ngo/, karuna_app/ shell folders
[x] Created website/README.md
[x] Created flutter/README.md
[x] Rewrote start.bat with new paths (7 options, all correct)

---

## REMAINING TASKS FOR NEXT AGENT (if needed)

### HIGH PRIORITY
1. Run npm install in website/citizen and website/ngo (node_modules were NOT moved)
   cd website\citizen && npm install
   cd website\ngo && npm install

2. Run flutter pub get in flutter/
   cd flutter && flutter pub get

3. Verify builds:
   cd website\citizen && npm run dev  (should open on :5173)
   cd website\ngo && npm run dev      (should open on :5174)
   cd flutter && flutter run

### OPTIONAL / FUTURE
4. website/shared/ components (StatsView, SitaLive) need to be wired into
   citizen/ or ngo/ app if you want them accessible from the web.
   Currently they exist as reference/copy — not linked to any running app.
   
5. The website/citizen/ ReportFlow uses basic AI — consider upgrading it to
   use the claudeService/geminiService from website/shared/services/

6. Add register page to website/citizen/ (currently only has login)

---

## BACKEND REFERENCE
- Active: karuna-backend/ (Java Spring Boot, port 8081 locally)
- DB: Neon PostgreSQL Singapore
  - URL: set via SPRING_DATASOURCE_URL env var
  - User: neondb_owner
  - Password: set via SPRING_DATASOURCE_PASSWORD env var
- AI: Dual provider (set AI_PROVIDER=gemini or =claude in env)
  - Claude key: CLAUDE_API_KEY
  - Gemini key: GEMINI_API_KEY
- JWT: KARUNA_JWT_SECRET env var
- API base: /api/ (auth, cases, donations, adoptions, ai/triage)
- WebSocket: /ws

### Render Deployment
- Backend is deployed on Render (see render.yaml in karuna-backend/)
- Set all env vars in Render dashboard
- Citizen frontend: Vercel (see VERCEL_DEPLOY.md)
- NGO frontend: can also be deployed on Vercel separately
