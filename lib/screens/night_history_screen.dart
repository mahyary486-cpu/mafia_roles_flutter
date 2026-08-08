import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../logic/game_state.dart';
import '../models/night_record.dart';
import '../widgets/action_marks_row.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/tr_text.dart';

/// A permanent (for the rest of the game session) log of every past
/// night: who was marked by what, and who ended up eliminated. The live
/// Night Actions screen only ever shows the *current*, still-open night -
/// this is where past nights go to stay looked-back-at-able.
class NightHistoryScreen extends StatelessWidget {
  final GameState gameState;

  const NightHistoryScreen({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    final records = gameState.history;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const BannerAppBarBackground(),
        title: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Night History'), Text(' / تاریخچه شب‌ها')]),
      ),
      body: records.isEmpty
          ? Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  TrText('No nights finished yet.', style: TextStyle(color: AppColors.textSecondary)),
                  Text(' / هنوز هیچ شبی تمام نشده.', style: TextStyle(color: AppColors.textSecondary)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: records.length,
              itemBuilder: (context, index) {
                // Most recent night first.
                final record = records[records.length - 1 - index];
                return _NightRecordCard(record: record, gameState: gameState);
              },
            ),
    );
  }
}

class _NightRecordCard extends StatelessWidget {
  final NightRecord record;
  final GameState gameState;

  const _NightRecordCard({required this.record, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Night ${record.night} / شب ${record.night}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const Divider(height: 16),
            if (record.marks.isEmpty)
              Row(
                children: const [
                  TrText('No actions were marked.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  Text(' / هیچ اکتی ثبت نشد.', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              )
            else
              for (final mark in record.marks)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Player ${mark.playerNumber}: ${mark.label}',
                          style: TextStyle(fontSize: 12.5, color: mark.color),
                        ),
                      ),
                      if (mark.actionEmojis.isNotEmpty)
                        SizedBox(
                          width: 90,
                          child: ActionMarksRow(emojis: mark.actionEmojis),
                        ),
                    ],
                  ),
                ),
            if (record.eliminated.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Eliminated: ${record.eliminated.join(", ")}\n'
                'حذف‌شدگان: ${record.eliminated.join("، ")}',
                style: const TextStyle(
                  color: AppColors.mafiaTeam,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
            if (record.votes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: const [
                  TrText('Votes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(' / آرا:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              Text(
                record.votes.entries
                    .map((e) => 'P${e.key}: ${e.value}')
                    .join('   '),
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
