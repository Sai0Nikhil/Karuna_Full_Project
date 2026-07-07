import React, { useEffect, useState } from 'react';
import { getCases } from '../api';

interface Props { onViewCase: (id: number) => void; }

export const CaseList: React.FC<Props> = ({ onViewCase }) => {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('all');

  useEffect(() => {
    getCases().then(setCases).catch(() => {}).finally(() => setLoading(false));
  }, []);

  const filtered = filter === 'all' ? cases : cases.filter((c: any) => c.status === filter);

  if (loading) return <p className="text-slate-500">Loading...</p>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-800">All Cases</h1>
        <div className="flex gap-2">
          {['all', 'reported', 'rescue_route', 'in_treatment', 'discharged'].map((s) => (
            <button key={s} onClick={() => setFilter(s)}
              className={`px-3 py-1.5 text-xs font-medium rounded-lg ${filter === s ? 'bg-teal-600 text-white' : 'bg-white text-slate-600 border border-slate-200'}`}>
              {s === 'all' ? 'All' : s.replace('_', ' ')}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden">
        <table className="w-full text-sm">
          <thead className="bg-slate-50 text-slate-600 text-left">
            <tr>
              <th className="p-3 font-medium">ID</th>
              <th className="p-3 font-medium">Species</th>
              <th className="p-3 font-medium">Condition</th>
              <th className="p-3 font-medium">Location</th>
              <th className="p-3 font-medium">Severity</th>
              <th className="p-3 font-medium">Status</th>
              <th className="p-3 font-medium">Responder</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100">
            {filtered.map((c: any) => (
              <tr key={c.id} onClick={() => onViewCase(c.id)}
                className="hover:bg-slate-50 cursor-pointer">
                <td className="p-3 font-medium text-slate-700">#{c.id}</td>
                <td className="p-3 text-slate-600">{c.species}</td>
                <td className="p-3 text-slate-600 truncate max-w-[200px]">{c.probableCondition}</td>
                <td className="p-3 text-slate-500 text-xs">{c.locationLabel}</td>
                <td className="p-3">
                  <span className={`text-xs font-medium px-2 py-0.5 rounded ${
                    c.severity === 'critical' ? 'bg-red-100 text-red-700' :
                    c.severity === 'urgent' ? 'bg-orange-100 text-orange-700' :
                    'bg-green-100 text-green-700'
                  }`}>{c.severity}</span>
                </td>
                <td className="p-3">
                  <span className="text-xs font-medium px-2 py-0.5 rounded bg-blue-100 text-blue-700">{c.status}</span>
                </td>
                <td className="p-3 text-xs text-slate-500">{c.responderName || '—'}</td>
              </tr>
            ))}
          </tbody>
        </table>
        {filtered.length === 0 && <p className="p-8 text-center text-slate-500">No cases found.</p>}
      </div>
    </div>
  );
};
