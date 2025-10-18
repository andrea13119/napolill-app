import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../utils/app_theme.dart';

class StreakRing extends StatelessWidget {
  final int currentStreak;
  final int targetStreak;
  final double size;

  const StreakRing({
    super.key,
    required this.currentStreak,
    required this.targetStreak,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final progress = currentStreak / targetStreak;
    final angle = 2 * math.pi * progress;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
            ),
          ),

          // Progress arc
          CustomPaint(
            size: Size(size, size),
            painter: StreakRingPainter(
              progress: progress,
              angle: angle,
              color: AppTheme.secondaryColor,
              strokeWidth: 8,
            ),
          ),

          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Days', style: AppTheme.captionStyle.copyWith(fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '$currentStreak / $targetStreak',
                style: AppTheme.headingStyle.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Badge icon (cowboy hat)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.brown,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StreakRingPainter extends CustomPainter {
  final double progress;
  final double angle;
  final Color color;
  final double strokeWidth;

  StreakRingPainter({
    required this.progress,
    required this.angle,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        angle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(StreakRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.angle != angle ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
