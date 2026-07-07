# Contributing to Karuṇā

Thank you for contributing to Karuṇā! To keep work organized, please follow these guidelines.

---

## 🛠️ Development Workflow

We use a standard Git branch workflow. Please do not commit directly to the main branch.

### 1. Branch Naming Convention
* **Features:** eature/your-feature-name (e.g., eature/ai-vision-triage)
* **Bug Fixes:** ugfix/issue-description (e.g., ugfix/auth-token-refresh)
* **Documentation:** docs/description (e.g., docs/contributing-guidelines)

### 2. Pull Request (PR) Rules
* Keep PRs small and focused on a single logical change.
* Ensure code compiles/builds successfully before opening a PR.
* Write a brief summary explaining what changed and how to test it.

---

## 🧑‍💻 Technical Guidelines by Role

### 🤖 Core AI Developer
* **Model Configurations:**
  * Define prompt templates in GeminiService.java.
  * Ensure the system prompts are robust and output strict JSON when parsing is required.
  * Test changes using local mock data where possible to minimize API usage costs.
* **Testing:**
  * When modifying prompt structures, verify the JSON parser logic does not break.

### 🎨 Frontend Developer
* **Web UI (React):**
  * Follow Vite + React project structures.
  * Use local storage to persist user sessions (localStorage.setItem('user', ...)).
* **Mobile UI (Flutter):**
  * Use **Provider** for state management (ChangeNotifierProvider).
  * Run UI layouts through the layout inspector to prevent overflow pixels.

### ⚙️ Backend/Fullstack Developer
* **Database migrations:**
  * When modifying JPA entities, write the corresponding SQL in karuna-backend/schema.sql (and add seed data in seed.sql if required).
  * Enable SQL logging locally by keeping spring.jpa.show-sql=true in pplication.properties.

---

## 🔒 Security Best Practices
* **Secrets Management:**
  * Never hardcode API keys or passwords.
  * Ensure the root .gitignore blocks your local .env and pplication.properties changes.
  * Use environment variable overrides (SPRING_DATASOURCE_PASSWORD, GEMINI_API_KEY) when deploying.

---

## 💬 Communication
* Log your completed and pending work in [temp_work.md](file:///c:/Karuna_GAS/temp_work.md).
* Sync with the team regularly to coordinate integration points (especially when backend API contracts or DTOs change).
