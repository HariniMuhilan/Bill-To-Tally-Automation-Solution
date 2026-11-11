import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/server_settings_dialog.dart';

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
  bool _isSignUp = false;

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  final _regEmailController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureConfirmPassword = true;

  WarningBannerData? _warningBanner;

  // Real-time inline field validation errors
  String? _signInEmailError;
  String? _signInPasswordError;
  String? _signUpEmailError;
  String? _signUpPasswordError;
  String? _signUpConfirmError;

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
    _regEmailController.addListener(() {
      if (_signUpEmailError != null && _isValidEmail(_regEmailController.text.trim())) {
        setState(() => _signUpEmailError = null);
      }
    });
    _regPasswordController.addListener(() {
      if (_signUpPasswordError != null && _regPasswordController.text.length >= 6) {
        setState(() => _signUpPasswordError = null);
      }
      if (_confirmPasswordController.text.isNotEmpty) {
        setState(() {
          _signUpConfirmError = _regPasswordController.text == _confirmPasswordController.text
              ? null
              : 'Passwords do not match';
        });
      }
    });
    _confirmPasswordController.addListener(() {
      if (_confirmPasswordController.text.isNotEmpty) {
        setState(() {
          _signUpConfirmError = _regPasswordController.text == _confirmPasswordController.text
              ? null
              : 'Passwords do not match';
        });
      } else {
        setState(() => _signUpConfirmError = null);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
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
          color: Color(0xFFE65100),
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
            message: 'We could not sign you in with "$email". If you have not created an account yet, create one now.',
            color: const Color(0xFFD97706),
            actionLabel: 'CREATE AN ACCOUNT',
            onAction: () {
              setState(() {
                _isSignUp = true;
                _regEmailController.text = email;
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
            color: const Color(0xFFD97706),
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
            color: Color(0xFFD97706),
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

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In is temporarily disabled. Please use your email and password.'),
        backgroundColor: Color(0xFFC86E46),
      ),
    );
  }

  Future<void> _handleCreateAccount() async {
    final email = _regEmailController.text.trim();
    final password = _regPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();
    final fullName = email.contains('@') ? email.split('@').first : email;

    // Early validation
    bool hasError = false;
    if (email.isEmpty) {
      _signUpEmailError = 'Email address is required';
      hasError = true;
    } else if (!_isValidEmail(email)) {
      _signUpEmailError = 'Enter a valid email address (e.g. name@gmail.com)';
      hasError = true;
    } else {
      _signUpEmailError = null;
    }

    if (password.isEmpty) {
      _signUpPasswordError = 'Password is required';
      hasError = true;
    } else if (password.length < 6) {
      _signUpPasswordError = 'Password must be at least 6 characters';
      hasError = true;
    } else {
      _signUpPasswordError = null;
    }

    if (confirmPass.isEmpty) {
      _signUpConfirmError = 'Please confirm your password';
      hasError = true;
    } else if (password != confirmPass) {
      _signUpConfirmError = 'Passwords do not match';
      hasError = true;
    } else {
      _signUpConfirmError = null;
    }

    if (hasError) {
      setState(() {
        _warningBanner = const WarningBannerData(
          icon: Icons.warning_amber_rounded,
          title: 'Check Registration Details',
          message: 'Please review the warnings highlighted below before submitting.',
          color: Color(0xFFE65100),
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _warningBanner = null;
      _signUpEmailError = null;
      _signUpPasswordError = null;
      _signUpConfirmError = null;
    });

    try {
      if (SupabaseService.isReady) {
        final session = await SupabaseService.signUp(
          emailOrUsername: email,
          password: password,
          fullName: fullName,
        );
        if (session != null) {
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

      // Case 1: User already registered
      if (rawMsg.contains('user already registered') ||
          rawMsg.contains('user_already_exists') ||
          rawMsg.contains('already been registered')) {
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.account_circle_rounded,
            title: 'Account Already Exists',
            message: 'An account is already registered with "$email". Please sign in instead.',
            color: const Color(0xFF2563EB),
            actionLabel: 'SIGN IN INSTEAD',
            onAction: () {
              setState(() {
                _isSignUp = false;
                _emailController.text = email;
                _warningBanner = null;
                _signUpEmailError = null;
                _signUpPasswordError = null;
                _signUpConfirmError = null;
              });
            },
          );
        });
      }
      // Case 2: Email not confirmed (if user signed up and confirmation is required)
      else if (rawMsg.contains('email not confirmed')) {
        setState(() {
          _warningBanner = const WarningBannerData(
            icon: Icons.mark_email_unread_rounded,
            title: 'Verification Link Sent',
            message: 'Account created! Please check your email inbox to verify your account, or disable "Confirm email" in Supabase Auth settings.',
            color: AppColors.successGreen,
          );
        });
      }
      // Case 3: Network error
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
      // Generic error
      else {
        String cleanMsg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        setState(() {
          _warningBanner = WarningBannerData(
            icon: Icons.error_outline_rounded,
            title: 'Registration Error',
            message: cleanMsg,
            color: AppColors.errorRed,
          );
        });
      }
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

          // Backend URL Settings Button
          Positioned(
            top: 10,
            right: 14,
            child: SafeArea(
              child: IconButton(
                tooltip: 'Backend Server URL',
                icon: const Icon(Icons.settings_ethernet_rounded, color: AppColors.maroonDark, size: 24),
                onPressed: () => ServerSettingsDialog.show(context, storage: widget.storage, api: widget.api),
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
                          const Text(
                            'PURCHASE VOUCHER AUTOMATION',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                              color: Color(0xFF966069),
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
                            height: 44,
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
                                      duration: const Duration(milliseconds: 220),
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
                                              child: Text(
                                                'SIGN IN',
                                                style: AppTypography.fontS(
                                                  color: !_isSignUp ? Colors.white : AppColors.brandInk.withValues(alpha: 0.65),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
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
                                              child: Text(
                                                'CREATE ACCOUNT',
                                                style: AppTypography.fontS(
                                                  color: _isSignUp ? Colors.white : AppColors.brandInk.withValues(alpha: 0.65),
                                                  fontWeight: FontWeight.w700,
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
                            _buildFrostedInputField(
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'name@company.com',
                              keyboardType: TextInputType.emailAddress,
                              hasError: _signInEmailError != null,
                            ),
                            if (_signInEmailError != null)
                              _buildInlineErrorText(_signInEmailError!),
                            const SizedBox(height: 14),

                            // PASSWORD FIELD
                            _buildFieldHeader('PASSWORD', error: _signInPasswordError),
                            const SizedBox(height: 5),
                            _buildFrostedInputField(
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: 'Enter password',
                              obscureText: _obscurePassword,
                              hasError: _signInPasswordError != null,
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            if (_signInPasswordError != null)
                              _buildInlineErrorText(_signInPasswordError!),
                            const SizedBox(height: 20),

                            // SIGN IN CTA BUTTON (Orange Gloss)
                            LiquidGlass(
                              isOrangeGloss: true,
                              borderRadius: 24,
                              height: 48,
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
                          ] else ...[
                            // EMAIL FIELD
                            _buildFieldHeader('EMAIL ADDRESS', error: _signUpEmailError),
                            const SizedBox(height: 5),
                            _buildFrostedInputField(
                              controller: _regEmailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'name@company.com',
                              keyboardType: TextInputType.emailAddress,
                              hasError: _signUpEmailError != null,
                            ),
                            if (_signUpEmailError != null)
                              _buildInlineErrorText(_signUpEmailError!),
                            const SizedBox(height: 14),

                            // PASSWORD FIELD
                            _buildFieldHeader('PASSWORD', error: _signUpPasswordError),
                            const SizedBox(height: 5),
                            _buildFrostedInputField(
                              controller: _regPasswordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: 'At least 6 characters',
                              obscureText: _obscureRegPassword,
                              hasError: _signUpPasswordError != null,
                              onToggleObscure: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                            ),
                            if (_signUpPasswordError != null)
                              _buildInlineErrorText(_signUpPasswordError!),
                            const SizedBox(height: 14),

                            // CONFIRM PASSWORD FIELD
                            _buildFieldHeader('CONFIRM PASSWORD', error: _signUpConfirmError),
                            const SizedBox(height: 5),
                            _buildFrostedInputField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: 'Repeat password',
                              obscureText: _obscureConfirmPassword,
                              hasError: _signUpConfirmError != null,
                              onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            if (_signUpConfirmError != null)
                              _buildInlineErrorText(_signUpConfirmError!),
                            const SizedBox(height: 20),

                            // CREATE ACCOUNT CTA BUTTON
                            LiquidGlass(
                              isOrangeGloss: true,
                              borderRadius: 24,
                              height: 48,
                              onTap: _isLoading ? null : _handleCreateAccount,
                              child: Center(
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                      )
                                    : Text(
                                        'CREATE ACCOUNT',
                                        style: AppTypography.fontL(color: Colors.white, fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subtle horizontal separator line
                    Container(
                      width: double.infinity,
                      height: 1.2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            AppColors.brandInk.withValues(alpha: 0.18),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // CONTINUE WITH GOOGLE Button
                    LiquidGlass(
                      borderRadius: 25,
                      height: 50,
                      onTap: _handleGoogleSignIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/google_logo.png',
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.g_mobiledata_rounded,
                                size: 26,
                                color: Color(0xFF4285F4),
                              );
                            },
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'CONTINUE WITH GOOGLE',
                            style: AppTypography.fontS(
                              color: AppColors.brandInk,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
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
          fontSize: 11.5,
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
                        fontSize: 11.5,
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
              child: InkWell(
                onTap: data.onAction,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                          fontSize: 11,
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
          ],
        ],
      ),
    );
  }

  Widget _buildFrostedInputField({
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool hasError = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasError
              ? AppColors.errorRed.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.90),
          width: hasError ? 1.5 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: hasError
                ? AppColors.errorRed.withValues(alpha: 0.08)
                : const Color(0xFFC86E46).withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            icon,
            size: 19,
            color: hasError ? AppColors.errorRed : AppColors.maroonDark.withValues(alpha: 0.70),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: AppTypography.fontM(
                color: AppColors.brandInk,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: hintText,
                hintStyle: TextStyle(
                  color: AppColors.brandInk.withValues(alpha: 0.40),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          if (onToggleObscure != null)
            GestureDetector(
              onTap: onToggleObscure,
              child: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: AppColors.maroonDark.withValues(alpha: 0.65),
                size: 18,
              ),
            ),
        ],
      ),
    );
  }
}
