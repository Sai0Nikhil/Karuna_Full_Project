// Use env variable in production, fallback to localhost for dev
const BASE = import.meta.env.VITE_API_URL || 'http://localhost:8081/api';

function authHeaders(): Record<string, string> {
  const t = localStorage.getItem('token');
  return t ? { Authorization: `Bearer ${t}`, 'Content-Type': 'application/json' } : { 'Content-Type': 'application/json' };
}

async function handle(res: Response) {
  if (!res.ok) {
    const body = await res.json().catch(() => ({ message: res.statusText }));
    throw new Error(body.message || 'Request failed');
  }
  return res.json();
}

// ─── Auth ────────────────────────────────────────────────────────────

export const login = (email: string, password: string, role?: string) =>
  fetch(`${BASE}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, role }),
  }).then(handle);

export const register = (data: any) =>
  fetch(`${BASE}/auth/register`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  }).then(handle);

// ─── Cases ───────────────────────────────────────────────────────────

export const getCases = () =>
  fetch(`${BASE}/cases`, { headers: authHeaders() }).then(handle);

export const getOpenCases = () =>
  fetch(`${BASE}/cases/open`, { headers: authHeaders() }).then(handle);

export const getCase = (id: number) =>
  fetch(`${BASE}/cases/${id}`, { headers: authHeaders() }).then(handle);

export const createCase = (data: any) =>
  fetch(`${BASE}/cases`, {
    method: 'POST', headers: authHeaders(), body: JSON.stringify(data),
  }).then(handle);

export const assignCase = (caseId: number, responderId: number) =>
  fetch(`${BASE}/cases/${caseId}/assign`, {
    method: 'POST', headers: authHeaders(), body: JSON.stringify({ responderId }),
  }).then(handle);

export const advanceCase = (caseId: number, event: string) =>
  fetch(`${BASE}/cases/${caseId}/advance`, {
    method: 'POST', headers: authHeaders(), body: JSON.stringify({ event }),
  }).then(handle);

export const addNote = (caseId: number, text: string) =>
  fetch(`${BASE}/cases/${caseId}/notes`, {
    method: 'POST', headers: authHeaders(), body: JSON.stringify({ text }),
  }).then(handle);

// ─── Users (admin) ───────────────────────────────────────────────────

export const getResponders = () =>
  fetch(`${BASE}/users/responders`, { headers: authHeaders() }).then(handle);

export const getMyCases = () =>
  fetch(`${BASE}/cases/my`, { headers: authHeaders() }).then(handle);

// ─── Donations ───────────────────────────────────────────────────────

export const getDonations = () =>
  fetch(`${BASE}/donations`, { headers: authHeaders() }).then(handle);

export const getDonationsForCase = (caseId: number) =>
  fetch(`${BASE}/donations/case/${caseId}`, { headers: authHeaders() }).then(handle);

// ─── Adoptions ───────────────────────────────────────────────────────

export const getAdoptionsForCase = (caseId: number) =>
  fetch(`${BASE}/adoptions/case/${caseId}`, { headers: authHeaders() }).then(handle);

export const updateAdoptionStatus = (adoptionId: number, status: string) =>
  fetch(`${BASE}/adoptions/${adoptionId}`, {
    method: 'PUT', headers: authHeaders(), body: JSON.stringify({ status }),
  }).then(handle);
