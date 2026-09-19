import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'mobile_api_service.dart';

typedef AlertCallback = void Function(Map<String, dynamic> data);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  bool _isFirebaseInitialized = false;
  bool get isFirebaseInitialized => _isFirebaseInitialized;
  AlertCallback? onAlertReceived;
  final StreamController<Map<String, dynamic>> _alertStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get alertStream => _alertStreamController.stream;

  RealtimeChannel? _realtimeChannel;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectDelay = 30; // seconds

  Future<void> initialize() async {
    // 1. Initialize Supabase Realtime WebSocket listener for backend alerts
    _listenToSupabaseRealtime();

    // 2. Attempt Firebase initialization if google-services.json is available
    try {
      await Firebase.initializeApp();
      _isFirebaseInitialized = true;

      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await messaging.getToken();
        debugPrint('ARCShield FCM Device Token: $token');
        if (token != null) {
          try {
            await MobileApiService().registerDevice(
              accountId: 'demo-account-01',
              fcmToken: token,
            );
            debugPrint('ARCShield FCM token registered with backend.');
          } catch (e) {
            debugPrint('FCM token registration notice: $e');
          }
        }
      }

      // Foreground FCM listener
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Foreground FCM push received: ${message.data}');
        _dispatchAlert(message.data);
      });

      // Notification click listener
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM opened app: ${message.data}');
        _dispatchAlert(message.data);
      });
    } catch (e) {
      debugPrint(
        'FCM notice: $e. Operating via Supabase Realtime WebSockets for instant backend alerts.',
      );
      _isFirebaseInitialized = false;
    }
  }

  void _listenToSupabaseRealtime() {
    _cancelReconnectTimer();
    _unsubscribeChannel();

    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client.channel('fraud_alerts');

      _realtimeChannel!
          .onBroadcast(
            event: 'incoming_alert',
            callback: (Map<String, dynamic> payload) {
              debugPrint('[BACKEND REALTIME PUSH RECEIVED ON PHONE] $payload');
              // Supabase wraps broadcast in: {type, event, payload: {actual data}}
              // Unwrap so home_screen gets flat fields: direction, risk_band, amount etc.
              final Map<String, dynamic> alertData =
                  (payload['payload'] is Map<String, dynamic>)
                      ? payload['payload'] as Map<String, dynamic>
                      : payload;
              debugPrint('[ALERT DATA DISPATCHED] $alertData');
              // Physical vibration & sound alert on phone
              HapticFeedback.heavyImpact();
              SystemSound.play(SystemSoundType.alert);
              _reconnectAttempts = 0;
              _dispatchAlert(alertData);
            },
          )
          .subscribe((status, [error]) {
            debugPrint(
              '[Supabase Realtime: fraud_alerts] Status: $status, Error: $error',
            );
            if (status == RealtimeSubscribeStatus.subscribed) {
              debugPrint('[Supabase Realtime] Channel ACTIVE — ready for backend alerts.');
              _reconnectAttempts = 0;
              _cancelReconnectTimer();
            } else if (status == RealtimeSubscribeStatus.channelError ||
                status == RealtimeSubscribeStatus.timedOut) {
              debugPrint('[Supabase Realtime] Connection lost. Scheduling reconnect...');
              _scheduleReconnect();
            }
          });
    } catch (e) {
      debugPrint('Supabase Realtime listener notice: $e');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _cancelReconnectTimer();
    _reconnectAttempts++;
    // Exponential backoff: 2s, 4s, 8s, 16s, 30s max
    final delaySeconds = (_reconnectAttempts <= 5)
        ? (2 * _reconnectAttempts).clamp(2, _maxReconnectDelay)
        : _maxReconnectDelay;

    debugPrint(
      '[Supabase Realtime] Reconnect attempt #$_reconnectAttempts in ${delaySeconds}s...',
    );

    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      debugPrint('[Supabase Realtime] Reconnecting now...');
      _listenToSupabaseRealtime();
    });
  }

  void _cancelReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _unsubscribeChannel() {
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    } catch (_) {}
  }

  void _dispatchAlert(Map<String, dynamic> data) {
    _alertStreamController.add(data);
    if (onAlertReceived != null) {
      onAlertReceived!(data);
    }
  }

  // Fallback / simulated alert trigger
  void simulateIncomingAlert({
    required String transactionId,
    required String counterparty,
    required double amount,
    required List<String> reasonCodes,
  }) {
    final simulatedData = {
      'transaction_id': transactionId,
      'counterparty': counterparty,
      'amount': amount.toString(),
      'direction': 'INCOMING',
      'risk_band': 'HIGH',
      'reason_codes': reasonCodes.join(','),
    };
    HapticFeedback.heavyImpact();
    _dispatchAlert(simulatedData);
  }

  void dispose() {
    _cancelReconnectTimer();
    _unsubscribeChannel();
    _alertStreamController.close();
  }
}
