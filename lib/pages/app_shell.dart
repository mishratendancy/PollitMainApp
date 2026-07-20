import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../theme/pollit_theme.dart';
import 'feed_screen.dart';
import 'create_poll_screen.dart';
import 'profile/profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}



class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;

  final List<Widget> _pages = [
    const FeedScreen(),
    const CreatePollScreen(),
    const Center(child: Text('Inbox (Coming Soon)')),
    const ProfileScreen(),
  ];

  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PollitColors.background,
      extendBody: true, // Float over content
      body: NotificationListener<UserScrollNotification>(
        onNotification: (notification) {
          if (notification.direction == ScrollDirection.forward) {
            if (!_isNavBarVisible) setState(() => _isNavBarVisible = true);
          } else if (notification.direction == ScrollDirection.reverse) {
            if (_isNavBarVisible) setState(() => _isNavBarVisible = false);
          }
          return false;
        },
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: AnimatedSlide(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        offset: _isNavBarVisible ? Offset.zero : const Offset(0, 1.5),
        child: CurvedNavigationBar(
          key: _bottomNavigationKey,
          index: _currentIndex,
          height: 72.0,
          items: <Widget>[
            Icon(
              _currentIndex == 0 ? Icons.home_filled : Icons.home_outlined,
              size: 26,
              color: _currentIndex == 0 ? const Color(0xFF18181b) : Colors.white,
            ),
            Icon(
              _currentIndex == 1 ? Icons.add_circle : Icons.add_circle_outline,
              size: 26,
              color: _currentIndex == 1 ? const Color(0xFF18181b) : Colors.white,
            ),
            Icon(
              _currentIndex == 2 ? Icons.notifications : Icons.notifications_outlined,
              size: 26,
              color: _currentIndex == 2 ? const Color(0xFF18181b) : Colors.white,
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
                  avatarWidget = Transform.scale(
                    scale: 1.15, // Zooms in just enough to hide padding without cropping the head
                    child: Image.network(
                      resolvedUrl,
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _currentIndex == 3 ? Icons.person : Icons.person_outline,
                        size: 26,
                        color: _currentIndex == 3 ? const Color(0xFF18181b) : Colors.white,
                      ),
                    ),
                  );
                } else {
                  avatarWidget = Icon(
                    _currentIndex == 3 ? Icons.person : Icons.person_outline,
                    size: 26,
                    color: _currentIndex == 3 ? const Color(0xFF18181b) : Colors.white,
                  );
                }

                return Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _currentIndex == 3 ? const Color(0xFF18181b) : Colors.white,
                      width: _currentIndex == 3 ? 1.5 : 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: avatarWidget,
                );
              },
            ),
          ],
          color: const Color(0xFF18181b),
          buttonBackgroundColor: Colors.white,
          backgroundColor: Colors.transparent,
          animationCurve: Curves.easeOutCubic,
          animationDuration: const Duration(milliseconds: 400),
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          letIndexChange: (index) => true,
        ),
      ),
    );
  }
}
