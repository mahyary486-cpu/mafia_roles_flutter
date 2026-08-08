import 'package:flutter/material.dart';

/// A compact, horizontally-scrollable row of small emoji badges shown
/// next to a player - one per role whose action has touched them this
/// round, in the order they were applied. Scrollable because more than
/// one action can land on the same player in a single round.
class ActionMarksRow extends StatelessWidget {
  final List<String> emojis;
  final Color color;

  const ActionMarksRow({super.key, required this.emojis, this.color = Colors.deepOrange});

  @override
  Widget build(BuildContext context) {
    if (emojis.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 22,
      child: ListView(
        scrollDirection: Axis.horizontal,
        shrinkWrap: true,
        children: emojis
            .map(
              (emoji) => Container(
                margin: const EdgeInsets.only(right: 4, top: 2),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color.withOpacity(0.6)),
                ),
                alignment: Alignment.center,
                child: Text(emoji, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
      ),
    );
  }
}
