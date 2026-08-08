import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/role_data.dart';
import '../models/role.dart';
import '../models/role_action_type.dart';
import '../models/role_type.dart';
import '../models/team.dart';

/// A curated bank of emojis relevant to social-deduction game roles, for
/// picking a role's icon without needing to hunt for or paste one.
/// Covers killing/protection/investigation/disable/manipulation/win-type
/// abilities, so there's a sensible option for nearly any custom role.
const List<String> kRoleEmojiBank = [
  '🔪', '🔫', '🗡️', '🐺', '💣', '☠️', '🩸', // killing
  '🛡️', '🩺', '❤️‍🩹', '👼', '🏠', '🧿', // protection
  '🔍', '👁️', '🕵️', '🔮', '📷', '📋', '🧠', // investigation
  '⛓️', '🤐', '🍸', '🚔', '🗝️', // disable
  '🔀', '🖐️', '🎭', '🧙‍♀️', '🧪', '🧟', '🪄', // manipulation
  '🤡', '⚖️', '🏴‍☠️', '🏆', '👑', // win condition
  '👤', '👥', '🥷', '🎩', '🃏', '💂', '🪖', '🎖️', '💪', '🤠', '✨', '💥', '🤝', '✝️',
];

/// Shows a form where the game master types a name + description for a
/// one-off custom role, picks which side it belongs to, whether it acts
/// during the Day or the Night, which of the six broad ability patterns
/// it follows, and (optionally) where its icon should sit in the
/// toolbar relative to an existing role. Returns the finished [Role], or
/// null if cancelled.
///
/// Kept compact on purpose: the name/description/emoji fields (the part
/// that matters every single time) stay right at the top with no
/// scrolling needed to reach them; the classification controls below are
/// packed tightly so the whole form fits on one screen.
Future<Role?> showCustomRoleDialog(BuildContext context) {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final emojiController = TextEditingController(text: '🎭');
  Team selectedTeam = Team.citizen;
  RoleActionTiming selectedTiming = RoleActionTiming.night;
  RoleActionCategory selectedCategory = RoleActionCategory.killing;
  RoleType? insertAfter;

  final toolbarRoleOptions = RoleData.all.values
      .where((r) => r.type != RoleType.citizen && r.type != RoleType.mafia)
      .toList()
    ..sort((a, b) => a.name.compareTo(b.name));

  return showDialog<Role>(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            title: const _BilingualLabel(en: 'Custom Role', fa: 'نقش سفارشی', fontSize: 16),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Role name / اسم نقش',
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Ability / توضیح توانایی',
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: TextField(
                          controller: emojiController,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 20),
                          decoration: const InputDecoration(isDense: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: kRoleEmojiBank.map((e) {
                              final selected = emojiController.text == e;
                              return GestureDetector(
                                onTap: () => setState(() => emojiController.text = e),
                                child: Container(
                                  width: 32,
                                  margin: const EdgeInsets.only(right: 4),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? AppColors.accent.withOpacity(0.25)
                                        : Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                    border: selected
                                        ? Border.all(color: AppColors.accent)
                                        : null,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(e, style: const TextStyle(fontSize: 16)),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const _CompactLabel(en: 'Side', fa: 'تیم'),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<Team>(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: const [
                        ButtonSegment(value: Team.citizen, label: Text('Citizen', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: Team.mafia, label: Text('Mafia', style: TextStyle(fontSize: 11))),
                        ButtonSegment(value: Team.independent, label: Text('Independent', style: TextStyle(fontSize: 11))),
                      ],
                      selected: {selectedTeam},
                      onSelectionChanged: (s) => setState(() => selectedTeam = s.first),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _CompactLabel(en: 'Acts by Day / Night', fa: 'اکت روز / شب'),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<RoleActionTiming>(
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      segments: const [
                        ButtonSegment(
                          value: RoleActionTiming.day,
                          label: Text('Day / روز', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.wb_sunny_rounded, size: 15),
                        ),
                        ButtonSegment(
                          value: RoleActionTiming.night,
                          label: Text('Night / شب', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.nightlight_round, size: 15),
                        ),
                      ],
                      selected: {selectedTiming},
                      onSelectionChanged: (s) => setState(() => selectedTiming = s.first),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const _CompactLabel(en: 'Ability type', fa: 'نوع توانایی'),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: RoleActionCategory.values.map((category) {
                      final selected = selectedCategory == category;
                      return ChoiceChip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        selected: selected,
                        onSelected: (_) => setState(() => selectedCategory = category),
                        avatar: Text(category.emoji, style: const TextStyle(fontSize: 11)),
                        label: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.nameEn, style: const TextStyle(fontSize: 9)),
                            Text(
                              category.nameFa,
                              style: const TextStyle(fontSize: 8, color: AppColors.textGold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 10),
                  const _CompactLabel(
                    en: 'Toolbar position (optional)',
                    fa: 'جای آیکون در نوار ابزار (اختیاری)',
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: DropdownButtonFormField<RoleType?>(
                      isDense: true,
                      style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                      decoration: const InputDecoration(isDense: true),
                      value: insertAfter,
                      hint: const Text('End of list / انتهای لیست', style: TextStyle(fontSize: 11)),
                      items: [
                        const DropdownMenuItem<RoleType?>(
                          value: null,
                          child: Text('End of list / انتهای لیست', style: TextStyle(fontSize: 11)),
                        ),
                        for (final role in toolbarRoleOptions)
                          DropdownMenuItem<RoleType?>(
                            value: role.type,
                            child: Text(
                              'After ${role.name} / بعد از ${role.nameFa}',
                              style: const TextStyle(fontSize: 11),
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(() => insertAfter = value),
                    ),
                  ),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            actions: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel / انصراف', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        final name = nameController.text.trim();
                        final description = descriptionController.text.trim();
                        if (name.isEmpty) return;

                        final color = switch (selectedTeam) {
                          Team.mafia => AppColors.mafiaTeam,
                          Team.citizen => AppColors.citizenTeam,
                          Team.independent => AppColors.independentTeam,
                        };

                        Navigator.of(context).pop(
                          Role(
                            type: RoleType.custom,
                            customId: 'custom_${DateTime.now().microsecondsSinceEpoch}',
                            team: selectedTeam,
                            name: name,
                            description: description.isEmpty ? '—' : description,
                            nameFa: name,
                            descriptionFa: description.isEmpty ? '—' : description,
                            iconAsset: 'assets/icons/custom.svg',
                            color: color,
                            emoji: emojiController.text.trim().isEmpty
                                ? '🎭'
                                : emojiController.text.trim(),
                            actionTiming: selectedTiming,
                            actionCategory: selectedCategory,
                            insertAfterRoleType: insertAfter,
                          ),
                        );
                      },
                      child: const Text('Add / افزودن', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    },
  );
}

/// English on top (bigger), Persian underneath (smaller) - the app-wide
/// bilingual label convention, prioritizing the English-speaking reader.
class _BilingualLabel extends StatelessWidget {
  final String en;
  final String fa;
  final Color? color;
  final FontWeight weight;
  final double fontSize;

  const _BilingualLabel({
    required this.en,
    required this.fa,
    this.color,
    this.weight = FontWeight.bold,
    this.fontSize = 17,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(en, style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color)),
        Text(
          fa,
          style: TextStyle(fontSize: fontSize - 5, color: color ?? AppColors.textGold),
        ),
      ],
    );
  }
}

/// A single-line "English / فارسی" label, for compact section headers
/// where there isn't room for two stacked lines.
class _CompactLabel extends StatelessWidget {
  final String en;
  final String fa;

  const _CompactLabel({required this.en, required this.fa});

  @override
  Widget build(BuildContext context) {
    return Text(
      '$en / $fa',
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
      ),
    );
  }
}
