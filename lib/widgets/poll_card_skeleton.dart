import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/pollit_theme.dart';

class PollCardSkeleton extends StatelessWidget {
  const PollCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Shimmer.fromColors(
      baseColor: PollitColors.surfaceLight,
      highlightColor: PollitColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reddit-style Header Skeleton
            Row(
              children: [
                const CircleAvatar(
                  radius: 12,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 60,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 100,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Title Skeleton
            Container(
              width: double.infinity,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: MediaQuery.of(context).size.width * 0.6,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 24),
            
            // Options List Skeleton
            ...List.generate(3, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  height: 48, // approximate height of an option tile
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: PollitColors.cardBorder,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white, // shimmer color applies to this
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 12),
            
            // Footer Action Bar Skeleton
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFooterButtonSkeleton(),
                _buildFooterButtonSkeleton(),
                _buildFooterButtonSkeleton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterButtonSkeleton() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 40,
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ],
      ),
    );
  }
}
