import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_session.dart';
import 'storage_service.dart';

class SignUpResult {
  final bool requiresEmailConfirmation;
  final UserSession? session;
  final String email;

  const SignUpResult({
    required this.requiresEmailConfirmation,
    this.session,
    required this.email,
  });
}

class SupabaseService {
  static SupabaseClient? get client {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static bool get isReady => client != null;

  /// Current Supabase JWT access token, or null if signed out / uninitialized.
  static String? get currentAccessToken => client?.auth.currentSession?.accessToken;

  /// HTTP Authorization headers for authenticated backend requests.
  static Map<String, String> authHeaders([String? overrideToken]) {
    final token = overrideToken ?? currentAccessToken;
    if (token == null || token.isEmpty) return const {};
    return {'Authorization': 'Bearer $token'};
  }

  /// Refresh current Supabase session cleanly and return the updated JWT access token.
  static Future<String?> refreshAccessToken() async {
    final supa = client;
    if (supa == null || supa.auth.currentSession == null) return null;
    try {
      final res = await supa.auth.refreshSession();
      return res.session?.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Helper to ensure valid email address
  static String formatEmail(String input) {
    final trimmed = input.trim().toLowerCase();
    if (trimmed.contains('@')) {
      return trimmed;
    }
    return '$trimmed@billbooks.io';
  }

  /// Sign In with Email & Password
  static Future<UserSession?> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final email = formatEmail(emailOrUsername);
    final response = await supa.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Login failed: user not found');
    }

    final meta = user.userMetadata ?? {};
    final fullName = meta['full_name'] as String? ?? email.split('@').first;
    final username = emailOrUsername.contains('@') ? emailOrUsername.split('@').first : emailOrUsername;
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'AU';

    return UserSession(
      username: username,
      fullName: fullName,
      role: 'Reviewer',
      initials: initials.isNotEmpty ? initials : 'AU',
    );
  }

  static String get emailConfirmationRedirectUrl =>
      '${StorageService.staticSiteUrl}/email-confirmed/index.html';

  /// Sign Up with Email & Password
  static Future<SignUpResult> signUp({
    required String emailOrUsername,
    required String password,
    required String fullName,
  }) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final email = formatEmail(emailOrUsername);
    final response = await supa.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName},
      emailRedirectTo: emailConfirmationRedirectUrl,
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Registration failed: please try again');
    }

    // When Supabase email confirmation is enabled, session is null until confirmed
    if (response.session == null) {
      return SignUpResult(
        requiresEmailConfirmation: true,
        email: email,
      );
    }

    final username = emailOrUsername.contains('@') ? emailOrUsername.split('@').first : emailOrUsername;
    final initials = fullName.isNotEmpty
        ? fullName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase()
        : 'AU';

    final session = UserSession(
      username: username,
      fullName: fullName,
      role: 'Reviewer',
      initials: initials.isNotEmpty ? initials : 'AU',
    );

    return SignUpResult(
      requiresEmailConfirmation: false,
      session: session,
      email: email,
    );
  }

  /// Sign Out
  static Future<void> signOut() async {
    final supa = client;
    if (supa != null) {
      await supa.auth.signOut();
    }
  }

  /// Resend Sign-Up Email Confirmation Link
  static Future<void> resendConfirmationEmail({required String email}) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final formatted = formatEmail(email);
    await supa.auth.resend(
      type: OtpType.signup,
      email: formatted,
      emailRedirectTo: emailConfirmationRedirectUrl,
    );
  }

  /// Send Password Reset Code / Link to user email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final formatted = formatEmail(email);
    await supa.auth.resetPasswordForEmail(formatted);
  }

  /// Send a 6-digit email verification OTP before submitting an onboarding access request.
  static Future<void> sendAccessRequestOtp({required String email}) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final formatted = formatEmail(email);
    await supa.auth.signInWithOtp(
      email: formatted,
      shouldCreateUser: true,
    );
  }

  /// Verify the 6-digit email OTP and return the short-lived JWT access token.
  static Future<String> verifyAccessRequestOtp({
    required String email,
    required String otp,
  }) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final formatted = formatEmail(email);
    final authRes = await supa.auth.verifyOTP(
      email: formatted,
      token: otp.trim(),
      type: OtpType.email,
    );

    final token = authRes.session?.accessToken ?? supa.auth.currentSession?.accessToken;
    if (token == null || token.trim().isEmpty) {
      throw Exception('Invalid or expired 6-digit verification code.');
    }
    return token.trim();
  }

  /// Verify 6-8 digit OTP code (if not already verified in current recovery session) and update password
  static Future<void> verifyResetOtpAndUpdatePassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final formatted = formatEmail(email);
    // 1. Verify OTP only if recovery session is not already active (prevents single-use OTP
    //    from failing as "expired" if updateUser rejects e.g. same-as-old password).
    if (supa.auth.currentSession == null) {
      final authRes = await supa.auth.verifyOTP(
        email: formatted,
        token: otp.trim(),
        type: OtpType.recovery,
      );

      if (authRes.session == null && authRes.user == null) {
        throw Exception('Invalid or expired verification code. Please check your email.');
      }
    }

    // 2. Set new password for the authenticated recovery session
    await supa.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}

