class AppConstants {
  // App Info
  static const String appName = 'NAPOLILL';
  static const String appTagline = 'REPROGRAM-BRAIN';
  static const String appVersion = '1.0.0';

  // Categories
  static const String categorySelbstbewusstsein = 'selbstbewusstsein';
  static const String categorySelbstwert = 'selbstwert';
  static const String categoryAengste = 'aengste';
  static const String categoryCustom = 'custom';

  // Levels
  static const String levelBeginner = 'beginner';
  static const String levelAdvanced = 'advanced';
  static const String levelOpen = 'open';

  // Moods
  static const String moodWuetend = 'wuetend';
  static const String moodTraurig = 'traurig';
  static const String moodPassiv = 'passiv';
  static const String moodFroehlich = 'froehlich';
  static const String moodEuphorisch = 'euphorisch';

  // Playback Modes
  static const String modeMeditation = 'meditation';
  static const String modeEndless = 'endless';

  // Audio Settings
  static const int maxAffirmations = 30;
  static const int meditationDuration5Min = 5;
  static const int meditationDuration10Min = 10;
  static const int maxEndlessHours = 9;

  // File Paths
  static const String audioDir = 'napolill/entries';
  static const String recordingFormat = '.aac'; // Für Live-Recordings
  static const String finalAudioFormat = '.m4a'; // Für fertige Einträge
  static const String takePrefix = 'take_';

  // File naming
  static const String entryPrefix = 'entry_';
  static const String affirmationPrefix = 'affirmation_';

  // Storage paths
  static const String recordingsPath = 'recordings';
  static const String entriesPath = 'entries';

  // Solfeggio Frequencies
  static const List<String> solfeggioFrequencies = [
    '174',
    '284',
    '396',
    '417',
    '528',
    '639',
    '741',
    '852',
    '963',
  ];

  // Level-based Solfeggio Frequencies
  static const Map<String, List<String>> levelSolfeggioFrequencies = {
    levelBeginner: ['174', '284', '396'],
    levelAdvanced: ['174', '284', '396', '417', '528', '639'],
    levelOpen: ['174', '284', '396', '417', '528', '639', '741', '852', '963'],
  };

  // Solfeggio Frequency Descriptions
  static const Map<String, Map<String, String>> solfeggioDescriptions = {
    '174': {
      'name': '174 Hz',
      'title': 'Entspannung & Sicherheit',
      'description':
          'Hilft, Stress und körperliche Anspannung loszulassen. Ideal, um zur Ruhe zu kommen und sich sicherer zu fühlen.',
    },
    '284': {
      'name': '285 Hz',
      'title': 'Heilung & Stabilität',
      'description':
          'Fördert innere Erholung und gibt ein Gefühl von Stabilität. Unterstützt dabei, wieder ins Gleichgewicht zu finden.',
    },
    '396': {
      'name': '396 Hz',
      'title': 'Angst loslassen',
      'description':
          'Hilft, Schuldgefühle und Ängste zu reduzieren. Gut geeignet, um mit einem gestärkten Selbstwertgefühl neu zu starten.',
    },
    '417': {
      'name': '417 Hz',
      'title': 'Blockaden lösen',
      'description':
          'Unterstützt das Loslassen von alten Mustern und schwierigen Situationen. Fördert Neuanfang und innere Klarheit.',
    },
    '528': {
      'name': '528 Hz',
      'title': 'Selbstheilung & Liebe',
      'description':
          'Bekannt als „Liebesfrequenz". Fördert Selbstannahme, innere Heilung und positive Veränderungen.',
    },
    '639': {
      'name': '639 Hz',
      'title': 'Harmonie & Beziehungen',
      'description':
          'Hilft, mehr Verständnis und Nähe zu anderen aufzubauen. Unterstützt friedvolle und ausgeglichene Beziehungen.',
    },
    '741': {
      'name': '741 Hz',
      'title': 'Klarheit & Intuition',
      'description':
          'Bringt Klarheit und unterstützt, den eigenen Weg besser zu erkennen. Gut, um innere Blockaden zu durchbrechen.',
    },
    '852': {
      'name': '852 Hz',
      'title': 'Innere Wahrheit',
      'description':
          'Stärkt die Verbindung zur eigenen Wahrheit. Für Menschen, die tiefer in ihr Bewusstsein eintauchen möchten.',
    },
    '963': {
      'name': '963 Hz',
      'title': 'Bewusstsein & Verbindung',
      'description':
          'Erhöht die Wahrnehmung und das Gefühl der inneren Verbundenheit. Für erfahrene Nutzer, die bereit sind, weiterzugehen.',
    },
  };

