import 'dart:convert';

import 'package:flutter/services.dart';

import '../../domain/entities/offline_prayer_city.dart';

class OfflinePrayerCitiesDataSource {
  static const _basePath = 'assets/data/prayer_cities';

  final Map<String, List<OfflinePrayerCity>> _citiesByCountry = {};
  List<OfflinePrayerCountry>? _countries;

  Future<List<OfflinePrayerCountry>> loadCountries() async {
    final cached = _countries;
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString('$_basePath/countries.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    final countries = decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => OfflinePrayerCountry(
            code: (item['code'] as String? ?? '').toUpperCase(),
            cityCount: (item['cities'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((country) => country.code.isNotEmpty)
        .toList()
      ..sort((a, b) => a.code.compareTo(b.code));
    _countries = countries;
    return countries;
  }

  Future<List<OfflinePrayerCity>> loadCities(String countryCode) async {
    final normalizedCode = countryCode.trim().toLowerCase();
    final cached = _citiesByCountry[normalizedCode];
    if (cached != null) {
      return cached;
    }

    final raw = await rootBundle.loadString(
      '$_basePath/cities_$normalizedCode.json',
    );
    final decoded = jsonDecode(raw) as List<dynamic>;
    final cities = decoded
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => OfflinePrayerCity(
            countryCode: normalizedCode.toUpperCase(),
            name: item['n'] as String? ?? '',
            normalizedName: item['nn'] as String? ?? '',
            latitude: (item['lat'] as num?)?.toDouble() ?? 0,
            longitude: (item['lng'] as num?)?.toDouble() ?? 0,
          ),
        )
        .where((city) => city.name.isNotEmpty)
        .toList();
    _citiesByCountry[normalizedCode] = cities;
    return cities;
  }

  Future<List<OfflinePrayerCity>> searchCities({
    required String countryCode,
    required String query,
    int limit = 60,
  }) async {
    final cities = await loadCities(countryCode);
    final normalizedQuery = normalizeSearch(query);
    if (normalizedQuery.isEmpty) {
      return cities.take(limit).toList();
    }

    return cities
        .where(
          (city) =>
              normalizeSearch(city.name).contains(normalizedQuery) ||
              normalizeSearch(city.normalizedName).contains(normalizedQuery),
        )
        .take(limit)
        .toList();
  }

  List<OfflinePrayerCountry> searchCountries(
    List<OfflinePrayerCountry> countries,
    String query,
  ) {
    final normalizedQuery = normalizeSearch(query);
    if (normalizedQuery.isEmpty) {
      return countries;
    }
    return countries
        .where(
            (country) => country.code.toLowerCase().contains(normalizedQuery))
        .toList();
  }

  static String normalizeSearch(String value) {
    const replacements = {
      'á': 'a',
      'à': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ā': 'a',
      'ç': 'c',
      'ć': 'c',
      'č': 'c',
      'ď': 'd',
      'é': 'e',
      'è': 'e',
      'ê': 'e',
      'ë': 'e',
      'ē': 'e',
      'í': 'i',
      'ì': 'i',
      'î': 'i',
      'ï': 'i',
      'ī': 'i',
      'ñ': 'n',
      'ń': 'n',
      'ó': 'o',
      'ò': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ō': 'o',
      'ú': 'u',
      'ù': 'u',
      'û': 'u',
      'ü': 'u',
      'ū': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'ž': 'z',
      'ź': 'z',
      'ż': 'z',
    };
    final buffer = StringBuffer();
    for (final rune in value.toLowerCase().runes) {
      final char = String.fromCharCode(rune);
      buffer.write(replacements[char] ?? char);
    }
    return buffer.toString().trim();
  }
}
