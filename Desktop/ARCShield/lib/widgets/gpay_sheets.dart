import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../screens/send_money_screen.dart';

// ── Shared Helper Models ──────────────────────────────────────────────────────

class FakeContact {
  final String name;
  final String upiId;
  final String phone;
  final String initials;
  final int color;
  final List<FakeTransaction> history;

  const FakeContact({
    required this.name,
    required this.upiId,
    required this.phone,
    required this.initials,
    required this.color,
    this.history = const [],
  });
}

class FakeTransaction {
  final String id;
  final String title;
  final String subtitle;
  final double amount;
  final bool isCredit;
  final String date;
  final String upiRef;
  final String status;

  const FakeTransaction({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.isCredit,
    required this.date,
    required this.upiRef,
    this.status = 'Completed',
  });
}

// ── Tamil Nadu Preset Contacts for Allen CR ───────────────────────────────────

final List<FakeContact> fakePeople = [
  const FakeContact(
    name: 'Karthik',
    upiId: 'karthik.m@okhdfcbank',
    phone: '+91 98401 23456',
    initials: 'KM',
    color: 0xFF1E8E3E,
    history: [
      FakeTransaction(
        id: 'TXN-TN-01',
        title: 'Paid to Karthik',
        subtitle: 'Saravana Bhavan lunch split',
        amount: 450.0,
        isCredit: false,
        date: 'Yesterday, 1:45 PM',
        upiRef: '428190382910',
      ),
      FakeTransaction(
        id: 'TXN-TN-02',
        title: 'Received from Karthik',
        subtitle: 'Metro card topup share',
        amount: 200.0,
        isCredit: true,
        date: '12 Sep 2026, 6:15 PM',
        upiRef: '427189201948',
      ),
    ],
  ),
  const FakeContact(
    name: 'Vignesh',
    upiId: 'vignesh.s@okaxis',
    phone: '+91 98402 34567',
    initials: 'VS',
    color: 0xFF0B57D0,
    history: [
      FakeTransaction(
        id: 'TXN-TN-03',
        title: 'Paid to Vignesh',
        subtitle: 'Sathyam Cinemas IMAX tickets',
        amount: 850.0,
        isCredit: false,
        date: '10 Sep 2026, 9:20 PM',
        upiRef: '425981029384',
      ),
    ],
  ),
  const FakeContact(
    name: 'Meenakshi',
    upiId: 'meenakshi.r@okicici',
    phone: '+91 98403 45678',
    initials: 'MR',
    color: 0xFFD93025,
    history: [
      FakeTransaction(
        id: 'TXN-TN-04',
        title: 'Received from Meenakshi',
        subtitle: 'T. Nagar shopping share',
        amount: 1200.0,
        isCredit: true,
        date: '08 Sep 2026, 11:30 AM',
        upiRef: '424892019283',
      ),
    ],
  ),
  const FakeContact(
    name: 'Senthil',
    upiId: 'senthil.k@oksbi',
    phone: '+91 98404 56789',
    initials: 'SK',
    color: 0xFF7B1FA2,
    history: [
      FakeTransaction(
        id: 'TXN-TN-05',
        title: 'Paid to Senthil',
        subtitle: 'Kumbakonam degree coffee',
        amount: 180.0,
        isCredit: false,
        date: '05 Sep 2026, 5:10 PM',
        upiRef: '423891029384',
      ),
    ],
  ),
  const FakeContact(
    name: 'Soundarya',
    upiId: 'soundarya.v@okhdfcbank',
    phone: '+91 98405 67890',
    initials: 'SV',
    color: 0xFFE65100,
    history: [
      FakeTransaction(
        id: 'TXN-TN-06',
        title: 'Paid to Soundarya',
        subtitle: 'A2B sweets box',
        amount: 650.0,
        isCredit: false,
        date: '01 Sep 2026, 7:45 PM',
        upiRef: '421892039182',
      ),
    ],
  ),
  const FakeContact(
    name: 'Saravanan',
    upiId: 'saravanan.p@okaxis',
    phone: '+91 98406 78901',
    initials: 'SP',
    color: 0xFF00796B,
    history: [
      FakeTransaction(
        id: 'TXN-TN-07',
        title: 'Received from Saravanan',
        subtitle: 'ECR bike ride fuel split',
        amount: 320.0,
        isCredit: true,
        date: '28 Aug 2026, 4:12 PM',
        upiRef: '419820192834',
      ),
    ],
  ),
  const FakeContact(
    name: 'Nithya',
    upiId: 'nithya.s@oksbi',
    phone: '+91 98407 89012',
    initials: 'NS',
    color: 0xFF37474F,
    history: [
      FakeTransaction(
        id: 'TXN-TN-08',
        title: 'Paid to Nithya',
        subtitle: 'Higginbothams books & gifts',
        amount: 410.0,
        isCredit: false,
        date: '25 Aug 2026, 2:30 PM',
        upiRef: '418729102938',
      ),
    ],
  ),
];

