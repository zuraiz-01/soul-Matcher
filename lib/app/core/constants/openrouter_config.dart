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
    defaultValue:
        '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',
  );

  static bool get isConfigured => apiKey.trim().isNotEmpty;
}
