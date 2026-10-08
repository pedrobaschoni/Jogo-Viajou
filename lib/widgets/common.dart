import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic.dart';
import '../models.dart';
import '../prefs.dart';
import '../sfx.dart';
import '../theme.dart';

/// Texto com contorno grosso de tinta (títulos estilo adesivo).
class StrokeText extends StatelessWidget {
  final String text;
  final double size;
  final Color fill;
  final Color stroke;
  final double? strokeWidth;
  final Color? shadow;
  final TextAlign align;

  const StrokeText(
    this.text, {
    super.key,
    required this.size,
    this.fill = C.cream,
    this.stroke = C.ink,
    this.strokeWidth,
    this.shadow,
    this.align = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    final base = display(size, color: null, height: 1.05);
    final sw = strokeWidth ?? size * 0.16;
    final sh = shadow;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = sw
      ..strokeJoin = StrokeJoin.round
      ..color = stroke;
    return Stack(
      children: [
        Text(
          text,
          textAlign: align,
          style: base.copyWith(
            foreground: strokePaint,
            shadows: sh == null ? null : [Shadow(color: sh, offset: Offset(0, size * 0.09))],
          ),
        ),
        Text(text, textAlign: align, style: base.copyWith(color: fill)),
      ],
    );
  }
}

/// Botão gordinho que afunda quando você aperta.
class ChunkyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double fontSize;
  final IconData? icon;
  final double? height;
  final bool expand;
  final bool sound;
  final double depth;
  final double radius;
  final EdgeInsets padding;

  const ChunkyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = C.sun,
    this.textColor = C.ink,
    this.fontSize = 22,
    this.icon,
    this.height,
    this.expand = false,
    this.sound = true,
    this.depth = 5,
    this.radius = 18,
    this.padding = const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
  });

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final d = widget.depth;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: widget.textColor, size: widget.fontSize * 1.05),
          if (widget.label.isNotEmpty) SizedBox(width: widget.fontSize * 0.35),
        ],
        if (widget.label.isNotEmpty)
          widget.expand
              ? Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(widget.label, maxLines: 1, style: display(widget.fontSize, color: widget.textColor)),
                  ),
                )
              : Text(widget.label, maxLines: 1, style: display(widget.fontSize, color: widget.textColor)),
      ],
    );
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: enabled ? () => _set(false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                if (widget.sound) Sfx.play('tap', volume: 0.6);
                widget.onTap!();
              }
            : null,
        child: Padding(
          padding: EdgeInsets.only(right: d, bottom: d),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 70),
            height: widget.height,
            transform: Matrix4.translationValues(_down ? d : 0, _down ? d : 0, 0),
            padding: widget.padding,
            alignment: widget.height != null || widget.expand ? Alignment.center : null,
            decoration: inkBox(
              color: enabled ? widget.color : C.disabled,
              radius: widget.radius,
              shadow: _down ? 0 : d,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

/// Botão redondo de ícone.
class RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final String? tooltip;

  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.color = C.cream,
    this.size = 44,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final b = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          width: size,
          height: size,
          decoration: inkBox(color: color, radius: size / 2, shadow: 3),
          child: Icon(icon, color: C.ink, size: size * 0.52),
        ),
      ),
    );
    return tooltip == null ? b : Tooltip(message: tooltip!, child: b);
  }
}

class MuteButton extends StatefulWidget {
  const MuteButton({super.key});
  @override
  State<MuteButton> createState() => _MuteButtonState();
}

class _MuteButtonState extends State<MuteButton> {
  @override
  Widget build(BuildContext context) {
    return RoundIconButton(
      icon: Sfx.muted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
      tooltip: Sfx.muted ? 'Ligar som' : 'Desligar som',
      onTap: () => setState(() {
        Sfx.muted = !Sfx.muted;
        Prefs.muted = Sfx.muted;
        if (!Sfx.muted) Sfx.play('tap');
      }),
    );
  }
}

/// Etiqueta arredondada.
class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color textColor;
  final double size;
  final IconData? icon;
  const Pill(this.text,
      {super.key, this.color = C.ink, this.textColor = C.cream, this.size = 14, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.85, vertical: size * 0.4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: C.ink, width: 2),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: size * 1.1, color: textColor), SizedBox(width: size * 0.3)],
        Text(text, style: display(size, color: textColor, letterSpacing: 0.8)),
      ]),
    );
  }
}

/// Mini carta com o número de cartas que a pessoa levou.
class CardBadge extends StatelessWidget {
  final int count;
  final double size;
  const CardBadge({super.key, required this.count, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
        child: child,
      ),
      child: Transform.rotate(
        key: ValueKey(count),
        angle: 0.12,
        child: Container(
          width: size,
          height: size * 1.3,
          alignment: Alignment.center,
          decoration: inkBox(
            color: count == 0 ? C.cream : C.pink,
            radius: size * 0.22,
            shadow: 2,
            border: 2,
          ),
          child: Text('$count', style: display(size * 0.62, color: count == 0 ? C.ink : C.cream)),
        ),
      ),
    );
  }
}

