import React, { useEffect, useState } from 'react';
import { getOpenCases, applyForAdoption } from '../api';

export const AdoptPage: React.FC = () => {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    getOpenCases().then((all) => {
      // Only show adoptable cases
      setCases(all.filter((c: any) => c.status === 'discharged' || c.status === 'in_treatment'));
    }).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const handleApply = async (caseId: number) => {
    const name = prompt('Your name:');
    if (!name) return;
    const contact = prompt('Phone or email:');
    if (!contact) return;
    const reason = prompt('Why do you want to adopt?');
    if (!reason) return;
    try {
      await applyForAdoption(caseId, { applicantName: name, contact, reason });
      alert('Application submitted! The NGO will review it.');
    } catch (err: any) {
      alert(err.message);
    }
  };

  if (loading) return <p className="text-center text-slate-500 mt-8">Loading...</p>;

  return (
    <div className="max-w-4xl mx-auto">
      <h2 className="text-xl font-bold text-teal-800 mb-4">Adopt an animal</h2>
      {cases.length === 0 ? (
        <p className="text-slate-500">No animals available for adoption right now.</p>
      ) : (
        <div className="grid md:grid-cols-2 gap-4">
          {cases.map((c) => (
            <div key={c.id} className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
              {c.imageDataUrl && <img src={c.imageDataUrl} alt="" className="w-full h-36 object-cover rounded-lg mb-3 bg-slate-100" />}
              <div className="flex items-center gap-2 mb-1">
                <span className="text-xs font-semibold px-2 py-0.5 rounded bg-blue-100 text-blue-800">{c.status}</span>
                <span className="text-xs text-slate-500">{c.species}</span>
              </div>
              <p className="font-medium text-slate-800 text-sm">{c.probableCondition}</p>
              <p className="text-xs text-slate-500 mt-1">{c.locationLabel}</p>
              <p className="text-xs text-slate-400 mt-1">Reported by {c.reporterName}</p>
              <button onClick={() => handleApply(c.id)}
                className="mt-3 w-full bg-emerald-600 text-white text-sm font-medium py-2 rounded-lg hover:bg-emerald-700">
                Apply to adopt
              </button>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
