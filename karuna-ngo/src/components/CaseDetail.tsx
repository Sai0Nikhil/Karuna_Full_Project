import React, { useEffect, useState, useCallback } from 'react';
import { getCase, assignCase, advanceCase, addNote, getResponders } from '../api';

interface Props { caseId: number; onBack: () => void; user: any; }

const STATUS_ACTIONS: Record<string, { next: string; label: string; color: string }[]> = {
  reported: [
    { next: 'rescue_route', label: 'Dispatch to rescue →', color: 'bg-amber-600 hover:bg-amber-700' },
  ],
  rescue_route: [
    { next: 'in_treatment', label: 'Start treatment →', color: 'bg-purple-600 hover:bg-purple-700' },
  ],
  in_treatment: [
    { next: 'discharged', label: 'Mark as recovered →', color: 'bg-emerald-600 hover:bg-emerald-700' },
  ],
};

export const CaseDetail: React.FC<Props> = ({ caseId, onBack, user }) => {
  const [c, setCase] = useState<any>(null);
  const [responders, setResponders] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [noteText, setNoteText] = useState('');
  const [actionLoading, setActionLoading] = useState(false);

  const load = useCallback(() => {
    setLoading(true);
    Promise.all([getCase(caseId), getResponders()])
      .then(([cData, rData]) => { setCase(cData); setResponders(rData); })
      .catch(() => {})
      .finally(() => setLoading(false));
  }, [caseId]);

  useEffect(() => { load(); }, [load]);

  const handleAdvance = async (event: string) => {
    setActionLoading(true);
    try { await advanceCase(caseId, event); await load(); }
    catch (err: any) { alert(err.message); }
    finally { setActionLoading(false); }
  };

  const handleAssign = async (responderId: number) => {
    setActionLoading(true);
    try { await assignCase(caseId, responderId); await load(); }
    catch (err: any) { alert(err.message); }
    finally { setActionLoading(false); }
  };

  const handleAddNote = async () => {
    if (!noteText.trim()) return;
    setActionLoading(true);
    try { await addNote(caseId, noteText); setNoteText(''); await load(); }
    catch (err: any) { alert(err.message); }
    finally { setActionLoading(false); }
  };

  if (loading) return <p className="text-slate-500">Loading case...</p>;
  if (!c) return <p className="text-red-500">Case not found.</p>;

  const actions = STATUS_ACTIONS[c.status] || [];
  const parsedNotes: string[] = (() => {
    try { return JSON.parse(c.notes || '[]'); } catch { return []; }
  })();
  const parsedFirstAid: string[] = (() => {
    try { return JSON.parse(c.firstAidSteps || '[]'); } catch { return []; }
  })();
  const donations = c.donations || [];
  const adoptions = c.adoptions || [];

  return (
    <div>
      <button onClick={onBack} className="text-sm text-teal-600 hover:underline mb-4">← Back to cases</button>

      <div className="flex gap-6 flex-wrap">
        {/* Left — Case info */}
        <div className="flex-1 min-w-0 space-y-4">
          <div className="bg-white rounded-xl border border-slate-200 p-5">
            <div className="flex items-start justify-between mb-3">
              <div>
                <h1 className="text-xl font-bold text-slate-800">Case #{c.id}</h1>
                <p className="text-sm text-slate-500">
                  Reported {new Date(c.createdAt || Date.now()).toLocaleDateString('en-IN')}
                  {c.reporterName && ` by ${c.reporterName}`}
                </p>
              </div>
              <div className="flex gap-2">
                <span className={`text-xs font-semibold px-2 py-1 rounded ${
                  c.severity === 'critical' ? 'bg-red-100 text-red-700' :
                  c.severity === 'urgent' ? 'bg-orange-100 text-orange-700' :
                  'bg-green-100 text-green-700'
                }`}>{c.severity}</span>
                <span className="text-xs font-semibold px-2 py-1 rounded bg-blue-100 text-blue-700">{c.status}</span>
              </div>
            </div>

            {c.imageDataUrl && (
              <img src={c.imageDataUrl} alt="" className="w-full h-48 object-cover rounded-lg mb-3 bg-slate-100" />
            )}

            <p className="text-sm text-slate-700 mb-2"><strong>Condition:</strong> {c.probableCondition}</p>
            <p className="text-sm text-slate-700 mb-2"><strong>Species:</strong> {c.species}</p>
            <p className="text-sm text-slate-700 mb-2"><strong>Location:</strong> {c.locationLabel}</p>
            {c.responderName && <p className="text-sm text-slate-700"><strong>Responder:</strong> {c.responderName}</p>}
          </div>

          {/* First aid steps */}
          {parsedFirstAid.length > 0 && (
            <div className="bg-amber-50 border border-amber-200 rounded-xl p-5">
              <h3 className="font-semibold text-amber-800 mb-2">🩹 First aid steps</h3>
              <ol className="list-decimal list-inside text-sm text-amber-900 space-y-1">
                {parsedFirstAid.map((step, i) => <li key={i}>{step}</li>)}
              </ol>
            </div>
          )}

          {/* Notes */}
          <div className="bg-white rounded-xl border border-slate-200 p-5">
            <h3 className="font-semibold text-slate-700 mb-3">Notes</h3>
            {parsedNotes.length === 0 && <p className="text-xs text-slate-400">No notes yet.</p>}
            <div className="space-y-2 mb-3">
              {parsedNotes.map((n, i) => (
                <div key={i} className="text-sm bg-slate-50 p-2 rounded text-slate-700">{n}</div>
              ))}
            </div>
            <div className="flex gap-2">
              <input
                value={noteText} onChange={e => setNoteText(e.target.value)}
                placeholder="Add a note..."
                className="flex-1 p-2 border border-slate-300 rounded-lg text-sm"
              />
              <button onClick={handleAddNote} disabled={actionLoading || !noteText.trim()}
                className="px-4 py-2 bg-teal-600 text-white text-sm rounded-lg hover:bg-teal-700 disabled:opacity-50">
                Add
              </button>
            </div>
          </div>
        </div>

        {/* Right — Actions, donations, adoptions */}
        <div className="w-80 space-y-4">
          {/* Status actions */}
          {actions.length > 0 && (
            <div className="bg-white rounded-xl border border-slate-200 p-5">
              <h3 className="font-semibold text-slate-700 mb-3">Actions</h3>
              <div className="space-y-2">
                {actions.map((a) => (
                  <button key={a.next} onClick={() => handleAdvance(a.next)}
                    disabled={actionLoading}
                    className={`w-full text-white text-sm font-medium py-2 rounded-lg disabled:opacity-50 ${a.color}`}>
                    {actionLoading ? 'Processing...' : a.label}
                  </button>
                ))}
              </div>
            </div>
          )}

          {/* Assignment */}
          {(!c.responderName || user.role === 'NGO') && (
            <div className="bg-white rounded-xl border border-slate-200 p-5">
              <h3 className="font-semibold text-slate-700 mb-3">
                {c.responderName ? 'Reassign' : 'Assign responder'}
              </h3>
              <select
                onChange={(e) => { const v = parseInt(e.target.value); if (v) handleAssign(v); }}
                disabled={actionLoading}
                className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                defaultValue=""
              >
                <option value="" disabled>Select a responder...</option>
                {responders.map((r: any) => <option key={r.id} value={r.id}>{r.name} ({r.email})</option>)}
              </select>
            </div>
          )}

          {/* Donations */}
          <div className="bg-white rounded-xl border border-slate-200 p-5">
            <h3 className="font-semibold text-slate-700 mb-3">Donations</h3>
            {donations.length === 0 ? (
              <p className="text-xs text-slate-400">No donations yet.</p>
            ) : (
              <div className="space-y-2 max-h-48 overflow-y-auto">
                {donations.map((d: any) => (
                  <div key={d.id} className="flex justify-between text-sm">
                    <span className="text-slate-600">{d.donorName}</span>
                    <span className="font-medium text-teal-700">₹{d.amountInr}</span>
                  </div>
                ))}
              </div>
            )}
            <div className="mt-2 text-sm font-medium text-slate-700">
              Total: ₹{donations.reduce((s: number, d: any) => s + d.amountInr, 0).toLocaleString('en-IN')}
            </div>
          </div>

          {/* Adoption applications */}
          <div className="bg-white rounded-xl border border-slate-200 p-5">
            <h3 className="font-semibold text-slate-700 mb-3">Adoption applications</h3>
            {adoptions.length === 0 ? (
              <p className="text-xs text-slate-400">No applications yet.</p>
            ) : (
              <div className="space-y-3">
                {adoptions.map((a: any) => (
                  <div key={a.id} className="border border-slate-100 rounded-lg p-3">
                    <p className="text-sm font-medium text-slate-700">{a.applicantName}</p>
                    <p className="text-xs text-slate-500">{a.contact}</p>
                    <p className="text-xs text-slate-600 mt-1">"{a.reason}"</p>
                    <span className="text-xs font-medium px-2 py-0.5 rounded bg-blue-100 text-blue-700 mt-1 inline-block">
                      {a.status}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
