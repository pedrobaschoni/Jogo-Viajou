import 'dart:math';

import 'package:flutter/material.dart';

import '../data/questions.dart';
import '../models.dart';
import '../sfx.dart';
import '../theme.dart';
import 'common.dart';

/// A carta da pergunta. Cai na mesa virada e gira em 3D para mostrar a frente.
class QuestionCard extends StatefulWidget {
  final Question q;
  final int index;
  final int total;
  final bool compact;

  const QuestionCard({
    super.key,
    required this.q,
    required this.index,
    required this.total,
    this.compact = false,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1150));

  @override
  void initState() {
    super.initState();
    _deal();
  }

  void _deal() {
    _c.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 380), () {
      if (mounted) Sfx.play('flip', volume: 0.8);
    });
  }

  @override
  void didUpdateWidget(covariant QuestionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.q.id != widget.q.id || oldWidget.index != widget.index) _deal();
  }

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
        final drop = Curves.easeOutBack.transform(const Interval(0.0, 0.42).transform(v));
        final flip = Curves.easeInOutCubic.transform(const Interval(0.36, 1.0).transform(v));
        final angle = (1 - flip) * pi;
        final showFront = angle < pi / 2;
        final face = showFront
            ? _front()
            : Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(pi),
                child: _back(),
              );
        return Transform.translate(
          offset: Offset(0, (1 - drop) * -320),
          child: Transform.rotate(
            angle: (1 - drop) * -0.3 + sin(flip * pi) * 0.04,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: face,
            ),
          ),
        );
      },
    );
  }

  Widget _front() {
    final q = widget.q;
    final cat = q.author != null ? familyCat : catOf(q.cat);
    final compact = widget.compact;
    final unitText = q.isYear
        ? 'RESPOSTA: UM ANO'
        : q.unit.isEmpty
            ? 'RESPOSTA: UM NÚMERO'
            : 'RESPOSTA EM ${q.unit.toUpperCase()}';
    return Container(
      decoration: inkBox(color: C.cream, radius: 26, shadow: 7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: cat.color,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 8 : 11),
              child: Row(children: [
                Icon(cat.icon, color: C.ink, size: compact ? 18 : 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cat.name.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: display(compact ? 15 : 17, color: C.ink, letterSpacing: 1),
                  ),
                ),
                Text('${widget.index + 1}/${widget.total}', style: display(compact ? 15 : 17, color: C.ink)),
              ]),
            ),
            Container(height: 3, color: C.ink),
            Expanded(
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    bottom: -22,
                    child: Transform.rotate(
                      angle: -0.25,
                      child: Icon(cat.icon, size: 130, color: cat.color.withValues(alpha: 0.22)),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, compact ? 8 : 14, 18, 6),
                    child: LayoutBuilder(
                      builder: (context, cons) => Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: cons.maxWidth,
                            child: Text(
                              q.text,
                              textAlign: TextAlign.center,
                              style: body(compact ? 22 : 27, weight: FontWeight.w900, height: 1.18),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (q.author != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Pergunta de ${q.author}: essa pessoa sabe a resposta!',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: body(12.5, color: C.muted, weight: FontWeight.w800),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(top: 6, bottom: compact ? 10 : 14),
              child: Center(child: Pill(unitText, size: compact ? 11.5 : 13)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _back() {
    return Container(
      decoration: inkBox(color: C.pink, radius: 26, shadow: 7),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _BackPattern())),
            Center(
              child: Transform.rotate(
                angle: -0.12,
                child: StrokeText('VIAJOU!', size: widget.compact ? 40 : 52, fill: C.cream, shadow: C.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackPattern extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = const Color(0xFFE23C76);
    const step = 34.0;
    var row = 0;
    for (var y = 0.0; y < size.height + step; y += step) {
      final off = row.isEven ? 0.0 : step / 2;
      for (var x = -step; x < size.width + step; x += step) {
        final c = Offset(x + off, y);
        final path = Path();
        for (var i = 0; i < 8; i++) {
          final a = -pi / 2 + i * pi / 4;
          final r = i.isEven ? 7.0 : 2.6;
          final pt = c + Offset(cos(a) * r, sin(a) * r);
          if (i == 0) {
            path.moveTo(pt.dx, pt.dy);
          } else {
            path.lineTo(pt.dx, pt.dy);
          }
        }
        path.close();
        canvas.drawPath(path, p);
      }
      row++;
    }
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = C.cream.withValues(alpha: 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(12, 12, size.width - 24, size.height - 24), const Radius.circular(16)),
      border,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
