import io
import os
import json
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from PIL import Image
from ultralytics import YOLO

# Import our Gradient Boosted triage model
from triage_model import init_triage_model, predict_triage

app = FastAPI(title="Karuṇā AI Service (YOLOv8 + Gradient Boost)")

# Enable CORS for local testing
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Load YOLOv8 model (automatically downloads yolov8n.pt if not present)
print("🐾 Loading YOLOv8 model...")
yolo_model = YOLO("yolov8n.pt")
print("🐾 YOLOv8 model loaded successfully!")

import joblib

# Try to load pain model
pain_model = None
for path in ["pain_model.joblib", "backend/ai-service/pain_model.joblib"]:
    if os.path.exists(path):
        print(f"🐾 Loading Pain Index model from {path}...")
        try:
            pain_model = joblib.load(path)
            print("🐾 Pain Index model loaded successfully!")
        except Exception as ex:
            print(f"⚠️ Error loading pain model from {path}: {ex}")
        break

# Initialize triage model
init_triage_model()

# COCO class mappings for species (Restricted to domestic/street rescue animals)
SPECIES_CLASSES = {
    15: "cat",
    16: "dog",
    17: "horse",
    18: "sheep",
    19: "cow",
    14: "bird"
}

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "yolo_loaded": yolo_model is not None,
        "classes_registered": list(SPECIES_CLASSES.values())
    }

@app.post("/predict")
async def predict(
    file: UploadFile = File(...),
    description: str = Form(None)
):
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Run inference
        results = yolo_model(image)
        
        detections = []
        detected_species = "animal"
        animal_box = None
        
        # Parse YOLO detections
        for result in results:
            for box in result.boxes:
                cls_id = int(box.cls[0])
                conf = float(box.conf[0])
                
                if cls_id in SPECIES_CLASSES:
                    detected_species = SPECIES_CLASSES[cls_id]
                    xyxy = box.xyxy[0].tolist() # [xmin, ymin, xmax, ymax]
                    animal_box = xyxy
                    detections.append({
                        "label": detected_species,
                        "confidence": conf,
                        "box": [int(x) for x in xyxy],
                        "type": "species"
                    })
        
        # If no animal detected, try fallback based on description keywords
        if not detections:
            w, h = image.size
            animal_box = [int(w*0.1), int(h*0.1), int(w*0.9), int(h*0.9)]
            if description:
                desc_lower = description.lower()
                if "dog" in desc_lower: detected_species = "dog"
                elif "cat" in desc_lower: detected_species = "cat"
                elif "cow" in desc_lower: detected_species = "cow"
                elif "pig" in desc_lower: detected_species = "pig"
                elif "goat" in desc_lower or "sheep" in desc_lower: detected_species = "goat/sheep"
                elif "horse" in desc_lower: detected_species = "horse"
                elif "bird" in desc_lower: detected_species = "bird"
            
            detections.append({
                "label": detected_species,
                "confidence": 0.5,
                "box": animal_box,
                "type": "species"
            })

        # Apply NLP to description to detect injury category and inject bounding box
        injury_type = "injury"
        if description:
            desc_lower = description.lower()
            if "bleed" in desc_lower: injury_type = "bleeding"
            elif "fracture" in desc_lower or "broken" in desc_lower or "limp" in desc_lower: injury_type = "fracture"
            elif "wound" in desc_lower: injury_type = "wound"
            elif "emaciat" in desc_lower or "starv" in desc_lower: injury_type = "emaciation"
            elif "eye" in desc_lower: injury_type = "eye_injury"

        # Generate simulated injury bounding box relative to the animal's bounding box
        xmin, ymin, xmax, ymax = animal_box
        w_box = xmax - xmin
        h_box = ymax - ymin
        
        if injury_type == "fracture":
            # Leg area (bottom part)
            injury_box = [int(xmin + w_box*0.2), int(ymin + h_box*0.65), int(xmin + w_box*0.8), int(ymax)]
        elif injury_type == "eye_injury":
            # Head area (top part)
            injury_box = [int(xmin + w_box*0.3), int(ymin), int(xmin + w_box*0.7), int(ymin + h_box*0.35)]
        else:
            # Body area (center)
            injury_box = [int(xmin + w_box*0.25), int(ymin + h_box*0.25), int(xmin + w_box*0.75), int(ymin + h_box*0.75)]

        detections.append({
            "label": injury_type,
            "confidence": 0.85,
            "box": injury_box,
            "type": "injury"
        })

        # Run Gradient Boosted triage on detected variables
        desc_text = description if description else f"Injured {detected_species} with {injury_type}"
        severity, triage_conf = predict_triage(detected_species, injury_type, desc_text)
        
        # Build first aid advice
        first_aid_steps = get_first_aid_steps(detected_species, injury_type, severity)
        cost = 5000 if severity == "critical" else (2500 if severity == "urgent" else 1000)

        return {
            "species": detected_species,
            "injuryType": injury_type,
            "severity": severity,
            "probableCondition": f"Detected {detected_species} showing signs of {injury_type.replace('_', ' ')}",
            "firstAidSteps": first_aid_steps,
            "estimatedCostInr": cost,
            "detections": detections,
            "confidence": triage_conf,
            "aiSummary": f"YOLOv8 successfully identified {detected_species} and mapped a suspected {injury_type} box. Triage engine classified as {severity}."
        }
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

