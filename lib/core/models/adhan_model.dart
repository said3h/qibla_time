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
          name: 'Adhan 1',
          file: 'azan1.mp3',
          description: 'Llamada a la oración 1',
        ),
        AdhanModel(
          name: 'Adhan 2',
          file: 'azan2.mp3',
          description: 'Llamada a la oración 2',
        ),
        AdhanModel(
          name: 'Adhan 3',
          file: 'azan3.mp3',
          description: 'Llamada a la oración 3',
        ),
        AdhanModel(
          name: 'Adhan 4',
          file: 'azan4.mp3',
          description: 'Llamada a la oración 4',
        ),
        AdhanModel(
          name: 'Adhan 5',
          file: 'azan5.mp3',
          description: 'Llamada a la oración 5',
        ),
        AdhanModel(
          name: 'Adhan 6',
          file: 'azan6.mp3',
          description: 'Llamada a la oración 6',
        ),
      ];

  @override
  String toString() => 'AdhanModel(name: $name, file: $file)';
}
