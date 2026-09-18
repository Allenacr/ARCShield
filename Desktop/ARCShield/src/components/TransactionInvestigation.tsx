import React, { useState, useEffect } from 'react';
import { AlertItem } from './AlertFeed';
import {
  ShieldCheck,
  BrainCircuit,
  Network,
  Sliders,
  Info,
  Lock,
  CheckCircle2,
  Copy,
  Check,
  Scale,
  Clock,
  AlertTriangle,
  ChevronRight,
  Zap,
  Loader2,
} from 'lucide-react';
import { apiUrl } from '../config';

interface TransactionInvestigationProps {
  alert: AlertItem | null;
  onOpenCounterfactual: () => void;
  onOpenGraph: () => void;
  onQuarantineSuccess?: (txId: string) => void;
  onScoreUpdated?: (txId: string, riskScore: number, riskBand: string, latencyMs: number) => void;
}

interface ScoreResponse {
  transaction_id: string;
  direction: string;
  risk_score: number;
  risk_band: string;
  recommended_action: string;
  model_version: string;
  reason_codes: string[];
  shap_top: [string, number][];
  latency_ms: number;
}

/* ─── Section Header ────────────────────────────── */
function SectionLabel({ icon: Icon, label, right }: {
  icon: React.ElementType; label: string; right?: React.ReactNode;
}) {
  return (
    <div className="flex items-center justify-between mb-3">
      <div className="flex items-center gap-2">
        <Icon size={15} className="text-blue-600 shrink-0" />
        <span className="text-[12px] font-bold font-display text-slate-700 uppercase tracking-wider">{label}</span>
      </div>
      {right}
    </div>
  );
}

/* ─── SHAP Bar Row ──────────────────────────────── */
function ShapRow({ name, impact, color }: { name: string; impact: number; color: string }) {
  // Format technical feature key to human-readable label
  const readableName = name
    .replace(/_/g, ' ')
    .replace(/\b\w/g, c => c.toUpperCase())
    .replace('Proximity Hops', 'FIR Proximity Hops')
    .replace('Seen Before', 'Prior Interaction')
    .replace('Pass Through Ratio', 'Pass-Through Velocity')
    .replace('Safe Account Claim', 'Coercion: Safe Account Claim')
    .replace('New Device Before Transfer', 'Unrecognized Device Inflow')
    .replace('Escalating Amounts', 'Escalating Sequence Drift')
    .replace('Threshold Avoidance Score', 'Structuring Threshold Proximity');

  return (
    <div className="flex items-center gap-3 py-2 border-b border-slate-100 last:border-none">
      <div className="flex-1 min-w-0">
        <p className="text-[12px] font-medium text-slate-700 truncate leading-tight" title={readableName}>{readableName}</p>
      </div>
      <div className="flex items-center gap-2.5 shrink-0">
        <div className="w-24 h-1.5 rounded-full bg-slate-100 overflow-hidden">
          <div className={`${color} h-full rounded-full transition-all duration-700`} style={{ width: `${Math.min(100, Math.max(10, impact * 100))}%` }} />
        </div>
        <span className="text-[11px] font-mono font-bold text-blue-700 w-12 text-right">+{impact.toFixed(2)}</span>
      </div>
    </div>
  );
}

