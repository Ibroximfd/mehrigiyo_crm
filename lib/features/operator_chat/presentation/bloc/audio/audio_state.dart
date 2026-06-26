import 'package:equatable/equatable.dart';

/// States for [AudioBloc]. Only ONE audio is ever active, so the state carries
/// the [messageId] it applies to; every other voice message is implicitly idle.
sealed class AudioState extends Equatable {
  const AudioState();

  @override
  List<Object?> get props => [];
}

/// No audio is playing or buffered.
class AudioIdleState extends AudioState {
  const AudioIdleState();
}

/// [messageId] is buffering before playback starts.
class AudioLoadingState extends AudioState {
  final int messageId;
  const AudioLoadingState(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

/// [messageId] is currently playing.
class AudioPlayingState extends AudioState {
  final int messageId;
  final Duration position;
  final Duration duration;
  const AudioPlayingState({
    required this.messageId,
    required this.position,
    required this.duration,
  });

  @override
  List<Object?> get props => [messageId, position, duration];
}

/// [messageId] is paused at [position].
class AudioPausedState extends AudioState {
  final int messageId;
  final Duration position;
  final Duration duration;
  const AudioPausedState({
    required this.messageId,
    required this.position,
    required this.duration,
  });

  @override
  List<Object?> get props => [messageId, position, duration];
}

/// Playback of [messageId] failed.
class AudioErrorState extends AudioState {
  final int messageId;
  final String error;
  const AudioErrorState({required this.messageId, required this.error});

  @override
  List<Object?> get props => [messageId, error];
}
