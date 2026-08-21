import io
import os
import joblib
import pandas as pd
import numpy as np
from PIL import Image
from fastapi import FastAPI, UploadFile, File, Form, HTTPException, Body
from fastapi.middleware.cors import CORSMiddleware
from ultralytics import YOLO

app = FastAPI(title="Tiny Karuṇā ML Backend")

# Enable CORS for easy mobile/local connections
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Global variables for models
triage_model = None
pain_model = None
skin_model = None
diagnosis_model = None
symptom_nlp_model = None

# Model paths
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "models")

def load_models():
    global triage_model, pain_model, skin_model, diagnosis_model, symptom_nlp_model
    
    # Load Triage Model
    triage_path = os.path.join(MODELS_DIR, "triage_model.joblib")
    if os.path.exists(triage_path):
        try:
            triage_model = joblib.load(triage_path)
            print("🐾 Loaded Triage Model successfully!")
        except Exception as e:
            print(f"⚠️ Error loading triage model: {e}")
            
    # Load Pain Model
    pain_path = os.path.join(MODELS_DIR, "pain_model.joblib")
    if os.path.exists(pain_path):
        try:
            pain_model = joblib.load(pain_path)
            print("🐾 Loaded Pain Model successfully!")
        except Exception as e:
            print(f"⚠️ Error loading pain model: {e}")
            
    # Load Skin Disease Classifier (YOLOv8-cls)
    skin_path = os.path.join(MODELS_DIR, "skin_classifier.pt")
    if os.path.exists(skin_path):
        try:
            skin_model = YOLO(skin_path)
            print("🐾 Loaded YOLOv8 Skin Disease model successfully!")
        except Exception as e:
            print(f"⚠️ Error loading skin model: {e}")

    # Load Veterinary Diagnosis Model
    diag_path = os.path.join(MODELS_DIR, "diagnosis_model.joblib")
    if os.path.exists(diag_path):
        try:
            diagnosis_model = joblib.load(diag_path)
            print("🐾 Loaded Animal Diagnosis Model successfully!")
        except Exception as e:
            print(f"⚠️ Error loading diagnosis model: {e}")

    # Load Symptom NLP Model
    nlp_path = os.path.join(MODELS_DIR, "symptom_nlp_model.joblib")
    if os.path.exists(nlp_path):
        try:
            symptom_nlp_model = joblib.load(nlp_path)
            print("🐾 Loaded Pet Symptom NLP Model successfully!")
        except Exception as e:
            print(f"⚠️ Error loading symptom NLP model: {e}")

@app.on_event("startup")
def startup_event():
    load_models()

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "triage_model_loaded": triage_model is not None,
        "pain_model_loaded": pain_model is not None,
        "skin_model_loaded": skin_model is not None,
        "diagnosis_model_loaded": diagnosis_model is not None,
        "symptom_nlp_model_loaded": symptom_nlp_model is not None
    }

