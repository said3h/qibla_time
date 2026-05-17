class TafsirConfig {
  const TafsirConfig({
    required this.enabled,
    required this.baseUrl,
    this.internalBuild = false,
    this.provider = 'quran_foundation',
    this.authToken,
    this.clientId,
    this.defaultResourceId,
  });

  static const fromEnvironment = TafsirConfig(
    enabled: bool.fromEnvironment('TAFSIR_API_ENABLED'),
    internalBuild: bool.fromEnvironment('QIBLA_INTERNAL_TAFSIR_BUILD'),
    baseUrl: String.fromEnvironment(
      'TAFSIR_API_BASE_URL',
      defaultValue: 'https://api.quran.com/api/v4',
    ),
    provider: String.fromEnvironment('TAFSIR_API_PROVIDER'),
    authToken: String.fromEnvironment('TAFSIR_API_AUTH_TOKEN'),
    clientId: String.fromEnvironment('TAFSIR_API_CLIENT_ID'),
    defaultResourceId: String.fromEnvironment('TAFSIR_DEFAULT_RESOURCE_ID'),
  );

  final bool enabled;
  final String baseUrl;
  final bool internalBuild;
  final String provider;
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
    final value = _nonEmpty(defaultResourceId) ?? (isQulPreview ? '268' : null);
    if (value == null) return null;
    final parsed = int.tryParse(value);
    if (parsed == null || parsed <= 0) return null;
    return parsed.toString();
  }

  String get normalizedProvider {
    final value = provider.trim().toLowerCase();
    if (value.isEmpty) return 'quran_foundation';
    return value;
  }

  bool get isQulPreview => normalizedProvider == 'qul_preview';

  bool get canCreateApiClient {
    if (!enabled || baseUri == null) return false;
    if (isQulPreview) return true;
    return normalizedAuthToken != null && normalizedClientId != null;
  }

  static String? _nonEmpty(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}

class QulTafsirResource {
  const QulTafsirResource({
    required this.languageCode,
    required this.resourceId,
    required this.name,
    required this.notes,
  });

  final String languageCode;
  final String resourceId;
  final String name;
  final String notes;
}

const qulTafsirResourcesByLanguage = <String, QulTafsirResource>{
  'es': QulTafsirResource(
    languageCode: 'es',
    resourceId: '268',
    name: 'Spanish Abridged Explanation of the Quran',
    notes: 'QUL preview, Al-Mukhtasar/Abridged Explanation.',
  ),
  'en': QulTafsirResource(
    languageCode: 'en',
    resourceId: '266',
    name: 'English Al-Mukhtasar',
    notes: 'QUL preview, Al-Mukhtasar.',
  ),
  'ar': QulTafsirResource(
    languageCode: 'ar',
    resourceId: '251',
    name: 'Arabic Al-Mukhtasar in interpreting the Noble Quran',
    notes: 'QUL preview, Arabic Al-Mukhtasar.',
  ),
  'tr': QulTafsirResource(
    languageCode: 'tr',
    resourceId: '258',
    name: 'Turkish Al-Mukhtasar in Interpreting the Noble Quran',
    notes: 'QUL preview, Turkish Al-Mukhtasar.',
  ),
  'fr': QulTafsirResource(
    languageCode: 'fr',
    resourceId: '259',
    name: 'French Abridged Explanation of the Quran',
    notes: 'QUL preview, Al-Mukhtasar/Abridged Explanation.',
  ),
  'ru': QulTafsirResource(
    languageCode: 'ru',
    resourceId: '262',
    name: 'Russian Al-Mukhtasar',
    notes: 'QUL preview, Russian Al-Mukhtasar.',
  ),
  'it': QulTafsirResource(
    languageCode: 'it',
    resourceId: '253',
    name: 'Italian Al-Mukhtasar in interpreting the Noble Quran',
    notes: 'QUL preview, Italian Al-Mukhtasar.',
  ),
};

QulTafsirResource? qulTafsirResourceForLanguage(String languageCode) {
  final normalized = languageCode.trim().toLowerCase().replaceAll('-', '_');
  final shortCode = normalized.split('_').first;
  return qulTafsirResourcesByLanguage[shortCode];
}
