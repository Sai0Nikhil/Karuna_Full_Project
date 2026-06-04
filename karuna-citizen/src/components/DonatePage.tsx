import React, { useEffect, useState } from 'react';
import { getOpenCases, donate } from '../api';

export const DonatePage: React.FC = () => {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [donating, setDonating] = useState<number | null>(null);

  useEffect(() => {
    getOpenCases().then(setCases).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const handleDonate = async (caseId: number) => {
    const name = prompt('Your name:');
    if (!name) return;
    const amount = parseInt(prompt('Amount (₹):') || '0', 10);
    if (!amount || amount < 1) return;
    setDonating(caseId);
    try {
      await donate(caseId, { donorName: name, amountInr: amount });
      alert('Thank you for your donation!');
    } catch (err: any) {
      alert(err.message);
    } finally {
      setDonating(null);
    }
  };

  if (loading) return <p className="text-center text-slate-500 mt-8">Loading...</p>;

  return (
    <div className="max-w-4xl mx-auto">
      <h2 className="text-xl font-bold text-teal-800 mb-4">Support a case</h2>
      {cases.length === 0 ? (
        <p className="text-slate-500">No active cases needing funding.</p>
      ) : (
        <div className="grid md:grid-cols-2 gap-4">
          {cases.map((c) => {
            const raised = c.donations?.reduce((s: number, d: any) => s + d.amountInr, 0) || 0;
            const goal = c.estimatedCostInr || 0;
            const pct = goal > 0 ? Math.min(100, Math.round((raised / goal) * 100)) : 0;
            return (
              <div key={c.id} className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
                {c.imageDataUrl && <img src={c.imageDataUrl} alt="" className="w-full h-36 object-cover rounded-lg mb-3 bg-slate-100" />}
                <div className="flex items-center gap-2 mb-1">
                  <span className="text-xs font-semibold px-2 py-0.5 rounded bg-amber-100 text-amber-800">{c.severity}</span>
                  <span className="text-xs text-slate-500">{c.species}</span>
                </div>
                <p className="font-medium text-slate-800 text-sm">{c.probableCondition}</p>
                <p className="text-xs text-slate-500 mt-1">{c.locationLabel}</p>
                <div className="mt-3">
                  <div className="flex justify-between text-xs text-slate-600 mb-1">
                    <span>₹{raised.toLocaleString('en-IN')} raised</span>
                    <span>of ₹{goal.toLocaleString('en-IN')}</span>
                  </div>
                  <div className="w-full bg-slate-200 rounded-full h-2">
                    <div className="bg-teal-500 h-2 rounded-full" style={{ width: `${pct}%` }} />
                  </div>
                </div>
                <button onClick={() => handleDonate(c.id)} disabled={donating === c.id}
                  className="mt-3 w-full bg-teal-600 text-white text-sm font-medium py-2 rounded-lg hover:bg-teal-700 disabled:opacity-50">
                  {donating === c.id ? 'Processing...' : 'Donate'}
                </button>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
