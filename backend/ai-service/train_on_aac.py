import os
import pandas as pd
import numpy as np
import joblib
from sklearn.ensemble import GradientBoostingClassifier
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.pipeline import Pipeline
from sklearn.compose import ColumnTransformer
from sklearn.preprocessing import OneHotEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report

def train_model():
    dataset_path = 'datasets/archive (2)/aac_intakes_outcomes.csv'
    model_path = 'backend/ai-service/triage_model.joblib'
    
    if not os.path.exists(dataset_path):
        print(f"Error: Dataset not found at {dataset_path}")
        return
        
    print("Loading Austin Animal Center dataset...")
    # Load columns to optimize memory usage
    cols = ['animal_type', 'intake_condition', 'breed', 'color', 'found_location', 'outcome_type', 'time_in_shelter_days']
    df = pd.read_csv(dataset_path, usecols=cols)
    print(f"Loaded {len(df)} records.")
    
    # 1. Map species
    df['species'] = df['animal_type'].str.lower()
    df.loc[~df['species'].isin(['dog', 'cat', 'bird']), 'species'] = 'other'
    
    # 2. Map simplified injury tags
    df['injury'] = 'other'
    df.loc[df['intake_condition'] == 'Injured', 'injury'] = 'wound'
    df.loc[df['intake_condition'] == 'Sick', 'injury'] = 'emaciation'
    
    # 3. Define target severity
    # Critical: Sick/Injured and died or euthanized in shelter
    # Urgent: Sick/Injured but was successfully adopted/transferred/returned
    # Routine: Normal, Aged, Nursing, etc.
    conditions = [
        (df['intake_condition'].isin(['Injured', 'Sick'])) & (df['outcome_type'].isin(['Died', 'Euthanasia'])),
        (df['intake_condition'].isin(['Injured', 'Sick'])) & (~df['outcome_type'].isin(['Died', 'Euthanasia'])),
    ]
    choices = ['critical', 'urgent']
    df['severity'] = np.select(conditions, choices, default='routine')
    
    # 4. Generate Natural Language Description to train TF-IDF
    print("Generating natural language descriptions...")
    def build_desc(row):
        color = str(row['color']).lower() if pd.notna(row['color']) else 'unknown color'
        breed = str(row['breed']).lower() if pd.notna(row['breed']) else 'unknown breed'
        species = str(row['species'])
        loc = str(row['found_location']).strip() if pd.notna(row['found_location']) else 'unknown location'
        cond = str(row['intake_condition']).lower()
        
        # Add variation to syntax to train robust sentence recognition
        return f"A stray {color} {breed} {species} was rescued from {loc} in {cond} condition."
        
    df['desc'] = df.apply(build_desc, axis=1)
    
    n_routine = min(len(df[df['severity'] == 'routine']), 8000)
    n_urgent = min(len(df[df['severity'] == 'urgent']), 8000)
    
    df_routine = df[df['severity'] == 'routine'].sample(n=n_routine, random_state=42) if n_routine > 0 else df[df['severity'] == 'routine']
    df_urgent = df[df['severity'] == 'urgent'].sample(n=n_urgent, random_state=42) if n_urgent > 0 else df[df['severity'] == 'urgent']
    df_critical = df[df['severity'] == 'critical']
    
    df_balanced = pd.concat([df_routine, df_urgent, df_critical]).sample(frac=1, random_state=42)
    print(f"Balanced training set size: {len(df_balanced)} records.")
    print(df_balanced['severity'].value_counts())
    
    # 5. Build ML Pipeline
    preprocessor = ColumnTransformer(
        transformers=[
            ('cat', OneHotEncoder(handle_unknown='ignore'), ['species', 'injury']),
            ('text', TfidfVectorizer(max_features=100, stop_words='english'), 'desc')
        ])
        
    pipeline = Pipeline(steps=[
        ('preprocessor', preprocessor),
        ('classifier', GradientBoostingClassifier(n_estimators=100, learning_rate=0.1, max_depth=5, random_state=42))
    ])
    
    X = df_balanced[['species', 'injury', 'desc']]
    y = df_balanced['severity']
    
    X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
    
    print("Training Gradient Boosting Classifier...")
    pipeline.fit(X_train, y_train)
    
    # 6. Evaluate Model
    y_pred = pipeline.predict(X_test)
    print("\nModel Evaluation Metrics:")
    print(classification_report(y_test, y_pred))
    
    # 7. Save Pipeline
    print(f"Saving retrained model to {model_path}...")
    joblib.dump(pipeline, model_path)
    print("Model saved successfully!")

if __name__ == '__main__':
    train_model()
