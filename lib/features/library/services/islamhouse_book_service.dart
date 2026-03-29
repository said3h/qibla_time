import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_model.dart';

/// Servicio para acceder a la API de IslamHouse
/// Documentación: https://api3.islamhouse.com/v3
class IslamHouseBookService {
  static const String _baseUrl = 'https://api3.islamhouse.com/v3';
  static const String _apiKey = ''; // API key opcional, IslamHouse permite acceso público

  final String _languageCode;

  IslamHouseBookService({String languageCode = 'es'})
      : _languageCode = languageCode;

  // ── Endpoints ──────────────────────────────────────────────

  /// Obtiene lista de libros en español
  Future<List<IslamHouseBook>> getBooks({
    int page = 1,
    int limit = 20,
    String? category,
    String? author,
    String? searchQuery,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/books').replace(
        queryParameters: {
          'lang': _languageCode,
          'page': page.toString(),
          'limit': limit.toString(),
          if (category != null) 'category': category,
          if (author != null) 'author': author,
          if (searchQuery != null) 'q': searchQuery,
        },
      );

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final booksData = data['data'] as List? ?? [];

        return booksData
            .map((book) => IslamHouseBook.fromJson(book as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Error al cargar libros: ${response.statusCode}');
      }
    } catch (e) {
      // Fallback: libros en cache
      return _getCachedBooks();
    }
  }

  /// Obtiene un libro específico por ID
  Future<IslamHouseBook?> getBookById(int id) async {
    try {
      final uri = Uri.parse('$_baseUrl/books/$id');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return IslamHouseBook.fromJson(data['data'] as Map<String, dynamic>);
      }
    } catch (e) {
      // Retornar null si falla
    }
    return null;
  }

  /// Obtiene categorías disponibles
  Future<List<IslamHouseCategory>> getCategories() async {
    try {
      final uri = Uri.parse('$_baseUrl/categories?lang=$_languageCode');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final categoriesData = data['data'] as List? ?? [];

        return categoriesData
            .map((cat) => IslamHouseCategory.fromJson(cat as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      // Retornar categorías por defecto
      return _getDefaultCategories();
    }
    return [];
  }

  /// Busca libros por texto
  Future<List<IslamHouseBook>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return getBooks(searchQuery: query.trim());
  }

  /// Obtiene libros destacados/recomendados
  Future<List<IslamHouseBook>> getFeaturedBooks({int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/books/featured?lang=$_languageCode&limit=$limit');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final booksData = data['data'] as List? ?? [];

        return booksData
            .map((book) => IslamHouseBook.fromJson(book as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      final cached = await _getCachedBooks();
      return cached.take(limit).toList();
    }
    return [];
  }

  /// Obtiene libros más descargados
  Future<List<IslamHouseBook>> getMostDownloaded({int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/books/popular?lang=$_languageCode&limit=$limit');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final booksData = data['data'] as List? ?? [];

        return booksData
            .map((book) => IslamHouseBook.fromJson(book as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      final cached = await _getCachedBooks();
      return cached.take(limit).toList();
    }
    return [];
  }

  /// Obtiene libros nuevos/recientes
  Future<List<IslamHouseBook>> getNewBooks({int limit = 10}) async {
    try {
      final uri = Uri.parse('$_baseUrl/books/new?lang=$_languageCode&limit=$limit');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final booksData = data['data'] as List? ?? [];

        return booksData
            .map((book) => IslamHouseBook.fromJson(book as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      final cached = await _getCachedBooks();
      return cached.take(limit).toList();
    }
    return [];
  }

  // ── Cache ──────────────────────────────────────────────

  static const String _cacheKey = 'islamhouse_books_cache';
  static const String _cacheTimestampKey = 'islamhouse_books_cache_timestamp';

  /// Guarda libros en cache
  Future<void> cacheBooks(List<IslamHouseBook> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = books.map((b) => json.encode(b.toJson())).toList();
      await prefs.setStringList(_cacheKey, booksJson);
      await prefs.setInt(_cacheTimestampKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) {
      // Ignorar errores de cache
    }
  }

  /// Obtiene libros de cache
  Future<List<IslamHouseBook>> _getCachedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList(_cacheKey) ?? [];

      return booksJson
          .map((jsonStr) => IslamHouseBook.fromJson(json.decode(jsonStr) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Verifica si el cache es válido (menos de 24 horas)
  Future<bool> isCacheValid() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getInt(_cacheTimestampKey);

      if (timestamp == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final hoursSinceCache = (now - timestamp) / (1000 * 60 * 60);

      return hoursSinceCache < 24;
    } catch (e) {
      return false;
    }
  }

  /// Limpia el cache
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }

  // ── Utilidades ──────────────────────────────────────────────

  /// Categorías por defecto (fallback)
  List<IslamHouseCategory> _getDefaultCategories() {
    return IslamHouseBook.mainCategories.map((name) => IslamHouseCategory(
      id: name.hashCode,
      name: name,
      nameArabic: '',
      bookCount: 0,
      parentId: null,
    )).toList();
  }
}

// ── Providers ──────────────────────────────────────────────

final islamHouseBookServiceProvider = Provider<IslamHouseBookService>((ref) {
  return IslamHouseBookService(languageCode: 'es');
});

final islamHouseBooksProvider = FutureProvider<List<IslamHouseBook>>((ref) async {
  final service = ref.read(islamHouseBookServiceProvider);
  final books = await service.getBooks(limit: 50);
  await service.cacheBooks(books);
  return books;
});

final islamHouseCategoriesProvider = FutureProvider<List<IslamHouseCategory>>((ref) async {
  return ref.read(islamHouseBookServiceProvider).getCategories();
});

final islamHouseFeaturedBooksProvider = FutureProvider<List<IslamHouseBook>>((ref) async {
  return ref.read(islamHouseBookServiceProvider).getFeaturedBooks(limit: 10);
});

final islamHouseSearchProvider = FutureProvider.family<List<IslamHouseBook>, String>((ref, query) async {
  return ref.read(islamHouseBookServiceProvider).searchBooks(query);
});
