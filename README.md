# 🐾 Karuṇā — AI-Powered Animal Rescue & Triage Platform

Welcome to the **Karuṇā** project! This repository contains a cross-platform animal rescue and triage platform powered by Google Gemini and Anthropic Claude AI. 

This project is organized for **team collaboration** where different members can focus on their domains of expertise (AI engineering, React Web development, Flutter Mobile development, or Spring Boot backend engineering).

---

## 🏗️ Project Architecture & Role Division

Karuṇā is split into modular components so team members can work in parallel without blocking each other.

`mermaid
graph TD
    classDef frontend fill:#e1f5fe,stroke:#0288d1,stroke-width:2px;
    classDef backend fill:#e8f5e9,stroke:#388e3c,stroke-width:2px;
    classDef ai fill:#fff3e0,stroke:#f57c00,stroke-width:2px;

    %% Frontends
    CitizenWeb["Vite/React Citizen Portal"]:::frontend
    NGOWeb["Vite/React NGO Portal"]:::frontend
    FlutterApp["Flutter Mobile App (Citizen, NGO, Vet)"]:::frontend

    %% Backend
    SpringBackend["Java Spring Boot Backend"]:::backend

    %% AI Services
    AIProxy["AI Provider Switcher (Gemini/Claude)"]:::ai
    Triage["AI Photo Triage (Vision)"]:::ai
    SitaChat["Sita AI Chatbot (NLP)"]:::ai

    %% Connections
    CitizenWeb -->|REST / WebSocket| SpringBackend
    NGOWeb -->|REST / WebSocket| SpringBackend
    FlutterApp -->|REST| SpringBackend

    SpringBackend --> AIProxy
    AIProxy --> Triage
    AIProxy --> SitaChat
`

### 👥 Collaboration Roles

#### 🤖 1. The Core AI Developer
* **Workspace:** karuna-backend/src/main/java/com/karuna/service/
* **Key Files:**
  * GeminiService.java — The main orchestrator for AI logic.
  * GeminiProvider.java — Google Gemini Flash API integration.
  * ClaudeProvider.java — Anthropic Claude API integration.
  * AiController.java — AI REST endpoints.
* **Responsibilities:**
  * **Prompt Engineering:** Refine instructions for animal triage, first aid steps, and case summaries.
  * **Vision Logic:** Enhance the image parsing capabilities for detecting wounds, animal species, and severity.
  * **Sita Chatbot:** Improve conversational capabilities, adding localized language support (Hindi, Tamil, etc.).
  * **Model Selection:** Benchmark and tune model configurations (temperatures, system prompts, etc.).

#### 🎨 2. The Frontend Developer
* **Workspace:** website/ (React) & lutter/ (Mobile)
* **React Web Portals:**
  * website/citizen/ — Portal for citizens to report injured animals, donate, and apply for adoption.
  * website/ngo/ — Dashboard for NGOs to dispatch responders and manage active cases.
* **Flutter Mobile App:**
  * lutter/ — Unified mobile app for Android and iOS that includes Citizen, NGO, and Veterinary clinical portals.
* **Responsibilities:**
  * Build responsive, highly aesthetic user interfaces using CSS/Tailwind (React) or Flutter widgets.
  * Integrate REST endpoints and WebSockets for real-time case updates.
  * Implement client-side location services, map routing, and camera capabilities.

#### ⚙️ 3. The Backend/Fullstack Developer
* **Workspace:** karuna-backend/ (Java Spring Boot)
* **Responsibilities:**
  * Manage PostgreSQL database schema migrations (schema.sql).
  * Build out REST APIs and secure endpoints using JWT (AuthService.java).
  * Implement WebSocket triggers for real-time messaging.

---

## 📂 Project Directory Structure

`
c:\Karuna_GAS\
├── karuna-backend\      # Java Spring Boot REST API
│   ├── src/             # Controller, DTO, Entity, Repository, Service layers
│   ├── pom.xml          # Maven dependency configuration
│   └── schema.sql       # PostgreSQL database initialization script
├── website\             # Vite / React Web applications
│   ├── citizen\         # Citizen portal web application
│   ├── ngo\             # NGO portal web application
│   └── shared\          # Salvaged shared services, store, types and utility classes
├── flutter\             # Cross-platform Flutter Mobile Application
│   ├── lib/             # Screens (auth, citizen, ngo, vet), models, providers, services
│   └── pubspec.yaml     # Dart/Flutter package configuration
├── start.bat            # Windows startup script to launch services
└── temp_work.md         # Active development task board / tracker
`

---

## 🚀 Getting Started (Local Setup)

To coordinate running backend services and frontends locally, follow these steps:

### 1. Backend & Database Setup
1. Install **Java Development Kit (JDK) 21** and **Maven**.
2. Spin up a local PostgreSQL database or obtain a PostgreSQL connection string (e.g. from Neon.tech).
3. Create a .env file inside the karuna-backend/ folder based on .env.example:
   `ash
   cp karuna-backend/.env.example karuna-backend/.env
   `
4. Fill in database connection strings and your AI API keys (CLAUDE_API_KEY and/or GEMINI_API_KEY).

### 2. Frontend Configuration
* **Web apps:** Copy .env.example to .env in both website/citizen/ and website/ngo/ folders. They default to http://localhost:8081 which is the local Spring Boot backend port.
* **Flutter app:** Modify the default server IP in lutter/lib/config/api_config.dart to match your local IP if running on a physical phone, or keep the default emulator loopback (10.0.2.2).

### 3. Launching Services
Run the launcher command script:
`ash
./start.bat
`
This utility script lets you quickly run:
1. **Java Backend + Citizen Web App** (Recommended)
2. **Java Backend + NGO Web App**
3. **All services simultaneously** (Backend + Citizen + NGO)
4. Or individual services alone.

---

## 🤝 Code of Collaboration

Let's maintain a neat codebase:
* **Never commit secrets:** Keep all .env files and API keys in your local environment. Do not push them to GitHub.
* **Feature Branches:** Create clean git feature branches (eature/ai-vision, eature/ngo-map) instead of working directly on main.
* **Sync Updates:** Log completed and remaining tasks in [temp_work.md](file:///c:/Karuna_GAS/temp_work.md) so the team is always aligned.
