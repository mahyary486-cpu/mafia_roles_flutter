import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';
import '../models/role.dart';
import 'neon_dot_frame.dart';

/// A single card that starts closed and reveals a role on tap.
///
/// Give this widget a fresh [Key] (e.g. `ValueKey(playerNumber)`) whenever
/// the player changes, so it always starts closed again for the new
/// player without any manual reset logic.
class RoleRevealCard extends StatefulWidget {
  final Role role;

  const RoleRevealCard({super.key, required this.role});

  @override
  State<RoleRevealCard> createState() => _RoleRevealCardState();
}

class _RoleRevealCardState extends State<RoleRevealCard> {
  bool _revealed = false;

  void _reveal() {
    if (!_revealed) {
      setState(() => _revealed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _reveal,
      child: NeonDotFrame(
        dotCount: 5,
        dotSize: 4.5,
        borderRadius: 20,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 350),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: RotationTransition(
                turns: Tween<double>(begin: 0.75, end: 1).animate(animation),
                child: ScaleTransition(scale: animation, child: child),
              ),
            );
          },
          child: _revealed
              ? _RevealedFace(key: const ValueKey('revealed'), role: widget.role)
              : const _ClosedFace(key: ValueKey('closed')),
        ),
      ),
    );
  }
}

class _ClosedFace extends StatelessWidget {
  const _ClosedFace({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      height: 300,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/background_galaxy.jpg',
            fit: BoxFit.cover,
          ),
          Positioned.fill(
            child: Container(color: Colors.black.withOpacity(0.15)),
          ),
          Padding(
            padding: const EdgeInsets.all(48),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _RevealedFace extends StatelessWidget {
  final Role role;

  const _RevealedFace({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      constraints: const BoxConstraints(minHeight: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: role.color.withOpacity(0.6), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: SvgPicture.asset(
              role.iconAsset,
              colorFilter: ColorFilter.mode(role.color, BlendMode.srcIn),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            role.name,
            textAlign: TextAlign.center,
            style: AppTextStyles.englishFlashy.copyWith(fontSize: 22),
          ),
          const SizedBox(height: 4),
          Text(
            role.nameFa,
            textAlign: TextAlign.center,
            style: AppTextStyles.persianGold.copyWith(fontSize: 17),
          ),
          const SizedBox(height: 12),
          Text(
            role.displayShortDescription,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            role.displayShortDescriptionFa,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
