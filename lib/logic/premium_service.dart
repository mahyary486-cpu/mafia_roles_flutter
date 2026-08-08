import 'package:shared_preferences/shared_preferences.dart';

/// The app's second monetization path (the first is the end-of-game
/// interstitial ad in `ad_service.dart`): free forever up to
/// [freePlayerLimit] players, then a small monthly subscription to
/// unlock larger games.
///
/// IMPORTANT: this is the *structure* only. There is no real payment
/// processing wired up yet - `isPremium` is only ever set locally on the
/// device by [debugSetPremium] (for testing the unlocked state), and
/// [unlockPriceLabel] is just display text. Actually charging people
/// needs a real store listing plus billing setup (Google Play Billing
/// on Android, App Store / Stripe elsewhere) - none of which can be
/// wired up without a registered developer/merchant account, which the
/// game master said isn't set up yet. When it is, replace
/// [purchasePremium]'s body with a real `in_app_purchase` (or
/// `google_play_billing`) call, and persist the *verified* receipt
/// instead of the local flag used here.
class PremiumService {
  PremiumService._();

  static const _premiumKey = 'is_premium_v1';

  /// Player counts at or below this are always free, no matter what.
  static const int freePlayerLimit = 7;

  /// Display-only price text for the paywall - not connected to a real
  /// billing SKU yet.
  static const String unlockPriceLabel = '\$1 / month';

  static bool _cachedIsPremium = false;

  /// Loads the locally-stored premium flag. Call once early (e.g. in
  /// `main()`) before relying on [isPremiumSync].
  static Future<bool> loadIsPremium() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedIsPremium = prefs.getBool(_premiumKey) ?? false;
    return _cachedIsPremium;
  }

  /// The last value loaded by [loadIsPremium] - safe to call
  /// synchronously from build methods once the app has started.
  static bool get isPremiumSync => _cachedIsPremium;

  /// True if a game with [playerCount] players is playable without
  /// upgrading.
  static bool isCountFree(int playerCount) => playerCount <= freePlayerLimit;

  /// True if [playerCount] needs premium and the game master doesn't
  /// have it yet - i.e. the paywall should be shown.
  static bool needsPaywall(int playerCount) =>
      !isCountFree(playerCount) && !_cachedIsPremium;

  /// Placeholder for the real purchase flow - see the class doc. For now
  /// this just flips the local flag so the rest of the app (and anyone
  /// testing the paywall UI) has something to react to.
  static Future<void> debugSetPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_premiumKey, value);
    _cachedIsPremium = value;
  }
}