/// Avatar redondo do jogador.
class PlayerChip extends StatelessWidget {
  final Player p;
  final bool active;
  final bool isMe;
  final bool isHost;
  final double size;
  final bool showName;
  final bool showCards;
  final VoidCallback? onRemove;

  const PlayerChip({
    super.key,
    required this.p,
    this.active = false,
    this.isMe = false,
    this.isHost = false,
    this.size = 52,
    this.showName = true,
    this.showCards = true,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final color = playerColor(p.color);
    final avatar = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: active ? C.cream : C.ink, width: active ? 4 : 3),
        boxShadow: [
          active
              ? BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 22, spreadRadius: 2)
              : const BoxShadow(color: C.ink, offset: Offset(3, 3)),
        ],
      ),
      child: Text(p.initials, style: display(size * 0.4, color: C.ink)),
    );

    return AnimatedScale(
      scale: active ? 1.12 : 1.0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutBack,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              avatar,
              if (showCards)
                Positioned(right: -size * 0.14, bottom: -size * 0.06, child: CardBadge(count: p.cards.length, size: size * 0.4)),
              if (isHost)
                Positioned(
                  left: -size * 0.1,
                  top: -size * 0.16,
                  child: Transform.rotate(
                    angle: -0.4,
                    child: Icon(Icons.star_rounded, color: C.sun, size: size * 0.45,
                        shadows: const [Shadow(color: C.ink, offset: Offset(1.5, 1.5))]),
                  ),
                ),
              if (onRemove != null)
                Positioned(
                  right: -size * 0.16,
                  top: -size * 0.16,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      width: size * 0.42,
                      height: size * 0.42,
                      decoration: inkBox(color: C.cream, radius: size, shadow: 0, border: 2),
                      child: Icon(Icons.close_rounded, size: size * 0.28, color: C.ink),
                    ),
                  ),
                ),
            ],
          ),
          if (showName) ...[
            SizedBox(height: size * 0.16),
            SizedBox(
              width: size + 30,
              child: Text(
                isMe ? 'Você' : p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: body(12.5, color: active ? C.sun : C.cream, weight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Aviso flutuante estilo adesivo.
void toast(BuildContext context, String msg, {Color color = C.sun}) {
  final m = ScaffoldMessenger.maybeOf(context);
  if (m == null) return;
  m.hideCurrentSnackBar();
  m.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    padding: EdgeInsets.zero,
    duration: const Duration(milliseconds: 2800),
    content: Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 480),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: inkBox(color: color, radius: 16, shadow: 4),
        child: Text(msg, textAlign: TextAlign.center, style: body(15, weight: FontWeight.w800)),
      ),
    ),
  ));
}

/// Executa uma jogada e mostra o erro bonitinho se der problema.
Future<bool> runAct(BuildContext context, Future<void> Function() fn) async {
  try {
    await fn();
    return true;
  } on GameError catch (e) {
    Sfx.play('deny');
    if (context.mounted) toast(context, e.message);
  } catch (e) {
    debugPrint('Falha na jogada: $e');
    if (context.mounted) toast(context, 'Deu ruim na conexão. Tenta de novo!', color: C.pink);
  }
  return false;
}

/// Pergunta de sim/não estilizada.
Future<bool> confirmDialog(BuildContext context, String title, String message,
    {String yes = 'SIM', String no = 'NÃO'}) async {
  final r = await showDialog<bool>(
    context: context,
    barrierColor: C.ink.withValues(alpha: 0.7),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 16),
          decoration: inkBox(color: C.cream, radius: 26, shadow: 7),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(title, textAlign: TextAlign.center, style: display(28, color: C.ink)),
            const SizedBox(height: 10),
            Text(message, textAlign: TextAlign.center, style: body(16, weight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: ChunkyButton(
                  label: no,
                  color: C.cream2,
                  fontSize: 18,
                  expand: true,
                  onTap: () => Navigator.of(ctx).pop(false),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ChunkyButton(
                  label: yes,
                  color: C.pink,
                  textColor: C.cream,
                  fontSize: 18,
                  expand: true,
                  onTap: () => Navigator.of(ctx).pop(true),
                ),
              ),
            ]),
          ]),
        ),
      ),
    ),
  );
  return r ?? false;
}

/// Base de bottom sheet estilizado e centralizado (bom no celular e no PC).
Future<T?> showStyledSheet<T>(BuildContext context, Widget Function(BuildContext ctx) builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: C.ink.withValues(alpha: 0.7),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 540,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.92,
          ),
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 12, 18, 18),
            decoration: inkBox(color: C.cream, radius: 28, shadow: 7),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: builder(ctx),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
