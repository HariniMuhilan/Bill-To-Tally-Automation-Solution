import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/forgot_password_dialog.dart';
import '../widgets/request_access_otp_dialog.dart';

class WarningBannerData {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? actionLabel;
  final VoidCallback? onAction;

  const WarningBannerData({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.actionLabel,
    this.onAction,
  });
}

class LoginScreen extends StatefulWidget {
  final StorageService storage;
  final ApiService api;
  final ValueChanged<UserSession> onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.storage,
    required this.api,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRequestAccess = false;

  // Sign In controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Request Access controllers
  final _reqNameController = TextEditingController();
  final _reqBusinessController = TextEditingController();
  final _reqEmailController = TextEditingController();
  final _reqPhoneController = TextEditingController();

  WarningBannerData? _warningBanner;

  // Inline validation errors
  String? _signInEmailError;
  String? _signInPasswordError;
  String? _reqNameError;
  String? _reqBusinessError;
  String? _reqEmailError;
  String? _reqPhoneError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(() {
      if (_signInEmailError != null && _isValidEmail(_emailController.text.trim())) {
        setState(() => _signInEmailError = null);
      }
    });
    _passwordController.addListener(() {
      if (_signInPasswordError != null && _passwordController.text.isNotEmpty) {
        setState(() => _signInPasswordError = null);
      }
    });
    _reqNameController.addListener(() {
      if (_reqNameError != null && _reqNameController.text.trim().isNotEmpty) {
        setState(() => _reqNameError = null);
      }
    });
    _reqBusinessController.addListener(() {
      if (_reqBusinessError != null && _reqBusinessController.text.trim().isNotEmpty) {
        setState(() => _reqBusinessError = null);
      }
    });
    _reqEmailController.addListener(() {
      if (_reqEmailError != null && _isValidEmail(_reqEmailController.text.trim())) {
        setState(() => _reqEmailError = null);
      }
    });
    _reqPhoneController.addListener(() {
      if (_reqPhoneError != null && _isValidPhone(_reqPhoneController.text.trim())) {
        setState(() => _reqPhoneError = null);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _reqNameController.dispose();
    _reqBusinessController.dispose();
    _reqEmailController.dispose();
    _reqPhoneController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 10 && digits.length <= 15;
  }

  String _getDeviceLabel() {
    if (kIsWeb) return 'Web Browser';
    try {
      if (Platform.isAndroid) return 'Android Device';
      if (Platform.isIOS) return 'Apple iPhone';
      if (Platform.isWindows) return 'Windows Workstation';
      if (Platform.isMacOS) return 'macOS Workstation';
      if (Platform.isLinux) return 'Linux Workstation';
    } catch (_) {}
    return 'Mobile App Device';
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool hasError = false;
    if (email.isEmpty) {
      _signInEmailError = 'Email address is required';
      hasError = true;
    } else if (!_isValidEmail(email)) {
      _signInEmailError = 'Enter a valid email address (e.g. name@gmail.com)';
      hasError = true;
    } else {
      _signInEmailError = null;
    }

    if (password.isEmpty) {
      _signInPasswordError = 'Password is required';
      hasError = true;
    } else {
      _signInPasswordError = null;
    }

    if (hasError) {
      setState(() {
        _warningBanner = const WarningBannerData(
          icon: Icons.warning_amber_rounded,
          title: 'Missing Required Fields',
          message: 'Please fill in all fields with valid information before signing in.',
          color: AppColors.orange,
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _warningBanner = null;
      _signInEmailError = null;
      _signInPasswordError = null;
    });

    try {
      if (SupabaseService.isReady) {
        final session = await SupabaseService.signIn(
          emailOrUsername: email,
          password: password,
        );
        if (!mounted) return;
        if (session != null) {
          // Strict Single-Device Lock: Claim device session
          final deviceLabel = _getDeviceLabel();
          final claimRes = await widget.api.claimDeviceSession(deviceLabel: deviceLabel);

          if (!claimRes.success) {
            // Revert local sign-in if another device owns the session
            await SupabaseService.signOut();
            if (!mounted) return;
            setState(() {
              _warningBanner = WarningBannerData(
                icon: Icons.phonelink_lock_rounded,
                title: 'Device Lock Conflict',
                message: claimRes.error ??
                    'This account is currently active on another device. BillBooks enforces single-device security per merchant. Please log out from that device or ask your administrator to reset your device lock.',
                color: AppColors.errorRed,
                actionLabel: 'OK',
                onAction: () => setState(() => _warningBanner = null),
              );
            });
            return;
          }

          if (claimRes.data != null && claimRes.data!['session_id'] != null) {
            await widget.storage.setActiveDeviceSessionId(claimRes.data!['session_id'].toString());
          }

          // Check and update subscription status
          final subStatus = await widget.api.getSubscriptionStatus();
          if (subStatus.success && subStatus.data != null) {
            final data = subStatus.data!;
            await widget.storage.setScanAllowed(data['is_scan_allowed'] == true);
            await widget.storage.setSubscriptionStatus(data['status']?.toString());
            await widget.storage.setSubscriptionStartDate(data['subscription_start']?.toString());
            await widget.storage.setSubscriptionEndDate(data['subscription_end']?.toString());
          }

          await widget.storage.saveUser(session);
          if (!mounted) return;
          widget.onLoginSuccess(session);
          return;
        }
      } else {
        setState(() {
          _warningBanner = const WarningBannerData(
            icon: Icons.cloud_off_rounded,
            title: 'Authentication Service Offline',
            message: 'Supabase authentication is not configured yet. Please check connection.',
            color: AppColors.errorRed,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      final rawMsg = e.toString().toLowerCase();

      if (rawMsg.contains('invalid login credentials') || rawMsg.contains('invalid_credentials')) {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.person_search_rounded,
            title: 'Account Not Found or Incorrect Password',
            message: 'We could not sign you in with "$email". If your organization has not provisioned login access yet, request access below.',
            color: AppColors.warningAmber,
            actionLabel: 'REQUEST ACCESS',
            onAction: () {
              setState(() {
                _isRequestAccess = true;
                _reqEmailController.text = email;
                _warningBanner = null;
                _signInEmailError = null;
                _signInPasswordError = null;
              });
            },
          );
        });
      } else if (rawMsg.contains('email not confirmed')) {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.mark_email_unread_rounded,
            title: 'Email Confirmation Required',
            message: 'Supabase sent a confirmation email to $email. Check your inbox (and Spam) or resend it below.',
            color: AppColors.warningAmber,
            actionLabel: 'RESEND CONFIRMATION EMAIL',
            onAction: () => _handleResendConfirmationEmail(email),
          );
        });
      } else if (rawMsg.contains('socketexception') ||
          rawMsg.contains('network') ||
          rawMsg.contains('failed host lookup') ||
          rawMsg.contains('connection refused') ||
          rawMsg.contains('clientexception')) {
        setState(() {
          _warningBanner = const WarningBannerData(
            icon: Icons.wifi_off_rounded,
            title: 'Connection Error',
            message: 'Could not reach Supabase. Check your internet connection and verify that fechwdczejepckkhbizm.supabase.co is accessible.',
            color: AppColors.errorRed,
          );
        });
      } else {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.error_outline_rounded,
            title: 'Sign In Failed',
            message: e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), ''),
            color: AppColors.errorRed,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResendConfirmationEmail(String email) async {
    setState(() => _isLoading = true);
    try {
      await SupabaseService.resendConfirmationEmail(email: email);
      if (!mounted) return;
      setState(() {
        _warningBanner = WarningBannerData(
          icon: Icons.mark_email_read_rounded,
          title: 'Confirmation Email Sent',
          message: 'A fresh confirmation link was sent to $email. Open it to activate your account, then sign in.',
          color: AppColors.successGreen,
          actionLabel: 'OK',
          onAction: () => setState(() => _warningBanner = null),
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _warningBanner = WarningBannerData(
          icon: Icons.error_outline_rounded,
          title: 'Could Not Resend Email',
          message: e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), ''),
          color: AppColors.errorRed,
          actionLabel: 'RETRY',
          onAction: () => _handleResendConfirmationEmail(email),
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForgotPasswordDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        onPasswordResetSuccess: (message) {
          if (!mounted) return;
          setState(() {
            _warningBanner = WarningBannerData(
              icon: Icons.check_circle_outline_rounded,
              title: 'Password Updated',
              message: message,
              color: AppColors.successGreen,
            );
          });
        },
      ),
    );
  }

  Future<void> _handleRequestAccess() async {
    final fullName = _reqNameController.text.trim();
    final businessName = _reqBusinessController.text.trim();
    final email = _reqEmailController.text.trim();
    final phone = _reqPhoneController.text.trim();

    bool hasError = false;
    if (fullName.isEmpty) {
      _reqNameError = 'Full name is required';
      hasError = true;
    } else {
      _reqNameError = null;
    }

    if (businessName.isEmpty) {
      _reqBusinessError = 'Business or shop name is required';
      hasError = true;
    } else {
      _reqBusinessError = null;
    }

    if (email.isEmpty) {
      _reqEmailError = 'Email address is required';
      hasError = true;
    } else if (!_isValidEmail(email)) {
      _reqEmailError = 'Enter a valid email address (e.g. name@company.com)';
      hasError = true;
    } else {
      _reqEmailError = null;
    }

    if (phone.isEmpty) {
      _reqPhoneError = 'Phone number is required';
      hasError = true;
    } else if (!_isValidPhone(phone)) {
      _reqPhoneError = 'Enter a valid 10–15 digit phone number';
      hasError = true;
    } else {
      _reqPhoneError = null;
    }

    if (hasError) {
      setState(() {
        _warningBanner = const WarningBannerData(
          icon: Icons.warning_amber_rounded,
          title: 'Check Request Details',
          message: 'Please fill in all fields with valid contact details before submitting.',
          color: AppColors.orange,
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _warningBanner = null;
      _reqNameError = null;
      _reqBusinessError = null;
      _reqEmailError = null;
      _reqPhoneError = null;
    });

    try {
      if (!SupabaseService.isReady) {
        setState(() {
          _warningBanner = const WarningBannerData(
            icon: Icons.cloud_off_rounded,
            title: 'Verification Service Offline',
            message: 'Email verification is unavailable right now. Please check your internet connection.',
            color: AppColors.errorRed,
          );
        });
        return;
      }

      await SupabaseService.sendAccessRequestOtp(email: email);
      if (!mounted) return;
      setState(() => _isLoading = false);

      final result = await showDialog<ApiResult<Map<String, dynamic>>?>(
        context: context,
        barrierDismissible: false,
        builder: (_) => RequestAccessOtpDialog(
          fullName: fullName,
          businessName: businessName,
          email: email,
          phone: phone,
          api: widget.api,
        ),
      );
      if (!mounted || result == null) return;

      if (result.success) {
        _reqNameController.clear();
        _reqBusinessController.clear();
        _reqPhoneController.clear();
        setState(() {
          _isRequestAccess = false;
          _emailController.text = email;
          _warningBanner = WarningBannerData(
            icon: Icons.check_circle_outline_rounded,
            title: 'Access Request Submitted',
            message: 'Your email "$email" is verified and your request for "$businessName" has been sent. Your admin will share login credentials once activated.',
            color: AppColors.successGreen,
          );
        });
      } else if (result.error == 'ACCESS_REQUEST_ENDPOINT_UNAVAILABLE') {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.admin_panel_settings_outlined,
            title: 'Contact Admin for Access',
            message: 'Online request submission is not active on the server yet. Please share "$email" and "$businessName" with your administrator to provision your account.',
            color: AppColors.infoBlue,
          );
        });
      } else {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.error_outline_rounded,
            title: 'Request Could Not Be Sent',
            message: result.error ?? 'Please try again in a moment.',
            color: AppColors.errorRed,
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      final rawMsg = e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), '');
      final lower = rawMsg.toLowerCase();
      final friendly = (lower.contains('rate limit') ||
              lower.contains('429') ||
              lower.contains('over_email_send_rate_limit'))
          ? 'Too many verification emails sent. Please wait a minute and try again.'
          : rawMsg;
      setState(() {
        _warningBanner = WarningBannerData(
          icon: Icons.mark_email_unread_outlined,
          title: 'Could Not Send Verification Code',
          message: friendly,
          color: AppColors.errorRed,
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _switchTab(bool toRequestAccess) {
    if (_isRequestAccess == toRequestAccess) return;
    setState(() {
      _isRequestAccess = toRequestAccess;
      _warningBanner = null;
      _signInEmailError = null;
      _signInPasswordError = null;
      _reqNameError = null;
      _reqBusinessError = null;
      _reqEmailError = null;
      _reqPhoneError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LiquidBackgroundPainter(),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'billbooks_brand_logo',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/billbooks_header_logo.png',
                            width: 230,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/billbooks_logo.png',
                              width: 230,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'PURCHASE VOUCHER AUTOMATION',
                              style: TextStyle(
                                fontFamily: 'DM Sans',
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.4,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    LiquidGlass(
                      borderRadius: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildModeToggle(),
                          const SizedBox(height: 16),
                          AnimatedSize(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            child: _warningBanner == null
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: _buildWarningCard(_warningBanner!),
                                  ),
                          ),
                          AnimatedSwitcher(
                            duration: MediaQuery.disableAnimationsOf(context)
                                ? Duration.zero
                                : const Duration(milliseconds: 180),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: KeyedSubtree(
                              key: ValueKey<bool>(_isRequestAccess),
                              child: !_isRequestAccess
                                  ? _buildSignInForm(context)
                                  : _buildRequestAccessForm(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      height: 46,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pillWidth = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
                curve: Curves.easeInOutCubic,
                left: _isRequestAccess ? pillWidth : 0,
                top: 0,
                bottom: 0,
                width: pillWidth,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.maroonLight, AppColors.maroonDark],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.maroonDark.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  _buildTabOption(
                    label: 'SIGN IN',
                    semanticLabel: 'Sign In tab',
                    isSelected: !_isRequestAccess,
                    onTap: () => _switchTab(false),
                  ),
                  _buildTabOption(
                    label: 'REQUEST ACCESS',
                    semanticLabel: 'Request Access tab',
                    isSelected: _isRequestAccess,
                    onTap: () => _switchTab(true),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTabOption({
    required String label,
    required String semanticLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: semanticLabel,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: AppTypography.fontS(
                    color: isSelected ? Colors.white : AppColors.brandInk.withValues(alpha: 0.70),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabeledInput(
          label: 'EMAIL ADDRESS',
          controller: _emailController,
          icon: Icons.mail_outline_rounded,
          hintText: 'name@company.com',
          semanticLabel: 'Email address',
          keyboardType: TextInputType.emailAddress,
          error: _signInEmailError,
        ),
        const SizedBox(height: 14),
        _buildLabeledInput(
          label: 'PASSWORD',
          controller: _passwordController,
          icon: Icons.lock_outline_rounded,
          hintText: 'Enter password',
          semanticLabel: 'Password',
          obscureText: _obscurePassword,
          onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
          error: _signInPasswordError,
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _openForgotPasswordDialog,
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 44),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              'Forgot Password?',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.maroonDark.withValues(alpha: 0.90),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _buildSubmitButton(
          label: 'SIGN IN',
          busySemanticLabel: 'Signing in',
          idleSemanticLabel: 'Sign In',
          onTap: _handleSignIn,
        ),
      ],
    );
  }

  Widget _buildRequestAccessForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLabeledInput(
          label: 'FULL NAME',
          controller: _reqNameController,
          icon: Icons.person_outline_rounded,
          hintText: 'Your full name',
          semanticLabel: 'Full name',
          error: _reqNameError,
        ),
        const SizedBox(height: 14),
        _buildLabeledInput(
          label: 'BUSINESS / SHOP NAME',
          controller: _reqBusinessController,
          icon: Icons.storefront_outlined,
          hintText: 'Company or shop name',
          semanticLabel: 'Business or shop name',
          error: _reqBusinessError,
        ),
        const SizedBox(height: 14),
        _buildLabeledInput(
          label: 'EMAIL ADDRESS',
          controller: _reqEmailController,
          icon: Icons.mail_outline_rounded,
          hintText: 'name@company.com',
          semanticLabel: 'Access request email address',
          keyboardType: TextInputType.emailAddress,
          error: _reqEmailError,
        ),
        const SizedBox(height: 14),
        _buildLabeledInput(
          label: 'PHONE NUMBER',
          controller: _reqPhoneController,
          icon: Icons.phone_outlined,
          hintText: '10-digit mobile number',
          semanticLabel: 'Phone number',
          keyboardType: TextInputType.phone,
          error: _reqPhoneError,
        ),
        const SizedBox(height: 20),
        _buildSubmitButton(
          label: 'REQUEST ACCESS',
          busySemanticLabel: 'Submitting access request',
          idleSemanticLabel: 'Request Access',
          onTap: _handleRequestAccess,
        ),
      ],
    );
  }

  Widget _buildLabeledInput({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
    required String semanticLabel,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFieldHeader(label, error: error),
        const SizedBox(height: 5),
        FrostedInputField(
          controller: controller,
          icon: icon,
          hintText: hintText,
          semanticLabel: semanticLabel,
          keyboardType: keyboardType,
          obscureText: obscureText,
          hasError: error != null,
          onToggleObscure: onToggleObscure,
        ),
        if (error != null) _buildInlineErrorText(error),
      ],
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required String busySemanticLabel,
    required String idleSemanticLabel,
    required VoidCallback onTap,
  }) {
    return LiquidGlass(
      isOrangeGloss: true,
      borderRadius: 24,
      height: 48,
      semanticLabel: _isLoading ? busySemanticLabel : idleSemanticLabel,
      onTap: _isLoading ? null : onTap,
      child: Center(
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
              )
            : Text(
                label,
                style: AppTypography.fontL(color: Colors.white, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildFieldHeader(String label, {String? error}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTypography.fontS(
            color: error != null ? AppColors.errorRed : AppColors.brandInk,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (error != null)
          const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.errorRed),
      ],
    );
  }

  Widget _buildInlineErrorText(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.errorRed,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildWarningCard(WarningBannerData data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: data.color.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      style: TextStyle(
                        color: data.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.message,
                      style: TextStyle(
                        color: data.color.withValues(alpha: 0.90),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (data.actionLabel != null && data.onAction != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Semantics(
                button: true,
                label: data.actionLabel,
                child: InkWell(
                  onTap: data.onAction,
                  borderRadius: BorderRadius.circular(8),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: data.color,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: data.color.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            data.actionLabel!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
