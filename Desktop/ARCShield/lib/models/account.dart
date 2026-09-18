class Account {
  final String id;
  final String userId;
  final String accountNumber;
  final String upiId;
  final String bankCode;
  final double totalBalance;
  final double heldBalance;
  final double availableBalance;
  final bool isActive;

  Account({
    required this.id,
    required this.userId,
    required this.accountNumber,
    required this.upiId,
    required this.bankCode,
    required this.totalBalance,
    required this.heldBalance,
    required this.availableBalance,
    required this.isActive,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountNumber: json['account_number'] as String,
      upiId: (json['upi_id'] ?? '') as String,
      bankCode: (json['bank_code'] ?? 'BANK_A') as String,
      totalBalance: (json['total_balance'] as num).toDouble(),
      heldBalance: (json['held_balance'] as num).toDouble(),
      availableBalance: (json['available_balance'] as num).toDouble(),
      isActive: (json['is_active'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'account_number': accountNumber,
        'upi_id': upiId,
        'bank_code': bankCode,
        'total_balance': totalBalance,
        'held_balance': heldBalance,
        'available_balance': availableBalance,
        'is_active': isActive,
      };
}
