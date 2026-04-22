import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hadiths_multilang_v2 loads and has no obvious UTF-8 corruption',
      () async {
    final file = File('assets/data/hadiths_multilang_v2.json');
    final raw = await file.readAsString();
    final decoded = jsonDecode(raw);

    expect(decoded, isA<List<dynamic>>());
    final hadiths = decoded as List<dynamic>;
    expect(hadiths.length, greaterThanOrEqualTo(1900));
    expect(raw.contains('\uFFFD'), isFalse);
    expect(_containsArabic(raw), isTrue);
  });
}

bool _containsArabic(String value) {
  for (final codeUnit in value.codeUnits) {
    if (codeUnit >= 0x0600 && codeUnit <= 0x06FF) {
      return true;
    }
  }
  return false;
}
