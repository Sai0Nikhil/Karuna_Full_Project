import React, { useEffect, useState } from 'react';
import { getOpenCases, donate, subscribeToCaseUpdates } from '../api';

interface DonationFormState {
  donorName: string;
  amountInr: string;
  message: string;
}

const EMPTY_FORM: DonationFormState = {
  donorName: '',
  amountInr: '',
  message: '',
};

export const DonatePage: React.FC = () => {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [donating, setDonating] = useState<number | null>(null);
  const [selectedCaseId, setSelectedCaseId] = useState<number | null>(null);
  const [form, setForm] = useState<DonationFormState>(EMPTY_FORM);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    const loadCases = (showLoading = false) => {
      if (showLoading) setLoading(true);
      getOpenCases().then(setCases).catch(() => {}).finally(() => {
        if (showLoading) setLoading(false);
      });
    };
    loadCases(true);
    return subscribeToCaseUpdates(() => loadCases(false));
  }, []);

  const startDonation = (caseId: number) => {
    setSelectedCaseId(caseId);
    setForm(EMPTY_FORM);
    setNotice('');
    setError('');
  };

  const handleDonate = async (caseId: number) => {
    const donorName = form.donorName.trim();
    const amountInr = Number(form.amountInr);
    if (!donorName) {
      setError('Enter your name before donating.');
      return;
    }
    if (!Number.isFinite(amountInr) || amountInr < 1) {
      setError('Enter a valid donation amount.');
      return;
    }
    setDonating(caseId);
    setError('');
    setNotice('');
    try {
      await donate(caseId, { donorName, amountInr: Math.round(amountInr), message: form.message.trim() || undefined });
      setCases(await getOpenCases());
      setNotice('Donation recorded. Thank you for supporting this case.');
      setSelectedCaseId(null);
      setForm(EMPTY_FORM);
    } catch (err: any) {
      setError(err.message || 'Donation failed.');
    } finally {
      setDonating(null);
    }
  };

  if (loading) return <p className="text-center text-slate-500 mt-8">Loading...</p>;

  return (
    <div className="max-w-4xl mx-auto">
      <h2 className="text-xl font-bold text-teal-800 mb-4">Support a case</h2>
      {notice && <div className="mb-4 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg p-3">{notice}</div>}
      {error && <div className="mb-4 text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg p-3">{error}</div>}
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
                {selectedCaseId === c.id ? (
                  <form
                    onSubmit={(event) => {
                      event.preventDefault();
                      handleDonate(c.id);
                    }}
                    className="mt-4 border-t border-slate-100 pt-4 space-y-3"
                  >
                    <div className="grid sm:grid-cols-2 gap-3">
                      <div>
                        <label htmlFor={`donor-name-${c.id}`} className="block text-xs font-medium text-slate-600 mb-1">Name</label>
                        <input
                          id={`donor-name-${c.id}`}
                          value={form.donorName}
                          onChange={(event) => setForm({ ...form, donorName: event.target.value })}
                          className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                          placeholder="Your name"
                          required
                        />
                      </div>
                      <div>
                        <label htmlFor={`donation-amount-${c.id}`} className="block text-xs font-medium text-slate-600 mb-1">Amount</label>
                        <input
                          id={`donation-amount-${c.id}`}
                          type="number"
                          min="1"
                          value={form.amountInr}
                          onChange={(event) => setForm({ ...form, amountInr: event.target.value })}
                          className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                          placeholder="₹"
                          required
                        />
                      </div>
                    </div>
                    <div>
                      <label htmlFor={`donation-message-${c.id}`} className="block text-xs font-medium text-slate-600 mb-1">Message</label>
                      <textarea
                        id={`donation-message-${c.id}`}
                        value={form.message}
                        onChange={(event) => setForm({ ...form, message: event.target.value })}
                        className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                        rows={2}
                        placeholder="Optional note for the rescue team"
                      />
                    </div>
                    <div className="flex gap-2">
                      <button type="submit" disabled={donating === c.id}
                        className="flex-1 bg-teal-600 text-white text-sm font-medium py-2 rounded-lg hover:bg-teal-700 disabled:opacity-50">
                        {donating === c.id ? 'Processing...' : 'Submit donation'}
                      </button>
                      <button type="button" onClick={() => setSelectedCaseId(null)}
                        className="px-4 py-2 border border-slate-300 text-slate-600 text-sm rounded-lg hover:bg-slate-50">
                        Cancel
                      </button>
                    </div>
                  </form>
                ) : (
                  <button onClick={() => startDonation(c.id)} disabled={donating === c.id}
                    className="mt-3 w-full bg-teal-600 text-white text-sm font-medium py-2 rounded-lg hover:bg-teal-700 disabled:opacity-50">
                    Donate
                  </button>
                )}
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
