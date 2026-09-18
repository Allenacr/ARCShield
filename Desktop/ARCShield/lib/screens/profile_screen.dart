import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/gpay_sheets.dart';
import '../models/account.dart';

class ProfileScreen extends StatefulWidget {
  final Account? account;
  const ProfileScreen({super.key, this.account});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _quarantineProtection = true;
  bool _coercionCheck = true;
  bool _fraudAlerts = true;
  bool _biometricAppLock = true;
  String _selectedLanguage = 'English (India)';

  void _showAddBankAccountSheet() {
    final banks = [
      {'name': 'HDFC Bank', 'code': 'HDFC'},
      {'name': 'State Bank of India', 'code': 'SBI'},
      {'name': 'ICICI Bank', 'code': 'ICICI'},
      {'name': 'Axis Bank', 'code': 'AXIS'},
      {'name': 'Kotak Mahindra Bank', 'code': 'KOTAK'},
      {'name': 'Punjab National Bank', 'code': 'PNB'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
            const Text('Select your bank',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
            const SizedBox(height: 4),
            const Text('An SMS will be sent from +91 98450 12345 to verify your account',
                style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: banks.length,
                itemBuilder: (_, i) {
                  final b = banks[i];
                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance, color: Color(0xFF0B57D0), size: 20),
                    ),
                    title: Text(b['name']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDC1C6)),
                    onTap: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Linked ${b['name']} account successfully with ARCShield verification!'),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog() {
    final langs = ['English (India)', 'हिन्दी (Hindi)', 'ಕನ್ನಡ (Kannada)', 'தமிழ் (Tamil)', 'తెలుగు (Telugu)'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Language'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        children: langs
            .map((lang) => SimpleDialogOption(
                  onPressed: () {
                    setState(() => _selectedLanguage = lang);
                    Navigator.pop(ctx);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(lang, style: const TextStyle(fontSize: 14)),
                        if (_selectedLanguage == lang)
                          const Icon(Icons.check, color: Color(0xFF0B57D0), size: 18),
                      ],
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  void _confirmSignOut() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out?'),
        content: const Text('You will need to re-verify your phone number (+91 98450 12345) next time you log in.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Signed out of Allen CR account')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD93025)),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mockAccount = widget.account ??
        Account(
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1F1F1F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Profile',
            style: TextStyle(color: Color(0xFF1F1F1F), fontWeight: FontWeight.w600, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code, color: Color(0xFF1F1F1F)),
            onPressed: () => UpiQrCodeSheet.show(context, mockAccount),
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFF1F1F1F)),
            onPressed: () => showHelpSupportSheet(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Profile Hero ──────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
              color: Colors.white,
              child: Column(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => UpiQrCodeSheet.show(context, mockAccount),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF0B57D0), Color(0xFF1E8E3E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text('AL',
                            style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Allen CR',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1F1F1F))),
                  const SizedBox(height: 4),
                  const Text('+91 98450 12345',
                      style: TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
                  const SizedBox(height: 6),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'allen.cr@okhdfcbank'));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('UPI ID copied to clipboard'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('allen.cr@okhdfcbank',
                            style: TextStyle(color: Color(0xFF5F6368), fontSize: 13)),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F0FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('Copy',
                              style: TextStyle(color: Color(0xFF0B57D0), fontSize: 11, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Shield badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F4EA),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, color: Color(0xFF1E8E3E), size: 14),
                        SizedBox(width: 6),
                        Text('ARCShield Protected',
                            style: TextStyle(color: Color(0xFF137333), fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE8EAED)),

            // ── Linked Bank Accounts ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Linked Bank Accounts',
                      style: TextStyle(
                          color: Color(0xFF5F6368), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  TextButton.icon(
                    onPressed: _showAddBankAccountSheet,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Bank', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
            _bankTile(
              bank: 'HDFC Bank',
              accountNo: '•••• 7241',
              isDefault: true,
              onTap: () => CheckBalanceDialog.show(context, mockAccount),
            ),
            _bankTile(
              bank: 'State Bank of India',
              accountNo: '•••• 8832',
              isDefault: false,
              onTap: () => CheckBalanceDialog.show(context, mockAccount),
            ),

            const Divider(height: 1, color: Color(0xFFE8EAED)),

            // ── ARCShield Security Settings ───────────────────────
            _sectionHeader('ARCShield Security'),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFE8F0FE), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.shield_outlined, color: Color(0xFF0B57D0), size: 20),
              ),
              title: const Text('Quarantine Protection',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F1F1F))),
              subtitle: const Text('Auto-hold suspicious incoming funds',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
              trailing: Switch(
                value: _quarantineProtection,
                activeThumbColor: const Color(0xFF0B57D0),
                onChanged: (val) {
                  setState(() => _quarantineProtection = val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(val
                          ? 'Quarantine Protection activated'
                          : 'Warning: Incoming fraud funds will not be auto-held'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.psychology_outlined, color: Color(0xFF1E8E3E), size: 20),
              ),
              title: const Text('Coercion Safety Prompt',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F1F1F))),
              subtitle: const Text('AI check for pressure or urgency (≥ ₹5,000)',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
              trailing: Switch(
                value: _coercionCheck,
                activeThumbColor: const Color(0xFF1E8E3E),
                onChanged: (val) => setState(() => _coercionCheck = val),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFFEF7E0), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.notifications_outlined, color: Color(0xFFB06000), size: 20),
              ),
              title: const Text('Real-time Fraud Alerts',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F1F1F))),
              subtitle: const Text('Push notifications for mule proximity',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
              trailing: Switch(
                value: _fraudAlerts,
                activeThumbColor: const Color(0xFF0B57D0),
                onChanged: (val) => setState(() => _fraudAlerts = val),
              ),
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: const Color(0xFFF1F3F4), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.fingerprint, color: Color(0xFF5F6368), size: 20),
              ),
              title: const Text('Biometric App Lock',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F1F1F))),
              subtitle: const Text('Fingerprint / Face unlock before payments',
                  style: TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
              trailing: Switch(
                value: _biometricAppLock,
                activeThumbColor: const Color(0xFF0B57D0),
                onChanged: (val) => setState(() => _biometricAppLock = val),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFE8EAED)),

            // ── General ───────────────────────────────────────────
            _sectionHeader('General Settings'),
            _settingsTile(
              icon: Icons.language_outlined,
              iconBg: const Color(0xFFF1F3F4),
              iconColor: const Color(0xFF5F6368),
              title: 'Language',
              subtitle: _selectedLanguage,
              onTap: _showLanguageDialog,
            ),
            _settingsTile(
              icon: Icons.autorenew,
              iconBg: const Color(0xFFF1F3F4),
              iconColor: const Color(0xFF5F6368),
              title: 'Autopay & Mandates',
              subtitle: '2 active (Netflix ₹499/mo, Spotify ₹119/mo)',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Autopay mandates verified by ARCShield')),
                );
              },
            ),
            _settingsTile(
              icon: Icons.help_outline,
              iconBg: const Color(0xFFF1F3F4),
              iconColor: const Color(0xFF5F6368),
              title: 'Help & Support',
              subtitle: 'Report an issue or contact 1930 Cyber helpline',
              onTap: () => showHelpSupportSheet(context),
            ),
            _settingsTile(
              icon: Icons.card_giftcard,
              iconBg: const Color(0xFFF1F3F4),
              iconColor: const Color(0xFF5F6368),
              title: 'Referral Rewards',
              subtitle: 'Code: ALLEN50 • Earn ₹51 per friend',
              onTap: () => showReferralDialog(context),
            ),

            const Divider(height: 1, color: Color(0xFFE8EAED)),

            // ── Sign Out ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _confirmSignOut,
                  icon: const Icon(Icons.logout, color: Color(0xFFD93025), size: 18),
                  label: const Text('Sign Out',
                      style: TextStyle(color: Color(0xFFD93025), fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFAD2CF)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
              ),
            ),

            // App version
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Text('ARCShield v1.0.0 (Google Pay UPI Engine)',
                  style: TextStyle(color: Color(0xFFBDC1C6), fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(title,
              style: const TextStyle(
                  color: Color(0xFF5F6368), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ),
      );

  Widget _bankTile({
    required String bank,
    required String accountNo,
    required bool isDefault,
    required VoidCallback onTap,
  }) =>
      ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F0FE),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.account_balance, color: Color(0xFF0B57D0), size: 20),
        ),
        title: Text(bank,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F1F1F))),
        subtitle: Text('A/C $accountNo • Tap to check balance',
            style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
        trailing: isDefault
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F4EA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text('Default',
                    style: TextStyle(color: Color(0xFF137333), fontSize: 11, fontWeight: FontWeight.w600)),
              )
            : const Icon(Icons.chevron_right, color: Color(0xFFBDC1C6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );

  Widget _settingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF1F1F1F))),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF5F6368))),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFBDC1C6)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
}
