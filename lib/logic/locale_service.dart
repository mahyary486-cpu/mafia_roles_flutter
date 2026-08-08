import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide translation helper - NOT the full flutter `gen-l10n` pipeline
/// (that needs the Flutter SDK to run codegen, which isn't available in
/// the environment this was built in). Instead: every bilingual string in
/// this app is written as "English / فارسی". The Persian half is fixed
/// by design and never changes. This service lets the game master swap
/// the *English* half for any other language.
///
/// Two ways to get a translation:
/// - [tr] - instant, synchronous, but only knows the small hand-written
///   phrase list below. Good for short labels that must never flicker
///   (buttons, titles).
/// - [translate] - async, calls Google Translate's free web endpoint
///   (the same one the popular `translator`-style packages use - no API
///   key or billing account needed, unlike the official Cloud
///   Translation API). Works for *any* text, including the full
///   rulebook. Needs internet on the device; silently falls back to the
///   original English if there's no connection or the request fails.
///   Results are cached (in memory + on disk) so the same phrase is
///   never re-translated twice.
///
/// See [TrText] (tr_text.dart) for the widget that uses [translate]
/// automatically.
class LocaleService {
  LocaleService._();
  static final LocaleService instance = LocaleService._();

  /// 'en' means "show the original English text" (no translation - the
  /// default state before the game master picks a language).
  final ValueNotifier<String> languageCode = ValueNotifier<String>('en');

  static const Map<String, String> supportedLanguages = {
    'fa': 'فارسی',
    'en': 'English',
    'ar': 'العربية',
    'tr': 'Türkçe',
    'es': 'Español',
    'fr': 'Français',
    'de': 'Deutsch',
    'ru': 'Русский',
    'zh-CN': '中文',
    'hi': 'हिन्दी',
    'ur': 'اردو',
    'pt': 'Português',
    'it': 'Italiano',
    'az': 'Azərbaycan',
    'id': 'Bahasa Indonesia',
    'ja': '日本語',
    'ko': '한국어',
  };

  void setLanguage(String code) => languageCode.value = code;

  static const _cacheKey = 'translation_cache_v1';
  final Map<String, String> _cache = {};
  SharedPreferences? _prefs;
  bool _cacheLoaded = false;

  Future<void> _ensureCacheLoaded() async {
    if (_cacheLoaded) return;
    _cacheLoaded = true;
    try {
      _prefs = await SharedPreferences.getInstance();
      final raw = _prefs?.getString(_cacheKey);
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _cache.addAll(decoded.map((k, v) => MapEntry(k, v as String)));
      }
    } catch (_) {
      // No persisted cache yet, or it's corrupt - just start fresh.
    }
  }

  Future<void> _persistCache() async {
    try {
      await _prefs?.setString(_cacheKey, jsonEncode(_cache));
    } catch (_) {
      // Best-effort only - a failed save just means re-fetching next time.
    }
  }

  /// Quick check used right after the game master picks a language: try
  /// translating a single word and report whether it actually reached
  /// Google Translate. Used to show "translation needs internet" instead
  /// of silently only ever showing English.
  Future<bool> canReachTranslationService() async {
    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': 'en',
        'tl': languageCode.value,
        'dt': 't',
        'q': 'test',
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Translates [english] into the currently-selected language. Returns
  /// [english] unchanged if the language is 'en', if there's no
  /// internet, or if anything else goes wrong - this should never throw
  /// or leave the UI blank.
  Future<String> translate(String english) async {
    final lang = languageCode.value;
    if (lang == 'en' || english.trim().isEmpty) return english;

    // Fast path: a hand-written translation, no network needed.
    final builtIn = _translations[english]?[lang];
    if (builtIn != null) return builtIn;

    await _ensureCacheLoaded();
    final cacheKey = '$lang::$english';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      final uri = Uri.https('translate.googleapis.com', '/translate_a/single', {
        'client': 'gtx',
        'sl': 'en',
        'tl': lang,
        'dt': 't',
        'q': english,
      });
      final response = await http.get(uri).timeout(const Duration(seconds: 6));
      if (response.statusCode != 200) return english;
      final decoded = jsonDecode(response.body) as List<dynamic>;
      final segments = decoded[0] as List<dynamic>;
      final translated = segments.map((s) => (s as List<dynamic>)[0] as String).join();
      if (translated.trim().isEmpty) return english;
      _cache[cacheKey] = translated;
      unawaited(_persistCache());
      return translated;
    } catch (_) {
      // Offline, blocked, rate-limited, or an unexpected response shape -
      // any of these just means "show the English text for now".
      return english;
    }
  }

  /// canonical English phrase -> {language code: translated phrase}.
  /// A small fast-path list for the most common labels; everything else
  /// goes through [translate] instead.
  static const Map<String, Map<String, String>> _translations = {
    'Number of Players': {
      'tr': 'Oyuncu Sayısı',
      'ar': 'عدد اللاعبين',
      'es': 'Número de Jugadores',
      'fr': 'Nombre de Joueurs',
    },
    'More Players': {
      'tr': 'Daha Fazla Oyuncu',
      'ar': 'المزيد من اللاعبين',
      'es': 'Más Jugadores',
      'fr': 'Plus de Joueurs',
    },
    'Help': {'tr': 'Yardım', 'ar': 'مساعدة', 'es': 'Ayuda', 'fr': 'Aide'},
    'Rulebook': {
      'tr': 'Kural Kitabı',
      'ar': 'كتاب القواعد',
      'es': 'Reglamento',
      'fr': 'Règlement',
    },
    'Number of Mafia': {
      'tr': 'Mafya Sayısı',
      'ar': 'عدد المافيا',
      'es': 'Número de Mafiosos',
      'fr': 'Nombre de Mafieux',
    },
    'Select Roles': {
      'tr': 'Rolleri Seç',
      'ar': 'اختر الأدوار',
      'es': 'Elegir Roles',
      'fr': 'Choisir les Rôles',
    },
    'Start Game': {
      'tr': 'Oyunu Başlat',
      'ar': 'ابدأ اللعبة',
      'es': 'Iniciar Juego',
      'fr': 'Démarrer la Partie',
    },
    'Full Roster': {
      'tr': 'Tam Kadro',
      'ar': 'القائمة الكاملة',
      'es': 'Lista Completa',
      'fr': 'Liste Complète',
    },
    'Day': {'tr': 'Gündüz', 'ar': 'النهار', 'es': 'Día', 'fr': 'Jour'},
    'Night Actions': {
      'tr': 'Gece Aksiyonları',
      'ar': 'أفعال الليل',
      'es': 'Acciones Nocturnas',
      'fr': 'Actions Nocturnes',
    },
    'End Night': {
      'tr': 'Geceyi Bitir',
      'ar': 'إنهاء الليل',
      'es': 'Terminar Noche',
      'fr': 'Terminer la Nuit',
    },
    'End Game': {
      'tr': 'Oyunu Bitir',
      'ar': 'إنهاء اللعبة',
      'es': 'Terminar Juego',
      'fr': 'Terminer la Partie',
    },
    'Confirm & Go to Day': {
      'tr': 'Onayla ve Gündüze Geç',
      'ar': 'تأكيد والانتقال إلى النهار',
      'es': 'Confirmar e Ir al Día',
      'fr': 'Confirmer et Passer au Jour',
    },
  };

  String tr(String english) {
    final lang = languageCode.value;
    if (lang == 'en') return english;
    return _translations[english]?[lang] ?? english;
  }
}
