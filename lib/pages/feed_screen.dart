import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../theme/pollit_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/feed_provider.dart';
import '../services/firestore_service.dart';
import '../models/poll.dart';
import '../models/option.dart';
import '../widgets/app_sidebar.dart';
import 'onboarding/auth_screen.dart';
import '../widgets/poll_card.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  final FirestoreService _firestoreService = FirestoreService();
  bool _isTopBarVisible = true;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: PollitColors.background,
      drawer: const AppSidebar(),
      body: Stack(
        children: [
          // The Feed List
          NotificationListener<UserScrollNotification>(
            onNotification: (notification) {
              if (notification.direction == ScrollDirection.forward) {
                if (!_isTopBarVisible) setState(() => _isTopBarVisible = true);
              } else if (notification.direction == ScrollDirection.reverse) {
                if (_isTopBarVisible) setState(() => _isTopBarVisible = false);
              }
              return false;
            },
            child: Consumer<FeedProvider>(
              builder: (context, feedProvider, child) {
                if (feedProvider.isLoading && feedProvider.polls.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (feedProvider.error != null) {
                  return Center(
                    child: Text(
                      'Error: ${feedProvider.error}',
                      style: const TextStyle(color: PollitColors.error),
                    ),
                  );
                }

                return FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _entryController,
                    curve: Curves.easeOut,
                  ),
                  child: ListView.builder(
                    padding: EdgeInsets.fromLTRB(4, topPadding + 80, 4, 24),
                    itemCount: feedProvider.polls.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 24, left: 12, right: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: PollitColors.background,
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: PollitColors.accent.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.search, color: PollitColors.accent.withValues(alpha: 0.8), size: 20),
                              const SizedBox(width: 12),
                              const Text(
                                'Search Poll-it',
                                style: TextStyle(
                                  color: PollitColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final pollIndex = index - 1;
                      final isFirstPoll = pollIndex == 0;
                      final isLastPoll = pollIndex == feedProvider.polls.length - 1;

                      return Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: isFirstPoll ? const BorderSide(color: PollitColors.cardBorder) : BorderSide.none,
                            left: const BorderSide(color: PollitColors.cardBorder),
                            right: const BorderSide(color: PollitColors.cardBorder),
                            bottom: isLastPoll ? const BorderSide(color: PollitColors.cardBorder) : BorderSide.none,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (isFirstPoll) const SizedBox(height: 16),
                            
                            // The Inner Frame (Poll Card)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: PollitColors.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: PollitColors.cardBorder),
                              ),
                              child: PollCard(
                                poll: feedProvider.polls[pollIndex],
                                firestoreService: _firestoreService,
                              ),
                            ),
                            
                            // Divider between inner frames
                            if (!isLastPoll)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Divider(
                                  height: 1,
                                  thickness: 1,
                                  color: PollitColors.cardBorder,
                                ),
                              ),
                            if (isLastPoll) const SizedBox(height: 16),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          
          // The Animated Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              height: _isTopBarVisible ? topPadding + 60 : topPadding + 16, // Collapses to a 16px border below status bar
              decoration: BoxDecoration(
                color: PollitColors.background,
                border: Border(
                  bottom: BorderSide(
                    color: PollitColors.cardBorder.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isTopBarVisible ? 1.0 : 0.0,
                  child: IgnorePointer(
                    ignoring: !_isTopBarVisible,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: Row(
                        children: [
                          Builder(
                            builder: (context) => IconButton(
                              icon: const Icon(Icons.menu, color: PollitColors.textPrimary),
                              onPressed: () => Scaffold.of(context).openDrawer(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Poll-it',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          Consumer<AuthProvider>(
                            builder: (context, authProvider, _) {
                              final profile = authProvider.userProfile;
                              String? resolvedUrl = profile?['photoURL'] as String?;
                              if (resolvedUrl != null && resolvedUrl.contains('api.dicebear.com') && resolvedUrl.contains('/svg')) {
                                resolvedUrl = resolvedUrl.replaceAll('/svg', '/png');
                              }
                              
                              Widget avatarWidget;
                              if (resolvedUrl != null) {
                                avatarWidget = Image.network(
                                  resolvedUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.account_circle_outlined, color: PollitColors.textPrimary),
                                );
                              } else {
                                avatarWidget = const Icon(Icons.account_circle_outlined, color: PollitColors.textPrimary);
                              }

                              return PopupMenuButton<String>(
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: PollitColors.surfaceLight,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: PollitColors.cardBorder, width: 1.5),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: avatarWidget,
                                ),
                                tooltip: 'Profile & settings',
                                color: PollitColors.surface,
                            offset: const Offset(0, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: PollitColors.cardBorder, width: 0.5),
                            ),
                            onSelected: (value) async {
                              if (value == 'logout') {
                                await Provider.of<AuthProvider>(context, listen: false).logout();
                                // AuthWrapper will see user == null and show OnboardingScreen
                                if (mounted) {
                                  Navigator.of(context).popUntil((route) => route.isFirst);
                                }
                              }
                            },
                            itemBuilder: (context) {
                              final profile = Provider.of<AuthProvider>(context, listen: false).userProfile;
                              final username = profile?['username'] ?? 'User';
                              return [
                                PopupMenuItem(
                                  enabled: false,
                                  child: Text(
                                    '@$username',
                                    style: const TextStyle(
                                      color: PollitColors.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'profile',
                                  child: Text('Profile'),
                                ),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Text(
                                    'Log out',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ];
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 4),
                    ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


