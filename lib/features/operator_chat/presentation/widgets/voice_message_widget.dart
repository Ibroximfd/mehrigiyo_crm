import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/audio/audio_bloc.dart';
import '../bloc/audio/audio_event.dart';
import '../bloc/audio/audio_state.dart';

/// Telegram-style inline voice message: a play/pause button, a seekable
/// progress bar and a duration label, all inside the chat bubble. Playback is
/// driven entirely by [AudioBloc] (single active audio for the whole screen),
/// so this is a pure [StatelessWidget].
class VoiceMessageWidget extends StatelessWidget {
  final int messageId;
  final String url;
  final bool isMine;
  final String? fileName;

  const VoiceMessageWidget({
    super.key,
    required this.messageId,
    required this.url,
    required this.isMine,
    this.fileName,
  });

  String get _resolvedUrl => ApiConstants.resolveMediaUrl(url);

  @override
  Widget build(BuildContext context) {
    final pending = _resolvedUrl.isEmpty;

    return RepaintBoundary(
      child: BlocSelector<AudioBloc, AudioState, _VoiceUiState>(
        selector: (state) => _select(state, messageId),
        builder: (context, ui) {
          // Colors adapt to bubble side.
          final accent = isMine ? Colors.white : AppColors.primary;
          final onAccent = isMine ? AppColors.primary : Colors.white;
          final trackColor = isMine
              ? Colors.white.withValues(alpha: 0.30)
              : const Color(0xFFD1FAE5);

          final total = ui.duration;
          final pos = ui.position;
          final isActive = ui.status == _PlayStatus.playing ||
              ui.status == _PlayStatus.paused;

          // webm recordings from MediaRecorder carry no duration header, so the
          // browser reports it as 0/Infinity. Treat anything outside a sane
          // range as "unknown" and fall back to an elapsed-time view.
          final hasDuration =
              total.inMilliseconds > 0 && total.inHours < 24;

          final progress = hasDuration
              ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
              : null; // null → indeterminate bar while playing

          // With a known length: remaining while active, total at rest.
          // Without one: just count elapsed seconds up.
          final String label;
          if (ui.status == _PlayStatus.error) {
            label = 'Xatolik';
          } else if (hasDuration) {
            label = _fmt(isActive ? (total - pos) : total);
          } else if (isActive) {
            label = _fmt(pos);
          } else {
            label = 'Ovozli xabar';
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 220, maxWidth: 280),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 6),
              child: Row(
                children: [
                  _PlayButton(
                    status: ui.status,
                    accent: accent,
                    onAccent: onAccent,
                    pending: pending,
                    onTap: pending
                        ? null
                        : () => _onTap(context, ui.status),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ProgressBar(
                          // Indeterminate while playing an unknown-length clip.
                          progress: progress ??
                              (ui.status == _PlayStatus.playing ? null : 0.0),
                          accent: accent,
                          trackColor: trackColor,
                          enabled: isActive && hasDuration,
                          onSeek: (fraction) =>
                              context.read<AudioBloc>().add(
                                    AudioSeekRequested(
                                      messageId: messageId,
                                      position: Duration(
                                        milliseconds:
                                            (total.inMilliseconds * fraction)
                                                .round(),
                                      ),
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: isMine
                                ? Colors.white70
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onTap(BuildContext context, _PlayStatus status) {
    final bloc = context.read<AudioBloc>();
    if (status == _PlayStatus.playing) {
      bloc.add(AudioPauseRequested(messageId));
    } else {
      bloc.add(AudioPlayRequested(messageId: messageId, audioUrl: _resolvedUrl));
    }
  }

  /// Maps the global [AudioState] to just this message's slice of UI state, so
  /// BlocSelector only rebuilds this widget when its own state changes.
  static _VoiceUiState _select(AudioState state, int id) {
    switch (state) {
      case AudioLoadingState(:final messageId) when messageId == id:
        return const _VoiceUiState(status: _PlayStatus.loading);
      case AudioPlayingState(:final messageId, :final position, :final duration)
          when messageId == id:
        return _VoiceUiState(
          status: _PlayStatus.playing,
          position: position,
          duration: duration,
        );
      case AudioPausedState(:final messageId, :final position, :final duration)
          when messageId == id:
        return _VoiceUiState(
          status: _PlayStatus.paused,
          position: position,
          duration: duration,
        );
      case AudioErrorState(:final messageId) when messageId == id:
        return const _VoiceUiState(status: _PlayStatus.error);
      default:
        return const _VoiceUiState(status: _PlayStatus.idle);
    }
  }

  static String _fmt(Duration d) {
    if (d.isNegative) d = Duration.zero;
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

enum _PlayStatus { idle, loading, playing, paused, error }

class _VoiceUiState extends Equatable {
  final _PlayStatus status;
  final Duration position;
  final Duration duration;

  const _VoiceUiState({
    required this.status,
    this.position = Duration.zero,
    this.duration = Duration.zero,
  });

  @override
  List<Object?> get props => [status, position, duration];
}

class _PlayButton extends StatelessWidget {
  final _PlayStatus status;
  final Color accent;
  final Color onAccent;
  final bool pending;
  final VoidCallback? onTap;

  const _PlayButton({
    required this.status,
    required this.accent,
    required this.onAccent,
    required this.pending,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final showSpinner = pending || status == _PlayStatus.loading;
    return Material(
      color: accent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 36,
          height: 36,
          child: showSpinner
              ? Padding(
                  padding: const EdgeInsets.all(9),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: onAccent,
                  ),
                )
              : Icon(
                  status == _PlayStatus.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: onAccent,
                  size: 22,
                ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  /// null → indeterminate (unknown-length clip while playing).
  final double? progress;
  final Color accent;
  final Color trackColor;
  final bool enabled;
  final ValueChanged<double> onSeek;

  const _ProgressBar({
    required this.progress,
    required this.accent,
    required this.trackColor,
    required this.enabled,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled
              ? (d) => onSeek((d.localPosition.dx / width).clamp(0.0, 1.0))
              : null,
          onHorizontalDragUpdate: enabled
              ? (d) => onSeek((d.localPosition.dx / width).clamp(0.0, 1.0))
              : null,
          child: SizedBox(
            height: 14,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: trackColor,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
