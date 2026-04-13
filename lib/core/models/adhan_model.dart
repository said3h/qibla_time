/// Modelo para representar un Adhan (llamada a la oracion)
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
          name: 'Adhan 1',
          file: 'azan1.mp3',
          description: 'Llamada a la oracion 1',
        ),
        AdhanModel(
          name: 'Adhan 2',
          file: 'azan2.mp3',
          description: 'Llamada a la oracion 2',
        ),
        AdhanModel(
          name: 'Adhan 3',
          file: 'azan3.mp3',
          description: 'Llamada a la oracion 3',
        ),
        AdhanModel(
          name: 'Adhan 4',
          file: 'azan4.mp3',
          description: 'Llamada a la oracion 4',
        ),
        AdhanModel(
          name: 'Adhan 5',
          file: 'azan5.mp3',
          description: 'Llamada a la oracion 5',
        ),
        AdhanModel(
          name: 'Adhan 6',
          file: 'azan6.mp3',
          description: 'Llamada a la oracion 6',
        ),
        AdhanModel(
          name: 'Adhan Madinah',
          file: 'azan_madinah.mp3',
          description: 'Short Madinah adhan',
        ),
        AdhanModel(
          name: 'Adhan Makkah',
          file: 'azan_makkah.mp3',
          description: 'Short Makkah adhan',
        ),
      ];

  @override
  String toString() => 'AdhanModel(name: $name, file: $file)';
}
