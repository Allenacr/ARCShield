import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/supabase_config.dart';

class MobileApiService {
  String get _baseUrl => SupabaseConfig.apiBaseUrl.replaceFirst(RegExp(r'/$'), '');

  Future<void> registerDevice({required String accountId, required String fcmToken}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mobile/devices'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'account_id': accountId, 'fcm_token': fcmToken}),
    );
    if (response.statusCode >= 300) {
      throw Exception('Device registration failed (${response.statusCode})');
    }
  }

  Future<Map<String, dynamic>> recordDecision({
    required String transactionId,
    required String accountId,
    required String decision,
    required double amount,
    String? reason,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/mobile/decisions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'transaction_id': transactionId,
        'account_id': accountId,
        'decision': decision,
        'amount': amount,
        'reason': reason,
      }),
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 300 || data['success'] != true) {
      throw Exception(data['detail'] ?? 'Mobile decision failed');
    }
    return data;
  }
}