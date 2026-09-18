import 'dart:async';
import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/notification_service.dart';
import '../widgets/quarantine_dialog.dart';
import '../widgets/gpay_sheets.dart';
import 'send_money_screen.dart';
import 'qr_scanner_screen.dart';
import 'profile_screen.dart';
import 'money_tab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final NotificationService _notificationService = NotificationService();
  StreamSubscription? _alertSub;
  int _selectedTab = 0;
  Map<String, dynamic>? _pendingAlert; // holds alert if received while off-screen

  Account _currentAccount = Account(
    id: 'demo-account-01',
    userId: 'demo-user-01',
    accountNumber: '•••• •••• 7241',
    upiId: 'allen.cr@okhdfcbank',
    bankCode: 'BANK_A',
    totalBalance: 124500.0,
    heldBalance: 0.0,
    availableBalance: 124500.0,
    isActive: true,
  );

  @override
  void initState() {
    super.initState();
    _listenToPushAlerts();
  }

  void _listenToPushAlerts() {
    _alertSub = _notificationService.alertStream.listen((data) {
      debugPrint('[HOME_SCREEN STREAM EVENT RECEIVED] $data');
      final String riskBand = data['risk_band'] ?? '';
      final String direction = data['direction'] ?? '';
      debugPrint('[HOME_SCREEN] direction=$direction, riskBand=$riskBand');
      if (direction == 'INCOMING' &&
          (riskBand == 'HIGH' || riskBand == 'MEDIUM')) {
        _pendingAlert = data;
        _tryShowAlertDialog();
      } else {
        debugPrint('[HOME_SCREEN] Condition not met (direction=$direction, riskBand=$riskBand)');
      }
    });
  }

  void _tryShowAlertDialog() {
    debugPrint('[HOME_SCREEN] _tryShowAlertDialog called. mounted=$mounted');
    if (!mounted || _pendingAlert == null) return;

    final data = _pendingAlert!;
    _pendingAlert = null;

    final double amount =
        double.tryParse(data['amount']?.toString() ?? '0') ?? 0.0;
    final String counterparty = data['counterparty'] ?? 'Unknown Sender';
    final String txId = data['transaction_id'] ?? 'demo-tx';
    final List<String> reasons = (data['reason_codes'] as String? ??
            'UNKNOWN_SENDER,COMPLAINT_PROXIMITY_2_HOPS,HIGH_PASS_THROUGH_RISK')
        .split(',');

    // Use postFrameCallback to ensure the widget tree is fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => QuarantineDialog(
          transactionId: txId,
          accountId: _currentAccount.id,
          amount: amount,
          counterparty: counterparty,
          reasonCodes: reasons,
          onActionCompleted: () {
            setState(() {
              _currentAccount = Account(
                id: _currentAccount.id,
                userId: _currentAccount.userId,
                accountNumber: _currentAccount.accountNumber,
                upiId: _currentAccount.upiId,
                bankCode: _currentAccount.bankCode,
                totalBalance: _currentAccount.totalBalance,
                heldBalance: _currentAccount.heldBalance + amount,
                availableBalance: _currentAccount.totalBalance -
                    (_currentAccount.heldBalance + amount),
                isActive: true,
              );
            });
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _alertSub?.cancel();
    super.dispose();
  }

  void _triggerScenario5CloserDemo() {
    _notificationService.simulateIncomingAlert(
      transactionId: 'tx-scenario-5-closer',
      counterparty: 'karan9921@upi (Stranger)',
      amount: 42000.0,
      reasonCodes: [
        'UNKNOWN_SENDER',
        'COMPLAINT_PROXIMITY_2_HOPS',
        'HIGH_PASS_THROUGH_RISK',
        'FAN_IN_PATTERN',
        'UNUSUAL_INFLOW',
      ],
    );
  }

  void _deductBalance(double amount) {
    setState(() {
      final newAvail = _currentAccount.availableBalance - amount;
      _currentAccount = Account(
        id: _currentAccount.id,
        userId: _currentAccount.userId,
        accountNumber: _currentAccount.accountNumber,
        upiId: _currentAccount.upiId,
        bankCode: _currentAccount.bankCode,
        totalBalance: _currentAccount.totalBalance - amount,
        heldBalance: _currentAccount.heldBalance,
        availableBalance: newAvail >= 0 ? newAvail : 0,
        isActive: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedTab,
          children: [
            // Tab 0: Home view
            _buildHomeContent(),
            // Tab 1: Money / Finance view
            MoneyTabView(
              account: _currentAccount,
              onCheckBalance: () => CheckBalanceDialog.show(context, _currentAccount),
            ),
            // Tab 2: Profile view
            ProfileScreen(account: _currentAccount),
          ],
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedTab,
        onTap: (i) => setState(() => _selectedTab = i),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF0B57D0),
        unselectedItemColor: const Color(0xFF5F6368),
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 12,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee_outlined),
            activeIcon: Icon(Icons.currency_rupee),
            label: 'Money',
          ),
          BottomNavigationBarItem(
            icon: CircleAvatar(
              radius: 12,
              backgroundColor: Color(0xFF0B57D0),
              child: Text(
                'AL',
                style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
              ),
            ),
            label: 'You',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent() {
    return Column(
      children: [
        // ── Search Bar ──────────────────────────────────────────
        _buildSearchBar(context),

        // ── Scrollable Body ────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Illustration
                _buildHeroBanner(),

                // White card containing quick actions + UPI strip
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0A000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 4 Quick Action squares
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionSquare(
                              icon: Icons.qr_code_scanner,
                              label: 'Scan any\nQR code',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QrScannerScreen(account: _currentAccount),
                                ),
                              ),
                            ),
                            _buildActionSquare(
                              icon: Icons.currency_rupee_outlined,
                              label: 'Pay\nanyone',
                              onTap: () async {
                                final res = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => SendMoneyScreen(account: _currentAccount),
                                  ),
                                );
                                if (res is double) _deductBalance(res);
                              },
                            ),
                            _buildActionSquare(
                              icon: Icons.account_balance_outlined,
                              label: 'Bank\ntransfer',
                              onTap: () => BankTransferSheet.show(context, _currentAccount),
                            ),
                            _buildActionSquare(
                              icon: Icons.phone_android_outlined,
                              label: 'Mobile\nrecharge',
                              onTap: () => MobileRechargeSheet.show(
                                context,
                                _currentAccount,
                                onRechargeCompleted: (amt) => _deductBalance(amt),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // UPI Info Strip
                      _buildUpiStrip(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // People Section
                _buildPeopleSection(context),

                // Businesses Section
                _buildBusinessesSection(context),

                // Bills & Utilities Section
                _buildBillsSection(context),

                // Check Bank Balance & Statement Shortcut Strip
                _buildFinanceShortcuts(),

                // ARCShield alert test (small card)
                _buildAlertTestCard(),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Search Bar ─────────────────────────────────────────────────────────────
  Widget _buildSearchBar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => SearchOverlaySheet.show(context, _currentAccount),
              child: Container(
                height: 46,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(23),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF5F6368), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search by name or number',
                        style: TextStyle(color: Color(0xFF5F6368), fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // More options
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F3F4),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF5F6368), size: 20),
              onSelected: (val) {
                if (val == 'profile') setState(() => _selectedTab = 2);
                if (val == 'referral') showReferralDialog(context);
                if (val == 'help') showHelpSupportSheet(context);
                if (val == 'alert') _triggerScenario5CloserDemo();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'profile', child: Text('My Profile (Allen CR)')),
                const PopupMenuItem(value: 'referral', child: Text('Referral Code')),
                const PopupMenuItem(value: 'help', child: Text('Help & 24x7 Support')),
                const PopupMenuItem(value: 'alert', child: Text('Test Fraud Alert')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero Illustration Banner ───────────────────────────────────────────────
  Widget _buildHeroBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/bank_hero.jpg',
              fit: BoxFit.cover,
            ),
            // Gradient overlay for contrast
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.35),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // ARCShield badge
            Positioned(
              bottom: 12,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(color: Color(0x1F000000), blurRadius: 4),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield, color: Color(0xFF0B57D0), size: 14),
                    SizedBox(width: 4),
                    Text(
                      'ARCShield Active',
                      style: TextStyle(
                        color: Color(0xFF0B57D0),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── UPI Strip ─────────────────────────────────────────────────────────────
  Widget _buildUpiStrip() {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () => TapAndPaySheet.show(context),
            child: _upiChip(Icons.contactless_outlined, 'Tap & Pay'),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => UpiLiteSheet.show(context, _currentAccount),
            child: _upiChip(Icons.account_balance_wallet_outlined, 'UPI Lite: ₹2,000'),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => UpiQrCodeSheet.show(context, _currentAccount),
            child: _upiChip(Icons.qr_code, 'UPI ID: allen.cr@okhdfcbank'),
          ),
        ],
      ),
    );
  }

  Widget _upiChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5F6368)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF3C4043), fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── Quick Action Square ────────────────────────────────────────────────────
  Widget _buildActionSquare({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F0FE),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(icon, color: const Color(0xFF0B57D0), size: 28),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF3C4043),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── People Section ─────────────────────────────────────────────────────────
  Widget _buildPeopleSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Text(
              'People',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 8,
                crossAxisSpacing: 0,
                childAspectRatio: 0.85,
              ),
              itemCount: fakePeople.length + 1, // 7 people + More
              itemBuilder: (_, i) {
                if (i == fakePeople.length) {
                  // "More" button
                  return GestureDetector(
                    onTap: () => AllContactsSheet.show(context, _currentAccount),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F3F4),
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFFE8EAED), width: 1.5),
                          ),
                          child: const Center(
                            child: Icon(Icons.keyboard_arrow_down, color: Color(0xFF5F6368), size: 24),
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          'More',
                          style: TextStyle(fontSize: 11, color: Color(0xFF3C4043), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  );
                }

                final c = fakePeople[i];
                return GestureDetector(
                  onTap: () => ContactDetailSheet.show(context, c, _currentAccount),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Color(c.color).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            c.initials,
                            style: TextStyle(
                              color: Color(c.color),
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        c.name,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF3C4043), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Businesses Section ─────────────────────────────────────────────────────
  Widget _buildBusinessesSection(BuildContext context) {
    final businesses = [
      {'name': 'Saravana Bhavan', 'upi': 'saravana@icici', 'icon': Icons.restaurant, 'color': 0xFFD93025},
      {'name': 'A2B Sweets', 'upi': 'a2b@icici', 'icon': Icons.cake, 'color': 0xFFFC8019},
      {'name': 'Swiggy Chennai', 'upi': 'swiggy@icici', 'icon': Icons.delivery_dining, 'color': 0xFFFC8019},
      {'name': 'Zepto Chennai', 'upi': 'zepto@axis', 'icon': Icons.shopping_bag, 'color': 0xFF7B1FA2},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Text('Businesses & Merchants',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: businesses.map((b) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SendMoneyScreen(
                          account: _currentAccount,
                          prefillName: b['name'] as String,
                          prefillUpiId: b['upi'] as String,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: Color(b['color'] as int).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(b['icon'] as IconData, color: Color(b['color'] as int), size: 24),
                      ),
                      const SizedBox(height: 5),
                      Text(b['name'] as String,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF3C4043))),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bills & Utilities Section ──────────────────────────────────────────────
  Widget _buildBillsSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bills & Recharges',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
          const SizedBox(height: 12),
          // TANGEDCO electricity bill due banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF7E0),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFECC0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.bolt, color: Color(0xFFB06000), size: 24),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TANGEDCO (TNEB) Electricity Bill',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
                      Text('Due in 3 days • Consumer #09-241-014-982 (Chennai South)',
                          style: TextStyle(fontSize: 11, color: Color(0xFF5F6368))),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final res = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SendMoneyScreen(
                          account: _currentAccount,
                          prefillName: 'TANGEDCO (TNEB)',
                          prefillUpiId: 'tangedco@tneb',
                          prefillAmount: '1450',
                        ),
                      ),
                    );
                    if (res is double) _deductBalance(res);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0B57D0),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Pay ₹1,450', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Finance Shortcuts (Check Balance, Transaction History) ─────────────────
  Widget _buildFinanceShortcuts() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.history, color: Color(0xFF0B57D0), size: 20),
            ),
            title: const Text('See transaction history',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDC1C6)),
            onTap: () => setState(() => _selectedTab = 1),
          ),
          const Divider(height: 1, color: Color(0xFFF1F3F4), indent: 56),
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.account_balance, color: Color(0xFF0B57D0), size: 20),
            ),
            title: const Text('Check bank balance',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F))),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDC1C6)),
            onTap: () => CheckBalanceDialog.show(context, _currentAccount),
          ),
        ],
      ),
    );
  }

  // ── ARCShield Alert Test Card ──────────────────────────────────────────────
  Widget _buildAlertTestCard() {
    return GestureDetector(
      onTap: _triggerScenario5CloserDemo,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE8E6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFAD2CF)),
        ),
        child: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFD93025), size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Test Fraud Protection',
                      style: TextStyle(color: Color(0xFFD93025), fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('Simulate an unexpected suspicious inflow',
                      style: TextStyle(color: Color(0xFFC5221F), fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Color(0xFFD93025), size: 20),
          ],
        ),
      ),
    );
  }
}
