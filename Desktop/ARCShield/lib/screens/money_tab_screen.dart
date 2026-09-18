import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';
import '../widgets/gpay_sheets.dart';
import 'profile_screen.dart';

class MoneyTabView extends StatelessWidget {
  final Account account;
  final VoidCallback? onCheckBalance;

  const MoneyTabView({
    super.key,
    required this.account,
    this.onCheckBalance,
  });

  @override
  Widget build(BuildContext context) {
    final recentTransactions = [
      const FakeTransaction(
        id: 'TXN-901',
        title: 'Karthik Murugan',
        subtitle: 'Saravana Bhavan lunch split',
        amount: 450.0,
        isCredit: false,
        date: 'Yesterday, 1:45 PM',
        upiRef: '428190382910',
      ),
      const FakeTransaction(
        id: 'TXN-902',
        title: 'Swiggy Chennai',
        subtitle: 'Order #SW982109 - Adyar',
        amount: 342.0,
        isCredit: false,
        date: '16 Sep 2026, 1:15 PM',
        upiRef: '427819201948',
      ),
      const FakeTransaction(
        id: 'TXN-903',
        title: 'Meenakshi',
        subtitle: 'T. Nagar shopping pool credit',
        amount: 1200.0,
        isCredit: true,
        date: '15 Sep 2026, 11:30 AM',
        upiRef: '426982019283',
      ),
      const FakeTransaction(
        id: 'TXN-904',
        title: 'TANGEDCO (TNEB)',
        subtitle: 'Consumer #09-241-014-982',
        amount: 1450.0,
        isCredit: false,
        date: '12 Sep 2026, 10:04 AM',
        upiRef: '425891029384',
      ),
      const FakeTransaction(
        id: 'TXN-905',
        title: 'Senthil',
        subtitle: 'Kumbakonam degree coffee',
        amount: 180.0,
        isCredit: false,
        date: '08 Sep 2026, 5:10 PM',
        upiRef: '424891029384',
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Money & Finance',
            style: TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF5F6368)),
            onPressed: () => showHelpSupportSheet(context),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF0B57D0),
                child: Text('AL', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Total Bank Balance Hero Card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B57D0), Color(0xFF1A73E8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x1F0B57D0), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Bank Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '₹${NumberFormat.currency(locale: 'en_IN', symbol: '').format(account.availableBalance)}',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => CheckBalanceDialog.show(context, account),
                        icon: const Icon(Icons.lock_outline, size: 16, color: Color(0xFF0B57D0)),
                        label: const Text('Check Balance',
                            style: TextStyle(color: Color(0xFF0B57D0), fontWeight: FontWeight.bold)),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () => UpiLiteSheet.show(context, account),
                        icon: const Icon(Icons.flash_on, size: 16, color: Colors.white),
                        label: const Text('UPI Lite: ₹2,000', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Linked Accounts Section
            _cardContainer(
              title: 'Linked Bank Accounts',
              child: Column(
                children: [
                  _bankRow(
                    context: context,
                    bankName: 'HDFC Bank',
                    accountNo: '•••• 7241',
                    isPrimary: true,
                    onTap: () => CheckBalanceDialog.show(context, account),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F3F4)),
                  _bankRow(
                    context: context,
                    bankName: 'State Bank of India',
                    accountNo: '•••• 8832',
                    isPrimary: false,
                    onTap: () => CheckBalanceDialog.show(context, account),
                  ),
                ],
              ),
            ),

            // CIBIL Credit Score Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text('782',
                          style: TextStyle(color: Color(0xFF1E8E3E), fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CIBIL Credit Score: Excellent',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1F1F1F))),
                        SizedBox(height: 2),
                        Text('Updated 2 days ago • No missed payments',
                            style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFBDC1C6)),
                ],
              ),
            ),

            // ARCShield Fraud Defense Vault Status
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user, color: Color(0xFF16A34A), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ARCShield Real-Time Defense',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF15803D))),
                        Text(
                          account.heldBalance > 0
                              ? '₹${account.heldBalance.toStringAsFixed(0)} actively quarantined for your protection.'
                              : 'All accounts safe. 0 mule hops detected in last 30 days.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Recent Transactions
            _cardContainer(
              title: 'Transaction History',
              action: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing all past statement records')),
                  );
                },
                child: const Text('View statement', style: TextStyle(fontSize: 12)),
              ),
              child: Column(
                children: recentTransactions.map((tx) {
                  return InkWell(
                    onTap: () => TransactionReceiptSheet.show(context, tx),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: tx.isCredit
                                  ? const Color(0xFFE6F4EA)
                                  : const Color(0xFFF1F3F4),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              tx.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                              color: tx.isCredit ? const Color(0xFF1E8E3E) : const Color(0xFF5F6368),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(tx.title,
                                    style: const TextStyle(
                                        fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F))),
                                const SizedBox(height: 2),
                                Text('${tx.subtitle} • ${tx.date}',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                              ],
                            ),
                          ),
                          Text(
                            '${tx.isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: tx.isCredit ? const Color(0xFF1E8E3E) : const Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _cardContainer({required String title, required Widget child, Widget? action}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
              if (action != null) action,
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _bankRow({
    required BuildContext context,
    required String bankName,
    required String accountNo,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.account_balance, color: Color(0xFF0B57D0), size: 20),
      ),
      title: Text(bankName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text('Savings $accountNo', style: const TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isPrimary)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(8)),
              child: const Text('Primary',
                  style: TextStyle(color: Color(0xFF137333), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          TextButton(
            onPressed: onTap,
            child: const Text('Check Balance', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
