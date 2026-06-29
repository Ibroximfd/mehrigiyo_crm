import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

import '../../../../../core/utils/web_media.dart';
import 'audio_event.dart';
import 'audio_state.dart';

/// Single audio controller for the whole chat screen. Holds ONE [AudioPlayer]
/// and guarantees only one voice message plays at a time — starting a new one
/// stops whatever was playing. Pauses automatically when the app backgrounds.
class AudioBloc extends Bloc<AudioEvent, AudioState>
    with WidgetsBindingObserver {
  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;

  /// The message whose audio is currently loaded in [_player].
  int? _currentId;

  /// The `blob:` URL backing the currently loaded clip, if we downloaded it.
  /// Revoked when a new clip loads or the bloc closes to free memory.
  String? _blobUrl;

  AudioBloc() : super(const AudioIdleState()) {
    on<AudioPlayRequested>(_onPlay, transformer: droppable());
    on<AudioPauseRequested>(_onPause);
    on<AudioSeekRequested>(_onSeek);
    on<AudioPlaybackPositionChanged>(_onPositionChanged);
    on<AudioPlaybackCompleted>(_onCompleted);
    on<AudioPlaybackError>(_onError);

    WidgetsBinding.instance.addObserver(this);

    // Detect natural completion.
    _stateSub = _player.playerStateStream.listen((ps) {
      if (ps.processingState == ProcessingState.completed) {
        final id = _currentId;
        if (id != null) add(AudioPlaybackCompleted(id));
      }
    });

    // Throttled position updates (~200ms) feed the progress bar.
    _posSub = _player
        .createPositionStream(
          minPeriod: const Duration(milliseconds: 200),
          maxPeriod: const Duration(milliseconds: 200),
        )
        .listen((pos) {
      final id = _currentId;
      if (id == null) return;
      add(AudioPlaybackPositionChanged(
        messageId: id,
        position: pos,
        duration: _player.duration ?? Duration.zero,
      ));
    });
  }

  Future<void> _onPlay(
    AudioPlayRequested event,
    Emitter<AudioState> emit,
  ) async {
    try {
      // Resume the same paused message: flip to playing immediately, then start
      // the player WITHOUT awaiting (see note below).
      if (_currentId == event.messageId && state is AudioPausedState) {
        final paused = state as AudioPausedState;
        emit(AudioPlayingState(
          messageId: event.messageId,
          position: _player.position,
          duration: paused.duration,
        ));
        _startPlayback();
        return;
      }

      // A different (or fresh) message → buffer the new source and play.
      if (_currentId != event.messageId) {
        _currentId = event.messageId;
        emit(AudioLoadingState(event.messageId));

        // Download the clip and play it from an in-memory blob: URL instead of
        // letting the <audio> element stream the remote file. Streaming uses
        // HTTP range requests that the deployed build's service worker
        // intercepts and stalls forever (works under `flutter run`, which has
        // no service worker). Voice clips are small, so a one-shot download is
        // cheap and robust. Falls back to the direct URL if the fetch fails.
        final blob = await fetchAsBlobUrl(event.audioUrl)
            .timeout(const Duration(seconds: 20), onTimeout: () => null);
        // A newer tap may have superseded us while downloading.
        if (_currentId != event.messageId) {
          if (blob != null) revokeBlobUrl(blob);
          return;
        }

        final String playUrl;
        if (blob != null) {
          _revokeBlob();
          _blobUrl = blob;
          playUrl = blob;
        } else {
          // Fetch failed (e.g. CORS) — fall back to streaming the remote URL.
          playUrl = event.audioUrl;
        }

        final loaded = await _player.setUrl(playUrl);
        if (_currentId != event.messageId) return;
        emit(AudioPlayingState(
          messageId: event.messageId,
          position: Duration.zero,
          duration: loaded ?? _player.duration ?? Duration.zero,
        ));
        _startPlayback();
      } else {
        emit(AudioPlayingState(
          messageId: event.messageId,
          position: _player.position,
          duration: _player.duration ?? Duration.zero,
        ));
        _startPlayback();
      }
    } catch (e) {
      _currentId = null;
      emit(AudioErrorState(messageId: event.messageId, error: e.toString()));
    }
  }

  /// Frees the currently held blob: URL (if any).
  void _revokeBlob() {
    final b = _blobUrl;
    if (b != null) {
      revokeBlobUrl(b);
      _blobUrl = null;
    }
  }

  /// Fire-and-forget play. We never await the [AudioPlayer.play] future because
  /// it only completes when playback *finishes* (awaiting it would freeze the UI
  /// on the loading state). Errors (e.g. a browser autoplay-policy rejection) are
  /// swallowed rather than surfaced, since they don't affect the loaded state.
  void _startPlayback() {
    _player.play().catchError((_) {});
  }

  Future<void> _onPause(
    AudioPauseRequested event,
    Emitter<AudioState> emit,
  ) async {
    if (_currentId != event.messageId) return;
    await _player.pause();
    final s = state;
    if (s is AudioPlayingState && s.messageId == event.messageId) {
      emit(AudioPausedState(
        messageId: event.messageId,
        position: _player.position,
        duration: s.duration,
      ));
    }
  }

  Future<void> _onSeek(
    AudioSeekRequested event,
    Emitter<AudioState> emit,
  ) async {
    if (_currentId != event.messageId) return;
    await _player.seek(event.position);
    final dur = _player.duration ?? Duration.zero;
    final s = state;
    if (s is AudioPlayingState && s.messageId == event.messageId) {
      emit(AudioPlayingState(
        messageId: event.messageId,
        position: event.position,
        duration: dur,
      ));
    } else if (s is AudioPausedState && s.messageId == event.messageId) {
      emit(AudioPausedState(
        messageId: event.messageId,
        position: event.position,
        duration: dur,
      ));
    }
  }

  void _onPositionChanged(
    AudioPlaybackPositionChanged event,
    Emitter<AudioState> emit,
  ) {
    final s = state;
    // Only the actively-playing message advances.
    if (s is AudioPlayingState && s.messageId == event.messageId) {
      emit(AudioPlayingState(
        messageId: event.messageId,
        position: event.position,
        duration:
            event.duration == Duration.zero ? s.duration : event.duration,
      ));
    }
  }

  Future<void> _onCompleted(
    AudioPlaybackCompleted event,
    Emitter<AudioState> emit,
  ) async {
    await _player.pause();
    await _player.seek(Duration.zero);
    _currentId = null;
    emit(const AudioIdleState());
  }

  void _onError(AudioPlaybackError event, Emitter<AudioState> emit) {
    _currentId = null;
    emit(AudioErrorState(messageId: event.messageId, error: event.error));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pause when the app is backgrounded/hidden.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      final id = _currentId;
      if (id != null && _player.playing) add(AudioPauseRequested(id));
    }
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _posSub?.cancel();
    _stateSub?.cancel();
    _revokeBlob();
    _player.dispose();
    return super.close();
  }
}
