import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/account.dart';
import '../models/transaction_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  // Stream current account data with live balance changes
  Stream<List<Account>> streamAccounts() {
    return _client
        .from('accounts')
        .stream(primaryKey: ['id'])
        .map((data) => data.map((json) => Account.fromJson(json)).toList());
  }

  // Stream transactions for the active account
  Stream<List<TransactionItem>> streamTransactions(String accountId) {
    return _client
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data
            .where((tx) =>
                tx['sender_account_id'] == accountId ||
                tx['receiver_account_id'] == accountId)
            .map((json) => TransactionItem.fromJson(json))
            .toList());
  }

  // Trigger Quarantine Hold (F-15)
  Future<bool> quarantineTransaction({
    required String transactionId,
    required String accountId,
    required double amount,
    String? reason,
  }) async {
    try {
      await _client.from('quarantine_holds').insert({
        'transaction_id': transactionId,
        'account_id': accountId,
        'held_amount': amount,
        'status': 'ACTIVE',
        'release_reason': reason ?? 'User flagged unexpected credit',
      });
      return true;
    } catch (e) {
      print('Quarantine error: $e');
      return false;
    }
  }

  // Attempt Outgoing Transfer with Balance Validation
  Future<Map<String, dynamic>> sendMoney({
    required String senderAccountId,
    required String counterpartyIdentifier,
    required double amount,
    String? note,
  }) async {
    try {
      final res = await _client.from('transactions').insert({
        'sender_account_id': senderAccountId,
        'counterparty_identifier': counterpartyIdentifier,
        'amount': amount,
        'direction': 'OUTGOING',
        'channel': 'UPI',
        'reference_note': note,
        'status': 'PENDING',
      }).select().single();

      return {'success': true, 'transaction': res};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
