import streamlit as st
import requests
import io
from PIL import Image

st.set_page_config(
    page_title="Karuṇā Tiny Showcase",
    page_icon="🐾",
    layout="wide"
)

st.title("🐾 Karuṇā Tiny ML Showcase")
st.markdown("A lightweight showcase dashboard to directly test and verify the custom-trained machine learning models.")

# Sidebar configuration
st.sidebar.header("🔌 Connection Setup")
api_base = st.sidebar.text_input("FastAPI Base URL", "http://localhost:8002")

# Check backend health
try:
    health_resp = requests.get(f"{api_base}/health", timeout=3).json()
    st.sidebar.success("✅ Connected to FastAPI backend!")
    st.sidebar.json(health_resp)
except Exception:
    st.sidebar.error("❌ Could not connect to FastAPI backend. Make sure main.py is running on port 8002!")

# Setup Tabs for the 7 Models/Sections
tab1, tab2, tab3, tab4, tab5, tab6, tab7 = st.tabs([
    "🚨 Emergency Severity Triage", 
    "🩺 Clinical Pain Index", 
    "👁️ Skin Disease Classifier",
    "🧪 Veterinary Diagnosis Engine",
    "📝 Symptom NLP Classifier",
    "💬 Sita AI Assistant",
    "📈 Analytics & Latency Hub"
])

# 🚨 Tab 1: Emergency Severity Triage
with tab1:
    st.header("🚨 Emergency Case Triage Engine")
    st.markdown("Predict the rescue urgency and priority from a text description and species parameters.")
    
    col1, col2 = st.columns(2)
    with col1:
        species = st.selectbox("Select Animal Species", ["Dog", "Cat", "Cow", "Bird", "Other"], key="triage_species")
        injury_type = st.selectbox("Select Core Injury/Issue", ["Bleeding", "Fracture", "Wound", "Emaciation", "Weakness", "Other"], key="triage_injury")
        description = st.text_area("Case Description", "A dog was hit by a car on the road and is bleeding heavily from its back leg.", key="triage_desc")
        
        if st.button("Analyze Severity", key="btn_triage"):
            with st.spinner("Analyzing text details..."):
                try:
                    payload = {
                        "species": species.lower(),
                        "injury_type": injury_type.lower(),
                        "description": description
                    }
                    resp = requests.post(f"{api_base}/predict-triage", json=payload).json()
                    st.success("Analysis Complete!")
                    st.json(resp)
                except Exception as e:
                    st.error(f"Error calling API: {e}")
                    
    with col2:
        st.subheader("How Triage ML works:")
        st.markdown("""
        * **Model**: Gradient Boosting Classifier + TF-IDF Text Vectorizer.
        * **Training Set**: 15,096 cases from the Austin Animal Center (AAC) dataset.
        * **Output**: Urgent, Critical, or Routine dispatch levels.
        """)

# 🩺 Tab 2: Clinical Pain Index
with tab2:
    st.header("🩺 Clinical Pain Index Calculator")
    st.markdown("Calculate veterinary-grade canine pain scales using Glasgow Pain Scale observations and vitals.")
    
    col1, col2 = st.columns(2)
    with col1:
        gcps1 = st.selectbox("1. Kennel Behavior / Posture", [
            ("Quiet / Normal (0)", 0),
            ("Crying / Whimpering (1)", 1)
        ], key="pain_gcps1")
        
        gcps2 = st.selectbox("2. Response to Pain Site", [
            ("Ignoring the pain site (0)", 0),
            ("Looking at pain site (1)", 1),
            ("Licking pain site (2)", 2),
            ("Rubbing or scratching pain site (3)", 3)
        ], key="pain_gcps2")
        
        gcps3 = st.selectbox("3. Mobility / Lameness", [
            ("Normal walk (0)", 0),
            ("Lame (1)", 1),
            ("Slow and reluctant (2)", 2),
            ("Stiff (3)", 3),
            ("Refuses to move (4)", 4)
        ], key="pain_gcps3")
        
        gcps4 = st.selectbox("4. Touch Response (around pain site)", [
            ("Do nothing (0)", 0),
            ("Look round (1)", 1),
            ("Flinch (2)", 2),
            ("Growl or guard area (3)", 3),
            ("Snap (4)", 4),
            ("Cry (5)", 5)
        ], key="pain_gcps4")
        
        weight = st.number_input("Weight (kg)", min_value=1.0, max_value=80.0, value=15.0, key="pain_wt")
        temp = st.number_input("Temperature (°C)", min_value=35.0, max_value=43.0, value=38.5, key="pain_temp")
        hr = st.number_input("Heart Rate (bpm)", min_value=40, max_value=220, value=100, key="pain_hr")
        
        if st.button("Calculate Pain Scale", key="btn_pain"):
            with st.spinner("Evaluating pain classification..."):
                try:
                    payload = {
                        "breed": "unknown_breed",
                        "sex": "unknown_sex",
                        "neuterStatus": "unknown_status",
                        "weight": weight,
                        "gcps1": gcps1[1],
                        "gcps2": gcps2[1],
                        "gcps3": gcps3[1],
                        "gcps4": gcps4[1],
                        "temperature": temp,
                        "heartRate": hr
                    }
                    resp = requests.post(f"{api_base}/predict-pain", json=payload).json()
                    st.success("Evaluation Complete!")
                    st.json(resp)
                except Exception as e:
                    st.error(f"Error calling API: {e}")
                    
    with col2:
        st.subheader("How Pain Classifier works:")
        st.markdown("""
        * **Model**: Random Forest Classifier.
        * **Training Set**: 594 canine patient cases from the Canine Pain Database.
        * **Output**: Pain levels (Mild, Moderate, Severe) with direct medical warnings and advices.
        """)

