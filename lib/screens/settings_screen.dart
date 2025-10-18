import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../providers/app_provider.dart';
import '../models/user_prefs.dart';
import '../utils/app_theme.dart';
import 'home_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _vibrationEnabled = true;
  bool _notificationsEnabled = true;
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
      _notificationsEnabled = userPrefs.pushAllowed;
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
              subtitle: userPrefs.displayName ?? 'Nicht angemeldet',
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
              subtitle: 'Lokal gespeichert',
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

            // Notifications
            _buildNotificationItem(),

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

  Widget _buildNotificationItem() {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: moodTheme.accentColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          Icons.notifications,
          color: moodTheme.accentColor,
          size: 20,
        ),
      ),
      title: Text(
        'Benachrichtigungen',
        style: AppTheme.bodyStyle.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        _notificationsEnabled ? 'Aktiviert' : 'Deaktiviert',
        style: AppTheme.bodyStyle.copyWith(
          color: _notificationsEnabled
              ? moodTheme.accentColor
              : Colors.grey[400],
          fontSize: 12,
        ),
      ),
      trailing: Switch(
        value: _notificationsEnabled,
        onChanged: _handleNotificationToggle,
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
          'Profil bearbeiten',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Profil-Bearbeitung wird implementiert',
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
          'Synchronisation',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Deine Daten werden lokal gespeichert. Cloud-Synchronisation wird später implementiert.',
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

  Future<void> _handleNotificationToggle(bool value) async {
    try {
      final deviceService = ref.read(deviceServiceProvider);

      if (value) {
        // Enable notifications - request permission
        final hasPermission = await deviceService
            .requestNotificationPermission();
        setState(() {
          _notificationsEnabled = hasPermission;
        });

        if (hasPermission) {
          ref.read(userPrefsProvider.notifier).updatePushAllowed(true);
        } else {
          // Show dialog to go to settings
          _showNotificationPermissionDialog();
        }
      } else {
        // Disable notifications - open app settings
        await deviceService.openDeviceSettings();
        setState(() {
          _notificationsEnabled = false;
        });
        ref.read(userPrefsProvider.notifier).updatePushAllowed(false);
      }
    } catch (e) {
      debugPrint('Error handling notification toggle: $e');
    }
  }

  void _showNotificationPermissionDialog() {
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
          'Benachrichtigungen',
          style: AppTheme.headingStyle.copyWith(fontSize: 18),
        ),
        content: Text(
          'Um Benachrichtigungen zu aktivieren, gehe zu den Geräte-Einstellungen für Napolill.',
          style: AppTheme.bodyStyle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final deviceService = ref.read(deviceServiceProvider);
              await deviceService.openDeviceSettings();
            },
            style: TextButton.styleFrom(foregroundColor: moodTheme.accentColor),
            child: const Text('Einstellungen öffnen'),
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
          'Passe die App an deine Bedürfnisse an. Aktiviere Vibrationen, stelle die Lautstärke ein, aktiviere Benachrichtigungen oder überprüfe die Temperatur deines Geräts für optimale Performance.',
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
