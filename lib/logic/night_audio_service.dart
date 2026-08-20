import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays the two "Game Master Assistant" narration clips back-to-back,
/// looping the pair for as long as the Night Actions screen is open -
/// track 1, then track 2, then back to track 1, forever - until muted or
/// the night screen closes.
///
/// A single app-wide instance (see [instance]) so the mute preference
/// and "is it currently playing" state survive navigating in and out of
/// the Night Actions screen, and so a role-action video (see
/// [role_action_video.dart]) can duck the music immediately no matter
/// which screen asked for it.
class NightAudioService extends ChangeNotifier {
  NightAudioService._() {
    // The Thief's stolen-shot video plays muted (volume 0) but, like any
    // video, still opens its own audio track - which by default makes
    // Android hand our background music's audio focus over to it and
    // pause us, even though it makes no sound itself. Telling our
    // player not to fight over audio focus (and, on iOS, to mix with
    // others) keeps the night loop playing straight through it.
    AudioPlayer.global.setAudioContext(
      AudioContext(
        android: const AudioContextAndroid(
          isSpeakerphoneOn: false,
          stayAwake: false,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.ambient,
          options: const {AVAudioSessionOptions.mixWithOthers},
        ),
      ),
    );
  }
  static final NightAudioService instance = NightAudioService._();

  static const _tracks = [
    'audio/night_loop_1.mp3',
    'audio/night_loop_2.mp3',
  ];

  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;
  bool _wantsToPlay = false;
  int _trackIndex = 0;
  bool _pausedForVideo = false;

  bool get muted => _muted;

  void setMuted(bool value) {
    if (_muted == value) return;
    _muted = value;
    notifyListeners();
    if (_muted) {
      _player.stop();
    } else if (_wantsToPlay) {
      _playCurrentTrack();
    }
  }

  void toggleMuted() => setMuted(!_muted);

  /// Call when the Night Actions screen opens. Starts the loop from
  /// track 1 (unless muted, in which case it just remembers to start
  /// once un-muted).
  Future<void> startNightLoop() async {
    _wantsToPlay = true;
    _trackIndex = 0;
    if (_muted) return;
    await _playCurrentTrack();
  }

  /// Call when the Night Actions screen closes (back to Day). Stops the
  /// music entirely - it only plays during the night.
  Future<void> stopNightLoop() async {
    _wantsToPlay = false;
    _pausedForVideo = false;
    await _player.stop();
  }

  /// Call the instant a role-action video starts - cuts the background
  /// music immediately so it doesn't play under the video's own sound.
  Future<void> duckForVideo() async {
    if (!_wantsToPlay || _muted) return;
    _pausedForVideo = true;
    await _player.stop();
  }

  /// Call right after the role-action video finishes - resumes the loop
  /// from where it conceptually left off (just continues the sequence),
  /// unless muted or the night screen has since closed.
  Future<void> resumeAfterVideo() async {
    if (!_pausedForVideo) return;
    _pausedForVideo = false;
    if (!_wantsToPlay || _muted) return;
    await _playCurrentTrack();
  }

  Future<void> _playCurrentTrack() async {
    await _player.stop();
    await _player.play(AssetSource(_tracks[_trackIndex]));
    _player.onPlayerComplete.first.then((_) {
      if (!_wantsToPlay || _muted || _pausedForVideo) return;
      _trackIndex = (_trackIndex + 1) % _tracks.length;
      _playCurrentTrack();
    });
  }
}
