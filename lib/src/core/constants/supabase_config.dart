// إعدادات الاتصال بـ Supabase مع دعم متغيرات البيئة والأمان
class SupabaseConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://sgbfmqplryyhypdvrlmn.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNnYmZtcXBscnl5aHlwZHZybG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODIzMzMzMTYsImV4cCI6MjA5NzkwOTMxNn0.HtW6qIoBsxjFYWLG0C4QXublMzB06glrpLccQZcPP8Q',
  );
}
