import React, { useEffect, useState } from 'react';
import { getMyCases } from '../api';

interface Props { user: any; }

export const CaseList: React.FC<Props> = ({ user }) => {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) return;
    getMyCases().then(setCases).catch(() => {}).finally(() => setLoading(false));
  }, [user]);

  if (!user) return <p className="text-center text-slate-500 mt-8">Please sign in to see your cases.</p>;
  if (loading) return <p className="text-center text-slate-500 mt-8">Loading...</p>;

  return (
    <div className="max-w-3xl mx-auto">
      <h2 className="text-xl font-bold text-teal-800 mb-4">My Reports</h2>
      {cases.length === 0 ? (
        <p className="text-slate-500">No cases reported yet.</p>
      ) : (
        <div className="space-y-3">
          {cases.map((c) => (
            <div key={c.id} className="bg-white rounded-lg p-4 shadow-sm border border-slate-200">
              <div className="flex gap-4">
                {c.imageDataUrl && <img src={c.imageDataUrl} alt="" className="w-20 h-20 rounded object-cover bg-slate-100" />}
                <div>
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-semibold px-2 py-0.5 rounded bg-blue-100 text-blue-800">{c.status}</span>
                    <span className="text-xs text-slate-500">#{c.id}</span>
                  </div>
                  <p className="text-sm text-slate-700 mt-1">{c.probableCondition}</p>
                  <p className="text-xs text-slate-500">{c.locationLabel}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
