import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/audio_waveform.dart';
import '../bloc/audio/audio_bloc.dart';
import '../bloc/audio/audio_event.dart';
import '../bloc/audio/audio_state.dart';

/// Telegram-style inline voice message: a play/pause button, an amplitude
/// waveform that reflects the recording's actual rhythm, and a duration label —
/// all inside the chat bubble. Playback is driven by [AudioBloc] (a single
/// active audio for the whole screen).
///
/// The waveform + true duration are decoded from the audio bytes via the Web
/// Audio API ([AudioWaveform]). If that fails (e.g. CORS) it degrades to a
/// deterministic pseudo-waveform so the bubble still looks right and playback
/// keeps working.
class VoiceMessageWidget extends StatefulWidget {
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

  @override
  State<VoiceMessageWidget> createState() => _VoiceMessageWidgetState();
}

class _VoiceMessageWidgetState extends State<VoiceMessageWidget> {
  String get _resolvedUrl => ApiConstants.resolveMediaUrl(widget.url);

  WaveformData? _waveform;
  late List<double> _bars;

  @override
  void initState() {
    super.initState();
    // Fallback bars are stable per message, so the shape doesn't change once
    // the real waveform decodes in.
    _bars = AudioWaveform.pseudoBars(widget.messageId);
    _waveform = AudioWaveform.cachedOf(_resolvedUrl);
    if (_waveform != null) _bars = _waveform!.bars;
    _loadWaveform();
  }

  @override
  void didUpdateWidget(VoiceMessageWidget old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url || old.messageId != widget.messageId) {
      _bars = AudioWaveform.pseudoBars(widget.messageId);
      _waveform = AudioWaveform.cachedOf(_resolvedUrl);
      if (_waveform != null) _bars = _waveform!.bars;
      _loadWaveform();
    }
  }

  Future<void> _loadWaveform() async {
    if (_waveform != null) return;
    final url = _resolvedUrl;
    if (url.isEmpty) return;
    final data = await AudioWaveform.load(url);
    if (!mounted || data == null) return;
    setState(() {
      _waveform = data;
      _bars = data.bars;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pending = _resolvedUrl.isEmpty;
    return RepaintBoundary(
      child: BlocSelector<AudioBloc, AudioState, _VoiceUiState>(
        selector: (state) => _select(state, widget.messageId),
        builder: (context, ui) {
          // Both bubbles now have a light background (mine = light green,
          // theirs = white), so voice controls use the same green accents.
          const accent = AppColors.primary;
          const onAccent = Colors.white;
          const trackColor = Color(0xFFB9E8D7);

          // Prefer the decoded duration (reliable for webm); fall back to what
          // the player reports.
          final decoded = _waveform?.durationSeconds;
          final total = (decoded != null && decoded > 0)
              ? Duration(milliseconds: (decoded * 1000).round())
              : ui.duration;
          final pos = ui.position;
          final isActive = ui.status == _PlayStatus.playing ||
              ui.status == _PlayStatus.paused;

          final hasDuration = total.inMilliseconds > 0 && total.inHours < 24;
          final progress = hasDuration
              ? (pos.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0)
              : 0.0;

          final String label;
          if (ui.status == _PlayStatus.error) {
            label = 'Xatolik';
          } else if (hasDuration) {
            // Count remaining while playing, show total length at rest.
            label = _fmt(isActive ? (total - pos) : total);
          } else if (isActive) {
            label = _fmt(pos);
          } else {
            label = 'Ovozli xabar';
          }

          return ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 240, maxWidth: 290),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 12, 8),
              child: Row(
                children: [
                  _PlayButton(
                    status: ui.status,
                    accent: accent,
                    onAccent: onAccent,
                    pending: pending,
                    onTap: pending ? null : () => _onTap(context, ui.status),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Waveform(
                          bars: _bars,
                          progress: progress,
                          playedColor: accent,
                          trackColor: trackColor,
                          enabled: isActive && hasDuration,
                          onSeek: (fraction) =>
                              context.read<AudioBloc>().add(
                                    AudioSeekRequested(
                                      messageId: widget.messageId,
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
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF94A3B8),
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
      bloc.add(AudioPauseRequested(widget.messageId));
    } else {
      bloc.add(AudioPlayRequested(
        messageId: widget.messageId,
        audioUrl: _resolvedUrl,
      ));
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
          width: 38,
          height: 38,
          child: showSpinner
              ? Padding(
                  padding: const EdgeInsets.all(10),
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
                  size: 24,
                ),
        ),
      ),
    );
  }
}

/// Seekable amplitude waveform. Bars left of [progress] use [playedColor], the
/// rest [trackColor]. Dragging/tapping reports the tapped fraction via [onSeek]
/// when [enabled].
class _Waveform extends StatelessWidget {
  final List<double> bars;
  final double progress;
  final Color playedColor;
  final Color trackColor;
  final bool enabled;
  final ValueChanged<double> onSeek;

  const _Waveform({
    required this.bars,
    required this.progress,
    required this.playedColor,
    required this.trackColor,
    required this.enabled,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        void seek(double dx) => onSeek((dx / width).clamp(0.0, 1.0));
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: enabled ? (d) => seek(d.localPosition.dx) : null,
          onHorizontalDragUpdate:
              enabled ? (d) => seek(d.localPosition.dx) : null,
          child: SizedBox(
            height: 30,
            width: double.infinity,
            child: CustomPaint(
              painter: _WaveformPainter(
                bars: bars,
                progress: progress,
                playedColor: playedColor,
                trackColor: trackColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final Color playedColor;
  final Color trackColor;

  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.playedColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final n = bars.length;
    if (n == 0) return;

    const gap = 2.0;
    final barW = ((size.width - gap * (n - 1)) / n).clamp(1.5, 4.0);
    const minH = 3.0;
    final progressX = size.width * progress;
    final paint = Paint()..style = PaintingStyle.fill;
    final radius = Radius.circular(barW / 2);

    for (var i = 0; i < n; i++) {
      final x = i * (barW + gap);
      final h = (minH + bars[i] * (size.height - minH)).clamp(minH, size.height);
      final top = (size.height - h) / 2;
      final centerX = x + barW / 2;
      paint.color = centerX <= progressX ? playedColor : trackColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, top, barW, h), radius),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress ||
      old.playedColor != playedColor ||
      old.trackColor != trackColor ||
      !identical(old.bars, bars);
}
