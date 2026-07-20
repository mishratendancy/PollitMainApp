import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../models/poll.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/pollit_theme.dart';
import '../../widgets/poll_card.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final profile = authProvider.userProfile;
    final uid = authProvider.user?.uid;

    if (profile == null || uid == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final displayName = profile['displayName'] ?? 'User';
    final username = profile['username'] ?? 'user';
    String? photoURL = profile['photoURL'] as String?;
    if (photoURL != null && photoURL.contains('api.dicebear.com') && photoURL.contains('/svg')) {
      photoURL = photoURL.replaceAll('/svg', '/png');
    }
    final pollsCreated = profile['pollsCreated'] ?? 0;
    final voteCount = profile['voteCount'] ?? 0;
    final inkmarks = profile['inkmarks'] ?? 0;

    return Scaffold(
      backgroundColor: PollitColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My profile',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: PollitColors.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.water_drop_outlined, color: PollitColors.textMuted, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              inkmarks.toString(),
                              style: const TextStyle(
                                color: PollitColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: PollitColors.surfaceLight,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.settings_outlined, color: PollitColors.textPrimary, size: 22),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Avatar
            Container(
              width: 110,
              height: 110,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: photoURL != null
                  ? Image.network(
                      photoURL,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.grey),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.grey),
            ),
            
            const SizedBox(height: 16),
            
            // Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.verified, color: PollitColors.accent, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            
            // Stats
            Text(
              '$pollsCreated Polls · $voteCount Votes · @$username',
              style: const TextStyle(
                fontSize: 14,
                color: PollitColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Pill Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: PollitColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.layers, size: 16, color: Colors.black),
                        SizedBox(width: 8),
                        Text(
                          'Polls',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: PollitColors.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, size: 16, color: PollitColors.textMuted),
                        SizedBox(width: 8),
                        Text(
                          'Votes',
                          style: TextStyle(
                            color: PollitColors.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Polls List
            Expanded(
              child: StreamBuilder<List<Poll>>(
                stream: _firestoreService.getUserPollsStream(uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading polls.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }

                  final polls = snapshot.data ?? [];

                  if (polls.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.poll_outlined, size: 48, color: PollitColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          const Text(
                            "You haven't created any polls yet.",
                            style: TextStyle(color: PollitColors.textMuted, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.only(bottom: 100), // Space for bottom nav
                    itemCount: polls.length,
                    separatorBuilder: (context, index) => const Divider(
                      color: PollitColors.cardBorder,
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      return PollCard(
                        poll: polls[index],
                        firestoreService: _firestoreService,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
