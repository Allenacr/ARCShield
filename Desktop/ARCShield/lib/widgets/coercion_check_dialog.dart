import 'package:flutter/material.dart';

class CoercionCheckDialog extends StatefulWidget {
  final double amount;
  final String recipient;
  final Function(Map<String, bool> answers) onVerified;

  const CoercionCheckDialog({
    super.key,
    required this.amount,
    required this.recipient,
    required this.onVerified,
  });

  @override
  State<CoercionCheckDialog> createState() => _CoercionCheckDialogState();
}

class _CoercionCheckDialogState extends State<CoercionCheckDialog> {
  bool _urgent = false;
  bool _secret = false;
  bool _safeAccount = false;
  bool _shareCode = false;

  @override
  Widget build(BuildContext context) {
    final hasRedFlags = _urgent || _secret || _safeAccount || _shareCode;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: hasRedFlags ? const Color(0xFFFAD2CF) : const Color(0xFFE8EAED),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasRedFlags ? const Color(0xFFFCE8E6) : const Color(0xFFE8F0FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    hasRedFlags ? Icons.warning_amber_rounded : Icons.shield_outlined,
                    color: hasRedFlags ? const Color(0xFFD93025) : const Color(0xFF0B57D0),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Safety Verification',
                    style: TextStyle(
                      color: Color(0xFF1F1F1F),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Before completing this transfer, please answer honestly to protect your funds:',
              style: TextStyle(color: Color(0xFF5F6368), fontSize: 13),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _urgent,
              onChanged: (val) => setState(() => _urgent = val ?? false),
              title: const Text('Someone told me to act immediately or pay urgently',
                  style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFD93025),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _secret,
              onChanged: (val) => setState(() => _secret = val ?? false),
              title: const Text('Someone told me to keep this transfer secret',
                  style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFD93025),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _safeAccount,
              onChanged: (val) => setState(() => _safeAccount = val ?? false),
              title: const Text('Someone claims this is a "safe account" or police verification',
                  style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFD93025),
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              value: _shareCode,
              onChanged: (val) => setState(() => _shareCode = val ?? false),
              title: const Text('Someone asked me to read back a verification code / OTP',
                  style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 13)),
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: const Color(0xFFD93025),
              contentPadding: EdgeInsets.zero,
            ),
            if (hasRedFlags) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCE8E6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFAD2CF)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Color(0xFFC5221F), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'WARNING: Legitimate banks and police NEVER ask you to transfer funds to a "safe account". This is likely an impersonation scam.',
                        style: TextStyle(color: Color(0xFFC5221F), fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDADCE0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onVerified({
                        'urgent': _urgent,
                        'secret': _secret,
                        'safe_account': _safeAccount,
                        'share_code': _shareCode,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasRedFlags ? const Color(0xFFD93025) : const Color(0xFF0B57D0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      hasRedFlags ? 'Confirm Risk' : 'Proceed',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
