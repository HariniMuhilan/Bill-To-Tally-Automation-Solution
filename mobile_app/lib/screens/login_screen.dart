import 'dart:math';
import 'package:flutter/material.dart';
import '../models/user_session.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
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

  // Sign In controllers
  final _usernameController = TextEditingController(text: 'accounts_user_01');
  final _passwordController = TextEditingController(text: 'tally@2026');
  bool _obscurePassword = true;

  // Create Account controllers
  final _fullNameController = TextEditingController();
  final _regUsernameController = TextEditingController();
  final _regPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureRegPassword = true;
  bool _obscureConfirmPassword = true;

  String? _errorMessage;

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
      backgroundColor: AppColors.blushIvory,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand Logo & Typography (Thermal Printer + Billbooks)
                const BillbooksLogo(
                  iconSize: 110,
                  showWordmark: true,
                ),
                const SizedBox(height: 26),

                // Main Auth Card
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Smoothly animated pill toggle with permanent curvy borders
                        Container(
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: AppColors.blushIvory,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final pillWidth = constraints.maxWidth / 2;
                              return Stack(
                                children: [
                                  // Moving pill indicator (never flickers, keeps 10px rounded corners at all frames)
                                  AnimatedPositioned(
                                    duration: const Duration(milliseconds: 220),
                                    curve: Curves.easeInOutCubic,
                                    left: _isSignUp ? pillWidth : 0,
                                    top: 0,
                                    bottom: 0,
                                    width: pillWidth,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.plumSlate,
                                        borderRadius: BorderRadius.circular(10),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.plumSlate.withOpacity(0.25),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Interactive Touch Targets
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
                                          borderRadius: BorderRadius.circular(10),
                                          child: Center(
                                            child: Text(
                                              'Sign In',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: !_isSignUp ? Colors.white : AppColors.textMuted,
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
                                          borderRadius: BorderRadius.circular(10),
                                          child: Center(
                                            child: Text(
                                              'Create Account',
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _isSignUp ? Colors.white : AppColors.textMuted,
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
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.errorRedBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: AppColors.errorRed, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(color: AppColors.errorRed, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),
                        ],

                        // Dynamic Form: Sign In vs Create Account
                        if (!_isSignUp) ...[
                          // Sign In Form
                          const Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              hintText: 'e.g. accounts_user_01',
                              prefixIcon: const Icon(Icons.person_outline, size: 20),
                              filled: true,
                              fillColor: AppColors.blushIvory,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: AppColors.blushIvory,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // SIGN IN CTA
                          ElevatedButton(
                            onPressed: _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.plumSlate,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'SIGN IN',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                            ),
                          ),
                        ] else ...[
                          // Create Account Form
                          const Text('Full Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _fullNameController,
                            decoration: InputDecoration(
                              hintText: 'e.g. John Doe',
                              prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                              filled: true,
                              fillColor: AppColors.blushIvory,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _regUsernameController,
                            decoration: InputDecoration(
                              hintText: 'e.g. jdoe_admin',
                              prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                              filled: true,
                              fillColor: AppColors.blushIvory,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _regPasswordController,
                            obscureText: _obscureRegPassword,
                            decoration: InputDecoration(
                              hintText: 'At least 6 characters',
                              prefixIcon: const Icon(Icons.lock_outline, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureRegPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: () => setState(() => _obscureRegPassword = !_obscureRegPassword),
                              ),
                              filled: true,
                              fillColor: AppColors.blushIvory,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          const Text('Confirm Password', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: InputDecoration(
                              hintText: 'Re-enter password',
                              prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, size: 18),
                                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                              ),
                              filled: true,
                              fillColor: AppColors.blushIvory,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: AppColors.borderSubtle),
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),

                          // CREATE ACCOUNT CTA
                          ElevatedButton(
                            onPressed: _handleCreateAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.plumSlate,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text(
                              'CREATE ACCOUNT',
                              style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.8),
                            ),
                          ),
                        ],
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
