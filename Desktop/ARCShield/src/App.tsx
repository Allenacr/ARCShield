import React, { useState, useEffect } from 'react';
import {
  Shield,
  Activity,
  Briefcase,
  CheckCircle2,
  Sliders,
  Network,
  Lock,
  Users,
  ShieldAlert,
  Sparkles,
  CreditCard,
  ShieldCheck,
  TrendingUp,
  Bell,
  ChevronDown,
  Zap,
  Play,
  Cpu,
} from 'lucide-react';
import { AlertFeed, AlertItem } from './components/AlertFeed';
import { TransactionInvestigation } from './components/TransactionInvestigation';
import { CounterfactualSlider } from './components/CounterfactualSlider';
import { EntityGraphViewer } from './components/EntityGraphViewer';
import { CaseManagement, CaseItem } from './components/CaseManagement';
import { CoercionDialogModal } from './components/CoercionDialogModal';
import { TamilContactsModal } from './components/TamilContactsModal';
import { ScenarioLauncher } from './components/ScenarioLauncher';
import { SystemMonitor } from './components/SystemMonitor';
import { apiUrl } from './config';

/* ─── Seed Data ───────────────────────────────────── */
const INITIAL_ALERTS: AlertItem[] = [
  {
    id: 'alt-scen-5',
    transactionId: 'TX-IN-42000-CLOSER',
    counterparty: 'karan9921@upi (Stranger)',
    amount: 42000,
    direction: 'INCOMING',
    riskScore: 92,
    riskBand: 'HIGH',
    reasonCodes: ['UNKNOWN_SENDER', 'COMPLAINT_PROXIMITY_2_HOPS', 'HIGH_PASS_THROUGH_RISK', 'UNUSUAL_INFLOW'],
    timestamp: 'Just now',
  },
  {
    id: 'alt-scen-2',
    transactionId: 'TX-OUT-75000-ATO',
    counterparty: 'mule_payee_01@upi',
    amount: 75000,
    direction: 'OUTGOING',
    riskScore: 89,
    riskBand: 'HIGH',
    reasonCodes: ['NEW_DEVICE_BEFORE_TRANSFER', 'CREDENTIAL_CHANGE_BEFORE_TRANSFER', 'ESCALATING_AMOUNTS_SEQUENCE'],
    timestamp: '6 mins ago',
  },
  {
    id: 'alt-scen-3',
    transactionId: 'TX-OUT-95000-COERCION',
    counterparty: 'cbi_verification_cell@upi',
    amount: 95000,
    direction: 'OUTGOING',
    riskScore: 96,
    riskBand: 'HIGH',
    reasonCodes: ['COERCION_SAFE_ACCOUNT_CLAIM', 'COERCION_URGENT_REQUEST', 'COERCION_SECRECY_REQUEST'],
    timestamp: '14 mins ago',
  },
  {
    id: 'alt-scen-4',
    transactionId: 'TX-OUT-9950-STRUCT',
    counterparty: 'offshore_remit@upi',
    amount: 9950,
    direction: 'OUTGOING',
    riskScore: 78,
    riskBand: 'HIGH',
    reasonCodes: ['STRUCTURING_THRESHOLD_AVOIDANCE'],
    timestamp: '22 mins ago',
  },
  {
    id: 'alt-scen-1',
    transactionId: 'TX-OUT-1200-QUIET',
    counterparty: 'Starbucks Coffee Corp',
    amount: 1200,
    direction: 'OUTGOING',
    riskScore: 12,
    riskBand: 'LOW',
    reasonCodes: ['ROUTINE_TRANSACTION', 'KNOWN_DEVICE', 'NORMAL_HOURS'],
    timestamp: '45 mins ago',
  },
];

const INITIAL_CASES: CaseItem[] = [
  {
    id: 'case-01',
    caseNumber: 'CASE-20260918-Q42K',
    accountId: 'acc-user-target',
    heldAmount: 42000,
    status: 'OPEN',
    proactiveHoldTime: '2026-09-18 11:20:04 UTC',
    reason: 'Account holder proactively tapped Hold for 24h on unsolicited ₹42,000 credit before touching funds.',
  },
];

