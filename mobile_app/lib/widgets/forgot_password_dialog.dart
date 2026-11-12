import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;
  final ValueChanged<String> onPasswordResetSuccess;

  const ForgotPasswordDialog({
    super.key,
    required this.initialEmail,
    required this.onPasswordResetSuccess,
  });

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  int _stage = 0; // 0 = Request Code, 1 = Enter Code & New Password

  late final TextEditingController _emailController;
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNewPass = true;
  bool _obscureConfirmPass = true;
  bool _isLoading = false;
  String? _dialogError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }

  Future<void> _handleSendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _dialogError = 'Please enter your email address');
      return;
    }
    if (!_isValidEmail(email)) {
      setState(() => _dialogError = 'Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
      _dialogError = null;
    });

    try {
      await SupabaseService.sendPasswordResetEmail(email: email);
      if (mounted) {
        setState(() {
          _stage = 1;
          _isLoading = false;
          _dialogError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        final lower = msg.toLowerCase();
        if (lower.contains('rate limit') || lower.contains('429') || lower.contains('over_email_send_rate_limit')) {
          msg = 'Email rate limit reached. Supabase limits email delivery frequency. Please wait a few minutes before trying again.';
        } else if (lower.contains('user not found')) {
          msg = 'No account found with this email address.';
        }
        setState(() {
          _dialogError = msg;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUpdatePassword() async {
    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (otp.isEmpty || otp.length < 6) {
      setState(() => _dialogError = 'Please enter the 6-digit verification code');
      return;
    }
    if (newPass.isEmpty) {
      setState(() => _dialogError = 'Please enter your new password');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _dialogError = 'Password must be at least 6 characters');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _dialogError = 'Passwords do not match');
      return;
    }

    setState(() {
      _isLoading = true;
      _dialogError = null;
    });

    try {
      await SupabaseService.verifyResetOtpAndUpdatePassword(
        email: email,
        otp: otp,
        newPassword: newPass,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onPasswordResetSuccess(email);
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString().replaceAll('Exception: ', '').replaceAll('AuthException: ', '');
        if (msg.toLowerCase().contains('invalid') || msg.toLowerCase().contains('expired')) {
          msg = 'The verification code is invalid or has expired. Please check your email or request a new code.';
        }
        setState(() {
          _dialogError = msg;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: LiquidGlass(
        borderRadius: 28,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Icon and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.maroonDark.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: AppColors.maroonDark,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _stage == 0 ? 'Forgot Password?' : 'Reset Password',
                          style: AppTypography.fontL(
                            color: AppColors.brandInk,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _stage == 0
                              ? 'Enter your email for a verification code'
                              : 'Enter 6-digit code and new password',
                          style: TextStyle(
                            fontFamily: 'DM Sans',
                            fontSize: 12,
                            color: AppColors.brandInk.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.brandInk),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Error banner if any
              if (_dialogError != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.errorRed.withValues(alpha: 0.30),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 16, color: AppColors.errorRed),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _dialogError!,
                          style: const TextStyle(
                            color: AppColors.errorRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // STAGE 0: Enter Email
              if (_stage == 0) ...[
                Text(
                  'REGISTERED EMAIL',
                  style: AppTypography.fontS(
                    color: AppColors.brandInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildFrostedInput(
                  controller: _emailController,
                  icon: Icons.mail_outline_rounded,
                  hintText: 'name@company.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 22),

                LiquidGlass(
                  isOrangeGloss: true,
                  borderRadius: 22,
                  height: 48,
                  onTap: _isLoading ? null : _handleSendResetCode,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            'SEND 6-DIGIT CODE',
                            style: AppTypography.fontM(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ] else ...[
                // STAGE 1: Enter OTP & New Password
                Text(
                  '6-DIGIT VERIFICATION CODE',
                  style: AppTypography.fontS(
                    color: AppColors.brandInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildFrostedInput(
                  controller: _otpController,
                  icon: Icons.pin_outlined,
                  hintText: 'Enter 6-digit code',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 14),

                Text(
                  'NEW PASSWORD',
                  style: AppTypography.fontS(
                    color: AppColors.brandInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildFrostedInput(
                  controller: _newPasswordController,
                  icon: Icons.lock_outline_rounded,
                  hintText: 'At least 6 characters',
                  obscureText: _obscureNewPass,
                  onToggleObscure: () => setState(() => _obscureNewPass = !_obscureNewPass),
                ),
                const SizedBox(height: 14),

                Text(
                  'CONFIRM NEW PASSWORD',
                  style: AppTypography.fontS(
                    color: AppColors.brandInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _buildFrostedInput(
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline_rounded,
                  hintText: 'Repeat new password',
                  obscureText: _obscureConfirmPass,
                  onToggleObscure: () => setState(() => _obscureConfirmPass = !_obscureConfirmPass),
                ),
                const SizedBox(height: 22),

                LiquidGlass(
                  isOrangeGloss: true,
                  borderRadius: 22,
                  height: 48,
                  onTap: _isLoading ? null : _handleUpdatePassword,
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                          )
                        : Text(
                            'UPDATE PASSWORD',
                            style: AppTypography.fontM(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => setState(() => _stage = 0),
                      child: Text(
                        'Change Email',
                        style: TextStyle(
                          color: AppColors.brandInk.withValues(alpha: 0.70),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _handleSendResetCode,
                      child: const Text(
                        'Resend Code',
                        style: TextStyle(
                          color: AppColors.maroonDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrostedInput({
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
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.90),
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.maroonDark.withValues(alpha: 0.70)),
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

