import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logic/role_overrides_store.dart';
import '../models/role.dart';

/// Lets the game master rename/re-describe a built-in role. The role's
/// mechanic, team, and icon never change - only the text shown for it.
/// Returns true if something was saved (so the caller can refresh).
Future<bool> showEditRoleDialog(BuildContext context, Role role) async {
  final nameController = TextEditingController(text: role.name);
  final nameFaController = TextEditingController(text: role.nameFa);
  final descController = TextEditingController(text: role.description);
  final descFaController = TextEditingController(text: role.descriptionFa);
  final emojiController = TextEditingController(text: role.emoji);

  final saved = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Edit Role / ویرایش نقش'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name (English)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: nameFaController,
                decoration: const InputDecoration(labelText: 'اسم (فارسی)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descController,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'Ability (English)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descFaController,
                maxLines: 3,
                decoration:
                    const InputDecoration(labelText: 'توانایی (فارسی)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: emojiController,
                decoration: const InputDecoration(
                  labelText: 'Emoji (paste one) / ایموجی (پیست کنید)',
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () async {
                  await RoleOverridesStore.clearOverride(role.type.name);
                  if (context.mounted) Navigator.of(context).pop(true);
                },
                icon: const Icon(Icons.restore, size: 18),
                label: const Text('Reset to default / بازگشت به پیش‌فرض'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel / انصراف'),
          ),
          ElevatedButton(
            onPressed: () async {
              await RoleOverridesStore.setOverride(
                role.type.name,
                name: nameController.text.trim().isEmpty
                    ? role.name
                    : nameController.text.trim(),
                nameFa: nameFaController.text.trim().isEmpty
                    ? role.nameFa
                    : nameFaController.text.trim(),
                description: descController.text.trim().isEmpty
                    ? role.description
                    : descController.text.trim(),
                descriptionFa: descFaController.text.trim().isEmpty
                    ? role.descriptionFa
                    : descFaController.text.trim(),
                emoji: emojiController.text.trim().isEmpty
                    ? role.emoji
                    : emojiController.text.trim(),
              );
              if (context.mounted) Navigator.of(context).pop(true);
            },
            child: const Text('Save / ذخیره'),
          ),
        ],
      );
    },
  );

  return saved ?? false;
}
