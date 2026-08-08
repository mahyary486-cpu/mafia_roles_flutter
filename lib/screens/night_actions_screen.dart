import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/role_data.dart';
import '../logic/game_state.dart';
import '../logic/locale_service.dart';
import '../logic/night_audio_service.dart';
import '../widgets/night_music_mute_button.dart';
import '../models/role.dart';
import '../models/role_action_type.dart';
import '../models/role_type.dart';
import '../models/team.dart';
import '../widgets/action_marks_row.dart';
import '../widgets/banner_app_bar_background.dart';
import '../widgets/role_action_video.dart';
import '../widgets/role_emoji_badge.dart';
import '../widgets/role_toolbar_button.dart';
import '../widgets/tr_text.dart';
import 'night_history_screen.dart';

/// A first version of a "night board" for the game master: tap a role
/// icon to arm it, then tap a player to apply that role's effect to them
/// - their name lights up in a color that says what happened.
///
/// This is a general-purpose tool, not a full rules engine for every one
/// of the game's 28 roles: it groups roles into six broad effect types
/// (shot / saved / silenced / cured / blocked / other) and handles the two
/// interactions explicitly asked for (Doctor undoing a Sniper/Godfather
/// shot, Priest undoing Natasha's silence). Anything more specific is
/// still up to the game master's own judgment - see the note at the
/// bottom of this screen.
class NightActionsScreen extends StatefulWidget {
  final GameState gameState;

  const NightActionsScreen({super.key, required this.gameState});

  @override
  State<NightActionsScreen> createState() => _NightActionsScreenState();
}

enum _Effect { shot, saved, silenced, cured, blocked, info }

class _NightActionsScreenState extends State<NightActionsScreen> {
  RoleType? _armedType;
  Role? _armedRole;
  bool _judgeArmed = false;
  bool _stolenRoleArmed = false;

  @override
  void initState() {
    super.initState();
    // The night loop is started earlier, the instant "End Day" is
    // pressed (see DayNightTransitionScreen), so it plays under the
    // transition's board/sign images instead of only starting once
    // this screen finally loads.
  }

  @override
  void dispose() {
    NightAudioService.instance.stopNightLoop();
    super.dispose();
  }

  /// Cuts the background night music immediately, plays the clip, then
  /// resumes the music where the loop would naturally continue.
  Future<void> _playActionVideo(String assetPath) async {
    await NightAudioService.instance.duckForVideo();
    await showRoleActionVideo(context, assetPath);
    await NightAudioService.instance.resumeAfterVideo();
  }

  /// Same clip, but silent - used when the Thief steals a killing
  /// role's ability. The night background music keeps playing straight
  /// through it instead of being ducked, since the video itself makes
  /// no sound.
  Future<void> _playActionVideoMuted(String assetPath) async {
    await showRoleActionVideo(context, assetPath, muted: true);
  }

  /// The Investigator gets two targets before his icon goes dark - every
  /// other role only gets one. Reset once he's used up both.
  final List<int> _investigatorTargets = [];

  _Effect _effectFor(RoleType type) {
    switch (type) {
      case RoleType.godfather:
      case RoleType.mafia:
      case RoleType.sniper:
      case RoleType.strongman:
        return _Effect.shot;
      case RoleType.doctor:
      case RoleType.commander:
        return _Effect.saved;
      case RoleType.priest:
        return _Effect.cured;
      case RoleType.natasha:
        return _Effect.silenced;
      case RoleType.bartender:
      case RoleType.enchanter:
        return _Effect.blocked;
      default:
        return _Effect.info;
    }
  }

  Color _colorForEffect(_Effect e) {
    switch (e) {
      case _Effect.shot:
        return Colors.redAccent;
      case _Effect.saved:
      case _Effect.cured:
        return Colors.greenAccent;
      case _Effect.silenced:
        return Colors.blueGrey;
      case _Effect.blocked:
        return Colors.brown;
      case _Effect.info:
        return Colors.purpleAccent;
    }
  }

