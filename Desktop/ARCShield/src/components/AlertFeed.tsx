import React, { useState, useEffect } from 'react';
import {
  ArrowDownLeft,
  ArrowUpRight,
  Search,
  Clock,
  Sparkles,
  Zap,
} from 'lucide-react';
import { supabase } from '../supabase';

export interface AlertItem {
  id: string;
  transactionId: string;
  counterparty: string;
  amount: number;
  direction: 'INCOMING' | 'OUTGOING';
  riskScore: number;
  riskBand: 'LOW' | 'MEDIUM' | 'HIGH';
  reasonCodes: string[];
  timestamp: string;
  isLive?: boolean;
}

interface AlertFeedProps {
  alerts: AlertItem[];
  selectedAlert: AlertItem | null;
  onSelectAlert: (alert: AlertItem) => void;
  onNewLiveAlert?: (alert: AlertItem) => void;
}

const RISK_CONFIG = {
  HIGH:   { bg: 'bg-rose-50',   border: 'border-rose-200',   text: 'text-rose-700',   dot: 'bg-rose-500',   bar: 'bg-rose-500'   },
  MEDIUM: { bg: 'bg-amber-50',  border: 'border-amber-200',  text: 'text-amber-700',  dot: 'bg-amber-500',  bar: 'bg-amber-500'  },
  LOW:    { bg: 'bg-emerald-50', border: 'border-emerald-200', text: 'text-emerald-700', dot: 'bg-emerald-500', bar: 'bg-emerald-400' },
};

