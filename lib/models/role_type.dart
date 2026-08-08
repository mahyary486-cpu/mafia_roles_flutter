/// Every built-in role that can exist in the game.
///
/// [custom] is special: it marks a role written by the game master at
/// setup time. Its actual name/description/team live in the [Role] object
/// itself (constructed on the fly), not in `role_data.dart`.
///
/// To add a new *built-in* role: add it here, then add its entry in
/// `role_data.dart`.
enum RoleType {
  // Citizen team
  citizen,
  doctor,
  sniper,
  bartender,
  priest,
  detective,
  investigator,
  cowboy,
  bomber,
  gunman,
  invincible,
  commander,
  guard,
  freemason,
  tyler,
  spy,
  snowman,
  consigliere,
  veteran,
  blackmailer,
  mayor,
  // Mafia team
  mafia,
  godfather,
  terrorist,
  thief,
  natasha,
  joker,
  enchanter,
  yakuza,
  strongman,
  psycho,
  // Independent
  nostradamus,
  killer,
  president,
  // Game-master-authored role
  custom,
}

/// Roles whose special ability is used during the Day phase instead of at
/// night (their icon lives in the Day toolbar, not the Night one).
const Set<RoleType> dayActionRoleTypes = {
  RoleType.cowboy,
  RoleType.bomber,
  RoleType.terrorist,
};
