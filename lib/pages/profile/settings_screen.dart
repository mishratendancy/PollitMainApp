import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/pollit_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showLogoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: PollitColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: PollitColors.textPrimary),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 48), // Balances the close button for center alignment
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Are you sure want to Logout?',
                style: TextStyle(
                  color: PollitColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Thank you and see you again! ❤️',
                style: TextStyle(
                  color: PollitColors.textMuted,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: PollitColors.cardBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: PollitColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await Provider.of<AuthProvider>(context, listen: false).logout();
                        if (context.mounted) {
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        }
                      },
                      child: const Text(
                        'Yes, Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 8, top: 24),
      child: Text(
        title,
        style: const TextStyle(
          color: PollitColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isDestructive ? Colors.redAccent : PollitColors.textMuted,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive ? Colors.redAccent : PollitColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: isDestructive ? Colors.redAccent.withValues(alpha: 0.5) : PollitColors.textMuted.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Column(
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PollitColors.background,
      appBar: AppBar(
        backgroundColor: PollitColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: PollitColors.textPrimary),
        title: const Text(
          'Settings',
          style: TextStyle(color: PollitColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildSectionHeader('Account'),
          _buildSettingsCard(
            children: [
              _buildSettingsRow(icon: Icons.person_outline, title: 'Account Information', onTap: () {}),
              const Divider(color: PollitColors.cardBorder, height: 1),
              _buildSettingsRow(icon: Icons.receipt_long_outlined, title: 'My Orders', onTap: () {}),
              const Divider(color: PollitColors.cardBorder, height: 1),
              _buildSettingsRow(icon: Icons.location_on_outlined, title: 'Address Management', onTap: () {}),
              const Divider(color: PollitColors.cardBorder, height: 1),
              _buildSettingsRow(icon: Icons.settings_outlined, title: 'Setting', onTap: () {}),
              const Divider(color: PollitColors.cardBorder, height: 1),
              _buildSettingsRow(icon: Icons.lock_outline, title: 'Password Manager', onTap: () {}),
            ],
          ),
          
          _buildSectionHeader('Support'),
          _buildSettingsCard(
            children: [
              _buildSettingsRow(icon: Icons.help_outline, title: 'Help Center', onTap: () {}),
              const Divider(color: PollitColors.cardBorder, height: 1),
              _buildSettingsRow(
                icon: Icons.logout,
                title: 'Logout',
                isDestructive: true,
                onTap: () => _showLogoutBottomSheet(context),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