/* ─── Stat Card Component ─────────────────────────── */
function StatCard({ label, value, sub, color = 'blue', icon: Icon }: {
  label: string; value: string | number; sub?: string;
  color?: 'blue' | 'emerald' | 'rose' | 'amber'; icon: React.ElementType;
}) {
  const palettes = {
    blue:    { bg: 'bg-blue-50',   text: 'text-blue-700',   iconBg: 'bg-blue-100',   iconText: 'text-blue-600' },
    emerald: { bg: 'bg-emerald-50', text: 'text-emerald-700', iconBg: 'bg-emerald-100', iconText: 'text-emerald-600' },
    rose:    { bg: 'bg-rose-50',   text: 'text-rose-700',   iconBg: 'bg-rose-100',   iconText: 'text-rose-600' },
    amber:   { bg: 'bg-amber-50',  text: 'text-amber-700',  iconBg: 'bg-amber-100',  iconText: 'text-amber-600' },
  };
  const p = palettes[color];

  return (
    <div className="card p-5 flex items-center gap-4 animate-slide-up">
      <div className={`icon-box w-11 h-11 ${p.iconBg}`}>
        <Icon size={20} className={p.iconText} />
      </div>
      <div className="min-w-0">
        <p className="text-xs font-medium text-slate-500 truncate">{label}</p>
        <p className={`text-xl font-bold font-mono ${p.text} tracking-tight leading-tight mt-0.5`}>{value}</p>
        {sub && <p className="text-[11px] text-slate-400 font-medium mt-0.5 truncate">{sub}</p>}
      </div>
    </div>
  );
}

/* ─── Quick Action Button ─────────────────────────── */
function QuickAction({ label, sub, icon: Icon, colorClass, hoverBorder, onClick }: {
  label: string; sub: string; icon: React.ElementType;
  colorClass: string; hoverBorder: string; onClick: () => void;
}) {
  return (
    <button
      onClick={onClick}
      className={`group p-4 rounded-xl border border-slate-200 bg-slate-50 hover:bg-white ${hoverBorder} 
        text-left transition-all duration-200 hover:shadow-card flex flex-col gap-2.5`}
    >
      <div className={`icon-box w-10 h-10 ${colorClass} rounded-xl`}>
        <Icon size={18} className="text-white" />
      </div>
      <div>
        <p className="text-[13px] font-semibold text-slate-800 leading-tight">{label}</p>
        <p className="text-[11px] text-slate-400 font-medium mt-0.5">{sub}</p>
      </div>
    </button>
  );
}

