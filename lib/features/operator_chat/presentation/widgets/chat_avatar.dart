import 'dart:ui_web' as ui;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../../../core/constants/api_constants.dart';

// Dedup registered HtmlElementView factories (same URL → same view id).
final _registeredAvatarViews = <String>{};

/// Circular chat avatar. Shows the profile photo when [avatarUrl] is set,
/// otherwise a colourful gradient disc with the name's first letter.
///
/// On Flutter web (CanvasKit) cross-origin images fail to decode without CORS
/// headers, so — like the rest of the chat ([_ImageAttachment]) — we try
/// [Image.network] first and fall back to a plain HTML `<img>` element (which
/// loads cross-origin images fine) when that fails.
class ChatAvatar extends StatefulWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const ChatAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24,
  });

  @override
  State<ChatAvatar> createState() => _ChatAvatarState();
}

class _ChatAvatarState extends State<ChatAvatar> {
  // true once Image.network fails (CORS) → switch to an HTML <img>.
  bool _htmlFallback = false;

  static const List<List<Color>> _gradients = [
    [Color(0xFF2AABEE), Color(0xFF229ED9)], // telegram blue
    [Color(0xFF0D6A55), Color(0xFF1AAB87)], // app green
    [Color(0xFFF59E0B), Color(0xFFEF8B08)], // amber
    [Color(0xFFEC4899), Color(0xFFDB2777)], // pink
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // violet
    [Color(0xFF14B8A6), Color(0xFF0D9488)], // teal
    [Color(0xFFEF4444), Color(0xFFDC2626)], // red
  ];

  Widget _fallback(double size) {
    final initial =
        widget.name.trim().isNotEmpty ? widget.name.trim()[0].toUpperCase() : '?';
    final gradient =
        _gradients[widget.name.hashCode.abs() % _gradients.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: widget.radius * 0.8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Cross-origin-safe HTML `<img>`, made circular via CSS (platform views on
  /// web can't be reliably clipped by a Flutter ClipOval).
  Widget _htmlImg(String url, double size) {
    final viewId = 'avatar-${url.hashCode}';
    if (!_registeredAvatarViews.contains(viewId)) {
      _registeredAvatarViews.add(viewId);
      ui.platformViewRegistry.registerViewFactory(
        viewId,
        (_) => web.HTMLImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'cover'
          ..style.borderRadius = '50%'
          ..style.pointerEvents = 'none',
      );
    }
    return SizedBox(
      width: size,
      height: size,
      child: HtmlElementView(viewType: viewId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.radius * 2;
    final hasUrl = widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty;
    if (!hasUrl) return _fallback(size);

    final url = ApiConstants.resolveMediaUrl(widget.avatarUrl!);
    if (_htmlFallback) return _htmlImg(url, size);

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Show the gradient while the image is still decoding.
        frameBuilder: (_, child, frame, wasSync) =>
            (frame == null && !wasSync) ? _fallback(size) : child,
        errorBuilder: (_, _, _) {
          // Canvas fetch failed (CORS) — switch to the HTML <img> next frame.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _htmlFallback = true);
          });
          return _fallback(size);
        },
      ),
    );
  }
}
