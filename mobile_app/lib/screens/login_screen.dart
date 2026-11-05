import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/user_session.dart';
import '../services/storage_service.dart';
import '../widgets/billbooks_logo.dart';

class LoginScreen extends StatefulWidget {
  final StorageService storage;
  final ValueChanged<UserSession> onLoginSuccess;

  const LoginScreen({
    super.key,
    required this.storage,
    required this.onLoginSuccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSignUp = false;

  // Controllers
  final _usernameController = TextEditingController(text: 'accounts_user_01');
  final _passwordController = TextEditingController(text: 'tally@2026');
  bool _obscurePassword = true;

  final _fullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;

  // Color Palette as per spec
  static const Color cBackground = Color(0xFFFCEEDE);     // Creamy peach bg
  static const Color cInputBg = Color(0xFFFFCC80);        // Input fill
  static const Color cPrimaryOrange = Color(0xFFF25F3D);  // Sign in CTA button
  static const Color cCardBg = Color(0xFFFFFFFF);         // White form card
  static const Color cPillTrack = Color(0xFFD9D9D9);      // Segmented control track
  static const Color cDeepPlum = Color(0xFF7C2946);       // Deep plum text/accents

  // 3 DM Sans Typography Sizes: Large (16), Medium (13), Small (11)
  static final TextStyle fontL = GoogleFonts.dmSans(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static final TextStyle fontM = GoogleFonts.dmSans(
    fontSize: 13,
    fontWeight: FontWeight.w600,
  );

  static final TextStyle fontS = GoogleFonts.dmSans(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _regUsernameController.dispose();
    _regPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignIn() {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter your username');
      return;
    }

    final matched = UserSession.demoPresets.firstWhere(
      (u) => u.username.toLowerCase() == username.toLowerCase(),
      orElse: () => UserSession(
        username: username,
        fullName: username.toUpperCase(),
        role: 'Standard User',
        initials: username.substring(0, min(2, username.length)).toUpperCase(),
      ),
    );

    widget.storage.saveUser(matched);
    widget.onLoginSuccess(matched);
  }

  void _handleGoogleSignIn() {
    final googleUser = UserSession(
      username: 'google_user',
      fullName: 'Google User',
      role: 'Reviewer',
      initials: 'GU',
    );
    widget.storage.saveUser(googleUser);
    widget.onLoginSuccess(googleUser);
  }

  void _handleCreateAccount() {
    final fullName = _fullNameController.text.trim();
    final username = _regUsernameController.text.trim();
    final password = _regPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (fullName.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Please enter a username');
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

    final newUser = UserSession(
      username: username,
      fullName: fullName,
      role: 'Reviewer',
      initials: fullName.isNotEmpty ? fullName.substring(0, min(2, fullName.length)).toUpperCase() : 'AU',
    );

    widget.storage.saveUser(newUser);
    widget.onLoginSuccess(newUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cBackground,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Top Brand Logo & Tagline
                const BillbooksLogo(
                  iconSize: 100,
                  showWordmark: true,
                ),
                const SizedBox(height: 32),

                // 2. White Card Container
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cCardBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Pill Toggle: SIGN IN / CREATE ACCOUNT
                      Container(
                        height: 44,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: cPillTrack,
                          borderRadius: BorderRadius.circular(22),
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
                                      color: cCardBg,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.06),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
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
                                            style: fontS.copyWith(
                                              color: !_isSignUp ? const Color(0xFF222222) : const Color(0xFF555555),
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
                                            style: fontS.copyWith(
                                              color: _isSignUp ? const Color(0xFF222222) : const Color(0xFF555555),
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
                            color: const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: fontM.copyWith(color: const Color(0xFFDC2626)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Form Content
                      if (!_isSignUp) ...[
                        // USERNAME FIELD
                        Text(
                          'USERNAME',
                          style: fontS.copyWith(color: const Color(0xFF222222)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cInputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _usernameController,
                            style: fontM.copyWith(
                              color: const Color(0xFF2D1600),
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // PASSWORD FIELD
                        Text(
                          'PASSWORD',
                          style: fontS.copyWith(color: const Color(0xFF222222)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cInputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  style: fontM.copyWith(
                                    color: const Color(0xFF2D1600),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                                child: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF6B4800),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // SIGN IN CTA BUTTON (F25F3D)
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cPrimaryOrange,
                              foregroundColor: cCardBg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'SIGN IN',
                              style: fontL.copyWith(color: cCardBg),
                            ),
                          ),
                        ),
                      ] else ...[
                        // FULL NAME FIELD
                        Text(
                          'FULL NAME',
                          style: fontS.copyWith(color: const Color(0xFF222222)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cInputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _fullNameController,
                            style: fontM.copyWith(color: const Color(0xFF2D1600)),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // USERNAME FIELD
                        Text(
                          'USERNAME',
                          style: fontS.copyWith(color: const Color(0xFF222222)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cInputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: TextField(
                            controller: _regUsernameController,
                            style: fontM.copyWith(color: const Color(0xFF2D1600)),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // PASSWORD FIELD
                        Text(
                          'PASSWORD',
                          style: fontS.copyWith(color: const Color(0xFF222222)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cInputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _regPasswordController,
                                  obscureText: _obscureRegPassword,
                                  style: fontM.copyWith(color: const Color(0xFF2D1600)),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                                child: Icon(
                                  _obscureRegPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF6B4800),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // CONFIRM PASSWORD FIELD
                        Text(
                          'CONFIRM PASSWORD',
                          style: fontS.copyWith(color: const Color(0xFF222222)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: cInputBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  style: fontM.copyWith(color: const Color(0xFF2D1600)),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                child: Icon(
                                  _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: const Color(0xFF6B4800),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // CREATE ACCOUNT CTA BUTTON
                        SizedBox(
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _handleCreateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cPrimaryOrange,
                              foregroundColor: cCardBg,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              'CREATE ACCOUNT',
                              style: fontL.copyWith(color: cCardBg),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Subtle horizontal separator line
                Container(
                  width: double.infinity,
                  height: 1,
                  color: const Color(0xFF9E9E9E).withOpacity(0.4),
                ),
                const SizedBox(height: 24),

                // 4. CONTINUE WITH GOOGLE Button
                InkWell(
                  onTap: _handleGoogleSignIn,
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cCardBg,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          style: fontS.copyWith(
                            color: const Color(0xFF1F1F1F),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
