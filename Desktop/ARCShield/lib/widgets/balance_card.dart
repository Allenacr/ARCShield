import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/account.dart';

class BalanceCard extends StatelessWidget {
  final Account account;

  const BalanceCard({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
    final hasHeldBalance = account.heldBalance > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0FE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.account_balance, color: Color(0xFF0B57D0), size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.bankCode == 'BANK_A' ? 'State Bank of India' : 'HDFC Bank',
                        style: const TextStyle(
                          color: Color(0xFF1F1F1F),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'A/C ${account.accountNumber}',
                        style: const TextStyle(
                          color: Color(0xFF5F6368),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 12, color: Color(0xFF1E8E3E)),
                    SizedBox(width: 4),
                    Text(
                      'Default UPI',
                      style: TextStyle(
                        color: Color(0xFF3C4043),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Total balance',
            style: TextStyle(
              color: Color(0xFF5F6368),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatCurrency.format(account.totalBalance),
            style: const TextStyle(
              color: Color(0xFF1F1F1F),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE8EAED), height: 1),
          const SizedBox(height: 14),

          // Split Breakdown: Available vs Held
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F4EA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lock_open, size: 13, color: Color(0xFF137333)),
                          SizedBox(width: 4),
                          Text(
                            'Available to spend',
                            style: TextStyle(
                              color: Color(0xFF137333),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatCurrency.format(account.availableBalance),
                        style: const TextStyle(
                          color: Color(0xFF137333),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasHeldBalance) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCE8E6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield, size: 13, color: Color(0xFFC5221F)),
                            SizedBox(width: 4),
                            Text(
                              'Quarantined hold',
                              style: TextStyle(
                                color: Color(0xFFC5221F),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatCurrency.format(account.heldBalance),
                          style: const TextStyle(
                            color: Color(0xFFC5221F),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          if (hasHeldBalance) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF7E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFEEFC3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFB06000), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '₹${formatCurrency.format(account.heldBalance).replaceAll('₹', '').trim()} is quarantined for 24h. You are protected from mule liability.',
                      style: const TextStyle(color: Color(0xFF5F370E), fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
