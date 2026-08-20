import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/banner_app_bar_background.dart';

/// One paragraph of rule text, in both languages.
class RulebookSection {
  final String titleEn;
  final String titleFa;
  final String bodyEn;
  final String bodyFa;

  const RulebookSection({
    required this.titleEn,
    required this.titleFa,
    required this.bodyEn,
    required this.bodyFa,
  });
}

/// A read-only page for one of the preset rulebook variants (Classic,
/// Mountainous 11v2, etc.) - reference material only, not wired into the
/// live game engine yet.
class PresetRulebookScreen extends StatelessWidget {
  final String titleEn;
  final String titleFa;
  final List<RulebookSection> sections;

  const PresetRulebookScreen({
    super.key,
    required this.titleEn,
    required this.titleFa,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const BannerAppBarBackground(),
        title: Text('Game Master Assistant - $titleEn'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Compiled by Game Master Assistant',
            style: TextStyle(color: AppColors.textGold, fontSize: 11, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 6),
          Text(titleEn, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
          const Divider(height: 28, color: Colors.white24),
          for (final s in sections) ...[
            Text(
              s.titleEn,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(s.bodyEn, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Reference only for now - not yet wired into automatic game '
              'tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

/// The 4 preset rulebook variants' content, written by Game Master
/// Assistant based on widely-known, standard Mafia/Werewolf conventions.
class PresetRulebooks {
  PresetRulebooks._();

  static const classic = [
    RulebookSection(
      titleEn: 'Setup',
      titleFa: 'آماده‌سازی',
      bodyEn: 'For 7 players: 3 Villagers, 1 Cop, 1 Doctor, 2 Mafia. The '
          'moderator deals roles secretly and everyone keeps their role '
          'hidden all game.',
      bodyFa: 'برای ۷ بازیکن: ۳ شهروند، ۱ کارآگاه، ۱ دکتر، ۲ مافیا. گرداننده '
          'نقش‌ها را مخفیانه پخش می‌کند و همه تا پایان بازی نقش خود را مخفی نگه می‌دارند.',
    ),
    RulebookSection(
      titleEn: 'Night Phase',
      titleFa: 'فاز شب',
      bodyEn: 'Everyone closes their eyes. The Mafia silently agree on one '
          'player to eliminate. The Cop points to one player and the '
          'moderator signals whether they are Mafia or not. The Doctor '
          'picks one player to protect - if the Mafia targets that same '
          'player, they survive.',
      bodyFa: 'همه چشم‌ها را می‌بندند. مافیا بی‌صدا روی یک بازیکن برای حذف '
          'توافق می‌کند. کارآگاه به یک بازیکن اشاره می‌کند و گرداننده با اشاره '
          'می‌گوید مافیاست یا نه. دکتر یک بازیکن را برای محافظت انتخاب می‌کند - '
          'اگر مافیا همان بازیکن را هدف بگیرد، او زنده می‌ماند.',
    ),
    RulebookSection(
      titleEn: 'Day Phase',
      titleFa: 'فاز روز',
      bodyEn: 'Everyone wakes up and the moderator announces who (if anyone) '
          'was eliminated overnight. Players discuss openly and accuse who '
          'they suspect, then vote. Whoever gets a majority is eliminated '
          'and their role is revealed.',
      bodyFa: 'همه بیدار می‌شوند و گرداننده اعلام می‌کند شب گذشته چه کسی '
          '(اگر کسی) حذف شده. بازیکنان آزادانه بحث و اتهام می‌زنند، سپس رای‌گیری '
          'می‌شود. هر کس اکثریت آرا را بگیرد حذف می‌شود و نقشش فاش می‌شود.',
    ),
    RulebookSection(
      titleEn: 'Winning',
      titleFa: 'شرط برد',
      bodyEn: 'Villagers win once every Mafia member has been eliminated. '
          'Mafia wins once their numbers equal or outnumber the remaining '
          'Villagers.',
      bodyFa: 'شهروندان وقتی برنده می‌شوند که همه اعضای مافیا حذف شده باشند. '
          'مافیا وقتی برنده می‌شود که تعدادش با شهروندان باقی‌مانده برابر یا '
          'بیشتر شود.',
    ),
  ];

  static const mountainous11v2 = [
    RulebookSection(
      titleEn: 'Setup',
      titleFa: 'آماده‌سازی',
      bodyEn: 'For 13 players: 11 plain Villagers, 2 Mafia, no power roles '
          'at all on either side. A stripped-down, high-tension variant '
          'that relies purely on discussion and voting rather than special '
          'abilities.',
      bodyFa: 'برای ۱۳ بازیکن: ۱۱ شهروند ساده، ۲ مافیا، بدون هیچ نقش قدرتی '
          'در هیچ‌کدام از دو طرف. نسخه‌ای ساده و پرتنش که کاملاً به بحث و '
          'رای‌گیری متکی است، نه توانایی‌های ویژه.',
    ),
    RulebookSection(
      titleEn: 'Night Phase',
      titleFa: 'فاز شب',
      bodyEn: 'The only night action is the Mafia choosing one Villager to '
          'eliminate together. There is nothing else to resolve, so nights '
          'are short.',
      bodyFa: 'تنها اکت شب این است که مافیا با هم یک شهروند را برای حذف '
          'انتخاب می‌کند. چیز دیگری برای حل کردن نیست، پس شب‌ها کوتاه هستند.',
    ),
    RulebookSection(
      titleEn: 'Day Phase',
      titleFa: 'فاز روز',
      bodyEn: 'Standard discussion and majority vote. Since no one has '
          'information from a Cop-like role, reading behavior and voting '
          'patterns is the only tool the Villagers have.',
      bodyFa: 'بحث معمولی و رای‌گیری با اکثریت. چون هیچ‌کس اطلاعاتی از یک نقش '
          'شبیه کارآگاه نداره، تحلیل رفتار و الگوی رای‌ها تنها ابزار شهروندانه.',
    ),
    RulebookSection(
      titleEn: 'Winning',
      titleFa: 'شرط برد',
      bodyEn: 'Same as Classic: Villagers win by eliminating both Mafia; '
          'Mafia wins once they equal or outnumber the remaining '
          'Villagers.',
      bodyFa: 'مثل نسخه کلاسیک: شهروندان با حذف هر دو مافیا برنده می‌شوند؛ '
          'مافیا وقتی تعدادش با شهروندان باقی‌مانده برابر یا بیشتر بشه برنده می‌شود.',
    ),
  ];

  static const advancedRolesMix = [
    RulebookSection(
      titleEn: 'Setup',
      titleFa: 'آماده‌سازی',
      bodyEn: 'For 11 players: a Seer (checks a player\'s alignment each '
          'night), a Martyr (can sacrifice themselves to save another), a '
          'Hunter (takes someone down with them if eliminated), 2 Wolves '
          '(the Mafia-equivalent), a Cultist (an independent role working '
          'for the Wolves without being one), and the rest plain '
          'Villagers.',
      bodyFa: 'برای ۱۱ بازیکن: یک غیب‌گو (هر شب همسویی یک بازیکن را بررسی '
          'می‌کند)، یک فداکار (می‌تواند خودش را برای نجات دیگری فدا کند)، یک '
          'شکارچی (اگر حذف شود یک نفر را همراه خودش می‌برد)، ۲ گرگ (معادل '
          'مافیا)، یک فرقه‌گرا (نقشی مستقل که بدون عضویت رسمی برای گرگ‌ها کار '
          'می‌کند)، و بقیه شهروند ساده.',
    ),
    RulebookSection(
      titleEn: 'Night Phase',
      titleFa: 'فاز شب',
      bodyEn: 'The Wolves choose a victim together. The Seer investigates '
          'one player. The Martyr may choose to intercept an attack meant '
          'for someone else, sacrificing themselves instead. All actions '
          'are reported to the moderator in the usual private order.',
      bodyFa: 'گرگ‌ها با هم یک قربانی انتخاب می‌کنند. غیب‌گو یک بازیکن را '
          'بررسی می‌کند. فداکار می‌تواند یک حمله در نظرگرفته‌شده برای فرد دیگر '
          'را روی خودش بگیرد و به‌جای او فدا شود. همه اکت‌ها با همان ترتیب '
          'خصوصی معمول به گرداننده گفته می‌شود.',
    ),
    RulebookSection(
      titleEn: 'Special Rules',
      titleFa: 'قوانین ویژه',
      bodyEn: 'If the Hunter is eliminated (by vote or by the Wolves), they '
          'immediately name one other player who is eliminated with them. '
          'The Cultist wins alongside the Wolves but doesn\'t know who they '
          'are and has no night action of their own.',
      bodyFa: 'اگر شکارچی حذف شود (با رای یا توسط گرگ‌ها)، بلافاصله یک '
          'بازیکن دیگر را نام می‌برد که همراه او حذف می‌شود. فرقه‌گرا همراه '
          'گرگ‌ها برنده می‌شود اما نمی‌داند آن‌ها چه کسانی هستند و هیچ اکت شبی '
          'برای خودش ندارد.',
    ),
    RulebookSection(
      titleEn: 'Winning',
      titleFa: 'شرط برد',
      bodyEn: 'Villagers (and the Seer, Martyr, Hunter) win once both '
          'Wolves are eliminated. The Wolves and Cultist win together once '
          'the Wolves equal or outnumber the remaining Villagers.',
      bodyFa: 'شهروندان (و غیب‌گو، فداکار، شکارچی) وقتی هر دو گرگ حذف بشن '
          'برنده می‌شوند. گرگ‌ها و فرقه‌گرا با هم وقتی تعداد گرگ‌ها با شهروندان '
          'باقی‌مانده برابر یا بیشتر بشه برنده می‌شوند.',
    ),
  ];

  static const townHeavy = [
    RulebookSection(
      titleEn: 'Setup',
      titleFa: 'آماده‌سازی',
      bodyEn: 'For 7 players: 5 plain Villagers, 1 Cop, 1 Doctor, and 2 '
          'Mafia. A gentler variant that gives the Villager side more '
          'informational tools relative to the Mafia\'s numbers, good for '
          'newer groups.',
      bodyFa: 'برای ۷ بازیکن: ۵ شهروند ساده، ۱ کارآگاه، ۱ دکتر، و ۲ مافیا. '
          'نسخه‌ای ملایم‌تر که نسبت به تعداد مافیا، ابزار اطلاعاتی بیشتری به '
          'طرف شهروندان می‌دهد - مناسب گروه‌های تازه‌کار.',
    ),
    RulebookSection(
      titleEn: 'Night & Day Phases',
      titleFa: 'فاز شب و روز',
      bodyEn: 'Identical flow to Classic: Mafia picks a target, Cop '
          'investigates, Doctor protects, then everyone discusses and '
          'votes during the day.',
      bodyFa: 'روندی مثل نسخه کلاسیک: مافیا هدف انتخاب می‌کند، کارآگاه '
          'بررسی می‌کند، دکتر محافظت می‌کند، بعد همه در طول روز بحث و '
          'رای‌گیری می‌کنند.',
    ),
    RulebookSection(
      titleEn: 'Winning',
      titleFa: 'شرط برد',
      bodyEn: 'Villagers win by eliminating both Mafia. Mafia wins once '
          'they equal or outnumber the remaining Villagers - though with '
          'this many Villagers to start, that usually takes the Mafia '
          'longer to reach.',
      bodyFa: 'شهروندان با حذف هر دو مافیا برنده می‌شوند. مافیا وقتی تعدادش '
          'با شهروندان باقی‌مانده برابر یا بیشتر بشه برنده می‌شود - هرچند با '
          'این تعداد شهروند در ابتدا، معمولاً رسیدن مافیا به این نقطه بیشتر '
          'طول می‌کشد.',
    ),
  ];
}
