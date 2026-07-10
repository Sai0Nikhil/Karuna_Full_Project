import React, { useCallback, useEffect, useState } from 'react';
import { getCases, getOpenCases, getMyCases, subscribeToCaseUpdates } from '../api';

interface Props { user: any; onViewCase: (id: number) => void; }

export const Dashboard: React.FC<Props> = ({ user, onViewCase }) => {
  const [allCases, setAllCases] = useState<any[]>([]);
  const [openCases, setOpenCases] = useState<any[]>([]);
  const [myCases, setMyCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);

  const loadDashboard = useCallback((showLoading = false) => {
    if (showLoading) setLoading(true);
    return Promise.all([getCases(), getOpenCases(), getMyCases()])
      .then(([all, open, my]) => { setAllCases(all); setOpenCases(open); setMyCases(my); })
      .catch(() => {})
      .finally(() => {
        if (showLoading) setLoading(false);
      });
  }, []);

  useEffect(() => {
    loadDashboard(true);
    return subscribeToCaseUpdates(() => { void loadDashboard(false); });
  }, [loadDashboard]);

  if (loading) return <p className="text-slate-500">Loading dashboard...</p>;

  const statusCounts: Record<string, number> = {};
  allCases.forEach((c: any) => { statusCounts[c.status] = (statusCounts[c.status] || 0) + 1; });

  const totals = {
    total: allCases.length,
    open: openCases.length,
    unassigned: openCases.filter((c: any) => !c.responderName).length,
    inTreatment: statusCounts['in_treatment'] || 0,
    discharged: statusCounts['discharged'] || 0,
  };

  // Calculate funding stats
  const totalDonations = allCases.reduce((sum: number, c: any) => {
    const d = c.donations || [];
    return sum + d.reduce((s: number, d2: any) => s + d2.amountInr, 0);
  }, 0);
  const totalEstimated = allCases.reduce((sum: number, c: any) => sum + (c.estimatedCostInr || 0), 0);

  return (
    <div>
      <h1 className="text-2xl font-bold text-slate-800 mb-6">Dashboard</h1>

      {/* Stats cards */}
      <div className="grid grid-cols-2 md:grid-cols-5 gap-4 mb-6">
        <StatCard label="Total cases" value={totals.total} color="bg-blue-500" />
        <StatCard label="Open" value={totals.open} color="bg-amber-500" />
        <StatCard label="Unassigned" value={totals.unassigned} color="bg-red-500" />
        <StatCard label="In treatment" value={totals.inTreatment} color="bg-purple-500" />
        <StatCard label="Recovered" value={totals.discharged} color="bg-emerald-500" />
      </div>

      {/* Funding progress */}
      <div className="bg-white rounded-xl border border-slate-200 p-5 mb-6">
        <h2 className="font-semibold text-slate-700 mb-2">Funding progress</h2>
        <div className="flex justify-between text-sm text-slate-600 mb-1">
          <span>₹{(totalDonations).toLocaleString('en-IN')} raised</span>
          <span>of ₹{(totalEstimated).toLocaleString('en-IN')} needed</span>
        </div>
        <progress
          className="w-full h-3 rounded-full overflow-hidden accent-teal-500"
          max={100}
          value={totalEstimated > 0 ? Math.min(100, (totalDonations / totalEstimated) * 100) : 0}
        />
      </div>

      {/* Recent unassigned cases */}
      {openCases.filter((c: any) => !c.responderName).length > 0 && (
        <div className="bg-white rounded-xl border border-slate-200 p-5 mb-6">
          <div className="flex items-center justify-between mb-4">
            <h2 className="font-semibold text-slate-700">Unassigned cases — needs dispatch</h2>
            <span className="text-xs bg-red-100 text-red-700 px-2 py-1 rounded-full font-medium">
              {openCases.filter((c: any) => !c.responderName).length} pending
            </span>
          </div>
          <div className="space-y-2">
            {openCases.filter((c: any) => !c.responderName).slice(0, 5).map((c: any) => (
              <button key={c.id} onClick={() => onViewCase(c.id)}
                className="w-full text-left flex justify-between items-center p-3 rounded-lg hover:bg-slate-50 border border-slate-100">
                <div>
                  <span className="font-medium text-sm">#{c.id}</span>
                  <span className="text-xs text-slate-500 ml-2">{c.species}</span>
                  <p className="text-xs text-slate-600 mt-0.5 truncate max-w-xs">{c.probableCondition}</p>
                </div>
                <span className="text-xs text-slate-500">{c.locationLabel}</span>
              </button>
            ))}
          </div>
        </div>
      )}

      {/* My assigned cases */}
      {myCases.length > 0 && (
        <div className="bg-white rounded-xl border border-slate-200 p-5">
          <h2 className="font-semibold text-slate-700 mb-4">My assigned cases</h2>
          <div className="space-y-2">
            {myCases.map((c: any) => (
              <button key={c.id} onClick={() => onViewCase(c.id)}
                className="w-full text-left flex justify-between items-center p-3 rounded-lg hover:bg-slate-50 border border-slate-100">
                <div>
                  <span className="font-medium text-sm">#{c.id}</span>
                  <span className={`ml-2 text-xs font-medium px-2 py-0.5 rounded ${
                    c.status === 'in_treatment' ? 'bg-purple-100 text-purple-700' :
                    c.status === 'assigned' ? 'bg-amber-100 text-amber-700' :
                    c.status === 'discharged' ? 'bg-emerald-100 text-emerald-700' :
                    'bg-slate-100 text-slate-700'
                  }`}>{c.status}</span>
                  <p className="text-xs text-slate-600 mt-0.5">{c.probableCondition}</p>
                </div>
                <span className="text-xs text-slate-500">{c.locationLabel}</span>
              </button>
            ))}
          </div>
        </div>
      )}
    </div>
  );
};

const StatCard: React.FC<{ label: string; value: number; color: string }> = ({ label, value, color }) => (
  <div className="bg-white rounded-xl border border-slate-200 p-4 shadow-sm">
    <div className={`inline-block w-2 h-2 rounded-full ${color} mb-2`} />
    <div className="text-2xl font-bold text-slate-800">{value}</div>
    <div className="text-xs text-slate-500">{label}</div>
  </div>
);