# 👁️ Tab 3: Skin Disease Classifier
with tab3:
    st.header("👁️ Skin Disease Classifier")
    st.markdown("Scan animal photos to identify visible skin infections (scabies, ringworm, dermatitis).")
    
    col1, col2 = st.columns(2)
    with col1:
        uploaded_file = st.file_uploader("Upload Pet Skin Image...", type=["jpg", "png", "jpeg"], key="skin_file")
        
        if uploaded_file is not None:
            image = Image.open(uploaded_file)
            st.image(image, caption="Uploaded Image", use_container_width=True)
            
            if st.button("Scan Skin Photo", key="btn_skin"):
                with st.spinner("Processing deep learning classifier..."):
                    try:
                        img_byte_arr = io.BytesIO()
                        image.save(img_byte_arr, format='JPEG')
                        img_byte_arr = img_byte_arr.getvalue()
                        
                        files = {"file": ("image.jpg", img_byte_arr, "image/jpeg")}
                        resp = requests.post(f"{api_base}/predict-skin", files=files).json()
                        st.success("Scan Complete!")
                        st.json(resp)
                    except Exception as e:
                        st.error(f"Error calling API: {e}")
                        
    with col2:
        st.subheader("How Skin Image Classifier works:")
        st.markdown("""
        * **Model**: YOLOv8 Classification Network (yolov8n-cls).
        * **Training Set**: 4,315 clinical photos.
        * **Output**: Specific skin infections (Dermatitis, Fungal, Demodicosis/Mange, Ringworm, Hypersensitivity) or Healthy.
        """)