  String _labelForEffect(_Effect e, Role role) {
    switch (e) {
      case _Effect.shot:
        return 'Shot (${role.name}) / شات (${role.nameFa})';
      case _Effect.saved:
        return 'Saved (${role.name}) / سیو (${role.nameFa})';
      case _Effect.cured:
        return 'Cured (${role.name}) / رفع اثر (${role.nameFa})';
      case _Effect.silenced:
        return 'Silenced (${role.name}) / سکوت (${role.nameFa})';
      case _Effect.blocked:
        return 'Blocked (${role.name}) / بسته (${role.nameFa})';
      case _Effect.info:
        return '${role.name} / ${role.nameFa}';
    }
  }

  void _toggleArm(Role role) {
    if (_armedType == role.type) {
      setState(() {
        _armedType = null;
        _armedRole = null;
      });
      return;
    }
    setState(() {
      _armedType = role.type;
      _armedRole = role;
      _judgeArmed = false;
    });
  }

  void _toggleJudgeArm() {
    setState(() {
      _judgeArmed = !_judgeArmed;
      if (_judgeArmed) {
        _armedType = null;
        _armedRole = null;
      }
    });
  }

  void _toggleStolenRoleArm() {
    setState(() {
      _stolenRoleArmed = !_stolenRoleArmed;
      if (_stolenRoleArmed) {
        _armedType = null;
        _armedRole = null;
        _judgeArmed = false;
      }
    });
  }

  void _applyStolenRole(int playerNumber) {
    if (widget.gameState.stolenNightRoleUsed) return;
    final stolenType = widget.gameState.stolenNightRoleType;
    if (stolenType == null) return;
    final role = RoleData.all[stolenType];
    if (role == null) return;
    final effect = _effectFor(stolenType);
    final currentLabel = widget.gameState.nightMarkLabel(playerNumber) ?? '';

    if (effect == _Effect.saved && currentLabel.startsWith('Shot')) {
      widget.gameState.setNightMark(
        playerNumber,
        Colors.greenAccent,
        'Saved - was shot / سیو شد (شات خورده بود)',
      );
    } else {
      widget.gameState.setNightMark(
        playerNumber,
        _colorForEffect(effect),
        '${_labelForEffect(effect, role)} - ability stolen by the Thief / '
        'توانایی توسط دزد دزدیده و اجرا شد',
      );
    }
    if (effect == _Effect.shot) {
      widget.gameState.markShotTonight(playerNumber);
      _playActionVideoMuted('assets/videos/godfather_shot.mp4');
    }
    if (effect == _Effect.saved) widget.gameState.markSavedTonight(playerNumber);

    // Both the stolen role's icon and the Thief's icon show up next to
    // the affected player, so it's clear at a glance who really acted.
    widget.gameState.addActionBadge(playerNumber, role.emoji);
    widget.gameState.addActionBadge(playerNumber, '🗡️');

    // The icon stays put next to the Thief, now shown as dark/used, so
    // the game master can see it was already spent tonight - it does
    // not just vanish.
    widget.gameState.markStolenNightRoleUsed();
    setState(() => _stolenRoleArmed = false);
  }

