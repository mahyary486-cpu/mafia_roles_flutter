import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/ad_ids.dart';

/// Thin wrapper around the Google Mobile Ads SDK.
///
/// Every call here is defensive: if there's no internet connection or ads
/// otherwise fail to load, we simply don't show anything - the rest of
/// the app (which needs no network at all) keeps working normally.
class AdService {
  AdService._();

  static bool _initialized = false;

  /// Call once, early in `main()`, before `runApp`.
  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (_) {
      // No internet, or ads unavailable for some other reason - fine,
      // the app doesn't depend on this succeeding.
    }
  }
}

/// Loads an interstitial ad ahead of time so it's ready the instant
/// "End Game" is pressed, and shows it then (if it loaded in time).
/// Call [preload] when the roster screen opens, and [showIfReady] when
/// the game master presses "End Game".
class InterstitialAdController {
  InterstitialAd? _ad;

  static const _lastShownKey = 'last_interstitial_shown_ms';
  static const _cooldownMinutesKey = 'next_interstitial_cooldown_minutes';

  void preload() {
    InterstitialAd.load(
      adUnitId: AdIds.interstitialAndroid,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _ad = ad,
        onAdFailedToLoad: (_) => _ad = null,
      ),
    );
  }

  /// The gap between ads is randomized between 30 and 59 minutes each
  /// time, rather than a fixed interval.
  Future<bool> _cooldownElapsed() async {
    final prefs = await SharedPreferences.getInstance();
    final lastMs = prefs.getInt(_lastShownKey);
    if (lastMs == null) return true;
    final cooldownMinutes = prefs.getInt(_cooldownMinutesKey) ?? 30;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    return DateTime.now().difference(last) >= Duration(minutes: cooldownMinutes);
  }

  Future<void> _markShownNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastShownKey, DateTime.now().millisecondsSinceEpoch);
    await prefs.setInt(_cooldownMinutesKey, 30 + Random().nextInt(30)); // 30-59
  }

  /// Shows the ad if it's ready AND at least 30 minutes have passed since
  /// the last time an ad was shown; calls [onDone] either way (right away
  /// if no ad is available or the cooldown hasn't elapsed, or once the ad
  /// is closed).
  void showIfReady(VoidCallback onDone) {
    final ad = _ad;
    if (ad == null) {
      onDone();
      return;
    }
    _cooldownElapsed().then((elapsed) {
      if (!elapsed) {
        onDone();
        return;
      }
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _markShownNow();
          onDone();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          onDone();
        },
      );
      ad.show();
      _ad = null;
    });
  }

  void dispose() {
    _ad?.dispose();
  }
}
