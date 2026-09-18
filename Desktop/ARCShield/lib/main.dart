import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase Client
  try {
    await Supabase.initialize(
      url: SupabaseConfig.supabaseUrl,
      publishableKey: SupabaseConfig.supabaseAnonKey,
    );
    debugPrint('Supabase successfully initialized.');
  } catch (e) {
    debugPrint('Supabase init notice: $e');
  }

  // 2. Initialize Notification Service (FCM with simulated fallback)
  final notificationService = NotificationService();
  await notificationService.initialize();

  runApp(const ArcShieldApp());
}

class ArcShieldApp extends StatelessWidget {
  const ArcShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ARCShield',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0B57D0), // Google Blue
          onPrimary: Colors.white,
          secondary: Color(0xFF1E8E3E), // Google Green
          surface: Colors.white,
          onSurface: Color(0xFF1F1F1F),
          error: Color(0xFFD93025), // Google Red
          outlineVariant: Color(0xFFE8EAED),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: Color(0xFF1F1F1F)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1F1F1F),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.light().textTheme.apply(
            bodyColor: const Color(0xFF1F1F1F),
            displayColor: const Color(0xFF1F1F1F),
          ),
        ),
        dividerTheme: const DividerThemeData(
          color: Color(0xFFE8EAED),
          thickness: 1,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
