# Karuṇā — Website Frontend

This folder contains the web frontend for Karuṇā, split into two separate Vite/React apps.

## Structure

```
website/
├── citizen/      ← Citizen-facing portal (report, donate, adopt, my cases)
├── ngo/          ← NGO staff portal (dashboard, case management, dispatch)
└── shared/       ← Shared components & services (Stats, AI chat, realtime, types)
    ├── components/   StatsView, SitaLive, AnalysisResult, AutoDispatchPanel, etc.
    ├── services/     claudeService, geminiService, dispatch, realtime, api
    ├── store/        State management (caseStore, remoteCaseStore, router)
    ├── types.ts
    └── constants.ts
```

## Running Locally

### Citizen Portal (port 5173)
```bash
cd citizen
npm install
npm run dev
```

### NGO Portal (port 5174)
```bash
cd ngo
npm install
npm run dev
```

## Environment Variables

Copy `.env.example` to `.env` in each sub-folder and fill in real values:

```
VITE_API_URL=http://localhost:8081   # Java Spring Boot backend
```

For production, `.env.production` already points to the Render deployment.

## Features

| Feature | citizen/ | ngo/ |
|---|---|---|
| Landing Page | ✅ | — |
| Login | ✅ | ✅ |
| AI Photo Triage (report animal) | ✅ | — |
| Case List | ✅ | ✅ |
| Case Detail | — | ✅ |
| Donate | ✅ | — |
| Adopt | ✅ | — |
| NGO Dashboard | — | ✅ |
| Assign / Dispatch Cases | — | ✅ |
| Stats & Analytics | shared/ | shared/ |
| Sita AI Chat | shared/ | shared/ |
| Real-time WebSocket | shared/ | shared/ |

## Backend
The web apps connect to the **Java Spring Boot** backend in `../karuna-backend/`.
See `../karuna-backend/.env.example` for required environment variables.
