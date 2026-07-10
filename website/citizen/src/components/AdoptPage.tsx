import React, { useEffect, useState } from 'react';
import { getOpenCases, applyForAdoption, subscribeToCaseUpdates } from '../api';

interface AdoptionFormState {
  applicantName: string;
  contact: string;
  reason: string;
}

const EMPTY_FORM: AdoptionFormState = {
  applicantName: '',
  contact: '',
  reason: '',
};

export const AdoptPage: React.FC = () => {
  const [cases, setCases] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCaseId, setSelectedCaseId] = useState<number | null>(null);
  const [submitting, setSubmitting] = useState<number | null>(null);
  const [form, setForm] = useState<AdoptionFormState>(EMPTY_FORM);
  const [notice, setNotice] = useState('');
  const [error, setError] = useState('');

  useEffect(() => {
    const loadCases = (showLoading = false) => {
      if (showLoading) setLoading(true);
      getOpenCases().then((all) => {
        // Only show adoptable cases
        setCases(all.filter((c: any) => c.status === 'discharged' || c.status === 'in_treatment'));
      }).catch(() => {}).finally(() => {
        if (showLoading) setLoading(false);
      });
    };
    loadCases(true);
    return subscribeToCaseUpdates(() => loadCases(false));
  }, []);

  const startApplication = (caseId: number) => {
    setSelectedCaseId(caseId);
    setForm(EMPTY_FORM);
    setNotice('');
    setError('');
  };

  const handleApply = async (caseId: number) => {
    const applicantName = form.applicantName.trim();
    const contact = form.contact.trim();
    const reason = form.reason.trim();
    if (!applicantName || !contact || !reason) {
      setError('Name, contact, and reason are required.');
      return;
    }
    setSubmitting(caseId);
    setNotice('');
    setError('');
    try {
      await applyForAdoption(caseId, { applicantName, contact, reason });
      const openCases = await getOpenCases();
      setCases(openCases.filter((c: any) => c.status === 'discharged' || c.status === 'in_treatment'));
      setNotice('Application submitted. The NGO team will review it.');
      setSelectedCaseId(null);
      setForm(EMPTY_FORM);
    } catch (err: any) {
      setError(err.message || 'Application failed.');
    } finally {
      setSubmitting(null);
    }
  };

  if (loading) return <p className="text-center text-slate-500 mt-8">Loading...</p>;

  return (
    <div className="max-w-4xl mx-auto">
      <h2 className="text-xl font-bold text-teal-800 mb-4">Adopt an animal</h2>
      {notice && <div className="mb-4 text-sm text-green-700 bg-green-50 border border-green-200 rounded-lg p-3">{notice}</div>}
      {error && <div className="mb-4 text-sm text-red-700 bg-red-50 border border-red-200 rounded-lg p-3">{error}</div>}
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
              {selectedCaseId === c.id ? (
                <form
                  onSubmit={(event) => {
                    event.preventDefault();
                    handleApply(c.id);
                  }}
                  className="mt-4 border-t border-slate-100 pt-4 space-y-3"
                >
                  <div className="grid sm:grid-cols-2 gap-3">
                    <div>
                      <label htmlFor={`adopter-name-${c.id}`} className="block text-xs font-medium text-slate-600 mb-1">Name</label>
                      <input
                        id={`adopter-name-${c.id}`}
                        value={form.applicantName}
                        onChange={(event) => setForm({ ...form, applicantName: event.target.value })}
                        className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                        placeholder="Your name"
                        required
                      />
                    </div>
                    <div>
                      <label htmlFor={`adopter-contact-${c.id}`} className="block text-xs font-medium text-slate-600 mb-1">Contact</label>
                      <input
                        id={`adopter-contact-${c.id}`}
                        value={form.contact}
                        onChange={(event) => setForm({ ...form, contact: event.target.value })}
                        className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                        placeholder="Phone or email"
                        required
                      />
                    </div>
                  </div>
                  <div>
                    <label htmlFor={`adopter-reason-${c.id}`} className="block text-xs font-medium text-slate-600 mb-1">Reason</label>
                    <textarea
                      id={`adopter-reason-${c.id}`}
                      value={form.reason}
                      onChange={(event) => setForm({ ...form, reason: event.target.value })}
                      className="w-full p-2 border border-slate-300 rounded-lg text-sm"
                      rows={3}
                      placeholder="Briefly describe your adoption plan"
                      required
                    />
                  </div>
                  <div className="flex gap-2">
                    <button type="submit" disabled={submitting === c.id}
                      className="flex-1 bg-emerald-600 text-white text-sm font-medium py-2 rounded-lg hover:bg-emerald-700 disabled:opacity-50">
                      {submitting === c.id ? 'Submitting...' : 'Submit application'}
                    </button>
                    <button type="button" onClick={() => setSelectedCaseId(null)}
                      className="px-4 py-2 border border-slate-300 text-slate-600 text-sm rounded-lg hover:bg-slate-50">
                      Cancel
                    </button>
                  </div>
                </form>
              ) : (
                <button onClick={() => startApplication(c.id)}
                  className="mt-3 w-full bg-emerald-600 text-white text-sm font-medium py-2 rounded-lg hover:bg-emerald-700">
                  Apply to adopt
                </button>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
