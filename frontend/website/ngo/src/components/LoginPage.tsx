import React, { useState } from 'react';
import { login as apiLogin, register as apiRegister } from '../api';

interface Props { onLogin: (u: any) => void; }

const ROLES = [
  { value: 'NGO', label: 'NGO / Organisation' },
  { value: 'VOLUNTEER', label: 'Volunteer / Responder' },
];

export const LoginPage: React.FC<Props> = ({ onLogin }) => {
  const [mode, setMode] = useState<'login' | 'register'>('login');
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [role, setRole] = useState('NGO');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const res = mode === 'login'
        ? await apiLogin(email, password, role)
        : await apiRegister({ name, email, password, role });
      onLogin(res);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-100 p-4">
      <div className="max-w-sm w-full bg-white rounded-xl shadow-md p-8">
        <div className="text-center mb-6">
          <div className="text-4xl mb-2">🐾</div>
          <h2 className="text-2xl font-bold text-teal-800 font-adlam">NGO Dashboard</h2>
          <p className="text-sm text-slate-500 mt-1">
            {mode === 'login' ? 'Sign in to manage cases' : 'Create an operations account'}
          </p>
        </div>
        <form onSubmit={handleSubmit} className="space-y-4">
          {mode === 'register' && (
            <div>
              <label htmlFor="ngo-name" className="block text-sm font-medium text-slate-700 mb-1">Name</label>
              <input id="ngo-name" required value={name} onChange={e => setName(e.target.value)} placeholder="Organisation or responder name"
                className="w-full p-2.5 border border-slate-300 rounded-lg" />
            </div>
          )}
          <div>
            <label htmlFor="ngo-role" className="block text-sm font-medium text-slate-700 mb-1">Login as</label>
            <select id="ngo-role" value={role} onChange={(e) => setRole(e.target.value)} aria-label="Login as"
              className="w-full p-2.5 border border-slate-300 rounded-lg">
              {ROLES.map(r => <option key={r.value} value={r.value}>{r.label}</option>)}
            </select>
          </div>
          <div>
            <label htmlFor="ngo-email" className="block text-sm font-medium text-slate-700 mb-1">Email</label>
            <input id="ngo-email" type="email" required value={email} onChange={e => setEmail(e.target.value)} placeholder="you@example.com"
              className="w-full p-2.5 border border-slate-300 rounded-lg" />
          </div>
          <div>
            <label htmlFor="ngo-password" className="block text-sm font-medium text-slate-700 mb-1">Password</label>
            <input id="ngo-password" type="password" required value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••"
              className="w-full p-2.5 border border-slate-300 rounded-lg" />
          </div>
          {error && <div className="text-red-600 text-sm bg-red-50 p-3 rounded-lg">{error}</div>}
          <button type="submit" disabled={loading}
            className="w-full bg-teal-600 text-white font-bold py-3 rounded-lg hover:bg-teal-700 disabled:opacity-50">
            {loading ? (mode === 'login' ? 'Signing in...' : 'Creating account...') : (mode === 'login' ? 'Sign in' : 'Create account')}
          </button>
        </form>
        <button
          type="button"
          onClick={() => {
            setError('');
            setMode(mode === 'login' ? 'register' : 'login');
          }}
          className="mt-4 w-full text-sm text-teal-700 hover:underline"
        >
          {mode === 'login' ? 'Create NGO / responder account' : 'Back to sign in'}
        </button>
      </div>
    </div>
  );
};