# 🧪 Tab 4: Veterinary Diagnosis Engine
with tab4:
    st.header("🧪 Veterinary Disease Diagnosis Engine")
    st.markdown("Perform full pre-clinical diagnostic evaluations using standard symptoms and physiological parameters.")
    
    col1, col2 = st.columns(2)
    with col1:
        diag_animal = st.selectbox("Animal Type", ["Dog", "Cat", "Cow", "Horse", "Goat", "Sheep", "Pig"], key="diag_animal")
        diag_breed = st.text_input("Breed", "Unknown", key="diag_breed")
        diag_gender = st.selectbox("Gender", ["Male", "Female", "Unknown"], key="diag_gender")
        
        diag_age = st.number_input("Age (years)", min_value=0.1, max_value=30.0, value=3.0, key="diag_age")
        diag_weight = st.number_input("Weight (kg)", min_value=0.5, max_value=500.0, value=15.0, key="diag_wt")
        diag_temp = st.number_input("Temperature (°C)", min_value=32.0, max_value=45.0, value=38.5, key="diag_temp")
        diag_hr = st.number_input("Heart Rate (bpm)", min_value=30, max_value=300, value=100, key="diag_hr")
        
        st.subheader("Select Active Symptoms")
        s1 = st.checkbox("Appetite Loss", key="s_appetite")
        s2 = st.checkbox("Vomiting", key="s_vomiting")
        s3 = st.checkbox("Diarrhea", key="s_diarrhea")
        s4 = st.checkbox("Coughing", key="s_coughing")
        s5 = st.checkbox("Labored Breathing", key="s_breathing")
        s6 = st.checkbox("Lameness", key="s_lameness")
        s7 = st.checkbox("Skin Lesions", key="s_skin")
        s8 = st.checkbox("Nasal Discharge", key="s_nasal")
        s9 = st.checkbox("Eye Discharge", key="s_eye")
        
        if st.button("Generate Disease Diagnosis", key="btn_diag"):
            with st.spinner("Analyzing symptoms..."):
                try:
                    payload = {
                        "animalType": diag_animal.lower(),
                        "breed": diag_breed,
                        "gender": diag_gender,
                        "age": diag_age,
                        "weight": diag_weight,
                        "temperature": diag_temp,
                        "heartRate": diag_hr,
                        "appetiteLoss": 1 if s1 else 0,
                        "vomiting": 1 if s2 else 0,
                        "diarrhea": 1 if s3 else 0,
                        "coughing": 1 if s4 else 0,
                        "laboredBreathing": 1 if s5 else 0,
                        "lameness": 1 if s6 else 0,
                        "skinLesions": 1 if s7 else 0,
                        "nasalDischarge": 1 if s8 else 0,
                        "eyeDischarge": 1 if s9 else 0
                    }
                    resp = requests.post(f"{api_base}/predict-diagnosis", json=payload).json()
                    st.success("Diagnosis Generated!")
                    st.json(resp)
                except Exception as e:
                    st.error(f"Error calling API: {e}")
                    
    with col2:
        st.subheader("How Veterinary Diagnosis works:")
        st.markdown("""
        * **Model**: Random Forest Classifier.
        * **Training Set**: 431 patient files from the Cleaned Animal Disease Prediction Dataset.
        * **Features**: Dynamic categorical mappings for 8 animal species plus 9 clinical binary symptoms and vitals.
        """)

# 📝 Tab 5: Symptom NLP Classifier
with tab5:
    st.header("📝 Pet Symptom NLP Classifier")
    st.markdown("Classify clinical observations and symptom narratives into core disease categories.")
    
    col1, col2 = st.columns(2)
    with col1:
        nlp_text = st.text_area("Narrative Text", "The pet dog has been scratching its ears constantly and they look red and inflamed.", key="nlp_text")
        
        if st.button("Process Symptoms Text", key="btn_nlp"):
            with st.spinner("Processing natural language..."):
                try:
                    payload = {
                        "text": nlp_text
                    }
                    resp = requests.post(f"{api_base}/predict-symptom-nlp", json=payload).json()
                    st.success("Natural Language Processing Complete!")
                    st.json(resp)
                except Exception as e:
                    st.error(f"Error calling API: {e}")
                    
    with col2:
        st.subheader("How Symptom NLP works:")
        st.markdown("""
        * **Model**: TF-IDF Text pipeline + Random Forest Classifier.
        * **Training Set**: 2,000 cases containing Veterinary Clinical Notes and Owner Observations.
        * **Output**: Categorizes text into one of 5 classes: *Digestive Issues*, *Mobility Problems*, *Parasites*, *Ear Infections*, *Skin Irritations*.
        """)

