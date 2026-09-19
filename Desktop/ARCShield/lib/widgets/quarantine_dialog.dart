import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/mobile_api_service.dart';

class QuarantineDialog extends StatefulWidget {
  final String transactionId;
  final String accountId;
  final double amount;
  final String counterparty;
  final List<String> reasonCodes;
  final ValueChanged<String> onActionCompleted;

  const QuarantineDialog({
    super.key,
    required this.transactionId,
    required this.accountId,
    required this.amount,
    required this.counterparty,
    required this.reasonCodes,
    required this.onActionCompleted,
  });

  @override
  State<QuarantineDialog> createState() => _QuarantineDialogState();
}

class _QuarantineDialogState extends State<QuarantineDialog> {
  bool _isLoading = false;

  String _formatReason(String code) {
    switch (code.toUpperCase().trim()) {
      case 'UNKNOWN_SENDER':
        return 'First-time transfer from an unknown sender.';
      case 'COMPLAINT_PROXIMITY_2_HOPS':
        return 'Sender account is 2 hops away from a reported cybercrime complaint.';
      case 'HIGH_PASS_THROUGH_RISK':
        return 'Pattern matches rapid money-mule pass-through behaviour.';
      case 'FAN_IN_PATTERN':
        return 'Sender received multiple rapid credits from other accounts.';
      case 'UNUSUAL_INFLOW':
        return 'Amount is significantly higher than your typical account inflow.';
      default:
        return code.replaceAll('_', ' ').toLowerCase();
    }
  }

  Future<void> _handleDecision(String decision) async {
    setState(() => _isLoading = true);
    try {
      await MobileApiService().recordDecision(
        transactionId: widget.transactionId,
        accountId: widget.accountId,
        amount: widget.amount,
        decision: decision,
        reason: 'Account holder chose $decision on unexpected incoming credit',
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onActionCompleted(decision);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: decision == 'HOLD' ? const Color(0xFF10B981) : const Color(0xFF0B57D0),
          content: Text(decision == 'HOLD'
              ? '₹${NumberFormat.currency(locale: 'en_IN', symbol: '').format(widget.amount)} held for 24 hours. The backend ledger has been updated.'
              : 'Your $decision decision was recorded by the backend.'),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: const Color(0xFFD93025), content: Text('Could not record decision: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: const BorderSide(color: Color(0xFFE8EAED), width: 1.0),
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
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE8E6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.shield,
                      color: Color(0xFFD93025), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unexpected Money Received',
                        style: TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Google Pay Safety Shield',
                        style: TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'A transfer of ${currency.format(widget.amount)} arrived from ${widget.counterparty}.',
              style: const TextStyle(color: Color(0xFF3C4043), fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 14),
            const Text(
              'Risk signals flagged by fraud guard:',
              style: TextStyle(
                color: Color(0xFFD93025),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8EAED)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: widget.reasonCodes.map((code) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(color: Color(0xFFD93025), fontWeight: FontWeight.bold)),
                        Expanded(
                          child: Text(
                            _formatReason(code),
                            style: const TextStyle(
                                color: Color(0xFF3C4043), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF7E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFB06000), size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Holding this credit for 24h prevents account freezing if this sender is part of a mule syndicate.',
                      style: TextStyle(color: Color(0xFF5F370E), fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _handleDecision('RECOGNISE'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFDADCE0)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Recognise',
                        style: TextStyle(color: Color(0xFF5F6368), fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _handleDecision('HOLD'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B57D0),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Hold for 24h',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
