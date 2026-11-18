import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import 'app_vector_icons.dart';
import 'liquid_glass.dart';

/// Modal dialog that verifies a 6-digit email OTP before submitting an access request.
class RequestAccessOtpDialog extends StatefulWidget {
  final String fullName;
  final String businessName;
  final String email;
  final String phone;
  final ApiService api;

  const RequestAccessOtpDialog({
    super.key,
    required this.fullName,
    required this.businessName,
    required this.email,
    required this.phone,
    required this.api,
  });

  @override
  State<RequestAccessOtpDialog> createState() => _RequestAccessOtpDialogState();
}

class _RequestAccessOtpDialogState extends State<RequestAccessOtpDialog> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMsg;
  String? _infoMsg;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String _cleanError(Object e) {
    final msg = e
        .toString()
        .replaceAll('Exception: ', '')
        .replaceAll('AuthException: ', '');
    final lower = msg.toLowerCase();
    if (lower.contains('rate limit') ||
        lower.contains('429') ||
        lower.contains('over_email_send_rate_limit')) {
      return 'Too many verification emails sent. Please wait a minute before trying again.';
    }
    if (lower.contains('expired') || lower.contains('invalid') || lower.contains('otp')) {
      return 'Invalid or expired 6-digit code. Check your email or tap Resend Code.';
    }
    return msg;
  }

  Future<void> _handleResend() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _infoMsg = null;
    });
    try {
      await SupabaseService.sendAccessRequestOtp(email: widget.email);
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _infoMsg = 'A fresh 6-digit code has been sent to ${widget.email}.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = _cleanError(e);
      });
    }
  }

  Future<void> _handleVerifyAndSubmit() async {
    final otp = _otpController.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() => _errorMsg = 'Enter the 6-digit numeric code sent to your email.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMsg = null;
      _infoMsg = null;
    });

    try {
      final accessToken = await SupabaseService.verifyAccessRequestOtp(
        email: widget.email,
        otp: otp,
      );

      final result = await widget.api.submitAccessRequest(
        fullName: widget.fullName,
        businessName: widget.businessName,
        email: widget.email,
        phone: widget.phone,
        accessToken: accessToken,
      );

      // Clear temporary OTP session so the device stays signed out until admin provisions login.
      try {
        await SupabaseService.signOut();
      } catch (_) {}

      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      try {
        await SupabaseService.signOut();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMsg = _cleanError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AppColors.maroonDark.withValues(alpha: 0.10),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.maroonDark.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const AppVectorIcon(
                      type: AppVectorIconType.mail,
                      color: AppColors.maroonDark,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Verify Email Address',
                      style: AppTypography.fontL(
                        color: AppColors.brandInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const AppVectorIcon(
                      type: AppVectorIconType.close,
                      size: 18,
                      color: AppColors.brandInk,
                    ),
                    tooltip: 'Close',
                    onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Enter the 6-digit verification code sent to ${widget.email} to confirm your email before sending your request.',
                style: AppTypography.fontS(color: AppColors.mutedText, fontWeight: FontWeight.w500)
                    .copyWith(height: 1.4),
              ),
              const SizedBox(height: 14),
              if (_errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.errorRed.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: const TextStyle(
                      color: AppColors.errorRed,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              if (_infoMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.successGreen.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    _infoMsg!,
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                '6-DIGIT VERIFICATION CODE',
                style: AppTypography.fontS(
                  color: AppColors.brandInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              FrostedInputField(
                controller: _otpController,
                icon: Icons.pin_outlined,
                hintText: '6-digit code (e.g. 123456)',
                semanticLabel: '6-digit email verification code',
                keyboardType: TextInputType.number,
                isSolidSurface: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading ? null : _handleResend,
                  child: const Text(
                    'Resend Code',
                    style: TextStyle(
                      fontFamily: 'DM Sans',
                      fontWeight: FontWeight.w700,
                      color: AppColors.maroonDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              LiquidGlass(
                isOrangeGloss: true,
                borderRadius: 24,
                height: 46,
                semanticLabel: _isLoading ? 'Verifying code' : 'Verify and submit request',
                onTap: _isLoading ? null : _handleVerifyAndSubmit,
                child: Center(
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'VERIFY & SUBMIT',
                          style: AppTypography.fontM(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
