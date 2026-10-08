/// Formatação de números no padrão brasileiro (1.234,5).
String fmtNum(num v, {bool group = true}) {
  if (v.isNaN || v.isInfinite) return '?';
  final neg = v < 0;
  final abs = v.abs();
  String intPart;
  String dec = '';
  if (abs == abs.roundToDouble()) {
    intPart = abs.round().toString();
  } else {
    var s = abs.toStringAsFixed(3);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    final parts = s.split('.');
    intPart = parts[0];
    if (parts.length > 1 && parts[1].isNotEmpty) dec = ',${parts[1]}';
  }
  if (group && intPart.length > 3) {
    final b = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) b.write('.');
      b.write(intPart[i]);
    }
    intPart = b.toString();
  }
  return '${neg ? '-' : ''}$intPart$dec';
}

/// Anos aparecem sem separador de milhar (1889, não 1.889).
String fmtAnswer(num v, String unit) => fmtNum(v, group: unit != 'ano');

/// Número com unidade: "1.250 km", "92%", "1889".
String withUnit(num v, String unit) {
  final n = fmtAnswer(v, unit);
  if (unit.isEmpty || unit == 'ano') return n;
  if (unit.startsWith('%') || unit.startsWith('°')) return '$n$unit';
  return '$n $unit';
}

/// Quantas casas decimais um número tem (até 3).
int decimalsOf(double v) {
  if (v == v.roundToDouble()) return 0;
  final s = v.toStringAsFixed(3).replaceFirst(RegExp(r'0+$'), '');
  final i = s.indexOf('.');
  return i < 0 ? 0 : s.length - i - 1;
}

/// Lê um número digitado por uma pessoa: aceita "1.500", "1500", "13,8" e "13.8".
double? parseHumanNumber(String raw) {
  var s = raw.trim().replaceAll(' ', '');
  if (s.isEmpty) return null;
  if (s.contains(',')) {
    s = s.replaceAll('.', '').replaceAll(',', '.');
  } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(s)) {
    s = s.replaceAll('.', '');
  }
  return double.tryParse(s);
}
