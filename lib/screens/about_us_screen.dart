import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../widgets/app_background.dart';
import '../widgets/tr_text.dart';

/// "About Us" - what the app does, its key features, and how to reach
/// the developer.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const _features = [
    'Designed specifically for Mafia game moderators.',
    'Free version supports up to 7 players.',
    'Premium subscription unlocks all features.',
    'Fast, intuitive, and easy-to-use interface.',
    'Regular updates with new features, improvements, and bug fixes.',
    'Designed to provide a smooth and reliable game management experience.',
  ];

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [TrText('About Us')],
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Center(
                child: Image.asset(
                  'assets/images/mask_logo.png',
                  width: 96,
                  height: 96,
                ),
              ),
              const SizedBox(height: 20),
              const TrText(
                'About the App',
                style: AppTextStyles.englishFlashy,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const TrText(
                'Mafia Game Assistant is a mobile application designed to '
                'help Mafia game moderators manage game sessions more '
                'efficiently. It provides practical tools for organizing '
                'roles, controlling game flow, and simplifying the '
                'moderation process.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const TrText(
                'Key Features',
                style: AppTextStyles.englishFlashy,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              for (final feature in _features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: TrText(
                    feature,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
              const TrText(
                'We are committed to continuously improving the '
                'application based on user feedback and introducing new '
                'features in future updates.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const TrText(
                'Thank you for choosing Mafia Game Assistant.',
                style: TextStyle(
                  color: AppColors.textGold,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              const TrText(
                'Contact Us',
                style: AppTextStyles.englishFlashy,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const _ContactRow(
                icon: Icons.play_circle_outline,
                text: 'youtube.com/@Game-Master-Assistant',
              ),
              const _ContactRow(
                icon: Icons.camera_alt_outlined,
                text: 'instagram.com/game_master_assistant',
              ),
              const _ContactRow(
                icon: Icons.email_outlined,
                text: 'mahyaryaghoobalipour@gmail.com',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textGold, size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: SelectableText(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
