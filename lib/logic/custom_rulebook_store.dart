import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/custom_rulebook.dart';

/// Saves game-master-written rulebooks locally on the device, forever -
/// same "no account, no cloud" approach as [CustomRolesStore]. Each one
/// is a title, a long free-form rules description, and an optional
/// simple win-condition rule.
class CustomRulebookStore {
  CustomRulebookStore._();

  static const _key = 'custom_rulebooks_v1';

  static Future<List<CustomRulebook>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => CustomRulebook.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> _saveAll(List<CustomRulebook> books) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(books.map((b) => b.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  /// Adds a new rulebook, or replaces an existing one with the same id.
  static Future<void> save(CustomRulebook book) async {
    final all = await loadAll();
    all.removeWhere((b) => b.id == book.id);
    all.add(book);
    await _saveAll(all);
  }

  static Future<void> remove(String id) async {
    final all = await loadAll();
    all.removeWhere((b) => b.id == id);
    await _saveAll(all);
  }
}
