import 'package:flutter/material.dart';
import '../theme/pollit_theme.dart';

class AppSidebar extends StatelessWidget {
  const AppSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: PollitColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Communities',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.explore_outlined, color: PollitColors.textPrimary),
              title: const Text('Discover', style: TextStyle(color: PollitColors.textPrimary)),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.trending_up, color: PollitColors.textPrimary),
              title: const Text('Trending', style: TextStyle(color: PollitColors.textPrimary)),
              onTap: () {},
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Text(
                'YOUR COMMUNITIES',
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: PollitColors.surfaceLight,
                child: Text('T', style: TextStyle(fontSize: 12, color: PollitColors.textPrimary)),
              ),
              title: const Text('Technology', style: TextStyle(color: PollitColors.textPrimary)),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: PollitColors.surfaceLight,
                child: Text('W', style: TextStyle(fontSize: 12, color: PollitColors.textPrimary)),
              ),
              title: const Text('Weekend', style: TextStyle(color: PollitColors.textPrimary)),
              onTap: () {},
            ),
            ListTile(
              leading: const CircleAvatar(
                radius: 14,
                backgroundColor: PollitColors.surfaceLight,
                child: Text('P', style: TextStyle(fontSize: 12, color: PollitColors.textPrimary)),
              ),
              title: const Text('Product', style: TextStyle(color: PollitColors.textPrimary)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
