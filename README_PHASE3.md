# 🐾 Karuṇā — Phase 3: YOLOv8 Python AI Service

This file documents the design and integration of the custom, self-hosted AI triage pipeline, replacing external paid model stubs.

---

## 🤖 AI Stack Architecture

We developed a dedicated **Python microservice** (`ai-service/`) using **FastAPI** to run heavy machine learning workloads locally. This service is fully decoupled from the Spring Boot API, scaling independently.

```
                  ┌──────────────┐
                  │ Flutter App  │
                  └──────┬───────┘
                         │
                         │ POST /api/ai/analyze-photo (base64)
                         ▼
             ┌─────────────────────────┐
             │   Spring Boot Backend   │
             │       (Port 8081)       │
             └───────────┬─────────────┘
                         │
                         │ Decodes base64 & wraps as multipart
                         │ POST /predict
                         ▼
             ┌─────────────────────────┐
             │    FastAPI AI Service   │
             │       (Port 8000)       │
             ├─────────────────────────┤
             │  🔍 YOLOv8 Detector     │  ← Identifies species
             │  📊 Gradient Boost ML   │  ← Triage severity
             │  📋 Rule-based FirstAid │  ← Steps generator
             └─────────────────────────┘
```

---

## 📁 AI Service Structure

All Python-related assets live under `ai-service/`:
- `main.py` — FastAPI application routing (`/predict`, `/health`).
- `triage_model.py` — Trains and loads a scikit-learn `GradientBoostingClassifier` on startup using historical case schemas.
- `requirements.txt` — PyPI package requirements (fastapi, uvicorn, ultralytics, scikit-learn, pillow).
- `Dockerfile` — Custom container definition pre-packaged with mesa GL libraries required by OpenCV.

---

## ⚙️ Core AI Components

### 1. YOLOv8 Species Detection
Uses the official Ultralytics YOLOv8 nano model (`yolov8n.pt`). Since nano is optimized for speed, it runs efficiently on standard CPUs without GPU acceleration.
- Detects animal classes (dog, cat, cow, bird) in real time.
- If the animal is successfully localized, its bounding box coordinates `[xmin, ymin, xmax, ymax]` are returned.

### 2. Dynamically Injected Injury Bounding Boxes
Since injury datasets vary, the FastAPI service applies keyword NLP to the case description. It then overlays a **custom injury bounding box** relative to the animal's bounding box coordinates:
- Limping / Fractures → Placed at the bottom 30% of the animal box (legs).
- Eye / Head injuries → Placed at the top 30% of the animal box.
- Wounds / Bleeding → Placed on the center torso of the animal box.

### 3. Gradient Boost Triage Engine
Fits a `GradientBoostingClassifier` on synthetic case rows during server boot. It extracts:
- One-hot encoded species name.
- One-hot encoded injury category.
- TF-IDF word vectors from the citizen's description.
It yields a severity score (`critical`, `urgent`, or `routine`) and model classification confidence.

---

## 🔌 Integration Details

### Spring Boot Integration
When the citizen submits a photo for AI analysis:
1. `AIService.java` intercept `analyzePhoto(base64DataUrl, ...)`
2. It strips the data URL prefix and decodes the base64 payload into a raw `byte[]` array.
3. It packages the raw bytes into a `ByteArrayResource` and sets `multipart/form-data` content headers.
4. Using Spring's `RestTemplate`, it POSTs the image to `http://localhost:8000/predict`.
5. If the Python container is offline, the Java service handles the exception and falls back to a local rule-based keyword triage to guarantee service availability.

---

## 🐳 Docker Compose Deployment

We created a `docker-compose.yml` file at the repository root to start all services, database schemas, and volume mounts:

```bash
docker-compose up --build
```

This starts:
1. **PostgreSQL** (`port 5432`)
2. **MongoDB** (`port 27017`)
3. **FastAPI AI Service** (`port 8000`)
4. **Spring Boot Backend** (`port 8081`)

---

## 🎯 Verification Matrix

Verify the endpoints:
- Check AI Service health: `GET http://localhost:8000/health`
- Test YOLOv8 analysis:
  ```bash
  curl -X POST "http://localhost:8000/predict" \
       -F "file=@dog_photo.jpg" \
       -F "description=Dog is bleeding from leg"
  ```
