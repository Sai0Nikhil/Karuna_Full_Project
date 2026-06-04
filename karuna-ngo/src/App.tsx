import React, { useState, useEffect } from 'react';
import { LoginPage } from './components/LoginPage';
import { Dashboard } from './components/Dashboard';
import { CaseDetail } from './components/CaseDetail';
import { CaseList } from './components/CaseList';

type Page = 'login' | 'dashboard' | 'case-detail' | 'cases';

interface AuthUser {
  token: string;
  userId: number;
  name: string;
  email: string;
  role: string;
}

export default function App() {
  const [page, setPage] = useState<Page>('dashboard');
  const [user, setUser] = useState<AuthUser | null>(null);
  const [selectedCaseId, setSelectedCaseId] = useState<number | null>(null);

  useEffect(() => {
    const saved = localStorage.getItem('user');
    if (saved) {
      try { const u = JSON.parse(saved); setUser(u); } catch { localStorage.removeItem('user'); }
    }
  }, []);

  const doLogin = (u: AuthUser) => {
    setUser(u);
    localStorage.setItem('token', u.token);
    localStorage.setItem('user', JSON.stringify(u));
    setPage('dashboard');
  };

  const doLogout = () => {
    setUser(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setPage('login');
  };

  const goToCase = (id: number) => { setSelectedCaseId(id); setPage('case-detail'); };

  if (!user) return <LoginPage onLogin={doLogin} />;

  return (
    <div className="min-h-screen bg-slate-100 flex">
      {/* Sidebar */}
      <aside className="w-56 bg-teal-900 text-white flex flex-col shrink-0">
        <div className="p-4 text-lg font-adlam flex items-center gap-2 border-b border-teal-700">
          🐾 Karuṇā <span className="text-xs font-sans opacity-70">NGO</span>
        </div>
        <nav className="flex-1 p-2 space-y-1">
          <SideBtn active={page === 'dashboard'} onClick={() => setPage('dashboard')}>
            📊 Dashboard
          </SideBtn>
          <SideBtn active={page === 'cases'} onClick={() => setPage('cases')}>
            📋 All Cases
          </SideBtn>
          {/* Link to Citizen Portal */}
          <a
            href={import.meta.env.VITE_CITIZEN_URL || '/citizen'}
            target="_blank"
            rel="noopener noreferrer"
            className="w-full text-left px-3 py-2 rounded-lg text-sm font-medium transition text-orange-300 hover:bg-teal-800 flex items-center gap-2"
          >
            🏠 Citizen Portal
          </a>
        </nav>
        <div className="p-4 border-t border-teal-700 text-sm">
          <div className="text-teal-200 truncate">{user.name}</div>
          <div className="text-teal-400 text-xs">{user.role}</div>
          <button onClick={doLogout} className="mt-2 text-teal-300 hover:text-white text-xs">Logout</button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 p-6 overflow-y-auto">
        {page === 'dashboard' && <Dashboard user={user} onViewCase={goToCase} />}
        {page === 'cases' && <CaseList onViewCase={goToCase} />}
        {page === 'case-detail' && selectedCaseId && (
          <CaseDetail caseId={selectedCaseId} onBack={() => { setSelectedCaseId(null); setPage('cases'); }} user={user} />
        )}
      </main>
    </div>
  );
}

const SideBtn: React.FC<{ active: boolean; onClick: () => void; children: React.ReactNode }> = ({ active, onClick, children }) => (
  <button
    onClick={onClick}
    className={`w-full text-left px-3 py-2 rounded-lg text-sm font-medium transition ${active ? 'bg-teal-700 text-white' : 'text-teal-100 hover:bg-teal-800'}`}
  >
    {children}
  </button>
);
