import 'dart:async';
import 'dart:js_interop';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:web/web.dart' as web;

@JS('fetch')
external JSPromise<web.Response> _fetch(JSString url);

/// Decoded waveform of a voice message: the true [durationSeconds] (read from
/// the decoded buffer, which is reliable even when the webm container has no
/// duration header) plus [bars] — normalized 0..1 amplitudes for the bar UI.
class WaveformData {
  final double durationSeconds;
  final List<double> bars;
  const WaveformData(this.durationSeconds, this.bars);
}

/// Decodes audio clips into a Telegram-style amplitude waveform using the
/// browser's Web Audio API. Results are cached per-url and concurrent requests
/// for the same url share a single decode. Web-only (uses `package:web`).
class AudioWaveform {
  AudioWaveform._();

  /// How many bars a waveform is reduced to.
  static const int barCount = 44;

  static final Map<String, WaveformData> _cache = {};
  static final Map<String, Future<WaveformData?>> _inflight = {};

  /// Returns an already-decoded waveform for [url], or null if not decoded yet.
  static WaveformData? cachedOf(String url) => _cache[url];

  /// Fetches and decodes [url] into a [WaveformData]. Returns null when the
  /// bytes can't be fetched or decoded (e.g. the media server blocks CORS) so
  /// callers can fall back gracefully without breaking playback.
  static Future<WaveformData?> load(String url) {
    if (url.isEmpty) return Future.value(null);
    final cached = _cache[url];
    if (cached != null) return Future.value(cached);
    return _inflight[url] ??=
        _decode(url).whenComplete(() => _inflight.remove(url));
  }

  static Future<WaveformData?> _decode(String url) async {
    web.AudioContext? ctx;
    try {
      final resp = await _fetch(url.toJS).toDart;
      final buffer = await resp.arrayBuffer().toDart;
      ctx = web.AudioContext();
      final audio = await ctx.decodeAudioData(buffer).toDart;
      final channel = audio.getChannelData(0).toDart;
      final data = WaveformData(audio.duration, _downsample(channel, barCount));
      _cache[url] = data;
      return data;
    } catch (_) {
      return null;
    } finally {
      try {
        ctx?.close();
      } catch (_) {}
    }
  }

  /// Reduces raw PCM samples to [buckets] RMS amplitudes, normalized so the
  /// loudest bar is 1.0 (keeps quiet recordings visible).
  static List<double> _downsample(Float32List samples, int buckets) {
    if (samples.isEmpty) return List.filled(buckets, 0.0);
    final per = (samples.length / buckets).ceil();
    final out = List<double>.filled(buckets, 0.0);
    var maxAmp = 0.0;
    for (var b = 0; b < buckets; b++) {
      final start = b * per;
      if (start >= samples.length) break;
      final end = math.min(start + per, samples.length);
      var sum = 0.0;
      for (var i = start; i < end; i++) {
        sum += samples[i] * samples[i];
      }
      final amp = math.sqrt(sum / (end - start));
      out[b] = amp;
      if (amp > maxAmp) maxAmp = amp;
    }
    if (maxAmp > 0) {
      for (var i = 0; i < buckets; i++) {
        out[i] = (out[i] / maxAmp).clamp(0.0, 1.0);
      }
    }
    return out;
  }

  /// A deterministic, natural-looking fallback waveform derived from a message
  /// id. Used only when the real audio can't be decoded, so the bubble still
  /// looks like a voice message instead of a flat bar.
  static List<double> pseudoBars(int seed, [int buckets = barCount]) {
    final rnd = math.Random(seed == 0 ? 1 : seed);
    return List<double>.generate(buckets, (i) {
      // Blend a slow envelope with jitter for an organic shape.
      final envelope = 0.5 + 0.4 * math.sin(i / buckets * math.pi * 3);
      final jitter = rnd.nextDouble() * 0.5;
      return (0.25 + envelope * 0.4 + jitter * 0.35).clamp(0.15, 1.0);
    });
  }
}
