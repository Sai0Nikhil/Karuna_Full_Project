# Karuṇā — Flutter Mobile App

Cross-platform mobile/desktop app built with Flutter. Supports Android, iOS, Web, Windows, Linux, macOS.

## Structure

```
flutter/
└── lib/
    ├── main.dart           ← App entry, routing
    ├── screens/
    │   ├── auth/           ← choose_role, login, register
    │   ├── citizen/        ← home, report_flow, case_detail, donate, adopt, first_aid, sita_chat, my_cases
    │   ├── ngo/            ← dashboard, case_list, case_detail, map_routing
    │   └── vet/            ← home, cases, clinic, slots, tracking
    ├── providers/          ← auth_provider, case_provider (state management)
    ├── services/           ← api_service, ai_service, auth_service, case_service, donation_service, adoption_service
    ├── models/             ← case_model, user_model, donation_model, adoption_model
    ├── widgets/            ← case_card, loading_button, status_badge
    └── utils/              ← app_theme, helpers
```

## Features (richest frontend)

### Citizen Portal
- 📸 AI-powered animal photo triage (report flow)
- 💬 Sita AI chat assistant
- 🩹 First Aid guide
- 💰 Donate to cases
- 🐾 Adopt animals
- 📋 My reported cases history

### NGO Portal
- 📊 Dashboard with live case stats
- 📋 Case list & detailed view
- ✅ Assign & dispatch responders
- 🗺️ **Map routing** to animal location (exclusive to Flutter)

### Vet Portal *(exclusive to Flutter)*
- 🏥 Clinic management
- 🕐 Slot scheduling
- 🔍 Case tracking
- 📋 Assigned cases view

## Getting Started

```bash
cd flutter
flutter pub get
flutter run
```

## Backend
Connects to the **Java Spring Boot** backend in `../karuna-backend/`.
Configure the API URL in `lib/config/`.
