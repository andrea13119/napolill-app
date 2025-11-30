import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/user_prefs.dart';
import '../services/sync_service.dart';
import '../utils/app_theme.dart';
import '../utils/mood_theme.dart';
import 'home_screen.dart';
import 'auth_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _vibrationEnabled = true;
  double _defaultBackgroundVolume = 0.5;
  double? _deviceTemperature;
  String? _temperatureColor;
  String _appVersion = '2.0.0'; // Fallback version

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadDeviceTemperature();
    _loadAppVersion();
  }

  void _loadSettings() {
    final userPrefs = ref.read(userPrefsProvider);
    setState(() {
      _vibrationEnabled = userPrefs.vibrationEnabled ?? true;
      _defaultBackgroundVolume = userPrefs.defaultBackgroundVolume ?? 0.5;
    });
  }

  Future<void> _loadDeviceTemperature() async {
    try {
      final deviceService = ref.read(deviceServiceProvider);
      final temperature = await deviceService.getDeviceTemperature();
      final color = temperature != null
          ? deviceService.getTemperatureColor(temperature)
          : null;

      setState(() {
        _deviceTemperature = temperature;
        _temperatureColor = color;
      });
    } catch (e) {
      debugPrint('Error loading device temperature: $e');
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
      debugPrint('App version loaded: $_appVersion');
    } catch (e) {
      debugPrint('Error loading app version: $e');
      // Keep fallback version
    }
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = ref.watch(userPrefsProvider);
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: moodTheme.backgroundGradient),
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
                    children: [
                      // Account section
                      _buildAccountSection(userPrefs),

                      const SizedBox(height: 24),

                      // App settings
                      _buildAppSettingsSection(),

                      const SizedBox(height: 24),

                      // Info Hub
                      _buildInfoHubSection(),

                      const SizedBox(height: 24),

                      // About
                      _buildAboutSection(),
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
            onPressed: () {
              // Navigate to HomeScreen and reset navigation to tab 0
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const HomeScreen(initialTabIndex: 0),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          Expanded(
            child: Center(
              child: Column(
                children: [
                  Text(
                    'Einstellungen',
                    style: AppTheme.headingStyle.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Container(width: 100, height: 1, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildAccountSection(UserPrefs userPrefs) {
    final moodTheme = ref.watch(currentMoodThemeProvider);
    final firebaseUser = ref.watch(currentUserProvider);

    // Determine profile subtitle based on UserPrefs displayName or Firebase email
    String profileSubtitle;
    if (firebaseUser != null) {
      // User is authenticated - show display name from UserPrefs or email
      profileSubtitle =
          userPrefs.displayName ?? firebaseUser.email ?? 'Angemeldet';
    } else {
      // User is not authenticated
      profileSubtitle = 'Nicht angemeldet';
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodTheme.cardColor.withValues(alpha: 0.75),
            moodTheme.cardColor.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moodTheme.accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: moodTheme.accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ACCOUNT',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAccountInfoDialog(),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Profile info
            _buildSettingItem(
              icon: Icons.person,
              title: 'Profil',
              subtitle: profileSubtitle,
              onTap: _showProfileDialog,
            ),

            _buildSettingItem(
              icon: Icons.subscriptions,
              title: 'Abonnement',
              subtitle: 'Kostenlos',
              onTap: _showSubscriptionDialog,
            ),

            _buildSettingItem(
              icon: Icons.cloud_sync,
              title: 'Synchronisation',
              subtitle: ref.watch(userPrefsProvider).syncEnabled
                  ? 'Mit Firebase synchronisiert'
                  : 'Lokal gespeichert',
              onTap: _showSyncDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodTheme.cardColor.withValues(alpha: 0.75),
            moodTheme.cardColor.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moodTheme.accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: moodTheme.accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'APP-EINSTELLUNGEN',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAppSettingsInfoDialog(),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Vibration
            _buildSwitchItem(
              icon: Icons.vibration,
              title: 'Vibration',
              subtitle: 'Haptisches Feedback für die App',
              value: _vibrationEnabled,
              onChanged: (value) {
                setState(() {
                  _vibrationEnabled = value;
                });
                ref.read(userPrefsProvider.notifier).updateVibration(value);
              },
            ),

            // Temperature
            _buildTemperatureItem(),

            // Default background volume
            _buildSliderItem(
              icon: Icons.volume_up,
              title: 'Standard-Hintergrundlautstärke',
              subtitle: '${(_defaultBackgroundVolume * 100).round()}%',
              value: _defaultBackgroundVolume,
              onChanged: (value) {
                setState(() {
                  _defaultBackgroundVolume = value;
                });
                ref
                    .read(userPrefsProvider.notifier)
                    .updateDefaultBackgroundVolume(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoHubSection() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodTheme.cardColor.withValues(alpha: 0.75),
            moodTheme.cardColor.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moodTheme.accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: moodTheme.accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'INFO-HUB',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showInfoHubInfoDialog(),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSettingItem(
              icon: Icons.newspaper,
              title: 'Neuigkeiten',
              subtitle: 'Aktuelle Updates',
              onTap: () => _openExternalLink('https://napolill.com/news'),
            ),

            _buildSettingItem(
              icon: Icons.science,
              title: 'Wissenschaft',
              subtitle: 'Studien & Forschung',
              onTap: () => _openExternalLink('https://napolill.com/science'),
            ),

            _buildSettingItem(
              icon: Icons.privacy_tip,
              title: 'Datenschutz',
              subtitle: 'Datenschutzerklärung',
              onTap: () => _openExternalLink('https://napolill.com/privacy'),
            ),

            _buildSettingItem(
              icon: Icons.description,
              title: 'AGB',
              subtitle: 'Allgemeine Geschäftsbedingungen',
              onTap: () => _openExternalLink('https://napolill.com/terms'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            moodTheme.cardColor.withValues(alpha: 0.75),
            moodTheme.cardColor.withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: moodTheme.accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: moodTheme.accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'ÜBER DIE APP',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAboutInfoDialog(),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildSettingItem(
              icon: Icons.info,
              title: 'Version',
              subtitle: _appVersion,
              onTap: null,
            ),

            _buildSettingItem(
              icon: Icons.help,
              title: 'Hilfe & Support',
              subtitle: 'FAQ und Kontakt',
              onTap: () => _openExternalLink('https://napolill.com/support'),
            ),

            _buildSettingItem(
              icon: Icons.star,
              title: 'Bewerten',
              subtitle: 'App Store bewerten',
              onTap: _showRatingDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: moodTheme.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: moodTheme.accentColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTheme.bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodyStyle.copyWith(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right,
              color: moodTheme.accentColor.withValues(alpha: 0.6),
            )
          : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: moodTheme.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: moodTheme.accentColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTheme.bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTheme.bodyStyle.copyWith(
          color: Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: moodTheme.accentColor,
        activeTrackColor: moodTheme.accentColor.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildTemperatureItem() {
    final moodTheme = ref.watch(currentMoodThemeProvider);
    String temperatureText = 'Lädt...';
    Color temperatureColor = Colors.grey;

    if (_deviceTemperature != null) {
      temperatureText = '${_deviceTemperature!.toStringAsFixed(1)}°C';
      switch (_temperatureColor) {
        case 'green':
          temperatureColor = Colors.green;
          break;
        case 'red':
          temperatureColor = Colors.red;
          break;
        case 'orange':
          temperatureColor = Colors.orange;
          break;
        default:
          temperatureColor = Colors.grey;
      }
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: moodTheme.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.thermostat, color: moodTheme.accentColor, size: 20),
      ),
      title: Text(
        'Geräte-Temperatur',
        style: AppTheme.bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        temperatureText,
        style: AppTheme.bodyStyle.copyWith(
          color: temperatureColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      trailing: IconButton(
        icon: Icon(Icons.refresh, color: moodTheme.accentColor),
        onPressed: _loadDeviceTemperature,
      ),
    );
  }

  Widget _buildSliderItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: moodTheme.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: moodTheme.accentColor, size: 20),
      ),
      title: Text(
        title,
        style: AppTheme.bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: AppTheme.bodyStyle.copyWith(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Slider(
            value: value,
            onChanged: onChanged,
            activeColor: moodTheme.accentColor,
            inactiveColor: Colors.grey.withValues(alpha: 0.3),
            min: 0.0,
            max: 1.0,
            divisions: 10,
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);
    final user = ref.read(currentUserProvider);
    final userPrefs = ref.read(userPrefsProvider);
    final isAuthenticated = user != null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'Profil',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isAuthenticated)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Nicht angemeldet',
                    style: AppTheme.bodyStyle.copyWith(
                      color: Colors.grey[400],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else ...[
                // E-Mail
                _buildProfileInfoRow(
                  icon: Icons.email,
                  label: 'E-Mail',
                  value: user.email ?? 'Nicht verfügbar',
                  moodTheme: moodTheme,
                ),
                const SizedBox(height: 12),
                // Display Name (editable)
                _buildEditableProfileInfoRow(
                  icon: Icons.person,
                  label: 'Anzeigename',
                  value: userPrefs.displayName ?? 'Kein Name gesetzt',
                  moodTheme: moodTheme,
                  onEdit: () {
                    Navigator.of(context).pop();
                    _showEditDisplayNameDialog();
                  },
                ),
                const SizedBox(height: 12),
                // E-Mail Verifizierung
                _buildEmailVerificationRow(
                  isVerified: user.emailVerified,
                  moodTheme: moodTheme,
                  user: user,
                ),
                const SizedBox(height: 24),
                // Buttons
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showResetPasswordDialog();
                    },
                    icon: const Icon(Icons.lock_reset, size: 20),
                    label: const Text('Passwort zurücksetzen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: moodTheme.accentColor.withValues(
                        alpha: 0.2,
                      ),
                      foregroundColor: moodTheme.accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showSignOutConfirmationDialog();
                    },
                    icon: const Icon(Icons.logout, size: 20),
                    label: const Text('Abmelden'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange.withValues(alpha: 0.2),
                      foregroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _showDeleteAccountConfirmationDialog();
                    },
                    icon: const Icon(Icons.delete_forever, size: 20),
                    label: const Text('Account löschen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.2),
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required MoodTheme moodTheme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: moodTheme.accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditableProfileInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required MoodTheme moodTheme,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: moodTheme.accentColor, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onEdit,
          icon: Icon(Icons.edit, color: moodTheme.accentColor, size: 20),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  Widget _buildEmailVerificationRow({
    required bool isVerified,
    required MoodTheme moodTheme,
    required User user,
  }) {
    return Row(
      children: [
        Icon(
          isVerified ? Icons.verified : Icons.warning_amber_rounded,
          color: isVerified ? Colors.green : Colors.orange,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'E-Mail-Verifizierung',
                style: AppTheme.bodyStyle.copyWith(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                isVerified ? 'E-Mail verifiziert' : 'E-Mail nicht verifiziert',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isVerified ? Colors.green : Colors.orange,
                ),
              ),
            ],
          ),
        ),
        if (!isVerified)
          TextButton(
            onPressed: () => _handleResendVerificationEmail(user),
            child: Text(
              'Erneut senden',
              style: TextStyle(color: moodTheme.accentColor, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _handleResendVerificationEmail(User user) async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendEmailVerification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Verifizierungs-E-Mail wurde gesendet'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending verification email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetPasswordDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);
    final user = ref.read(currentUserProvider);
    final emailController = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'Passwort zurücksetzen',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Gib deine E-Mail-Adresse ein, um ein neues Passwort anzufordern.',
              style: AppTheme.bodyStyle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: AppTheme.bodyStyle.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'E-Mail',
                labelStyle: AppTheme.bodyStyle.copyWith(
                  color: Colors.grey[400],
                ),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: moodTheme.accentColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              final email = emailController.text.trim();
              if (email.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte gib eine E-Mail-Adresse ein'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final authService = ref.read(authServiceProvider);
                await authService.resetPassword(email: email);
                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('E-Mail wurde gesendet'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('Senden'),
          ),
        ],
      ),
    );
  }

  void _showSignOutConfirmationDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'Abmelden',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Möchtest du dich wirklich abmelden?',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleSignOut();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.orange),
            child: const Text('Abmelden'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();

      if (mounted) {
        // Navigate to AuthScreen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Abmelden: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showDeleteAccountConfirmationDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.red.withValues(alpha: 0.5), width: 2),
        ),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Account löschen',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 18,
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Achtung: Diese Aktion kann nicht rückgängig gemacht werden!',
              style: AppTheme.bodyStyle.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Wenn du deinen Account löschst, werden:',
              style: AppTheme.bodyStyle,
            ),
            const SizedBox(height: 8),
            Text(
              '• Alle deine Daten dauerhaft gelöscht\n'
              '• Alle lokalen Einstellungen zurückgesetzt\n'
              '• Du musst dich neu registrieren, um die App wieder zu nutzen',
              style: AppTheme.bodyStyle.copyWith(
                fontSize: 12,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Bist du dir sicher, dass du deinen Account löschen möchtest?',
              style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleDeleteAccount();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    try {
      final authService = ref.read(authServiceProvider);
      final user = ref.read(currentUserProvider);

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kein angemeldeter User gefunden'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Check if user is signed in with Google
      bool isGoogleUser = authService.isSignedInWithGoogle();

      if (isGoogleUser) {
        // Google user - deleteAccount will handle re-authentication automatically
        await authService.deleteAccount();
      } else {
        // Email/Password user - need to get password from user first
        final result = await _showReAuthPasswordDialog(user.email ?? '');
        if (!result.success) {
          return; // User canceled
        }
        // Delete account with credentials for re-authentication
        await authService.deleteAccount(
          email: user.email,
          password: result.password,
        );
      }

      // Reset local user preferences
      await ref.read(userPrefsProvider.notifier).resetForTesting();

      if (mounted) {
        // Navigate to AuthScreen and clear navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account wurde erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        String errorMessage = 'Fehler beim Löschen';
        if (e.code == 'requires-recent-login') {
          errorMessage =
              'Bitte melde dich erneut an, um diese Aktion durchzuführen';
        } else if (e.message != null) {
          errorMessage = e.message!;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      debugPrint('Error deleting account: $e');
      if (mounted) {
        String errorMessage = e.toString();
        if (errorMessage.contains('requires-recent-login')) {
          errorMessage =
              'Bitte melde dich erneut an, um diese Aktion durchzuführen';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<({bool success, String password})> _showReAuthPasswordDialog(
    String email,
  ) async {
    final passwordController = TextEditingController();
    final moodTheme = ref.read(currentMoodThemeProvider);
    bool success = false;
    String password = '';

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'Erneute Anmeldung erforderlich',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Um deinen Account zu löschen, musst du dich erneut anmelden.',
              style: AppTheme.bodyStyle,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: AppTheme.bodyStyle,
              decoration: InputDecoration(
                labelText: 'Passwort',
                labelStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[800],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey[600]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: moodTheme.accentColor),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              password = passwordController.text;
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Bitte gib dein Passwort ein'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                final authService = ref.read(authServiceProvider);
                await authService.reauthenticateWithEmailAndPassword(
                  email: email,
                  password: password,
                );
                success = true;
                if (!context.mounted) return;
                Navigator.of(context).pop();
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Falsches Passwort. Bitte versuche es erneut.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );

    passwordController.dispose();
    return (success: success, password: password);
  }

  Future<void> _showEditDisplayNameDialog() async {
    final moodTheme = ref.read(currentMoodThemeProvider);
    final userPrefs = ref.read(userPrefsProvider);
    final displayNameController = TextEditingController(
      text: userPrefs.displayName ?? '',
    );
    bool reopenProfile = false; // signal to reopen profile after dialog closes

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: moodTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: moodTheme.accentColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          title: Text(
            'Anzeigename ändern',
            style: AppTheme.headingStyle.copyWith(fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gib einen neuen Anzeigenamen ein:',
                style: AppTheme.bodyStyle,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: displayNameController,
                style: AppTheme.bodyStyle,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Anzeigename',
                  labelStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[600]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: moodTheme.accentColor),
                  ),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (!context.mounted) return;
                reopenProfile = true;
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () async {
                final newDisplayName = displayNameController.text.trim();
                if (newDisplayName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Bitte gib einen Namen ein'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (newDisplayName.length > 50) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Der Name darf maximal 50 Zeichen lang sein',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                // Get the value before async operations to avoid using disposed controller
                final nameToSave = newDisplayName;

                try {
                  // Update in UserPrefs only (no Firebase update needed)
                  await ref
                      .read(userPrefsProvider.notifier)
                      .updateDisplayName(nameToSave);

                  // Push prefs immediately so displayName is reflected in Firestore
                  await ref.read(syncServiceProvider).pushUserPrefsIfEnabled();

                  // Close dialog - controller will be disposed in the .then() callback
                  if (!context.mounted) return;
                  reopenProfile = true;
                  Navigator.of(context).pop();

                  if (!mounted || !context.mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Anzeigename wurde erfolgreich geändert'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                } catch (e) {
                  debugPrint('Error updating display name: $e');
                  // Don't dispose controller on error, let user try again or close dialog manually
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Ändern: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: moodTheme.accentColor,
              ),
              child: const Text('Speichern'),
            ),
          ],
        );
      },
    ).then((_) {
      // Do not dispose the controller here to avoid rebuilds during pop using a disposed instance
      // Reopen profile dialog only after full close and next frame
      // Optionally reopen profile dialog only after full close and next frame
      if (reopenProfile && mounted && context.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && context.mounted) {
            _showProfileDialog();
          }
        });
      }
    });
  }

  void _showSubscriptionDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'Abonnement',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Aktuell nutzt du die kostenlose Version. Premium-Features werden später verfügbar sein.',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSyncDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);
    final userPrefs = ref.read(userPrefsProvider);
    bool enabled = userPrefs.syncEnabled;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: moodTheme.cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: moodTheme.accentColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            title: Text(
              'Synchronisation',
              style: AppTheme.headingStyle.copyWith(fontSize: 18),
            ),
            content: RadioGroup<bool>(
              groupValue: enabled,
              onChanged: (value) {
                if (value == null) return;
                setState(() => enabled = value);
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RadioListTile<bool>(
                    value: false,
                    title: const Text('Nur lokal speichern'),
                    subtitle: const Text(
                      'Keine Datenübertragung, offline nutzbar',
                    ),
                    selected: !enabled,
                  ),
                  RadioListTile<bool>(
                    value: true,
                    title: const Text('Mit Firebase synchronisieren'),
                    subtitle: const Text('Daten zwischen Geräten abgleichen'),
                    selected: enabled,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
                child: const Text('Abbrechen'),
              ),
              TextButton(
                onPressed: () async {
                  await ref
                      .read(userPrefsProvider.notifier)
                      .updateSyncEnabled(enabled);
                  // Push user_prefs immediately so Cloud reflects new choice
                  // Use force=true to push even when disabling sync
                  await ref.read(syncServiceProvider).pushUserPrefsIfEnabled(force: true);
                  if (enabled) {
                    // Kein Sofort-Pull nötig – passiert beim App-Start/Login
                  }
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        enabled
                            ? 'Firebase-Synchronisation aktiviert'
                            : 'Nur lokale Speicherung aktiviert',
                      ),
                      backgroundColor: enabled ? Colors.green : Colors.orange,
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: moodTheme.accentColor,
                ),
                child: const Text('Speichern'),
              ),
              if (enabled)
                TextButton(
                  onPressed: () async {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Synchronisation gestartet'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                    await ref.read(syncServiceProvider).syncFromCloudDelta();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Synchronisation abgeschlossen'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  child: const Text('Jetzt synchronisieren'),
                ),
              TextButton(
                onPressed: () async {
                  // Full push + pull
                  await ref.read(syncServiceProvider).pushAll();
                  await ref.read(syncServiceProvider).syncFromCloudDelta();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Alles synchronisiert'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                child: const Text('Alles synchronisieren'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openExternalLink(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Link konnte nicht geöffnet werden: $url'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error opening external link: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Öffnen des Links'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showRatingDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'App bewerten',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Bewerte Napolill im App Store und hilf anderen Nutzern!',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAccountInfoDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'ACCOUNT',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Hier kannst du dein Profil verwalten, Abonnement-Einstellungen anpassen und deine Daten synchronisieren. Alle deine persönlichen Einstellungen werden hier zentral verwaltet.',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAppSettingsInfoDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'APP-EINSTELLUNGEN',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Passe die App an deine Bedürfnisse an. Aktiviere Vibrationen, stelle die Lautstärke ein oder überprüfe die Temperatur deines Geräts für optimale Performance.',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showInfoHubInfoDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'INFO-HUB',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Bleibe auf dem Laufenden mit unseren neuesten Nachrichten, Updates und wichtigen Ankündigungen. Hier findest du alle aktuellen Informationen rund um Napolill.',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAboutInfoDialog() {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: moodTheme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        title: Text(
          'ÜBER DIE APP',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Erfahre mehr über Napolill, bewerten die App im Store, kontaktiere uns bei Fragen oder schaue dir unsere Datenschutzerklärung und Nutzungsbedingungen an.',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
