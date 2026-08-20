import React, { useState, useEffect } from 'react';
import { LoginPage } from './components/LoginPage';
import { RegisterPage } from './components/RegisterPage';
import { LandingPage } from './components/LandingPage';
import { ReportFlow } from './components/ReportFlow';
import { CaseList } from './components/CaseList';
import { DonatePage } from './components/DonatePage';
import { AdoptPage } from './components/AdoptPage';

type Page = 'login' | 'register' | 'landing' | 'report' | 'my-cases' | 'donate' | 'adopt';

interface AuthUser {
  token: string;
  userId: number;
  name: string;
  email: string;
  role: string;
}

export default function App() {
  const [page, setPage] = useState<Page>('landing');
  const [user, setUser] = useState<AuthUser | null>(null);

  useEffect(() => {
    const saved = localStorage.getItem('user');
    if (saved) {
      try { setUser(JSON.parse(saved)); } catch { localStorage.removeItem('user'); }
    }
  }, []);

  const doLogin = (u: AuthUser) => {
    setUser(u);
    localStorage.setItem('token', u.token);
    localStorage.setItem('user', JSON.stringify(u));
    setPage('landing');
  };

  const doLogout = () => {
    setUser(null);
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setPage('landing');
  };

  return (
    <div className="min-h-screen font-sans bg-slate-100">
      {/* Top bar */}
      <header className="bg-white shadow-sm border-b border-slate-200 sticky top-0 z-30">
        <div className="container mx-auto px-4 py-3 flex items-center justify-between">
          <button onClick={() => setPage('landing')} className="flex items-center gap-2 text-2xl font-adlam text-teal-700">
            <span>🐾</span><span>Karuṇā</span>
            <span className="text-xs text-slate-500 font-sans ml-1 hidden sm:inline">Citizen</span>
          </button>
          <nav className="flex items-center gap-2 text-sm">
            <NavBtn active={page === 'landing'} onClick={() => setPage('landing')}>Home</NavBtn>
            <NavBtn active={page === 'report'} onClick={() => setPage('report')}>Report</NavBtn>
            <NavBtn active={page === 'donate'} onClick={() => setPage('donate')}>Donate</NavBtn>
            <NavBtn active={page === 'adopt'} onClick={() => setPage('adopt')}>Adopt</NavBtn>
            {user && <NavBtn active={page === 'my-cases'} onClick={() => setPage('my-cases')}>My Cases</NavBtn>}
            {/* NGO Portal Link */}
            <a
              href={import.meta.env.VITE_NGO_URL || '/ngo'}
              target="_blank"
              rel="noopener noreferrer"
              className="px-3 py-1.5 rounded-md text-orange-600 border border-orange-300 hover:bg-orange-50 font-medium transition"
            >
              NGO Portal
            </a>
            {user ? (
              <button onClick={doLogout} className="px-3 py-1.5 rounded-md text-slate-500 hover:bg-slate-100">
                Logout ({user.name})
              </button>
            ) : (
              <button onClick={() => setPage('login')} className="px-3 py-1.5 rounded-md bg-teal-600 text-white font-medium hover:bg-teal-700">
                Login
              </button>
            )}
          </nav>
        </div>
      </header>

      {/* Page content */}
      <div className="container mx-auto px-4 py-6">
        {page === 'login' && <LoginPage onLogin={doLogin} onRegister={() => setPage('register')} />}
        {page === 'register' && <RegisterPage onRegister={doLogin} onBackToLogin={() => setPage('login')} />}
        {page === 'landing' && <LandingPage onNavigate={setPage} user={user} />}
        {page === 'report' && <ReportFlow user={user} onNeedLogin={() => setPage('login')} />}
        {page === 'my-cases' && <CaseList user={user} />}
        {page === 'donate' && <DonatePage />}
        {page === 'adopt' && <AdoptPage />}
      </div>

      <footer className="text-center text-xs text-slate-500 py-6">
        🐾 Karuṇā · Citizen Portal
      </footer>
    </div>
  );
}

const NavBtn: React.FC<{ active: boolean; onClick: () => void; children: React.ReactNode }> = ({ active, onClick, children }) => (
  <button onClick={onClick} className={`px-3 py-1.5 rounded-md font-medium transition ${active ? 'bg-teal-600 text-white' : 'text-slate-700 hover:bg-slate-100'}`}>
    {children}
  </button>
);
