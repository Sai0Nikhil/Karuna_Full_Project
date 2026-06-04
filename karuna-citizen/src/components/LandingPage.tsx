import React from 'react';

interface Props {
  onNavigate: (p: string) => void;
  user: any;
}

export const LandingPage: React.FC<Props> = ({ onNavigate, user }) => (
  <main>
    {/* Hero */}
    <section className="bg-gradient-to-br from-teal-800 via-teal-700 to-emerald-800 text-white rounded-2xl p-10 md:p-16 text-center">
      <div className="text-5xl mb-4 animate-fade-up">🐾</div>
      <h1 className="text-4xl md:text-5xl font-bold font-adlam mb-3 animate-fade-up animate-fade-up-d1">Karuṇā</h1>
      <p className="text-lg text-teal-100 max-w-2xl mx-auto mb-2 animate-fade-up animate-fade-up-d2">
        AI-assisted community-driven street-animal rescue
      </p>
      <div className="h-px w-20 bg-teal-400 mx-auto my-4" />
      <p className="text-teal-200 max-w-xl mx-auto text-sm animate-fade-up animate-fade-up-d3">
        Found an animal in distress? Upload a photo and your location — get instant first-aid guidance.
        Track every step from rescue to recovery.
      </p>

      <div className="mt-8 flex flex-wrap justify-center gap-3">
        <button onClick={() => onNavigate('report')}
          className="bg-white text-teal-800 font-bold px-6 py-3 rounded-xl shadow-lg hover:scale-105 transition-all">
          Report an animal →
        </button>
        <button onClick={() => onNavigate('donate')}
          className="bg-teal-600 text-white font-bold px-6 py-3 rounded-xl border-2 border-teal-400/40 hover:bg-teal-500 transition-all">
          Donate to a case
        </button>
        {!user && (
          <button onClick={() => onNavigate('login')}
            className="bg-white/20 text-white font-medium px-6 py-3 rounded-xl border border-white/30 hover:bg-white/30 transition-all">
            Sign in
          </button>
        )}
      </div>
    </section>

    {/* How it works */}
    <section className="py-12">
      <h2 className="text-2xl font-bold text-center text-slate-800 mb-8">How it works</h2>
      <div className="grid md:grid-cols-4 gap-6 max-w-4xl mx-auto">
        {[
          { icon: '📸', title: 'Photo & location', desc: 'Snap the animal and the app records GPS + time.' },
          { icon: '🤖', title: 'AI triage', desc: 'Our engine assesses injury severity and gives first-aid steps.' },
          { icon: '🚑', title: 'Auto-dispatch', desc: 'Nearest qualified responder is notified automatically.' },
          { icon: '📋', title: 'Track to outcome', desc: 'Follow treatment, donate, or adopt — all in one place.' },
        ].map((s, i) => (
          <div key={i} className="text-center">
            <div className="text-3xl mb-2">{s.icon}</div>
            <h3 className="font-semibold text-slate-800 text-sm">{s.title}</h3>
            <p className="text-xs text-slate-500 mt-1">{s.desc}</p>
          </div>
        ))}
      </div>
    </section>
  </main>
);
