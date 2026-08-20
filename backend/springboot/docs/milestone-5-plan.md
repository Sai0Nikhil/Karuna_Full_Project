# Milestone 5 — AI Integration Platform

## Overview

Milestone 5 introduces AI-powered features to the KARUNA platform. The focus is on building a provider-agnostic AI abstraction layer, implementing rescue triage and animal condition prediction, and delivering an AI chatbot interface called "Sita".

This document outlines the high-level roadmap, phases, deliverables, and success criteria. No implementation details are included here.

---

## Phase 1 — AI Foundation

### Objectives
Establish the core AI infrastructure required to integrate multiple LLM providers, manage prompts, validate responses, and handle errors gracefully.

### Expected Deliverables
- `AIProvider` interface with unified request/response contracts
- `GeminiProvider` implementation for Google Gemini
- `ClaudeProvider` implementation for Anthropic Claude
- Prompt template framework with versioning
- JSON schema validation for AI responses
- Retry and timeout policies
- Rate limiting and quota management
- Centralized AI configuration (`karuna.ai.*` properties)

### Dependencies
- Milestone 4 backend complete
- LLM API keys configured via environment variables
- JSON schema validation library (existing or new)

### Success Criteria
- Both Gemini and Claude providers can be swapped via configuration without code changes
- Prompt templates are versioned and reusable
- Failed AI calls retry with exponential backoff
- Invalid AI responses are rejected before reaching business logic
- AI configuration is externalized and profile-aware

---

## Phase 2 — AI Features

### Objectives
Implement domain-specific AI features that add tangible value to rescue operations, animal care, and adopter guidance.

### Expected Deliverables
- **Rescue Triage**: AI-assisted case prioritization based on description, location, and animal condition
- **Animal Condition Prediction**: Predictive model output for treatment urgency and likely outcomes
- **Rescue Priority Prediction**: Suggested priority level for newly reported cases
- **AI Chatbot ("Sita")**: Conversational assistant for citizens, NGOs, and volunteers
- **Conversation History**: Persistent chat logs tied to users and rescue cases

### Dependencies
- Phase 1 AI foundation complete
- MongoDB collections available for chat logs and prediction storage
- Frontend chat components ready for integration

### Success Criteria
- Triage predictions are returned within acceptable latency (p95 < 2s)
- Chatbot responses are context-aware and role-appropriate
- Conversation history survives application restarts
- AI-generated predictions are auditable via `AiPrediction` document schema

---

## Phase 3 — Integrations

### Objectives
Connect AI features to external systems and user-facing channels.

### Expected Deliverables
- File upload support for animal images
- Image processing pipeline for vision-based triage
- WebSocket notifications for real-time AI status updates
- Email notifications for critical predictions and chat summaries
- Background job processing for long-running AI tasks

### Dependencies
- Phase 2 AI features complete
- File storage solution (local or cloud)
- WebSocket infrastructure (existing)
- Email service configuration

### Success Criteria
- Images uploaded by users are processed and linked to cases
- Long-running AI tasks do not block HTTP requests
- Users receive real-time status updates via WebSocket
- Email notifications are sent for critical AI events

---

## Phase 4 — Production

### Objectives
Harden the platform for production deployment at scale.

### Expected Deliverables
- Docker containerization
- Kubernetes deployment manifests
- Monitoring and observability stack
- Metrics and health checks
- CI/CD pipeline
- Security hardening
- Performance tuning

### Dependencies
- Phases 1–3 complete
- Infrastructure team availability
- Cloud provider selection

### Success Criteria
- Application builds into a reproducible Docker image
- Kubernetes deployment passes liveness and readiness probes
- Prometheus metrics expose AI latency, error rates, and token usage
- CI/CD runs build, test, and security scans on every PR
- Security headers, CSP, and rate limiting are enforced
- p95 API latency remains under 500ms for non-AI endpoints

---

## Timeline

| Phase | Target | Priority |
|-------|--------|----------|
| Phase 1 — AI Foundation | Milestone 5.1 | High |
| Phase 2 — AI Features | Milestone 5.2 | High |
| Phase 3 — Integrations | Milestone 5.3 | Medium |
| Phase 4 — Production | Milestone 5.4 | Medium |

---

## Out of Scope for Milestone 5

- Mobile app AI features (Flutter)
- Advanced model fine-tuning
- Multi-modal inputs beyond image + text
- Real-time video analysis
- Edge deployment

---

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| LLM API rate limits | Implement caching, fallback providers, and exponential backoff |
| Prompt injection | JSON schema validation, input sanitization, and output filtering |
| Token cost overruns | Request compression, response truncation, and usage monitoring |
| Model latency | Async processing for non-critical tasks, streaming for chatbot |
