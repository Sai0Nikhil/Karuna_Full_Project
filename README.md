# 🐾 Karuṇā — AI-Powered Animal Rescue & Triage Platform

[![Java](https://img.shields.io/badge/Java-21-blue)](https://www.java.com/)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.3.13-brightgreen)](https://spring.io/projects/spring-boot)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-blue)](https://www.postgresql.org/)
[![MongoDB](https://img.shields.io/badge/MongoDB-6%2B-green)](https://www.mongodb.com/)
[![License](https://img.shields.io/badge/License-Internal-lightgrey)](https://github.com/rushmanthnalluri/Karuna_Full_Project)

**Karuṇā** is a cross-platform animal rescue and triage platform that connects citizens, NGOs, volunteers, and veterinarians to rescue and care for injured animals. The platform leverages AI for intelligent triage, rescue prioritization, and conversational assistance.

This repository is a **monorepo** containing the Spring Boot backend, React web portals, and Flutter mobile application.

---

## 📁 Repository Structure

| Component | Path | Description |
|-----------|------|-------------|
| **Backend** | `springboot/` | Java Spring Boot REST API with PostgreSQL, MongoDB, JWT auth, and analytics |
| **Citizen Web** | `website/citizen/` | Vite/React portal for citizens to report cases, donate, and adopt |
| **NGO Web** | `website/ngo/` | Vite/React dashboard for NGOs to manage cases and volunteers |
| **Shared** | `website/shared/` | Shared React components, types, and API services |
| **Mobile** | `flutter/` | Flutter mobile app for Android/iOS (Citizen, NGO, Vet portals) |

---

## 🚀 Quick Start

### Prerequisites
- **JDK 21** and **Maven 3.9+**
- **PostgreSQL 15+** (or Neon.tech cloud)
- **MongoDB 6+** (optional for document storage)
- **Node.js 18+** and **npm** (for frontend)
- **Flutter 3.x** (for mobile)

### Backend Setup

```bash
cd springboot
cp .env.example .env
# Edit .env with your database credentials and API keys

mvn clean compile
mvn test
mvn spring-boot:run
```

The backend starts on `http://localhost:8081`.

- **Swagger UI**: `http://localhost:8081/swagger-ui.html`
- **OpenAPI JSON**: `http://localhost:8081/v3/api-docs`
- **Actuator**: `http://localhost:8081/actuator/health`

### Frontend Setup

```bash
# Citizen portal
cd website/citizen
npm install
npm run dev

# NGO portal
cd website/ngo
npm install
npm run dev
```

### Mobile Setup

```bash
cd flutter
flutter pub get
flutter run
```

---

## 📚 Documentation

### Backend Documentation
The backend has comprehensive documentation inside the `springboot/` directory:

| Document | Description |
|----------|-------------|
| [springboot/README.md](springboot/README.md) | Backend-specific README with tech stack, architecture, API docs, and deployment guide |
| [springboot/docs/architecture.md](springboot/docs/architecture.md) | Layered architecture, request flows, authentication, authorization |
| [springboot/docs/module-overview.md](springboot/docs/module-overview.md) | Summary of all backend modules |
| [springboot/docs/milestone-5-plan.md](springboot/docs/milestone-5-plan.md) | Roadmap for AI Integration Platform (Milestone 5) |
| [springboot/docs/database-design.md](springboot/docs/database-design.md) | Entity-to-table mapping, relationships, indexing strategy |
| [springboot/docs/er-diagram.md](springboot/docs/er-diagram.md) | ER diagram in Mermaid syntax |

### Frontend Documentation
See [website/README.md](website/README.md) for frontend setup and conventions.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     KARUNA MONOREPO                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────────┐  │
│  │   Citizen    │  │     NGO      │  │     Mobile      │  │
│  │   Web App    │  │   Web App    │  │   (Flutter)     │  │
│  │  (React)     │  │  (React)     │  │                 │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬────────┘  │
│         │                  │                    │           │
│         └──────────────────┼────────────────────┘           │
│                            │                               │
│                    ┌───────▼────────┐                      │
│                    │   Spring Boot  │                      │
│                    │    Backend     │                      │
│                    │  (Port 8081)   │                      │
│                    └───────┬────────┘                      │
│                            │                               │
│         ┌──────────────────┼──────────────────┐            │
│         │                  │                  │            │
│    ┌────▼────┐       ┌────▼────┐      ┌─────▼─────┐      │
│    │PostgreSQL│       │ MongoDB │      │  AI APIs  │      │
│    │  (JPA)  │       │(Docs)   │      │(Gemini/   │      │
│    │         │       │         │      │ Claude)   │      │
│    └─────────┘       └─────────┘      └───────────┘      │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 🔐 Authentication

The backend uses **JWT-based stateless authentication**:

- **Access tokens**: Short-lived (15 minutes), used for API authentication
- **Refresh tokens**: Long-lived (7 days), stored hashed in PostgreSQL, rotated on use
- **Roles**: `CITIZEN`, `NGO`, `VOLUNTEER`, `VET`, `ADMIN`
- **Authorization**: Method-level via `@PreAuthorize` with role checks

All API requests (except auth endpoints) require a Bearer token:

```
Authorization: Bearer <access_token>
```

---

## 🧪 Testing

```bash
# Run all tests
mvn test

# Run specific test class
mvn test -Dtest=DonationServiceTest

# Run with coverage (requires JaCoCo configuration)
mvn test jacoco:report
```

Current test suite: **69 unit tests** covering services, security, and authorization.

---

## 🔧 Configuration

The backend is configured via environment variables. See [springboot/.env.example](springboot/.env.example) for all available options.

Key environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `SPRING_PROFILES_ACTIVE` | Active Spring profile | `dev` |
| `POSTGRES_URL` | PostgreSQL JDBC URL | `jdbc:postgresql://localhost:5432/karuna` |
| `MONGODB_URI` | MongoDB connection string | `mongodb://localhost:27017/karuna` |
| `KARUNA_JWT_SECRET` | JWT signing secret (min 32 chars) | — |
| `GEMINI_API_KEY` | Google Gemini API key | — |
| `CLAUDE_API_KEY` | Anthropic Claude API key | — |

---

## 📊 Technology Stack

### Backend
- **Framework**: Spring Boot 3.3.13
- **Language**: Java 21
- **Security**: Spring Security 6, JWT (JJWT 0.12.6), BCrypt
- **Persistence**: PostgreSQL (JPA/Hibernate), MongoDB
- **Migrations**: Flyway 10
- **Mapping**: MapStruct 1.6.3
- **API Docs**: springdoc-openapi 2.6.0 (Swagger UI)
- **Metrics**: Micrometer + Prometheus
- **Build**: Maven

### Frontend
- **Framework**: React 18 + Vite
- **Language**: TypeScript
- **Styling**: CSS/Tailwind
- **State**: React Context

### Mobile
- **Framework**: Flutter 3.x
- **Language**: Dart

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

---

## 📝 License

This project is currently licensed as **Internal project**. A formal open-source license has not yet been selected.

---

## 🙏 Contributors

Maintained by the **Karuna Team**.

- Repository: [rushmanthnalluri/Karuna_Full_Project](https://github.com/rushmanthnalluri/Karuna_Full_Project)
- Issues: [GitHub Issues](https://github.com/rushmanthnalluri/Karuna_Full_Project/issues)

---

## 🗺️ Roadmap

- **v0.4** ✅ Core backend complete (Milestones 1–4)
- **v0.5** 🔄 AI Integration Platform (Milestone 5) — See [docs/milestone-5-plan.md](springboot/docs/milestone-5-plan.md)
  - Phase 1: AI Foundation (Gemini/Claude providers, prompt framework)
  - Phase 2: AI Features (rescue triage, animal prediction, Sita chatbot)
  - Phase 3: Integrations (file upload, WebSocket, email, background jobs)
  - Phase 4: Production (Docker, K8s, monitoring, CI/CD)
