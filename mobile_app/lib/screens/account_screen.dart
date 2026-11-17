import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_session.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';

/// User account overview, organization status, legal links, logout, and account deletion.
class AccountScreen extends StatefulWidget {
  final UserSession user;
  final StorageService storage;
  final ApiService? api;
  final VoidCallback onLogout;

  const AccountScreen({
    super.key,
    required this.user,
    required this.storage,
    this.api,
    required this.onLogout,
  });

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static final Uri _privacyUrl = Uri.parse(
    '${StorageService.staticSiteUrl}/privacy-policy',
  );
  static final Uri _termsUrl = Uri.parse(
    '${StorageService.staticSiteUrl}/terms',
  );

  bool _isBusy = false;

  Future<void> _openExternalLink(Uri uri, String label) async {
    try {
      final supported = await canLaunchUrl(uri);
      if (!supported) {
        _showMessage('Unable to open $label on this device.', isError: true);
        return;
      }
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        _showMessage('Could not launch $label.', isError: true);
      }
    } catch (_) {
      _showMessage('Could not open $label right now.', isError: true);
    }
  }

  Future<void> _confirmAndDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: !_isBusy,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed, size: 24),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Delete Account',
                style: AppTypography.fontL(
                  color: AppColors.brandInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will remove your cached bills, Excel drafts, and session from this device. Once your organization backend endpoint is active, your cloud account data will also be permanently deleted.\n\nDo you want to continue?',
          style: AppTypography.fontM(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.fontM(
                color: AppColors.brandInk,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              minimumSize: const Size(112, 44),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);
    try {
      if (widget.api != null) {
        try {
          await widget.api!.deleteAccount();
        } catch (_) {}
      }
      await widget.storage.clearAllUserData();
      await widget.storage.clearActiveUserData();
      await SupabaseService.signOut();
      if (!mounted) return;
      widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      _showMessage('Could not complete account deletion. Please try again.', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  Future<void> _handleLogout() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      if (widget.api != null) {
        try {
          await widget.api!.releaseDeviceSession();
        } catch (_) {}
      }
      await widget.storage.clearAllUserData();
      await widget.storage.clearActiveUserData();
      await SupabaseService.signOut();
      if (!mounted) return;
      widget.onLogout();
    } catch (_) {
      if (!mounted) return;
      widget.onLogout();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: AppTypography.fontM(color: Colors.white)),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final accessStatus = widget.storage.subscriptionStatus?.toUpperCase() ??
        (widget.storage.isScanAllowed ? 'ACTIVE' : 'INACTIVE');
    final validityWindow =
        '${widget.storage.subscriptionStartDate ?? '—'} → ${widget.storage.subscriptionEndDate ?? '—'}';

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Summary Card
            LiquidGlass(
              isDarkMaroon: true,
              borderRadius: 22,
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.45), width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: AppTypography.fontL(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.fontL(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.fontS(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user.role,
                            style: AppTypography.fontS(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Subscription & Session Card
            LiquidGlass(
              borderRadius: 20,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Subscription & Device',
                    style: AppTypography.fontL(
                      color: AppColors.brandInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AccountInfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Access Status',
                    value: accessStatus,
                  ),
                  const Divider(height: 18, color: AppColors.borderSubtle),
                  _AccountInfoRow(
                    icon: Icons.date_range_rounded,
                    label: 'Validity Window',
                    value: validityWindow,
                  ),
                  const Divider(height: 18, color: AppColors.borderSubtle),
                  const _AccountInfoRow(
                    icon: Icons.smartphone_rounded,
                    label: 'Device Policy',
                    value: 'Single Active Device',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Legal & Compliance Card
            LiquidGlass(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
                    child: Text(
                      'Legal & Support',
                      style: AppTypography.fontL(
                        color: AppColors.brandInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _AccountActionTile(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Privacy Policy',
                    subtitle: 'How invoice data is processed & stored',
                    onTap: () => _openExternalLink(_privacyUrl, 'Privacy Policy'),
                  ),
                  const Divider(height: 4, color: AppColors.borderSubtle),
                  _AccountActionTile(
                    icon: Icons.description_outlined,
                    label: 'Terms of Service',
                    subtitle: 'Usage terms and data retention policy',
                    onTap: () => _openExternalLink(_termsUrl, 'Terms of Service'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Session Actions Card
            LiquidGlass(
              borderRadius: 20,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Column(
                children: [
                  _AccountActionTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    subtitle: 'Release this session so you can sign in elsewhere',
                    onTap: _isBusy ? null : _handleLogout,
                  ),
                  const Divider(height: 4, color: AppColors.borderSubtle),
                  _AccountActionTile(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    subtitle: 'Clear local data and request permanent deletion',
                    accentColor: AppColors.errorRed,
                    onTap: _isBusy ? null : _confirmAndDeleteAccount,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _AccountInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.maroonDark),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: AppTypography.fontS(
              color: AppColors.mutedText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTypography.fontM(
              color: AppColors.brandInk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;

  const _AccountActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.accentColor = AppColors.brandInk,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$label. $subtitle',
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: ExcludeSemantics(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 54),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 22, color: accentColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: AppTypography.fontM(
                              color: accentColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: AppTypography.fontS(
                              color: AppColors.mutedText,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.mutedText.withValues(alpha: 0.7),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
