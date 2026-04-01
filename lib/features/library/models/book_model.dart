/// Modelo para libros de IslamHouse
class IslamHouseBook {
  const IslamHouseBook({
    required this.id,
    required this.title,
    required this.titleArabic,
    required this.description,
    required this.author,
    required this.category,
    required this.language,
    required this.downloadUrl,
    required this.readUrl,
    required this.coverUrl,
    required this.format,
    required this.size,
    required this.pages,
    required this.rating,
    required this.downloads,
  });

  final int id;
  final String title;
  final String titleArabic;
  final String description;
  final String author;
  final String category;
  final String language;
  final String downloadUrl;
  final String readUrl;
  final String coverUrl;
  final String format;
  final String size;
  final int pages;
  final double rating;
  final int downloads;

  factory IslamHouseBook.fromJson(Map<String, dynamic> json) {
    final attachments = (json['attachments'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final firstAttachment = attachments.isNotEmpty ? attachments.first : null;
    final preparedBy = (json['prepared_by'] as List? ?? const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final firstPreparer = preparedBy.isNotEmpty ? preparedBy.first : null;
    final title = _firstNonEmpty([
      json['title'],
      json['description'],
      'Sin título',
    ]);
    final titleArabic = _firstNonEmpty([
      json['title_arabic'],
      (json['source_language'] == 'ar' || json['translation_language'] == 'ar')
          ? title
          : null,
    ]);
    final description = _firstNonEmpty([
      json['full_description'],
      json['description'],
    ]);
    final author = _firstNonEmpty([
      json['author'],
      firstPreparer?['title'],
      firstPreparer?['description'],
      'IslamHouse',
    ]);
    final downloadUrl = _firstNonEmpty([
      json['download_url'],
      firstAttachment?['url'],
    ]);
    final readUrl = _firstNonEmpty([
      json['read_url'],
      downloadUrl,
      json['api_url'],
    ]);

    return IslamHouseBook(
      id: json['id'] as int? ?? 0,
      title: title,
      titleArabic: titleArabic,
      description: description,
      author: author,
      category: _firstNonEmpty([
        json['category'],
        json['type'] == 'books' ? 'Libros' : null,
        'General',
      ]),
      language: _firstNonEmpty([
        json['language'],
        json['translated_language'],
        json['translation_language'],
        json['source_language'],
        'es',
      ]),
      downloadUrl: downloadUrl,
      readUrl: readUrl,
      coverUrl: _firstNonEmpty([
        json['cover_url'],
        json['image'],
      ]),
      format: _firstNonEmpty([
        json['format'],
        firstAttachment?['extension_type'],
        'PDF',
      ]),
      size: _firstNonEmpty([
        json['size'],
        firstAttachment?['size'],
        '0 MB',
      ]),
      pages: json['pages'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      downloads: json['downloads'] as int? ?? json['hits'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'title_arabic': titleArabic,
      'description': description,
      'author': author,
      'category': category,
      'language': language,
      'download_url': downloadUrl,
      'read_url': readUrl,
      'cover_url': coverUrl,
      'format': format,
      'size': size,
      'pages': pages,
      'rating': rating,
      'downloads': downloads,
    };
  }

  /// Obtiene el libro del día basado en la fecha.
  static IslamHouseBook getBookOfDay(List<IslamHouseBook> books) {
    if (books.isEmpty) {
      return _placeholder();
    }
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return books[seed % books.length];
  }

  /// Libro placeholder cuando no hay datos.
  static IslamHouseBook _placeholder() {
    return const IslamHouseBook(
      id: 0,
      title: 'Libro del día',
      titleArabic: '',
      description: 'Un libro recomendado para leer hoy',
      author: 'IslamHouse',
      category: 'Libros',
      language: 'es',
      downloadUrl: '',
      readUrl: 'https://islamhouse.com/es/',
      coverUrl: '',
      format: 'PDF',
      size: '0 MB',
      pages: 0,
      rating: 0.0,
      downloads: 0,
    );
  }

  /// Categorias principales disponibles.
  static const List<String> mainCategories = [
    'El Noble Corán',
    'La Sunnah del Profeta',
    'Creencia islámica',
    'Jurisprudencia islámica',
    'Virtudes',
    'Pecados Mayores',
    'Idioma árabe',
    'Llamada al Islam',
    'Historia',
    'Cultura islámica',
    'Sermones',
    'Lecciones académicas',
    'Biografía profética',
    'Presentando el Islam',
  ];

  static String _firstNonEmpty(List<Object?> values) {
    for (final value in values) {
      final normalized = value?.toString().trim() ?? '';
      if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
        return normalized;
      }
    }
    return '';
  }
}

/// Categoria de libros
class IslamHouseCategory {
  const IslamHouseCategory({
    required this.id,
    required this.name,
    required this.nameArabic,
    required this.bookCount,
    required this.parentId,
  });

  final int id;
  final String name;
  final String nameArabic;
  final int bookCount;
  final int? parentId;

  factory IslamHouseCategory.fromJson(Map<String, dynamic> json) {
    return IslamHouseCategory(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Sin nombre',
      nameArabic: json['name_arabic'] as String? ?? '',
      bookCount: json['book_count'] as int? ?? 0,
      parentId: json['parent_id'] as int?,
    );
  }
}

/// Estado de carga de libros
enum BooksLoadStatus {
  loading,
  success,
  error,
  empty,
}

/// Resultado de carga de libros
class BooksLoadResult {
  const BooksLoadResult({
    required this.status,
    this.books = const [],
    this.error,
  });

  final BooksLoadStatus status;
  final List<IslamHouseBook> books;
  final String? error;

  bool get isLoading => status == BooksLoadStatus.loading;
  bool get isSuccess => status == BooksLoadStatus.success;
  bool get isError => status == BooksLoadStatus.error;
  bool get isEmpty => status == BooksLoadStatus.empty;
}
