import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/audit_log.dart';
import 'package:mobile_app/models/draft_sheet.dart';
import 'package:mobile_app/models/invoice.dart';
import 'package:mobile_app/models/mapping.dart';
import 'package:mobile_app/models/user_session.dart';
import 'package:mobile_app/services/storage_service.dart';

UserSession _makeUser(String username, {String fullName = 'Test User'}) {
  return UserSession(
    username: username,
    fullName: fullName,
    role: 'Reviewer',
    initials: 'TU',
  );
}

Invoice _makeInvoice(String id, String supplier, {double total = 1000.0}) {
  return Invoice(
    id: id,
    sourceFilename: '$id.jpg',
    supplierRaw: supplier,
    invoiceNo: 'BILL-$id',
    invoiceDate: '2026-11-13',
    grandTotal: total,
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('User-Scoped Storage Isolation', () {
    test('isolates invoices, drafts, mappings, and audit logs between users on the same device', () async {
      final storage = await StorageService.init();

      // 1. User A logs in and stores data
      final userA = _makeUser('alice@example.com', fullName: 'Alice');
      await storage.saveUser(userA);

      final invA = _makeInvoice('INV-A1', 'Alice Hardware');
      await storage.saveInvoices([invA]);
      await storage.saveDraftSheets([
        DraftSheet(
          id: 'DRAFT-A1',
          fileName: 'Alice_Sheet.xlsx',
          createdAt: '2026-11-13',
          updatedAt: '2026-11-13',
          totalAmount: 1000.0,
          invoices: [invA],
        ),
      ]);
      await storage.saveMappings([
        MasterMapping(
          id: 'MAP-A1',
          raw: 'Alice Raw',
          tally: 'Alice Tally Ledger',
          category: 'Purchase',
          date: '2026-11-13',
        ),
      ]);
      await storage.saveAuditLogs([
        AuditLog(
          time: '2026-11-13 10:00:00',
          actor: userA.username,
          action: 'APPROVED',
          summary: 'Alice approved INV-A1',
        ),
      ]);

      expect(storage.getInvoices().map((e) => e.id), ['INV-A1']);
      expect(storage.getDraftSheets().map((e) => e.id), ['DRAFT-A1']);
      expect(storage.getMappings().map((e) => e.id), ['MAP-A1']);
      expect(storage.getAuditLogs().length, 1);

      // 2. User A logs out, User B logs in -> must start completely clean
      await storage.saveUser(null);
      expect(storage.getUser(), isNull);

      final userB = _makeUser('bob@example.com', fullName: 'Bob');
      await storage.saveUser(userB);

      expect(storage.getInvoices(), isEmpty);
      expect(storage.getDraftSheets(), isEmpty);
      expect(storage.getAuditLogs(), isEmpty);
      // User B gets fresh default mappings instead of Alice's custom mappings
      expect(storage.getMappings().any((m) => m.id == 'MAP-A1'), isFalse);
      expect(storage.getMappings().any((m) => m.id == 'MAP-LED-01'), isTrue);

      // 3. User B saves own invoice
      final invB = _makeInvoice('INV-B1', 'Bob Traders');
      await storage.saveInvoices([invB]);
      expect(storage.getInvoices().map((e) => e.id), ['INV-B1']);

      // 4. Switch back to User A -> sees only User A's data
      await storage.saveUser(userA);
      expect(storage.getInvoices().map((e) => e.id), ['INV-A1']);
      expect(storage.getDraftSheets().map((e) => e.id), ['DRAFT-A1']);
      expect(storage.getMappings().map((e) => e.id), ['MAP-A1']);
      expect(storage.getAuditLogs().first.summary, 'Alice approved INV-A1');
    });

    test('normalizes casing and whitespace so the same account shares its scope', () async {
      final storage = await StorageService.init();

      await storage.saveUser(_makeUser('  Alice@Example.COM  '));
      await storage.saveInvoices([_makeInvoice('INV-NORM', 'Normalized Supplier')]);

      await storage.saveUser(null);
      await storage.saveUser(_makeUser('alice@example.com'));

      expect(storage.getInvoices().map((e) => e.id), ['INV-NORM']);
    });

    test('handles special characters in usernames safely without colliding', () async {
      final storage = await StorageService.init();

      await storage.saveUser(_makeUser('user/one+test!'));
      await storage.saveInvoices([_makeInvoice('INV-SPEC1', 'Vendor 1')]);

      await storage.saveUser(_makeUser('user_two'));
      expect(storage.getInvoices(), isEmpty);

      await storage.saveUser(_makeUser('user/one+test!'));
      expect(storage.getInvoices().map((e) => e.id), ['INV-SPEC1']);
    });

    test('clearAllInvoices only deletes active user invoices and preserves others', () async {
      final storage = await StorageService.init();
      final userA = _makeUser('user_a');
      final userB = _makeUser('user_b');

      await storage.saveUser(userA);
      await storage.saveInvoices([_makeInvoice('INV-A', 'Vendor A')]);

      await storage.saveUser(userB);
      await storage.saveInvoices([_makeInvoice('INV-B', 'Vendor B')]);

      // Clear while logged in as User A
      await storage.saveUser(userA);
      await storage.clearAllInvoices();
      expect(storage.getInvoices(), isEmpty);

      // User B must still retain their invoice
      await storage.saveUser(userB);
      expect(storage.getInvoices().map((e) => e.id), ['INV-B']);
    });

    test('falls back safely to guest scope when logged out without leaking into named users', () async {
      final storage = await StorageService.init();

      expect(storage.getUser(), isNull);
      await storage.saveInvoices([_makeInvoice('INV-GUEST', 'Guest Bill')]);
      expect(storage.getInvoices().map((e) => e.id), ['INV-GUEST']);

      await storage.saveUser(_makeUser('real_user'));
      expect(storage.getInvoices(), isEmpty);
    });
  });

  group('Resilience & Edge Cases', () {
    test('purges legacy unscoped keys from older builds on init', () async {
      SharedPreferences.setMockInitialValues({
        'bill_to_tally_mobile_invoices': jsonEncode([_makeInvoice('INV-OLD', 'Old Leak').toJson()]),
        'bill_to_tally_mobile_drafts': jsonEncode([]),
        'bill_to_tally_mobile_audit': jsonEncode([]),
        'bill_to_tally_mobile_mappings': jsonEncode([]),
      });

      final storage = await StorageService.init();
      final prefs = await SharedPreferences.getInstance();

      expect(prefs.containsKey('bill_to_tally_mobile_invoices'), isFalse);
      expect(prefs.containsKey('bill_to_tally_mobile_drafts'), isFalse);
      expect(prefs.containsKey('bill_to_tally_mobile_audit'), isFalse);
      expect(prefs.containsKey('bill_to_tally_mobile_mappings'), isFalse);
      expect(prefs.getBool('bill_to_tally_mobile_cleaned_v5'), isTrue);

      await storage.saveUser(_makeUser('new_account'));
      expect(storage.getInvoices(), isEmpty);
    });

    test('survives corrupted JSON in SharedPreferences without crashing', () async {
      SharedPreferences.setMockInitialValues({
        'bill_to_tally_mobile_user': '{not-valid-json',
        'bill_to_tally_mobile_invoices_alice': 'corrupted[json',
        'bill_to_tally_mobile_drafts_alice': '12345',
        'bill_to_tally_mobile_mappings_alice': '{"unexpected":"object"}',
        'bill_to_tally_mobile_audit_alice': 'invalid',
        'bill_to_tally_mobile_cleaned_v5': true,
      });

      final storage = await StorageService.init();
      expect(storage.getUser(), isNull);

      await storage.saveUser(_makeUser('alice'));
      expect(storage.getInvoices(), isEmpty);
      expect(storage.getDraftSheets(), isEmpty);
      expect(storage.getMappings(), isEmpty);
      expect(storage.getAuditLogs(), isEmpty);
    });

    test('filters out legacy sample bill INV-743425 automatically', () async {
      final storage = await StorageService.init();
      await storage.saveUser(_makeUser('alice'));
      await storage.saveInvoices([
        _makeInvoice('INV-743425', 'Sample Demo'),
        _makeInvoice('INV-REAL', 'Real Store'),
      ]);

      expect(storage.getInvoices().map((e) => e.id), ['INV-REAL']);
    });

    test('enforces 2 free scan limit per user and respects Pro/exempt accounts', () async {
      final storage = await StorageService.init();

      expect(storage.isUserExempt('Admin '), isTrue);
      expect(storage.canUserScan('admin'), isTrue);

      const user = 'TrialUser@Example.com';
      expect(storage.canUserScan(user), isTrue);
      await storage.incrementFreeScansUsed(user);
      expect(storage.getFreeScansUsed('trialuser@example.com'), 1);
      expect(storage.canUserScan(user), isTrue);

      await storage.incrementFreeScansUsed(user);
      expect(storage.getFreeScansUsed(user), 2);
      expect(storage.canUserScan(user), isFalse);

      await storage.setUserPro(user, true);
      expect(storage.canUserScan(user), isTrue);
    });
  });
}
