import 'package:flutter/material.dart';

/// Telegram-style chat wallpaper: a soft vertical gradient with a sparse,
/// faint doodle pattern painted once and cached.
///
/// Performance: the painter is `const`, [shouldRepaint] is always `false`, and
/// the whole thing is wrapped in a [RepaintBoundary] so it is rasterized once
/// and never repainted while messages scroll on top of it.
class ChatWallpaper extends StatelessWidget {
  const ChatWallpaper({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _WallpaperPainter(),
      ),
    );
  }
}

class _WallpaperPainter extends CustomPainter {
  const _WallpaperPainter();

  // Soft green-tinted paper, matching the app's primary palette.
  static const _top = Color(0xFFEAF3EE);
  static const _bottom = Color(0xFFDCEAE1);
  static const _doodle = Color(0x0A0D6A55); // ~4% primary green

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Base gradient.
    final bg = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [_top, _bottom],
      ).createShader(rect);
    canvas.drawRect(rect, bg);

    // Sparse doodle grid — faint rings + dots on a staggered lattice.
    final dot = Paint()
      ..color = _doodle
      ..style = PaintingStyle.fill;
    final ring = Paint()
      ..color = _doodle
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    const step = 64.0;
    var row = 0;
    for (double y = 24; y < size.height + step; y += step) {
      final offsetX = (row.isEven) ? 0.0 : step / 2;
      for (double x = 24 + offsetX; x < size.width + step; x += step) {
        if ((row + (x ~/ step)) % 3 == 0) {
          canvas.drawCircle(Offset(x, y), 9, ring);
        } else {
          canvas.drawCircle(Offset(x, y), 2.5, dot);
        }
      }
      row++;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