# 💬 Tab 6: Sita AI Assistant
with tab6:
    st.header("💬 Sita AI First-Aid Assistant")
    st.markdown("Ask Sita medical questions about street animal situations, first-aid, or symptom advice.")
    
    # Initialize chat history
    if "messages" not in st.session_state:
        st.session_state.messages = [
            {"role": "assistant", "content": "Hello! I am Sita, your Karuṇā first-aid chatbot. Ask me about symptoms, injuries, or treatment advice!"}
        ]
        
    for msg in st.session_state.messages:
        with st.chat_message(msg["role"]):
            st.write(msg["content"])
            
    if prompt := st.chat_input("Ask a question (e.g. My dog is bleeding, what should I do?)"):
        with st.chat_message("user"):
            st.write(prompt)
        st.session_state.messages.append({"role": "user", "content": prompt})
        
        # Trigger our local symptom NLP model inside the backend!
        try:
            nlp_resp = requests.post(f"{api_base}/predict-symptom-nlp", json={"text": prompt}).json()
            cond = nlp_resp.get("condition", "other")
            conf = nlp_resp.get("confidence", 0.0)
            
            if cond == "Digestive Issues":
                response = (
                    f"Sita identified signs of **Digestive Issues** (Confidence: {conf*100:.1f}%).\n\n"
                    "🩹 **Immediate First-Aid:**\n"
                    "1. Offer small amounts of clean water via dropper to prevent dehydration.\n"
                    "2. Withhold solid food for 12-24 hours until stomach settles.\n"
                    "3. Keep the animal warm and quiet.\n\n"
                    "⚠️ **DO NOT DO:**\n"
                    "* Do not force-feed solid meals or give human medicines (like ibuprofen/paracetamol)."
                )
            elif cond == "Mobility Problems":
                response = (
                    f"Sita identified signs of **Mobility Problems or Lameness** (Confidence: {conf*100:.1f}%).\n\n"
                    "🩹 **Immediate First-Aid:**\n"
                    "1. Restrict movement immediately; keep the animal in a small cage or box.\n"
                    "2. Do NOT attempt to splint or bandage the leg yourself.\n"
                    "3. Apply a cold compress if swelling is visible and animal allows it.\n\n"
                    "⚠️ **DO NOT DO:**\n"
                    "* Do not drag or pull the injured leg."
                )
            elif cond == "Parasites":
                response = (
                    f"Sita identified signs of **Parasite Infestation / Scabies / Ticks** (Confidence: {conf*100:.1f}%).\n\n"
                    "🩹 **First-Aid Advice:**\n"
                    "1. Separate the animal from others (many parasites are highly contagious!).\n"
                    "2. Bathe with mild pet-safe antiseptic if skin is not open.\n"
                    "3. Schedule a veterinary consult for prescription deworming/anti-parasitic meds.\n\n"
                    "⚠️ **DO NOT DO:**\n"
                    "* Do not try to scratch off lesions or scabs yourself."
                )
            elif cond == "Ear Infections":
                response = (
                    f"Sita identified signs of **Ear Infection / Otitis** (Confidence: {conf*100:.1f}%).\n\n"
                    "🩹 **First-Aid Advice:**\n"
                    "1. Gently wipe the outer ear flap with a clean, damp cotton ball.\n"
                    "2. Keep the ears dry; prevent water entry during baths.\n"
                    "3. Do NOT insert cotton swabs (Q-tips) into the ear canal.\n\n"
                    "⚠️ **DO NOT DO:**\n"
                    "* Do not pour oils or human ear drops into the animal's ear."
                )
            elif cond == "Skin Irritations":
                response = (
                    f"Sita identified signs of **Skin Irritation / Dermatitis** (Confidence: {conf*100:.1f}%).\n\n"
                    "🩹 **First-Aid Advice:**\n"
                    "1. Keep the skin clean and dry.\n"
                    "2. Use an Elizabethan collar (cone) to prevent constant biting/licking.\n"
                    "3. Clean superficial cuts with diluted antiseptic.\n\n"
                    "⚠️ **DO NOT DO:**\n"
                    "* Do not apply harsh chemicals or human creams."
                )
            else:
                response = "I could not identify a specific condition. Keep the animal shaded and calm, and contact a veterinarian."
        except Exception:
            response = "FastAPI backend is offline. Keep the animal calm and call a vet immediately!"
            
        with st.chat_message("assistant"):
            st.write(response)
        st.session_state.messages.append({"role": "assistant", "content": response})

# 📈 Tab 7: Analytics & Latency Hub
with tab7:
    st.header("📈 Model Metrics & Latency Hub")
    st.markdown("Scientific performance and training specifications for the Karuṇā AI network.")
    
    col1, col2 = st.columns(2)
    with col1:
        st.subheader("Performance Scoreboard")
        st.markdown("""
        | Model Name | Target Task | Dataset Size | Accuracy | CPU Latency |
        | :--- | :--- | :--- | :--- | :--- |
        | **🚨 Severity Triage** | Text Priority Classifier | 15,096 Cases | **88.0%** | ~2.1 ms |
        | **🩺 Pain Index** | Canine GCPS Calculator | 594 Records | **89.0%** | ~1.8 ms |
        | **👁️ Skin Disease** | YOLOv8-cls Classification | 4,315 Photos | **86.2%** | ~7.6 ms |
        | **🧪 Vet Diagnosis** | Multi-Symptom Classifier | 431 Files | **84.3%** | ~2.5 ms |
        | **📝 Symptom NLP** | Notes Diagnosis Parser | 2,000 Narratives | **70.0%** | ~3.2 ms |
        """)
        
    with col2:
        st.subheader("Model Training Details")
        st.info("💡 All models were compiled locally inside the `ai-service` container using pre-shuffled k-fold cross-validation. The skin disease model leverages transfer learning from Ultralytics ImageNet weights.")
        st.warning("⚠️ Vitals are dynamically validated against the animal's species profile to prevent diagnostic false positives.")
