/// Modelo para representar un Adhan (llamada a la oración)
class AdhanModel {
  final String name;
  final String file;
  final String? description;

  AdhanModel({
    required this.name,
    required this.file,
    this.description,
  });

  /// Lista de adhans disponibles
  static List<AdhanModel> get availableAdhans => [
        AdhanModel(
          name: 'Makkah',
          file: 'adhan_makkah.mp3',
          description: 'Estilo tradicional de La Meca',
        ),
        AdhanModel(
          name: 'Madinah',
          file: 'adhan_madinah.mp3',
          description: 'Estilo de Medina',
        ),
        AdhanModel(
          name: 'Cairo',
          file: 'adhan_cairo.mp3',
          description: 'Estilo egipcio clásico',
        ),
        AdhanModel(
          name: 'Istanbul',
          file: 'adhan_istanbul.mp3',
          description: 'Estilo turco otomano',
        ),
        AdhanModel(
          name: 'Abdulmalik',
          file: 'adhan_abdulmalik.mp3',
          description: 'Abdulmalik Al-Nu\'man',
        ),
      ];

  @override
  String toString() => 'AdhanModel(name: $name, file: $file)';
}
