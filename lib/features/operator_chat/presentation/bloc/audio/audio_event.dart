import 'package:equatable/equatable.dart';

/// Events for [AudioBloc]. A single bloc drives every voice message in the chat
/// screen, so every event carries the [messageId] it refers to.
sealed class AudioEvent extends Equatable {
  const AudioEvent();

  @override
  List<Object?> get props => [];
}

/// Start (or resume) playback of [audioUrl] for [messageId]. If a different
/// message is currently playing it is stopped first.
class AudioPlayRequested extends AudioEvent {
  final int messageId;
  final String audioUrl;
  const AudioPlayRequested({required this.messageId, required this.audioUrl});

  @override
  List<Object?> get props => [messageId, audioUrl];
}

/// Pause playback of [messageId] at its current position.
class AudioPauseRequested extends AudioEvent {
  final int messageId;
  const AudioPauseRequested(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Seek [messageId] to [position].
class AudioSeekRequested extends AudioEvent {
  final int messageId;
  final Duration position;
  const AudioSeekRequested({required this.messageId, required this.position});

  @override
  List<Object?> get props => [messageId, position];
}

/// Emitted internally from the player's position stream (throttled ~200ms).
class AudioPlaybackPositionChanged extends AudioEvent {
  final int messageId;
  final Duration position;
  final Duration duration;
  const AudioPlaybackPositionChanged({
    required this.messageId,
    required this.position,
    required this.duration,
  });

  @override
  List<Object?> get props => [messageId, position, duration];
}

/// Emitted internally when playback reaches the end.
class AudioPlaybackCompleted extends AudioEvent {
  final int messageId;
  const AudioPlaybackCompleted(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// Emitted internally when playback fails.
class AudioPlaybackError extends AudioEvent {
  final int messageId;
  final String error;
  const AudioPlaybackError({required this.messageId, required this.error});

  @override
  List<Object?> get props => [messageId, error];
}
