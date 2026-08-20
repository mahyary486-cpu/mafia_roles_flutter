import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logic/game_state.dart';
import '../widgets/app_background.dart';
import '../widgets/neon_dot_frame.dart';
import '../widgets/tr_text.dart';
import 'custom_rulebook_screen.dart';
import 'role_selection_screen.dart';
import 'rulebook_text_screen.dart';

/// Lets the game master pick which rulebook/ruleset this game follows.
/// Each rulebook can have its own default role mix, win conditions, and
/// night/day action rules. Right now only "Mafia Psychology Academy -
/// Advanced" (the ruleset built throughout this app) is fully wired up;
/// the others are shown so the intended structure is visible, and will be
/// built out one at a time in future updates.
class RulebookSelectorScreen extends StatelessWidget {
  final int totalPlayers;
  final int mafiaCount;
  final int citizenCount;
  final int independentCount;
  final GameState gameState;

  const RulebookSelectorScreen({
    super.key,
    required this.totalPlayers,
    required this.mafiaCount,
    required this.citizenCount,
    required this.independentCount,
    required this.gameState,
  });

  static const _comingSoon = [
    _RulebookInfo(
      titleEn: 'Classic',
      titleFa: 'کلاسیک',
      subtitleEn: '7 players - Villager x3, Cop, Doctor, Mafia x2',
      subtitleFa: '۷ نفره - شهروند×۳، کارآگاه، دکتر، مافیا×۲',
      bodyEn:
          'The original small-town Mafia setup. 7 players: 3 plain '
          'Villagers, a Cop, a Doctor, and 2 Mafia.\n\n'
          'Night: the Mafia secretly agree on one player to eliminate. '
          'The Doctor picks one player (including themselves) to protect '
          'for the night - if the Doctor\'s pick matches the Mafia\'s '
          'target, that player survives. The Cop investigates one player '
          'and privately learns whether they are Mafia or not.\n\n'
          'Day: everyone discusses who they suspect, then votes to lynch '
          'one player. A majority vote eliminates that player immediately.\n\n'
          'Win conditions: the Town (Villagers, Cop, Doctor) wins when '
          'both Mafia are eliminated. The Mafia win once their numbers '
          'equal or outnumber the remaining Town.',
      bodyFa:
          'ساختار اصلی و کلاسیک بازی مافیا در یک شهر کوچک. ۷ بازیکن: ۳ '
          'شهروند ساده، یک کارآگاه، یک دکتر، و ۲ مافیا.\n\n'
          'شب: مافیاها مخفیانه روی حذف یک بازیکن توافق می‌کنند. دکتر یک '
          'بازیکن (حتی خودش) را برای آن شب محافظت می‌کند - اگر انتخاب '
          'دکتر با هدف مافیا یکی باشد، آن بازیکن زنده می‌ماند. کارآگاه یک '
          'بازیکن را استعلام می‌کند و خصوصی می‌فهمد مافیاست یا نه.\n\n'
          'روز: همه درباره مظنونین بحث می‌کنند، سپس با رأی‌گیری یک نفر را '
          'اعدام می‌کنند. با اکثریت آرا آن بازیکن بلافاصله حذف می‌شود.\n\n'
          'شرط برد: شهروندان (شهروند، کارآگاه، دکتر) وقتی هر دو مافیا حذف '
          'شوند می‌برند. مافیا وقتی تعدادشان برابر یا بیشتر از شهروندان '
          'باقی‌مانده شود می‌برد.',
    ),
    _RulebookInfo(
      titleEn: 'Mountainous 11v2',
      titleFa: 'کوهستانی ۱۱ در برابر ۲',
      subtitleEn: '13 players - Villager x11, Mafia x2, no power roles',
      subtitleFa: '۱۳ نفره - شهروند×۱۱، مافیا×۲، بدون نقش قدرت',
      bodyEn:
          'A pure numbers-and-deduction variant with no special roles at '
          'all - 13 players: 11 plain Villagers and 2 Mafia.\n\n'
          'Night: the 2 Mafia secretly agree and eliminate one player. '
          'There is no Doctor and no Cop, so the Town has no information '
          'beyond what happens at the table.\n\n'
          'Day: open discussion followed by a majority vote to lynch one '
          'player.\n\n'
          'Because there are no power roles, this variant leans entirely '
          'on reading behavior, voting patterns, and social deduction - '
          'often used to teach the core mechanics of the game.\n\n'
          'Win conditions: Villagers win once both Mafia are eliminated. '
          'The Mafia win once their numbers equal or outnumber the '
          'remaining Villagers.',
      bodyFa:
          'یک نسخه خالص مبتنی بر عدد و استدلال، بدون هیچ نقش خاصی - ۱۳ '
          'بازیکن: ۱۱ شهروند ساده و ۲ مافیا.\n\n'
          'شب: ۲ مافیا مخفیانه توافق کرده و یک بازیکن را حذف می‌کنند. '
          'دکتر و کارآگاهی وجود ندارد، پس شهروندان اطلاعاتی فراتر از '
          'آنچه سر میز می‌گذرد ندارند.\n\n'
          'روز: بحث آزاد و سپس رأی‌گیری با اکثریت برای اعدام یک نفر.\n\n'
          'چون هیچ نقش قدرتی وجود نداره، این نسخه کاملاً روی خوانش رفتار، '
          'الگوی رأی‌دادن و استدلال اجتماعی تکیه داره - معمولاً برای '
          'آموزش مکانیزم اصلی بازی استفاده می‌شه.\n\n'
          'شرط برد: شهروندان وقتی هر دو مافیا حذف بشن می‌برند. مافیا وقتی '
          'تعدادشان برابر یا بیشتر از شهروندان باقی‌مانده بشه می‌بره.',
    ),
    _RulebookInfo(
      titleEn: 'Advanced Roles Mix (11 Players)',
      titleFa: 'ترکیب نقش‌های پیشرفته (۱۱ نفره)',
      subtitleEn: '11 players - Seer, Martyr, Hunter, Wolves x2, Cultist',
      subtitleFa: '۱۱ نفره - غیب‌گو، فداکار، شکارچی، گرگ×۲، فرقه‌گرا',
      bodyEn:
          'A Werewolf-flavored variant with several special roles. 11 '
          'players: Seer, Martyr, Hunter, 2 Wolves, a Cultist, and plain '
          'Villagers filling the rest.\n\n'
          'Seer: each night, learns whether one chosen player is a Wolf.\n'
          'Martyr: once per game, can sacrifice themselves to save '
          'another player who would have died that night.\n'
          'Hunter: if eliminated (by vote or by the Wolves), immediately '
          'takes one other player down with them.\n'
          'Wolves: each night, secretly agree on one player to eliminate.\n'
          'Cultist: wins alongside the Wolves but doesn\'t know who they '
          'are; usually learns of, or is recruited by, the Wolves during '
          'the game.\n\n'
          'Day: discussion followed by a majority-vote lynch, same as the '
          'other variants.\n\n'
          'Win conditions: the Village wins once both Wolves are '
          'eliminated. The Wolves (and the Cultist with them) win once '
          'they equal or outnumber the remaining Village.',
      bodyFa:
          'یک نسخه با حال‌وهوای گرگینه و چند نقش خاص. ۱۱ بازیکن: غیب‌گو، '
          'فداکار، شکارچی، ۲ گرگ، یک فرقه‌گرا، و بقیه شهروند ساده.\n\n'
          'غیب‌گو: هر شب می‌فهمد یک بازیکن انتخابی گرگ هست یا نه.\n'
          'فداکار: یک‌بار در کل بازی می‌تواند خودش را فدا کند تا کسی که '
          'قرار بود آن شب بمیرد نجات پیدا کند.\n'
          'شکارچی: اگر حذف بشه (با رأی یا توسط گرگ‌ها)، بلافاصله یک نفر '
          'دیگر را هم با خودش از بازی خارج می‌کند.\n'
          'گرگ‌ها: هر شب مخفیانه روی حذف یک بازیکن توافق می‌کنند.\n'
          'فرقه‌گرا: همراه گرگ‌ها می‌برد ولی نمی‌دونه اونا کی هستن؛ '
          'معمولاً در طول بازی گرگ‌ها رو می‌شناسه یا توسط اونا جذب '
          'می‌شه.\n\n'
          'روز: بحث و سپس اعدام با اکثریت رأی، مثل بقیه نسخه‌ها.\n\n'
          'شرط برد: روستا وقتی هر دو گرگ حذف بشن می‌بره. گرگ‌ها (همراه '
          'فرقه‌گرا) وقتی تعدادشان برابر یا بیشتر از روستاییان '
          'باقی‌مانده بشه می‌برند.',
    ),
    _RulebookInfo(
      titleEn: 'Town-Heavy Power Setup',
      titleFa: 'قدرت‌محور شهروندی',
      subtitleEn: '7 players - Villager x5, Cop, Doctor, Mafia x2',
      subtitleFa: '۷ نفره - شهروند×۵، کارآگاه، دکتر، مافیا×۲',
      bodyEn:
          'A Town-favored balance for smaller groups. 7 players: 5 plain '
          'Villagers, a Cop, a Doctor, and 2 Mafia.\n\n'
          'Mechanically identical to the Classic setup (Mafia pick a '
          'target each night, the Doctor can save one player, the Cop '
          'investigates one player), just with more plain Villagers '
          'relative to Mafia - giving the Town more room for a wrong '
          'lynch early on without immediately losing.\n\n'
          'Day: discussion followed by a majority-vote lynch.\n\n'
          'Win conditions: the Town wins once both Mafia are eliminated. '
          'The Mafia win once their numbers equal or outnumber the '
          'remaining Town.',
      bodyFa:
          'یک تعادل به‌نفع شهروندان برای گروه‌های کوچک‌تر. ۷ بازیکن: ۵ '
          'شهروند ساده، یک کارآگاه، یک دکتر، و ۲ مافیا.\n\n'
          'از نظر مکانیزم دقیقاً مثل نسخه کلاسیکه (مافیا هر شب هدف '
          'انتخاب می‌کنند، دکتر می‌تونه یک نفر رو سیو بده، کارآگاه یک '
          'نفر رو استعلام می‌کنه)، فقط شهروند ساده بیشتری نسبت به مافیا '
          'داره - یعنی شهروندان فضای بیشتری برای یک اعدام اشتباه در '
          'اوایل بازی دارند بدون اینکه فوری ببازند.\n\n'
          'روز: بحث و سپس اعدام با اکثریت رأی.\n\n'
          'شرط برد: شهروندان وقتی هر دو مافیا حذف بشن می‌برند. مافیا '
          'وقتی تعدادشان برابر یا بیشتر از شهروندان باقی‌مانده بشه '
          'می‌بره.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Padding(
            padding: EdgeInsets.only(top: 6),
            child: TrText('Choose Rulebook'),
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _RulebookCard(
                titleEn: 'Mafia Psychology Academy - Advanced',
                titleFa: 'مافیای پیشرفته آکادمی',
                subtitleEn: 'Every role built in this app, with the full '
                    'wake-order and no-shot rules - ready to play now.',
                subtitleFa: 'همه‌ی نقش‌های ساخته‌شده در این اپ، با ترتیب '
                    'کامل بیدارشدن و قانون ناتویی - همین الان آماده‌ی بازیه.',
                active: true,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoleSelectionScreen(
                        totalPlayers: totalPlayers,
                        mafiaCount: mafiaCount,
                        citizenCount: citizenCount,
                        independentCount: independentCount,
                        gameState: gameState,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textGold,
                    side: const BorderSide(color: AppColors.textGold, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CustomRulebookScreen()),
                    );
                  },
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Custom Rulebook'),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: TrText(
                  'More rulebooks (coming soon)',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
              for (final entry in _comingSoon)
                _RulebookCard(
                  titleEn: entry.titleEn,
                  titleFa: entry.titleFa,
                  subtitleEn: entry.subtitleEn,
                  subtitleFa: entry.subtitleFa,
                  active: false,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RulebookTextScreen(
                          titleEn: entry.titleEn,
                          titleFa: entry.titleFa,
                          bodyEn: entry.bodyEn,
                          bodyFa: entry.bodyFa,
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RulebookCard extends StatelessWidget {
  final String titleEn;
  final String titleFa;
  final String subtitleEn;
  final String subtitleFa;
  final bool active;
  final VoidCallback onTap;

  const _RulebookCard({
    required this.titleEn,
    required this.titleFa,
    required this.subtitleEn,
    required this.subtitleFa,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: active ? 1.0 : 0.55,
      child: NeonDotFrame(
        dotCount: 4,
        dotSize: 5,
        borderRadius: 14,
        child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TrText(
                        titleEn,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.yellowAccent,
                        ),
                      ),
                    ),
                    if (active)
                      const Icon(Icons.check_circle, color: AppColors.citizenTeam, size: 18)
                    else
                      const Icon(Icons.lock_clock, color: AppColors.textSecondary, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                TrText(subtitleEn, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _RulebookInfo {
  final String titleEn;
  final String titleFa;
  final String subtitleEn;
  final String subtitleFa;
  final String bodyEn;
  final String bodyFa;

  const _RulebookInfo({
    required this.titleEn,
    required this.titleFa,
    required this.subtitleEn,
    required this.subtitleFa,
    required this.bodyEn,
    required this.bodyFa,
  });
}
