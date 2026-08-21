# Karuṇā AI Triage — Veterinary & Rescue Datasets Directory

This document provides a compiled, curated directory of open datasets across Hugging Face, Kaggle, Open Data Portals, and Zenodo. These datasets contain real-world electronic health records, shelter intake logs, clinical images, and symptoms classifications that can be used to train, benchmark, and evaluate the **Karuṇā** AI Triage models.

---

## 📋 Primary Triage & Text Classification Datasets

### 1. SAVSNET PetEVAL (Hugging Face)
* **Dataset Link:** [SAVSNET/PetEVAL on Hugging Face](https://huggingface.co/datasets/SAVSNET/PetEVAL)
* **Host Organization:** [Small Animal Veterinary Surveillance Network (SAVSNET)](https://huggingface.co/SAVSNET)
* **Data Type:** Free-text Clinical Notes (NLP)
* **Description:** Consists of **17,600 professionally annotated real-world free-text electronic health records (EHRs)** from UK first-opinion veterinary clinics. It includes over 20,000 ICD-11 syndromic chapter labels, Named Entity Recognition (NER) tags for diseases/symptoms, and demographic metadata (species, breed, age, weight).
* **Why Use It:**
  * Ideal for training clinical NLP models to understand unstructured veterinarian consultation notes.
  * Standardizes raw field observations into formal medical categories.

### 2. PetFinder.my Adoption Prediction (Kaggle)
* **Dataset Link:** [PetFinder.my Adoption Prediction on Kaggle](https://www.kaggle.com/c/petfinder-adoption-prediction)
* **Data Type:** Tabular + Free-text Rescuer Narratives + Photos (Multimodal)
* **Description:** Contains details on tens of thousands of rescue animals in Malaysia, including rescuer-written incident narratives, physical traits (species, breed, age, color), health states (`1 = Healthy`, `2 = Minor Injury`, `3 = Serious Injury`, `0 = Not Specified`), and vaccination records.
* **Why Use It:**
  * Matches your current classifier's data schema perfectly (`species`, `description`, `severity`).
  * Direct ground-truth supervision for severity mapping.
  * Can expand the triage model to process both photos and text descriptions concurrently.

### 3. Pet Health Symptoms Dataset (Hugging Face)
* **Dataset Link:** [karenwky/pet-health-symptoms-dataset on Hugging Face](https://huggingface.co/datasets/karenwky/pet-health-symptoms-dataset)
* **Data Type:** Layman Observation Text vs. Clinical Notes
* **Description:** Contains 2,000 text samples mapped across common veterinary symptom domains (*Skin Irritations*, *Digestive Issues*, *Parasites*, *Ear Infections*, *Mobility Problems*). It explicitly tags the narrator's tone as `Owner Observation` (layman terminology) or `Clinical Notes` (veterinary terminology).
* **Why Use It:**
  * Vital for public-facing reporting portals.
  * Helps SITA (your AI voice assistant) bridge the gap between how owners informally describe emergency symptoms and formal clinical classifications.

---

## 🏥 Shelter Intake & Outcome Registries

### 4. Austin Animal Center Intakes and Outcomes
* **Dataset Links:**
  * [AAC Intakes - Austin Open Data Portal](https://data.austintexas.gov/Health-and-Community-Services/Austin-Animal-Center-Intakes/wter-evkm)
  * [AAC Outcomes - Austin Open Data Portal](https://data.austintexas.gov/Health-and-Community-Services/Austin-Animal-Center-Outcomes/9t4d-g238)
  * [AAC Shelter Dataset Mirror on Kaggle](https://www.kaggle.com/datasets/aaronschlegel/austin-animal-center-shelter-intakes-and-outcomes)
* **Data Type:** Tabular Intake Registers
* **Description:** Holds over 150,000 companion animal records from the largest municipal no-kill shelter in the US. Features critical columns: `Intake Condition` (`Injured`, `Sick`, `Normal`, `Aged`, `Nursing`, `Medical`, `Feral`, `Pregnant`), `Intake Type` (`Stray`, `Owner Surrender`, `Public Assist`), and corresponding outcome fields (`Adoption`, `Transfer`, `Euthanasia`, `Died`).
* **Why Use It:**
  * Connects the initial triage health grade of a stray directly to final survival/mortality outcomes.
  * Helps predict recovery timelines, length of stay, and medical urgency.

### 5. Sonoma County Animal Shelter Intakes & Outcomes
* **Dataset Links:**
  * [Sonoma County Open Data Portal](https://data.sonomacounty.ca.gov/Government/Animal-Shelter-Intake-and-Outcome/924b-igh5)
  * [Sonoma County Dataset Mirror on Kaggle](https://www.kaggle.com/datasets/thedevastator/sonoma-county-animal-shelter-intake-and-outcome)
* **Data Type:** Tabular County Database
* **Description:** Contains municipal shelter records utilizing standard Asilomar/Maddie's Fund health triage categories (`Healthy`, `Treatable-Manageable`, `Treatable-Rehabilitable`, `Untreatable-Severe`).
* **Why Use It:**
  * Perfect for out-of-distribution validation to ensure your triage classifier works reliably on data from other counties or shelters.

---

## 🔬 Clinical, Diagnostic & Specialized Datasets

### 6. Canine Multidimensional Pain & Emergency Database (Zenodo)
* **Dataset Link:** [Zenodo Record #15303646](https://zenodo.org/records/15303646)
* **Data Type:** Clinical Pain Metric Tables
* **Description:** Evaluates pain levels and trauma classifications in emergency admissions, recording Visual Analogue Scales (VAS) and Glasgow Composite Measure Pain Scales (GCPS) alongside age, breed, and primary veterinary diagnosis.
* **Why Use It:**
  * Helps build algorithmic pain-scoring models to automatically rank incoming rescue cases by acute pain severity.

### 7. VetXRay Radiograph Database (Zenodo)
* **Dataset Link:** [Zenodo Record #19051776](https://zenodo.org/records/19051776)
* **Data Type:** Annotated Clinical X-Ray Images
* **Description:** Includes 9,882 thoracic radiographs from cats and dogs annotated by board-certified radiologists across 17 pathological categories (e.g. pneumothorax, diaphragmatic hernia, fractures).
* **Why Use It:**
  * Essential if your roadmap expands to medical diagnostic imaging triage for NGO veterinary clinics.

### 8. Pet Disease Image Database (Kaggle)
* **Dataset Link:** [Pet Disease Images on Kaggle](https://www.kaggle.com/datasets/kshitij192/pet-disease-images)
* **Data Type:** Classified Injury/Disease Images
* **Description:** Over 5,000 categorized clinical images spanning 27 ocular lesions, external trauma wounds, skin conditions (mange, ringworm), and external parasites.
* **Why Use It:**
  * Can be used to train YOLOv8 or classification models to detect visible wounds and skin conditions from rescuer photos.

---

## 🌐 Dynamic Conversational & Epidemiological Data

### 9. Veterinary-Med Q&A Dataset (Hugging Face)
* **Dataset Link:** [viggovet/Veterinary-Med on Hugging Face](https://huggingface.co/datasets/viggovet/Veterinary-Med)
* **Data Type:** Conversational Q&A (NLP)
* **Description:** A large dialogue dataset covering 58 clinical categories and 911 veterinary domains designed to train conversational AI agents.
* **Why Use It:**
  * Highly useful for teaching SITA how to interact with callers, ask clarifying follow-up symptom questions, and provide immediate stabilization guidelines.

### 10. RVC VetCompass (Royal Veterinary College)
* **Dataset Link:** [VetCompass Research Data](https://www.rvc.ac.uk/vetcompass)
* **Data Type:** Epidemiological Research Tables
* **Description:** Tracks disorders, breed-specific emergency risks, and mortality statistics across millions of companion animals.
* **Why Use It:**
  * Helps calibrate baseline risk percentages (e.g., categorizing large-breed stray breathing issues as higher risk for Gastric Torsion/GDV).
