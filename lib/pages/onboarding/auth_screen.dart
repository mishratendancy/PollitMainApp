import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../../theme/pollit_theme.dart';
import '../../providers/auth_provider.dart';
import '../pollit_home_page.dart';
import '../app_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _headerOpacity;
  late final Animation<double> _headerSlide;
  late final Animation<double> _formOpacity;
  late final Animation<double> _formSlide;
  late final Animation<double> _socialOpacity;

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _headerSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutCubic),
      ),
    );

    _formOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.65, curve: Curves.easeOut),
      ),
    );

    _formSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.25, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _socialOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (_isLogin) {
        await authProvider.signIn(email, password);
      } else {
        if (username.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a username')),
          );
          setState(() => _isSubmitting = false);
          return;
        }
        await authProvider.signUp(email, password, username: username);
      }
      
      if (mounted) {
        _goToHome();
      }
    } catch (e) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.getErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();
      
      if (mounted) {
        _goToHome();
      }
    } catch (e) {
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.getErrorMessage(e)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _goToHome() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 700),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const AppShell(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
      ),
      (_) => false,
    );
  }

  Widget _buildToggleTab(String text, bool isActive) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (!isActive) {
          setState(() {
            _isLogin = text == 'Log in';
          });
        }
      },
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            color: isActive ? Colors.white : PollitColors.textMuted,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            fontSize: 14,
          ),
          child: Text(text),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        color: PollitColors.textPrimary,
        fontSize: 16,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: PollitColors.textMuted.withValues(alpha: 0.5)),
        filled: true,
        fillColor: Colors.transparent,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PollitColors.cardBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: PollitColors.accent, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: PollitColors.background,
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _entryController,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Opacity(
                      opacity: _headerOpacity.value,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.arrow_back,
                                  color: PollitColors.textMuted,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Back',
                                  style: TextStyle(
                                    color: PollitColors.textMuted,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 170,
                            height: 40,
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: PollitColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: PollitColors.cardBorder,
                                width: 0.5,
                              ),
                            ),
                            child: Stack(
                              children: [
                                AnimatedAlign(
                                  alignment: _isLogin
                                      ? Alignment.centerLeft
                                      : Alignment.centerRight,
                                  duration: const Duration(milliseconds: 250),
                                  curve: Curves.easeOutCubic,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.5,
                                    heightFactor: 1.0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: PollitColors.accent
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildToggleTab('Log in', _isLogin),
                                    ),
                                    Expanded(
                                      child: _buildToggleTab('Sign up', !_isLogin),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Title
                    Opacity(
                      opacity: _headerOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _headerSlide.value),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              child: Text(
                                _isLogin ? 'Welcome Back' : 'Join the Community',
                                key: ValueKey('title_$_isLogin'),
                                style: Theme.of(context)
                                    .textTheme
                                    .displaySmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      fontSize: 32,
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 400),
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              child: Text(
                                _isLogin
                                    ? "Dive in and see what's being polled today."
                                    : "Sign up to see what the world is polling.",
                                key: ValueKey('subtitle_$_isLogin'),
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  color: PollitColors.textMuted,
                                  fontSize: 15,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Form fields
                    Opacity(
                      opacity: _formOpacity.value,
                      child: Transform.translate(
                        offset: Offset(0, _formSlide.value),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username (sign up only)
                            AnimatedSize(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, -0.2),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _isLogin
                                    ? const SizedBox.shrink(key: ValueKey('login'))
                                    : Padding(
                                        key: const ValueKey('signup'),
                                        padding: const EdgeInsets.only(bottom: 20),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            _buildInputLabel('Username'),
                                            _buildTextField(
                                              hintText: 'your_username',
                                              controller: _usernameController,
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),

                            // Email
                            _buildInputLabel('Email'),
                            _buildTextField(
                              hintText: 'you@example.com',
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 20),

                            // Password
                            _buildInputLabel('Password'),
                            _buildTextField(
                              hintText: '••••••••••••',
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              suffixIcon: GestureDetector(
                                onTap: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                                child: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: PollitColors.textMuted,
                                  size: 20,
                                ),
                              ),
                            ),

                            // Forgot password
                            AnimatedSize(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOut,
                                switchOutCurve: Curves.easeIn,
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, -0.2),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _isLogin
                                    ? Align(
                                        key: const ValueKey('forgot_pass'),
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: TextButton(
                                            onPressed: () {},
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                            ),
                                            child: Text(
                                              'Forgot password?',
                                              style: TextStyle(
                                                color: PollitColors.accent,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : const SizedBox.shrink(key: ValueKey('no_forgot_pass')),
                              ),
                            ),

                            const SizedBox(height: 28),

                            // Primary button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isSubmitting ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: PollitColors.accent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28),
                                  ),
                                  elevation: 0,
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Continue',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Don't have an account
                            Center(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                                child: RichText(
                                  key: ValueKey(_isLogin),
                                  text: TextSpan(
                                    style: const TextStyle(fontSize: 14),
                                    children: [
                                      TextSpan(
                                        text: _isLogin
                                            ? "Don't have an account? "
                                            : 'Already have an account? ',
                                        style: const TextStyle(
                                          color: PollitColors.textMuted,
                                        ),
                                      ),
                                      TextSpan(
                                        text: _isLogin ? 'Sign up' : 'Log in',
                                        style: const TextStyle(
                                          color: PollitColors.accent,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        recognizer: TapGestureRecognizer()
                                          ..onTap = () {
                                            setState(() => _isLogin = !_isLogin);
                                          },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Divider
                    Opacity(
                      opacity: _socialOpacity.value,
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 0.5,
                              color: PollitColors.divider,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Or',
                              style: TextStyle(
                                color: PollitColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 0.5,
                              color: PollitColors.divider,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Social buttons
                    Opacity(
                      opacity: _socialOpacity.value,
                      child: Column(
                        children: [
                          _SocialButton(
                            iconWidget: SvgPicture.asset(
                              'assets/images/google_logo.svg',
                              width: 26,
                              height: 26,
                            ),
                            label: 'Google',
                            onTap: _handleGoogleSignIn,
                          ),
                          const SizedBox(height: 12),
                          _SocialButton(
                            iconWidget: const Icon(
                              Icons.facebook_rounded,
                              color: Color(0xFF1877F2),
                              size: 24,
                            ),
                            label: 'Facebook',
                            onTap: _goToHome,
                          ),
                          const SizedBox(height: 12),
                          _SocialButton(
                            iconWidget: SvgPicture.asset(
                              'assets/images/x_logo.svg',
                              width: 22,
                              height: 22,
                            ),
                            label: 'X',
                            onTap: _goToHome,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Terms
                    Center(
                      child: Opacity(
                        opacity: _socialOpacity.value,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          child: RichText(
                            key: ValueKey(_isLogin),
                            textAlign: TextAlign.center,
                            text: TextSpan(
                              style: TextStyle(
                                color: PollitColors.textMuted,
                                fontSize: 12,
                                height: 1.5,
                              ),
                              children: [
                                TextSpan(
                                  text: _isLogin
                                      ? 'By signing in I confirm that I have read and agree to the Poll-it\n'
                                      : 'By signing up I confirm that I have read and agree to the Poll-it\n',
                                ),
                                const TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: PollitColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                const TextSpan(
                                  text: 'Terms of Service.',
                                  style: TextStyle(
                                    color: PollitColors.accent,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SocialButton extends StatefulWidget {
  const _SocialButton({
    required this.iconWidget,
    required this.label,
    required this.onTap,
  });

  final Widget iconWidget;
  final String label;
  final VoidCallback onTap;

  @override
  State<_SocialButton> createState() => _SocialButtonState();
}

class _SocialButtonState extends State<_SocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: PollitColors.surface,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(
              color: PollitColors.cardBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              widget.iconWidget,
              const SizedBox(width: 10),
              Text(
                'Continue with ${widget.label}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
