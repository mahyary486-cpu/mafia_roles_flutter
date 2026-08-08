import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/banner_app_bar_background.dart';

/// A read-only reference page for one of the well-known Mafia/Werewolf
/// rule variants - not yet playable inside the app (only the app's own
/// rulebook is wired to the live game engine), just the rules text for
/// reference. Reachable from the rulebook selector screen.
class RulebookTextScreen extends StatelessWidget {
  final String titleEn;
  final String titleFa;
  final String bodyEn;
  final String bodyFa;

  const RulebookTextScreen({
    super.key,
    required this.titleEn,
    required this.titleFa,
    required this.bodyEn,
    required this.bodyFa,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const BannerAppBarBackground(),
        title: const Text('Game Master Assistant', style: TextStyle(fontSize: 15)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(titleEn, style: AppTextStyles.englishFlashy.copyWith(fontSize: 20)),
            Text(titleFa, style: AppTextStyles.persianGold.copyWith(fontSize: 15)),
            const SizedBox(height: 4),
            const Text(
              'Reference only - not yet playable inside the app. / '
              'فقط جهت مرجع - هنوز داخل اپ قابل‌بازی نیست.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontStyle: FontStyle.italic),
            ),
            const Divider(height: 24),
            Text(bodyEn, style: const TextStyle(color: AppColors.textSecondary, height: 1.6)),
            const SizedBox(height: 16),
            Text(bodyFa, style: const TextStyle(color: AppColors.textGold, height: 1.9)),
            const SizedBox(height: 20),
            const Text(
              'Compiled by Game Master Assistant / گردآوری‌شده از طرف Game Master Assistant',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
