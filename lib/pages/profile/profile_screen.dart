import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/poll.dart';
import '../../providers/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../theme/pollit_theme.dart';
import '../../widgets/poll_card.dart';

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
      body: DefaultTabController(
        length: 1,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                expandedHeight: 220.0,
                floating: false,
                pinned: false,
                backgroundColor: PollitColors.background,
                elevation: 0,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      // Subtle gradient background at top
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 180,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                PollitColors.accent.withValues(alpha: 0.15),
                                PollitColors.background,
                              ],
                            ),
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Premium Avatar
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: PollitColors.surfaceLight,
                                border: Border.all(
                                  color: PollitColors.accent.withValues(alpha: 0.6),
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: PollitColors.accent.withValues(alpha: 0.25),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: photoURL != null
                                    ? Image.network(
                                        photoURL,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: PollitColors.textMuted),
                                      )
                                    : const Icon(Icons.person, size: 50, color: PollitColors.textMuted),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              displayName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: PollitColors.textPrimary,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@$username',
                              style: const TextStyle(
                                color: PollitColors.textMuted,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Stats Card wrapped in a SliverToBoxAdapter
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      color: PollitColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: PollitColors.cardBorder),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Polls', pollsCreated.toString()),
                        _buildDivider(),
                        _buildStatColumn('Votes', voteCount.toString()),
                        _buildDivider(),
                        _buildStatColumn('Inkmarks', inkmarks.toString()),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Sticky Tab Bar
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    indicatorColor: PollitColors.accent,
                    indicatorWeight: 3,
                    labelColor: PollitColors.textPrimary,
                    unselectedLabelColor: PollitColors.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    dividerColor: PollitColors.cardBorder,
                    tabs: const [
                      Tab(text: 'My Polls'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: StreamBuilder<List<Poll>>(
            stream: _firestoreService.getUserPollsStream(uid),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading polls.', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                );
              }

              final polls = snapshot.data ?? [];

              if (polls.isEmpty) {
                return const Center(
                  child: Text(
                    "You haven't created any polls yet.",
                    style: TextStyle(color: PollitColors.textMuted, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 100),
                itemCount: polls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: PollCard(
                      poll: polls[index],
                      firestoreService: _firestoreService,
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: PollitColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: PollitColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 35,
      width: 1,
      color: PollitColors.cardBorder,
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: PollitColors.background,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
