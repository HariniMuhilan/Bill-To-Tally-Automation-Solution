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
  // Toggle: false = Sign In, true = Request Access
  bool _isSignUp = false;
  bool _accessRequestSubmitted = false;

  // Sign In Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Request Access Controllers
  final _reqFullNameController = TextEditingController();
  final _reqBusinessController = TextEditingController();
  final _reqEmailController = TextEditingController();
  final _reqPhoneController = TextEditingController();
  final _reqNotesController = TextEditingController();

  WarningBannerData? _warningBanner;

  // Real-time inline field validation errors
  String? _signInEmailError;
  String? _signInPasswordError;
  String? _reqFullNameError;
  String? _reqBusinessError;
  String? _reqEmailError;
  String? _reqPhoneError;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to auto-clear inline errors when user types
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
    _reqFullNameController.addListener(() {
      if (_reqFullNameError != null && _reqFullNameController.text.trim().isNotEmpty) {
        setState(() => _reqFullNameError = null);
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
      if (_reqPhoneError != null && _reqPhoneController.text.trim().length >= 10) {
        setState(() => _reqPhoneError = null);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _reqFullNameController.dispose();
    _reqBusinessController.dispose();
    _reqEmailController.dispose();
    _reqPhoneController.dispose();
    _reqNotesController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
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

    // Early validation
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
        if (session != null) {
          // Strict Single-Device Lock: Claim device session
          final deviceLabel = _getDeviceLabel();
          final claimRes = await widget.api.claimDeviceSession(deviceLabel: deviceLabel);

          if (!claimRes.success) {
            // Revert local sign-in if another device owns the session
            await SupabaseService.signOut();
            setState(() {
              _warningBanner = WarningBannerData(
                icon: Icons.phonelink_lock_rounded,
                title: 'Device Lock Conflict',
                message: claimRes.error ??
                    'This account is currently active on another device. BillBooks enforces single-device security per merchant. Please log out from that device or ask your administrator to reset your device lock.',
                color: AppColors.errorRed,
              );
            });
            return;
          }

          if (claimRes.data != null && claimRes.data!['session_id'] != null) {
            await widget.storage.setActiveDeviceSessionId(claimRes.data!['session_id'].toString());
          }

          widget.storage.saveUser(session);
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
      final rawMsg = e.toString().toLowerCase();
      
      // Case 1: Account does not exist or wrong password
      if (rawMsg.contains('invalid login credentials') || rawMsg.contains('invalid_credentials')) {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.person_search_rounded,
            title: 'Account Not Found or Incorrect Password',
            message: 'We could not sign you in with "$email". If your shop account has not been provisioned yet, please request access below.',
            color: AppColors.warningAmber,
            actionLabel: 'REQUEST ACCESS',
            onAction: () {
              setState(() {
                _isSignUp = true;
                _reqEmailController.text = email;
                _warningBanner = null;
                _signInEmailError = null;
                _signInPasswordError = null;
              });
            },
          );
        });
      } 
      // Case 2: Email not confirmed
      else if (rawMsg.contains('email not confirmed')) {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.mark_email_unread_rounded,
            title: 'Email Confirmation Required',
            message: 'Supabase sent a confirmation email to $email. Please check your inbox and verify before signing in, or disable "Confirm email" in Supabase Auth settings.',
            color: AppColors.warningAmber,
          );
        });
      }
      // Case 3: Network / Connection error
      else if (rawMsg.contains('socketexception') ||
               rawMsg.contains('failed host lookup') ||
               rawMsg.contains('clientexception') ||
               rawMsg.contains('connection refused')) {
        setState(() {
          _warningBanner = const WarningBannerData(
            icon: Icons.wifi_off_rounded,
            title: 'Network Connection Failed',
            message: 'Could not connect to the authentication server. Please check your internet connection.',
            color: AppColors.errorRed,
          );
        });
      }
      // Case 4: Rate limit / too many attempts
      else if (rawMsg.contains('over_email_send_rate_limit') || rawMsg.contains('too many requests')) {
        setState(() {
          _warningBanner = const WarningBannerData(
            icon: Icons.timer_outlined,
            title: 'Rate Limit Reached',
            message: 'Too many attempts. Please wait a minute and try again.',
            color: AppColors.warningAmber,
          );
        });
      }
      // Generic error
      else {
        String cleanMsg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.error_outline_rounded,
            title: 'Sign In Failed',
            message: cleanMsg,
            color: AppColors.errorRed,
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openForgotPasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ForgotPasswordDialog(
        initialEmail: _emailController.text.trim(),
        onPasswordResetSuccess: (email) {
          setState(() {
            _emailController.text = email;
            _passwordController.clear();
            _warningBanner = const WarningBannerData(
              icon: Icons.check_circle_outline_rounded,
              title: 'Password Updated Successfully',
              message: 'Your password has been reset. You can now sign in with your new password.',
              color: AppColors.successGreen,
            );
          });
        },
      ),
    );
  }

  Future<void> _handleRequestAccess() async {
    final fullName = _reqFullNameController.text.trim();
    final businessName = _reqBusinessController.text.trim();
    final email = _reqEmailController.text.trim();
    final phone = _reqPhoneController.text.trim();
    final notes = _reqNotesController.text.trim();

    // Early validation
    bool hasError = false;
    if (fullName.isEmpty) {
      _reqFullNameError = 'Contact name is required';
      hasError = true;
    } else {
      _reqFullNameError = null;
    }

    if (businessName.isEmpty) {
      _reqBusinessError = 'Shop or business name is required';
      hasError = true;
    } else {
      _reqBusinessError = null;
    }

    if (email.isEmpty) {
      _reqEmailError = 'Email address is required';
      hasError = true;
    } else if (!_isValidEmail(email)) {
      _reqEmailError = 'Enter a valid email address (e.g. name@gmail.com)';
      hasError = true;
    } else {
      _reqEmailError = null;
    }

    if (phone.isEmpty) {
      _reqPhoneError = 'Phone number is required for WhatsApp credentials';
      hasError = true;
    } else if (phone.replaceAll(RegExp(r'\D'), '').length < 10) {
      _reqPhoneError = 'Enter a valid 10-digit mobile number';
      hasError = true;
    } else {
      _reqPhoneError = null;
    }

    if (hasError) {
      setState(() {
        _warningBanner = const WarningBannerData(
          icon: Icons.warning_amber_rounded,
          title: 'Missing Required Information',
          message: 'Please review the fields highlighted below to submit your access request.',
          color: AppColors.orange,
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _warningBanner = null;
      _reqFullNameError = null;
      _reqBusinessError = null;
      _reqEmailError = null;
      _reqPhoneError = null;
    });

    try {
      final res = await widget.api.submitAccessRequest(
        fullName: fullName,
        businessName: businessName,
        email: email,
        phone: phone,
        notes: notes.isNotEmpty ? notes : null,
      );

      if (res.success) {
        setState(() {
          _accessRequestSubmitted = true;
          _warningBanner = null;
        });
      } else {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.error_outline_rounded,
            title: 'Submission Failed',
            message: res.error ?? 'Could not submit access request. Please check connection.',
            color: AppColors.errorRed,
          );
        });
      }
    } catch (e) {
      setState(() {
        _warningBanner = WarningBannerData(
          icon: Icons.error_outline_rounded,
          title: 'Request Error',
          message: e.toString(),
          color: AppColors.errorRed,
        );
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Exact 3D Wavy Liquid Glass Background
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LiquidBackgroundPainter(),
              ),
            ),
          ),

          // 2. Main Login Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Full Brand Logo
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

                    // Liquid Glass Form Card
                    LiquidGlass(
                      borderRadius: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Pill Toggle: SIGN IN / CREATE ACCOUNT
                          Container(
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
                                      left: _isSignUp ? pillWidth : 0,
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
                                        Expanded(
                                          child: Semantics(
                                            button: true,
                                            selected: !_isSignUp,
                                            label: 'Sign In tab',
                                            child: InkWell(
                                              onTap: () {
                                                if (_isSignUp) {
                                                  setState(() {
                                                    _isSignUp = false;
                                                    _warningBanner = null;
                                                  });
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(18),
                                              child: Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'SIGN IN',
                                                      maxLines: 1,
                                                      style: AppTypography.fontS(
                                                        color: !_isSignUp ? Colors.white : AppColors.brandInk.withValues(alpha: 0.70),
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Semantics(
                                            button: true,
                                            selected: _isSignUp,
                                            label: 'Request Access tab',
                                            child: InkWell(
                                              onTap: () {
                                                if (!_isSignUp) {
                                                  setState(() {
                                                    _isSignUp = true;
                                                    _warningBanner = null;
                                                  });
                                                }
                                              },
                                              borderRadius: BorderRadius.circular(18),
                                              child: Center(
                                                child: Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                                  child: FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    child: Text(
                                                      'REQUEST ACCESS',
                                                      maxLines: 1,
                                                      style: AppTypography.fontS(
                                                        color: _isSignUp ? Colors.white : AppColors.brandInk.withValues(alpha: 0.70),
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Clean Warning / Exceptional Case Card
                          if (_warningBanner != null) ...[
                            _buildWarningCard(_warningBanner!),
                            const SizedBox(height: 14),
                          ],

                          // Form Content
                          if (!_isSignUp) ...[
                            // EMAIL FIELD
                            _buildFieldHeader('EMAIL ADDRESS', error: _signInEmailError),
                            const SizedBox(height: 5),
                            FrostedInputField(
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'name@company.com',
                              semanticLabel: 'Email address',
                              keyboardType: TextInputType.emailAddress,
                              hasError: _signInEmailError != null,
                            ),
                            if (_signInEmailError != null)
                              _buildInlineErrorText(_signInEmailError!),
                            const SizedBox(height: 14),

                            // PASSWORD FIELD
                            _buildFieldHeader('PASSWORD', error: _signInPasswordError),
                            const SizedBox(height: 5),
                            FrostedInputField(
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: 'Enter password',
                              semanticLabel: 'Password',
                              obscureText: _obscurePassword,
                              hasError: _signInPasswordError != null,
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            if (_signInPasswordError != null)
                              _buildInlineErrorText(_signInPasswordError!),
                            const SizedBox(height: 4),

                            // FORGOT PASSWORD LINK
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

                            // SIGN IN CTA BUTTON (Orange Gloss)
                            LiquidGlass(
                              isOrangeGloss: true,
                              borderRadius: 24,
                              height: 48,
                              semanticLabel: _isLoading ? 'Signing in' : 'Sign In',
                              onTap: _isLoading ? null : _handleSignIn,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                      )
                                    : Text(
                                        'SIGN IN',
                                        style: AppTypography.fontL(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ] else if (_accessRequestSubmitted) ...[
                            // ACCESS REQUEST CONFIRMATION STATE
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.successGreen.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: AppColors.successGreen.withValues(alpha: 0.35),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: AppColors.successGreen,
                                    size: 48,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Access Request Submitted!',
                                    style: AppTypography.fontM(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.brandInk,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Thank you, ${_reqFullNameController.text.trim()}! Your request for ${_reqBusinessController.text.trim()} has been registered.\n\nOur team will review your shop details, verify subscription, and send your login credentials via WhatsApp / Email.',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.fontS(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            LiquidGlass(
                              isOrangeGloss: true,
                              borderRadius: 24,
                              height: 48,
                              onTap: () {
                                setState(() {
                                  _isSignUp = false;
                                  _accessRequestSubmitted = false;
                                  _reqFullNameController.clear();
                                  _reqBusinessController.clear();
                                  _reqEmailController.clear();
                                  _reqPhoneController.clear();
                                  _reqNotesController.clear();
                                });
                              },
                              child: Center(
                                child: Text(
                                  'RETURN TO SIGN IN',
                                  style: AppTypography.fontL(color: Colors.white, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),
                          ] else ...[
                            // REQUEST ACCESS FORM
                            // CONTACT NAME
                            _buildFieldHeader('CONTACT NAME', error: _reqFullNameError),
                            const SizedBox(height: 5),
                            FrostedInputField(
                              controller: _reqFullNameController,
                              icon: Icons.person_outline_rounded,
                              hintText: 'e.g. Ramesh Kumar',
                              semanticLabel: 'Contact full name',
                              keyboardType: TextInputType.name,
                              hasError: _reqFullNameError != null,
                            ),
                            if (_reqFullNameError != null)
                              _buildInlineErrorText(_reqFullNameError!),
                            const SizedBox(height: 12),

                            // SHOP / BUSINESS NAME
                            _buildFieldHeader('SHOP / BUSINESS NAME', error: _reqBusinessError),
                            const SizedBox(height: 5),
                            FrostedInputField(
                              controller: _reqBusinessController,
                              icon: Icons.storefront_outlined,
                              hintText: 'e.g. Sri Balaji Hardware & Electricals',
                              semanticLabel: 'Shop or business name',
                              keyboardType: TextInputType.text,
                              hasError: _reqBusinessError != null,
                            ),
                            if (_reqBusinessError != null)
                              _buildInlineErrorText(_reqBusinessError!),
                            const SizedBox(height: 12),

                            // EMAIL ADDRESS
                            _buildFieldHeader('EMAIL ADDRESS', error: _reqEmailError),
                            const SizedBox(height: 5),
                            FrostedInputField(
                              controller: _reqEmailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'shop@gmail.com',
                              semanticLabel: 'Shop contact email',
                              keyboardType: TextInputType.emailAddress,
                              hasError: _reqEmailError != null,
                            ),
                            if (_reqEmailError != null)
                              _buildInlineErrorText(_reqEmailError!),
                            const SizedBox(height: 12),

                            // WHATSAPP PHONE NUMBER
                            _buildFieldHeader('WHATSAPP MOBILE NUMBER', error: _reqPhoneError),
                            const SizedBox(height: 5),
                            FrostedInputField(
                              controller: _reqPhoneController,
                              icon: Icons.phone_outlined,
                              hintText: '+91 98400 12345',
                              semanticLabel: 'Mobile number for credentials',
                              keyboardType: TextInputType.phone,
                              hasError: _reqPhoneError != null,
                            ),
                            if (_reqPhoneError != null)
                              _buildInlineErrorText(_reqPhoneError!),
                            const SizedBox(height: 12),

                            // NOTES / REQUIREMENTS (OPTIONAL)
                            _buildFieldHeader('SHOP REQUIREMENTS (OPTIONAL)'),
                            const SizedBox(height: 5),
                            FrostedInputField(
                              controller: _reqNotesController,
                              icon: Icons.notes_rounded,
                              hintText: 'e.g. Parrys wholesale shop, ~40 daily bills',
                              semanticLabel: 'Additional notes or requirements',
                              keyboardType: TextInputType.text,
                            ),
                            const SizedBox(height: 18),

                            // REQUEST ACCESS CTA BUTTON
                            LiquidGlass(
                              isOrangeGloss: true,
                              borderRadius: 24,
                              height: 48,
                              semanticLabel: _isLoading ? 'Submitting request' : 'Request Access',
                              onTap: _isLoading ? null : _handleRequestAccess,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                      )
                                    : Text(
                                        'REQUEST SHOP ACCESS',
                                        style: AppTypography.fontL(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ],
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
