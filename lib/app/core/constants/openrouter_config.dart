class OpenRouterConfig {
  OpenRouterConfig._();

  static const String baseUrl = 'https://openrouter.ai/api/v1';
  static const String model = String.fromEnvironment(
    'OPENROUTER_MODEL',
    defaultValue: 'openai/gpt-4o-mini',
  );

  // NOTE: Move this to --dart-define for production apps.
  static const String apiKey = String.fromEnvironment(
    'OPENROUTER_API_KEY',
    defaultValue: '',
  );

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
