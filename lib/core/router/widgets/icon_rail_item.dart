import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'notification_badge.dart';

class IconRailItem extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const IconRailItem({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  State<IconRailItem> createState() => _IconRailItemState();
}

class _IconRailItemState extends State<IconRailItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      preferBelow: false,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.gold.withValues(alpha: 0.18)
                      : _hovered
                      ? Colors.white.withValues(alpha: 0.07)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColors.gold.withValues(alpha: 0.45)
                        : Colors.transparent,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.isSelected
                      ? AppColors.gold
                      : Colors.white.withValues(alpha: 0.65),
                  size: 20,
                ),
              ),
              if (widget.badgeCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: NotificationBadge(count: widget.badgeCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
