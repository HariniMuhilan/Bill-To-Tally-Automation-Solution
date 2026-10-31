import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';
import '../models/draft_sheet.dart';
import '../models/mapping.dart';
import '../models/audit_log.dart';
import '../models/user_session.dart';

class StorageService {
  static const String _keyInvoices = 'bill_to_tally_mobile_invoices';
  static const String _keyDrafts = 'bill_to_tally_mobile_drafts';
  static const String _keyMappings = 'bill_to_tally_mobile_mappings';
  static const String _keyAudit = 'bill_to_tally_mobile_audit';
  static const String _keyUser = 'bill_to_tally_mobile_user';
  static const String _keyApiBase = 'bill_to_tally_mobile_api_base';
  static const String _keyTallyHost = 'bill_to_tally_mobile_tally_host';
  static const String _keyTallyPort = 'bill_to_tally_mobile_tally_port';
  static const String _keyTallyCompany = 'bill_to_tally_mobile_tally_company';
  static const String _keyPostingEnabled = 'bill_to_tally_mobile_posting_enabled';

  static const String _keyCleanedOldData = 'bill_to_tally_mobile_cleaned_v4';

  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    service._purgeOldDemoData();
    return service;
  }

  void _purgeOldDemoData() {
    if (!_prefs.containsKey(_keyCleanedOldData)) {
      _prefs.remove(_keyInvoices);
      _prefs.setBool(_keyCleanedOldData, true);
    }
  }

  // --- Configuration ---
  String get apiBaseUrl => _prefs.getString(_keyApiBase) ?? 'http://127.0.0.1:8000';
  Future<void> setApiBaseUrl(String url) => _prefs.setString(_keyApiBase, url);

  String get tallyHost => _prefs.getString(_keyTallyHost) ?? '127.0.0.1';
  Future<void> setTallyHost(String host) => _prefs.setString(_keyTallyHost, host);

  int get tallyPort => _prefs.getInt(_keyTallyPort) ?? 9000;
  Future<void> setTallyPort(int port) => _prefs.setInt(_keyTallyPort, port);

  String get tallyCompany => _prefs.getString(_keyTallyCompany) ?? 'ASHAN TEST LABS PVT LTD';
  Future<void> setTallyCompany(String c) => _prefs.setString(_keyTallyCompany, c);

  bool get postingEnabled => _prefs.getBool(_keyPostingEnabled) ?? false;
  Future<void> setPostingEnabled(bool e) => _prefs.setBool(_keyPostingEnabled, e);

  // --- User Session ---
  UserSession? getUser() {
    final raw = _prefs.getString(_keyUser);
    if (raw == null) return UserSession.defaultUser;
    try {
      return UserSession.fromJson(jsonDecode(raw));
    } catch (_) {
      return UserSession.defaultUser;
    }
  }

  Future<void> saveUser(UserSession? user) async {
    if (user == null) {
      await _prefs.remove(_keyUser);
    } else {
      await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
    }
  }

  String getUserPassword(String username) {
    return _prefs.getString('user_pwd_$username') ?? 'tally@2026';
  }

  Future<void> setUserPassword(String username, String password) async {
    await _prefs.setString('user_pwd_$username', password);
  }

  // --- Invoices ---
  List<Invoice> getInvoices() {
    final raw = _prefs.getString(_keyInvoices);
    if (raw == null) {
      return [];
    }
    try {
      final List list = jsonDecode(raw);
      return list
          .map((i) => Invoice.fromJson(i as Map<String, dynamic>))
          .where((i) => i.id != 'INV-743425' && !i.sourceFilename.contains('sample_bill'))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clearAllInvoices() async {
    await _prefs.remove(_keyInvoices);
  }

  Future<void> saveInvoices(List<Invoice> invoices) async {
    final list = invoices.map((i) => i.toJson()).toList();
    await _prefs.setString(_keyInvoices, jsonEncode(list));
  }

  // --- Draft Excel Sheets ---
  List<DraftSheet> getDraftSheets() {
    final raw = _prefs.getString(_keyDrafts);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((d) => DraftSheet.fromJson(d as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDraftSheets(List<DraftSheet> drafts) async {
    final list = drafts.map((d) => d.toJson()).toList();
    await _prefs.setString(_keyDrafts, jsonEncode(list));
  }

  // --- Master Mappings ---
  List<MasterMapping> getMappings() {
    final raw = _prefs.getString(_keyMappings);
    if (raw == null) {
      // Seed default ledger mappings
      return [
        MasterMapping(
          id: 'MAP-LED-01',
          raw: 'Purchase Accounts 18% GST',
          tally: 'Purchase - GST 18%',
          category: 'Purchase Accounts',
          status: 'VERIFIED',
          date: '2026-09-01',
        ),
        MasterMapping(
          id: 'MAP-LED-02',
          raw: 'Printing and Stationery Expenses',
          tally: 'Printing & Stationery Exp',
          category: 'Indirect Expenses',
          status: 'VERIFIED',
          date: '2026-09-01',
        ),
        MasterMapping(
          id: 'MAP-LED-03',
          raw: 'Input CGST 9%',
          tally: 'Input CGST @ 9%',
          category: 'Duties & Taxes',
          status: 'VERIFIED',
          date: '2026-09-01',
        ),
        MasterMapping(
          id: 'MAP-LED-04',
          raw: 'Input SGST 9%',
          tally: 'Input SGST @ 9%',
          category: 'Duties & Taxes',
          status: 'VERIFIED',
          date: '2026-09-01',
        ),
      ];
    }
    try {
      final List list = jsonDecode(raw);
      return list.map((m) => MasterMapping.fromJson(m as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveMappings(List<MasterMapping> mappings) async {
    final list = mappings.map((m) => m.toJson()).toList();
    await _prefs.setString(_keyMappings, jsonEncode(list));
  }

  // --- Audit Trail ---
  List<AuditLog> getAuditLogs() {
    final raw = _prefs.getString(_keyAudit);
    if (raw == null) return [];
    try {
      final List list = jsonDecode(raw);
      return list.map((a) => AuditLog.fromJson(a as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAuditLogs(List<AuditLog> logs) async {
    final list = logs.map((a) => a.toJson()).toList();
    await _prefs.setString(_keyAudit, jsonEncode(list));
  }
}
