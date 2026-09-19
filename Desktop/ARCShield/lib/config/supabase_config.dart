class SupabaseConfig {
  static const String supabaseUrl = 'https://vefzfpymcrjeawekcvnj.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZlZnpmcHltY3JqZWF3ZWtjdm5qIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk3MjMxNTgsImV4cCI6MjEwNTI5OTE1OH0.08bRsa2TV9-CF60Gav5T6T0Qlflm8kZyPlHYMk9zPrs';
  
  // Override with: flutter run --dart-define=ARC_API_BASE_URL=https://your-api.example.com
  static const String apiBaseUrl = String.fromEnvironment(
    'ARC_API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
}
