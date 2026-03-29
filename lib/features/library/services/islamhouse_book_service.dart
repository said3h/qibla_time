import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/book_model.dart';

/// Servicio para acceder a la API de IslamHouse.
class IslamHouseBookService {
  static const String _connectionKey = 'paV29H2gm56kvLPy';
  static const String _baseUrl =
      'https://api3.islamhouse.com/v3/$_connectionKey/main';

  IslamHouseBookService({String languageCode = 'es'})
      : _languageCode = languageCode;

  final String _languageCode;

  /// Obtiene lista de libros en espanol.
  Future<List<IslamHouseBook>> getBooks({
    int page = 1,
    int limit = 20,
    String? category,
    String? author,
    String? searchQuery,
  }) async {
    try {
      final response = await http.get(
        _buildBooksUri(page: page, limit: limit),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        throw Exception('Error al cargar libros: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final booksData = data['data'] as List? ?? const [];
      final books = booksData
          .whereType<Map>()
          .map((book) => IslamHouseBook.fromJson(Map<String, dynamic>.from(book)))
          .toList();

      return _applyLocalFilters(
        books,
        category: category,
        author: author,
        searchQuery: searchQuery,
      );
    } catch (e) {
      final cachedBooks = await _getCachedBooks();
      return _applyLocalFilters(
        cachedBooks,
        category: category,
        author: author,
        searchQuery: searchQuery,
      );
    }
  }

  /// Obtiene un libro especifico por ID.
  Future<IslamHouseBook?> getBookById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/get-item/$id/$_languageCode/json'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        return null;
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      return IslamHouseBook.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  /// Obtiene categorias disponibles a partir de los libros cargados.
  Future<List<IslamHouseCategory>> getCategories() async {
    try {
      final books = await getBooks(limit: 100);
      final categoryNames = books
          .map((book) => book.category.trim())
          .where((name) => name.isNotEmpty && name.toLowerCase() != 'general')
          .toSet()
          .toList()
        ..sort();

      return categoryNames
          .map(
            (name) => IslamHouseCategory(
              id: name.hashCode,
              name: name,
              nameArabic: '',
              bookCount: books.where((book) => book.category == name).length,
              parentId: null,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Busca libros por texto.
  Future<List<IslamHouseBook>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }
    return getBooks(searchQuery: query.trim());
  }

  /// Obtiene libros destacados/recomendados.
  Future<List<IslamHouseBook>> getFeaturedBooks({int limit = 10}) async {
    final books = await getBooks(limit: limit);
    return books.take(limit).toList();
  }

  /// Obtiene libros mas descargados.
  Future<List<IslamHouseBook>> getMostDownloaded({int limit = 10}) async {
    final books = await getBooks(limit: limit);
    return books.take(limit).toList();
  }

  /// Obtiene libros recientes.
  Future<List<IslamHouseBook>> getNewBooks({int limit = 10}) async {
    final books = await getBooks(limit: limit);
    return books.take(limit).toList();
  }

  Uri _buildBooksUri({
    required int page,
    required int limit,
  }) {
    return Uri.parse(
      '$_baseUrl/books/$_languageCode/$_languageCode/$page/$limit/json',
    );
  }

  List<IslamHouseBook> _applyLocalFilters(
    List<IslamHouseBook> books, {
    String? category,
    String? author,
    String? searchQuery,
  }) {
    var filtered = books;

    if (category != null && category.trim().isNotEmpty) {
      final normalizedCategory = category.trim().toLowerCase();
      filtered = filtered
          .where((book) => book.category.toLowerCase() == normalizedCategory)
          .toList();
    }

    if (author != null && author.trim().isNotEmpty) {
      final normalizedAuthor = author.trim().toLowerCase();
      filtered = filtered
          .where((book) => book.author.toLowerCase().contains(normalizedAuthor))
          .toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = searchQuery.trim().toLowerCase();
      filtered = filtered
          .where(
            (book) =>
                book.title.toLowerCase().contains(query) ||
                book.author.toLowerCase().contains(query) ||
                book.description.toLowerCase().contains(query),
          )
          .toList();
    }

    return filtered;
  }

  static const String _cacheKey = 'islamhouse_books_cache';
  static const String _cacheTimestampKey = 'islamhouse_books_cache_timestamp';

  /// Guarda libros en cache.
  Future<void> cacheBooks(List<IslamHouseBook> books) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = books.map((book) => json.encode(book.toJson())).toList();
      await prefs.setStringList(_cacheKey, booksJson);
      await prefs.setInt(
        _cacheTimestampKey,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      // Ignorar errores de cache.
    }
  }

  /// Obtiene libros de cache.
  Future<List<IslamHouseBook>> _getCachedBooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final booksJson = prefs.getStringList(_cacheKey) ?? const [];

      return booksJson
          .map(
            (jsonStr) => IslamHouseBook.fromJson(
              json.decode(jsonStr) as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Verifica si el cache es valido.
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

  /// Limpia el cache.
  Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cacheKey);
    await prefs.remove(_cacheTimestampKey);
  }
}

final islamHouseBookServiceProvider = Provider<IslamHouseBookService>((ref) {
  return IslamHouseBookService(languageCode: 'es');
});

final islamHouseBooksProvider = FutureProvider<List<IslamHouseBook>>((ref) async {
  final service = ref.read(islamHouseBookServiceProvider);
  final books = await service.getBooks(limit: 50);
  if (books.isNotEmpty) {
    await service.cacheBooks(books);
  }
  return books;
});

final islamHouseCategoriesProvider =
    FutureProvider<List<IslamHouseCategory>>((ref) async {
  return ref.read(islamHouseBookServiceProvider).getCategories();
});

final islamHouseFeaturedBooksProvider =
    FutureProvider<List<IslamHouseBook>>((ref) async {
  return ref.read(islamHouseBookServiceProvider).getFeaturedBooks(limit: 10);
});

final islamHouseSearchProvider =
    FutureProvider.family<List<IslamHouseBook>, String>((ref, query) async {
  return ref.read(islamHouseBookServiceProvider).searchBooks(query);
});
