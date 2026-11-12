import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice.dart';
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

  /// Save invoice & line items to Supabase tables
  static Future<void> saveInvoice(Invoice inv) async {
    final supa = client;
    if (supa == null) return;

    final user = supa.auth.currentUser;
    if (user == null) return;

    try {
      // 1. Insert invoice record
      final invoiceData = {
        'user_id': user.id,
        'invoice_no': inv.invoiceNo,
        'invoice_date': inv.invoiceDate.isNotEmpty ? inv.invoiceDate : null,
        'supplier_name': inv.supplierRaw,
        'supplier_gstin': inv.gstin,
        'invoice_mode': inv.type.toLowerCase().contains('inventory') ? 'inventory' : 'accounting',
        'subtotal_amount': inv.subtotal,
        'discount_amount': inv.discount,
        'cgst_amount': inv.cgst,
        'sgst_amount': inv.sgst,
        'igst_amount': inv.igst,
        'total_amount': inv.grandTotal,
        'status': inv.status,
        'image_url': inv.imageUrl,
        'tally_ref': inv.tallyRef,
        'raw_ocr_data': {'raw_text': inv.rawOcrText},
      };

      final inserted = await supa.from('invoices').insert(invoiceData).select('id').single();
      final String invoiceDbId = inserted['id'];

      // 2. Insert line items
      if (inv.lines.isNotEmpty) {
        final lineItemsData = inv.lines.map((item) {
          return {
            'invoice_id': invoiceDbId,
            'line_no': item.lineNo,
            'item_description': item.descRaw,
            'hsn_sac_code': item.hsn,
            'quantity': item.qty,
            'unit_of_measure': item.unit,
            'unit_price': item.rate,
            'taxable_amount': item.taxable,
            'gst_rate_percent': item.taxRate,
            'cgst_amount': item.taxAmount / 2,
            'sgst_amount': item.taxAmount / 2,
            'igst_amount': 0.0,
            'total_line_amount': item.total,
            'tally_ledger_name': item.stockItem,
            'tally_item_name': item.stockItem,
          };
        }).toList();

        await supa.from('line_items').insert(lineItemsData);
      }
    } catch (e) {
      debugPrint('Supabase invoice save error: $e');
    }
  }
}