  Future<void> _applyJudgeDecision(int playerNumber) async {
    final target = widget.gameState.psychoTarget;
    if (target == null) return;
    if (playerNumber != target) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The judge can only decide on the Psycho\'s marked target. / '
            'قاضی فقط می‌تواند درباره فرد نشانه‌گذاری‌شده توسط روانی تصمیم بگیرد.',
          ),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Judge\'s Decision'), Text(' / تصمیم قاضی')]),
        content: const Text(
          'Like = eliminated. Dislike = stays in the game. / '
          'لایک = حذف می‌شود. دیس‌لایک = در بازی می‌ماند.',
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(false),
            icon: const Text('👎', style: TextStyle(fontSize: 20)),
            label: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Dislike'), Text(' / دیس‌لایک')]),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(true),
            icon: const Text('👍', style: TextStyle(fontSize: 20)),
            label: Row(mainAxisSize: MainAxisSize.min, children: const [TrText('Like'), Text(' / لایک')]),
          ),
        ],
      ),
    );
    if (approved == null) return;

    if (approved) {
      widget.gameState.markShotTonight(target);
      widget.gameState.addActionBadge(target, '👍');
      widget.gameState.setNightMark(
        target,
        Colors.redAccent,
        'Approved by the Judge / تایید شد توسط قاضی',
      );
    } else {
      widget.gameState.addActionBadge(target, '👎');
      widget.gameState.setNightMark(
        target,
        Colors.greenAccent,
        'Spared by the Judge / قاضی او را بخشید',
      );
    }
    widget.gameState.clearPsycho();
    setState(() => _judgeArmed = false);
  }

  void _applyToPlayer(int playerNumber) {
    final armed = _armedRole;
    if (armed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(mainAxisSize: MainAxisSize.min, children: [TrText('Tap a role icon above first'), const Text(' / اول یه آیکون نقش رو انتخاب کنید')]),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Simple Mode (toggle chosen at game start): skip every role
    // algorithm entirely - just drop that role's icon in front of the
    // tapped player as a visual note, and disarm. No elimination, no
    // saving, no stealing, nothing else happens.
    if (!widget.gameState.abilitiesAutoExecuted) {
      widget.gameState.addActionBadge(playerNumber, armed.emoji);
      setState(() => _armedType = _armedRole = null);
      return;
    }

    // If this role's ability was blocked earlier tonight (by the
    // Bartender, Thief, or Enchanter), it has no effect at all.
    if (widget.gameState.isRoleDisabledTonight(armed.type)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${armed.name} is blocked tonight - no effect. / '
            '${armed.nameFa} امشب بسته است - اثری ندارد.',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // The Psycho's action takes two taps: first marks a target (not
    // eliminated yet), then appoints a second player as "the judge" -
    // who later decides the target's fate via the separate judge icon.
    if (armed.type == RoleType.psycho) {
      if (widget.gameState.psychoTarget == null) {
        widget.gameState.setPsychoTarget(playerNumber);
        widget.gameState.setNightMark(
          playerNumber,
          Colors.redAccent,
          'Marked by the Psycho / نشانه‌گذاری شد توسط روانی',
        );
        setState(() {}); // stays armed - tap a second player next
        return;
      }
      if (widget.gameState.psychoJudge == null) {
        if (playerNumber == widget.gameState.psychoTarget) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Pick a different player as the judge. / '
                'یک بازیکن دیگر را به‌عنوان قاضی انتخاب کنید.',
              ),
              duration: Duration(seconds: 2),
            ),
          );
          return;
        }
        widget.gameState.setPsychoJudge(playerNumber);
        widget.gameState.addActionBadge(playerNumber, armed.emoji);
        widget.gameState
            .recordActedTonight(RoleType.psycho, widget.gameState.psychoTarget!);
        setState(() => _armedType = _armedRole = null); // disarm Psycho
        return;
      }
    }

    final targetRole = widget.gameState.roleFor(playerNumber);

    // Self-targeting: normally a role can't act on its own holder. Doctor,
    // Priest, and Natasha are the exception - each of them may target
    // themselves exactly once across the whole game (e.g. the Doctor
    // saving himself).
    final holderNumber = _findPlayerNumber(armed.type);
    if (holderNumber == playerNumber) {
      const selfAllowedRoles = {RoleType.doctor, RoleType.priest, RoleType.natasha};
      if (!selfAllowedRoles.contains(armed.type)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'This role cannot target itself. / این نقش نمی‌تواند روی خودش اکت کند.',
            ),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (widget.gameState.hasUsedSelfTarget(armed.type)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${armed.name} already used their one self-target for this '
              'game. / ${armed.nameFa} قبلاً یک‌بار اکت روی خودش را در این بازی استفاده کرده.',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      widget.gameState.markSelfTargetUsed(armed.type);
    }

    final effect = _effectFor(armed.type);
    final currentLabel = widget.gameState.nightMarkLabel(playerNumber) ?? '';

    // Sniper backfire rule: with up to 12 players, shooting a Citizen
    // backfires and the Sniper eliminates himself instead - the target is
    // safe. With more than 12 players, the shot lands as normal and the
    // Citizen is the one eliminated.
    if (armed.type == RoleType.sniper &&
        targetRole.team == Team.citizen &&
        (widget.gameState.playerCount ?? 0) <= 12) {
      final sniperNumber = _findPlayerNumber(RoleType.sniper);
      if (sniperNumber != null) {
        widget.gameState.setNightMark(
          sniperNumber,
          Colors.redAccent,
          'Backfired - shot a Citizen / برخورد به خودش کرد (شهروند را زده بود)',
        );
        widget.gameState.markShotTonight(sniperNumber);
        _playActionVideo('assets/videos/godfather_shot.mp4');
        widget.gameState.addActionBadge(sniperNumber, armed.emoji);
        widget.gameState.recordActedTonight(RoleType.sniper, playerNumber);
      }
      setState(() {});
      return;
    }

    // Thief targeting the Guard: the Thief gets caught and eliminated
    // instead of stealing anything.
    if (armed.type == RoleType.thief && targetRole.type == RoleType.guard) {
      final thiefNumber = _findPlayerNumber(RoleType.thief);
      if (thiefNumber != null) {
        widget.gameState.setNightMark(
          thiefNumber,
          Colors.redAccent,
          'Caught by the Guard / توسط نگهبان دستگیر شد',
        );
        widget.gameState.markShotTonight(thiefNumber);
        widget.gameState.addActionBadge(thiefNumber, armed.emoji);
        widget.gameState.recordActedTonight(RoleType.thief, playerNumber);
      }
      setState(() {});
      return;
    }

    // Thief targeting a day-action role (Cowboy/Bomber/Terrorist): the
    // Thief steals that ability instead of just blocking it - the next
    // day, the Thief acts in that player's place. The original holder's
    // row shows the Thief's icon as a reminder.
    if (armed.type == RoleType.thief && dayActionRoleTypes.contains(targetRole.type)) {
      final thiefNumber = _findPlayerNumber(RoleType.thief);
      if (thiefNumber != null) {
        widget.gameState.setThiefSteal(thiefNumber, playerNumber);
        widget.gameState.addActionBadge(playerNumber, armed.emoji);
        widget.gameState.setNightMark(
          playerNumber,
          Colors.brown,
          'Ability stolen by the Thief / نقشش توسط دزد دزدیده شد',
        );
        widget.gameState.recordActedTonight(RoleType.thief, playerNumber);
      }
      setState(() {});
      return;
    }

    // Thief targeting any other role with an active night ability
    // (Doctor, Detective, etc.): steals it for the rest of *this* night -
    // the stolen role's icon appears next to the Thief's in the toolbar,
    // blinking, ready for the game master to use it on someone.
    if (armed.type == RoleType.thief &&
        !_passiveRoles.contains(targetRole.type) &&
        !dayActionRoleTypes.contains(targetRole.type)) {
      final thiefNumber = _findPlayerNumber(RoleType.thief);
      if (thiefNumber != null) {
        widget.gameState.setStolenNightRole(targetRole.type, playerNumber);
        widget.gameState.addActionBadge(playerNumber, armed.emoji);
        widget.gameState.setNightMark(
          playerNumber,
          Colors.brown,
          'Ability stolen by the Thief / تواناییش توسط دزد دزدیده شد',
        );
        widget.gameState.recordActedTonight(RoleType.thief, playerNumber);
        _stolenRoleArmed = true;
      }
      setState(() {});
      return;
    }

    if (effect == _Effect.saved && currentLabel.startsWith('Shot')) {
      widget.gameState.setNightMark(
        playerNumber,
        Colors.greenAccent,
        'Saved - was shot / سیو شد (شات خورده بود)',
      );
    } else if (effect == _Effect.cured && currentLabel.startsWith('Silenced')) {
      widget.gameState.setNightMark(
        playerNumber,
        Colors.greenAccent,
        'Cured - was silenced / رفع سکوت شد',
      );
    } else if (armed.type == RoleType.yakuza && targetRole.type == RoleType.citizen) {
      widget.gameState.setNightMark(
        playerNumber,
        AppColors.mafiaTeam,
        'Converted to Mafia by Yakuza / یاکوزا او را به مافیا تبدیل کرد',
      );
    } else {
      widget.gameState.setNightMark(
        playerNumber,
        _colorForEffect(effect),
        _labelForEffect(effect, armed),
      );
    }

    // Order-independent tracking for Night Results: a player is only
    // actually eliminated if shot and never saved, regardless of which
    // order the game master tapped the Godfather/Sniper and the Doctor.
    final isKillingRole = effect == _Effect.shot ||
        (armed.type == RoleType.custom && armed.actionCategory == RoleActionCategory.killing);
    if (isKillingRole) widget.gameState.markShotTonight(playerNumber);
    if (effect == _Effect.saved) widget.gameState.markSavedTonight(playerNumber);
    if (effect == _Effect.silenced) widget.gameState.setNatashaSilence(playerNumber);
    if (isKillingRole) _playActionVideo('assets/videos/godfather_shot.mp4');

    // Every role's icon that touches a player shows up in front of that
    // player in the roster list - several can stack on the same player.
    widget.gameState.addActionBadge(playerNumber, armed.emoji);

    // The role's icon goes dark for the rest of the night once it's
    // used up its taps - the "X" next to it can undo this and re-arm it
    // for a different target. Every role gets one tap, except the
    // Investigator, who gets two before disarming.
    if (armed.type == RoleType.investigator) {
      _investigatorTargets.add(playerNumber);
      if (_investigatorTargets.length >= 2) {
        widget.gameState.recordActedTonight(armed.type, playerNumber);
        widget.gameState.setInvestigatorTargets(List.of(_investigatorTargets));
        _investigatorTargets.clear();
        _armedType = null;
        _armedRole = null;
      }
      // After the first tap, stay armed so the second tap can land too.
    } else {
      widget.gameState.recordActedTonight(armed.type, playerNumber);
      _armedType = null;
      _armedRole = null;
    }

    // Bartender, Thief, and Enchanter block the target's own role for
    // the rest of the night.
    const blockingRoles = {RoleType.bartender, RoleType.thief, RoleType.enchanter};
    if (blockingRoles.contains(armed.type)) {
      widget.gameState.disableRoleTonight(targetRole.type);
    }
    // The Bartender's target also carries a mark into the next day: if
    // that player holds a day-action role (Cowboy/Bomber/Terrorist), they
    // can still act, but only take themselves out - not their target.
    if (armed.type == RoleType.bartender) {
      widget.gameState.setBartenderBlock(playerNumber);
    }

    setState(() {}); // refresh to show the new mark
  }

  int? _findPlayerNumber(RoleType type) {
    final all = widget.gameState.allAssignedRoles;
    for (int i = 0; i < all.length; i++) {
      if (all[i].type == type) return i + 1;
    }
    return null;
  }

  /// Roles with no active night action of their own - they only react to
  /// other roles' actions (or have none at all), so they don't need a
  /// toolbar icon.
  static const _passiveRoles = {
    RoleType.citizen,
    RoleType.mafia,
    RoleType.guard,
    RoleType.invincible,
    RoleType.president,
  };

  /// Explicit toolbar order, right-to-left as described: the Thief (silent
  /// mafia) first, then the Bartender (wakes before everyone), then the
  /// rest of the mafia team in shooting-priority order, then citizens,
  /// then independents. Anything present but not listed here falls back
  /// to the end, grouped by team.
  static const _toolbarOrder = [
    RoleType.thief,
    RoleType.bartender,
    RoleType.godfather,
    RoleType.mafia,
    RoleType.natasha,
    RoleType.yakuza,
    RoleType.terrorist,
    RoleType.cowboy,
    RoleType.bomber,
    RoleType.joker,
    RoleType.enchanter,
    RoleType.strongman,
    RoleType.psycho,
    RoleType.spy,
    RoleType.consigliere,
    RoleType.blackmailer,
    RoleType.doctor,
    RoleType.sniper,
    RoleType.commander,
    RoleType.priest,
    RoleType.detective,
    RoleType.investigator,
    RoleType.freemason,
    RoleType.tyler,
    RoleType.snowman,
    RoleType.veteran,
    RoleType.mayor,
    RoleType.gunman,
    RoleType.nostradamus,
    RoleType.killer,
  ];

  /// True once every *named* mafia role (Godfather, Yakuza, etc.) has
  /// been eliminated but at least one plain Mafia is still alive - that
  /// lone plain Mafia then steps up and shoots in the Godfather's place.
  bool _plainMafiaShouldAct() {
    final gs = widget.gameState;
    final total = gs.playerCount ?? 0;
    var hasNamedMafiaAlive = false;
    var hasPlainMafiaAlive = false;
    for (int n = 1; n <= total; n++) {
      if (gs.isRemoved(n)) continue;
      final role = gs.roleFor(n);
      if (role.team != Team.mafia) continue;
      if (role.type == RoleType.mafia) {
        hasPlainMafiaAlive = true;
      } else {
        hasNamedMafiaAlive = true;
      }
    }
    return !hasNamedMafiaAlive && hasPlainMafiaAlive;
  }

  List<Role> _distinctRolesPresent() {
    final seen = <RoleType>{};
    final byType = <RoleType, Role>{};
    for (final role in widget.gameState.allAssignedRoles) {
      if (!_passiveRoles.contains(role.type)) {
        byType[role.type] = role;
      }
    }
    if (_plainMafiaShouldAct()) {
      final total = widget.gameState.playerCount ?? 0;
      for (int n = 1; n <= total; n++) {
        if (widget.gameState.isRemoved(n)) continue;
        final role = widget.gameState.roleFor(n);
        if (role.type == RoleType.mafia) {
          byType[RoleType.mafia] = role;
          break;
        }
      }
    }
    final result = <Role>[];
    for (final type in _toolbarOrder) {
      final role = byType[type];
      if (role != null && seen.add(type)) result.add(role);
    }
    // Anything present but not in the explicit order (e.g. a future role)
    // still shows up, grouped by team at the end.
    for (final team in [Team.mafia, Team.citizen, Team.independent]) {
      for (final role in byType.values) {
        if (role.team == team && seen.add(role.type)) result.add(role);
      }
    }
    // A custom role can ask to be placed right after a specific built-in
    // role instead of always landing at the end.
    final custom = byType[RoleType.custom];
    if (custom?.insertAfterRoleType != null) {
      result.remove(custom);
      final afterIndex = result.indexWhere((r) => r.type == custom!.insertAfterRoleType);
      result.insert(afterIndex >= 0 ? afterIndex + 1 : result.length, custom!);
    }
    return result;
  }

  Future<void> _showNightResults() async {
    final total = widget.gameState.playerCount ?? 0;
    final lines = <String>[];

    // Actions report: every marked player, purely informational.
    for (int n = 1; n <= total; n++) {
      if (widget.gameState.isRemoved(n)) continue;
      final label = widget.gameState.nightMarkLabel(n);
      if (label == null) continue;
      final role = widget.gameState.roleFor(n);
      lines.add('Player $n (${role.name}): $label');
    }

    // Eliminations: computed separately from the shot/saved sets, not
    // from a single overwritable mark, so it doesn't matter whether the
    // Godfather or the Doctor was tapped first. A shielded (Invincible)
    // player is never eliminated this way even if shot and not saved.
    // The Godfather also has his own one-time-ever shield, separate from
    // the Doctor/Invincible mechanics.
    final toEliminate = <int>[];
    var godfatherShieldUsedTonight = false;
    for (final n in widget.gameState.shotTonight) {
      if (widget.gameState.isRemoved(n)) continue;
      if (widget.gameState.isSavedTonight(n)) continue;
      final role = widget.gameState.roleFor(n);
      if (role.type == RoleType.invincible) continue;
      if (role.type == RoleType.godfather && widget.gameState.godfatherShieldAvailable) {
        widget.gameState.consumeGodfatherShield();
        godfatherShieldUsedTonight = true;
        continue;
      }
      toEliminate.add(n);
    }
    toEliminate.sort();
    if (godfatherShieldUsedTonight) {
      lines.add('The Godfather\'s shield absorbed a shot tonight. / '
          'شیلد پدرخوانده امشب یک شات را خنثی کرد.');
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const TrText('Night Results'),
        content: SizedBox(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (lines.isEmpty)
                Row(mainAxisSize: MainAxisSize.min, children: const [TrText('No actions marked.'), Text(' / هیچ اقدامی ثبت نشده.')])
              else
                ...lines.map((l) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Text(l, style: const TextStyle(fontSize: 13)),
                    )),
              if (toEliminate.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Will be eliminated: ${toEliminate.join(", ")}\n'
                  'حذف می‌شوند: ${toEliminate.join("، ")}',
                  style: const TextStyle(
                    color: AppColors.mafiaTeam,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const TrText('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const TrText('Confirm & End Night'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    for (final n in toEliminate) {
      widget.gameState.toggleRemoved(n);
    }
    widget.gameState.endNight();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.gameState.playerCount ?? 0;
    final roles = _distinctRolesPresent();
    // Once any role is armed (waiting for a player to be tapped), every
    // other ability icon locks so the game master can't tap the wrong
    // one mid-action. Everything unlocks again the moment that action
    // is applied to a player.
    final anyArmed = _armedType != null || _judgeArmed || _stolenRoleArmed;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        image: DecorationImage(
          image: AssetImage('assets/images/night_background.jpg'),
          fit: BoxFit.cover,
          opacity: 0.38,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: const BannerAppBarBackground(),
          title: ValueListenableBuilder<String>(
            valueListenable: LocaleService.instance.languageCode,
            builder: (context, _, __) =>
                Text('${LocaleService.instance.tr('Night Actions')} / اعمال شب'),
          ),
          leading: IconButton(
            icon: const Icon(Icons.wb_sunny_rounded, color: Colors.amber),
            tooltip: 'Back to Day / برگشت به روز',
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            const NightMusicMuteButton(),
            IconButton(
              tooltip: 'Night History / تاریخچه شب‌ها',
              icon: const Icon(Icons.history_edu_rounded),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => NightHistoryScreen(gameState: widget.gameState),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: 84,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    for (final role in roles) ...[
                      Builder(builder: (context) {
                        final armed = _armedType == role.type;
                        final holderNumber = _findPlayerNumber(role.type);
                        final holderRemoved = holderNumber == null ||
                            widget.gameState.isRemoved(holderNumber);
                        final acted = widget.gameState.hasActedTonight(role.type);
                        // If the Thief stole the Sniper's ability tonight,
                        // there's no real Sniper shot left for the
                        // Commander to review - so the Commander's own
                        // icon goes dark for the rest of the night too
                        // (as long as the Commander is still alive).
                        final commanderBlockedByStolenSniper =
                            role.type == RoleType.commander &&
                                widget.gameState.stolenNightRoleType == RoleType.sniper;
                        final disabled = widget.gameState.isRoleDisabledTonight(role.type) ||
                            dayActionRoleTypes.contains(role.type) ||
                            holderRemoved ||
                            acted ||
                            commanderBlockedByStolenSniper ||
                            (anyArmed && !armed);
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            RoleToolbarButton(
                              role: role,
                              armed: armed,
                              disabled: disabled,
                              onTap: () => _toggleArm(role),
                            ),
                          ],
                        );
                      }),
                      // The judge's icon appears right beside the
                      // Psycho's, once a judge has been appointed.
                      if (role.type == RoleType.psycho && widget.gameState.psychoJudge != null)
                        RoleToolbarButton(
                          role: widget.gameState.roleFor(widget.gameState.psychoJudge!),
                          armed: _judgeArmed,
                          disabled: anyArmed && !_judgeArmed,
                          onTap: (anyArmed && !_judgeArmed) ? null : _toggleJudgeArm,
                        ),
                      // A role the Thief stole tonight shows up right
                      // beside the Thief's own icon, ready to be used.
                      if (role.type == RoleType.thief &&
                          widget.gameState.stolenNightRoleType != null)
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.4, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.elasticOut,
                          builder: (context, scale, child) =>
                              Transform.scale(scale: scale, child: child),
                          child: RoleToolbarButton(
                            role: RoleData.all[widget.gameState.stolenNightRoleType]!,
                            armed: _stolenRoleArmed,
                            disabled: widget.gameState.stolenNightRoleUsed ||
                                (anyArmed && !_stolenRoleArmed),
                            onTap: (widget.gameState.stolenNightRoleUsed ||
                                    (anyArmed && !_stolenRoleArmed))
                                ? null
                                : _toggleStolenRoleArm,
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              if (_armedRole != null)
                Container(
                  width: double.infinity,
                  color: _armedRole!.color.withOpacity(0.35),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Armed: ${_armedRole!.name} / ${_armedRole!.nameFa} - tap a player',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFFF9C4),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                    ),
                  ),
                ),
              if (_stolenRoleArmed && widget.gameState.stolenNightRoleType != null)
                Builder(builder: (context) {
                  final stolen = RoleData.all[widget.gameState.stolenNightRoleType]!;
                  return Container(
                    width: double.infinity,
                    color: stolen.color.withOpacity(0.35),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Thief stole the ${stolen.name} ability - select a player to use it on. / '
                      'دزد توانایی ${stolen.nameFa} را دزدید - یک بازیکن را برای اجرا انتخاب کنید',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFF9C4),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                      ),
                    ),
                  );
                }),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final playerNumber = index + 1;
                    if (widget.gameState.isRemoved(playerNumber)) {
                      return const SizedBox.shrink();
                    }
                    final markColor = widget.gameState.nightMarkColor(playerNumber);
                    final markLabel = widget.gameState.nightMarkLabel(playerNumber);
                    final role = widget.gameState.roleFor(playerNumber);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.38),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                      onTap: () => _judgeArmed
                          ? _applyJudgeDecision(playerNumber)
                          : (_stolenRoleArmed
                              ? _applyStolenRole(playerNumber)
                              : _applyToPlayer(playerNumber)),
                      leading: RoleEmojiBadge(emoji: role.emoji, color: role.color, size: 24),
                      title: Text(
                        '$playerNumber - ${role.emoji} ${role.name} / ${role.nameFa}',
                        style: TextStyle(
                          color: markColor ?? AppColors.textPrimary,
                          fontWeight: markColor != null ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (markLabel != null)
                            Text(markLabel, style: TextStyle(color: markColor, fontSize: 11)),
                          ActionMarksRow(
                            emojis: widget.gameState.actionBadgesFor(playerNumber),
                          ),
                        ],
                      ),
                      trailing: markColor != null
                          ? IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: 'Clear mark / پاک کردن',
                              onPressed: () => setState(
                                () => widget.gameState.clearNightMark(playerNumber),
                              ),
                            )
                          : null,
                      ),
                    );
                  },
                ),
              ),
              _EliminatedSoFar(gameState: widget.gameState),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Role actions apply to the app\'s rulebook - for '
                          'roles you add yourself, you manage them.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                        const Text(
                          'اکت‌های نقش‌ها برای رول‌بوک اپ کاربرد دارد؛ برای نقش‌هایی '
                          'که اضافه می‌شود خودتان باید مدیریت کنید.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 9),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => setState(widget.gameState.clearAllNightMarks),
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TrText('Clear Marks', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 38,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _showNightResults,
                              child: const Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TrText('Night Results', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

/// A compact, always-visible strip at the bottom of the night screen
/// listing everyone eliminated so far (across all nights), so the game
/// master doesn't have to switch to the day screen to check.
class _EliminatedSoFar extends StatelessWidget {
  final GameState gameState;

  const _EliminatedSoFar({required this.gameState});

  @override
  Widget build(BuildContext context) {
    final removalsByNight = gameState.removalsByNight;
    final allRemoved = removalsByNight.expand((n) => n).toList();
    if (allRemoved.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 70),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Eliminated so far / حذف‌شده‌ها تا اینجا',
            style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: allRemoved.map((n) {
                  final role = gameState.roleFor(n);
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(
                      '$n ${role.emoji}',
                      style: TextStyle(color: role.color, fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
