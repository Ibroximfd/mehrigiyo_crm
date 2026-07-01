import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_constants.dart';

/// Circular chat avatar. Shows a cached network image when [avatarUrl] is set,
/// otherwise a colourful gradient disc with the name's first letter.
///
/// The gradient is derived deterministically from [name] so the same person
/// always gets the same colour.
class ChatAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;

  const ChatAvatar({
    super.key,
    required this.avatarUrl,
    required this.name,
    this.radius = 24,
  });

  static const List<List<Color>> _gradients = [
    [Color(0xFF2AABEE), Color(0xFF229ED9)], // telegram blue
    [Color(0xFF0D6A55), Color(0xFF1AAB87)], // app green
    [Color(0xFFF59E0B), Color(0xFFEF8B08)], // amber
    [Color(0xFFEC4899), Color(0xFFDB2777)], // pink
    [Color(0xFF8B5CF6), Color(0xFF7C3AED)], // violet
    [Color(0xFF14B8A6), Color(0xFF0D9488)], // teal
    [Color(0xFFEF4444), Color(0xFFDC2626)], // red
  ];

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : '?';
    final gradient = _gradients[name.hashCode.abs() % _gradients.length];

    final fallback = Container(
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
          fontSize: radius * 0.8,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );

    if (!hasUrl) return fallback;

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: ApiConstants.resolveMediaUrl(avatarUrl!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => fallback,
        errorWidget: (_, _, _) => fallback,
      ),
    );
  }
}
