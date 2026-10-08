import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Paleta do VIAJOU!: noite espacial, cartas creme e contornos de tinta.
class C {
  static const space = Color(0xFF150B33);
  static const space2 = Color(0xFF261457);
  static const ink = Color(0xFF0E0722);
  static const cream = Color(0xFFFFF4DF);
  static const cream2 = Color(0xFFFFE6B8);
  static const pink = Color(0xFFFF4F8B);
  static const sun = Color(0xFFFFC93C);
  static const mint = Color(0xFF2EE6A8);
  static const sky = Color(0xFF5BC8FF);
  static const lilac = Color(0xFFB69CFF);
  static const orange = Color(0xFFFF8A3D);
  static const muted = Color(0xFF6E5F8C);
  static const disabled = Color(0xFF8C7FA8);
}

const playerColors = <Color>[
  C.pink,
  C.sun,
  C.mint,
  C.sky,
  C.lilac,
  C.orange,
  Color(0xFFFF6B6B),
  Color(0xFF8BE36B),
  Color(0xFFFFA8DA),
  Color(0xFF4DD9E8),
];

Color playerColor(int i) => playerColors[i.abs() % playerColors.length];

/// Fonte de título (gordinha e divertida).
TextStyle display(double size,
        {Color? color = C.cream, double height = 1.0, double letterSpacing = 0.4, List<Shadow>? shadows}) =>
    GoogleFonts.getFont('Lilita One',
        fontSize: size, color: color, height: height, letterSpacing: letterSpacing, shadows: shadows);

/// Fonte de texto corrido.
TextStyle body(double size, {Color color = C.ink, FontWeight weight = FontWeight.w700, double height = 1.25}) =>
    GoogleFonts.getFont('Nunito', fontSize: size, color: color, fontWeight: weight, height: height);

/// Caixa com contorno de tinta e sombra dura deslocada (estilo adesivo).
BoxDecoration inkBox({Color color = C.cream, double radius = 22, double shadow = 5, double border = 3}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: C.ink, width: border),
      boxShadow: shadow > 0 ? [BoxShadow(color: C.ink, offset: Offset(shadow, shadow))] : null,
    );

/// Painel escuro translúcido por cima do céu.
BoxDecoration glassBox({double radius = 22}) => BoxDecoration(
      color: C.ink.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: C.cream.withValues(alpha: 0.18), width: 2),
    );

InputDecoration fieldDeco(String hint, {String? label}) => InputDecoration(
      hintText: hint,
      labelText: label,
      hintStyle: body(16, color: C.muted, weight: FontWeight.w600),
      labelStyle: body(15, color: C.muted),
      floatingLabelStyle: body(15, color: C.ink),
      filled: true,
      fillColor: Colors.white,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.ink, width: 3),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.pink, width: 3),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: C.ink, width: 3),
      ),
    );

ThemeData buildTheme() {
  final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: C.space,
    colorScheme: ColorScheme.fromSeed(seedColor: C.pink, brightness: Brightness.dark),
    textTheme: GoogleFonts.nunitoTextTheme(base.textTheme),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: C.pink,
      selectionColor: Color(0x55FF4F8B),
      selectionHandleColor: C.pink,
    ),
  );
}
