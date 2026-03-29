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
    return IslamHouseBook(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Sin tÃ­tulo',
      titleArabic: json['title_arabic'] as String? ?? '',
      description: json['description'] as String? ?? '',
      author: json['author'] as String? ?? 'Desconocido',
      category: json['category'] as String? ?? 'General',
      language: json['language'] as String? ?? 'es',
      downloadUrl: json['download_url'] as String? ?? '',
      readUrl: json['read_url'] as String? ?? '',
      coverUrl: json['cover_url'] as String? ?? '',
      format: json['format'] as String? ?? 'PDF',
      size: json['size'] as String? ?? '0 MB',
      pages: json['pages'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      downloads: json['downloads'] as int? ?? 0,
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

  /// Obtiene el libro del dÃ­a basado en la fecha
  static IslamHouseBook getBookOfDay(List<IslamHouseBook> books) {
    if (books.isEmpty) {
      return _placeholder();
    }
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    return books[seed % books.length];
  }

  /// Libro placeholder cuando no hay datos
  static IslamHouseBook _placeholder() {
    return const IslamHouseBook(
      id: 0,
      title: 'Libro del DÃ­a',
      titleArabic: 'ÙƒØªØ§Ø¨ Ø§Ù„ÙŠÙˆÙ…',
      description: 'Un libro recomendado para leer hoy',
      author: 'Varios autores',
      category: 'General',
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

  /// CategorÃ­as principales disponibles
  static const List<String> mainCategories = [
    'El Noble CorÃ¡n',
    'La Sunnah del Profeta',
    'Creencia IslÃ¡mica',
    'Jurisprudencia IslÃ¡mica',
    'Virtudes',
    'Pecados Mayores',
    'Idioma Ãrabe',
    'Llamada al Islam',
    'Historia',
    'Cultura IslÃ¡mica',
    'SermÃ³nes',
    'Lecciones AcadÃ©micas',
    'BiografÃ­a ProfÃ©tica',
    'Presentando el Islam',
  ];
}

/// CategorÃ­a de libros
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
