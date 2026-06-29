import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:just_audio/just_audio.dart';

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
        _startPlayback(event.messageId);
        return;
      }

      // A different (or fresh) message → buffer the new source and play.
      if (_currentId != event.messageId) {
        _currentId = event.messageId;
        emit(AudioLoadingState(event.messageId));
        debugPrint('[CHAT-DEBUG] AudioBloc.setUrl id=${event.messageId} '
            'url=${event.audioUrl}');

        // WEB AUTOPLAY: the browser only allows play() while a user gesture is
        // still "active". Awaiting setUrl (a network round-trip) ends that
        // gesture, so a play() afterwards is blocked (NotAllowedError) on sites
        // with low media-engagement (i.e. production, but not localhost). To
        // keep the gesture alive we kick off the load and call play() in the
        // SAME synchronous turn — before any await. setUrl replaces the current
        // source on its own, so the explicit stop()/seek() are not needed.
        final loadFuture = _player.setUrl(event.audioUrl);
        _startPlayback(event.messageId);

        final loaded = await loadFuture;
        debugPrint('[CHAT-DEBUG] AudioBloc.setUrl OK id=${event.messageId} '
            'duration=$loaded');
        // Still the active message? (a newer tap may have superseded us.)
        if (_currentId != event.messageId) return;
        emit(AudioPlayingState(
          messageId: event.messageId,
          position: _player.position,
          duration: loaded ?? _player.duration ?? Duration.zero,
        ));
      } else {
        emit(AudioPlayingState(
          messageId: event.messageId,
          position: _player.position,
          duration: _player.duration ?? Duration.zero,
        ));
        _startPlayback(event.messageId);
      }
    } catch (e, st) {
      debugPrint('[CHAT-DEBUG] AudioBloc PLAY ERROR id=${event.messageId} '
          'url=${event.audioUrl}\n  error=$e\n  $st');
      _currentId = null;
      emit(AudioErrorState(messageId: event.messageId, error: e.toString()));
    }
  }

  /// Fire-and-forget play with diagnostics. On web, `play()` rejects with a
  /// NotAllowedError when the browser's autoplay policy blocks playback (the
  /// user gesture was consumed by the awaited setUrl). We log that so the cause
  /// is visible instead of silently swallowed.
  void _startPlayback(int messageId) {
    _player.play().then((_) {
      debugPrint('[CHAT-DEBUG] play() finished id=$messageId '
          'pos=${_player.position} playing=${_player.playing}');
    }).catchError((e) {
      debugPrint('[CHAT-DEBUG] play() REJECTED id=$messageId error=$e');
    });
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
    _player.dispose();
    return super.close();
  }
}
