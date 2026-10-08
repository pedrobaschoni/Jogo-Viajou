import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Chuva de confete em loop.
class Confetti extends StatefulWidget {
  final int count;
  const Confetti({super.key, this.count = 90});

  @override
  State<Confetti> createState() => _ConfettiState();
}

class _Bit {
  final double x, delay, speed, sway, size, spin;
  final Color color;
  const _Bit(this.x, this.delay, this.speed, this.sway, this.size, this.spin, this.color);
}

class _ConfettiState extends State<Confetti> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 7))..repeat();
  late final List<_Bit> _bits;

  @override
  void initState() {
    super.initState();
    final r = Random();
    const colors = [C.pink, C.sun, C.mint, C.sky, C.lilac, C.orange, C.cream];
    _bits = List.generate(
      widget.count,
      (_) => _Bit(
        r.nextDouble(),
        r.nextDouble(),
        0.6 + r.nextDouble() * 0.8,
        r.nextDouble() * 2 - 1,
        6 + r.nextDouble() * 8,
        r.nextDouble() * 10 - 5,
        colors[r.nextInt(colors.length)],
      ),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(painter: _ConfettiPainter(_c, _bits), size: Size.infinite),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final Animation<double> anim;
  final List<_Bit> bits;
  _ConfettiPainter(this.anim, this.bits) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint();
    for (final b in bits) {
      final t = (anim.value * b.speed + b.delay) % 1.0;
      final y = -20 + t * (size.height + 40);
      final x = b.x * size.width + sin(t * pi * 4 + b.sway * 3) * 30 * b.sway;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(t * b.spin * pi);
      p.color = b.color;
      final squash = cos(t * pi * 6 + b.sway).abs();
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: b.size, height: b.size * 0.55 * (0.3 + 0.7 * squash)),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => false;
}