# 🚨 End Point 1: Emergency Triage Prediction (Text-based)
@app.post("/predict-triage")
def predict_triage(
    species: str = Body(..., embed=True),
    injury_type: str = Body(..., embed=True),
    description: str = Body(..., embed=True)
):
    global triage_model
    if triage_model is None:
        raise HTTPException(status_code=503, detail="Triage model is not loaded.")
        
    try:
        input_data = pd.DataFrame([{
            "species": str(species).lower().strip(),
            "injury": str(injury_type).lower().strip(),
            "desc": str(description).lower().strip()
        }])
        
        prediction = triage_model.predict(input_data)[0]
        probs = triage_model.predict_proba(input_data)[0]
        confidence = float(max(probs))
        
        cost = 5000 if prediction == "critical" else (2500 if prediction == "urgent" else 1000)
        
        return {
            "severity": prediction,
            "confidence": confidence,
            "estimatedCostInr": cost,
            "probableCondition": f"Injured {species} showing signs of {injury_type.replace('_', ' ')}"
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 🩺 End Point 2: Clinical Pain Index Calculator
@app.post("/predict-pain")
def predict_pain(body: dict = Body(...)):
    global pain_model
    if pain_model is None:
        raise HTTPException(status_code=503, detail="Pain model is not loaded.")
        
    try:
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
            advice = "Moderate pain detected. Keep the animal warm, calm, and consult a vet for pain management."
        elif prediction == "severe":
            advice = "WARNING: Severe clinical pain detected! Administer analgesics under vet supervision immediately."
            
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

# 👁️ End Point 3: Skin Disease Image Classifier
@app.post("/predict-skin")
async def predict_skin(file: UploadFile = File(...)):
    global skin_model
    if skin_model is None:
        raise HTTPException(status_code=503, detail="Skin classification model is not loaded.")
        
    try:
        contents = await file.read()
        image = Image.open(io.BytesIO(contents)).convert("RGB")
        
        # Run YOLOv8 classification inference
        results = skin_model(image)
        
        predicted_class = "unknown"
        confidence = 0.0
        
        for r in results:
            if r.probs is not None:
                top1_idx = int(r.probs.top1)
                confidence = float(r.probs.top1conf)
                predicted_class = r.names[top1_idx]
                break
                
        return {
            "skinClass": predicted_class,
            "confidence": confidence,
            "message": f"Identified skin condition: {predicted_class} with {confidence*100:.1f}% confidence."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 🩺 End Point 4: Veterinary Disease Diagnosis Classifier
@app.post("/predict-diagnosis")
def predict_diagnosis(body: dict = Body(...)):
    global diagnosis_model
    if diagnosis_model is None:
        raise HTTPException(status_code=503, detail="Diagnosis model is not loaded.")
        
    try:
        animal_type = str(body.get("animalType", "dog")).capitalize()
        breed = str(body.get("breed", "Unknown"))
        gender = str(body.get("gender", "Unknown"))
        
        age = float(body.get("age", 3.0))
        weight = float(body.get("weight", 10.0))
        body_temp = float(body.get("temperature", 38.5))
        heart_rate = float(body.get("heartRate", 100.0))
        
        symptom_1 = str(body.get("symptom1", "None"))
        symptom_2 = str(body.get("symptom2", "None"))
        symptom_3 = str(body.get("symptom3", "None"))
        symptom_4 = str(body.get("symptom4", "None"))
        
        appetite_loss = int(body.get("appetiteLoss", 0))
        vomiting = int(body.get("vomiting", 0))
        diarrhea = int(body.get("diarrhea", 0))
        coughing = int(body.get("coughing", 0))
        labored_breathing = int(body.get("laboredBreathing", 0))
        lameness = int(body.get("lameness", 0))
        skin_lesions = int(body.get("skinLesions", 0))
        nasal_discharge = int(body.get("nasalDischarge", 0))
        eye_discharge = int(body.get("eyeDischarge", 0))
        
        input_data = pd.DataFrame([{
            'Animal_Type': animal_type,
            'Breed': breed,
            'Gender': gender,
            'Age': age,
            'Weight': weight,
            'Body_Temperature': body_temp,
            'Heart_Rate': heart_rate,
            'Symptom_1': symptom_1,
            'Symptom_2': symptom_2,
            'Symptom_3': symptom_3,
            'Symptom_4': symptom_4,
            'Appetite_Loss': appetite_loss,
            'Vomiting': vomiting,
            'Diarrhea': diarrhea,
            'Coughing': coughing,
            'Labored_Breathing': labored_breathing,
            'Lameness': lameness,
            'Skin_Lesions': skin_lesions,
            'Nasal_Discharge': nasal_discharge,
            'Eye_Discharge': eye_discharge
        }])
        
        prediction = diagnosis_model.predict(input_data)[0]
        probs = diagnosis_model.predict_proba(input_data)[0]
        confidence = float(max(probs))
        
        return {
            "disease": prediction,
            "confidence": confidence,
            "recommendation": f"Consult a veterinarian. Suspected condition: {prediction}."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# 📝 End Point 5: Pet Symptom NLP Classifier
@app.post("/predict-symptom-nlp")
def predict_symptom_nlp(
    text: str = Body(..., embed=True)
):
    global symptom_nlp_model
    if symptom_nlp_model is None:
        raise HTTPException(status_code=503, detail="Symptom NLP model is not loaded.")
        
    try:
        input_data = pd.Series([str(text)])
        prediction = symptom_nlp_model.predict(input_data)[0]
        probs = symptom_nlp_model.predict_proba(input_data)[0]
        confidence = float(max(probs))
        
        return {
            "condition": prediction,
            "confidence": confidence,
            "summary": f"Text classified as {prediction} with {confidence*100:.1f}% confidence."
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8002, reload=True)
