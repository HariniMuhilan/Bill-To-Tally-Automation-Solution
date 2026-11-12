import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_session.dart';

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

  /// Send Password Reset 6-Digit Code / Link to user email
  static Future<void> sendPasswordResetEmail({required String email}) async {
    final supa = client;
    if (supa == null) {
      throw Exception('Supabase is not initialized');
    }

    final formatted = formatEmail(email);
    await supa.auth.resetPasswordForEmail(formatted);
  }

  /// Verify 6-digit OTP code and update password
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
    // 1. Verify OTP with recovery type
    final authRes = await supa.auth.verifyOTP(
      email: formatted,
      token: otp.trim(),
      type: OtpType.recovery,
    );

    if (authRes.session == null && authRes.user == null) {
      throw Exception('Invalid or expired verification code. Please check your email.');
    }

    // 2. Set new password for the authenticated recovery session
    await supa.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }
}

