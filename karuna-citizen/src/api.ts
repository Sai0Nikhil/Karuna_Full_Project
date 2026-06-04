const BASE = 'http://localhost:8081/api';

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

export const register = (data: {
  name: string; email: string; password: string; role: string; phone?: string; ngoName?: string;
}) =>
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

export const getMyCases = () =>
  fetch(`${BASE}/cases/my`, { headers: authHeaders() }).then(handle);

export const getCase = (id: number) =>
  fetch(`${BASE}/cases/${id}`, { headers: authHeaders() }).then(handle);

export const createCase = (data: any) =>
  fetch(`${BASE}/cases`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify(data),
  }).then(handle);

// ─── Donations ───────────────────────────────────────────────────────

export const getDonations = () =>
  fetch(`${BASE}/donations`, { headers: authHeaders() }).then(handle);

export const getDonationsForCase = (caseId: number) =>
  fetch(`${BASE}/donations/case/${caseId}`, { headers: authHeaders() }).then(handle);

export const donate = (caseId: number, data: { donorName: string; amountInr: number; message?: string }) =>
  fetch(`${BASE}/donations/case/${caseId}`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify(data),
  }).then(handle);

// ─── Adoptions ───────────────────────────────────────────────────────

export const getAdoptionsForCase = (caseId: number) =>
  fetch(`${BASE}/adoptions/case/${caseId}`, { headers: authHeaders() }).then(handle);

export const applyForAdoption = (caseId: number, data: { applicantName: string; contact: string; reason: string }) =>
  fetch(`${BASE}/adoptions/case/${caseId}/apply`, {
    method: 'POST',
    headers: authHeaders(),
    body: JSON.stringify(data),
  }).then(handle);
