import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import '../widgets/server_settings_dialog.dart';

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

  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _regEmailController.dispose();
    _regPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isLoading = false;

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email (e.g. name@gmail.com)');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      if (msg.toLowerCase().contains('email not confirmed')) {
        msg = 'Please verify your email or disable "Confirm email" in Supabase dashboard.';
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
      return;
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

    if (email.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email address');
      return;
    }
    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email (e.g. name@gmail.com)');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter a password');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }
    if (password != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
      }
    } catch (e) {
      String msg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
      if (msg.toLowerCase().contains('email not confirmed')) {
        msg = 'Registration successful! Please check your email to verify your account.';
      }
      setState(() {
        _errorMessage = msg;
        _isLoading = false;
      });
      return;
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
          // 1. Exact 3D Wavy Liquid Glass Background (Cached in RepaintBoundary for 60/120fps)
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
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Full Brand Logo with PURCHASE VOUCHER AUTOMATION
                    Hero(
                      tag: 'billbooks_brand_logo',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/images/billbooks_header_logo.png',
                            width: 240,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            errorBuilder: (_, __, ___) => Image.asset(
                              'assets/images/billbooks_logo.png',
                              width: 240,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'PURCHASE VOUCHER AUTOMATION',
                            style: TextStyle(
                              fontFamily: 'DM Sans',
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 2.2,
                              color: const Color(0xFF966069),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Liquid Glass Form Card
                    LiquidGlass(
                      borderRadius: 28,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
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
                                                  _errorMessage = null;
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
                                                  _errorMessage = null;
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
                          const SizedBox(height: 20),

                          // Error Banner
                          if (_errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.errorRed.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: AppColors.errorRed.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.errorRed, size: 16),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: AppTypography.fontM(color: AppColors.errorRed),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Form Content
                          if (!_isSignUp) ...[
                            // EMAIL FIELD
                            Text(
                              'EMAIL ADDRESS',
                              style: AppTypography.fontS(color: AppColors.brandInk, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            _buildFrostedInputField(
                              controller: _emailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'name@company.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),

                            // PASSWORD FIELD
                            Text(
                              'PASSWORD',
                              style: AppTypography.fontS(color: AppColors.brandInk, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            _buildFrostedInputField(
                              controller: _passwordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: 'Enter password',
                              obscureText: _obscurePassword,
                              onToggleObscure: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            const SizedBox(height: 22),

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
                            Text(
                              'EMAIL ADDRESS',
                              style: AppTypography.fontS(color: AppColors.brandInk, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            _buildFrostedInputField(
                              controller: _regEmailController,
                              icon: Icons.mail_outline_rounded,
                              hintText: 'name@company.com',
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 14),

                            // PASSWORD FIELD
                            Text(
                              'PASSWORD',
                              style: AppTypography.fontS(color: AppColors.brandInk, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            _buildFrostedInputField(
                              controller: _regPasswordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: 'At least 6 characters',
                              obscureText: _obscureRegPassword,
                              onToggleObscure: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                            ),
                            const SizedBox(height: 14),

                            // CONFIRM PASSWORD FIELD
                            Text(
                              'CONFIRM PASSWORD',
                              style: AppTypography.fontS(color: AppColors.brandInk, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            _buildFrostedInputField(
                              controller: _confirmPasswordController,
                              icon: Icons.lock_outline_rounded,
                              hintText: 'Repeat password',
                              obscureText: _obscureConfirmPassword,
                              onToggleObscure: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            const SizedBox(height: 22),

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
                    const SizedBox(height: 22),

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
                    const SizedBox(height: 22),

                    // CONTINUE WITH GOOGLE Button
                    LiquidGlass(
                      borderRadius: 25,
                      height: 50,
                      onTap: _handleGoogleSignIn,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Google "G" logo
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

  Widget _buildFrostedInputField({
    required TextEditingController controller,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
  }) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC86E46).withValues(alpha: 0.08),
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
            color: AppColors.maroonDark.withValues(alpha: 0.70),
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
