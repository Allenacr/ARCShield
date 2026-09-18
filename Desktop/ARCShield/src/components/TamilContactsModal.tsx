import React, { useState } from 'react';
import { X, Search, ArrowUpRight, ShieldCheck, MapPin } from 'lucide-react';

interface TamilContact {
  id: string;
  name: string;
  phone: string;
  upi: string;
  location: string;
  initials: string;
  color: string;
}

const TAMIL_CONTACTS: TamilContact[] = [
  { id: 'tn-1', name: 'Karthik Raja',   phone: '+91 98410 23456', upi: 'karthik.raja@okaxis',     location: 'Chennai',          initials: 'KR', color: 'bg-blue-600'    },
  { id: 'tn-2', name: 'Saravanan M',    phone: '+91 94431 87654', upi: 'saravanan.m@oksbi',        location: 'Madurai',          initials: 'SM', color: 'bg-emerald-600' },
  { id: 'tn-3', name: 'Sangeetha R',    phone: '+91 97890 54321', upi: 'sangeetha.r@okhdfcbank',   location: 'Coimbatore',       initials: 'SR', color: 'bg-violet-600'  },
  { id: 'tn-4', name: 'Priya D',        phone: '+91 98940 11223', upi: 'priya.d@okicici',           location: 'Salem',            initials: 'PD', color: 'bg-pink-600'    },
  { id: 'tn-5', name: 'Muthu Kumar',    phone: '+91 94860 33445', upi: 'muthu.kumar@okaxis',        location: 'Tiruchirappalli', initials: 'MK', color: 'bg-amber-600'   },
  { id: 'tn-6', name: 'Anitha S',       phone: '+91 97500 77889', upi: 'anitha.s@oksbi',            location: 'Tirunelveli',      initials: 'AS', color: 'bg-teal-600'    },
  { id: 'tn-7', name: 'Vignesh K',      phone: '+91 96290 99001', upi: 'vignesh.k@okhdfcbank',     location: 'Vellore',          initials: 'VK', color: 'bg-indigo-600'  },
  { id: 'tn-8', name: 'Lakshmi N',      phone: '+91 94440 66778', upi: 'lakshmi.n@okaxis',          location: 'Thanjavur',        initials: 'LN', color: 'bg-cyan-600'    },
];

const QUICK_AMOUNTS = ['500', '2500', '15000', '75000'];

interface TamilContactsModalProps {
  onClose: () => void;
  onSelectContactForTransfer: (contact: TamilContact, amount: number) => void;
}

