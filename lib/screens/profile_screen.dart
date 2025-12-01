import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../providers/app_provider.dart';
import '../models/user_prefs.dart';
import '../services/sync_service.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import 'home_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late PageController _pageController;
  int _currentPage = 0;
  DateTime _selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userPrefs = ref.watch(userPrefsProvider);
    final statistics = ref.watch(statisticsProvider);

    final moodTheme = ref.watch(currentMoodThemeProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: moodTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(userPrefs),

              // Content
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildOverviewPage(userPrefs, statistics),
                    _buildCalendarPage(userPrefs),
                    _buildBadgesPage(userPrefs),
                  ],
                ),
              ),

              // Bottom navigation
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(UserPrefs userPrefs) {
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
                  Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentColor.withValues(alpha: 0.3),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/logo_napolill.png',
                      height: 80,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 48), // Platzhalter für symmetrisches Layout
        ],
      ),
    );
  }

  Widget _buildOverviewPage(
    UserPrefs userPrefs,
    AsyncValue<Map<String, dynamic>> statistics,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Profile card
          _buildProfileCard(userPrefs),

          const SizedBox(height: 24),

          // Statistics
          _buildStatisticsCard(statistics),

          const SizedBox(height: 24),

          // Recent activity
          _buildRecentActivityCard(),
        ],
      ),
    );
  }

  Widget _buildCalendarPage(UserPrefs userPrefs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Calendar
          _buildCalendarCard(),

          const SizedBox(height: 24),

          // Mood summary
          _buildMoodSummaryCard(),
        ],
      ),
    );
  }

  Widget _buildBadgesPage(UserPrefs userPrefs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Abzeichen
          _buildBadgesCard(),

          const SizedBox(height: 24),

          // Achievements
          _buildAchievementsCard(),
        ],
      ),
    );
  }

  Widget _buildProfileCard(UserPrefs userPrefs) {
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
          children: [
            // Avatar with edit button
            Stack(
              children: [
                GestureDetector(
                  onTap: () => _showProfileImageOptions(context, userPrefs),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: moodTheme.accentColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: moodTheme.accentColor.withValues(alpha: 0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: moodTheme.accentColor.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child:
                          userPrefs.profileImagePath != null &&
                              userPrefs.profileImagePath!.isNotEmpty
                          ? Image.file(
                              File(userPrefs.profileImagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 50,
                                );
                              },
                            )
                          : Icon(Icons.person, color: Colors.white, size: 50),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _showProfileImageOptions(context, userPrefs),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: moodTheme.accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              userPrefs.displayName ?? 'Nutzer',
              style: AppTheme.headingStyle.copyWith(fontSize: 24),
            ),

            const SizedBox(height: 8),

            // Topic and level
            Text(
              '${_getTopicDisplayName(userPrefs.selectedTopic)} • ${_getLevelDisplayName(userPrefs.level)}',
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // Join date
            Text(
              'Mitglied seit ${_formatDate(DateTime.now())}',
              style: AppTheme.bodyStyle.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard(AsyncValue<Map<String, dynamic>> statistics) {
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
              children: [
                Text(
                  'DEINE STATISTIKEN',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showProfileStatisticsInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            statistics.when(
              data: (data) => _buildStatisticsContent(data),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Text('Fehler: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsContent(Map<String, dynamic> data) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Gesamtzeit',
                _formatMinutes(data['totalListenMinutes'] ?? 0),
                Icons.timer,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Aktuelle Serie',
                '${data['currentStreak'] ?? 0} Tage',
                Icons.local_fire_department,
                Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Heute',
                _formatMinutes(data['todayListenMinutes'] ?? 0),
                Icons.today,
                Colors.green,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Affirmationen',
                '${data['totalAffirmations'] ?? 0}',
                Icons.record_voice_over,
                Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Aufnahmen',
                '${data['totalRecordings'] ?? 0}',
                Icons.mic,
                Colors.red,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Diese Woche',
                _formatMinutes(data['weekListenMinutes'] ?? 0),
                Icons.calendar_view_week,
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.headingStyle.copyWith(fontSize: 18, color: color),
          ),
          Text(
            label,
            style: AppTheme.bodyStyle.copyWith(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentActivities = ref.watch(recentActivitiesProvider);
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
              children: [
                Text(
                  'LETZTE AKTIVITÄTEN',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showRecentActivityInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            recentActivities.when(
              data: (activities) {
                if (activities.isEmpty) {
                  return Center(
                    child: Text(
                      'Noch keine Aktivitäten',
                      style: AppTheme.bodyDarkStyle.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  );
                }

                return Column(
                  children: activities
                      .take(3)
                      .map(
                        (activity) => _buildActivityItem(
                          _getActivityTitle(activity),
                          _formatActivityTime(activity.startedAt),
                          _getActivityIcon(activity.mode),
                          _getActivityColor(activity.mode),
                        ),
                      )
                      .toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Fehler beim Laden',
                  style: AppTheme.bodyDarkStyle.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    String title,
    String time,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                Text(
                  time,
                  style: AppTheme.bodyStyle.copyWith(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
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
              children: [
                Text(
                  'MOOD-KALENDER',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showCalendarInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Simple calendar grid
            _buildCalendarGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final moodTheme = ref.watch(currentMoodThemeProvider);
    final now = DateTime.now();
    final lastDay = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final userPrefs = ref.watch(userPrefsProvider);

    final isCurrentMonth =
        _selectedMonth.year == now.year && _selectedMonth.month == now.month;

    return Column(
      children: [
        // Month header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: _previousMonth,
              icon: Icon(Icons.chevron_left, color: moodTheme.accentColor),
            ),
            Text(
              '${_selectedMonth.month}/${_selectedMonth.year}',
              style: AppTheme.headingStyle.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: isCurrentMonth ? null : _nextMonth,
              icon: Icon(
                Icons.chevron_right,
                color: isCurrentMonth
                    ? Colors.grey.withValues(alpha: 0.3)
                    : moodTheme.accentColor,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 0.8, // Make cells taller
          ),
          itemCount: daysInMonth,
          itemBuilder: (context, index) {
            final day = index + 1;
            final dayDate = DateTime(
              _selectedMonth.year,
              _selectedMonth.month,
              day,
            );
            final isToday =
                dayDate.year == now.year &&
                dayDate.month == now.month &&
                dayDate.day == now.day;
            final moodForDay = _getMoodForDay(dayDate, userPrefs.moods);
            final hasMood = moodForDay != null && moodForDay.mood.isNotEmpty;

            return Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: hasMood
                    ? moodTheme.accentColor.withValues(alpha: 0.3)
                    : (isToday
                          ? moodTheme.accentColor.withValues(alpha: 0.15)
                          : Colors.transparent),
                borderRadius: BorderRadius.circular(8),
                border: isToday
                    ? Border.all(color: moodTheme.accentColor, width: 2)
                    : (hasMood
                          ? Border.all(
                              color: moodTheme.accentColor.withValues(
                                alpha: 0.4,
                              ),
                              width: 1,
                            )
                          : null),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: AppTheme.headingStyle.copyWith(
                        color: Colors.white,
                        fontWeight: isToday || hasMood
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    if (hasMood) ...[
                      const SizedBox(height: 1),
                      Text(
                        _getMoodEmoji(moodForDay.mood),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildMoodSummaryCard() {
    final moodStatistics = ref.watch(moodStatisticsProvider);
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
              children: [
                Text(
                  'MOOD-ÜBERSICHT',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showMoodOverviewInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            moodStatistics.when(
              data: (moodStats) {
                // Define all mood options with their emojis and colors
                final allMoods = [
                  {'mood': 'wuetend', 'emoji': '😠', 'color': Colors.red},
                  {'mood': 'traurig', 'emoji': '😢', 'color': Colors.blue},
                  {'mood': 'passiv', 'emoji': '😐', 'color': Colors.orange},
                  {'mood': 'froehlich', 'emoji': '😊', 'color': Colors.green},
                  {'mood': 'euphorisch', 'emoji': '🤩', 'color': Colors.purple},
                ];

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: allMoods.map((moodData) {
                    final mood = moodData['mood'] as String;
                    final emoji = moodData['emoji'] as String;
                    final color = moodData['color'] as Color;
                    final count = moodStats[mood] ?? 0;

                    return _buildMoodOverviewItem(
                      emoji,
                      count,
                      color,
                      _getMoodDisplayName(mood),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Fehler beim Laden',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodOverviewItem(
    String emoji,
    int count,
    Color color,
    String moodName,
  ) {
    return Column(
      children: [
        Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(emoji, style: const TextStyle(fontSize: 20)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          moodName,
          style: AppTheme.bodyStyle.copyWith(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBadgesCard() {
    final badges = ref.watch(badgesProvider);
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
              children: [
                Text(
                  'ABZEICHEN',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showBadgesInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            badges.when(
              data: (allBadges) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: allBadges.length,
                  itemBuilder: (context, index) {
                    final badge = allBadges[index];
                    final isEarned = badge['earned'] as bool;
                    final color = badge['color'] as Color;

                    return Container(
                      decoration: BoxDecoration(
                        gradient: isEarned
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withValues(alpha: 0.3),
                                  color.withValues(alpha: 0.2),
                                ],
                              )
                            : null,
                        color: !isEarned
                            ? Colors.grey.withValues(alpha: 0.1)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isEarned
                              ? color
                              : Colors.grey.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: isEarned
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _getIconFromString(badge['icon'] as String),
                            color: isEarned ? Colors.white : Colors.grey,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              badge['name'] as String,
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 9,
                                color: isEarned ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text(
                  'Fehler beim Laden',
                  style: AppTheme.bodyStyle.copyWith(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsCard() {
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
              children: [
                Text(
                  'ERFOLGE',
                  style: AppTheme.headingStyle.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _showAchievementsInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    color: moodTheme.accentColor,
                    size: 18,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Consumer(
              builder: (context, ref, child) {
                final statistics = ref.watch(statisticsProvider);
                final badges = ref.watch(badgesProvider);

                return statistics.when(
                  data: (stats) {
                    return badges.when(
                      data: (badgeList) {
                        return Column(
                          children: [
                            // Anmeldung & Erste Schritte
                            _buildAchievementItem(
                              'Willkommen',
                              'App-Anmeldung abgeschlossen',
                              Icons.person,
                              true,
                              current: 1,
                              target: 1,
                            ),
                            _buildAchievementItem(
                              'Erste Affirmation',
                              'Nimm deine erste Affirmation auf',
                              Icons.mic,
                              stats['totalAffirmations'] as int >= 1,
                              current: stats['totalAffirmations'] as int,
                              target: 1,
                            ),
                            _buildAchievementItem(
                              'Erste Meditation',
                              'Schließe deine erste Meditation ab',
                              Icons.play_arrow,
                              stats['totalListenMinutes'] as int > 0,
                              current: stats['totalListenMinutes'] as int > 0
                                  ? 1
                                  : 0,
                              target: 1,
                            ),
                            _buildAchievementItem(
                              'Erste Dauerschleife',
                              'Schließe deine erste Endlos-Session ab',
                              Icons.all_inclusive,
                              (badgeList.firstWhere(
                                    (badge) => badge['id'] == 'first_endless',
                                    orElse: () => {'earned': false},
                                  )['earned']
                                  as bool),
                              current:
                                  (badgeList.firstWhere(
                                        (badge) =>
                                            badge['id'] == 'first_endless',
                                        orElse: () => {'earned': false},
                                      )['earned']
                                      as bool)
                                  ? 1
                                  : 0,
                              target: 1,
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Streak-Abzeichen',
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: moodTheme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Streak-Badges (wichtigste Meilensteine)
                            _buildAchievementItem(
                              '3-Tage Serie',
                              'Meditiere 3 Tage in Folge',
                              Icons.local_fire_department,
                              stats['currentStreak'] as int >= 3,
                              current: stats['currentStreak'] as int,
                              target: 3,
                            ),
                            _buildAchievementItem(
                              '9-Tage Serie',
                              'Meditiere 9 Tage in Folge',
                              Icons.local_fire_department,
                              stats['currentStreak'] as int >= 9,
                              current: stats['currentStreak'] as int,
                              target: 9,
                            ),
                            _buildAchievementItem(
                              '21-Tage Serie',
                              'Meditiere 21 Tage in Folge',
                              Icons.local_fire_department,
                              stats['currentStreak'] as int >= 21,
                              current: stats['currentStreak'] as int,
                              target: 21,
                            ),
                            _buildAchievementItem(
                              '30-Tage Serie',
                              'Meditiere 30 Tage in Folge',
                              Icons.local_fire_department,
                              stats['currentStreak'] as int >= 30,
                              current: stats['currentStreak'] as int,
                              target: 30,
                            ),

                            const SizedBox(height: 8),
                            Text(
                              'Meisterschaft',
                              style: AppTheme.bodyStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: moodTheme.accentColor,
                              ),
                            ),
                            const SizedBox(height: 4),

                            _buildAchievementItem(
                              'Meister',
                              'Schließe 100 Meditationen ab',
                              Icons.emoji_events,
                              false, // Will be calculated from session count
                              current: 0,
                              target: 100,
                            ),
                          ],
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Text(
                          'Fehler beim Laden',
                          style: AppTheme.bodyStyle.copyWith(
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Text(
                      'Fehler beim Laden',
                      style: AppTheme.bodyStyle.copyWith(
                        color: Colors.grey[400],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementItem(
    String title,
    String description,
    IconData icon,
    bool completed, {
    int? current,
    int? target,
  }) {
    final moodTheme = ref.watch(currentMoodThemeProvider);
    final progressText = (current != null && target != null)
        ? '$current/$target'
        : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: completed ? moodTheme.accentColor : Colors.grey,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyStyle.copyWith(
                    fontWeight: FontWeight.w600,
                    color: completed ? Colors.white : Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        description,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 12,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                    if (progressText.isNotEmpty)
                      Text(
                        progressText,
                        style: AppTheme.bodyStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: completed
                              ? moodTheme.accentColor
                              : Colors.grey[400],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (completed)
            Icon(Icons.check_circle, color: moodTheme.accentColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      height: 59,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildNavItem('Übersicht', Icons.dashboard, 0),
          _buildNavItem('Kalender', Icons.calendar_month, 1),
          _buildNavItem('Abzeichen', Icons.emoji_events, 2),
        ],
      ),
    );
  }

  Widget _buildNavItem(String label, IconData icon, int index) {
    final isSelected = _currentPage == index;

    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.secondaryColor : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTheme.bodyDarkStyle.copyWith(
                color: isSelected ? AppTheme.secondaryColor : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Activity Info Dialog
  void _showRecentActivityInfo(BuildContext context) {
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
          'LETZTE AKTIVITÄTEN',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Hier siehst du deine letzten Aktivitäten:\n\n'
          '• Welche Affirmationen du zuletzt gehört hast\n'
          '• Wann du sie gehört hast (Heute, Gestern, etc.)\n'
          '• Aus welcher Kategorie die Affirmationen stammen\n\n'
          'So behältst du den Überblick über deine Nutzung und kannst deine Favoriten wiederfinden!',
          style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Verstanden',
              style: TextStyle(
                color: moodTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile Statistics Info Dialog
  void _showProfileStatisticsInfo(BuildContext context) {
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
          'DEINE STATISTIKEN',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Hier siehst du eine Übersicht deiner Nutzung:\n\n'
          '• Gesamte Hörzeit in Minuten\n'
          '• Deine aktuelle Streak (aufeinanderfolgende Tage)\n'
          '• Hörzeit heute, gestern und diese Woche\n'
          '• Anzahl der gehörten Affirmationen\n'
          '• Anzahl deiner eigenen Aufnahmen\n\n'
          'Nutze diese Statistiken, um deinen Fortschritt zu verfolgen und motiviert zu bleiben!',
          style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Verstanden',
              style: TextStyle(
                color: moodTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCalendarInfo(BuildContext context) {
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
          'MOOD-KALENDER',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Dein persönlicher Mood-Kalender zeigt dir:\n\n'
          '• Deine tägliche Stimmung als Emoji\n'
          '• Stimmungsmuster über den Monat hinweg\n'
          '• Navigiere durch vergangene Monate\n\n'
          'Wähle jeden Tag deine Stimmung im Home Screen aus, um deine emotionale Entwicklung zu tracken und Muster zu erkennen! 📅',
          style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Verstanden',
              style: TextStyle(
                color: moodTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoodOverviewInfo(BuildContext context) {
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
          'MOOD-ÜBERSICHT',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Deine Mood-Übersicht zeigt dir:\n\n'
          '• Wie oft du jede Stimmung ausgewählt hast\n'
          '• Eine visuelle Zusammenfassung aller Emotionen\n'
          '• Welche Stimmungen bei dir am häufigsten vorkommen\n\n'
          'Nutze diese Übersicht, um deine emotionalen Muster besser zu verstehen und bewusster mit deinen Gefühlen umzugehen! 💭',
          style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Verstanden',
              style: TextStyle(
                color: moodTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBadgesInfo(BuildContext context) {
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
          'ABZEICHEN',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Sammle Abzeichen für deine Erfolge:\n\n'
          '• Anmeldung & erste Schritte\n'
          '• Erste Affirmation, Meditation & Dauerschleife\n'
          '• Streak-Abzeichen für aufeinanderfolgende Tage (3, 6, 9, ... 30 Tage)\n'
          '• Meister-Abzeichen für 100 Meditationen\n\n'
          'Farbige Abzeichen hast du bereits freigeschaltet, graue Abzeichen kannst du noch erreichen! 🏆',
          style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Verstanden',
              style: TextStyle(
                color: moodTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAchievementsInfo(BuildContext context) {
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
          'ERFOLGE',
          style: AppTheme.headingStyle.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Deine Erfolge zeigen dir deinen Fortschritt:\n\n'
          '• Anmeldung & Erste Schritte: Willkommen, erste Affirmation, erste Meditation, erste Dauerschleife\n'
          '• Streak-Abzeichen: Halte deine tägliche Routine aufrecht\n'
          '• Meisterschaft: Erreiche 100 Meditationen\n\n'
          'Grüne Häkchen zeigen abgeschlossene Erfolge. Nutze diese Liste als Motivation, um alle Abzeichen zu sammeln! ✅',
          style: AppTheme.bodyStyle.copyWith(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Verstanden',
              style: TextStyle(
                color: moodTheme.accentColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Profile Image Options Dialog
  void _showProfileImageOptions(BuildContext context, UserPrefs userPrefs) {
    final moodTheme = ref.read(currentMoodThemeProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              moodTheme.cardColor.withValues(alpha: 0.95),
              moodTheme.cardColor.withValues(alpha: 0.98),
            ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: moodTheme.accentColor,
                ),
                title: const Text(
                  'Aus Galerie wählen',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: moodTheme.accentColor),
                title: const Text(
                  'Foto aufnehmen',
                  style: TextStyle(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              if (userPrefs.profileImagePath != null &&
                  userPrefs.profileImagePath!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text(
                    'Foto entfernen',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _removeProfileImage();
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      await _saveProfileImage(image.path);
    }
  }

  Future<void> _pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );

    if (image != null) {
      await _saveProfileImage(image.path);
    }
  }

  Future<void> _saveProfileImage(String imagePath) async {
    try {
      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final fileName =
          'profile_${DateTime.now().millisecondsSinceEpoch}${path.extension(imagePath)}';
      final savedImagePath = path.join(appDir.path, fileName);

      // Copy image to app directory
      final File imageFile = File(imagePath);
      await imageFile.copy(savedImagePath);

      // Update user prefs
      await ref
          .read(userPrefsProvider.notifier)
          .updateProfileImage(savedImagePath);

      // Trigger sync to Firebase
      await ref.read(syncServiceProvider).pushProfileImage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilbild erfolgreich aktualisiert'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeProfileImage() async {
    try {
      final userPrefs = ref.read(userPrefsProvider);

      // Delete old image file if exists
      if (userPrefs.profileImagePath != null &&
          userPrefs.profileImagePath!.isNotEmpty) {
        final File oldImage = File(userPrefs.profileImagePath!);
        if (await oldImage.exists()) {
          await oldImage.delete();
        }
      }

      // Update user prefs
      await ref.read(userPrefsProvider.notifier).updateProfileImage(null);

      // Trigger sync to Firebase (remove from cloud)
      await ref.read(syncServiceProvider).pushProfileImage();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profilbild entfernt'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Entfernen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

  String _formatDate(DateTime date) {
    return '${date.day}.${date.month}.${date.year}';
  }

  String _formatMinutes(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}Min';
  }

  String _getActivityTitle(dynamic activity) {
    switch (activity.mode) {
      case 'meditation':
        return 'Meditation abgeschlossen';
      case 'endless':
        return 'Dauerschleife beendet';
      default:
        return 'Aktivität abgeschlossen';
    }
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  void _nextMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    // Only allow navigation up to current month
    if (nextMonth.isBefore(DateTime(now.year, now.month + 1))) {
      setState(() {
        _selectedMonth = nextMonth;
      });
    }
  }

  String _formatActivityTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final activityDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (activityDate == today) {
      return 'Heute, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (activityDate == today.subtract(const Duration(days: 1))) {
      return 'Gestern, ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      final difference = today.difference(activityDate).inDays;
      return 'Vor $difference Tagen';
    }
  }

  IconData _getActivityIcon(String mode) {
    switch (mode) {
      case 'meditation':
        return Icons.check_circle;
      case 'endless':
        return Icons.repeat;
      default:
        return Icons.play_circle;
    }
  }

  Color _getActivityColor(String mode) {
    switch (mode) {
      case 'meditation':
        return Colors.green;
      case 'endless':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  MoodEntry? _getMoodForDay(DateTime date, List<MoodEntry> moods) {
    return moods.firstWhere(
      (mood) =>
          mood.date.year == date.year &&
          mood.date.month == date.month &&
          mood.date.day == date.day,
      orElse: () => MoodEntry(date: date, mood: ''),
    );
  }

  String _getMoodEmoji(String mood) {
    switch (mood) {
      case 'wuetend':
        return '😠';
      case 'traurig':
        return '😢';
      case 'passiv':
        return '😐';
      case 'froehlich':
        return '😊';
      case 'euphorisch':
        return '🤩';
      default:
        return '';
    }
  }

  String _getMoodDisplayName(String mood) {
    switch (mood) {
      case 'wuetend':
        return 'Wütend';
      case 'traurig':
        return 'Traurig';
      case 'passiv':
        return 'Passiv';
      case 'froehlich':
        return 'Fröhlich';
      case 'euphorisch':
        return 'Euphorisch';
      default:
        return mood;
    }
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName) {
      case 'person':
        return Icons.person;
      case 'play_arrow':
        return Icons.play_arrow;
      case 'all_inclusive':
        return Icons.all_inclusive;
      case 'local_fire_department':
        return Icons.local_fire_department;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'record_voice_over':
        return Icons.record_voice_over;
      case 'mic':
        return Icons.mic;
      case 'timer':
        return Icons.timer;
      default:
        return Icons.star;
    }
  }
}
