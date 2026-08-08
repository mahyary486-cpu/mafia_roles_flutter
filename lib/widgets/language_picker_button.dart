import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logic/locale_service.dart';

/// The small globe button that opens a language picker. The Persian half
/// of every bilingual string is fixed and never changes - this only
/// swaps which language the English half is shown in (see
/// [LocaleService] for which phrases are translated so far).
class LanguagePickerButton extends StatelessWidget {
  const LanguagePickerButton({super.key});

  Future<void> _openPicker(BuildContext context) async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Language / زبان'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: LocaleService.supportedLanguages.entries
                .map(
                  (e) => ListTile(
                    title: Text(e.value),
                    trailing: ValueListenableBuilder<String>(
                      valueListenable: LocaleService.instance.languageCode,
                      builder: (context, current, _) =>
                          current == e.key ? const Icon(Icons.check, color: AppColors.accent) : const SizedBox.shrink(),
                    ),
                    onTap: () => Navigator.of(context).pop(e.key),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (chosen != null) {
      LocaleService.instance.setLanguage(chosen);
      if (chosen != 'en' && context.mounted) {
        final reachable = await LocaleService.instance.canReachTranslationService();
        if (!reachable && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Translation needs internet - some text may stay in '
                'English until you\'re back online. / '
                'برای ترجمه به اینترنت نیاز است - تا وصل نشوید بعضی '
                'متن‌ها انگلیسی می‌مانند.',
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Language / زبان',
      icon: const Icon(Icons.public, color: AppColors.textGold),
      onPressed: () => _openPicker(context),
    );
  }
}