export const AlertFeed: React.FC<AlertFeedProps> = ({
  alerts,
  selectedAlert,
  onSelectAlert,
  onNewLiveAlert,
}) => {
  const [filterBand, setFilterBand]         = useState('ALL');
  const [filterDirection, setFilterDirection] = useState('ALL');
  const [searchQuery, setSearchQuery]       = useState('');
  const [realtimeConnected, setRealtimeConnected] = useState(false);

  useEffect(() => {
    if (!supabase) return;

    const client = supabase;
    const channel = client.channel('fraud_alerts');
    channel
      .on('broadcast', { event: 'incoming_alert' }, (eventPayload) => {
        const payload =
          eventPayload.payload && typeof eventPayload.payload === 'object' && 'payload' in eventPayload.payload
            ? (eventPayload.payload as any).payload
            : eventPayload.payload || eventPayload;

        const newAlert: AlertItem = {
          id: `live-${Date.now()}`,
          transactionId: payload.transaction_id || `TX-LIVE-${Date.now().toString().slice(-4)}`,
          counterparty: payload.counterparty || 'unknown-sender@upi',
          amount: parseFloat(payload.amount || '0') || 0,
          direction: (payload.direction as 'INCOMING' | 'OUTGOING') || 'INCOMING',
          riskScore: payload.risk_score ? parseInt(payload.risk_score) : 94,
          riskBand: (payload.risk_band as 'LOW' | 'MEDIUM' | 'HIGH') || 'HIGH',
          reasonCodes:
            typeof payload.reason_codes === 'string'
              ? payload.reason_codes.split(',')
              : Array.isArray(payload.reason_codes)
              ? payload.reason_codes
              : ['UNEXPECTED_CREDIT', 'HIGH_PASS_THROUGH_RISK'],
          timestamp: 'Just now',
          isLive: true,
        };
        if (onNewLiveAlert) onNewLiveAlert(newAlert);
      })
      .subscribe((status) => setRealtimeConnected(status === 'SUBSCRIBED'));
    return () => { client.removeChannel(channel); };
  }, [onNewLiveAlert]);

  const filtered = alerts.filter((a) => {
    if (filterBand !== 'ALL' && a.riskBand !== filterBand) return false;
    if (filterDirection !== 'ALL' && a.direction !== filterDirection) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      if (
        !a.counterparty.toLowerCase().includes(q) &&
        !a.transactionId.toLowerCase().includes(q) &&
        !a.reasonCodes.some(r => r.toLowerCase().includes(q))
      ) return false;
    }
    return true;
  });

  return (
    <div className="card flex flex-col overflow-hidden" style={{ minHeight: '560px', maxHeight: '720px' }}>

      {/* Header */}
      <div className="px-5 py-4 border-b border-slate-100 flex items-center justify-between gap-3 shrink-0">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-slate-900 flex items-center justify-center shrink-0">
            <Zap size={16} className="text-amber-400" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-[14px] font-bold font-display text-slate-900 leading-tight">
                Real-Time Ingestion Feed
              </h2>
              <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-[10px] font-bold border ${
                realtimeConnected
                  ? 'bg-emerald-50 border-emerald-200 text-emerald-700'
                  : 'bg-slate-100 border-slate-200 text-slate-500'
              }`}>
                {realtimeConnected
                  ? <><span className="live-dot" style={{ width: 6, height: 6 }} /> LIVE</>
                  : <><span className="status-dot bg-slate-400" style={{ width: 6, height: 6 }} /> SYNCING</>
                }
              </span>
            </div>
            <p className="text-[11px] text-slate-400 font-medium mt-0.5">Bidirectional UPI fraud scores</p>
          </div>
        </div>
        <span className="px-2.5 py-1 rounded-lg bg-slate-100 border border-slate-200 text-[12px] font-mono font-bold text-slate-600 shrink-0">
          {filtered.length}
        </span>
      </div>

      {/* Filters */}
      <div className="px-5 pt-3 pb-2 space-y-2.5 shrink-0">
        {/* Search */}
        <div className="relative">
          <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
          <input
            type="text"
            placeholder="Search UPI VPA, TX ID, reason code…"
            value={searchQuery}
            onChange={e => setSearchQuery(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-8 pr-3 py-2 text-[12px] font-medium text-slate-900 placeholder-slate-400 outline-none focus:border-blue-500 focus:bg-white transition"
          />
        </div>

        {/* Filter chips */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1">
          {(['ALL', 'HIGH', 'MEDIUM', 'LOW'] as const).map(b => (
            <button
              key={b}
              onClick={() => setFilterBand(b)}
              className={`shrink-0 px-2.5 py-1 rounded-lg text-[11px] font-bold transition-all ${
                filterBand === b
                  ? 'bg-slate-900 text-white'
                  : 'bg-slate-100 text-slate-500 hover:bg-slate-200'
              }`}
            >
              {b === 'ALL' ? 'All Risks' : b}
            </button>
          ))}
          <div className="w-px h-3.5 bg-slate-200 mx-0.5 shrink-0" />
          {(['ALL', 'INCOMING', 'OUTGOING'] as const).map(d => (
            <button
              key={d}
              onClick={() => setFilterDirection(d)}
              className={`shrink-0 px-2.5 py-1 rounded-lg text-[11px] font-bold transition-all ${
                filterDirection === d
                  ? 'bg-blue-600 text-white'
                  : 'bg-slate-100 text-slate-500 hover:bg-slate-200'
              }`}
            >
              {d === 'ALL' ? 'All Types' : d === 'INCOMING' ? '↙ In' : '↗ Out'}
            </button>
          ))}
        </div>
      </div>

      {/* Alert List */}
      <div className="flex-1 overflow-y-auto px-4 pb-4 space-y-2">
        {filtered.length === 0 ? (
          <div className="py-16 text-center text-slate-400">
            <Search size={28} className="mx-auto mb-3 opacity-40" />
            <p className="text-[13px] font-medium">No transactions match filters</p>
          </div>
        ) : (
          filtered.map(alert => {
            const isSelected  = selectedAlert?.id === alert.id;
            const isIncoming  = alert.direction === 'INCOMING';
            const risk        = RISK_CONFIG[alert.riskBand];

            return (
              <div
                key={alert.id}
                onClick={() => onSelectAlert(alert)}
                className={`relative rounded-xl border p-3.5 cursor-pointer transition-all duration-150 overflow-hidden animate-slide-up ${
                  isSelected
                    ? 'bg-blue-50 border-blue-500 shadow-selected'
                    : 'bg-white border-slate-200 hover:border-slate-300 hover:shadow-xs'
                }`}
              >
                {/* LIVE badge */}
                {alert.isLive && (
                  <div className="absolute top-0 right-0 bg-blue-600 text-white text-[9px] font-bold px-2 py-0.5 rounded-bl-lg flex items-center gap-1">
                    <Sparkles size={9} /> LIVE
                  </div>
                )}

                {/* Row 1: Amount + Risk badge */}
                <div className="flex items-center justify-between gap-2 mb-2">
                  <div className="flex items-center gap-2 min-w-0">
                    <div className={`w-6 h-6 rounded-md flex items-center justify-center shrink-0 ${
                      isIncoming ? 'bg-emerald-100 text-emerald-600' : 'bg-blue-100 text-blue-600'
                    }`}>
                      {isIncoming ? <ArrowDownLeft size={13} /> : <ArrowUpRight size={13} />}
                    </div>
                    <span className="text-[13px] font-bold font-mono text-slate-900">
                      ₹{alert.amount.toLocaleString('en-IN')}
                    </span>
                    <span className={`text-[10px] font-medium ${isIncoming ? 'text-emerald-600' : 'text-blue-600'}`}>
                      {isIncoming ? 'CREDIT' : 'DEBIT'}
                    </span>
                  </div>
                  <span className={`shrink-0 px-2 py-0.5 rounded-md text-[10px] font-bold border ${risk.bg} ${risk.border} ${risk.text}`}>
                    {alert.riskScore} · {alert.riskBand}
                  </span>
                </div>

                {/* Row 2: Counterparty */}
                <p className="text-[12px] font-semibold text-slate-800 truncate mb-1.5" title={alert.counterparty}>
                  {alert.counterparty}
                </p>

                {/* Risk score gauge bar */}
                <div className="gauge-track mb-2">
                  <div
                    className={`gauge-fill ${risk.bar} opacity-70`}
                    style={{ width: `${alert.riskScore}%` }}
                  />
                </div>

                {/* Row 3: Reason + Time */}
                <div className="flex items-center justify-between gap-2">
                  <span className="bg-slate-100 text-slate-600 text-[10px] font-mono font-medium px-1.5 py-0.5 rounded truncate max-w-[60%]">
                    {alert.reasonCodes[0] || 'ROUTINE'}
                  </span>
                  <span className="shrink-0 flex items-center gap-1 text-[10px] text-slate-400 font-medium">
                    <Clock size={10} />
                    {alert.timestamp}
                  </span>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
};
