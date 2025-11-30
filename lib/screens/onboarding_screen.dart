import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_provider.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import '../widgets/onboarding_page.dart';
import 'topic_selection_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _safetyCheckboxChecked = false;
  bool _accountCheckboxChecked = false;

  final List<OnboardingPageData> _pages = [
    OnboardingPageData(
      title: 'Willkommen bei Napolill',
      content:
          'Diese App unterstützt dich dabei, eigene Affirmationen aufzunehmen und gezielt zu nutzen – ob für Selbstwert, Selbstbewusstsein oder das Lösen innerer Blockaden.',
      showBullets: true,
      bullets: [
        'als **kurze Sessions** (5 oder 10 Minuten) abspielen',
        'oder in **Endlosschleife** – z. B. über Nacht',
      ],
      additionalText:
          'Dein Fortschritt wird automatisch verfolgt. Für jeden Meilenstein erhältst du ein Abzeichen – ganz ohne Druck, nur zur Motivation.',
      highlightText:
          'Alles bleibt anonym. Du entscheidest, wie tief du einsteigen möchtest.',
    ),
    OnboardingPageData(
      title: 'Wichtiger Hinweis vor der Nutzung von Napolill',
      content:
          'Diese App ersetzt keine Therapie und ist nicht für medizinische Zwecke gedacht. Sie unterstützt dich dabei, mit deinen inneren Themen achtsam umzugehen – in deinem Tempo und auf deine Weise.\n\nWenn du Affirmationen über Nacht oder mit Endlosschleife nutzen möchtest, achte auf dein Wohlbefinden. In manchen Sessions kann eine Lichtimpuls-Funktion verwendet werden – nur wenn du sie aktivierst.\n\nDiese App dient der emotionalen Selbstreflexion. Sie enthält Inhalte wie Affirmationen, Frequenzmusik und geführte Sessions, die auch über Nacht in Endlosschleife abgespielt werden können. In manchen Sessions kann – wenn aktiviert – eine Lichtimpulsfunktion (z. B. über den Handyblitz) genutzt werden.',
      showCheckbox: true,
      checkboxText:
          'ICH HABE DIE [SICHERHEITSHINWEISE](https://napolill.com/safety) GELESEN UND VERSTANDEN',
    ),
    OnboardingPageData(
      title: 'Datenschutzhinweis für Napolill',
      content:
          'Wie wir mit deinen Daten umgehen – kurz erklärt\n\nNapolill speichert nur das, was für deine Nutzung notwendig ist:',
      showBullets: true,
      bullets: [
        'Dein Benutzername oder deine E-Mail (zur Anmeldung)',
        'Deine eigenen aufgenommenen Affirmationen',
        'Dein Nutzungsverlauf (z. B. Streaks, letzte Nutzung)',
        'Optional: Deine gewählte Stimmung (zur Personalisierung)',
      ],
      additionalText:
          '**Wo gespeichert?**\nLokal auf deinem Gerät, damit du Inhalte ohne Internet sofort abspielen kannst.\nZusätzlich anonymisiert in Firebase (Cloud), damit deine Daten auch bei Gerätewechsel erhalten bleiben.\n\n**Was passiert nicht:**\n• Keine Weitergabe an Dritte.\n• Keine Verbindung mit deinem echten Namen.\n• Keine Werbung.\n\n**Was du jederzeit tun kannst:**\n• Deinen Account löschen\n• Deine Daten lokal löschen\n• Den Datenschutztext in der App unter "Einstellungen" nachlesen\n\n[Vollständige Datenschutzrichtlinien](https://napolill.com/privacy)',
    ),
    OnboardingPageData(
      title: 'AGB',
      content:
          'Allgemeine Nutzungsbedingungen der Napolill App (MVP-Version)\n\n1. Zweck der App\nDiese App bietet Audio-Inhalte zur Selbstreflexion. Sie ist ausschließlich für den privaten Gebrauch bestimmt. Es werden keine Ergebnisse garantiert.\n\n2. Keine medizinische Anwendung\nDie Inhalte sind keine Therapie und ersetzen keine psychologische, medizinische oder psychiatrische Behandlung.\n\n3. Haftungsausschluss\nDie Nutzung erfolgt auf eigene Gefahr. Es wird keine Haftung für unerwünschte emotionale Reaktionen oder technische Probleme übernommen. Die Lichtimpulsfunktion ist freiwillig, falls aktiviert.\n\n4. Datenschutz\nInformationen zur Datenspeicherung findest du im "Datenschutz"-Menü. Wir halten uns an die DSGVO.\n\n5. Account & Löschung\nDu kannst deinen Account jederzeit löschen. Alle gespeicherten Inhalte werden unwiderruflich entfernt.\n\n6. Updates & Änderungen\nFunktionen können geändert oder erweitert werden.\n\n[Vollständige AGB](https://napolill.com/terms)',
    ),
    OnboardingPageData(
      title: 'Hinweis bei Kontoerstellung',
      content:
          'Mit dem Erstellen eines Kontos erklärst du dich einverstanden, dass deine Affirmationen, deine Streak-Daten und deine Nutzungsverläufe anonymisiert gespeichert werden – lokal und zusätzlich in der Cloud (Firebase), um deine Nutzung auch bei Gerätewechsel aufrechtzuerhalten. Du kannst deinen Account jederzeit löschen.',
      showCheckbox: true,
      checkboxText:
          'ICH HABE DIE [DATENSCHUTZBESTIMMUNGEN](https://napolill.com/privacy) UND [AGB](https://napolill.com/terms) GELESEN UND BIN EINVERSTANDEN.',
    ),
    OnboardingPageData(
      title: 'Bitte bestätige vor der Nutzung:',
      content: '',
      showCheckboxes: true,
      checkboxes: [
        'Ich bin mir bewusst, dass diese App keine medizinische oder psychotherapeutische Behandlung ersetzt.',
        'Ich nutze die Inhalte freiwillig und auf eigene Verantwortung.',
        'Ich leide nicht an Epilepsie, lichtbedingter Migräne oder anderen neurologischen Erkrankungen, die durch wiederholte akustische oder visuelle Reize ausgelöst werden könnten.',
        'Ich habe die [Datenschutzrichtlinien](https://napolill.com/privacy) und [Nutzungsbedingungen](https://napolill.com/terms) gelesen und akzeptiert.',
        'ICH BESTÄTIGE DIE OBEN GENANNTEN HINWEISE UND MÖCHTE DIE APP NUTZEN.',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: AppConstants.slideTransitionDuration,
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppConstants.slideTransitionDuration,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed - warte darauf, dass alle Flags gespeichert sind
    final notifier = ref.read(userPrefsProvider.notifier);
    await notifier.updateConsent(true);
    await notifier.updatePrivacy(true);
    await notifier.updateAGB(true);

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const TopicSelectionScreen()),
    );
  }

  Future<void> _skipToTopicSelection() async {
    await _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for onboarding screen
    final neutralTheme = MoodTheme.standard;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: neutralTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      IconButton(
                        onPressed: _previousPage,
                        icon: Icon(
                          Icons.arrow_back,
                          color: MoodTheme.standard.accentColor,
                        ),
                      ),
                    Expanded(
                      child: SizedBox(
                        height: 80, // Kontrollierte Höhe der Logo-Box
                        child: Center(
                          child: Image.asset(
                            'assets/images/logo_napolill.png',
                            height: 80, // Logo-Größe innerhalb der Box
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    if (_currentPage > 0)
                      const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              const SizedBox(
                height: 8,
              ), // Verringerte Abstand zwischen Logo und Text
              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _pages.length,
                  physics:
                      (_currentPage == 5 ||
                          (_currentPage == 1 && !_safetyCheckboxChecked) ||
                          (_currentPage == 4 && !_accountCheckboxChecked))
                      ? const NeverScrollableScrollPhysics()
                      : null, // Block sliding on confirmation page, safety notice page, and account creation page when checkbox not checked
                  itemBuilder: (context, index) {
                    return OnboardingPage(
                      data: _pages[index],
                      onNext: _nextPage,
                      onPrevious: index > 0
                          ? _previousPage
                          : null, // No back button on first page
                      onSkip: index == _pages.length - 1
                          ? _skipToTopicSelection
                          : null,
                      onCheckboxStateChanged: index == 1
                          ? (bool checked) {
                              setState(() {
                                _safetyCheckboxChecked = checked;
                              });
                            }
                          : index == 4
                          ? (bool checked) {
                              setState(() {
                                _accountCheckboxChecked = checked;
                              });
                            }
                          : null,
                      initialCheckboxState: index == 1
                          ? _safetyCheckboxChecked
                          : index == 4
                          ? _accountCheckboxChecked
                          : null,
                    );
                  },
                ),
              ),

              // Page Indicator
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentPage
                            ? Colors.white
                            : Colors.white30,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
