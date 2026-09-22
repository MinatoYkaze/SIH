class AppConfig {
  static const String localBaseUrl = 'http://127.0.0.1:8000';
  static const String deployedBaseUrl = 'https://sih-a24k.onrender.com';

  static const String defaultBaseUrl = deployedBaseUrl;

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultBaseUrl,
  );

  static const String fallbackApiBaseUrl = String.fromEnvironment(
    'FALLBACK_API_BASE_URL',
    defaultValue: deployedBaseUrl,
  );

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://kpzbenzeljjcuiaphhhs.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_rX2oVOVp0979wUtdtOn8Zg_2LbkC7oi',
  );

  static bool get isSupabaseConfigured =>
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('transition.internal') &&
      !supabaseAnonKey.contains('dummy_anon_key');

  static const Duration requestTimeout = Duration(seconds: 30);
}
