import 'package:flutter_test/flutter_test.dart';
import 'package:qibla_time/features/support/models/dua_model.dart';
import 'package:qibla_time/features/support/services/dua_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const service = DuaShareService();
  const dua = Dua(
    id: 'single',
    title: 'Test dua',
    arabicText: 'الحمد لله',
    transliteration: 'Alhamdulillah',
    translation: 'Praise be to Allah',
    category: 'gratitude',
    reference: 'Test reference',
  );

  test('image data preserves Arabic for a dua without parts', () {
    final data = service.buildImageShareData(dua);
    expect(data.arabicText, dua.arabicText);
    expect(data.translation, dua.translation);
    expect(data.reference, isEmpty);
    expect(data.badgeLabel, isEmpty);
  });

  test('text sharing preserves Arabic for a dua without parts', () {
    expect(service.buildShareText(dua), contains(dua.arabicText));
    expect(service.buildShareText(dua), contains(dua.translation));
  });

  test('image content selection still excludes unselected text', () {
    expect(service.buildImageShareData(dua, includeArabic: false).arabicText,
        isNull);
    expect(
      service.buildImageShareData(dua, includeTranslation: false).translation,
      isEmpty,
    );
  });
}
