class TafsirConfig {
  const TafsirConfig({
    required this.enabled,
    required this.baseUrl,
    this.authToken,
    this.clientId,
    this.defaultResourceId,
  });

  static const fromEnvironment = TafsirConfig(
    enabled: bool.fromEnvironment('TAFSIR_API_ENABLED'),
    baseUrl: String.fromEnvironment(
      'TAFSIR_API_BASE_URL',
      defaultValue: 'https://api.quran.com/api/v4',
    ),
    authToken: String.fromEnvironment('TAFSIR_API_AUTH_TOKEN'),
    clientId: String.fromEnvironment('TAFSIR_API_CLIENT_ID'),
    defaultResourceId: String.fromEnvironment('TAFSIR_DEFAULT_RESOURCE_ID'),
  );

  final bool enabled;
  final String baseUrl;
  final String? authToken;
  final String? clientId;
  final String? defaultResourceId;

  Uri? get baseUri {
    final value = baseUrl.trim();
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

  String? get normalizedAuthToken => _nonEmpty(authToken);

  String? get normalizedClientId => _nonEmpty(clientId);

  String? get normalizedDefaultResourceId {
    final value = _nonEmpty(defaultResourceId);
    if (value == null) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return null;
    return parsed.toString();
  }

  bool get canCreateApiClient {
    return enabled &&
        baseUri != null &&
        normalizedAuthToken != null &&
        normalizedClientId != null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
