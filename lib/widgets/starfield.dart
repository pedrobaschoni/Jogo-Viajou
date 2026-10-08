import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Céu noturno animado: estrelas piscando, um planeta com anel e uma lua.
class Starfield extends StatefulWidget {
  final Widget child;
  const Starfield({super.key, required this.child});

  @override
  State<Starfield> createState() => _StarfieldState();
}

class _Star {
  final double x, y, r, phase, speed;
  const _Star(this.x, this.y, this.r, this.phase, this.speed);
}

class _StarfieldState extends State<Starfield> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 90))..repeat();
    final r = Random(42);
    _stars = List.generate(
      130,
      (_) => _Star(r.nextDouble(), r.nextDouble(), r.nextDouble() * 1.5 + 0.5, r.nextDouble() * pi * 2,
          r.nextDouble() * 0.8 + 0.2),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(-0.5, -0.9),
                radius: 1.5,
                colors: [Color(0xFF3D1D80), C.space, Color(0xFF0A0520)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(painter: _SkyPainter(_c, _stars)),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _SkyPainter extends CustomPainter {
  final Animation<double> anim;
  final List<_Star> stars;
  _SkyPainter(this.anim, this.stars) : super(repaint: anim);

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    final p = Paint();

    // Planeta com anel, canto inferior direito.
    final pr = min(size.width, size.height) * 0.15;
    final pc = Offset(size.width * 0.93, size.height * 0.9);
    p.color = const Color(0xFF2A175E);
    canvas.drawCircle(pc, pr, p);
    p.color = const Color(0xFF3A2380);
    canvas.drawCircle(pc.translate(-pr * 0.22, -pr * 0.22), pr * 0.74, p);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = pr * 0.09
      ..color = C.pink.withValues(alpha: 0.55);
    canvas.save();
    canvas.translate(pc.dx, pc.dy);
    canvas.rotate(-0.35);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: pr * 3.1, height: pr * 0.8), ring);
    canvas.restore();

    // Lua, canto superior esquerdo.
    final mr = min(size.width, size.height) * 0.05;
    final mc = Offset(size.width * 0.1, size.height * 0.12);
    p.color = const Color(0xFFFFE9B0).withValues(alpha: 0.85);
    canvas.drawCircle(mc, mr, p);
    p.color = const Color(0xFFE8C77E).withValues(alpha: 0.7);
    canvas.drawCircle(mc.translate(-mr * 0.3, mr * 0.2), mr * 0.22, p);
    canvas.drawCircle(mc.translate(mr * 0.35, -mr * 0.3), mr * 0.14, p);

    // Estrelas.
    final sparkle = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (final s in stars) {
      final x = ((s.x + t * s.speed * 0.25) % 1.0) * size.width;
      final y = s.y * size.height;
      final tw = 0.3 + 0.7 * (0.5 + 0.5 * sin(t * pi * 2 * 30 * s.speed + s.phase));
      p.color = Colors.white.withValues(alpha: tw * 0.9);
      canvas.drawCircle(Offset(x, y), s.r, p);
      if (s.r > 1.75) {
        final l = s.r * 3.2 * tw;
        sparkle.color = Colors.white.withValues(alpha: tw * 0.7);
        canvas.drawLine(Offset(x - l, y), Offset(x + l, y), sparkle);
        canvas.drawLine(Offset(x, y - l), Offset(x, y + l), sparkle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SkyPainter oldDelegate) => false;
}

/// Base de toda tela: céu animado + área segura + coluna centralizada.
class PageFrame extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const PageFrame({super.key, required this.child, this.maxWidth = 560});

  @override
  Widget build(BuildContext context) {
    return Starfield(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
