# 🚀 Deploying Karuṇā Web Apps on Vercel

This guide explains how to deploy the three frontend applications (`Karuna-`, `karuna-citizen`, and `karuna-ngo`) to Vercel, pointing to the live backend: `https://karuna-backend-pa4r.onrender.com`.

---

## 🛠️ Step 1 — Push your code to GitHub

Vercel deploys directly from GitHub. If you haven't already, initialize a repository in the root (`C:\Karuna_GAS`) and push the entire workspace to your GitHub account.

```bash
cd C:\Karuna_GAS
git init
git add .
git commit -m "Configure production endpoints and Vercel builds"
# Create a repository on github.com, then:
git remote add origin https://github.com/YOUR_USERNAME/karuna-full-project.git
git push -u origin main
```

---

## 💻 Step 2 — Deploy the Web Apps

Go to [Vercel](https://vercel.com/) and click **"Add New"** → **"Project"** for each of the web applications.

### 1️⃣ Project 1: Karuṇā AI App (Folder: `Karuna-`)
* **Framework Preset**: Vite
* **Root Directory**: `Karuna-`
* **Build Command**: `npm run build`
* **Output Directory**: `dist`
* **Environment Variables**:
  * `VITE_API_URL` = `https://karuna-backend-pa4r.onrender.com`

---

### 2️⃣ Project 2: Citizen Portal (Folder: `karuna-citizen`)
* **Framework Preset**: Vite
* **Root Directory**: `karuna-citizen`
* **Build Command**: `npm run build`
* **Output Directory**: `dist`
* **Environment Variables**:
  * `VITE_API_URL` = `https://karuna-backend-pa4r.onrender.com/api`
  * `VITE_NGO_URL` = `https://<YOUR_NGO_PORTAL_SUBDOMAIN>.vercel.app` (set this after deploying Project 3)

---

### 3️⃣ Project 3: NGO Portal (Folder: `karuna-ngo`)
* **Framework Preset**: Vite
* **Root Directory**: `karuna-ngo`
* **Build Command**: `npm run build`
* **Output Directory**: `dist`
* **Environment Variables**:
  * `VITE_API_URL` = `https://karuna-backend-pa4r.onrender.com/api`
  * `VITE_CITIZEN_URL` = `https://<YOUR_CITIZEN_PORTAL_SUBDOMAIN>.vercel.app` (set this after deploying Project 2)

---

## 💡 Notes on Configuration

* **Pre-configured Environment Files**: We have pre-configured `.env.production` files for all three portals with the live API URLs, meaning they will work out of the box when deployed on Vercel even if you don't manually set the environment variables in the Vercel dashboard.
* **Routing**: The applications use React state-based routing or client-side hash routing, so direct links and page refreshes will work seamlessly on Vercel without custom rewrite rules.
* **Backend Connection**: The production builds are fully updated to communicate directly with the live server at `https://karuna-backend-pa4r.onrender.com`.
