import 'package:flutter/material.dart';

import '../../../app/theme.dart';

class WalkingProgressCard extends StatelessWidget {
  final int completed;
  final int total;

  const WalkingProgressCard({
    super.key,
    required this.completed,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;
    final percent = (progress * 100).round();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Progress",
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completed of $total tasks completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$percent%',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            LayoutBuilder(
              builder: (context, constraints) {
                const horizontalPadding = 32.0;
                const trackTop = 46.0;
                const trackThickness = 5.0;
                const characterSize = 56.0;
                const startMarkerWidth = 48.0;
                const finishMarkerWidth = 56.0;
                const finishCircleSize = 36.0;
                const finishIconRadius = finishCircleSize / 2;

                final trackLeft = horizontalPadding;
                final trackRight = constraints.maxWidth - horizontalPadding;
                final lineEnd = trackRight - finishIconRadius;
                final lineLength = lineEnd - trackLeft;
                final availableCharacterSpan =
                    (lineEnd - characterSize - trackLeft)
                        .clamp(0.0, lineLength);
                final characterLeft =
                    trackLeft + availableCharacterSpan * progress;

                return SizedBox(
                  height: 104,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: trackLeft,
                        top: trackTop,
                        child: Container(
                          width: lineLength,
                          height: trackThickness,
                          decoration: BoxDecoration(
                            color: AppColors.outline,
                            borderRadius:
                                BorderRadius.circular(trackThickness),
                          ),
                        ),
                      ),
                      Positioned(
                        left: trackLeft,
                        top: trackTop,
                        child: Container(
                          width: lineLength * progress,
                          height: trackThickness,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius:
                                BorderRadius.circular(trackThickness),
                          ),
                        ),
                      ),
                      Positioned(
                        left: trackLeft - startMarkerWidth / 2,
                        top: trackTop - 10,
                        width: startMarkerWidth,
                        child: Column(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Start',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: trackRight - finishMarkerWidth / 2,
                        top: trackTop - (finishCircleSize / 2 - 3),
                        width: finishMarkerWidth,
                        child: Column(
                          children: [
                            Container(
                              width: finishCircleSize,
                              height: finishCircleSize,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.flag_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Finish',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        left: characterLeft,
                        top: trackTop + trackThickness / 2 - characterSize,
                        child: Image.asset(
                          'assets/images/character_fajrtoisha.png',
                          width: characterSize,
                          height: characterSize,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.directions_walk,
                            size: characterSize * 0.7,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}