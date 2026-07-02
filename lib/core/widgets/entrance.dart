import 'dart:async';
import 'package:flutter/material.dart';

/// One-shot fade + slide-up entrance for content appearing on screen.
///
/// Cheap by design: a single [AnimationController] driving Fade/Slide
/// transitions (compositor-friendly), played exactly once per widget life.
/// Use [delay] to stagger siblings — cap the stagger on long lists so late
/// items don't sit invisible (see [Entrance.staggered]).
class Entrance extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;

  /// Vertical offset the child slides in from, as a fraction of its height.
  final double slideFraction;

  const Entrance({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 320),
    this.slideFraction = 0.06,
  });

  /// Entrance for the [index]-th item of a list: 30ms stagger between items,
  /// capped after the first 12 so long lists appear without a long tail.
  factory Entrance.staggered({
    Key? key,
    required int index,
    required Widget child,
  }) {
    return Entrance(
      key: key,
      delay: Duration(milliseconds: 30 * index.clamp(0, 12)),
      child: child,
    );
  }

  @override
  State<Entrance> createState() => _EntranceState();
}

class _EntranceState extends State<Entrance>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, widget.slideFraction),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
