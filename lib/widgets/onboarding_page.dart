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
  final Future<void> Function(bool)? onPushNotificationChoice;
  final Future<void> Function(int hour, int minute)? onNotificationTimeSelected;
  final Function(bool)? onCheckboxStateChanged;
  final bool? initialCheckboxState;

  const OnboardingPage({
    super.key,
    required this.data,
    this.onNext,
    this.onPrevious,
    this.onSkip,
    this.onPushNotificationChoice,
    this.onNotificationTimeSelected,
    this.onCheckboxStateChanged,
    this.initialCheckboxState,
  });

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final List<bool> _checkboxStates = [];
  bool _singleCheckboxState = false;
  int? _selectedNotificationHour;
  int? _selectedNotificationMinute;

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
      // If notification times are shown and checkbox is checked, require time selection
      if (widget.data.showNotificationTimes && _singleCheckboxState) {
        return _selectedNotificationHour != null && _selectedNotificationMinute != null;
      }
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

                      // Notification Time Selection
                      if (widget.data.showNotificationTimes &&
                          widget.data.notificationTimes.isNotEmpty &&
                          _singleCheckboxState) ...[
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: MoodTheme.standard.cardColor.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: MoodTheme.standard.accentColor.withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Erinnerungszeit wählen:',
                                style: AppTheme.bodyStyle.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...widget.data.notificationTimes.map((time) {
                                final hour = time['hour'] as int;
                                final minute = time['minute'] as int;
                                final label = time['label'] as String?;
                                final isSelected = _selectedNotificationHour == hour && 
                                                   _selectedNotificationMinute == minute;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: InkWell(
                                    onTap: () async {
                                      setState(() {
                                        _selectedNotificationHour = hour;
                                        _selectedNotificationMinute = minute;
                                      });
                                      if (widget.onNotificationTimeSelected != null) {
                                        await widget.onNotificationTimeSelected!(hour, minute);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? MoodTheme.standard.accentColor.withValues(alpha: 0.3)
                                            : MoodTheme.standard.accentColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isSelected
                                              ? MoodTheme.standard.accentColor
                                              : MoodTheme.standard.accentColor.withValues(alpha: 0.3),
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle : Icons.access_time,
                                            color: MoodTheme.standard.accentColor,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              label ?? '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} Uhr',
                                              style: AppTheme.bodyStyle.copyWith(
                                                color: Colors.white,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              if (widget.data.showCheckbox &&
                  widget.data.checkboxText != null &&
                  widget.onSkip != null) ...[
                // Push notifications page - show both buttons (only when onSkip is provided)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: AppConstants.buttonHeight,
                        child: OutlinedButton(
                          onPressed: () async {
                            // Handle push notification choice in background
                            if (widget.onPushNotificationChoice != null) {
                              await widget.onPushNotificationChoice!(false);
                            }
                            // Navigate after completing onboarding
                            if (widget.onSkip != null) {
                              await widget.onSkip!();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: MoodTheme.standard.accentColor,
                            ),
                            foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                          ),
                          child: Text(
                            'Später',
                            style: AppTheme.buttonStyle.copyWith(
                              color: const Color.fromARGB(255, 0, 0, 0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: AppConstants.buttonHeight,
                        child: ElevatedButton(
                          onPressed: _canProceed
                              ? () async {
                                  // Handle push notification choice and WAIT for completion
                                  if (widget.onPushNotificationChoice != null) {
                                    await widget.onPushNotificationChoice!(true);
                                  }
                                  // Navigate to next page AFTER handling is complete
                                  if (widget.onNext != null) {
                                    widget.onNext!();
                                  }
                                }
                              : () {},
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
              ] else if (widget.data.showCheckbox &&
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
  final bool showNotificationTimes;
  final List<Map<String, dynamic>> notificationTimes;

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
    this.showNotificationTimes = false,
    this.notificationTimes = const [],
  });
}
