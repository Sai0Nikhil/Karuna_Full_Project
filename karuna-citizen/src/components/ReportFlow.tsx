import React, { useState, useCallback } from 'react';
import { createCase } from '../api';

interface Props { user: any; onNeedLogin: () => void; }

export const ReportFlow: React.FC<Props> = ({ user, onNeedLogin }) => {
  const [imageDataUrl, setImageDataUrl] = useState<string | null>(null);
  const [description, setDescription] = useState('');
  const [locationLabel, setLocationLabel] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<any>(null);

  const handleFile = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onloadend = () => setImageDataUrl(reader.result as string);
    reader.readAsDataURL(file);
  };

  const handleSubmit = useCallback(async () => {
    if (!user) { onNeedLogin(); return; }
    if (!imageDataUrl || !locationLabel) { setError('Please upload a photo and enter location.'); return; }
    setLoading(true);
    setError('');
    try {
      // Send to backend — AI triage handled server-side
      const c = await createCase({
        imageDataUrl,
        locationLabel,
        latitude: null,
        longitude: null,
        species: 'dog',
        injuryType: 'unknown',
        severity: 'routine',
        probableCondition: description || 'Injured animal reported',
        firstAidSteps: '[]',
        estimatedCostInr: 1500,
      });
      setResult(c);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [imageDataUrl, locationLabel, description, user]);

  return (
    <div className="max-w-2xl mx-auto bg-white rounded-xl shadow-md p-6 space-y-4">
      <h2 className="text-xl font-bold text-teal-800">Report an injured animal</h2>

      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">Upload photo</label>
        <input type="file" accept="image/*" capture="environment" onChange={handleFile}
          className="w-full p-2 border border-slate-300 rounded-lg" />
        {imageDataUrl && <img src={imageDataUrl} alt="preview" className="mt-2 max-h-48 rounded object-cover" />}
      </div>

      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">Location</label>
        <input type="text" value={locationLabel} onChange={(e) => setLocationLabel(e.target.value)}
          placeholder="e.g. Labbipet, Vijayawada"
          className="w-full p-2.5 border border-slate-300 rounded-lg" />
      </div>

      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">Describe the situation (optional)</label>
        <textarea value={description} onChange={(e) => setDescription(e.target.value)}
          placeholder="e.g. Dog is limping, wound on back leg"
          rows={3} className="w-full p-2.5 border border-slate-300 rounded-lg" />
      </div>

      {error && <div className="text-red-600 text-sm bg-red-50 p-3 rounded-lg">{error}</div>}

      <button onClick={handleSubmit} disabled={loading || !imageDataUrl}
        className="w-full bg-teal-600 text-white font-bold py-3 rounded-lg hover:bg-teal-700 disabled:opacity-50">
        {loading ? 'Submitting...' : user ? 'Submit report' : 'Sign in to submit'}
      </button>

      {result && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4">
          <h3 className="font-semibold text-green-800">Report submitted ✓</h3>
          <p className="text-sm text-green-700 mt-1">Case #{result.id} — {result.status}</p>
        </div>
      )}
    </div>
  );
};
