import React, { useState, useEffect } from 'react';
import { Sliders, X, Sparkles, ArrowRight, RotateCcw, Zap } from 'lucide-react';
import { AlertItem } from './AlertFeed';
import { apiUrl } from '../config';

interface CounterfactualSliderProps {
  alert: AlertItem | null;
  onClose: () => void;
}

export const CounterfactualSlider: React.FC<CounterfactualSliderProps> = ({ alert, onClose }) => {
  if (!alert) return null;

  const [amount, setAmount] = useState(alert.amount);
  const [deviceKnown, setDeviceKnown] = useState(false);
  const [coercionFlag, setCoercionFlag] = useState(false);
  const [simScore, setSimScore] = useState(alert.riskScore);
  const [simBand, setSimBand] = useState(alert.riskBand as string);

  useEffect(() => {
    let cancelled = false;

    const fallbackScore = () => {
      let score = alert.riskScore;
      if (amount < 2000) score -= 35;
      else if (amount < 10000) score -= 15;
      else if (amount > 50000) score += 12;
      if (deviceKnown) score -= 28;
      if (coercionFlag) score = Math.max(score, 96);
      score = Math.max(4, Math.min(99, score));
      if (!cancelled) {
        setSimScore(score);
        setSimBand(score >= 70 ? 'HIGH' : score >= 40 ? 'MEDIUM' : 'LOW');
      }
    };

    const fetchCounterfactual = async () => {
      try {
        const response = await fetch(apiUrl('/counterfactual'), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            transaction: {
              transaction_id: alert.transactionId,
              account_id: 'acc-user-target',
              counterparty: alert.counterparty,
              amount: alert.amount,
              direction: alert.direction,
              device_id: deviceKnown ? 'dev-primary-01' : 'dev-new-suspicious-99',
              coercion_answers: {
                safe_account_claim: coercionFlag,
                urgent_request: coercionFlag,
                secrecy_request: coercionFlag,
              },
            },
            overrides: {
              amount,
              device_id: deviceKnown ? 'dev-primary-01' : 'dev-new-suspicious-99',
              coercion_answers: {
                safe_account_claim: coercionFlag,
                urgent_request: coercionFlag,
                secrecy_request: coercionFlag,
              },
            },
          }),
        });

        if (!response.ok) {
          throw new Error('Counterfactual request failed');
        }

        const data = await response.json();
        if (cancelled) return;

        setSimScore(data.simulated_risk_score ?? alert.riskScore);
        setSimBand(data.simulated_risk_band ?? (data.simulated_risk_score >= 70 ? 'HIGH' : data.simulated_risk_score >= 40 ? 'MEDIUM' : 'LOW'));
      } catch {
        fallbackScore();
      }
    };

    fetchCounterfactual();
    return () => {
      cancelled = true;
    };
  }, [alert, amount, deviceKnown, coercionFlag]);

  const delta = simScore - alert.riskScore;
  const deltaColor = delta <= 0 ? 'text-emerald-700' : 'text-rose-700';
  const deltaLabel = delta > 0 ? `+${delta}` : `${delta}`;

  const bandColor = (b: string) =>
    b === 'HIGH' ? 'text-rose-700' : b === 'MEDIUM' ? 'text-amber-700' : 'text-emerald-700';

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in">
      <div className="bg-white rounded-2xl border border-slate-200 w-full max-w-lg shadow-2xl overflow-hidden">

        {/* Header */}
        <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
              <Sliders size={20} className="text-blue-600" />
            </div>
            <div>
              <h3 className="text-[15px] font-bold font-display text-slate-900">Counterfactual What-If Simulator</h3>
              <p className="text-[12px] text-slate-400 font-medium mt-0.5">Adjust parameters to observe live risk shifts</p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition">
            <X size={17} />
          </button>
        </div>

        {/* Score Comparison Banner */}
        <div className="mx-6 mt-5 p-4 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between gap-4">
          <div>
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider">Original</p>
            <p className="text-[20px] font-bold font-mono text-slate-900 mt-0.5 leading-none">
              {alert.riskScore}
              <span className={`text-[14px] ml-1.5 ${bandColor(alert.riskBand)}`}>{alert.riskBand}</span>
            </p>
          </div>
          <div className="flex flex-col items-center">
            <ArrowRight size={18} className="text-slate-300" />
            <span className={`text-[12px] font-bold font-mono ${deltaColor} mt-1`}>{deltaLabel}</span>
          </div>
          <div className="text-right">
            <p className="text-[10px] text-slate-400 font-bold uppercase tracking-wider flex items-center justify-end gap-1">
              <Sparkles size={10} className="text-blue-500" /> Simulated
            </p>
            <p className="text-[20px] font-bold font-mono text-slate-900 mt-0.5 leading-none">
              {simScore}
              <span className={`text-[14px] ml-1.5 ${bandColor(simBand)}`}>{simBand}</span>
            </p>
          </div>
        </div>

        {/* Score gauge */}
        <div className="mx-6 mt-3">
          <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
            <div
              className={`h-full rounded-full transition-all duration-500 ${
                simBand === 'HIGH' ? 'bg-rose-500' : simBand === 'MEDIUM' ? 'bg-amber-500' : 'bg-emerald-500'
              }`}
              style={{ width: `${simScore}%` }}
            />
          </div>
        </div>

        {/* Controls */}
        <div className="px-6 py-5 space-y-4">

          {/* Amount Slider */}
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-3">
            <div className="flex justify-between items-center text-[12px]">
              <span className="font-semibold text-slate-700">Transaction Amount</span>
              <span className="font-bold font-mono text-blue-700">₹{amount.toLocaleString('en-IN')}</span>
            </div>
            <input
              type="range"
              min={500} max={150000} step={500}
              value={amount}
              onChange={e => setAmount(Number(e.target.value))}
            />
            <div className="flex justify-between text-[10px] font-mono text-slate-400">
              <span>₹500 (Micro)</span><span>₹50,000</span><span>₹1,50,000</span>
            </div>
          </div>

          {/* Toggle: Device Fingerprint */}
          <div className="flex items-center justify-between p-4 rounded-xl bg-slate-50 border border-slate-200">
            <div>
              <p className="text-[13px] font-semibold text-slate-800">Device Fingerprint</p>
              <p className="text-[11px] text-slate-400 font-medium mt-0.5">Is this the primary trusted device?</p>
            </div>
            <button
              onClick={() => setDeviceKnown(!deviceKnown)}
              className={`px-4 py-1.5 rounded-xl text-[12px] font-bold border transition ${
                deviceKnown
                  ? 'bg-emerald-50 text-emerald-700 border-emerald-300'
                  : 'bg-white text-slate-500 border-slate-300 hover:border-slate-400'
              }`}
            >
              {deviceKnown ? 'Known Device' : 'New Device'}
            </button>
          </div>

          {/* Toggle: Coercion Flag */}
          <div className="flex items-center justify-between p-4 rounded-xl bg-slate-50 border border-slate-200">
            <div>
              <p className="text-[13px] font-semibold text-slate-800">Digital Arrest / Impersonation</p>
              <p className="text-[11px] text-slate-400 font-medium mt-0.5">Sent to "safe police account"?</p>
            </div>
            <button
              onClick={() => setCoercionFlag(!coercionFlag)}
              className={`px-4 py-1.5 rounded-xl text-[12px] font-bold border transition ${
                coercionFlag
                  ? 'bg-rose-50 text-rose-700 border-rose-300'
                  : 'bg-white text-slate-500 border-slate-300 hover:border-slate-400'
              }`}
            >
              {coercionFlag ? 'Coercion Flagged' : 'No Coercion'}
            </button>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-between">
          <button
            onClick={() => { setAmount(alert.amount); setDeviceKnown(false); setCoercionFlag(false); }}
            className="flex items-center gap-1.5 text-[12px] font-semibold text-slate-500 hover:text-slate-800 transition"
          >
            <RotateCcw size={13} /> Reset
          </button>
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-[12px] font-bold transition shadow-glow-blue"
          >
            Done
          </button>
        </div>
      </div>
    </div>
  );
};
