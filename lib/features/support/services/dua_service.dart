import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/dua_model.dart';

final duaServiceProvider = Provider<DuaService>((ref) => DuaService());

final allDuasProvider = FutureProvider<List<Dua>>((ref) async {
  return ref.watch(duaServiceProvider).loadAll();
});

class DuaService {
  List<Dua>? _cache;

  Future<List<Dua>> loadAll() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString('assets/data/duas_hisnul.json');
    final decoded = jsonDecode(raw) as List<dynamic>;
    _cache = decoded
        .map((item) => Dua.fromJson(item as Map<String, dynamic>))
        .toList();
    return _cache!;
  }

  Future<List<Dua>> getByCategory(String category) async {
    final duas = await loadAll();
    return duas.where((dua) => dua.category == category).toList();
  }

  Future<List<String>> getCategories() async {
    final duas = await loadAll();
    final categories = duas.map((dua) => dua.category).toSet().toList()
      ..sort();
    return categories;
  }
}
