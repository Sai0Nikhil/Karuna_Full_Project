import os
import joblib
import numpy as np
import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder

def train_diagnosis_model():
    print("\n-----------------------------------------")
    print("Training Animal Disease Diagnosis Model...")
    print("-----------------------------------------")
    
    file_path = "datasets/archive (7)/cleaned_animal_disease_prediction.csv"
    if not os.path.exists(file_path):
        print(f"Error: Dataset not found at {file_path}")
        return
        
    df = pd.read_csv(file_path)
    
    # Safely convert columns containing string units/dirty text to numeric
    for col in ['Body_Temperature', 'Heart_Rate', 'Weight', 'Age']:
        df[col] = pd.to_numeric(df[col].astype(str).str.replace(r'[^\d.]', '', regex=True), errors='coerce')
    
    # Fill missing values
    df['Gender'] = df['Gender'].fillna('Unknown')
    df['Breed'] = df['Breed'].fillna('Unknown')
    df['Symptom_1'] = df['Symptom_1'].fillna('None')
    df['Symptom_2'] = df['Symptom_2'].fillna('None')
    df['Symptom_3'] = df['Symptom_3'].fillna('None')
    df['Symptom_4'] = df['Symptom_4'].fillna('None')
    
    df['Weight'] = df['Weight'].fillna(df['Weight'].median() if not pd.isna(df['Weight'].median()) else 10.0)
    df['Body_Temperature'] = df['Body_Temperature'].fillna(df['Body_Temperature'].median() if not pd.isna(df['Body_Temperature'].median()) else 38.5)
    df['Heart_Rate'] = df['Heart_Rate'].fillna(df['Heart_Rate'].median() if not pd.isna(df['Heart_Rate'].median()) else 100.0)
    df['Age'] = df['Age'].fillna(df['Age'].median() if not pd.isna(df['Age'].median()) else 3.0)
    
    # Feature columns - now including the categorical symptoms and Breed
    cat_cols = ['Animal_Type', 'Breed', 'Gender', 'Symptom_1', 'Symptom_2', 'Symptom_3', 'Symptom_4']
    num_cols = ['Age', 'Weight', 'Body_Temperature', 'Heart_Rate']
    binary_cols = ['Appetite_Loss', 'Vomiting', 'Diarrhea', 'Coughing', 
                   'Labored_Breathing', 'Lameness', 'Skin_Lesions', 
                   'Nasal_Discharge', 'Eye_Discharge']
    
    # Convert binary columns to numeric
    for col in binary_cols:
        df[col] = df[col].map({'Yes': 1, 'No': 0, 1: 1, 0: 0}).fillna(0)
    
    X = df[cat_cols + num_cols + binary_cols]
    y = df['Disease_Prediction']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    preprocessor = ColumnTransformer(
        transformers=[
            ('cat', OneHotEncoder(handle_unknown='ignore'), cat_cols),
            ('num', 'passthrough', num_cols + binary_cols)
        ])
        
    pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('classifier', RandomForestClassifier(n_estimators=150, max_depth=12, random_state=42))
    ])
    
    pipeline.fit(X_train, y_train)
    acc = pipeline.score(X_test, y_test)
    print(f"Random Forest Diagnosis Model Accuracy: {acc*100:.2f}%")
    
    # Save model weights
    joblib.dump(pipeline, "backend/ai-service/diagnosis_model.joblib")
    print("Saved diagnosis_model.joblib successfully!")

def train_symptom_nlp_model():
    print("\n-----------------------------------------")
    print("Training Pet Symptom NLP Classifier...")
    print("-----------------------------------------")
    
    file_path = "datasets/archive (6)/pet-health-symptoms-dataset.csv"
    if not os.path.exists(file_path):
        print(f"Error: Dataset not found at {file_path}")
        return
        
    df = pd.read_csv(file_path)
    
    X = df['text'].astype(str)
    y = df['condition']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    # Increase TF-IDF max_features and tune Random Forest to improve accuracy
    pipeline = Pipeline(steps=[
        ('vectorizer', TfidfVectorizer(max_features=500, stop_words='english', ngram_range=(1,2))),
        ('classifier', RandomForestClassifier(n_estimators=200, min_samples_split=5, random_state=42))
    ])
    
    pipeline.fit(X_train, y_train)
    acc = pipeline.score(X_test, y_test)
    print(f"NLP Symptom Classifier Accuracy: {acc*100:.2f}%")
    
    # Save model weights
    joblib.dump(pipeline, "backend/ai-service/symptom_nlp_model.joblib")
    print("Saved symptom_nlp_model.joblib successfully!")

if __name__ == '__main__':
    train_diagnosis_model()
    train_symptom_nlp_model()
