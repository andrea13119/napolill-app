import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/constants.dart';
import '../providers/app_provider.dart';

class BottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final Function(int)? onTap;

  const BottomNavigation({super.key, required this.currentIndex, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodTheme = ref.watch(currentMoodThemeProvider);
    // Hole die tatsächliche Höhe der System-Navigationsleiste
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    // Container-Höhe = Inhalt (80) + System-Navigationsleiste (wenn vorhanden)
    // So bleibt der Inhalt immer 80 Pixel hoch, unabhängig von der System-Navigationsleiste
    final contentHeight = 80.0;
    final containerHeight = contentHeight + bottomPadding;
    // Padding für System-Navigationsleiste: verwende tatsächliche Höhe oder Mindestabstand von 24
    final safeBottomPadding = bottomPadding > 0 ? bottomPadding : 24.0;
    
    return Container(
      height: containerHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            moodTheme.bottomNavColor.withValues(alpha: 0.9),
            moodTheme.bottomNavColor.withValues(alpha: 0.95),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: moodTheme.accentColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: -5,
          ),
          BoxShadow(
            color: moodTheme.accentColor.withValues(alpha: 0.1),
            blurRadius: 15,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
          top: 0,
          bottom: safeBottomPadding,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              icon: Icons.home,
              label: AppStrings.home,
              index: 0,
              isActive: currentIndex == 0,
              ref: ref,
            ),
            _buildNavItem(
              icon: Icons.folder,
              label: AppStrings.mediathek,
              index: 1,
              isActive: currentIndex == 1,
              ref: ref,
            ),
            _buildNavItem(
              icon: Icons.person,
              label: AppStrings.profil,
              index: 2,
              isActive: currentIndex == 2,
              ref: ref,
            ),
            _buildNavItem(
              icon: Icons.settings,
              label: AppStrings.einstellungen,
              index: 3,
              isActive: currentIndex == 3,
              ref: ref,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isActive,
    required WidgetRef ref,
  }) {
    final moodTheme = ref.watch(currentMoodThemeProvider);

    return GestureDetector(
      onTap: () => onTap?.call(index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: isActive
            ? BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: moodTheme.accentColor.withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive
                  ? moodTheme.accentColor
                  : Colors.white.withValues(alpha: 0.7),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? moodTheme.accentColor
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 1),
                height: 2,
                width: 16,
                decoration: BoxDecoration(
                  color: moodTheme.accentColor,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
