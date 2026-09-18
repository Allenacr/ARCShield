import React from 'react';
import { Briefcase, Clock, CheckCircle2, Lock, AlertTriangle, FileText } from 'lucide-react';

export interface CaseItem {
  id: string;
  caseNumber: string;
  accountId: string;
  heldAmount: number;
  status: 'OPEN' | 'IN_INVESTIGATION' | 'RESOLVED_FRAUD' | 'RESOLVED_LEGITIMATE';
  proactiveHoldTime: string;
  reason: string;
}

interface CaseManagementProps {
  cases: CaseItem[];
  onStatusChange: (caseId: string, status: CaseItem['status']) => void;
}

const STATUS_CONFIG = {
  OPEN:               { label: 'Open',          bg: 'bg-amber-50',   border: 'border-amber-200',   text: 'text-amber-700'  },
  IN_INVESTIGATION:   { label: 'Investigating', bg: 'bg-blue-50',    border: 'border-blue-200',    text: 'text-blue-700'   },
  RESOLVED_FRAUD:     { label: 'Fraud',         bg: 'bg-rose-50',    border: 'border-rose-200',    text: 'text-rose-700'   },
  RESOLVED_LEGITIMATE:{ label: 'Legitimate',    bg: 'bg-emerald-50', border: 'border-emerald-200', text: 'text-emerald-700'},
};

export const CaseManagement: React.FC<CaseManagementProps> = ({ cases, onStatusChange }) => {
  return (
    <div className="card p-6 space-y-5 animate-slide-up">
      {/* Header */}
      <div className="flex items-center justify-between pb-5 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-amber-100 flex items-center justify-center">
            <Briefcase size={19} className="text-amber-600" />
          </div>
          <div>
            <h2 className="text-[15px] font-bold font-display text-slate-900 leading-tight">
              Quarantine Ledger Cases
            </h2>
            <p className="text-[12px] text-slate-400 font-medium mt-0.5">
              24-hour isolation holds under double-entry ledger rules
            </p>
          </div>
        </div>
        <span className="px-3 py-1.5 rounded-xl text-[12px] font-mono font-bold bg-amber-50 text-amber-700 border border-amber-200">
          {cases.length} Active
        </span>
      </div>

      {cases.length === 0 ? (
        <div className="py-20 text-center text-slate-400">
          <FileText size={32} className="mx-auto mb-3 opacity-30" />
          <p className="text-[13px] font-medium">No quarantine cases yet.</p>
          <p className="text-[12px] text-slate-300 mt-1">Enforce a 24h hold from the investigation panel.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {cases.map(c => {
            const st = STATUS_CONFIG[c.status];
            return (
              <div key={c.id} className="rounded-2xl border border-slate-200 bg-white overflow-hidden hover:shadow-card transition-all">
                {/* Case Top Banner */}
                <div className="px-5 py-3.5 bg-slate-50 border-b border-slate-200 flex flex-wrap items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5">
                    <span className="font-mono text-[11px] font-bold text-blue-700 bg-blue-50 border border-blue-200 px-2.5 py-0.5 rounded-full">
                      {c.caseNumber}
                    </span>
                    <span className="text-[12px] text-slate-500">
                      Account: <span className="text-slate-800 font-mono font-semibold">{c.accountId}</span>
                    </span>
                  </div>
                  <span className={`pill-btn ${st.bg} ${st.border} ${st.text} border`}>
                    {st.label}
                  </span>
                </div>

                {/* Case Body */}
                <div className="p-5 space-y-4">
                  {/* Amounts */}
                  <div className="grid grid-cols-2 gap-3">
                    <div className="p-4 rounded-xl bg-slate-50 border border-slate-200">
                      <p className="text-[11px] text-slate-400 font-medium">Quarantined Amount</p>
                      <p className="text-[20px] font-bold font-mono text-rose-700 mt-1 leading-none">
                        ₹{c.heldAmount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                      </p>
                    </div>
                    <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200">
                      <p className="text-[11px] text-emerald-600 font-bold">Safe Harbor Status</p>
                      <p className="text-[12px] font-semibold text-emerald-800 mt-2 flex items-center gap-1.5">
                        <CheckCircle2 size={14} />
                        Flagged Before Spend
                      </p>
                    </div>
                  </div>

                  {/* Evidence note */}
                  <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 text-[12px] text-slate-700 leading-relaxed">
                    <span className="font-bold text-slate-900">Evidence: </span>
                    {c.reason}
                  </div>

                  {/* Footer */}
                  <div className="flex flex-wrap items-center justify-between gap-3 pt-2 border-t border-slate-100">
                    <span className="flex items-center gap-1.5 text-[11px] text-amber-700 font-semibold">
                      <Clock size={13} />
                      Cooling-off: 23h 14m remaining
                    </span>
                    <div className="flex items-center gap-2">
                      {c.status === 'OPEN' && (
                        <button
                          onClick={() => onStatusChange(c.id, 'IN_INVESTIGATION')}
                          className="px-4 py-1.5 rounded-xl text-[12px] font-semibold border border-blue-200 bg-blue-50 hover:bg-blue-100 text-blue-700 transition"
                        >
                          Start investigation
                        </button>
                      )}
                      {c.status === 'IN_INVESTIGATION' && (
                        <button
                          onClick={() => onStatusChange(c.id, 'RESOLVED_LEGITIMATE')}
                          className="px-4 py-1.5 rounded-xl text-[12px] font-semibold border border-emerald-200 bg-emerald-50 hover:bg-emerald-100 text-emerald-700 transition"
                        >
                          Release to user
                        </button>
                      )}
                      {c.status === 'IN_INVESTIGATION' && (
                        <button
                          onClick={() => onStatusChange(c.id, 'RESOLVED_FRAUD')}
                          className="px-4 py-1.5 rounded-xl text-[12px] font-semibold bg-rose-600 hover:bg-rose-700 text-white transition flex items-center gap-1.5"
                        >
                          <Lock size={12} />
                          Refund to victim
                        </button>
                      )}
                      {c.status === 'OPEN' && (
                        <span className="text-[11px] text-slate-400">Assign an analyst to resolve this hold.</span>
                      )}
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
