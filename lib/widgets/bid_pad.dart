import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../sfx.dart';
import '../theme.dart';
import 'common.dart';

/// Teclado numérico próprio (no celular não abre o teclado do sistema).
class BidPad extends StatefulWidget {
  final Question q;
  final double? current;
  final bool canViajou;
  final bool compact;
  final Future<bool> Function(double value) onBid;
  final Future<bool> Function() onViajou;

  const BidPad({
    super.key,
    required this.q,
    required this.current,
    required this.canViajou,
    required this.onBid,
    required this.onViajou,
    this.compact = false,
  });

  @override
  State<BidPad> createState() => _BidPadState();
}

class _BidPadState extends State<BidPad> {
  String _txt = '';
  bool _sending = false;

  double? get _val => _txt.isEmpty ? null : double.tryParse(_txt);

  bool get _valid {
    final v = _val;
    if (v == null) return false;
    final c = widget.current;
    return c == null || v > c;
  }

  void _press(String k) {
    HapticFeedback.selectionClick();
    Sfx.play('key', volume: 0.45);
    setState(() {
      if (k == 'del') {
        if (_txt.isNotEmpty) _txt = _txt.substring(0, _txt.length - 1);
      } else if (k == ',') {
        if (!_txt.contains('.') && !widget.q.isYear) _txt = _txt.isEmpty ? '0.' : '$_txt.';
      } else if (k == '000') {
        if (_txt.isNotEmpty && _txt != '0' && !_txt.contains('.') && _txt.length <= 9) _txt = '${_txt}000';
      } else {
        if (_txt.length >= 13) return;
        final dot = _txt.indexOf('.');
        if (dot >= 0 && _txt.length - dot > 3) return;
        _txt = _txt == '0' ? k : '$_txt$k';
      }
    });
  }

  String _toTxt(double v) {
    if (v == v.roundToDouble()) return v.round().toString();
    final d = max(1, decimalsOf(v));
    return v.toStringAsFixed(d).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  void _quick(double Function(double base) f) {
    final base = widget.current ?? 0;
    var v = f(base);
    if (widget.current != null && v <= base) v = base + 1;
    HapticFeedback.selectionClick();
    Sfx.play('key', volume: 0.45);
    setState(() => _txt = _toTxt(v));
  }

  Future<void> _send() async {
    final v = _val;
    if (v == null || !_valid || _sending) return;
    setState(() => _sending = true);
    final ok = await widget.onBid(v);
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) _txt = '';
    });
  }

  Future<void> _viajou() async {
    if (_sending) return;
    setState(() => _sending = true);
    await widget.onViajou();
    if (mounted) setState(() => _sending = false);
  }

  String get _shown {
    if (_txt.isEmpty) return '';
    final parts = _txt.split('.');
    final intPart = parts[0].isEmpty ? '0' : parts[0];
    final n = fmtNum(int.tryParse(intPart) ?? 0, group: !widget.q.isYear);
    return parts.length > 1 ? '$n,${parts[1]}' : n;
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final keyH = compact ? 44.0 : 54.0;
    final cur = widget.current;
    final year = widget.q.isYear;
    final unit = widget.q.unit;
    final tooLow = _val != null && !_valid;

    final quick = <(String, double Function(double))>[];
    if (cur != null) {
      quick.add(('+1', (double b) => b + 1));
      if (year) {
        quick.add(('+5', (double b) => b + 5));
        quick.add(('+20', (double b) => b + 20));
      } else {
        quick.add(('+10%', (double b) => (b * 1.1).ceilToDouble()));
        quick.add(('x2', (double b) => b == 0 ? 1.0 : b * 2));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Visor
        Container(
          height: compact ? 56 : 66,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: inkBox(color: Colors.white, radius: 18, shadow: 4),
          child: Row(children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _txt.isEmpty
                    ? Text(cur == null ? 'Seu chute' : 'Mais que ${withUnit(cur, unit)}',
                        style: display(compact ? 24 : 28, color: C.disabled))
                    : Text(_shown, style: display(compact ? 32 : 38, color: tooLow ? C.pink : C.ink)),
              ),
            ),
            if (unit.isNotEmpty && unit != 'ano' && _txt.isNotEmpty) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 140),
                child: Text(unit,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: body(15, color: C.muted, weight: FontWeight.w800)),
              ),
            ],
          ]),
        ),
        SizedBox(height: compact ? 8 : 10),
        // Atalhos
        Row(children: [
          for (final item in quick) ...[
            Expanded(child: _MiniKey(label: item.$1, onTap: () => _quick(item.$2))),
            const SizedBox(width: 6),
          ],
          Expanded(child: _MiniKey(label: '000', onTap: year ? null : () => _press('000'))),
        ]),
        SizedBox(height: compact ? 6 : 8),
        // Teclas
        for (final row in const [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          [',', '0', 'del'],
        ])
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 5 : 7),
            child: Row(children: [
              for (var i = 0; i < row.length; i++) ...[
                Expanded(
                  child: ChunkyButton(
                    label: row[i] == 'del' ? '' : row[i],
                    icon: row[i] == 'del' ? Icons.backspace_rounded : null,
                    height: keyH,
                    expand: true,
                    sound: false,
                    depth: 3,
                    radius: 14,
                    fontSize: compact ? 24 : 28,
                    padding: EdgeInsets.zero,
                    color: row[i] == 'del' || row[i] == ',' ? C.cream2 : C.cream,
                    onTap: row[i] == ',' && year ? null : () => _press(row[i]),
                  ),
                ),
                if (i < row.length - 1) const SizedBox(width: 6),
              ],
            ]),
          ),
        if (tooLow)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text('Tem que ser maior que ${withUnit(cur!, unit)}',
                textAlign: TextAlign.center, style: body(13.5, color: C.pink, weight: FontWeight.w900)),
          ),
        SizedBox(height: compact ? 2 : 6),
        // Ações
        Row(children: [
          if (widget.canViajou) ...[
            Expanded(child: ViajouButton(height: compact ? 58 : 66, onTap: _sending ? null : _viajou)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: ChunkyButton(
              label: cur == null ? 'CHUTAR' : 'SUBIR',
              icon: Icons.arrow_upward_rounded,
              color: C.mint,
              height: compact ? 58 : 66,
              expand: true,
              fontSize: compact ? 22 : 26,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              onTap: _valid && !_sending ? _send : null,
            ),
          ),
        ]),
      ],
    );
  }
}

class _MiniKey extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _MiniKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ChunkyButton(
      label: label,
      onTap: onTap,
      height: 36,
      expand: true,
      sound: false,
      depth: 3,
      radius: 12,
      fontSize: 16,
      padding: EdgeInsets.zero,
      color: C.lilac,
    );
  }
}

/// O botão mais importante do jogo.
class ViajouButton extends StatefulWidget {
  final VoidCallback? onTap;
  final double height;
  const ViajouButton({super.key, required this.onTap, this.height = 66});

  @override
  State<ViajouButton> createState() => _ViajouButtonState();
}

class _ViajouButtonState extends State<ViajouButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 850))..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) => Transform.scale(
        scale: 1 + Curves.easeInOut.transform(_c.value) * 0.035,
        child: child,
      ),
      child: ChunkyButton(
        label: 'VIAJOU!',
        icon: Icons.rocket_launch_rounded,
        color: C.pink,
        textColor: C.cream,
        height: widget.height,
        expand: true,
        sound: false,
        fontSize: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        onTap: widget.onTap == null
            ? null
            : () {
                HapticFeedback.heavyImpact();
                widget.onTap!();
              },
      ),
    );
  }
}
