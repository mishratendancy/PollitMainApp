import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../providers/auth_provider.dart';
import '../../theme/pollit_theme.dart';
import 'topic_selection_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _isSubmitting = false;
  
  bool _useDefaultAvatar = false;
  String _avatarSeed = '';
  
  String? get _defaultPhotoUrl {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return authProvider.userProfile?['photoURL'] as String?;
  }

  @override
  void initState() {
    super.initState();
    _generateRandomSeed();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final defaultName = authProvider.userProfile?['displayName'] as String?;
      if (defaultName != null && defaultName.isNotEmpty) {
        _nameController.text = defaultName;
      }
      
      if (_defaultPhotoUrl != null && _defaultPhotoUrl!.isNotEmpty) {
        setState(() {
          _useDefaultAvatar = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _generateRandomSeed() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    final seed = String.fromCharCodes(Iterable.generate(
      8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    setState(() {
      _avatarSeed = seed;
      _useDefaultAvatar = false;
    });
  }

  String get _currentPhotoUrl {
    if (_useDefaultAvatar && _defaultPhotoUrl != null) {
      return _defaultPhotoUrl!;
    }
    return 'https://api.dicebear.com/7.x/micah/png?seed=$_avatarSeed&backgroundColor=transparent';
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name must be at least 2 characters.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.completeProfileSetup(name, _currentPhotoUrl);
      
      if (mounted) {
        HapticFeedback.mediumImpact();
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 700),
            pageBuilder: (context, animation, secondaryAnimation) =>
                const TopicSelectionScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(
                opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
                child: child,
              );
            },
          ),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to complete setup: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Set up your profile',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a display name and avatar before you jump in.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Avatar Preview
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: PollitColors.surfaceLight,
                    shape: BoxShape.circle,
                    border: Border.all(color: PollitColors.cardBorder, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _useDefaultAvatar && _defaultPhotoUrl != null
                      ? Image.network(
                          _defaultPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60),
                        )
                      : Image.network(
                          _currentPhotoUrl,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            );
                          },
                          errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 60),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Avatar Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_defaultPhotoUrl != null && _defaultPhotoUrl!.isNotEmpty) ...[
                    OutlinedButton(
                      onPressed: _isSubmitting ? null : () => setState(() => _useDefaultAvatar = true),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _useDefaultAvatar ? PollitColors.surfaceLight : Colors.transparent,
                        side: BorderSide(
                          color: _useDefaultAvatar ? PollitColors.accent : PollitColors.cardBorder,
                        ),
                      ),
                      child: const Text('Use default'),
                    ),
                    const SizedBox(width: 12),
                  ],
                  OutlinedButton(
                    onPressed: _isSubmitting ? null : _generateRandomSeed,
                    style: OutlinedButton.styleFrom(
                      backgroundColor: !_useDefaultAvatar ? PollitColors.surfaceLight : Colors.transparent,
                      side: BorderSide(
                        color: !_useDefaultAvatar ? PollitColors.accent : PollitColors.cardBorder,
                      ),
                    ),
                    child: const Text('Generate'),
                  ),
                ],
              ),
              
              const SizedBox(height: 48),
              
              // Display Name Input
              Text(
                'Display name',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  hintText: 'Choose a display name',
                ),
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text('Complete setup'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
