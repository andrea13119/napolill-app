import 'package:flutter/material.dart';

class MoodTheme {
  final RadialGradient backgroundGradient;
  final Color cardColor;
  final Color accentColor;
  final Color bottomNavColor;

  const MoodTheme({
    required this.backgroundGradient,
    required this.cardColor,
    required this.accentColor,
    required this.bottomNavColor,
  });

  // Methode zum Anpassen der Helligkeit/Sättigung
  MoodTheme withBrightness(double brightness) {
    // brightness: 0.0 = gedämpft, 1.0 = voll
    // Wir passen die Sättigung an, um die Farben weniger grell zu machen
    final saturation = brightness.clamp(0.0, 1.0);
    
    return MoodTheme(
      backgroundGradient: RadialGradient(
        center: backgroundGradient.center,
        radius: backgroundGradient.radius,
        colors: backgroundGradient.colors.map((color) {
          return _adjustColorBrightness(color, saturation);
        }).toList(),
        stops: backgroundGradient.stops,
      ),
      cardColor: _adjustColorBrightness(cardColor, saturation),
      accentColor: _adjustColorBrightness(accentColor, saturation),
      bottomNavColor: _adjustColorBrightness(bottomNavColor, saturation),
    );
  }

  // Hilfsmethode zum Anpassen der Farbhelligkeit/Sättigung
  Color _adjustColorBrightness(Color color, double saturation) {
    if (saturation >= 1.0) return color;
    
    // Konvertiere zu HSL
    final hsl = HSLColor.fromColor(color);
    
    // Reduziere die Sättigung basierend auf dem brightness-Wert
    // Bei saturation = 0.5 wird die Sättigung halbiert
    final adjustedSaturation = hsl.saturation * saturation;
    
    return hsl.withSaturation(adjustedSaturation).toColor();
  }

  // 😠 WUETEND (Wütend) - Energiegeladen, kraftvoll
  static MoodTheme get wuetend => MoodTheme(
    backgroundGradient: const RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        Color(0xFF8B1538), // Dunkelrot
        Color(0xFFFF4500), // Leuchtendes Orange-Rot
      ],
      stops: [0.0, 1.0],
    ),
    cardColor: const Color(0xFF5D1A1A), // Dunkelrot
    accentColor: const Color(0xFFFF6B35), // Leuchtendes Orange
    bottomNavColor: const Color(0xFF3D0E0E), // Sehr dunkles Rot
  );

  // 😢 TRAURIG (Traurig) - Beruhigend, tröstend
  static MoodTheme get traurig => MoodTheme(
    backgroundGradient: const RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        Color(0xFF1e3a5f), // Tiefes Blau
        Color(0xFF4682B4), // Stahlblau
      ],
      stops: [0.0, 1.0],
    ),
    cardColor: const Color(0xFF2C3E50), // Tiefes Blau
    accentColor: const Color(0xFF87CEEB), // Sanftes Cyan
    bottomNavColor: const Color(0xFF1a2332), // Dunkles Navy
  );

  // 😐 PASSIV (Neutral) - Ausgewogen, professionell
  static MoodTheme get passiv => MoodTheme(
    backgroundGradient: const RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        Color(0xFF4A5568), // Neutrales Grau
        Color(0xFF718096), // Helleres Grau
      ],
      stops: [0.0, 1.0],
    ),
    cardColor: const Color(0xFF2D3748), // Dunkles Grau
    accentColor: const Color(0xFFE2D5B8), // Warmes Beige
    bottomNavColor: const Color(0xFF1A202C), // Sehr dunkles Grau
  );

  // 😊 FROEHLICH (Fröhlich) - Optimistisch, energiegeladen
  static MoodTheme get froehlich => MoodTheme(
    backgroundGradient: const RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        Color(0xFF006400), // Dunkles Smaragdgrün
        Color(0xFF00FF7F), // Helles Spring Green
      ],
      stops: [0.0, 1.0],
    ),
    cardColor: const Color(0xFF003D00), // Sehr dunkles Grün
    accentColor: const Color(0xFF66FF99), // Helles Mintgrün
    bottomNavColor: const Color(0xFF002200), // Extrem dunkles Grün
  );

  // 🤩 EUPHORISCH (Euphorisch) - Lebendig, aufregend
  static MoodTheme get euphorisch => MoodTheme(
    backgroundGradient: const RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        Color(0xFF6A0DAD), // Warmes Lila
        Color(0xFFFF6B35), // Leuchtendes Orange
      ],
      stops: [0.0, 1.0],
    ),
    cardColor: const Color(0xFF4A1A5C), // Dunkles Lila
    accentColor: const Color(0xFFFFB366), // Goldenes Orange
    bottomNavColor: const Color(0xFF2D0F3A), // Sehr dunkles Lila
  );

  // Standard Theme (wenn kein Mood gewählt) - Mitternachtsblau mit Gold
  static MoodTheme get standard => MoodTheme(
    backgroundGradient: const RadialGradient(
      center: Alignment.topLeft,
      radius: 1.0,
      colors: [
        Color(0xFF0F1E3D), // Tiefes Mitternachtsblau
        Color(0xFF1E3A5F), // Sanftes Navy
      ],
      stops: [0.0, 1.0],
    ),
    cardColor: const Color(0xFF0A1628), // Sehr dunkles Navy
    accentColor: const Color(0xFFD4AF37), // Warmes Gold
    bottomNavColor: const Color(0xFF060D1A), // Extrem dunkles Blau
  );

  // Get theme based on mood string
  static MoodTheme fromMood(String? mood) {
    if (mood == null || mood.isEmpty) return standard;

    switch (mood.toLowerCase()) {
      case 'wuetend':
        return wuetend;
      case 'traurig':
        return traurig;
      case 'passiv':
        return passiv;
      case 'froehlich':
        return froehlich;
      case 'euphorisch':
        return euphorisch;
      default:
        return standard;
    }
  }
}
