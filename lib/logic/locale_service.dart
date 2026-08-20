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

  /// Sets the starting language from the device's own locale/region, if
  /// it's one this app supports - so a phone set to Persian, Arabic,
  /// German, etc. opens already in that language instead of English.
  /// Safe to call even if it doesn't match anything (stays 'en').
  void applyDeviceDefaultLanguage(String deviceLocale) {
    // deviceLocale looks like "fa_IR", "zh_CN", "en_US", etc.
    final normalized = deviceLocale.replaceAll('_', '-');
    final primary = normalized.split('-').first.toLowerCase();
    if (supportedLanguages.containsKey(normalized)) {
      languageCode.value = normalized;
      return;
    }
    // Chinese is stored as 'zh-CN' specifically.
    if (primary == 'zh') {
      languageCode.value = 'zh-CN';
      return;
    }
    if (supportedLanguages.containsKey(primary)) {
      languageCode.value = primary;
    }
  }

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
  // === Role names (auto-generated, best-effort machine + knowledge-based) ===
    'Citizen': {'fa': 'شهروند', 'ar': 'مواطن', 'tr': 'Vatandaş', 'es': 'Ciudadano', 'fr': 'Citoyen', 'de': 'Bürger', 'ru': 'Житель', 'zh-CN': '平民', 'hi': 'नागरिक', 'ur': 'شہری', 'pt': 'Cidadão', 'it': 'Cittadino', 'az': 'Vətəndaş', 'id': 'Warga', 'ja': '市民', 'ko': '시민'},
    'Doctor': {'fa': 'دکتر', 'ar': 'الطبيب', 'tr': 'Doktor', 'es': 'Doctor', 'fr': 'Docteur', 'de': 'Arzt', 'ru': 'Доктор', 'zh-CN': '医生', 'hi': 'डॉक्टर', 'ur': 'ڈاکٹر', 'pt': 'Médico', 'it': 'Dottore', 'az': 'Həkim', 'id': 'Dokter', 'ja': '医者', 'ko': '의사'},
    'Sniper': {'fa': 'اسنایپر', 'ar': 'القناص', 'tr': 'Keskin Nişancı', 'es': 'Francotirador', 'fr': 'Sniper', 'de': 'Scharfschütze', 'ru': 'Снайпер', 'zh-CN': '狙击手', 'hi': 'स्नाइपर', 'ur': 'سنائپر', 'pt': 'Atirador', 'it': 'Cecchino', 'az': 'Snayper', 'id': 'Penembak Jitu', 'ja': 'スナイパー', 'ko': '저격수'},
    'Bartender': {'fa': 'ساقی', 'ar': 'الساقي', 'tr': 'Barmen', 'es': 'Cantinero', 'fr': 'Barman', 'de': 'Barkeeper', 'ru': 'Бармен', 'zh-CN': '酒保', 'hi': 'बारटेंडर', 'ur': 'بارٹینڈر', 'pt': 'Barman', 'it': 'Barista', 'az': 'Barmen', 'id': 'Bartender', 'ja': 'バーテンダー', 'ko': '바텐더'},
    'Priest': {'fa': 'کشیش', 'ar': 'القس', 'tr': 'Papaz', 'es': 'Sacerdote', 'fr': 'Prêtre', 'de': 'Priester', 'ru': 'Священник', 'zh-CN': '牧师', 'hi': 'पादरी', 'ur': 'پادری', 'pt': 'Padre', 'it': 'Prete', 'az': 'Keşiş', 'id': 'Pendeta', 'ja': '神父', 'ko': '신부'},
    'Detective': {'fa': 'کارآگاه', 'ar': 'المحقق', 'tr': 'Dedektif', 'es': 'Detective', 'fr': 'Détective', 'de': 'Detektiv', 'ru': 'Детектив', 'zh-CN': '侦探', 'hi': 'जासूस', 'ur': 'جاسوس', 'pt': 'Detetive', 'it': 'Detective', 'az': 'Detektiv', 'id': 'Detektif', 'ja': '探偵', 'ko': '탐정'},
    'Investigator': {'fa': 'بازپرس', 'ar': 'المحقق العام', 'tr': 'Soruşturmacı', 'es': 'Investigador', 'fr': 'Enquêteur', 'de': 'Ermittler', 'ru': 'Следователь', 'zh-CN': '调查员', 'hi': 'अन्वेषक', 'ur': 'تفتیش کار', 'pt': 'Investigador', 'it': 'Investigatore', 'az': 'İstintaqçı', 'id': 'Penyelidik', 'ja': '調査官', 'ko': '수사관'},
    'Cowboy': {'fa': 'کابوی', 'ar': 'راعي البقر', 'tr': 'Kovboy', 'es': 'Vaquero', 'fr': 'Cowboy', 'de': 'Cowboy', 'ru': 'Ковбой', 'zh-CN': '牛仔', 'hi': 'काउबॉय', 'ur': 'کاؤ بوائے', 'pt': 'Caubói', 'it': 'Cowboy', 'az': 'Kovboy', 'id': 'Koboi', 'ja': 'カウボーイ', 'ko': '카우보이'},
    'Bomber': {'fa': 'بمبر', 'ar': 'المفجر', 'tr': 'Bombacı', 'es': 'Bombardero', 'fr': 'Bombardier', 'de': 'Bomber', 'ru': 'Подрывник', 'zh-CN': '炸弹客', 'hi': 'बमवर्षक', 'ur': 'بمبار', 'pt': 'Bombardeiro', 'it': 'Bombardiere', 'az': 'Bombaçı', 'id': 'Pengebom', 'ja': '爆弾魔', 'ko': '폭탄범'},
    'Gunman': {'fa': 'تفنگدار', 'ar': 'المسلح', 'tr': 'Silahşör', 'es': 'Pistolero', 'fr': 'Homme Armé', 'de': 'Revolvermann', 'ru': 'Стрелок', 'zh-CN': '枪手', 'hi': 'बंदूकधारी', 'ur': 'بندوق بردار', 'pt': 'Pistoleiro', 'it': 'Pistolero', 'az': 'Silahlı', 'id': 'Penembak', 'ja': 'ガンマン', 'ko': '총잡이'},
    'Invincible': {'fa': 'رویین‌تن', 'ar': 'الذي لا يُقهر', 'tr': 'Yenilmez', 'es': 'Invencible', 'fr': 'Invincible', 'de': 'Unbesiegbar', 'ru': 'Неуязвимый', 'zh-CN': '无敌者', 'hi': 'अजेय', 'ur': 'ناقابلِ شکست', 'pt': 'Invencível', 'it': 'Invincibile', 'az': 'Məğlubedilməz', 'id': 'Tak Terkalahkan', 'ja': '無敵', 'ko': '무적'},
    'Commander': {'fa': 'فرمانده', 'ar': 'القائد', 'tr': 'Komutan', 'es': 'Comandante', 'fr': 'Commandant', 'de': 'Kommandant', 'ru': 'Командир', 'zh-CN': '指挥官', 'hi': 'कमांडर', 'ur': 'کمانڈر', 'pt': 'Comandante', 'it': 'Comandante', 'az': 'Komandan', 'id': 'Komandan', 'ja': '指揮官', 'ko': '사령관'},
    'Guard': {'fa': 'نگهبان', 'ar': 'الحارس', 'tr': 'Muhafız', 'es': 'Guardia', 'fr': 'Garde', 'de': 'Wächter', 'ru': 'Охранник', 'zh-CN': '守卫', 'hi': 'रक्षक', 'ur': 'محافظ', 'pt': 'Guarda', 'it': 'Guardia', 'az': 'Mühafizəçi', 'id': 'Penjaga', 'ja': 'ガード', 'ko': '경호원'},
    'Freemason': {'fa': 'سرماسون', 'ar': 'الماسوني', 'tr': 'Mason', 'es': 'Masón', 'fr': 'Franc-maçon', 'de': 'Freimaurer', 'ru': 'Масон', 'zh-CN': '共济会员', 'hi': 'फ्रीमेसन', 'ur': 'فری میسن', 'pt': 'Maçom', 'it': 'Massone', 'az': 'Mason', 'id': 'Mason', 'ja': 'フリーメイソン', 'ko': '프리메이슨'},
    'Tyler': {'fa': 'تایلر', 'ar': 'تايلر', 'tr': 'Tyler', 'es': 'Tyler', 'fr': 'Tyler', 'de': 'Tyler', 'ru': 'Тайлер', 'zh-CN': '泰勒', 'hi': 'टायलर', 'ur': 'ٹائلر', 'pt': 'Tyler', 'it': 'Tyler', 'az': 'Tyler', 'id': 'Tyler', 'ja': 'タイラー', 'ko': '타일러'},
    'Snowman': {'fa': 'آدم‌برفی', 'ar': 'رجل الثلج', 'tr': 'Kardan Adam', 'es': 'Muñeco de Nieve', 'fr': 'Bonhomme de Neige', 'de': 'Schneemann', 'ru': 'Снеговик', 'zh-CN': '雪人', 'hi': 'हिममानव', 'ur': 'برف کا آدمی', 'pt': 'Boneco de Neve', 'it': 'Pupazzo di Neve', 'az': 'Qarköynəyi', 'id': 'Manusia Salju', 'ja': '雪だるま', 'ko': '눈사람'},
    'Veteran': {'fa': 'کهنه‌سرباز', 'ar': 'المخضرم', 'tr': 'Gazi', 'es': 'Veterano', 'fr': 'Vétéran', 'de': 'Veteran', 'ru': 'Ветеран', 'zh-CN': '老兵', 'hi': 'अनुभवी', 'ur': 'تجربہ کار', 'pt': 'Veterano', 'it': 'Veterano', 'az': 'Veteran', 'id': 'Veteran', 'ja': '退役軍人', 'ko': '베테랑'},
    'Mayor': {'fa': 'شهردار', 'ar': 'العمدة', 'tr': 'Belediye Başkanı', 'es': 'Alcalde', 'fr': 'Maire', 'de': 'Bürgermeister', 'ru': 'Мэр', 'zh-CN': '市长', 'hi': 'मेयर', 'ur': 'میئر', 'pt': 'Prefeito', 'it': 'Sindaco', 'az': 'Mer', 'id': 'Wali Kota', 'ja': '市長', 'ko': '시장'},
    'Psychologist': {'fa': 'روان‌شناس', 'ar': 'طبيب نفسي', 'tr': 'Psikolog', 'es': 'Psicólogo', 'fr': 'Psychologue', 'de': 'Psychologe', 'ru': 'Психолог', 'zh-CN': '心理学家', 'hi': 'मनोवैज्ञानिक', 'ur': 'ماہرِ نفسیات', 'pt': 'Psicólogo', 'it': 'Psicologo', 'az': 'Psixoloq', 'id': 'Psikolog', 'ja': '心理学者', 'ko': '심리학자'},
    'Mafia': {'fa': 'مافیا', 'ar': 'المافيا', 'tr': 'Mafya', 'es': 'Mafioso', 'fr': 'Mafieux', 'de': 'Mafia', 'ru': 'Мафия', 'zh-CN': '黑手党', 'hi': 'माफिया', 'ur': 'مافیا', 'pt': 'Máfia', 'it': 'Mafia', 'az': 'Mafiya', 'id': 'Mafia', 'ja': 'マフィア', 'ko': '마피아'},
    'Godfather': {'fa': 'پدرخوانده', 'ar': 'العراب', 'tr': 'Baba', 'es': 'Padrino', 'fr': 'Parrain', 'de': 'Pate', 'ru': 'Крёстный отец', 'zh-CN': '教父', 'hi': 'गॉडफादर', 'ur': 'گاڈ فادر', 'pt': 'Padrinho', 'it': 'Padrino', 'az': 'Cəngavər', 'id': 'Bapak Baptis', 'ja': 'ゴッドファーザー', 'ko': '대부'},
    'Terrorist': {'fa': 'تروریست', 'ar': 'الإرهابي', 'tr': 'Terörist', 'es': 'Terrorista', 'fr': 'Terroriste', 'de': 'Terrorist', 'ru': 'Террорист', 'zh-CN': '恐怖分子', 'hi': 'आतंकवादी', 'ur': 'دہشت گرد', 'pt': 'Terrorista', 'it': 'Terrorista', 'az': 'Terrorçu', 'id': 'Teroris', 'ja': 'テロリスト', 'ko': '테러리스트'},
    'Thief': {'fa': 'دزد', 'ar': 'اللص', 'tr': 'Hırsız', 'es': 'Ladrón', 'fr': 'Voleur', 'de': 'Dieb', 'ru': 'Вор', 'zh-CN': '小偷', 'hi': 'चोर', 'ur': 'چور', 'pt': 'Ladrão', 'it': 'Ladro', 'az': 'Oğru', 'id': 'Pencuri', 'ja': '泥棒', 'ko': '도둑'},
    'Natasha': {'fa': 'ناتاشا', 'ar': 'ناتاشا', 'tr': 'Natasha', 'es': 'Natasha', 'fr': 'Natasha', 'de': 'Natasha', 'ru': 'Наташа', 'zh-CN': '娜塔莎', 'hi': 'नताशा', 'ur': 'ناتاشا', 'pt': 'Natasha', 'it': 'Natasha', 'az': 'Nataşa', 'id': 'Natasha', 'ja': 'ナターシャ', 'ko': '나타샤'},
    'Joker': {'fa': 'جوکر', 'ar': 'الجوكر', 'tr': 'Joker', 'es': 'Bromista', 'fr': 'Joker', 'de': 'Joker', 'ru': 'Джокер', 'zh-CN': '小丑', 'hi': 'जोकर', 'ur': 'جوکر', 'pt': 'Coringa', 'it': 'Joker', 'az': 'Joker', 'id': 'Joker', 'ja': 'ジョーカー', 'ko': '조커'},
    'Enchanter': {'fa': 'افسونگر', 'ar': 'الساحر', 'tr': 'Büyücü', 'es': 'Encantador', 'fr': 'Enchanteur', 'de': 'Zauberer', 'ru': 'Чародей', 'zh-CN': '魅惑者', 'hi': 'जादूगर', 'ur': 'جادوگر', 'pt': 'Encantador', 'it': 'Incantatore', 'az': 'Sehrbaz', 'id': 'Penyihir', 'ja': '魔術師', 'ko': '마법사'},
    'Yakuza': {'fa': 'یاکوزا', 'ar': 'الياكوزا', 'tr': 'Yakuza', 'es': 'Yakuza', 'fr': 'Yakuza', 'de': 'Yakuza', 'ru': 'Якудза', 'zh-CN': '黑帮', 'hi': 'याकूज़ा', 'ur': 'یاکوزا', 'pt': 'Yakuza', 'it': 'Yakuza', 'az': 'Yakuza', 'id': 'Yakuza', 'ja': 'ヤクザ', 'ko': '야쿠자'},
    'Strongman': {'fa': 'مرد قوی', 'ar': 'الرجل القوي', 'tr': 'Güçlü Adam', 'es': 'Forzudo', 'fr': 'Homme Fort', 'de': 'Starker Mann', 'ru': 'Силач', 'zh-CN': '大力士', 'hi': 'शक्तिशाली', 'ur': 'طاقتور آدمی', 'pt': 'Homem Forte', 'it': 'Uomo Forte', 'az': 'Güclü Adam', 'id': 'Orang Kuat', 'ja': '怪力男', 'ko': '힘센 남자'},
    'Psycho': {'fa': 'روانی', 'ar': 'المختل', 'tr': 'Psikopat', 'es': 'Psicópata', 'fr': 'Psychopathe', 'de': 'Psychopath', 'ru': 'Психопат', 'zh-CN': '精神病患者', 'hi': 'मनोरोगी', 'ur': 'ذہنی مریض', 'pt': 'Psicopata', 'it': 'Psicopatico', 'az': 'Psixopat', 'id': 'Psikopat', 'ja': 'サイコ', 'ko': '싸이코'},
    'Spy': {'fa': 'جاسوس', 'ar': 'الجاسوس', 'tr': 'Casus', 'es': 'Espía', 'fr': 'Espion', 'de': 'Spion', 'ru': 'Шпион', 'zh-CN': '间谍', 'hi': 'जासूस', 'ur': 'جاسوس', 'pt': 'Espião', 'it': 'Spia', 'az': 'Casus', 'id': 'Mata-mata', 'ja': 'スパイ', 'ko': '스파이'},
    'Consigliere': {'fa': 'مشاور', 'ar': 'المستشار', 'tr': 'Danışman', 'es': 'Consejero', 'fr': 'Conseiller', 'de': 'Berater', 'ru': 'Консильери', 'zh-CN': '顾问', 'hi': 'सलाहकार', 'ur': 'مشیر', 'pt': 'Consigliere', 'it': 'Consigliere', 'az': 'Məsləhətçi', 'id': 'Penasihat', 'ja': '顧問', 'ko': '고문'},
    'Blackmailer': {'fa': 'اخاذ', 'ar': 'المبتز', 'tr': 'Şantajcı', 'es': 'Chantajista', 'fr': 'Maître Chanteur', 'de': 'Erpresser', 'ru': 'Шантажист', 'zh-CN': '勒索者', 'hi': 'ब्लैकमेलर', 'ur': 'بلیک میلر', 'pt': 'Chantagista', 'it': 'Ricattatore', 'az': 'Şantajçı', 'id': 'Pemeras', 'ja': '恐喝者', 'ko': '협박자'},
    'Nostradamus': {'fa': 'نوسترآداموس', 'ar': 'نوستراداموس', 'tr': 'Nostradamus', 'es': 'Nostradamus', 'fr': 'Nostradamus', 'de': 'Nostradamus', 'ru': 'Нострадамус', 'zh-CN': '诺查丹玛斯', 'hi': 'नास्त्रेदमस', 'ur': 'نوسٹراڈیمس', 'pt': 'Nostradamus', 'it': 'Nostradamus', 'az': 'Nostradamus', 'id': 'Nostradamus', 'ja': 'ノストラダムス', 'ko': '노스트라다무스'},
    'Killer': {'fa': 'کیلر', 'ar': 'القاتل', 'tr': 'Katil', 'es': 'Asesino', 'fr': 'Tueur', 'de': 'Killer', 'ru': 'Убийца', 'zh-CN': '杀手', 'hi': 'हत्यारा', 'ur': 'قاتل', 'pt': 'Assassino', 'it': 'Killer', 'az': 'Qatil', 'id': 'Pembunuh', 'ja': 'キラー', 'ko': '킬러'},
    'President': {'fa': 'پرزیدنت', 'ar': 'الرئيس', 'tr': 'Başkan', 'es': 'Presidente', 'fr': 'Président', 'de': 'Präsident', 'ru': 'Президент', 'zh-CN': '总统', 'hi': 'राष्ट्रपति', 'ur': 'صدر', 'pt': 'Presidente', 'it': 'Presidente', 'az': 'Prezident', 'id': 'Presiden', 'ja': '大統領', 'ko': '대통령'},
  // === Buttons / UI labels ===
    'Number of Players': {'tr': 'Oyuncu Sayısı', 'ar': 'عدد اللاعبين', 'es': 'Número de Jugadores', 'fr': 'Nombre de Joueurs', 'fa': 'تعداد بازیکنان', 'de': 'Spieleranzahl', 'ru': 'Количество игроков', 'zh-CN': '玩家人数', 'hi': 'खिलाड़ियों की संख्या', 'ur': 'کھلاڑیوں کی تعداد', 'pt': 'Número de Jogadores', 'it': 'Numero di Giocatori', 'az': 'Oyunçu sayı', 'id': 'Jumlah Pemain', 'ja': 'プレイヤー数', 'ko': '플레이어 수'},
    'More Players': {'tr': 'Daha Fazla Oyuncu', 'ar': 'المزيد من اللاعبين', 'es': 'Más Jugadores', 'fr': 'Plus de Joueurs', 'fa': 'بازیکنان بیشتر', 'de': 'Mehr Spieler', 'ru': 'Больше игроков', 'zh-CN': '更多玩家', 'hi': 'अधिक खिलाड़ी', 'ur': 'مزید کھلاڑی', 'pt': 'Mais Jogadores', 'it': 'Più Giocatori', 'az': 'Daha çox oyunçu', 'id': 'Pemain Lebih Banyak', 'ja': 'さらにプレイヤー', 'ko': '플레이어 추가'},
    'Help': {'tr': 'Yardım', 'ar': 'مساعدة', 'es': 'Ayuda', 'fr': 'Aide', 'fa': 'راهنما', 'de': 'Hilfe', 'ru': 'Помощь', 'zh-CN': '帮助', 'hi': 'सहायता', 'ur': 'مدد', 'pt': 'Ajuda', 'it': 'Aiuto', 'az': 'Kömək', 'id': 'Bantuan', 'ja': 'ヘルプ', 'ko': '도움말'},
    'Rulebook': {'tr': 'Kural Kitabı', 'ar': 'كتاب القواعد', 'es': 'Reglamento', 'fr': 'Règlement', 'fa': 'رول‌بوک', 'de': 'Regelbuch', 'ru': 'Свод правил', 'zh-CN': '规则手册', 'hi': 'नियम पुस्तिका', 'ur': 'قوانین کی کتاب', 'pt': 'Livro de Regras', 'it': 'Regolamento', 'az': 'Qayda kitabı', 'id': 'Buku Aturan', 'ja': 'ルールブック', 'ko': '룰북'},
    'Number of Mafia': {'tr': 'Mafya Sayısı', 'ar': 'عدد المافيا', 'es': 'Número de Mafiosos', 'fr': 'Nombre de Mafieux', 'fa': 'تعداد مافیا', 'de': 'Anzahl der Mafia', 'ru': 'Количество мафии', 'zh-CN': '黑手党人数', 'hi': 'माफिया की संख्या', 'ur': 'مافیا کی تعداد', 'pt': 'Número de Máfia', 'it': 'Numero di Mafiosi', 'az': 'Mafiya sayı', 'id': 'Jumlah Mafia', 'ja': 'マフィアの数', 'ko': '마피아 수'},
    'Select Roles': {'tr': 'Rolleri Seç', 'ar': 'اختر الأدوار', 'es': 'Elegir Roles', 'fr': 'Choisir les Rôles', 'fa': 'انتخاب نقش‌ها', 'de': 'Rollen wählen', 'ru': 'Выбор ролей', 'zh-CN': '选择角色', 'hi': 'भूमिकाएं चुनें', 'ur': 'کردار منتخب کریں', 'pt': 'Selecionar Papéis', 'it': 'Seleziona Ruoli', 'az': 'Rolları seçin', 'id': 'Pilih Peran', 'ja': '役職選択', 'ko': '역할 선택'},
    'Start Game': {'tr': 'Oyunu Başlat', 'ar': 'ابدأ اللعبة', 'es': 'Iniciar Juego', 'fr': 'Démarrer la Partie', 'fa': 'شروع بازی', 'de': 'Spiel starten', 'ru': 'Начать игру', 'zh-CN': '开始游戏', 'hi': 'खेल शुरू करें', 'ur': 'کھیل شروع کریں', 'pt': 'Iniciar Jogo', 'it': 'Inizia Partita', 'az': 'Oyuna başla', 'id': 'Mulai Permainan', 'ja': 'ゲーム開始', 'ko': '게임 시작'},
    'Full Roster': {'tr': 'Tam Kadro', 'ar': 'القائمة الكاملة', 'es': 'Lista Completa', 'fr': 'Liste Complète', 'fa': 'لیست کامل', 'de': 'Vollständige Liste', 'ru': 'Полный список', 'zh-CN': '完整名单', 'hi': 'पूर्ण सूची', 'ur': 'مکمل فہرست', 'pt': 'Lista Completa', 'it': 'Elenco Completo', 'az': 'Tam siyahı', 'id': 'Daftar Lengkap', 'ja': '全員リスト', 'ko': '전체 명단'},
    'Day': {'tr': 'Gündüz', 'ar': 'النهار', 'es': 'Día', 'fr': 'Jour', 'fa': 'روز', 'de': 'Tag', 'ru': 'День', 'zh-CN': '白天', 'hi': 'दिन', 'ur': 'دن', 'pt': 'Dia', 'it': 'Giorno', 'az': 'Gündüz', 'id': 'Siang', 'ja': '昼', 'ko': '낮'},
    'Night Actions': {'tr': 'Gece Aksiyonları', 'ar': 'أفعال الليل', 'es': 'Acciones Nocturnas', 'fr': 'Actions Nocturnes', 'fa': 'اعمال شب', 'de': 'Nachtaktionen', 'ru': 'Ночные действия', 'zh-CN': '夜晚行动', 'hi': 'रात्रि क्रियाएं', 'ur': 'رات کے اعمال', 'pt': 'Ações Noturnas', 'it': 'Azioni Notturne', 'az': 'Gecə hərəkətləri', 'id': 'Aksi Malam', 'ja': '夜のアクション', 'ko': '밤 행동'},
    'End Night': {'tr': 'Geceyi Bitir', 'ar': 'إنهاء الليل', 'es': 'Terminar Noche', 'fr': 'Terminer la Nuit', 'fa': 'پایان شب', 'de': 'Nacht beenden', 'ru': 'Закончить ночь', 'zh-CN': '结束夜晚', 'hi': 'रात समाप्त करें', 'ur': 'رات ختم کریں', 'pt': 'Terminar Noite', 'it': 'Fine Notte', 'az': 'Gecəni bitir', 'id': 'Akhiri Malam', 'ja': '夜を終了', 'ko': '밤 종료'},
    'End Game': {'tr': 'Oyunu Bitir', 'ar': 'إنهاء اللعبة', 'es': 'Terminar Juego', 'fr': 'Terminer la Partie', 'fa': 'پایان بازی', 'de': 'Spiel beenden', 'ru': 'Закончить игру', 'zh-CN': '结束游戏', 'hi': 'खेल समाप्त करें', 'ur': 'کھیل ختم کریں', 'pt': 'Terminar Jogo', 'it': 'Fine Partita', 'az': 'Oyunu bitir', 'id': 'Akhiri Permainan', 'ja': 'ゲーム終了', 'ko': '게임 종료'},
    'Confirm & Go to Day': {'tr': 'Onayla ve Gündüze Geç', 'ar': 'تأكيد والانتقال إلى النهار', 'es': 'Confirmar e Ir al Día', 'fr': 'Confirmer et Passer au Jour', 'fa': 'تایید و ورود به روز', 'de': 'Bestätigen und zum Tag', 'ru': 'Подтвердить и перейти к дню', 'zh-CN': '确认并进入白天', 'hi': 'पुष्टि करें और दिन पर जाएं', 'ur': 'تصدیق کریں اور دن پر جائیں', 'pt': 'Confirmar e Ir para o Dia', 'it': 'Conferma e Vai al Giorno', 'az': 'Təsdiqlə və gündüzə keç', 'id': 'Konfirmasi & Lanjut ke Siang', 'ja': '確認して昼へ', 'ko': '확인하고 낮으로'},
    'Previous': {'fa': 'قبلی', 'de': 'Zurück', 'ru': 'Назад', 'zh-CN': '上一个', 'hi': 'पिछला', 'ur': 'پچھلا', 'pt': 'Anterior', 'it': 'Precedente', 'az': 'Əvvəlki', 'id': 'Sebelumnya', 'ja': '前へ', 'ko': '이전'},
    'Next': {'fa': 'بعدی', 'de': 'Weiter', 'ru': 'Далее', 'zh-CN': '下一个', 'hi': 'अगला', 'ur': 'اگلا', 'pt': 'Próximo', 'it': 'Successivo', 'az': 'Növbəti', 'id': 'Berikutnya', 'ja': '次へ', 'ko': '다음'},
    'Cancel': {'fa': 'انصراف', 'de': 'Abbrechen', 'ru': 'Отмена', 'zh-CN': '取消', 'hi': 'रद्द करें', 'ur': 'منسوخ کریں', 'pt': 'Cancelar', 'it': 'Annulla', 'az': 'Ləğv et', 'id': 'Batal', 'ja': 'キャンセル', 'ko': '취소'},
    'Confirm': {'fa': 'تایید', 'de': 'Bestätigen', 'ru': 'Подтвердить', 'zh-CN': '确认', 'hi': 'पुष्टि करें', 'ur': 'تصدیق کریں', 'pt': 'Confirmar', 'it': 'Conferma', 'az': 'Təsdiqlə', 'id': 'Konfirmasi', 'ja': '確認', 'ko': '확인'},
    'Back to Day': {'fa': 'برگشت به روز', 'de': 'Zurück zum Tag', 'ru': 'Вернуться ко дню', 'zh-CN': '返回白天', 'hi': 'दिन पर वापस जाएं', 'ur': 'دن پر واپس جائیں', 'pt': 'Voltar ao Dia', 'it': 'Torna al Giorno', 'az': 'Gündüzə qayıt', 'id': 'Kembali ke Siang', 'ja': '昼へ戻る', 'ko': '낮으로 돌아가기'},
    'Choose Rulebook': {'fa': 'انتخاب رول‌بوک', 'de': 'Regelbuch wählen', 'ru': 'Выбрать свод правил', 'zh-CN': '选择规则手册', 'hi': 'नियम पुस्तिका चुनें', 'ur': 'قوانین کی کتاب منتخب کریں', 'pt': 'Escolher Livro de Regras', 'it': 'Scegli Regolamento', 'az': 'Qayda kitabını seç', 'id': 'Pilih Buku Aturan', 'ja': 'ルールブックを選ぶ', 'ko': '룰북 선택'},
    'Team Sizes': {'fa': 'تعداد تیم‌ها', 'de': 'Teamgrößen', 'ru': 'Размеры команд', 'zh-CN': '队伍人数', 'hi': 'टीम का आकार', 'ur': 'ٹیم کا سائز', 'pt': 'Tamanho das Equipes', 'it': 'Dimensioni Squadre', 'az': 'Komanda ölçüləri', 'id': 'Ukuran Tim', 'ja': 'チーム人数', 'ko': '팀 인원'},
    'Coming Soon': {'fa': 'به‌زودی', 'de': 'Demnächst', 'ru': 'Скоро', 'zh-CN': '即将推出', 'hi': 'जल्द आ रहा है', 'ur': 'جلد آ رہا ہے', 'pt': 'Em Breve', 'it': 'Prossimamente', 'az': 'Tezliklə', 'id': 'Segera Hadir', 'ja': '近日公開', 'ko': '출시 예정'},
    'Timer': {'fa': 'تایمر', 'de': 'Timer', 'ru': 'Таймер', 'zh-CN': '计时器', 'hi': 'टाइमर', 'ur': 'ٹائمر', 'pt': 'Cronômetro', 'it': 'Timer', 'az': 'Taymer', 'id': 'Pengatur Waktu', 'ja': 'タイマー', 'ko': '타이머'},
    'Votes': {'fa': 'آرا', 'de': 'Stimmen', 'ru': 'Голоса', 'zh-CN': '投票', 'hi': 'वोट', 'ur': 'ووٹ', 'pt': 'Votos', 'it': 'Voti', 'az': 'Səslər', 'id': 'Suara', 'ja': '投票', 'ko': '투표'},
    'Night History': {'fa': 'تاریخچه شب', 'de': 'Nachtverlauf', 'ru': 'История ночей', 'zh-CN': '夜晚记录', 'hi': 'रात्रि इतिहास', 'ur': 'رات کی تاریخ', 'pt': 'Histórico Noturno', 'it': 'Cronologia Notturna', 'az': 'Gecə tarixçəsi', 'id': 'Riwayat Malam', 'ja': '夜の履歴', 'ko': '밤 기록'},
    'Kick': {'fa': 'حذف', 'de': 'Entfernen', 'ru': 'Удалить', 'zh-CN': '淘汰', 'hi': 'हटाएं', 'ur': 'نکالیں', 'pt': 'Remover', 'it': 'Rimuovi', 'az': 'Çıxar', 'id': 'Keluarkan', 'ja': '排除', 'ko': '제거'},
    'Custom Rulebook': {'fa': 'رول‌بوک سفارشی', 'de': 'Eigenes Regelbuch', 'ru': 'Свой свод правил', 'zh-CN': '自定义规则手册', 'hi': 'कस्टम नियम पुस्तिका', 'ur': 'حسب ضرورت قوانین کی کتاب', 'pt': 'Livro de Regras Personalizado', 'it': 'Regolamento Personalizzato', 'az': 'Fərdi qayda kitabı', 'id': 'Buku Aturan Kustom', 'ja': 'カスタムルールブック', 'ko': '커스텀 룰북'},
    'Add Custom Role': {'fa': 'افزودن نقش سفارشی', 'de': 'Eigene Rolle hinzufügen', 'ru': 'Добавить свою роль', 'zh-CN': '添加自定义角色', 'hi': 'कस्टम भूमिका जोड़ें', 'ur': 'حسب ضرورت کردار شامل کریں', 'pt': 'Adicionar Papel Personalizado', 'it': 'Aggiungi Ruolo Personalizzato', 'az': 'Fərdi rol əlavə et', 'id': 'Tambah Peran Kustom', 'ja': 'カスタム役職を追加', 'ko': '커스텀 역할 추가'},
    'Reset clock': {'fa': 'ریست ساعت', 'de': 'Uhr zurücksetzen', 'ru': 'Сбросить таймер', 'zh-CN': '重置计时', 'hi': 'घड़ी रीसेट करें', 'ur': 'گھڑی ری سیٹ کریں', 'pt': 'Reiniciar Cronômetro', 'it': 'Reimposta Timer', 'az': 'Saatı sıfırla', 'id': 'Atur Ulang Waktu', 'ja': 'タイマーリセット', 'ko': '타이머 초기화'},
    'Undo': {'fa': 'واگرد', 'de': 'Rückgängig', 'ru': 'Отменить', 'zh-CN': '撤销', 'hi': 'पूर्ववत करें', 'ur': 'واپس کریں', 'pt': 'Desfazer', 'it': 'Annulla', 'az': 'Geri al', 'id': 'Batalkan', 'ja': '元に戻す', 'ko': '실행 취소'},
    'OK': {'fa': 'باشه', 'de': 'OK', 'ru': 'ОК', 'zh-CN': '好的', 'hi': 'ठीक है', 'ur': 'ٹھیک ہے', 'pt': 'OK', 'it': 'OK', 'az': 'Tamam', 'id': 'OK', 'ja': 'OK', 'ko': '확인'},
    'Speaking Timer': {'fa': 'تایمر صحبت', 'de': 'Redezeit-Timer', 'ru': 'Таймер выступления', 'zh-CN': '发言计时器', 'hi': 'बोलने का टाइमर', 'ur': 'بولنے کا ٹائمر', 'pt': 'Cronômetro de Fala', 'it': 'Timer di Discussione', 'az': 'Danışıq taymeri', 'id': 'Pengatur Waktu Bicara', 'ja': '発言タイマー', 'ko': '발언 타이머'},
    'Choose Mode': {'fa': 'انتخاب حالت', 'de': 'Modus wählen', 'ru': 'Выбор режима', 'zh-CN': '选择模式', 'hi': 'मोड चुनें', 'ur': 'موڈ منتخب کریں', 'pt': 'Escolher Modo', 'it': 'Scegli Modalità', 'az': 'Rejim seç', 'id': 'Pilih Mode', 'ja': 'モード選択', 'ko': '모드 선택'},
    'Online Game': {'fa': 'بازی آنلاین', 'de': 'Online-Spiel', 'ru': 'Онлайн-игра', 'zh-CN': '在线游戏', 'hi': 'ऑनलाइन गेम', 'ur': 'آن لائن گیم', 'pt': 'Jogo Online', 'it': 'Partita Online', 'az': 'Onlayn oyun', 'id': 'Permainan Online', 'ja': 'オンラインゲーム', 'ko': '온라인 게임'},
    'Game Master Assistant': {'fa': 'دستیار گرداننده', 'de': 'Spielleiter-Assistent', 'ru': 'Помощник ведущего', 'zh-CN': '主持人助手', 'hi': 'गेम मास्टर सहायक', 'ur': 'گیم ماسٹر اسسٹنٹ', 'pt': 'Assistente do Mestre', 'it': 'Assistente del Master', 'az': 'Aparıcı köməkçisi', 'id': 'Asisten Pemandu', 'ja': 'ゲームマスター補助', 'ko': '게임 마스터 도우미'},
  };

  String tr(String english) {
    final lang = languageCode.value;
    if (lang == 'en') return english;
    return _translations[english]?[lang] ?? english;
  }
}