final List<FakeContact> allExtendedContacts = [
  ...fakePeople,
  const FakeContact(
    name: 'Aravind Swamy',
    upiId: 'aravind.s@okhdfcbank',
    phone: '+91 98408 90123',
    initials: 'AS',
    color: 0xFF1976D2,
  ),
  const FakeContact(
    name: 'Anbarasu M',
    upiId: 'anbarasu.m@okicici',
    phone: '+91 98409 01234',
    initials: 'AM',
    color: 0xFFE91E63,
  ),
  const FakeContact(
    name: 'Dhanush Kumar',
    upiId: 'dhanush.k@okaxis',
    phone: '+91 98410 12345',
    initials: 'DK',
    color: 0xFF388E3C,
  ),
  const FakeContact(
    name: 'Kavitha Selvam',
    upiId: 'kavitha.s@oksbi',
    phone: '+91 98411 23456',
    initials: 'KS',
    color: 0xFFF57C00,
  ),
  const FakeContact(
    name: 'Thangavelu P',
    upiId: 'thangavel.p@okhdfcbank',
    phone: '+91 98412 34567',
    initials: 'TP',
    color: 0xFF8E24AA,
  ),
  const FakeContact(
    name: 'Vijay Anand',
    upiId: 'vijay.a@okaxis',
    phone: '+91 98413 45678',
    initials: 'VA',
    color: 0xFF0097A7,
  ),
  const FakeContact(
    name: 'Revathi Manian',
    upiId: 'revathi.m@okhdfcbank',
    phone: '+91 98414 56789',
    initials: 'RM',
    color: 0xFF5D4037,
  ),
  const FakeContact(
    name: 'Balamurugan T',
    upiId: 'balamurugan.t@oksbi',
    phone: '+91 98415 67890',
    initials: 'BT',
    color: 0xFF455A64,
  ),
  const FakeContact(
    name: 'Malathi Raman',
    upiId: 'malathi.r@okicici',
    phone: '+91 98416 78901',
    initials: 'MR',
    color: 0xFF2E7D32,
  ),
  const FakeContact(
    name: 'Ilango Pandian',
    upiId: 'ilango.p@okaxis',
    phone: '+91 98417 89012',
    initials: 'IP',
    color: 0xFFC2185B,
  ),
];

// ── 1. Bank Transfer Bottom Sheet ─────────────────────────────────────────────

class BankTransferSheet extends StatefulWidget {
  final Account account;
  const BankTransferSheet({super.key, required this.account});

  static void show(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BankTransferSheet(account: account),
    );
  }

  @override
  State<BankTransferSheet> createState() => _BankTransferSheetState();
}

