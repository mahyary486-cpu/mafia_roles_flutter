import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/role.dart';

/// Saves custom (game-master-written) roles locally on the device, so
/// they show up as reusable, checkable options in every future game -
/// same as the built-in roles. Nothing here ever leaves the device: no
/// account, no cloud, no server.
class CustomRolesStore {
  CustomRolesStore._();

  static const _key = 'custom_roles_v1';

  static Future<List<Role>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Role.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupted or outdated data - fail safe with an empty list rather
      // than crashing the app.
      return [];
    }
  }

  static Future<void> _saveAll(List<Role> roles) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(roles.map((r) => r.toJson()).toList());
    await prefs.setString(_key, raw);
  }

  /// Adds a new custom role to the saved list and persists it.
  static Future<void> add(Role role) async {
    final all = await loadAll();
    all.add(role);
    await _saveAll(all);
  }

  /// Permanently removes a custom role (by its id) from the saved list.
  static Future<void> remove(String roleId) async {
    final all = await loadAll();
    all.removeWhere((r) => r.id == roleId);
    await _saveAll(all);
  }
}