export const TamilContactsModal: React.FC<TamilContactsModalProps> = ({
  onClose,
  onSelectContactForTransfer,
}) => {
  const [search, setSearch]         = useState('');
  const [selected, setSelected]     = useState<TamilContact | null>(TAMIL_CONTACTS[0]);
  const [transferAmt, setTransferAmt] = useState('2500');

  const filtered = TAMIL_CONTACTS.filter(c =>
    c.name.toLowerCase().includes(search.toLowerCase()) ||
    c.upi.toLowerCase().includes(search.toLowerCase()) ||
    c.location.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4 animate-fade-in">
      <div className="bg-white rounded-2xl border border-slate-200 w-full max-w-2xl shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">

        {/* Modal Header */}
        <div className="px-6 py-5 border-b border-slate-100 flex items-center justify-between shrink-0">
          <div>
            <h3 className="text-[16px] font-bold font-display text-slate-900">Tamil Nadu Contact Directory</h3>
            <p className="text-[12px] text-slate-400 font-medium mt-0.5">
              Simulate ARCShield-protected UPI transfers to verified beneficiaries
            </p>
          </div>
          <button
            onClick={onClose}
            className="p-2 rounded-xl text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition"
          >
            <X size={17} />
          </button>
        </div>

        {/* Search */}
        <div className="px-6 pt-4 pb-2 shrink-0">
          <div className="relative">
            <Search size={13} className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" />
            <input
              type="text"
              placeholder="Search by name, city, or UPI VPA…"
              value={search}
              onChange={e => setSearch(e.target.value)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl pl-8 pr-4 py-2.5 text-[12px] font-medium text-slate-900 placeholder-slate-400 focus:outline-none focus:border-blue-500 focus:bg-white transition"
            />
          </div>
        </div>

        {/* Body: Contact list + Pay panel */}
        <div className="flex-1 overflow-hidden flex gap-0 px-6 pb-6 pt-3">

          {/* Contact List */}
          <div className="flex-1 overflow-y-auto pr-4 space-y-1.5 border-r border-slate-100 mr-4">
            {filtered.map(contact => {
              const isSel = selected?.id === contact.id;
              return (
                <div
                  key={contact.id}
                  onClick={() => setSelected(contact)}
                  className={`flex items-center gap-3 p-3 rounded-xl border cursor-pointer transition-all ${
                    isSel
                      ? 'bg-blue-50 border-blue-400'
                      : 'bg-white border-slate-200 hover:border-slate-300 hover:bg-slate-50'
                  }`}
                >
                  <div className={`w-9 h-9 rounded-xl ${contact.color} text-white text-[12px] font-bold flex items-center justify-center shrink-0`}>
                    {contact.initials}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="text-[13px] font-semibold text-slate-900 leading-tight truncate">{contact.name}</p>
                    <p className="text-[11px] font-mono text-slate-400 truncate">{contact.upi}</p>
                  </div>
                  <span className="shrink-0 text-[10px] font-medium text-slate-400 bg-slate-100 px-2 py-0.5 rounded-full flex items-center gap-1">
                    <MapPin size={9} />
                    {contact.location}
                  </span>
                </div>
              );
            })}
          </div>

          {/* Pay Panel */}
          <div className="w-52 shrink-0 flex flex-col">
            {selected ? (
              <>
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-3 mb-3">
                  <div className="flex items-center gap-2.5">
                    <div className={`w-10 h-10 rounded-xl ${selected.color} text-white text-[13px] font-bold flex items-center justify-center`}>
                      {selected.initials}
                    </div>
                    <div className="min-w-0">
                      <p className="text-[13px] font-semibold text-slate-900 leading-tight truncate">{selected.name}</p>
                      <p className="text-[10px] font-mono text-blue-600 truncate">{selected.upi}</p>
                    </div>
                  </div>
                  <div className="flex items-center gap-1.5 text-[11px] text-slate-400 font-medium">
                    <ShieldCheck size={12} className="text-emerald-500" />
                    ARCShield Protected
                  </div>
                </div>

                <label className="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5">Amount (₹)</label>
                <input
                  type="number"
                  value={transferAmt}
                  onChange={e => setTransferAmt(e.target.value)}
                  className="w-full bg-white border border-slate-300 rounded-xl px-3 py-2.5 text-[15px] font-bold font-mono text-slate-900 focus:outline-none focus:border-blue-500 transition mb-2"
                />

                {/* Quick amounts */}
                <div className="grid grid-cols-2 gap-1.5 mb-4">
                  {QUICK_AMOUNTS.map(amt => (
                    <button
                      key={amt}
                      onClick={() => setTransferAmt(amt)}
                      className={`py-1.5 rounded-xl text-[11px] font-bold border transition ${
                        transferAmt === amt
                          ? 'bg-blue-600 text-white border-blue-600'
                          : 'bg-white text-slate-600 border-slate-300 hover:border-blue-400 hover:text-blue-700'
                      }`}
                    >
                      ₹{parseInt(amt).toLocaleString('en-IN')}
                    </button>
                  ))}
                </div>

                <button
                  onClick={() => {
                    const amt = parseFloat(transferAmt) || 2500;
                    onSelectContactForTransfer(selected, amt);
                    onClose();
                  }}
                  className="w-full py-3 rounded-xl bg-blue-600 hover:bg-blue-700 text-white text-[13px] font-bold flex items-center justify-center gap-1.5 transition shadow-glow-blue mt-auto"
                >
                  Send Payment
                  <ArrowUpRight size={15} />
                </button>
              </>
            ) : (
              <div className="flex-1 flex items-center justify-center text-center">
                <p className="text-[12px] text-slate-400 font-medium">Select a contact to pay</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};
