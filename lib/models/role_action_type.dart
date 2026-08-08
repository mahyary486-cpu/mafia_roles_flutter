/// When a role's special ability is used.
enum RoleActionTiming { day, night }

/// The six broad ability categories a role's action can fall into -
/// mirrors the game-design classification: what a role's ability
/// fundamentally *does*, regardless of its flavor text. Used by the
/// custom-role builder so the game master can tell the app how a new
/// role should generally behave (which toolbar it appears in, and what
/// kind of effect tapping a target has).
enum RoleActionCategory {
  /// Directly kills/removes a player (Mafia, Vigilante, Cowboy, ...).
  killing,

  /// Saves or shields a player from being eliminated (Doctor, Bodyguard).
  protection,

  /// Reveals information about a target, no elimination (Detective, Spy).
  investigation,

  /// Silences or blocks another role's ability for the round (Bartender,
  /// Jailor).
  disable,

  /// Moves/steals a role, or grants an ability to someone else (Thief,
  /// Transporter).
  manipulation,

  /// Has its own special win condition instead of following its team's
  /// (Jester, Executioner, Survivor).
  winCondition,
}

extension RoleActionCategoryLabels on RoleActionCategory {
  String get emoji {
    switch (this) {
      case RoleActionCategory.killing:
        return '🔪';
      case RoleActionCategory.protection:
        return '🛡️';
      case RoleActionCategory.investigation:
        return '🔍';
      case RoleActionCategory.disable:
        return '⛓️';
      case RoleActionCategory.manipulation:
        return '🔄';
      case RoleActionCategory.winCondition:
        return '🏆';
    }
  }

  String get nameEn {
    switch (this) {
      case RoleActionCategory.killing:
        return 'Killing / Elimination';
      case RoleActionCategory.protection:
        return 'Protection / Saving';
      case RoleActionCategory.investigation:
        return 'Investigation / Information';
      case RoleActionCategory.disable:
        return 'Disable / Silence';
      case RoleActionCategory.manipulation:
        return 'Role Manipulation';
      case RoleActionCategory.winCondition:
        return 'Special Win Condition';
    }
  }

  String get nameFa {
    switch (this) {
      case RoleActionCategory.killing:
        return 'حذف بازیکن';
      case RoleActionCategory.protection:
        return 'محافظت و نجات';
      case RoleActionCategory.investigation:
        return 'کسب اطلاعات';
      case RoleActionCategory.disable:
        return 'غیرفعال‌سازی نقش دیگر';
      case RoleActionCategory.manipulation:
        return 'تغییر/جابجایی نقش';
      case RoleActionCategory.winCondition:
        return 'شرط برد خاص';
    }
  }
}
