import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';
import 'affirmation_selection_screen.dart';

class FinalNoticeScreen extends ConsumerStatefulWidget {
  const FinalNoticeScreen({super.key});

  @override
  ConsumerState<FinalNoticeScreen> createState() => _FinalNoticeScreenState();
}

class _FinalNoticeScreenState extends ConsumerState<FinalNoticeScreen> {
  bool _understood = false;

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: Copy to clipboard
        await Clipboard.setData(ClipboardData(text: url));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Link kopiert: $url'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // Fallback: Copy to clipboard
      await Clipboard.setData(ClipboardData(text: url));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Link kopiert: $url'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always use neutral theme for final notice screen
    final neutralTheme = MoodTheme.standard;
    final userPrefs = ref.watch(userPrefsProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: neutralTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Vorbereitung & Wissenschaftliche Basis',
                        style: AppTheme.headingStyle.copyWith(fontSize: 26),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // Content Card
                      Card(
                        color: AppTheme.cardColor,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Aufnahme-Tipps Section
                              _buildSectionTitle('📝 AUFNAHME-TIPPS'),
                              const SizedBox(height: 12),
                              _buildBulletPoint(
                                'Hintergrundgeräusche minimieren',
                              ),
                              _buildBulletPoint(
                                'Abstand: Smartphone/Mikro 10–15 cm vom Mund',
                              ),
                              _buildBulletPoint(
                                'Körperhaltung: Aufrecht und entspannt',
                              ),
                              _buildBulletPoint('Klar und deutlich sprechen'),

                              const SizedBox(height: 24),

                              // Embodiment Section
                              _buildSectionTitle('💭 EMBODIMENT-TECHNIK'),
                              const SizedBox(height: 12),
                              Text(
                                'Stell dir vor, du hast dein Ziel bereits erreicht:',
                                style: AppTheme.bodyDarkStyle.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildBulletPoint(
                                'Halte 1 konkrete Szene vor Augen, in der dein Satz wahr ist',
                              ),
                              _buildBulletPoint(
                                'Fühle die Emotionen dieser Szene während der Aufnahme',
                              ),

                              const SizedBox(height: 24),

                              // Wissenschaftliche Basis Section
                              _buildSectionTitle('🔬 WISSENSCHAFTLICHE BASIS'),
                              const SizedBox(height: 16),

                              _buildStudyItem(
                                '1️⃣ Visualisieren verbessert Leistung',
                                'Mentales Durchgehen einer Aufgabe kann Leistung spürbar verbessern – auch ohne echte Ausführung.',
                                'https://napolill.com/studies/visualization',
                                'Driskell, J.E. et al. (1994), Psychological Bulletin',
                              ),

                              const SizedBox(height: 16),

                              _buildStudyItem(
                                '2️⃣ Selbst-Affirmation macht offener',
                                'Kurze Selbst-Affirmation (Werte/Stärken erinnern) erhöht Offenheit für hilfreiche Botschaften und Verhaltensänderung.',
                                'https://napolill.com/studies/self-affirmation',
                                'Epton, T. et al. (2015), Psychological Bulletin',
                              ),

                              const SizedBox(height: 16),

                              _buildStudyItem(
                                '3️⃣ Schlaf & Konsolidierung',
                                'Schlaf fördert die Festigung neuer Inhalte. Abends aufnehmen/anhören kann die Verankerung unterstützen.',
                                'https://napolill.com/studies/sleep-consolidation',
                                'Rasch, B. & Born, J. (2013), Nature Reviews Neuroscience',
                              ),

                              const SizedBox(height: 24),

                              // Hinweis
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Diese App ersetzt keine Therapie. Nutze sie achtsam und in deinem Tempo.',
                                        style: AppTheme.bodyDarkStyle.copyWith(
                                          color: Colors.orange[200],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Single Checkbox
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Checkbox(
                                    value: _understood,
                                    onChanged: (value) => setState(
                                      () => _understood = value ?? false,
                                    ),
                                    activeColor: MoodTheme.standard.accentColor,
                                  ),
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(
                                        'ICH HABE DIE HINWEISE VERSTANDEN UND MÖCHTE FORTFAHREN',
                                        style: AppTheme.bodyDarkStyle.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Summary
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'Deine Auswahl:',
                              style: AppTheme.headingStyle.copyWith(
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSummaryItem(
                              'Thema',
                              _getTopicDisplayName(userPrefs.selectedTopic),
                            ),
                            _buildSummaryItem(
                              'Level',
                              _getLevelDisplayName(userPrefs.level),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Start Button
                      SizedBox(
                        width: double.infinity,
                        height: AppConstants.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _canStart() ? _start : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canStart()
                                ? MoodTheme.standard.accentColor
                                : Colors.grey,
                          ),
                          child: Text(
                            'JETZT STARTEN',
                            style: AppTheme.buttonStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo_napolill.png',
                    height: 50,
                    fit: BoxFit.contain,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTheme.bodyDarkStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: MoodTheme.standard.accentColor,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTheme.bodyDarkStyle.copyWith(fontSize: 16)),
          Expanded(child: Text(text, style: AppTheme.bodyDarkStyle)),
        ],
      ),
    );
  }

  Widget _buildStudyItem(
    String title,
    String description,
    String url,
    String citation,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTheme.bodyDarkStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 6),
        Text(description, style: AppTheme.bodyDarkStyle.copyWith(fontSize: 14)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => _launchURL(url),
          child: Row(
            children: [
              Icon(
                Icons.arrow_forward,
                size: 14,
                color: MoodTheme.standard.accentColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Mehr erfahren',
                style: AppTheme.bodyDarkStyle.copyWith(
                  color: MoodTheme.standard.accentColor,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Studie: $citation',
          style: AppTheme.bodyDarkStyle.copyWith(
            fontSize: 12,
            color: Colors.grey[400],
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(value, style: AppTheme.bodyStyle),
        ],
      ),
    );
  }

  bool _canStart() {
    return _understood;
  }

  void _start() {
    // Mark setup as completed
    ref.read(userPrefsProvider.notifier).updateConsent(true);
    ref.read(userPrefsProvider.notifier).updatePrivacy(true);
    ref.read(userPrefsProvider.notifier).updateAGB(true);

    // Get the selected topic from user preferences
    final userPrefs = ref.read(userPrefsProvider);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) =>
            AffirmationSelectionScreen(category: userPrefs.selectedTopic),
      ),
    );
  }

  String _getTopicDisplayName(String topic) {
    switch (topic) {
      case AppConstants.categorySelbstbewusstsein:
        return AppStrings.selbstbewusstsein;
      case AppConstants.categorySelbstwert:
        return AppStrings.selbstwert;
      case AppConstants.categoryAengste:
        return AppStrings.aengsteLoesen;
      case AppConstants.categoryCustom:
        return AppStrings.eigeneZiele;
      default:
        return topic;
    }
  }

  String _getLevelDisplayName(String level) {
    return AppStrings.mapLevelToLabel(level);
  }
}