  // UI Constants
  static const double borderRadius = 12.0;
  static const double buttonHeight = 48.0;
  static const double cardPadding = 16.0;

  // Animation Durations
  static const Duration introAnimationDuration = Duration(seconds: 5);
  static const Duration fadeTransitionDuration = Duration(milliseconds: 300);
  static const Duration slideTransitionDuration = Duration(milliseconds: 400);

  // Streak Badges
  static const List<int> streakMilestones = [5, 10, 15, 20, 30];

  // Colors (based on the design)
  static const int primaryColorValue = 0xFF214F5B; // Dark teal
  static const int secondaryColorValue = 0xFF2d2640; // Deep plum purple
  static const int accentColorValue = 0xFFE5B3B3; // Rose gold
  static const int backgroundColorValue = 0xFF1A3A42; // Darker teal
  static const int cardColorValue = 0xFFFFFFFF; // White
  static const int textColorValue = 0xFFFFFFFF; // White
  static const int textDarkColorValue = 0xFF000000; // Black
  static const int bottomNavColorValue = 0xFF1f1832; // Dark eggplant
}

class AppStrings {
  // Common
  static const String weiter = 'WEITER';
  static const String zurueck = 'ZURÜCK';
  static const String akzeptieren = 'AKZEPTIEREN';
  static const String starten = 'STARTEN';
  static const String fertig = 'FERTIG';
  static const String bearbeiten = 'BEARBEITEN';
  static const String loeschen = 'LÖSCHEN';
  static const String speichern = 'SPEICHERN';
  static const String abbrechen = 'ABBRECHEN';

  // Navigation
  static const String home = 'Home';
  static const String mediathek = 'Mediathek';
  static const String profil = 'Profil';
  static const String einstellungen = 'Settings';

  // Categories
  static const String selbstbewusstsein = 'Selbstbewusstsein';
  static const String selbstwert = 'Selbstwert';
  static const String aengsteLoesen = 'Ängste lösen';
  static const String eigeneZiele = 'Eigene Ziele';

  // Levels
  static const String level1Anfaenger = 'LEVEL 1 - ANFÄNGER';
  static const String level2Erfahren = 'LEVEL 2 - ERFAHREN';
  static const String level3Fortgeschritten = 'LEVEL 3 - FORTGESCHRITTEN';

  static String mapLevelToLabel(String level) {
    final normalized = level.toLowerCase();
    switch (normalized) {
      case AppConstants.levelBeginner:
        return level1Anfaenger;
      case AppConstants.levelAdvanced:
        return level2Erfahren;
      case AppConstants.levelOpen:
        return level3Fortgeschritten;
      default:
        return 'LEVEL ${normalized.toUpperCase()}';
    }
  }

  // Moods
  static const String wuetend = 'WUETEND';
  static const String traurig = 'TRAURIG';
  static const String passiv = 'PASSIV';
  static const String froehlich = 'FROEHLICH';
  static const String euphorisch = 'EUPHORISCH';

  // Playback
  static const String meditation = 'Meditation';
  static const String dauerschleife = 'Dauerschleife';
  static const String hoeren = 'HÖREN';
  static const String pause = 'PAUSE';
  static const String stop = 'STOP';
  static const String play = 'PLAY';

  // Time
  static const String heute = 'Heute';
  static const String gestern = 'Gestern';
  static const String dieserMonat = 'Dieser Monat';
  static const String tage = 'Tage';
  static const String stunden = 'Stunden';
  static const String minuten = 'Minuten';
}
