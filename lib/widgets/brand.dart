import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';
import 'common.dart';

/// Logo "VIAJOU!" com as letras pulando.
class Logo extends StatefulWidget {
  final double size;
  final bool animate;
  const Logo({super.key, this.size = 64, this.animate = true});

  @override
  State<Logo> createState() => _LogoState();
}

class _LogoState extends State<Logo> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  static const _letters = 'VIAJOU!';
  static const _fills = [C.cream, C.sun, C.cream, C.sun, C.cream, C.sun, C.pink];

  @override
  void initState() {
    super.initState();
    if (widget.animate) _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value * pi * 2;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (var i = 0; i < _letters.length; i++)
              Transform.translate(
                offset: Offset(0, widget.animate ? sin(t + i * 0.8) * s * 0.05 : 0),
                child: Transform.rotate(
                  angle: (widget.animate ? sin(t + i * 1.3) * 0.06 : 0) + (i.isEven ? -0.04 : 0.04),
                  child: StrokeText(_letters[i], size: s, fill: _fills[i], shadow: C.pink),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Mascote: uma capivara astronauta.
class Mascot extends StatefulWidget {
  final double size;
  final bool wave;
  const Mascot({super.key, this.size = 160, this.wave = true});

  @override
  State<Mascot> createState() => _MascotState();
}

class _MascotState extends State<Mascot> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = _c.value;
        final t = v * pi * 2;
        final blink = (v > 0.46 && v < 0.49) || (v > 0.92 && v < 0.95);
        return Transform.translate(
          offset: Offset(0, sin(t) * widget.size * 0.04),
          child: Transform.rotate(
            angle: sin(t * 0.5) * 0.06,
            child: CustomPaint(
              size: Size.square(widget.size),
              painter: _MascotPainter(blink: blink, arm: widget.wave ? sin(t * 2) * 0.35 : 0),
            ),
          ),
        );
      },
    );
  }
}

class _MascotPainter extends CustomPainter {
  final bool blink;
  final double arm;
  _MascotPainter({required this.blink, required this.arm});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 200);

    final ink = Paint()
      ..color = C.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    Paint fill(Color c) => Paint()..color = c;
    void both(Path path, Color c) {
      canvas.drawPath(path, fill(c));
      canvas.drawPath(path, ink);
    }

    Path rrect(double l, double t, double w, double h, double r) =>
        Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r)));
    Path circle(double x, double y, double r) => Path()..addOval(Rect.fromCircle(center: Offset(x, y), radius: r));

    const suit = Color(0xFFF1EEFB);
    const fur = Color(0xFFB07A45);
    const furDark = Color(0xFF8C5C30);

    // Mochila, corpo e braços.
    both(rrect(36, 120, 26, 52, 10), const Color(0xFFB9B2D6));
    both(rrect(52, 122, 96, 68, 32), suit);
    both(circle(100, 158, 11), C.pink);
    canvas.drawCircle(const Offset(100, 158), 4, fill(C.cream));
    both(rrect(40, 136, 24, 38, 12), suit);
    canvas.save();
    canvas.translate(146, 140);
    canvas.rotate(-0.9 + arm);
    both(rrect(-10, -40, 22, 44, 11), suit);
    both(circle(1, -42, 10), suit);
    canvas.restore();

    // Vidro do capacete (fundo).
    const hc = Offset(100, 82);
    canvas.drawCircle(hc, 66, fill(const Color(0x553FD0FF)));

    // Cabeça de capivara.
    both(circle(70, 50, 9), furDark);
    both(circle(92, 44, 8), furDark);
    both(rrect(56, 44, 82, 76, 32), fur);
    both(rrect(104, 72, 52, 46, 20), furDark);
    canvas.drawOval(Rect.fromCenter(center: const Offset(146, 86), width: 6, height: 10), fill(C.ink));
    final mouth = Paint()
      ..color = C.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(Path()..moveTo(126, 104)..quadraticBezierTo(136, 112, 146, 104), mouth);
    canvas.drawCircle(const Offset(84, 98), 7, fill(const Color(0x66FF4F8B)));
    if (blink) {
      canvas.drawLine(const Offset(90, 74), const Offset(106, 74), mouth);
    } else {
      canvas.drawCircle(const Offset(98, 72), 10, fill(Colors.white));
      canvas.drawCircle(const Offset(98, 72), 10, ink..strokeWidth = 3.5);
      canvas.drawCircle(const Offset(101, 73), 5, fill(C.ink));
      canvas.drawCircle(const Offset(103, 70), 1.8, fill(Colors.white));
      ink.strokeWidth = 5;
    }

    // Capacete (frente): contorno, brilho e gola.
    canvas.drawCircle(hc, 66, ink);
    canvas.drawArc(
      Rect.fromCircle(center: hc, radius: 54),
      pi * 1.1,
      pi * 0.35,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    both(rrect(66, 140, 68, 14, 7), const Color(0xFFB9B2D6));

    // Antena com estrelinha.
    canvas.drawLine(const Offset(100, 16), const Offset(100, 2), ink);
    final star = Path();
    for (var i = 0; i < 10; i++) {
      final a = -pi / 2 + i * pi / 5;
      final r = i.isEven ? 9.0 : 4.0;
      final pt = Offset(100 + cos(a) * r, 0 + sin(a) * r);
      if (i == 0) {
        star.moveTo(pt.dx, pt.dy);
      } else {
        star.lineTo(pt.dx, pt.dy);
      }
    }
    star.close();
    canvas.drawPath(star, fill(C.sun));
    canvas.drawPath(star, ink..strokeWidth = 3);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MascotPainter old) => old.blink != blink || old.arm != arm;
}
