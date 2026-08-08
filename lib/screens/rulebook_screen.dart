import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../constants/role_data.dart';
import '../models/role.dart';
import '../models/team.dart';
import '../widgets/app_background.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/neon_dot_frame.dart';
import '../widgets/tr_text.dart';

/// Full bilingual rulebook: every built-in role's name and ability in both
/// English and Persian, the general mafia "no-shot" rule, and a credit
/// block for the academy and developer.
class RulebookScreen extends StatelessWidget {
  const RulebookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mafiaRoles = RoleData.forTeam(Team.mafia);
    final citizenRoles = RoleData.forTeam(Team.citizen);
    final independentRoles = RoleData.forTeam(Team.independent);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: const BannerAppBarBackground(),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [TrText('Rulebook'), Text(' / رول‌بوک')],
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SectionHeader(titleFa: 'مافیا', titleEn: 'Mafia', color: AppColors.mafiaTeam),
              for (final role in mafiaRoles) _RoleRuleTile(role: role),
              const SizedBox(height: 20),
              _SectionHeader(
                  titleFa: 'شهروند', titleEn: 'Citizen', color: AppColors.citizenTeam),
              for (final role in citizenRoles) _RoleRuleTile(role: role),
              if (independentRoles.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SectionHeader(
                  titleFa: 'مستقل',
                  titleEn: 'Independent',
                  color: AppColors.independentTeam,
                ),
                for (final role in independentRoles) _RoleRuleTile(role: role),
              ],
              const SizedBox(height: 24),
              _RuleBlock(
                titleEn: 'General Rule — "No-Shot" / Slaughter',
                titleFa: 'قانون کلی — «ناتویی» / سلاخی',
                bodyEn:
                    "Once per game, the mafia's shooter may guess a "
                    'target\'s role and, instead of a normal shot, declare '
                    '"ناتویی" (unable to identify the role) - this even '
                    "works against Nostradamus. The target is eliminated "
                    'outright ("slaughtered"), ignoring their role, the '
                    "Doctor's save, and any shield entirely.",
                bodyFa:
                    'مافیای شات‌زننده در کل بازی یک‌بار می‌تواند با حدس نقش '
                    'یک بازیکن، به‌جای شات معمولی، «ناتویی» (ناتوانی در '
                    'تشخیص نقش) اعلام کند - این حتی روی نوستراداموس هم اثر '
                    'می‌کند. فرد بدون در نظر گرفتن نقش، سیو دکتر، یا هر '
                    'شیلدی، به‌صورت اصطلاحاً «سلاخی» از بازی خارج می‌شود.',
              ),
              const SizedBox(height: 12),
              _RuleBlock(
                titleEn: 'Day One — Blind Round',
                titleFa: 'روز اول — دور بلایند',
                bodyEn:
                    'In games of 12 players or fewer, day one is a "blind" '
                    "introduction round: players don't yet recognize each "
                    "other's behavior. The Cowboy and Terrorist have no "
                    'action on day one.',
                bodyFa:
                    'در تعداد 12 نفر و پایین‌تر، روز اول یک دور «بلایند» و '
                    'معارفه است؛ بازیکن‌ها هنوز همدیگر را نمی‌شناسند. کابوی و '
                    'تروریست در روز اول اکت (اقدام) ندارند.',
              ),
              const SizedBox(height: 12),
              _RuleBlock(
                titleEn: 'Wake Order at Night',
                titleFa: 'ترتیب بیدار کردن نقش‌ها در شب',
                bodyEn:
                    'If present in the game, roles wake in this order:\n\n'
                    '1. Bartender - alone, before anyone else, since his '
                    'ability can block any player, even a mafia member.\n'
                    '2. Thief - alone.\n'
                    '3. The rest of the mafia group (everyone except the '
                    'Thief) - they see the Thief\'s "like", but the Thief '
                    'does not wake with them.\n'
                    '4. Citizen-team named roles.',
                bodyFa:
                    'اگر در بازی حضور داشته باشند، نقش‌ها به این ترتیب بیدار '
                    'می‌شوند:\n\n'
                    '1. ساقی - تنها، زودتر از همه، چون توانایی‌اش می‌تواند '
                    'روی هر بازیکنی، حتی یک مافیا، اعمال شود.\n'
                    '2. دزد - به‌تنهایی.\n'
                    '3. باقی گروه مافیا (به‌جز دزد) - آن‌ها لایک دزد را '
                    'می‌بینند، اما دزد با آن‌ها بیدار نمی‌شود.\n'
                    '4. شهروندان نقش‌دار.',
              ),
              const SizedBox(height: 12),
              _RuleBlock(
                titleEn: 'Thief — Stealing a Day-Action Role',
                titleFa: 'دزد — سرقت نقش‌های دارای اکشن روز',
                bodyEn:
                    'If, at night, the Thief steals a role that acts during '
                    'the day (Terrorist, Cowboy, Bomber, or any similar '
                    'role), then starting the next day the Thief fully '
                    'owns that role\'s ability - the Thief\'s icon appears '
                    'next to the stolen role on the Day screen so the game '
                    'master always knows what the Thief is holding. The '
                    "original holder is completely deactivated for that "
                    "role: their day-action icon is gone, none of that "
                    "role's buttons work for them, and they can take no "
                    "day or night action tied to their old role - as far "
                    "as the game's logic is concerned, only the Thief is "
                    "recognized as that role's current holder, and the "
                    "system accepts no action from the original owner. If "
                    "the stolen role is eliminated from the game once its "
                    "action fires (like Terrorist or Cowboy), the Thief is "
                    "eliminated the same way, right after that action "
                    "fires. The original holder, having lost the ability, "
                    "is treated from then on as an ordinary Citizen or "
                    "plain Mafia member for any other purpose.\n\n"
                    'Terrorist specifically: the Terrorist (or the Thief, '
                    'if it was stolen) has no action of their own choosing '
                    "- their icon on the Day screen stays locked/inactive "
                    "until they are actually facing the vote majority (\"In "
                    'Defense\", shown in red). The instant they reach that '
                    "state, their icon unlocks and turns active, and every "
                    "player's Kick button opens up for the game master. "
                    "Whichever player the game master then taps is "
                    "eliminated together with whoever currently holds the "
                    "Terrorist's ability - the Thief, if the ability was "
                    "stolen, rather than the original Terrorist.\n\n"
                    'Reminder shown to the game master once the Terrorist '
                    'enters Defense: "If the Terrorist gets the exit vote, '
                    'once In Defense he can eliminate one player from the '
                    'roster."',
                bodyFa:
                    'اگر دزد در شب، نقش تروریست، کابوی، بمبر یا هر نقش '
                    'مشابهی که در روز اکت دارد را سرقت کند، از ابتدای روز '
                    'بعد، دزد به‌طور کامل صاحب آن توانایی می‌شود - آیکون '
                    'دزد در صفحه‌ی روز کنار نقش دزدیده‌شده نمایش داده '
                    'می‌شود تا گرداننده همیشه بداند دزد چه چیزی در اختیار '
                    'دارد. صاحب اصلی نقش کاملاً غیرفعال می‌شود: آیکون '
                    'اکشن روز او دیگر دیده نمی‌شود، هیچ‌کدام از دکمه‌های '
                    'آن نقش برایش کار نمی‌کند، و او نمی‌تواند هیچ اکشن '
                    'روز یا شب مرتبط با نقش قبلی‌اش را انجام دهد - از '
                    'دید منطق بازی، فقط دزد به‌عنوان دارنده‌ی فعلی آن '
                    'نقش شناخته می‌شود و سیستم هیچ اکشنی از صاحب اصلی '
                    'نمی‌پذیرد. اگر نقش دزدیده‌شده پس از اجرای اکشنش از '
                    'بازی خارج شود (مثل تروریست یا کابوی)، دزد هم بلافاصله '
                    'پس از اجرای همان اکشن از بازی خارج می‌شود. صاحب اصلی '
                    'نقش، پس از از دست دادن توانایی، برای هر منظور دیگری '
                    'مثل یک شهروند یا مافیای ساده در نظر گرفته می‌شود.\n\n'
                    'به‌طور خاص درباره‌ی تروریست: تروریست (یا دزد، اگر '
                    'توانایی‌اش دزدیده شده باشد) به‌خودی‌خود اکشنی ندارد - '
                    'آیکونش در صفحه‌ی روز قفل/غیرفعال می‌ماند تا زمانی که '
                    'واقعاً وارد رأی‌گیری اکثریت («در دفاعیه»، به رنگ قرمز) '
                    'شود. همان لحظه که به این حالت برسد، آیکونش باز و فعال '
                    'می‌شود و دکمه‌ی «کیک» همه‌ی بازیکنان برای گرداننده باز '
                    'می‌شود. هر بازیکنی که گرداننده در این حالت لمس کند، '
                    'همراه با دارنده‌ی فعلی توانایی تروریست از بازی خارج '
                    'می‌شود - یعنی دزد، اگر توانایی دزدیده شده باشد، نه '
                    'خود تروریست اصلی.\n\n'
                    'پیامی که به محض ورود تروریست به دفاعیه به گرداننده '
                    'نشان داده می‌شود: «تروریست اگر رأی خروج بیاورد، بعد از '
                    'دفاعیه می‌تواند یک نفر را از لیست پلیرها حذف کند.»',
              ),
              const SizedBox(height: 12),
              _RuleBlock(
                titleEn: 'Advanced Mafia (15+ players)',
                titleFa: 'مافیای پیشرفته (15 نفر به بالا)',
                bodyEn:
                    'Games with 15 or more players follow the "Advanced '
                    'Mafia" ruleset - richer role combinations and more '
                    'night-action interactions. Typical additions: '
                    'Invincible, Strongman, Psycho, Commander, and the '
                    "Sniper's larger bullet count (see their own entries "
                    'above for details).',
                bodyFa:
                    'قوانین بازی‌های 15 نفر به بالا بر اساس «مافیای پیشرفته» '
                    'است - ترکیب نقش‌های بیشتر و تعامل پیچیده‌تر بین '
                    'توانایی‌ها. نقش‌های رایج اضافه‌شده: رویین‌تن، مرد قوی، '
                    'روانی، فرمانده، و افزایش تعداد گلوله‌های اسنایپر (برای '
                    'جزئیات، توضیح خود آن نقش‌ها را در بالا ببینید).',
              ),
              const SizedBox(height: 12),
              _RuleBlock(
                titleEn: 'Win Conditions',
                titleFa: 'شرط‌های برد',
                bodyEn:
                    'Citizen side wins: every player on the "black side" '
                    '(Mafia and Independent) is eliminated.\n\n'
                    'Mafia side wins: the number of players left equals '
                    'the number of Citizens left, and no Independent is '
                    'left in the game.\n\n'
                    'Independent side wins: an Independent is present in '
                    'the game, and the number of Citizens left equals the '
                    'number of Mafia left.',
                bodyFa:
                    'شرط برد ساید شهروند: همه‌ی ساید سیاه (مافیا و مستقل) '
                    'از بازی خارج شده باشند.\n\n'
                    'شرط برد ساید مافیا: تعداد پلیرهای باقی‌مانده برابر با '
                    'تعداد شهروندان باقی‌مانده باشد و مستقلی در بازی نمانده '
                    'باشد.\n\n'
                    'شرط برد ساید مستقل: مستقلی در بازی حضور داشته باشد و '
                    'تعداد شهروندان باقی‌مانده با تعداد مافیای باقی‌مانده '
                    'برابر باشد.',
              ),
              const SizedBox(height: 32),
              const _CreditBlock(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuleBlock extends StatelessWidget {
  final String titleEn;
  final String titleFa;
  final String bodyEn;
  final String bodyFa;

  const _RuleBlock({
    required this.titleEn,
    required this.titleFa,
    required this.bodyEn,
    required this.bodyFa,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.textGold.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TrText(titleEn, style: AppTextStyles.englishFlashy, textAlign: TextAlign.center),
          Text(titleFa, style: AppTextStyles.persianGold, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          TrText(
            bodyEn,
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            bodyFa,
            style: const TextStyle(color: AppColors.textGold, height: 1.7),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titleFa;
  final String titleEn;
  final Color color;

  const _SectionHeader({required this.titleFa, required this.titleEn, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$titleFa / ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
          TrText(
            titleEn,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }
}

class _RoleRuleTile extends StatelessWidget {
  final Role role;

  const _RoleRuleTile({required this.role});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrText(role.name, style: AppTextStyles.englishFlashy.copyWith(fontSize: 15)),
          Text(role.nameFa, style: AppTextStyles.persianGold.copyWith(fontSize: 14)),
          const SizedBox(height: 4),
          TrText(
            role.description,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 2),
          Text(
            role.descriptionFa,
            style: const TextStyle(
              color: AppColors.textGold,
              fontSize: 12,
              height: 1.6,
            ),
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _CreditBlock extends StatelessWidget {
  const _CreditBlock();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const TwinklingStarRow(),
          const SizedBox(height: 10),
          const TrText(
            'Mafia Psychology Academy',
            style: AppTextStyles.englishFlashy,
            textAlign: TextAlign.center,
          ),
          const Text(
            'آکادمی روان‌شناسی مافیا',
            style: AppTextStyles.persianGold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const TrText(
            'Developer: Mahyar Yaghoobalipour',
            style: AppTextStyles.englishFlashy,
            textAlign: TextAlign.center,
          ),
          const Text(
            'توسعه‌دهنده و بنیان‌گذار آکادمی روان‌شناسی مافیا: مهیار یعقوبعلی‌پور',
            style: AppTextStyles.persianGold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'mahyary021@gmail.com',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const TwinklingStarRow(),
        ],
      ),
    );
  }
}