class _BankTransferSheetState extends State<BankTransferSheet> {
  final _accNoController = TextEditingController(text: '50100492837190');
  final _reAccNoController = TextEditingController(text: '50100492837190');
  final _ifscController = TextEditingController(text: 'HDFC0001234');
  final _nameController = TextEditingController(text: 'Karthik Murugan');
  String _branchInfo = 'HDFC Bank, Anna Nagar West, Chennai';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADCE0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.account_balance, color: Color(0xFF0B57D0), size: 24),
                SizedBox(width: 10),
                Text(
                  'Bank Transfer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Transfer directly to any bank account in Tamil Nadu & India',
              style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
            ),
            const SizedBox(height: 20),

            // Account number
            TextField(
              controller: _accNoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Bank account number',
                prefixIcon: const Icon(Icons.pin, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Re-enter account number
            TextField(
              controller: _reAccNoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Re-enter account number',
                prefixIcon: const Icon(Icons.pin, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // IFSC code
            TextField(
              controller: _ifscController,
              textCapitalization: TextCapitalization.characters,
              onChanged: (val) {
                setState(() {
                  if (val.toUpperCase().startsWith('HDFC')) {
                    _branchInfo = 'HDFC Bank, Anna Nagar West, Chennai';
                  } else if (val.toUpperCase().startsWith('SBIN')) {
                    _branchInfo = 'State Bank of India, Mount Road, Chennai';
                  } else if (val.toUpperCase().startsWith('ICIC')) {
                    _branchInfo = 'ICICI Bank, T. Nagar Branch, Chennai';
                  } else {
                    _branchInfo = 'Verified Branch: Tamil Nadu Clearing Hub';
                  }
                });
              },
              decoration: InputDecoration(
                labelText: 'IFSC code',
                prefixIcon: const Icon(Icons.domain, size: 20),
                suffixText: 'Search IFSC',
                suffixStyle: const TextStyle(color: Color(0xFF0B57D0), fontWeight: FontWeight.w600, fontSize: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            if (_branchInfo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Color(0xFF1E8E3E), size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _branchInfo,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF1E8E3E), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),

            // Recipient name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Recipient name',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),

            // ARCShield Safe Bank Transfer Badge
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFD2E3FC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield, color: Color(0xFF0B57D0), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'ARCShield Account Name Verification matched with beneficiary bank records.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF0B57D0), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SendMoneyScreen(
                        account: widget.account,
                        prefillName: _nameController.text.trim(),
                        prefillUpiId:
                            '${_accNoController.text.trim()}@${_ifscController.text.trim().toLowerCase()}.ifsc.npci',
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B57D0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: const Text('Confirm & Proceed', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 2. Mobile Recharge Bottom Sheet ───────────────────────────────────────────

class MobileRechargeSheet extends StatefulWidget {
  final Account account;
  final Function(double amount)? onRechargeCompleted;
  const MobileRechargeSheet({super.key, required this.account, this.onRechargeCompleted});

  static void show(BuildContext context, Account account, {Function(double amount)? onRechargeCompleted}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MobileRechargeSheet(account: account, onRechargeCompleted: onRechargeCompleted),
    );
  }

  @override
  State<MobileRechargeSheet> createState() => _MobileRechargeSheetState();
}

class _MobileRechargeSheetState extends State<MobileRechargeSheet> {
  final _phoneController = TextEditingController(text: '98401 23456');
  String _selectedOperator = 'Jio Prepaid - Tamil Nadu';
  int _selectedPlanIndex = 0;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _plans = [
    {
      'amount': 299.0,
      'validity': '28 Days',
      'data': '1.5 GB/day',
      'voice': 'Unlimited Calls',
      'tag': 'POPULAR',
      'desc': 'True 5G Unlimited + 100 SMS/day + JioCinema in Tamil Nadu',
    },
    {
      'amount': 349.0,
      'validity': '28 Days',
      'data': '2.0 GB/day',
      'voice': 'Unlimited Calls',
      'tag': 'BEST VALUE',
      'desc': 'Extra Data + JioCinema Premium trial subscription',
    },
    {
      'amount': 666.0,
      'validity': '84 Days',
      'data': '1.5 GB/day',
      'voice': 'Unlimited Calls',
      'tag': 'LONG VALIDITY',
      'desc': 'Quarterly pack with continuous high speed data in TN',
    },
    {
      'amount': 19.0,
      'validity': 'Base Plan',
      'data': '1.0 GB Booster',
      'voice': 'Data Only',
      'tag': 'TOP-UP',
      'desc': 'Instant 1GB high-speed data booster add-on',
    },
  ];

  void _executeRecharge() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _isProcessing = false);

    final plan = _plans[_selectedPlanIndex];
    final double amt = plan['amount'] as double;
    Navigator.pop(context);

    widget.onRechargeCompleted?.call(amt);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: Color(0xFFE6F4EA),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, color: Color(0xFF1E8E3E), size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Recharge Successful!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
            const SizedBox(height: 8),
            Text('₹${amt.toStringAsFixed(0)} pack credited to +91 ${_phoneController.text}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _receiptRow('Operator', _selectedOperator.split(' - ').first),
                  _receiptRow('Order ID', 'REC${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}'),
                  _receiptRow('Paid via', 'HDFC Bank ••••7241'),
                  _receiptRow('ARCShield Status', 'Verified Genuine'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(ctx),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B57D0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _receiptRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
            Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDADCE0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.phone_android, color: Color(0xFF0B57D0), size: 24),
                SizedBox(width: 10),
                Text('Mobile Recharge',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
              ],
            ),
            const SizedBox(height: 16),

            // Phone input
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Mobile number',
                prefixText: '+91 ',
                prefixIcon: const Icon(Icons.contacts_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),

            // Operator selector (Tamil Nadu circles)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFDADCE0)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedOperator,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 'Jio Prepaid - Tamil Nadu', child: Text('Jio Prepaid - Tamil Nadu')),
                    DropdownMenuItem(
                        value: 'Airtel Prepaid - Chennai & TN', child: Text('Airtel Prepaid - Chennai & TN')),
                    DropdownMenuItem(value: 'Vi Prepaid - Tamil Nadu', child: Text('Vi Prepaid - Tamil Nadu')),
                    DropdownMenuItem(value: 'BSNL Prepaid - Tamil Nadu', child: Text('BSNL Prepaid - Tamil Nadu')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedOperator = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            const Text('Popular Plans (Tamil Nadu)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
            const SizedBox(height: 10),

            // Plans list
            ...List.generate(_plans.length, (i) {
              final p = _plans[i];
              final isSelected = _selectedPlanIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedPlanIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFE8F0FE) : Colors.white,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0B57D0) : const Color(0xFFE8EAED),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Radio<int>(
                        value: i,
                        groupValue: _selectedPlanIndex,
                        activeColor: const Color(0xFF0B57D0),
                        onChanged: (val) => setState(() => _selectedPlanIndex = val!),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text('₹${(p['amount'] as double).toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE6F4EA),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(p['tag'] as String,
                                      style: const TextStyle(
                                          color: Color(0xFF137333), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('${p['data']} • ${p['validity']} • ${p['voice']}',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3C4043))),
                            const SizedBox(height: 2),
                            Text(p['desc'] as String,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 10),
            // Pay button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isProcessing ? null : _executeRecharge,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B57D0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'Recharge ₹${(_plans[_selectedPlanIndex]['amount'] as double).toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 3. Contact Detail & Quick Pay Sheet ────────────────────────────────────────

class ContactDetailSheet extends StatelessWidget {
  final FakeContact contact;
  final Account account;
  const ContactDetailSheet({super.key, required this.contact, required this.account});

  static void show(BuildContext context, FakeContact contact, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactDetailSheet(contact: contact, account: account),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDADCE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Contact avatar
          CircleAvatar(
            radius: 36,
            backgroundColor: Color(contact.color).withValues(alpha: 0.18),
            child: Text(
              contact.initials,
              style: TextStyle(
                color: Color(contact.color),
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(contact.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
          const SizedBox(height: 4),
          Text('${contact.phone} • ${contact.upiId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
          const SizedBox(height: 6),
          // Verified badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFE6F4EA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Color(0xFF1E8E3E), size: 12),
                SizedBox(width: 4),
                Text('ARCShield Verified Contact',
                    style: TextStyle(fontSize: 11, color: Color(0xFF137333), fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Transaction history snippets
          if (contact.history.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Recent Activity',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5F6368))),
            ),
            const SizedBox(height: 8),
            ...contact.history.map((tx) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                        size: 16,
                        color: tx.isCredit ? const Color(0xFF1E8E3E) : const Color(0xFF5F6368),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            Text(tx.date, style: const TextStyle(fontSize: 10, color: Color(0xFF5F6368))),
                          ],
                        ),
                      ),
                      Text(
                        '${tx.isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: tx.isCredit ? const Color(0xFF1E8E3E) : const Color(0xFF1F1F1F),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
          ],

          // Pay & Request buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Payment request of ₹500 sent to ${contact.name}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFF0B57D0)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Request', style: TextStyle(color: Color(0xFF0B57D0), fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SendMoneyScreen(
                          account: account,
                          prefillName: contact.name,
                          prefillUpiId: contact.upiId,
                        ),
                      ),
                    );
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B57D0),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  child: const Text('Pay', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 4. All Contacts Bottom Sheet (Tapping "More") ─────────────────────────────

class AllContactsSheet extends StatefulWidget {
  final Account account;
  const AllContactsSheet({super.key, required this.account});

  static void show(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AllContactsSheet(account: account),
    );
  }

  @override
  State<AllContactsSheet> createState() => _AllContactsSheetState();
}

class _AllContactsSheetState extends State<AllContactsSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = allExtendedContacts
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.upiId.toLowerCase().contains(_query.toLowerCase()) ||
            c.phone.contains(_query))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDADCE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Tamil Nadu Contacts Directory',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search by name, phone or UPI ID',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF5F6368)),
              filled: true,
              fillColor: const Color(0xFFF1F3F4),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final c = filtered[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  leading: CircleAvatar(
                    backgroundColor: Color(c.color).withValues(alpha: 0.18),
                    child: Text(c.initials,
                        style: TextStyle(color: Color(c.color), fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                  title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text('${c.phone} • ${c.upiId}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDC1C6), size: 20),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SendMoneyScreen(
                          account: widget.account,
                          prefillName: c.name,
                          prefillUpiId: c.upiId,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── 5. Tap & Pay Contactless Modal ────────────────────────────────────────────

class TapAndPaySheet extends StatelessWidget {
  const TapAndPaySheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const TapAndPaySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDADCE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Animated wave icon
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFE8F0FE),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.contactless, color: Color(0xFF0B57D0), size: 48),
          ),
          const SizedBox(height: 16),
          const Text('Hold near terminal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
          const SizedBox(height: 8),
          const Text(
            'Keep your phone near the contactless reader to pay instantly',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
          ),
          const SizedBox(height: 20),
          // Card info
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: const Row(
              children: [
                Icon(Icons.credit_card, color: Color(0xFF0B57D0), size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('HDFC Bank Platinum Debit',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Card ending in ••••7241 • Ready to Tap',
                          style: TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: Color(0xFF1E8E3E), size: 18),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Simulated Tap & Pay: ₹120 paid to Saravana Bhavan Anna Nagar via NFC'),
                    backgroundColor: Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B57D0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Simulate POS Terminal Tap', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 6. UPI Lite Management Modal ─────────────────────────────────────────────

class UpiLiteSheet extends StatefulWidget {
  final Account account;
  const UpiLiteSheet({super.key, required this.account});

  static void show(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => UpiLiteSheet(account: account),
    );
  }

  @override
  State<UpiLiteSheet> createState() => _UpiLiteSheetState();
}

class _UpiLiteSheetState extends State<UpiLiteSheet> {
  double _liteBalance = 2000.0;

  void _addFunds(double amt) {
    setState(() => _liteBalance += amt);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ₹${amt.toStringAsFixed(0)} to UPI Lite! New balance: ₹${_liteBalance.toStringAsFixed(0)}'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDADCE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UPI Lite Wallet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
                  Text('Pin-free payments up to ₹500',
                      style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('ACTIVE',
                    style: TextStyle(color: Color(0xFF137333), fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Balance card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0B57D0), Color(0xFF1A73E8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available UPI Lite Balance',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Text('₹${_liteBalance.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('Linked to HDFC Bank ••••7241 (Chennai Anna Nagar)',
                    style: TextStyle(color: Colors.white70, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Top up UPI Lite',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF5F6368))),
          const SizedBox(height: 8),
          Row(
            children: [
              _topUpChip(500),
              const SizedBox(width: 8),
              _topUpChip(1000),
              const SizedBox(width: 8),
              _topUpChip(2000),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SendMoneyScreen(
                      account: widget.account,
                      prefillAmount: '150',
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0B57D0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Pay with UPI Lite', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topUpChip(double amt) {
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _addFunds(amt),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFF0B57D0)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: Text('+₹${amt.toStringAsFixed(0)}',
            style: const TextStyle(color: Color(0xFF0B57D0), fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── 7. Allen's UPI QR Code Modal ─────────────────────────────────────────────

class UpiQrCodeSheet extends StatelessWidget {
  final Account account;
  const UpiQrCodeSheet({super.key, required this.account});

  static void show(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UpiQrCodeSheet(account: account),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDADCE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Scan to pay Allen CR',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
          const SizedBox(height: 4),
          const Text('UPI ID: allen.cr@okhdfcbank',
              style: TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
          const SizedBox(height: 20),

          // Visual QR Box
          Container(
            width: 200,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE8EAED), width: 1.5),
              boxShadow: const [
                BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 4,
                      crossAxisSpacing: 4,
                    ),
                    itemCount: 49,
                    itemBuilder: (_, i) {
                      final bool isCorner = (i < 3 || (i >= 7 && i < 10) || (i >= 14 && i < 17)) ||
                          (i % 7 >= 4 && i < 21) ||
                          (i >= 35 && i % 7 < 3);
                      final bool isFilled = isCorner || (i * 17) % 3 == 0;
                      return Container(
                        decoration: BoxDecoration(
                          color: isFilled ? const Color(0xFF1F1F1F) : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Color(0xFF0B57D0),
                      child: Text('AL',
                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Copy & Share buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: 'allen.cr@okhdfcbank'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UPI ID copied to clipboard'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16, color: Color(0xFF0B57D0)),
                label: const Text('Copy UPI ID', style: TextStyle(color: Color(0xFF0B57D0))),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0B57D0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('QR Code shared via secure link'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share QR'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0B57D0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── 8. Check Bank Balance Dialog with 4-digit PIN Pad ─────────────────────────

class CheckBalanceDialog extends StatefulWidget {
  final Account account;
  const CheckBalanceDialog({super.key, required this.account});

  static void show(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckBalanceDialog(account: account),
    );
  }

  @override
  State<CheckBalanceDialog> createState() => _CheckBalanceDialogState();
}

class _CheckBalanceDialogState extends State<CheckBalanceDialog> {
  String _pin = '';
  bool _isLoading = false;
  bool _showBalance = false;

  void _onDigit(String d) {
    if (_pin.length < 4) {
      setState(() => _pin += d);
      if (_pin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onBackspace() {
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  void _verifyPin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 750));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _showBalance = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: _showBalance ? _buildBalanceResult() : _buildPinPad(),
    );
  }

  Widget _buildBalanceResult() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: const BoxDecoration(
            color: Color(0xFFE6F4EA),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle, color: Color(0xFF1E8E3E), size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Available Bank Balance',
            style: TextStyle(fontSize: 14, color: Color(0xFF5F6368))),
        const SizedBox(height: 8),
        Text(
          '₹${NumberFormat.currency(locale: 'en_IN', symbol: '').format(widget.account.availableBalance)}',
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
        ),
        const SizedBox(height: 4),
        const Text('HDFC Bank ••••7241 (Chennai Anna Nagar Branch)',
            style: TextStyle(fontSize: 13, color: Color(0xFF5F6368))),
        if (widget.account.heldBalance > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF7E0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.shield_outlined, color: Color(0xFFB06000), size: 16),
                const SizedBox(width: 8),
                Text(
                  '₹${widget.account.heldBalance.toStringAsFixed(0)} held under ARCShield Quarantine',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB06000), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 46,
          child: FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0B57D0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            ),
            child: const Text('Done'),
          ),
        ),
      ],
    );
  }

  Widget _buildPinPad() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFDADCE0),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Enter 4-Digit UPI PIN',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
        const SizedBox(height: 4),
        const Text('HDFC Bank Savings A/C ••••7241',
            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
        const SizedBox(height: 20),

        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 30),
            child: CircularProgressIndicator(color: Color(0xFF0B57D0)),
          )
        else ...[
          // Pin dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) {
              final isFilled = i < _pin.length;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 10),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isFilled ? const Color(0xFF0B57D0) : const Color(0xFFE8EAED),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),

          // Keypad
          for (var row in [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
            ['', '0', 'DEL'],
          ])
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: row.map((char) {
                  if (char.isEmpty) {
                    return const SizedBox(width: 70, height: 50);
                  }
                  if (char == 'DEL') {
                    return SizedBox(
                      width: 70,
                      height: 50,
                      child: IconButton(
                        icon: const Icon(Icons.backspace_outlined, size: 22, color: Color(0xFF5F6368)),
                        onPressed: _onBackspace,
                      ),
                    );
                  }
                  return SizedBox(
                    width: 70,
                    height: 50,
                    child: TextButton(
                      onPressed: () => _onDigit(char),
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                      ),
                      child: Text(
                        char,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F1F1F),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ],
    );
  }
}

// ── 9. Transaction Receipt Bottom Sheet ────────────────────────────────────────

class TransactionReceiptSheet extends StatelessWidget {
  final FakeTransaction transaction;
  const TransactionReceiptSheet({super.key, required this.transaction});

  static void show(BuildContext context, FakeTransaction transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionReceiptSheet(transaction: transaction),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDADCE0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Icon(Icons.check_circle, color: Color(0xFF1E8E3E), size: 48),
          const SizedBox(height: 8),
          Text(
            '₹${transaction.amount.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
          ),
          const SizedBox(height: 4),
          Text(transaction.title, style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368))),
          const SizedBox(height: 2),
          Text(transaction.date, style: const TextStyle(fontSize: 12, color: Color(0xFF80868B))),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _receiptItem('UPI Ref ID', transaction.upiRef),
                _receiptItem('Payment Method', 'HDFC Bank ••••7241'),
                _receiptItem('Status', transaction.status),
                _receiptItem('ARCShield Security', 'CLEAN (0.02 Risk Score)'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Dispute ticket raised with ARCShield Fraud Prevention')),
                    );
                  },
                  icon: const Icon(Icons.flag_outlined, size: 16, color: Color(0xFFD93025)),
                  label: const Text('Report Issue', style: TextStyle(color: Color(0xFFD93025))),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFAD2CF)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share Receipt'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B57D0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptItem(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(k, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
            Text(v, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F))),
          ],
        ),
      );
}

// ── 10. Search Overlay Modal ──────────────────────────────────────────────────

class SearchOverlaySheet extends StatefulWidget {
  final Account account;
  const SearchOverlaySheet({super.key, required this.account});

  static void show(BuildContext context, Account account) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchOverlaySheet(account: account),
    );
  }

  @override
  State<SearchOverlaySheet> createState() => _SearchOverlaySheetState();
}

class _SearchOverlaySheetState extends State<SearchOverlaySheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = allExtendedContacts
        .where((c) =>
            c.name.toLowerCase().contains(_query.toLowerCase()) ||
            c.upiId.toLowerCase().contains(_query.toLowerCase()) ||
            c.phone.contains(_query))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: 'Search Tamil Nadu contacts or merchants',
                    border: InputBorder.none,
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          Expanded(
            child: ListView(
              children: [
                if (_query.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('Recent Tamil Nadu searches',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5F6368))),
                  ),
                  _recentSearchTile('Karthik', 'karthik.m@okhdfcbank'),
                  _recentSearchTile('TANGEDCO Electricity', 'tangedco@tneb'),
                  _recentSearchTile('Saravana Bhavan', 'saravanabhavan@icici'),
                  _recentSearchTile('Vignesh', 'vignesh.s@okaxis'),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Text('All People & Contacts',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF5F6368))),
                  ),
                ],
                ...filtered.map((c) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Color(c.color).withValues(alpha: 0.18),
                        child: Text(c.initials,
                            style: TextStyle(color: Color(c.color), fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${c.phone} • ${c.upiId}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SendMoneyScreen(
                              account: widget.account,
                              prefillName: c.name,
                              prefillUpiId: c.upiId,
                            ),
                          ),
                        );
                      },
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recentSearchTile(String title, String subtitle) => ListTile(
        leading: const Icon(Icons.history, color: Color(0xFF5F6368), size: 20),
        title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF80868B))),
        onTap: () {
          setState(() {
            _query = title;
            _searchController.text = title;
          });
        },
      );
}

// ── 11. Referral Code Dialog ──────────────────────────────────────────────────

void showReferralDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.card_giftcard, color: Color(0xFF0B57D0)),
          SizedBox(width: 8),
          Text('Referral Code'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Invite friends to ARCShield Google Pay. You earn ₹51 and your friend earns ₹21 when they make their first payment!',
            style: TextStyle(fontSize: 13, color: Color(0xFF5F6368), height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDADCE0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('ALLEN50',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2)),
                TextButton(
                  onPressed: () {
                    Clipboard.setData(const ClipboardData(text: 'ALLEN50'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Referral code copied!')),
                    );
                  },
                  child: const Text('COPY'),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
      ],
    ),
  );
}

// ── 12. Help & Support Sheet ──────────────────────────────────────────────────

void showHelpSupportSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFDADCE0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Help & 24x7 Support',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
          const SizedBox(height: 6),
          const Text('Instant assistance for payments & security in Tamil Nadu',
              style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
          const SizedBox(height: 16),
          _helpTile(Icons.support_agent, 'Chat with ARCShield AI Assistant', 'Instant resolution for disputed payments'),
          _helpTile(Icons.shield_outlined, 'National Cyber Crime Helpline (1930)',
              'Direct integration with Tamil Nadu Cyber Crime Wing & MHA'),
          _helpTile(Icons.help_outline, 'UPI Transaction FAQs', 'Check status, refunds, and bank timelines'),
          const SizedBox(height: 16),
        ],
      ),
    ),
  );
}

Widget _helpTile(IconData icon, String title, String subtitle) => ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF0B57D0), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Color(0xFFBDC1C6)),
    );