/* ─── Main App ────────────────────────────────────── */
export default function App() {
  const [activeTab, setActiveTab]                     = useState<'ALERTS' | 'CASES' | 'SYSTEM'>('ALERTS');
  const [alerts, setAlerts]                           = useState<AlertItem[]>(INITIAL_ALERTS);
  const [cases, setCases]                             = useState<CaseItem[]>(INITIAL_CASES);
  const [selectedAlert, setSelectedAlert]             = useState<AlertItem | null>(INITIAL_ALERTS[0]);
  const [showCounterfactual, setShowCounterfactual]   = useState(false);
  const [showGraph, setShowGraph]                     = useState(false);
  const [showCoercionModal, setShowCoercionModal]     = useState(false);
  const [showContactsModal, setShowContactsModal]     = useState(false);
  const [showScenarioLauncher, setShowScenarioLauncher] = useState(false);
  const [backendOnline, setBackendOnline]             = useState(true);
  const [recentLatencies, setRecentLatencies]         = useState<number[]>([0.38, 0.42, 0.51, 0.35]);
  const [availableBalance, setAvailableBalance]       = useState(124500.0);
  const [heldBalance, setHeldBalance]                 = useState(25000.0);

  const highRiskCount = alerts.filter(a => a.riskBand === 'HIGH').length;

  // Poll backend health status
  useEffect(() => {
    const checkHealth = async () => {
      try {
        const res = await fetch(apiUrl('/health'));
        setBackendOnline(res.ok);
      } catch {
        setBackendOnline(false);
      }
    };
    checkHealth();
    const interval = setInterval(checkHealth, 20000);
    return () => clearInterval(interval);
  }, []);

  const handleNewLiveAlert = (newAlert: AlertItem) => {
    setAlerts(prev => [newAlert, ...prev]);
    setSelectedAlert(newAlert);
  };

  const handleScoreUpdated = (txId: string, riskScore: number, riskBand: string, latencyMs: number) => {
    setRecentLatencies(prev => [latencyMs, ...prev.slice(0, 9)]);
    setAlerts(prev => prev.map(a => a.transactionId === txId ? { ...a, riskScore, riskBand: riskBand as any } : a));
  };

  const handleLaunchScenario = (newAlert: AlertItem, requiresCoercion?: boolean) => {
    setAlerts(prev => [newAlert, ...prev]);
    setSelectedAlert(newAlert);
    setActiveTab('ALERTS');
    if (requiresCoercion) {
      setShowCoercionModal(true);
    }
  };

  const handleQuarantineSuccess = (txId: string) => {
    const amt = selectedAlert?.amount || 25000;
    setHeldBalance(prev => prev + amt);
    const newCase: CaseItem = {
      id: `case-${Date.now()}`,
      caseNumber: `CASE-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${txId.slice(-4)}`,
      accountId: 'acc-user-target',
      heldAmount: amt,
      status: 'OPEN',
      proactiveHoldTime: new Date().toISOString(),
      reason: `Analyst enforced 24-hr hold on ${selectedAlert?.counterparty || 'unsolicited transfer'}`,
    };
    setCases(prev => [newCase, ...prev]);
  };

  const handleCaseStatusChange = (caseId: string, status: CaseItem['status']) => {
    setCases(prev => prev.map(caseItem => (
      caseItem.id === caseId ? { ...caseItem, status } : caseItem
    )));
  };

  const handleContactTransfer = (contact: any, amount: number) => {
    if (amount > 50000) { setShowCoercionModal(true); return; }
    setAvailableBalance(prev => Math.max(0, prev - amount));
    const newTxAlert: AlertItem = {
      id: `alt-${Date.now()}`,
      transactionId: `TX-OUT-${amount}-${contact.name.slice(0, 3).toUpperCase()}`,
      counterparty: `${contact.name} (${contact.upi})`,
      amount,
      direction: 'OUTGOING',
      riskScore: 18,
      riskBand: 'LOW',
      reasonCodes: ['KNOWN_BENEFICIARY', 'VERIFIED_CONTACT', 'NORMAL_HOURS'],
      timestamp: 'Just now',
      isLive: true,
    };
    setAlerts(prev => [newTxAlert, ...prev]);
    setSelectedAlert(newTxAlert);
  };

  return (
    <div className="min-h-screen flex flex-col bg-[#f8fafc] font-sans">

      {/* ── Top Nav ─────────────────────────────────── */}
      <header className="sticky top-0 z-40 bg-white border-b border-slate-200 shadow-xs">
        <div className="max-w-[1440px] mx-auto px-6 lg:px-10 h-[60px] flex items-center justify-between gap-4">

          {/* Brand */}
          <div className="flex items-center gap-3 shrink-0">
            <div className="w-9 h-9 bg-blue-600 rounded-xl flex items-center justify-center shadow-glow-blue">
              <Shield size={18} className="text-white stroke-[2.5]" />
            </div>
            <div className="leading-tight">
              <span className="text-[15px] font-bold font-display text-slate-900 tracking-tight">ARCShield</span>
              <span className="hidden sm:inline text-xs text-slate-400 font-medium ml-2">Fraud Defense Console</span>
            </div>
            <div className="hidden md:flex items-center gap-1.5 ml-2 px-2.5 py-1 rounded-full bg-emerald-50 border border-emerald-200">
              <span className="live-dot" />
              <span className="text-[11px] font-bold text-emerald-700 uppercase tracking-wide">
                {backendOnline ? 'Engine Online' : 'Connecting'}
              </span>
            </div>
          </div>

          {/* Center Nav Pills */}
          <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl border border-slate-200">
            {[
              { key: 'ALERTS', icon: Activity, label: `Telemetry (${alerts.length})` },
              { key: 'CASES',  icon: Briefcase, label: `Cases (${cases.length})` },
              { key: 'SYSTEM', icon: Cpu,       label: 'System Monitor' },
            ].map(({ key, icon: Icon, label }) => (
              <button
                key={key}
                onClick={() => setActiveTab(key as any)}
                className={`flex items-center gap-1.5 px-4 py-1.5 rounded-lg text-[13px] font-semibold transition-all duration-150 ${
                  activeTab === key
                    ? 'bg-white text-blue-700 shadow-xs'
                    : 'text-slate-500 hover:text-slate-800'
                }`}
              >
                <Icon size={14} />
                {label}
              </button>
            ))}
          </div>

          {/* Right: Demo launcher + user + bell */}
          <div className="flex items-center gap-3 shrink-0">
            <button
              onClick={() => setShowScenarioLauncher(true)}
              className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-[12px] font-bold shadow-glow-blue transition cursor-pointer"
            >
              <Play size={11} className="fill-white" />
              <span>Scenario Lab</span>
            </button>

            <button className="relative w-9 h-9 rounded-xl bg-slate-100 hover:bg-slate-200 border border-slate-200 flex items-center justify-center transition">
              <Bell size={16} className="text-slate-500" />
              {highRiskCount > 0 && (
                <span className="absolute -top-1 -right-1 w-4 h-4 rounded-full bg-rose-500 text-white text-[9px] font-bold flex items-center justify-center">
                  {highRiskCount}
                </span>
              )}
            </button>

            <div className="flex items-center gap-2 pl-2 border-l border-slate-200">
              <div className="w-8 h-8 rounded-xl bg-blue-600 text-white text-[12px] font-bold flex items-center justify-center">
                AC
              </div>
              <div className="hidden sm:block text-left leading-tight">
                <p className="text-[13px] font-semibold text-slate-800">Allen CR</p>
                <p className="text-[11px] text-slate-400 font-mono">Senior Analyst</p>
              </div>
              <ChevronDown size={14} className="text-slate-400 hidden sm:block" />
            </div>
          </div>
        </div>
      </header>

      {/* ── Main Workspace ───────────────────────────── */}
      <main className="flex-1 max-w-[1440px] w-full mx-auto px-6 lg:px-10 py-7 space-y-6">

        {/* ── Stats Row ─────────────────────────────── */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <StatCard
            label="Available Balance"
            value={`₹${availableBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`}
            sub="100% liquid for daily transfers"
            color="blue"
            icon={CreditCard}
          />
          <StatCard
            label="Quarantine Hold"
            value={`₹${heldBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}`}
            sub="24-hr safe harbor isolation"
            color="rose"
            icon={Lock}
          />
          <StatCard
            label="High Risk Alerts"
            value={highRiskCount}
            sub="Require immediate review"
            color="amber"
            icon={ShieldAlert}
          />
          <StatCard
            label="Cases Open"
            value={cases.length}
            sub="Active quarantine ledger"
            color="emerald"
            icon={ShieldCheck}
          />
        </div>

        {/* ── Account Card + Quick Actions ─────────── */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-5">

          {/* Account Hero */}
          <div className="lg:col-span-2 card p-6 space-y-5 animate-slide-up">
            {/* Account Header */}
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 rounded-xl bg-blue-600 flex items-center justify-center">
                  <CreditCard size={18} className="text-white" />
                </div>
                <div>
                  <p className="text-[13px] font-semibold text-slate-800">HDFC Bank •••• 7241</p>
                  <p className="text-[11px] text-slate-400 font-mono">allen.cr@okhdfcbank · Primary Account</p>
                </div>
              </div>
              <span className="px-2.5 py-1 rounded-full text-[11px] font-bold bg-emerald-50 text-emerald-700 border border-emerald-200 flex items-center gap-1.5">
                <ShieldCheck size={12} />
                Contactless Protected
              </span>
            </div>

            {/* Balance Split */}
            <div className="grid grid-cols-2 gap-4">
              <div className="p-5 rounded-2xl bg-gradient-to-br from-blue-50 to-blue-50/30 border border-blue-100">
                <p className="text-[11px] font-semibold text-blue-600 uppercase tracking-widest">Available</p>
                <p className="text-2xl font-bold font-mono text-blue-900 tracking-tight mt-1.5">
                  ₹{availableBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                </p>
                <p className="text-[11px] text-blue-500 font-medium mt-2 flex items-center gap-1">
                  <CheckCircle2 size={12} />
                  Fully liquid for UPI transfers
                </p>
              </div>
              <div className="p-5 rounded-2xl bg-gradient-to-br from-rose-50 to-rose-50/30 border border-rose-100">
                <p className="text-[11px] font-semibold text-rose-600 uppercase tracking-widest flex items-center gap-1">
                  <Lock size={11} /> Quarantine Hold
                </p>
                <p className="text-2xl font-bold font-mono text-rose-800 tracking-tight mt-1.5">
                  ₹{heldBalance.toLocaleString('en-IN', { minimumFractionDigits: 2 })}
                </p>
                <p className="text-[11px] text-rose-500 font-medium mt-2 flex items-center gap-1">
                  <ShieldCheck size={12} />
                  24-hr safe harbor hold active
                </p>
              </div>
            </div>

            {/* Visual balance ratio bar */}
            <div className="space-y-1.5">
              <div className="flex justify-between text-[11px] font-medium text-slate-500">
                <span>Balance utilization</span>
                <span className="font-mono">
                  {Math.round((heldBalance / (availableBalance + heldBalance)) * 100)}% quarantined
                </span>
              </div>
              <div className="h-2 rounded-full bg-slate-100 overflow-hidden">
                <div
                  className="h-full rounded-full bg-blue-500 relative"
                  style={{ width: `${Math.round((availableBalance / (availableBalance + heldBalance)) * 100)}%` }}
                >
                  <div className="absolute right-0 top-0 bottom-0 w-2 bg-rose-400 rounded-full" />
                </div>
              </div>
            </div>
          </div>

          {/* Quick Actions */}
          <div className="card p-6 space-y-4 animate-slide-up">
            <div className="flex items-center justify-between">
              <p className="text-[13px] font-semibold text-slate-700">Quick Actions</p>
              <Zap size={14} className="text-amber-400" />
            </div>
            <div className="grid grid-cols-2 gap-2.5">
              <QuickAction
                icon={Users}
                label="Pay Contacts"
                sub="Tamil Nadu directory"
                colorClass="bg-blue-600"
                hoverBorder="hover:border-blue-300"
                onClick={() => setShowContactsModal(true)}
              />
              <QuickAction
                icon={ShieldAlert}
                label="Coercion Guard"
                sub="Digital arrest F-04"
                colorClass="bg-rose-600"
                hoverBorder="hover:border-rose-300"
                onClick={() => setShowCoercionModal(true)}
              />
              <QuickAction
                icon={Network}
                label="Entity Graph"
                sub="2-hop FIR proximity"
                colorClass="bg-violet-600"
                hoverBorder="hover:border-violet-300"
                onClick={() => setShowGraph(true)}
              />
              <QuickAction
                icon={Play}
                label="Scenario Lab"
                sub="5 PRD testcases"
                colorClass="bg-amber-500"
                hoverBorder="hover:border-amber-300"
                onClick={() => setShowScenarioLauncher(true)}
              />
            </div>
          </div>
        </div>

        {/* ── Content Area ─────────────────────────── */}
        {activeTab === 'ALERTS' ? (
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-5 animate-fade-in">
            {/* Feed */}
            <div className="lg:col-span-5 flex flex-col">
              <AlertFeed
                alerts={alerts}
                selectedAlert={selectedAlert}
                onSelectAlert={setSelectedAlert}
                onNewLiveAlert={handleNewLiveAlert}
              />
            </div>
            {/* Investigation */}
            <div className="lg:col-span-7 flex flex-col">
              <TransactionInvestigation
                alert={selectedAlert}
                onOpenCounterfactual={() => setShowCounterfactual(true)}
                onOpenGraph={() => setShowGraph(true)}
                onQuarantineSuccess={handleQuarantineSuccess}
                onScoreUpdated={handleScoreUpdated}
              />
            </div>
          </div>
        ) : activeTab === 'CASES' ? (
          <div className="animate-fade-in">
            <CaseManagement cases={cases} onStatusChange={handleCaseStatusChange} />
          </div>
        ) : (
          <SystemMonitor
            totalScored={alerts.length}
            highRiskCount={highRiskCount}
            heldBalance={heldBalance}
            availableBalance={availableBalance}
            recentLatencies={recentLatencies}
          />
        )}
      </main>

      {/* ── Modals ───────────────────────────────────── */}
      {showScenarioLauncher && (
        <ScenarioLauncher
          onClose={() => setShowScenarioLauncher(false)}
          onLaunchScenario={handleLaunchScenario}
        />
      )}
      {showCounterfactual && (
        <CounterfactualSlider alert={selectedAlert} onClose={() => setShowCounterfactual(false)} />
      )}
      {showGraph && (
        <EntityGraphViewer alert={selectedAlert} onClose={() => setShowGraph(false)} />
      )}
      {showCoercionModal && (
        <CoercionDialogModal onClose={() => setShowCoercionModal(false)} />
      )}
      {showContactsModal && (
        <TamilContactsModal
          onClose={() => setShowContactsModal(false)}
          onSelectContactForTransfer={handleContactTransfer}
        />
      )}
    </div>
  );
}

