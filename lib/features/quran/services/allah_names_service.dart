import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/allah_name.dart';

class AllahNamesService {
  Future<List<AllahName>> loadAll() async {
    final raw = await rootBundle.loadString('assets/data/asmaul_husna.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => AllahName.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}

final allahNamesServiceProvider = Provider<AllahNamesService>((ref) {
  return AllahNamesService();
});

final allahNamesProvider = FutureProvider<List<AllahName>>((ref) async {
  return ref.watch(allahNamesServiceProvider).loadAll();
});