export const TransactionInvestigation: React.FC<TransactionInvestigationProps> = ({
  alert,
  onOpenCounterfactual,
  onOpenGraph,
  onQuarantineSuccess,
  onScoreUpdated,
}) => {
  const [copied, setCopied]                         = useState(false);
  const [isQuarantining, setIsQuarantining]         = useState(false);
  const [quarantinePlaced, setQuarantinePlaced]     = useState(false);
  const [quarantineError, setQuarantineError]       = useState<string | null>(null);
  const [simulatedAmount, setSimulatedAmount]       = useState<number>(alert ? alert.amount : 42000);
  const [liveSimScore, setLiveSimScore]             = useState<number>(alert ? alert.riskScore : 92);
  const [isScoring, setIsScoring]                   = useState(false);
  const [apiData, setApiData]                       = useState<ScoreResponse | null>(null);

  // Call live FastAPI /transactions/score on alert change
  useEffect(() => {
    if (!alert) return;
    setSimulatedAmount(alert.amount);
    setLiveSimScore(alert.riskScore);
    setQuarantinePlaced(false);
    setQuarantineError(null);
    setIsScoring(true);

    const fetchScore = async () => {
      try {
        const res = await fetch(apiUrl('/transactions/score'), {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            transaction_id: alert.transactionId,
            account_id: 'acc-user-target',
            counterparty: alert.counterparty,
            amount: alert.amount,
            direction: alert.direction,
            device_id: 'dev-primary-01',
          }),
        });
        if (res.ok) {
          const data: ScoreResponse = await res.json();
          setApiData(data);
          setLiveSimScore(data.risk_score);
          if (onScoreUpdated) {
            onScoreUpdated(alert.transactionId, data.risk_score, data.risk_band, data.latency_ms);
          }
        }
      } catch (err) {
        console.warn('FastAPI scoring fallback:', err);
      } finally {
        setIsScoring(false);
      }
    };

    fetchScore();
  }, [alert?.transactionId, alert?.amount, alert?.direction]);

  const handleAmountSlider = async (v: number) => {
    setSimulatedAmount(v);
    if (!alert) return;
    try {
      const res = await fetch(apiUrl('/counterfactual'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          transaction: {
            transaction_id: alert.transactionId,
            account_id: 'acc-user-target',
            counterparty: alert.counterparty,
            amount: alert.amount,
            direction: alert.direction,
          },
          overrides: { amount: v },
        }),
      });
      if (res.ok) {
        const data = await res.json();
        setLiveSimScore(data.simulated_risk_score);
        return;
      }
    } catch {
      // client-side fallback simulation if server unavailable
    }
    let score = alert.riskScore;
    if (v < 2000)       score -= 35;
    else if (v < 10000) score -= 18;
    else if (v > 60000) score += 10;
    setLiveSimScore(Math.max(5, Math.min(99, score)));
  };

  const handleQuarantine = async () => {
    setIsQuarantining(true);
    setQuarantineError(null);
    try {
      const res = await fetch(apiUrl('/quarantine'), {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          transaction_id: alert!.transactionId,
          account_id: 'acc-user-target',
          amount: alert!.amount,
          reason: `Analyst enforced 24-hr hold on ${alert!.riskBand} risk alert`,
        }),
      });
      if (!res.ok) throw new Error('The backend rejected the quarantine request.');
      setQuarantinePlaced(true);
      if (onQuarantineSuccess) onQuarantineSuccess(alert!.transactionId);
    } catch (error) {
      setQuarantineError(error instanceof Error ? error.message : 'Unable to enforce the hold.');
      setQuarantinePlaced(false);
    } finally {
      setIsQuarantining(false);
    }
  };

  /* ── Empty State ── */
  if (!alert) {
    return (
      <div className="card flex flex-col items-center justify-center text-center p-14" style={{ minHeight: '560px' }}>
        <div className="w-14 h-14 rounded-2xl bg-slate-100 flex items-center justify-center mb-4">
          <Info size={26} className="text-slate-300" />
        </div>
        <h3 className="text-[15px] font-bold font-display text-slate-700">Select a Transaction</h3>
        <p className="text-[12px] text-slate-400 font-medium max-w-xs mt-2 leading-relaxed">
          Click any transaction in the feed to open the forensic dossier — SHAP attribution, topology hops, and quarantine ledger.
        </p>
      </div>
    );
  }

  const isIncoming = alert.direction === 'INCOMING';
  const currentRiskScore = apiData ? apiData.risk_score : alert.riskScore;
  const currentRiskBand = apiData ? apiData.risk_band : alert.riskBand;
  const riskColor = currentRiskBand === 'HIGH' ? 'rose' : currentRiskBand === 'MEDIUM' ? 'amber' : 'emerald';

  // Dynamic SHAP from API with rich fallback
  const shapFeatures = (apiData && apiData.shap_top && apiData.shap_top.length > 0)
    ? apiData.shap_top.map(([name, impact], idx) => ({
        name,
        impact,
        color: idx === 0 ? 'bg-rose-500' : idx === 1 ? 'bg-amber-500' : idx === 2 ? 'bg-blue-500' : 'bg-sky-500'
      }))
    : [
        { name: 'complaint_proximity_hops', impact: 0.38, color: 'bg-rose-500' },
        { name: 'sender_seen_before', impact: 0.24, color: 'bg-amber-500' },
        { name: 'pass_through_ratio', impact: 0.21, color: 'bg-blue-500' },
        { name: 'inflow_vs_normal_ratio', impact: 0.17, color: 'bg-sky-500' },
      ];


  return (
    <div className="card flex flex-col overflow-y-auto animate-fade-in" style={{ maxHeight: '720px' }}>
      {/* ── Dossier Header ──────────────────────────── */}
      <div className="px-6 pt-6 pb-4 border-b border-slate-100 shrink-0">
        <div className="flex items-start justify-between gap-3 flex-wrap">
          {/* Left: TX ID + counterparty */}
          <div className="min-w-0 space-y-1.5">
            <div className="flex items-center gap-2 flex-wrap">
              <span className="inline-flex items-center gap-1.5 bg-slate-100 border border-slate-200 text-slate-700 text-[11px] font-mono font-bold px-2.5 py-1 rounded-lg">
                {alert.transactionId}
                <button
                  onClick={() => { navigator.clipboard.writeText(alert.transactionId); setCopied(true); setTimeout(() => setCopied(false), 2000); }}
                  className="text-slate-400 hover:text-slate-700 transition"
                >
                  {copied ? <Check size={11} className="text-emerald-600" /> : <Copy size={11} />}
                </button>
              </span>
              <span className="text-[11px] text-slate-400 font-medium">{alert.timestamp}</span>
              <span className="px-2 py-0.5 rounded-full bg-blue-50 border border-blue-100 text-blue-700 text-[10px] font-bold">
                UPI Instant Transfer
              </span>
            </div>
            <h2 className="text-[17px] font-bold font-display text-slate-900 leading-tight break-all">
              {alert.counterparty}
            </h2>
          </div>

          {/* Right: Amount + Direction */}
          <div className="text-right shrink-0">
            <p className="text-[24px] font-bold font-mono text-slate-900 tracking-tight leading-none">
              ₹{alert.amount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
            </p>
            <p className={`text-[11px] font-bold mt-1 ${isIncoming ? 'text-emerald-600' : 'text-blue-600'}`}>
              {alert.direction} · {isIncoming ? 'Direct Credit' : 'Direct Debit'}
            </p>
          </div>
        </div>

        {/* Risk Score Bar */}
        <div className="mt-4 p-3 rounded-xl bg-slate-50 border border-slate-200 flex items-center gap-4">
          <div className="flex-1 space-y-1.5">
            <div className="flex justify-between items-center text-[11px] font-medium">
              <span className="text-slate-500 flex items-center gap-1.5">
                Risk Score
                {isScoring && <Loader2 size={11} className="animate-spin text-blue-600" />}
              </span>
              <div className="flex items-center gap-2">
                {apiData?.latency_ms !== undefined && (
                  <span className="text-[10px] font-mono text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200 flex items-center gap-1">
                    <Zap size={10} /> {apiData.latency_ms}ms warm inference
                  </span>
                )}
                <span className={`font-bold font-mono text-[13px] ${
                  riskColor === 'rose' ? 'text-rose-700' : riskColor === 'amber' ? 'text-amber-700' : 'text-emerald-700'
                }`}>{currentRiskScore}/100</span>
              </div>
            </div>
            <div className="h-2 rounded-full bg-slate-200 overflow-hidden">
              <div
                className={`h-full rounded-full transition-all duration-700 ${
                  riskColor === 'rose' ? 'bg-rose-500' : riskColor === 'amber' ? 'bg-amber-500' : 'bg-emerald-500'
                }`}
                style={{ width: `${currentRiskScore}%` }}
              />
            </div>
          </div>
          <span className={`shrink-0 px-3 py-1.5 rounded-xl text-[11px] font-bold border ${
            riskColor === 'rose'
              ? 'bg-rose-50 border-rose-200 text-rose-700'
              : riskColor === 'amber'
              ? 'bg-amber-50 border-amber-200 text-amber-700'
              : 'bg-emerald-50 border-emerald-200 text-emerald-700'
          }`}>
            {currentRiskBand} RISK
          </span>
        </div>
      </div>

      {/* ── Body Sections ────────────────────────────── */}
      <div className="flex-1 px-6 py-5 space-y-6 overflow-y-auto">

        {/* Graph Topology Hops */}
        <div>
          <SectionLabel
            icon={Network}
            label="Topological Graph Path (2 Hops to FIR)"
            right={
              <span className="text-[10px] font-bold text-rose-700 bg-rose-50 border border-rose-200 px-2 py-0.5 rounded-lg">
                HIGH PROXIMITY
              </span>
            }
          />
          <div className="grid grid-cols-4 gap-2">
            {[
              { hop: 'HOP 0', role: 'ORIGIN',     name: alert.counterparty.split('@')[0], note: 'Unsolicited Sender', colors: 'bg-white border-slate-200 text-slate-700' },
              { hop: 'HOP 1', role: 'FORWARDER',  name: 'mule-bridge-01', note: 'Layering Pass-through', colors: 'bg-amber-50 border-amber-200 text-amber-800' },
              { hop: 'HOP 2', role: 'VICTIM',     name: 'acc-victim-01',  note: 'Coerced Arrest',        colors: 'bg-amber-50 border-amber-200 text-amber-800' },
              { hop: 'ANCHOR', role: 'FIR',       name: 'FIR-2026-9082',  note: 'Cyber Police 1930',     colors: 'bg-rose-50 border-rose-200 text-rose-800' },
            ].map((n, i) => (
              <React.Fragment key={n.hop}>
                <div className={`p-3 rounded-xl border text-[11px] ${n.colors}`}>
                  <span className="font-mono font-bold block text-[9px] opacity-60 mb-1">{n.hop}</span>
                  <p className="font-bold truncate text-[12px] leading-tight" title={n.name}>{n.name}</p>
                  <p className="opacity-70 text-[10px] mt-0.5 leading-tight">{n.note}</p>
                </div>
                {i < 3 && (
                  <div className="hidden col-span-0" />
                )}
              </React.Fragment>
            ))}
          </div>
        </div>

        {/* Inline What-If Simulator */}
        <div>
          <SectionLabel
            icon={Sliders}
            label="Inline What-If Simulator"
            right={
              <span className={`text-[12px] font-bold font-mono px-2.5 py-1 rounded-xl ${
                liveSimScore >= 70 ? 'bg-rose-100 text-rose-800' : 'bg-emerald-100 text-emerald-800'
              }`}>
                {liveSimScore}/100
              </span>
            }
          />
          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-3">
            <div className="flex justify-between text-[12px] text-slate-600 font-medium">
              <span>Simulated Transfer Amount</span>
              <span className="font-mono text-blue-700 font-bold">₹{simulatedAmount.toLocaleString('en-IN')}</span>
            </div>
            <input
              type="range"
              min={500} max={120000} step={500}
              value={simulatedAmount}
              onChange={e => handleAmountSlider(Number(e.target.value))}
            />
            <div className="flex justify-between text-[10px] text-slate-400 font-mono">
              <span>₹500</span>
              <span>₹{alert.amount.toLocaleString('en-IN')} (current)</span>
              <span>₹1,20,000</span>
            </div>
          </div>
        </div>

        {/* SHAP Contributions */}
        <div>
          <SectionLabel
            icon={BrainCircuit}
            label="Explainable AI — Live SHAP Contributions"
            right={<span className="text-[11px] text-slate-500 font-mono">{apiData?.model_version || 'bgt-risk-1.4.0'}</span>}
          />
          <div className="bg-white border border-slate-200 rounded-xl px-4 py-1 divide-y divide-slate-100">
            {shapFeatures.map(f => <ShapRow key={f.name} {...f} />)}
          </div>
        </div>

        {/* Quarantine Ledger Impact */}
        <div>
          <SectionLabel icon={Scale} label="Quarantine Ledger Impact" />
          <div className="grid grid-cols-2 gap-3">
            <div className="p-4 rounded-xl bg-white border border-slate-200">
              <p className="text-[11px] text-slate-500 font-medium">Available Balance</p>
              <p className="text-[17px] font-bold font-mono text-slate-900 mt-1">₹1,24,500.00</p>
              <p className="text-[10px] text-emerald-700 font-semibold mt-1.5 flex items-center gap-1">
                <CheckCircle2 size={11} /> Liquid for daily spends
              </p>
            </div>
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200">
              <p className="text-[11px] text-rose-600 font-bold flex items-center gap-1">
                <Lock size={11} /> Quarantine Hold
              </p>
              <p className="text-[17px] font-bold font-mono text-rose-800 mt-1">
                ₹{alert.amount.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
              </p>
              <p className="text-[10px] text-rose-500 font-semibold mt-1.5">24-hr safe harbor freeze</p>
            </div>
          </div>
        </div>
      </div>

      {/* ── Footer Actions ───────────────────────────── */}
      {quarantineError && (
        <div className="px-6 pt-3 text-[11px] font-medium text-rose-700" role="alert">
          {quarantineError}
        </div>
      )}
      <div className="px-6 py-4 border-t border-slate-100 flex items-center gap-2.5 shrink-0">
        <button
          onClick={onOpenGraph}
          className="flex-1 py-2.5 px-4 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-[12px] font-semibold text-slate-700 flex items-center justify-center gap-1.5 transition"
        >
          <Network size={14} className="text-blue-600" />
          Full Graph View
        </button>
        <button
          onClick={onOpenCounterfactual}
          className="flex-1 py-2.5 px-4 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-[12px] font-semibold text-slate-700 flex items-center justify-center gap-1.5 transition"
        >
          <Sliders size={14} className="text-violet-600" />
          Advanced Sim
        </button>
        <button
          onClick={handleQuarantine}
          disabled={quarantinePlaced || isQuarantining}
          className={`flex-1 py-2.5 px-4 rounded-xl text-[12px] font-bold flex items-center justify-center gap-1.5 transition ${
            quarantinePlaced
              ? 'bg-emerald-50 border border-emerald-300 text-emerald-700 cursor-default'
              : 'bg-blue-600 hover:bg-blue-700 text-white shadow-glow-blue'
          }`}
        >
          {quarantinePlaced
            ? <><CheckCircle2 size={14} /> Enforced</>
            : <><Lock size={14} /> {isQuarantining ? 'Enforcing…' : 'Enforce 24h Hold'}</>
          }
        </button>
      </div>
    </div>
  );
};
