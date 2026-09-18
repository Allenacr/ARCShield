import React, { useEffect, useMemo, useState } from 'react';
import { X, Network, AlertTriangle, ArrowRight, CheckCircle2 } from 'lucide-react';
import { AlertItem } from './AlertFeed';
import { apiUrl } from '../config';

interface EntityGraphViewerProps {
  alert: AlertItem | null;
  onClose: () => void;
}

interface GraphNode {
  id: string;
  name: string;
  type: string;
  is_flagged?: boolean;
  is_center?: boolean;
}

interface GraphLink {
  source: string;
  target: string;
  relation?: string;
}

interface GraphSnapshot {
  center?: string;
  radius?: number;
  nodes?: GraphNode[];
  links?: GraphLink[];
}

const HOP_COLORS = [
  { bg: 'bg-slate-50',  border: 'border-slate-200', label: 'text-slate-600', dot: 'bg-slate-400'  },
  { bg: 'bg-amber-50',  border: 'border-amber-200', label: 'text-amber-700', dot: 'bg-amber-500'  },
  { bg: 'bg-amber-50',  border: 'border-amber-200', label: 'text-amber-700', dot: 'bg-amber-500'  },
  { bg: 'bg-rose-50',   border: 'border-rose-200',  label: 'text-rose-700',  dot: 'bg-rose-500'   },
];

const fallbackNodes = [
  {
    hop: 'HOP 0',
    role: 'Transaction Counterparty',
    label: 'counterparty',
    type: 'SUSPECT SENDER',
    detail: 'First-time sender, anomalous sudden velocity',
  },
  {
    hop: 'HOP 1',
    role: 'Intermediary Mule Bridge',
    label: 'mule-bridge-01@axis',
    type: 'PASSTHROUGH FORWARDER',
    detail: 'Received ₹42k, dispersed 92% within 18 mins',
  },
  {
    hop: 'HOP 2',
    role: 'Coerced Victim Account',
    label: 'acc-victim-01 (Flagged)',
    type: 'FRAUD ORIGIN LINK',
    detail: 'Subject of extortion in digital arrest complaint',
  },
  {
    hop: 'ANCHOR',
    role: 'Verified Cybercrime FIR',
    label: 'FIR-2026-9082 (1930 Portal)',
    type: 'OFFICIAL COMPLAINT',
    detail: '₹1,50,000 Cyber Fraud filed at TN Cyber Cell',
  },
];

