import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Animated equalizer bars. Bars settle down when [playing] is false.
class Equalizer extends StatefulWidget {
  final bool playing;
  final int bars;
  final double height;
  final double barWidth;
  const Equalizer({
    super.key,
    required this.playing,
    this.bars = 5,
    this.height = 24,
    this.barWidth = 4,
  });

  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  final _phases = List.generate(12, (i) => Random(i * 7).nextDouble() * pi * 2);

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(covariant Equalizer old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) _c.repeat();
    if (!widget.playing && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(widget.bars, (i) {
            final t = _c.value * 2 * pi;
            final v = widget.playing
                ? 0.25 + 0.75 * (0.5 + 0.5 * sin(t * (1 + i * 0.35) + _phases[i]))
                : 0.18;
            return Container(
              width: widget.barWidth,
              height: widget.height * v,
              margin: EdgeInsets.symmetric(horizontal: widget.barWidth * 0.35),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB37A), AppColors.accent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(widget.barWidth),
              ),
            );
          }),
        ),
      ),
    );
  }
}
