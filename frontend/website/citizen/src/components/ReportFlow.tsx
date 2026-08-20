import React, { useState, useCallback } from 'react';
import { aiTriage, createCase } from '../api';

interface Props { user: any; onNeedLogin: () => void; }

export const ReportFlow: React.FC<Props> = ({ user, onNeedLogin }) => {
  const [imageDataUrl, setImageDataUrl] = useState<string | null>(null);
  const [description, setDescription] = useState('');
  const [locationLabel, setLocationLabel] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [result, setResult] = useState<any>(null);
  const [triageResult, setTriageResult] = useState<any>(null);

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
      const triage = await aiTriage({
        imageDataUrl,
        description,
        species: 'dog',
        locationLabel,
      });
      setTriageResult(triage);
      // Send to backend — AI triage handled server-side
      const c = await createCase({
        imageDataUrl,
        locationLabel,
        latitude: null,
        longitude: null,
        species: 'dog',
        injuryType: 'unknown',
        severity: triage?.severity || 'routine',
        probableCondition: triage?.probableCondition || description || 'Injured animal reported',
        firstAidSteps: JSON.stringify(triage?.firstAidSteps || []),
        estimatedCostInr: 1500,
      });
      setResult(c);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, [imageDataUrl, locationLabel, description, user]);

  const downloadCertificate = () => {
    if (!result) return;
    const jspdfModule = (window as any).jspdf;
    if (!jspdfModule) {
      alert('PDF library is loading, please try again.');
      return;
    }
    const { jsPDF } = jspdfModule;
    const doc = new jsPDF({
      orientation: 'landscape',
      unit: 'px',
      format: [640, 480]
    });

    const name = user?.name || 'Anonymous Compassionate Citizen';
    const dateStr = new Date().toLocaleDateString('en-IN', {
      day: 'numeric',
      month: 'long',
      year: 'numeric'
    });

    // Draw background color
    doc.setFillColor(248, 250, 253);
    doc.rect(0, 0, 640, 480, 'F');

    // Draw gold borders
    doc.setDrawColor(217, 119, 6);
    doc.setLineWidth(6);
    doc.rect(20, 20, 600, 440);

    doc.setDrawColor(15, 118, 110);
    doc.setLineWidth(1.5);
    doc.rect(26, 26, 588, 428);

    // Title
    doc.setTextColor(15, 118, 110);
    doc.setFont('Helvetica', 'bold');
    doc.setFontSize(26);
    doc.text('CERTIFICATE OF APPRECIATION', 320, 75, { align: 'center' });

    // Sub-title
    doc.setTextColor(100, 116, 139);
    doc.setFont('Helvetica', 'normal');
    doc.setFontSize(12);
    doc.text('THIS CERTIFICATE IS PROUDLY PRESENTED TO', 320, 110, { align: 'center' });

    // Recipient Name
    doc.setTextColor(30, 41, 59);
    doc.setFont('Helvetica', 'bold');
    doc.setFontSize(22);
    doc.text(name, 320, 155, { align: 'center' });

    // Inner underline for name
    doc.setDrawColor(15, 118, 110);
    doc.setLineWidth(1);
    doc.line(180, 165, 460, 165);

    // Appreciation Text
    doc.setTextColor(71, 85, 105);
    doc.setFont('Helvetica', 'normal');
    doc.setFontSize(12);
    const appreciationText = 
      "For showing outstanding compassion, care, and prompt action in reporting " +
      "an animal in distress to the Karuṇā Rescue Network. Your immediate support " +
      "has directly contributed to saving a life and making the world a kinder place.";
    const splitText = doc.splitTextToSize(appreciationText, 480);
    doc.text(splitText, 320, 200, { align: 'center' });

    // Details Box
    doc.setFillColor(241, 245, 249);
    doc.rect(80, 275, 480, 50, 'F');
    doc.setDrawColor(226, 231, 240);
    doc.rect(80, 275, 480, 50);

    doc.setTextColor(100, 116, 139);
    doc.setFontSize(10);
    doc.text('CASE IDENTIFIER', 180, 292, { align: 'center' });
    doc.text('DATE OF SUBMISSION', 440, 292, { align: 'center' });

    doc.setTextColor(15, 118, 110);
    doc.setFont('Helvetica', 'bold');
    doc.setFontSize(11);
    doc.text(`CASE #${result.id}`, 180, 312, { align: 'center' });
    doc.text(dateStr, 440, 312, { align: 'center' });

    // Signature Area
    doc.setDrawColor(15, 118, 110);
    doc.setLineWidth(1);
    doc.line(260, 385, 380, 385);
    
    doc.setTextColor(100, 116, 139);
    doc.setFont('Helvetica', 'normal');
    doc.setFontSize(10);
    doc.text('Karuṇā Team Signatory', 320, 398, { align: 'center' });

    // Logo / Seal stamp
    doc.setTextColor(217, 119, 6);
    doc.setFont('Helvetica', 'bold');
    doc.setFontSize(18);
    doc.text('🐾', 320, 422, { align: 'center' });

    doc.save(`Karuna_Certificate_${result.id}.pdf`);
  };

  return (
    <div className="max-w-2xl mx-auto bg-white rounded-xl shadow-md p-6 space-y-4">
      <h2 className="text-xl font-bold text-teal-800">Report an injured animal</h2>

      <div>
        <label className="block text-sm font-medium text-slate-700 mb-1">Upload photo</label>
        <input type="file" accept="image/*" onChange={handleFile} aria-label="Upload animal photo"
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

      {triageResult && (
        <div className="bg-slate-50 border border-slate-200 rounded-lg p-4">
          <p className="text-xs uppercase tracking-wider text-slate-500 mb-1">AI triage</p>
          <p className="font-medium text-slate-800">{triageResult.probableCondition}</p>
          <p className="text-sm text-slate-600 mt-1">Suggested severity: <span className="font-semibold">{triageResult.severity}</span></p>
        </div>
      )}

      <button onClick={handleSubmit} disabled={loading || !imageDataUrl}
        className="w-full bg-teal-600 text-white font-bold py-3 rounded-lg hover:bg-teal-700 disabled:opacity-50">
        {loading ? 'Submitting...' : user ? 'Submit report' : 'Sign in to submit'}
      </button>

      {result && (
        <div className="bg-green-50 border border-green-200 rounded-lg p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h3 className="font-semibold text-green-800">Report submitted ✓</h3>
            <p className="text-sm text-green-700 mt-1">Case #{result.id} — {result.status}</p>
          </div>
          <button
            onClick={downloadCertificate}
            className="bg-teal-600 text-white text-sm font-bold py-2 px-4 rounded-lg hover:bg-teal-700 transition whitespace-nowrap"
          >
            Download Certificate 📜
          </button>
        </div>
      )}
    </div>
  );
};