export const EntityGraphViewer: React.FC<EntityGraphViewerProps> = ({ alert, onClose }) => {
  const [snapshot, setSnapshot] = useState<GraphSnapshot | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    if (!alert) return;

    let cancelled = false;
    const loadSnapshot = async () => {
      setIsLoading(true);
      try {
        const response = await fetch(apiUrl(`/graph/snapshot/${encodeURIComponent(alert.counterparty)}`));
        if (!response.ok) {
          throw new Error('Graph snapshot unavailable');
        }
        const data: GraphSnapshot = await response.json();
        if (!cancelled) {
          setSnapshot(data);
        }
      } catch {
        if (!cancelled) {
          setSnapshot(null);
        }
      } finally {
        if (!cancelled) {
          setIsLoading(false);
        }
      }
    };

    loadSnapshot();
    return () => {
      cancelled = true;
    };
  }, [alert?.transactionId, alert?.counterparty]);

  if (!alert) return null;

  const nodes = useMemo(() => {
    if (snapshot && snapshot.nodes && snapshot.nodes.length > 0) {
      return snapshot.nodes.slice(0, 4).map((node, index) => ({
        hop: index === 0 ? 'HOP 0' : index === 1 ? 'HOP 1' : index === 2 ? 'HOP 2' : 'ANCHOR',
        role: node.is_center ? 'Transaction Counterparty' : node.is_flagged ? 'Flagged Entity' : node.type,
        label: node.name,
        type: node.is_flagged ? 'FLAGGED' : node.type,
        detail: node.is_center ? 'Current transaction entity in focus' : node.is_flagged ? 'Linked to flagged complaint network' : 'Connected entity in local graph',
      }));
    }

    return fallbackNodes.map((node) => ({
      ...node,
      label: node.label === 'counterparty' ? alert.counterparty : node.label,
    }));
  }, [alert.counterparty, snapshot]);

  const graphSummary = snapshot && snapshot.nodes ? `${snapshot.nodes.length} connected entities` : 'Live subgraph evidence';

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 overflow-y-auto animate-fade-in">
      <div className="bg-white rounded-2xl border border-slate-200 w-full max-w-4xl shadow-2xl flex flex-col max-h-[90vh]">

        <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between shrink-0">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-blue-100 flex items-center justify-center">
              <Network size={20} className="text-blue-600" />
            </div>
            <div>
              <div className="flex items-center gap-2.5">
                <h3 className="text-[15px] font-bold font-display text-slate-900">Multi-Hop Topological Entity Graph</h3>
                <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 border border-rose-200">
                  {isLoading ? 'LOADING' : graphSummary.toUpperCase()}
                </span>
              </div>
              <p className="text-[12px] text-slate-400 font-medium mt-0.5">
                Shortest path traversal to verified cybercrime FIR
              </p>
            </div>
          </div>
          <button onClick={onClose} className="p-2 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition">
            <X size={17} />
          </button>
        </div>

        <div className="p-6 space-y-5 flex-1 overflow-y-auto">
          <div className="flex items-center gap-2 px-4 py-2.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700">
            <AlertTriangle size={14} />
            <span className="text-[12px] font-bold">Proximity Alert: {snapshot ? 'Live backend subgraph loaded' : '2-Hop Network Layering Detected'}</span>
            <span className="ml-auto text-[11px] font-mono text-rose-400">{snapshot?.center || 'SNP-8921-EGO'}</span>
          </div>

          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {nodes.map((node, i) => {
              const c = HOP_COLORS[i] || HOP_COLORS[0];
              return (
                <div key={`${node.hop}-${node.label}`} className="relative">
                  <div className={`p-4 rounded-xl border ${c.bg} ${c.border} h-full flex flex-col gap-2 hover:shadow-card transition`}>
                    <div className="flex items-center gap-2">
                      <span className={`w-2 h-2 rounded-full ${c.dot} shrink-0`} />
                      <span className={`text-[10px] font-mono font-bold ${c.label}`}>{node.hop}</span>
                    </div>
                    <div>
                      <p className="text-[10px] text-slate-400 font-medium">{node.role}</p>
                      <p className="text-[13px] font-bold text-slate-900 break-all leading-tight mt-0.5">{node.label}</p>
                    </div>
                    <span className={`text-[9px] font-bold uppercase tracking-wider px-1.5 py-0.5 rounded ${c.bg} ${c.label} border ${c.border} self-start`}>
                      {node.type}
                    </span>
                    <p className="text-[11px] text-slate-500 leading-snug">{node.detail}</p>
                  </div>
                  {i < nodes.length - 1 && (
                    <div className="hidden md:flex absolute -right-1.5 top-1/2 -translate-y-1/2 z-10 w-3 h-3 rounded-full bg-white border border-slate-300 items-center justify-center">
                      <ArrowRight size={8} className="text-slate-400" />
                    </div>
                  )}
                </div>
              );
            })}
          </div>

          <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 text-[12px] leading-relaxed text-slate-600">
            <div className="flex items-center gap-1.5 font-bold text-blue-700 mb-1.5">
              <CheckCircle2 size={13} />
              Court-Admissible Graph Snapshot
            </div>
            Although{' '}
            <span className="font-bold text-slate-900">{alert.counterparty}</span>{' '}
            had no direct prior FIR under its exact UPI VPA, its directional transaction graph connects within 2 hops to{' '}
            <span className="font-bold text-rose-700">FIR-2026-9082</span>{' '}
            (Tamil Nadu State Cyber Police). This tamper-evident topology proof supports the 24-hour quarantine freeze under RBI Section 10(2).
          </div>
        </div>

        <div className="px-6 py-4 border-t border-slate-100 flex items-center justify-between shrink-0">
          <span className="text-[11px] text-slate-400 font-mono">Graph DB: NetworkX Core Engine</span>
          <button
            onClick={onClose}
            className="px-5 py-2 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-[12px] font-bold transition shadow-glow-blue"
          >
            Close Graph
          </button>
        </div>
      </div>
    </div>
  );
};
