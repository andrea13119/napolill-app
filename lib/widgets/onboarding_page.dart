import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/mood_theme.dart';

class OnboardingPage extends StatefulWidget {
  final OnboardingPageData data;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final Future<void> Function()? onSkip;
  final Function(bool)? onCheckboxStateChanged;
  final bool? initialCheckboxState;

  const OnboardingPage({
    super.key,
    required this.data,
    this.onNext,
    this.onPrevious,
    this.onSkip,
    this.onCheckboxStateChanged,
    this.initialCheckboxState,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<bool> _checkboxStates = [];
  bool _singleCheckboxState = false;

  @override
  void initState() {
    super.initState();
    if (widget.data.showCheckboxes) {
      _checkboxStates.addAll(List.filled(widget.data.checkboxes.length, false));
    }
    if (widget.data.showCheckbox && widget.initialCheckboxState != null) {
      _singleCheckboxState = widget.initialCheckboxState!;
    }
  }

  Future<void> _launchURL(String url) async {
    try {
      final Uri uri = Uri.parse(url);

      // Debug: Print URL for troubleshooting
      debugPrint('Attempting to launch URL: $url');

      // Try multiple launch modes
      bool launched = false;

      // Try 1: externalApplication
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          debugPrint('Successfully launched with externalApplication');
        }
      } catch (e) {
        debugPrint('externalApplication failed: $e');
      }

      // Try 2: platformDefault
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.platformDefault);
          launched = true;
          debugPrint('Successfully launched with platformDefault');
        } catch (e) {
          debugPrint('platformDefault failed: $e');
        }
      }

      // Try 3: externalNonBrowserApplication
      if (!launched) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
          launched = true;
          debugPrint(
            'Successfully launched with externalNonBrowserApplication',
          );
        } catch (e) {
          debugPrint('externalNonBrowserApplication failed: $e');
        }
      }

      // Try 4: Legacy launch method (fallback)
      if (!launched) {
        try {
          await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          launched = true;
          debugPrint('Successfully launched with legacy launch method');
        } catch (e) {
          debugPrint('Legacy launch failed: $e');
        }
      }

      if (!launched) {
        throw Exception('All launch modes failed');
      }
    } catch (e) {
      debugPrint('URL launch error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Link konnte nicht geöffnet werden: $url\n\nBitte versuche es später erneut oder öffne den Link manuell in deinem Browser.',
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Kopieren',
              onPressed: () {
                // Copy URL to clipboard
                Clipboard.setData(ClipboardData(text: url));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('URL in Zwischenablage kopiert!'),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Widget _buildTextWithLinks(String text, {FontWeight? fontWeight}) {
    // Split text by link patterns
    final List<TextSpan> spans = [];
    final RegExp linkRegex = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');
    int lastEnd = 0;

    for (final Match match in linkRegex.allMatches(text)) {
      // Add text before the link
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastEnd, match.start),
            style: AppTheme.bodyDarkStyle.copyWith(fontWeight: fontWeight),
          ),
        );
      }

      // Add the clickable link
      final String linkText = match.group(1)!;
      final String linkUrl = match.group(2)!;
      spans.add(
        TextSpan(
          text: linkText,
          style: AppTheme.bodyDarkStyle.copyWith(
            color: MoodTheme.standard.accentColor,
            decoration: TextDecoration.underline,
            fontWeight: FontWeight.bold, // Links sind jetzt immer fett
          ),
          recognizer: TapGestureRecognizer()..onTap = () => _launchURL(linkUrl),
        ),
      );

      lastEnd = match.end;
    }

    // Add remaining text
    if (lastEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastEnd),
          style: AppTheme.bodyDarkStyle.copyWith(fontWeight: fontWeight),
        ),
      );
    }

    return RichText(text: TextSpan(children: spans));
  }

  bool get _canProceed {
    if (widget.data.showCheckboxes) {
      return _checkboxStates.length == widget.data.checkboxes.length &&
          _checkboxStates.every((state) => state);
    }
    if (widget.data.showCheckbox) {
      return _singleCheckboxState;
    }
    return true;
  }

  void _toggleCheckbox(int index) {
    setState(() {
      _checkboxStates[index] = !_checkboxStates[index];
    });
  }

  void _toggleSingleCheckbox() {
    setState(() {
      _singleCheckboxState = !_singleCheckboxState;
    });
    // Notify parent about checkbox state change
    if (widget.onCheckboxStateChanged != null) {
      widget.onCheckboxStateChanged!(_singleCheckboxState);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.cardPadding),
      child: Card(
        color: AppTheme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                widget.data.title,
                style: AppTheme.headingDarkStyle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Content
                      if (widget.data.content.isNotEmpty)
                        _buildTextWithLinks(widget.data.content),

                      // Bullets
                      if (widget.data.showBullets &&
                          widget.data.bullets.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ...widget.data.bullets.map(
                          (bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: AppTheme.bodyDarkStyle),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: AppTheme.bodyDarkStyle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      // Additional Text
                      if (widget.data.additionalText != null) ...[
                        const SizedBox(height: 16),
                        _buildTextWithLinks(widget.data.additionalText!),
                      ],

                      // Highlight Text
                      if (widget.data.highlightText != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          widget.data.highlightText!,
                          style: AppTheme.bodyDarkStyle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      // Checkboxes
                      if (widget.data.showCheckboxes) ...[
                        const SizedBox(height: 24),
                        ...widget.data.checkboxes.asMap().entries.map((entry) {
                          final index = entry.key;
                          final checkboxText = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Checkbox(
                                  value: _checkboxStates[index],
                                  onChanged: (_) => _toggleCheckbox(index),
                                  activeColor: MoodTheme.standard.accentColor,
                                ),
                                Expanded(
                                  child: _buildTextWithLinks(
                                    checkboxText,
                                    fontWeight:
                                        index ==
                                            widget.data.checkboxes.length - 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Single Checkbox
                      if (widget.data.showCheckbox &&
                          widget.data.checkboxText != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _singleCheckboxState,
                              onChanged: (_) => _toggleSingleCheckbox(),
                              activeColor: MoodTheme.standard.accentColor,
                            ),
                            Expanded(
                              child: _buildTextWithLinks(
                                widget.data.checkboxText!,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (widget.data.showCheckbox &&
                  widget.data.checkboxText != null) ...[
                // Single checkbox page (like "Hinweis bei Kontoerstellung") - show only continue button
                SizedBox(
                  width: double.infinity,
                  height: AppConstants.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _canProceed ? widget.onNext : () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _canProceed
                          ? MoodTheme.standard.accentColor
                          : Colors.grey[600],
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[600],
                      disabledForegroundColor: Colors.white70,
                    ),
                    child: Text(AppStrings.weiter, style: AppTheme.buttonStyle),
                  ),
                ),
              ] else ...[
                // Regular page - show continue button and back button if available
                Row(
                  children: [
                    if (widget.onPrevious != null) ...[
                      Expanded(
                        child: SizedBox(
                          height: AppConstants.buttonHeight,
                          child: OutlinedButton(
                            onPressed: widget.onPrevious,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: Colors.grey[400]!),
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.grey[700],
                            ),
                            child: Text('Zurück', style: AppTheme.buttonStyle),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: AppConstants.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _canProceed ? widget.onNext : () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _canProceed
                                ? MoodTheme.standard.accentColor
                                : Colors.grey[600],
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[600],
                            disabledForegroundColor: Colors.white70,
                          ),
                          child: Text(
                            AppStrings.weiter,
                            style: AppTheme.buttonStyle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingPageData {
  final String title;
  final String content;
  final bool showBullets;
  final List<String> bullets;
  final String? additionalText;
  final String? highlightText;
  final bool showCheckboxes;
  final List<String> checkboxes;
  final bool showCheckbox;
  final String? checkboxText;

  OnboardingPageData({
    required this.title,
    required this.content,
    this.showBullets = false,
    this.bullets = const [],
    this.additionalText,
    this.highlightText,
    this.showCheckboxes = false,
    this.checkboxes = const [],
    this.showCheckbox = false,
    this.checkboxText,
  });
}