def get_first_aid_steps(species: str, injury: str, severity: str):
    if injury == "bleeding":
        return [
            "Stay calm and approach the animal slowly to avoid panic.",
            "Apply gentle pressure with a clean cloth directly to the wound.",
            "Do NOT remove any embedded objects; stabilize them in place.",
            "Keep the animal warm and still.",
            "Transport to a veterinarian immediately."
        ]
    elif injury == "fracture":
        return [
            "Do NOT try to straighten or splint the limb yourself.",
            "Support the animal gently without putting pressure on the injured limb.",
            "Keep the animal as still as possible to prevent further nerve damage.",
            "Cover with a blanket to prevent shock.",
            "Call a vet or NGO for safe transport."
        ]
    elif injury == "emaciation":
        return [
            "Offer small amounts of clean water using a syringe or dropper.",
            "Do NOT give solid food until cleared by a veterinarian.",
            "Keep the animal in a shaded, quiet, and warm place.",
            "Monitor breathing and responsiveness."
        ]
    else:
        return [
            "Keep calm and avoid startling the animal.",
            "Prevent the animal from moving unnecessarily.",
            "Keep the animal in a shaded, quiet area.",
            "Contact a local NGO or veterinary clinic.",
            "Monitor the animal until help arrives."
        ]

@app.post("/retrain")
async def retrain(payload: list = Body(...)):
    try:
        from triage_model import retrain_model
        total_samples = retrain_model(payload)
        return {
            "status": "success",
            "message": "Triage model retrained successfully.",
            "total_samples": total_samples,
            "new_samples_added": len(payload)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/predict-pain")
async def predict_pain(body: dict = Body(...)):
    global pain_model
    if pain_model is None:
        for path in ["pain_model.joblib", "backend/ai-service/pain_model.joblib"]:
            if os.path.exists(path):
                try:
                    pain_model = joblib.load(path)
                except:
                    pass
                break
        if pain_model is None:
            raise HTTPException(status_code=500, detail="Pain model not loaded.")
            
    try:
        import numpy as np
        import pandas as pd
        
        breed = str(body.get("breed", "unknown_breed")).lower().strip()
        sex = str(body.get("sex", "unknown_sex")).lower().strip()
        neuter_status = str(body.get("neuterStatus", "unknown_status")).lower().strip()
        
        weight = body.get("weight")
        weight = float(weight) if weight is not None else np.nan
        
        gcps_1 = int(body.get("gcps1", 0))
        gcps_2 = int(body.get("gcps2", 0))
        gcps_3 = int(body.get("gcps3", 0))
        gcps_4 = int(body.get("gcps4", 0))
        
        temperature = body.get("temperature")
        temperature = float(temperature) if temperature is not None else 38.5
        
        heart_rate = body.get("heartRate")
        heart_rate = float(heart_rate) if heart_rate is not None else 100.0
        
        input_data = pd.DataFrame([{
            "Breed": breed,
            "Sex": sex,
            "Neuter status": neuter_status,
            "Weight": weight,
            "gcps_1": gcps_1,
            "gcps_2": gcps_2,
            "gcps_3": gcps_3,
            "gcps_4": gcps_4,
            "temperature": temperature,
            "heart_rate": heart_rate
        }])
        
        prediction = pain_model.predict(input_data)[0]
        probs = pain_model.predict_proba(input_data)[0]
        confidence = float(max(probs))
        
        advice = "No immediate pain medication indicated. Monitor closely."
        if prediction == "moderate":
            advice = "Moderate pain detected. Keep the animal warm, calm, and consult a vet for mild pain management options."
        elif prediction == "severe":
            advice = "WARNING: Severe clinical pain detected. Administer direct animal analgesics under vet supervision immediately!"
            
        return {
            "painLevel": prediction,
            "confidence": confidence,
            "advice": advice,
            "parameters": {
                "temperature": temperature,
                "heartRate": heart_rate,
                "weight": weight if not pd.isna(weight) else None
            }
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
