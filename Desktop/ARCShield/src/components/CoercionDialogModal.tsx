import React, { useState, useEffect } from 'react';
import { ShieldAlert, X, Clock, PhoneCall, CheckCircle2 } from 'lucide-react';

interface CoercionDialogModalProps {
  onClose: () => void;
}

export const CoercionDialogModal: React.FC<CoercionDialogModalProps> = ({ onClose }) => {
  const [secondsLeft, setSecondsLeft] = useState(60);
  const [q1, setQ1] = useState<boolean | null>(null);
  const [q2, setQ2] = useState<boolean | null>(null);

  useEffect(() => {
    if (secondsLeft <= 0) return;
    const t = setInterval(() => setSecondsLeft(p => p - 1), 1000);
    return () => clearInterval(t);
  }, [secondsLeft]);

  const pct = (secondsLeft / 60) * 100;

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in">
      <div className="bg-white rounded-2xl border border-slate-200 w-full max-w-md shadow-2xl overflow-hidden">

        {/* Header */}
        <div className="px-6 pt-6 pb-4">
          <div className="flex items-start justify-between gap-3">
            <div className="flex items-center gap-3">
              <div className="w-11 h-11 rounded-xl bg-rose-100 flex items-center justify-center shrink-0">
                <ShieldAlert size={22} className="text-rose-600" />
              </div>
              <div>
                <span className="text-[10px] font-bold text-rose-700 uppercase tracking-wider bg-rose-50 border border-rose-200 px-2 py-0.5 rounded-full">
                  Mandatory Cooling-off (F-04)
                </span>
                <h3 className="text-[16px] font-bold font-display text-slate-900 mt-1 leading-tight">
                  Coercion & Digital Arrest Warning
                </h3>
              </div>
            </div>
            <button onClick={onClose} className="p-1.5 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition shrink-0">
              <X size={17} />
            </button>
          </div>
        </div>

        {/* Countdown */}
        <div className="mx-6 mb-4 p-4 rounded-xl bg-amber-50 border border-amber-200">
          <div className="flex items-center justify-between mb-2.5">
            <div className="flex items-center gap-2 text-amber-700">
              <Clock size={16} />
              <span className="text-[12px] font-bold">Safety Pause Active</span>
            </div>
            <span className="text-[22px] font-bold font-mono text-amber-800 leading-none">
              00:{secondsLeft < 10 ? `0${secondsLeft}` : secondsLeft}
            </span>
          </div>
          {/* Countdown progress bar */}
          <div className="h-1.5 rounded-full bg-amber-200 overflow-hidden">
            <div
              className="h-full rounded-full bg-amber-500 transition-all duration-1000"
              style={{ width: `${pct}%` }}
            />
          </div>
          <p className="text-[11px] text-amber-600 font-medium mt-2">
            Mandatory reflection window — prevents coerced outbound transfers.
          </p>
        </div>

        {/* Safety Questions */}
        <div className="px-6 space-y-3 mb-4">
          {[
            {
              q: '1. Are you currently on a call with someone claiming to be Police, CBI, ED, or Customs?',
              state: q1, setter: setQ1,
              yesLabel: 'Yes, I am', noLabel: 'No'
            },
            {
              q: '2. Has the caller told you NOT to disclose this payment to your family or bank?',
              state: q2, setter: setQ2,
              yesLabel: 'Yes, they insisted', noLabel: 'No'
            },
          ].map(({ q, state, setter, yesLabel, noLabel }, i) => (
            <div key={i} className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-2.5">
              <p className="text-[12px] font-medium text-slate-800 leading-snug">{q}</p>
              <div className="flex gap-2">
                <button
                  onClick={() => setter(true)}
                  className={`flex-1 py-2 text-[12px] font-bold rounded-xl border transition ${
                    state === true
                      ? 'bg-rose-50 text-rose-700 border-rose-300'
                      : 'bg-white text-slate-500 border-slate-300 hover:border-slate-400'
                  }`}
                >
                  {yesLabel}
                </button>
                <button
                  onClick={() => setter(false)}
                  className={`flex-1 py-2 text-[12px] font-bold rounded-xl border transition ${
                    state === false
                      ? 'bg-emerald-50 text-emerald-700 border-emerald-300'
                      : 'bg-white text-slate-500 border-slate-300 hover:border-slate-400'
                  }`}
                >
                  {noLabel}
                </button>
              </div>
            </div>
          ))}
        </div>

        {/* Helpline CTA */}
        <div className="px-6 mb-4">
          <a
            href="tel:1930"
            className="w-full py-3 rounded-xl bg-rose-600 hover:bg-rose-700 text-white text-[13px] font-bold flex items-center justify-center gap-2 transition shadow-glow-rose"
          >
            <PhoneCall size={16} />
            Dial 1930 — National Cyber Fraud Helpline (Free)
          </a>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-between">
          <button onClick={onClose} className="text-[12px] font-semibold text-slate-500 hover:text-slate-800 transition">
            I disconnected the fraud call
          </button>
          <button
            disabled={secondsLeft > 0}
            onClick={onClose}
            className={`px-5 py-2 rounded-xl text-[12px] font-bold transition ${
              secondsLeft > 0
                ? 'bg-slate-100 text-slate-400 cursor-not-allowed'
                : 'bg-blue-600 hover:bg-blue-700 text-white'
            }`}
          >
            {secondsLeft > 0 ? `Wait ${secondsLeft}s` : 'Proceed'}
          </button>
        </div>
      </div>
    </div>
  );
};
