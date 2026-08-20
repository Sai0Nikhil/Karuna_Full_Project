import os
import joblib
import numpy as np
import pandas as pd
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder

# Global model pipeline
model_pipeline = None
MODEL_PATH = "triage_model.joblib"

# Base synthetic dataset to maintain baseline knowledge during retraining
BASE_SYNTHETIC_DATA = [
    # Critical cases
    {"species": "dog", "injury": "bleeding", "desc": "heavy bleeding from leg accident car hit", "severity": "critical"},
    {"species": "cow", "injury": "fracture", "desc": "broken leg lying on road unable to move", "severity": "critical"},
    {"species": "dog", "injury": "wound", "desc": "unconscious animal bleeding heavily neck wound", "severity": "critical"},
    {"species": "cat", "injury": "bleeding", "desc": "active bleeding head injury urgent", "severity": "critical"},
    {"species": "cow", "injury": "bleeding", "desc": "deep stomach cut blood loss", "severity": "critical"},
    
    # Urgent cases
    {"species": "dog", "injury": "wound", "desc": "dog is limping with open wound on back paw", "severity": "urgent"},
    {"species": "cat", "injury": "wound", "desc": "stray cat has deep scratch on face", "severity": "urgent"},
    {"species": "dog", "injury": "emaciation", "desc": "extremely thin starving dog very weak", "severity": "urgent"},
    {"species": "cow", "injury": "wound", "desc": "maggot wound on ear needs dressing", "severity": "urgent"},
    {"species": "bird", "injury": "fracture", "desc": "pigeon with broken wing cannot fly", "severity": "urgent"},
    
    # Routine cases
    {"species": "dog", "injury": "skin_issue", "desc": "mange skin infection hair loss scratching", "severity": "routine"},
    {"species": "cat", "injury": "weakness", "desc": "small kitten looks weak and dehydrated", "severity": "routine"},
    {"species": "dog", "injury": "other", "desc": "minor limp but eating well", "severity": "routine"},
    {"species": "cow", "injury": "other", "desc": "grazing but has minor cut on tail", "severity": "routine"},
    {"species": "bird", "injury": "weakness", "desc": "dehydrated bird sitting on balcony", "severity": "routine"}
]

def init_triage_model():
    global model_pipeline
    
    if os.path.exists(MODEL_PATH):
        try:
            model_pipeline = joblib.load(MODEL_PATH)
            print("🐾 Loaded existing triage model from joblib file.")
            return
        except Exception as e:
            print(f"⚠️ Could not load model from file: {e}. Retraining a new model...")

    # Duplicate data to give model enough samples to fit
    data = BASE_SYNTHETIC_DATA * 15
    df = pd.DataFrame(data)
    
    train_and_save(df)
    print("🐾 Triage model initialized and saved to joblib successfully!")

def train_and_save(df):
    global model_pipeline
    
    preprocessor = ColumnTransformer(
        transformers=[
            ('cat', OneHotEncoder(handle_unknown='ignore'), ['species', 'injury']),
            ('text', TfidfVectorizer(max_features=50, stop_words='english'), 'desc')
        ])
        
    model_pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('classifier', GradientBoostingClassifier(n_estimators=50, random_state=42))
    ])
    
    X = df[['species', 'injury', 'desc']]
    y = df['severity']
    model_pipeline.fit(X, y)
    
    # Save the pipeline to disk
    joblib.dump(model_pipeline, MODEL_PATH)

def retrain_model(new_samples):
    """
    Retrains the model with a combination of base synthetic data and 
    user-submitted feedback data to avoid catastrophic forgetting.
    """
    # 1. Start with baseline synthetic data
    combined_data = BASE_SYNTHETIC_DATA * 15
    
    # 2. Append new user feedback samples
    formatted_new_samples = []
    for sample in new_samples:
        formatted_new_samples.append({
            "species": str(sample.get("species", "dog")).lower(),
            "injury": str(sample.get("injury", "injury")).lower(),
            "desc": str(sample.get("desc", "")).lower(),
            "severity": str(sample.get("severity", "routine")).lower()
        })
    
    # Weight new feedback samples higher (multiply by 5) so the model adapts faster
    combined_data.extend(formatted_new_samples * 5)
    
    df = pd.DataFrame(combined_data)
    train_and_save(df)
    print(f"🐾 Model successfully retrained on {len(df)} samples ({len(formatted_new_samples)} new logs).")
    return len(df)

def predict_triage(species: str, injury: str, description: str):
    global model_pipeline
    if model_pipeline is None:
        init_triage_model()
        
    df_pred = pd.DataFrame([{
        "species": species.lower(),
        "injury": injury.lower(),
        "desc": description.lower()
    }])
    
    severity = model_pipeline.predict(df_pred)[0]
    probs = model_pipeline.predict_proba(df_pred)[0]
    confidence = float(np.max(probs))
    
    return severity, confidence
