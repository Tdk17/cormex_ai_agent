class AppConfig {
  const AppConfig._();

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );
  static const String parseServerUrl = String.fromEnvironment(
    'PARSE_SERVER_URL',
    defaultValue: 'https://parseapi.back4app.com',
  );
  static const String parseApplicationId = String.fromEnvironment(
    'PARSE_APPLICATION_ID',
  );
  static const String parseRestApiKey = String.fromEnvironment(
    'PARSE_REST_API_KEY',
  );

  static bool get isProduction => environment == 'production';

  static void validate() {
    if (useMockData) return;
    if (parseServerUrl.isEmpty || parseApplicationId.isEmpty) {
      throw StateError(
        'PARSE_SERVER_URL e PARSE_APPLICATION_ID são obrigatórios fora do modo mock.',
      );
    }
  }
}
