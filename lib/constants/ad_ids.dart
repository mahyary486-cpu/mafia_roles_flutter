/// AdMob ad unit IDs, in one place so they're easy to swap out.
///
/// These are Google's official PUBLIC TEST ad unit IDs - safe to ship
/// while developing, since they always serve real (but non-monetized)
/// test ads and never risk an AdMob policy violation. Once you have a
/// real AdMob account and app registered, replace the four values below
/// with your own IDs from the AdMob console, and also update the
/// `APPLICATION_ID` in `.github/workflows/build_apk.yml` (search for
/// "ca-app-pub-3940256099942544~3347511713").
class AdIds {
  AdIds._();

  /// Shown as a small banner at the bottom of the first screen.
  static const String bannerAndroid = 'ca-app-pub-3940256099942544/6300978111';

  /// Shown as a full-screen interstitial after "End Game" is pressed -
  /// a natural pause point, not interrupting a live reveal.
  static const String interstitialAndroid =
      'ca-app-pub-3940256099942544/1033173712';
}
