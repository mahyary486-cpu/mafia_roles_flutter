import 'package:flutter/material.dart';
import 'role_action_type.dart';
import 'role_type.dart';
import 'team.dart';

/// Immutable description of a role: how it looks and reads in the UI.
///
/// Built-in roles are constructed once in `role_data.dart`. Custom
/// (game-master-authored) roles are constructed on the fly at setup time
/// with `type: RoleType.custom`.
@immutable
class Role {
  final RoleType type;
  final Team team;
  final String name;
  final String description;
  final String nameFa;
  final String descriptionFa;
  final String iconAsset;
  final Color color;

  /// A small emoji shown before the role's name in lists - a quick visual
  /// even without loading the SVG icon. Editable per-role (see
  /// EditRoleDialog / RoleOverridesStore). Plain Citizen and plain Mafia
  /// intentionally share the same neutral emoji, since neither has a
  /// special ability; every named role gets its own.
  final String emoji;

  /// A one-sentence version of [description]/[descriptionFa], used on the
  /// fixed-size in-game reveal card so every card is the same size. The
  /// full, detailed version stays in the rulebook. Falls back to the full
  /// description if no short one was given (e.g. for custom roles).
  final String? shortDescription;
  final String? shortDescriptionFa;

  /// Whether this role's ability is used during the Day or the Night.
  /// Built-in roles default to Night (matching how most of them already
  /// work); the handful of built-in Day roles (Cowboy/Bomber/Terrorist)
  /// are still identified separately via `dayActionRoleTypes` for now.
  /// Custom roles set this explicitly when the game master creates them.
  final RoleActionTiming actionTiming;

  /// Which of the six broad ability patterns this role's action follows
  /// (see [RoleActionCategory]). Null for built-in roles that haven't
  /// been classified yet; always set for new custom roles.
  final RoleActionCategory? actionCategory;

  /// For custom roles only: the built-in role this one's icon should be
  /// placed right after in the Day/Night action toolbar (e.g. "right
  /// after Godfather"). Null means "at the end", the default.
  final RoleType? insertAfterRoleType;

  /// A stable identifier used to track selection/storage. Built-in roles
  /// use their [RoleType]'s name (unique already); custom roles get their
  /// own generated id, since many custom roles all share
  /// `type: RoleType.custom`.
  final String? customId;
  String get id => customId ?? type.name;

  String get displayShortDescription => shortDescription ?? description;
  String get displayShortDescriptionFa => shortDescriptionFa ?? descriptionFa;

  const Role({
    required this.type,
    required this.team,
    required this.name,
    required this.description,
    required this.nameFa,
    required this.descriptionFa,
    required this.iconAsset,
    required this.color,
    this.emoji = '🎭',
    this.shortDescription,
    this.shortDescriptionFa,
    this.customId,
    this.actionTiming = RoleActionTiming.night,
    this.actionCategory,
    this.insertAfterRoleType,
  });

  /// Serializes a *custom* role for local storage. Built-in roles are
  /// never saved this way - they already live in `role_data.dart`.
  Map<String, dynamic> toJson() => {
        'customId': customId,
        'team': team.name,
        'name': name,
        'description': description,
        'nameFa': nameFa,
        'descriptionFa': descriptionFa,
        'color': color.value,
        'emoji': emoji,
        'actionTiming': actionTiming.name,
        'actionCategory': actionCategory?.name,
        'insertAfterRoleType': insertAfterRoleType?.name,
      };

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      type: RoleType.custom,
      customId: json['customId'] as String,
      team: Team.values.byName(json['team'] as String),
      name: json['name'] as String,
      description: json['description'] as String,
      nameFa: json['nameFa'] as String,
      descriptionFa: json['descriptionFa'] as String,
      iconAsset: 'assets/icons/custom.svg',
      color: Color(json['color'] as int),
      emoji: json['emoji'] as String? ?? '🎭',
      actionTiming: RoleActionTiming.values.byName(
        json['actionTiming'] as String? ?? 'night',
      ),
      actionCategory: (json['actionCategory'] as String?) == null
          ? null
          : RoleActionCategory.values.byName(json['actionCategory'] as String),
      insertAfterRoleType: (json['insertAfterRoleType'] as String?) == null
          ? null
          : RoleType.values.byName(json['insertAfterRoleType'] as String),
    );
  }
}
