import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/tr_text.dart';

/// Explains how to *use the app itself* (picking a player count, setting
/// mafia/citizen/independent numbers, choosing roles, reading the reveal
/// cards, using the roster) - as opposed to the Rulebook screen, which
/// covers Mafia *game* rules.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: const BannerAppBarBackground(),
          title: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Help'), Text(' / راهنما')]),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _HelpStep(
                stepEn: '1. Choose the number of players',
                stepFa: '۱. تعداد بازیکنان را انتخاب کنید',
                bodyEn:
                    'On the first screen, tap a number (3-12), or tap '
                    '"More Players" to type any number up to 100.',
                bodyFa:
                    'در صفحه‌ی اول، روی یک عدد (۳ تا ۱۲) بزنید، یا روی '
                    '"More Players" بزنید تا هر عددی تا ۱۰۰ تایپ کنید.',
              ),
              _HelpStep(
                stepEn: '2. Set team sizes',
                stepFa: '۲. تعداد تیم‌ها را تنظیم کنید',
                bodyEn:
                    'Type or adjust how many players are mafia, and '
                    'optionally how many are independent. Citizens are '
                    'whatever is left - the app just warns if citizens '
                    "don't outnumber mafia, it doesn't force anything.",
                bodyFa:
                    'تعداد مافیا را تایپ یا با +/- تنظیم کنید، و در صورت '
                    'تمایل تعداد نقش مستقل را هم مشخص کنید. شهروندان همون '
                    'باقی‌مانده‌ست - اپ فقط هشدار می‌ده اگه شهروندها بیشتر '
                    'از مافیا نباشن، چیزی رو اجبار نمی‌کنه.',
              ),
              _HelpStep(
                stepEn: '3. Pick which named roles are in play',
                stepFa: '۳. نقش‌های موردنظر را انتخاب کنید',
                bodyEn:
                    'Tick the roles you want for each side, up to the '
                    'number of slots shown. Anything left unticked is '
                    'filled automatically with plain Citizens/Mafia. You '
                    'can also write your own custom role - it gets saved '
                    'on this device for future games too.',
                bodyFa:
                    'نقش‌هایی که می‌خواید رو برای هر تیم تیک بزنید، تا '
                    'سقف تعدادی که نشون داده می‌شه. هرچی تیک نخوره، خودکار '
                    'با شهروند/مافیای ساده پر می‌شه. می‌تونید نقش سفارشی '
                    'خودتون رو هم بنویسید - روی همین گوشی ذخیره می‌شه و '
                    'برای بازی‌های بعدی هم می‌مونه.',
              ),
              _HelpStep(
                stepEn: '4. Reveal cards, one player at a time',
                stepFa: '۴. کارت‌ها را یکی‌یکی نشان دهید',
                bodyEn:
                    'Hand the phone to each player in turn. They tap the '
                    'closed card to reveal their role, then you tap Next. '
                    'You can go back with Previous if needed.',
                bodyFa:
                    'گوشی رو به هر بازیکن به‌نوبت بدید. اون کارت بسته رو '
                    'تاچ می‌کنه تا نقشش رو ببینه، بعد شما Next رو بزنید. '
                    'در صورت نیاز با Previous می‌تونید برگردید.',
              ),
              _HelpStep(
                stepEn: '5. Use the Full Roster during the game',
                stepFa: '۵. از لیست کامل بازیکنان استفاده کنید',
                bodyEn:
                    'The list icon (top right, during reveal) opens a '
                    'spoiler view of every player and role at once. Mark '
                    'players as removed as the game goes on, and use "End '
                    'Night" to move to the next night.',
                bodyFa:
                    'آیکون لیست (بالا راست، حین نشون‌دادن کارت‌ها) یه '
                    'نمای کامل از همه‌ی بازیکنان و نقش‌ها رو باز می‌کنه. '
                    'بازیکن‌های حذف‌شده رو علامت بزنید و با "End Night" به '
                    'شب بعد برید.',
              ),
              _HelpStep(
                stepEn: '6. Rulebook vs. Help',
                stepFa: '۶. رول‌بوک در برابر راهنما',
                bodyEn:
                    'The ⚡ icon on the first screen is the Rulebook - full '
                    'Mafia game rules and every role\'s ability. This Help '
                    'screen is just about using the app itself.',
                bodyFa:
                    'آیکون ⚡ توی صفحه‌ی اول، رول‌بوکه - قوانین کامل بازی '
                    'مافیا و توانایی هر نقش. این صفحه‌ی راهنما فقط درباره‌ی '
                    'نحوه‌ی استفاده از خود اپه.',
              ),
              _HelpStep(
                stepEn: '7. The 🌙 Night Actions board',
                stepFa: '۷. صفحه‌ی 🌙 اعمال شب',
                bodyEn:
                    'From the Full Roster, the moon icon opens a board of '
                    'role icons for this game. Tap a role to arm it, then '
                    'tap a player to apply its effect - their name lights '
                    'up in a color (shot/saved/silenced/blocked/other). '
                    'When done, "Night Results" shows a summary and moves '
                    'shot players to the removed list.',
                bodyFa:
                    'از لیست کامل بازیکنان، آیکون ماه یه صفحه از آیکون '
                    'نقش‌های همین بازی رو باز می‌کنه. یه آیکون رو تاچ کنید '
                    'تا مسلح بشه، بعد روی یه بازیکن تاچ کنید تا اثرش اعمال '
                    'بشه - اسمش با یه رنگ روشن می‌شه (شات/سیو/سکوت/بسته/سایر). '
                    'در پایان، «Night Results» خلاصه‌شو نشون می‌ده و شات‌خورده‌ها '
                    'رو به لیست حذف‌شده‌ها می‌بره.',
              ),
              _HelpStep(
                stepEn: '8. Editing emoji, names, and abilities',
                stepFa: '۸. ویرایش ایموجی، اسم، و توانایی',
                bodyEn:
                    'Every role has a small emoji next to it in lists. Tap '
                    'the pencil icon next to any built-in role (in role '
                    'selection) to rename it, rewrite its ability text, or '
                    'paste in a different emoji. "Reset to default" undoes '
                    'just that one role.',
                bodyFa:
                    'هر نقش توی لیست‌ها یه ایموجی کوچیک کنارش داره. روی '
                    'آیکون مداد کنار هر نقش پیش‌فرض (توی صفحه‌ی انتخاب نقش) '
                    'بزنید تا اسمش، متن توانایی‌ش، یا ایموجی‌ش رو عوض کنید. '
                    '«بازگشت به پیش‌فرض» فقط همون یه نقش رو ریست می‌کنه.',
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TrText(
                      'About the free version',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const Text('درباره‌ی نسخه‌ی رایگان', style: TextStyle(color: AppColors.textGold, fontSize: 12)),
                    const SizedBox(height: 6),
                    const TrText(
                      'Free for games up to 7 players. An ad appears every 3 games. '
                      'Pro removes the player limit; a monthly plan with ads is planned '
                      'alongside an ad-free monthly plan.',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'تا ۷ نفر رایگانه. هر ۳ بازی یک تبلیغ نشان داده می‌شود. نسخه‌ی '
                      'پرو محدودیت تعداد بازیکن را برمی‌دارد؛ یک اشتراک ماهانه با '
                      'تبلیغ و یک اشتراک ماهانه بدون تبلیغ در نظر گرفته شده است.',
                      style: TextStyle(color: AppColors.textGold, fontSize: 11, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const TrText('Mafia Psychology Academy', style: AppTextStyles.englishFlashy, textAlign: TextAlign.center),
                    const Text('آکادمی روان‌شناسی مافیا', style: AppTextStyles.persianGold, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Image.asset('assets/images/mask_logo.png', width: 20, height: 20),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Developer',
                                style: AppTextStyles.englishFlashy,
                                textAlign: TextAlign.center,
                              ),
                              const Text(
                                'Mahyar Yaghoobalipour',
                                style: AppTextStyles.englishFlashy,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'توسعه‌دهنده و بنیان‌گذار: مهیار یعقوبعلی‌پور',
                                style: AppTextStyles.persianGold,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Image.asset('assets/images/mask_logo.png', width: 20, height: 20),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'mahyary021@gmail.com',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String stepEn;
  final String stepFa;
  final String bodyEn;
  final String bodyFa;

  const _HelpStep({
    required this.stepEn,
    required this.stepFa,
    required this.bodyEn,
    required this.bodyFa,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TrText(stepEn, style: AppTextStyles.englishFlashy.copyWith(fontSize: 16)),
          Text(stepFa, style: AppTextStyles.persianGold.copyWith(fontSize: 13)),
          const SizedBox(height: 6),
          TrText(bodyEn, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            bodyFa,
            style: const TextStyle(color: AppColors.textGold, fontSize: 12, height: 1.6),
          ),
        ],
      ),
    );
  }
}
