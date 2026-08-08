import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lets the game master rename/re-describe a *built-in* role (its
/// mechanic, team, and icon stay the same - only the displayed text
/// changes). Saved locally on the device, same as custom roles.
class RoleOverridesStore {
  RoleOverridesStore._();

  static const _key = 'role_overrides_v1';

  /// In-memory cache, loaded once at app startup so lookups elsewhere in
  /// the app (RoleData.of, RoleData.forTeam) can apply overrides
  /// synchronously without every screen needing to await anything.
  static Map<String, Map<String, String>> _cache = {};

  static Future<void> loadIntoCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _cache = decoded.map(
        (key, value) => MapEntry(key, Map<String, String>.from(value as Map)),
      );
    } catch (_) {
      _cache = {};
    }
  }

  /// The override for a role type name (e.g. `RoleType.doctor.name`), if
  /// any: `{name, nameFa, description, descriptionFa, emoji}`.
  static Map<String, String>? overrideFor(String roleTypeName) =>
      _cache[roleTypeName];

  static Future<void> setOverride(
    String roleTypeName, {
    required String name,
    required String nameFa,
    required String description,
    required String descriptionFa,
    required String emoji,
  }) async {
    _cache[roleTypeName] = {
      'name': name,
      'nameFa': nameFa,
      'description': description,
      'descriptionFa': descriptionFa,
      'emoji': emoji,
    };
    await _persist();
  }

  static Future<void> clearOverride(String roleTypeName) async {
    _cache.remove(roleTypeName);
    await _persist();
  }

  static Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_cache));
  }
}
