class TransactionItem {
  final String id;
  final String? senderAccountId;
  final String? receiverAccountId;
  final double amount;
  final String direction; // 'INCOMING' | 'OUTGOING'
  final String status; // 'PENDING' | 'COMPLETED' | 'HELD' | 'REJECTED'
  final String counterpartyIdentifier;
  final String? referenceNote;
  final DateTime createdAt;
  final String? riskBand;
  final List<String>? reasonCodes;

  TransactionItem({
    required this.id,
    this.senderAccountId,
    this.receiverAccountId,
    required this.amount,
    required this.direction,
    required this.status,
    required this.counterpartyIdentifier,
    this.referenceNote,
    required this.createdAt,
    this.riskBand,
    this.reasonCodes,
  });

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      senderAccountId: json['sender_account_id'] as String?,
      receiverAccountId: json['receiver_account_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      direction: json['direction'] as String,
      status: (json['status'] ?? 'COMPLETED') as String,
      counterpartyIdentifier: (json['counterparty_identifier'] ?? 'Unknown') as String,
      referenceNote: json['reference_note'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      riskBand: json['risk_band'] as String?,
      reasonCodes: (json['reason_codes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
