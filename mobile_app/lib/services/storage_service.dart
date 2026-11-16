import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/invoice.dart';
import '../models/draft_sheet.dart';
import '../models/mapping.dart';
import '../models/audit_log.dart';
import '../models/user_session.dart';

/// Persistent local preferences store with user-scoped data isolation.
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

  static const String _keyCleanedOldData = 'bill_to_tally_mobile_cleaned_v5';
  static const String _keyFreeScansPrefix = 'bill_to_tally_free_scans_';
  static const String _keyProPrefix = 'bill_to_tally_pro_user_';

  static final RegExp _scopeSanitizer = RegExp(r'[^a-z0-9_@.-]');

  static const Set<String> _exemptAccounts = {
    'admin',
    'accounts_user_01',
    'operator',
  };

  static const String defaultApiUrl = 'https://bill-to-tally-automation-solution.onrender.com';

  final SharedPreferences _prefs;
  UserSession? _cachedUser;

  StorageService(this._prefs) {
    _cachedUser = _loadUserFromPrefs();
  }

  static Future<StorageService> init() async {
    final prefs = await SharedPreferences.getInstance();
    final service = StorageService(prefs);
    service._purgeOldDemoData();
    return service;
  }

  /// Removes legacy unscoped keys so older builds cannot leak data across accounts.
  void _purgeOldDemoData() {
    _prefs.remove(_keyApiBase);
    if (!_prefs.containsKey(_keyCleanedOldData)) {
      _prefs.remove(_keyInvoices);
      _prefs.remove(_keyDrafts);
      _prefs.remove(_keyMappings);
      _prefs.remove(_keyAudit);
      _prefs.setBool(_keyCleanedOldData, true);
    }
  }

  // --- Key Scoping & Normalization Helpers ---

  String _normalizeUsername(String? username) {
    return username?.trim().toLowerCase() ?? '';
  }

  String get _activeUserScope {
    final normalized = _normalizeUsername(_cachedUser?.username);
    if (normalized.isEmpty) return 'guest';
    return normalized.replaceAll(_scopeSanitizer, '_');
  }

  String _scopedKey(String baseKey) => '${baseKey}_$_activeUserScope';

  List<T> _readScopedList<T>(
    String baseKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final raw = _prefs.getString(_scopedKey(baseKey));
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((item) => fromJson(item as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeScopedList<T>(
    String baseKey,
    List<T> items,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    final encoded = jsonEncode(items.map(toJson).toList());
    await _prefs.setString(_scopedKey(baseKey), encoded);
  }

  // --- Environment & Tally Config ---

  String get apiBaseUrl => defaultApiUrl;
  Future<void> setApiBaseUrl(String url) async {}

  String get tallyHost => _prefs.getString(_keyTallyHost) ?? '127.0.0.1';
  Future<void> setTallyHost(String host) => _prefs.setString(_keyTallyHost, host);

  int get tallyPort => _prefs.getInt(_keyTallyPort) ?? 9000;
  Future<void> setTallyPort(int port) => _prefs.setInt(_keyTallyPort, port);

  String get tallyCompany => _prefs.getString(_keyTallyCompany) ?? 'ASHAN TEST LABS PVT LTD';
  Future<void> setTallyCompany(String c) => _prefs.setString(_keyTallyCompany, c);

  bool get postingEnabled => _prefs.getBool(_keyPostingEnabled) ?? false;
  Future<void> setPostingEnabled(bool e) => _prefs.setBool(_keyPostingEnabled, e);

  // --- User Session ---

  UserSession? _loadUserFromPrefs() {
    final raw = _prefs.getString(_keyUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserSession.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  UserSession? getUser() => _cachedUser;

  Future<void> saveUser(UserSession? user) async {
    _cachedUser = user;
    if (user == null) {
      await _prefs.remove(_keyUser);
    } else {
      await _prefs.setString(_keyUser, jsonEncode(user.toJson()));
    }
  }

  String getUserPassword(String username) {
    return _prefs.getString('user_pwd_${_normalizeUsername(username)}') ?? 'tally@2026';
  }

  Future<void> setUserPassword(String username, String password) async {
    await _prefs.setString('user_pwd_${_normalizeUsername(username)}', password);
  }

  // --- User-Scoped Invoices ---

  List<Invoice> getInvoices() {
    return _readScopedList(_keyInvoices, Invoice.fromJson)
        .where((i) => i.id != 'INV-743425' && !i.sourceFilename.contains('sample_bill'))
        .toList();
  }

  Future<void> clearAllInvoices() async {
    await _prefs.remove(_scopedKey(_keyInvoices));
  }

  Future<void> saveInvoices(List<Invoice> invoices) async {
    await _writeScopedList(_keyInvoices, invoices, (i) => i.toJson());
  }

  // --- User-Scoped Draft Excel Sheets ---

  List<DraftSheet> getDraftSheets() {
    return _readScopedList(_keyDrafts, DraftSheet.fromJson);
  }

  Future<void> saveDraftSheets(List<DraftSheet> drafts) async {
    await _writeScopedList(_keyDrafts, drafts, (d) => d.toJson());
  }

  // --- User-Scoped Master Mappings ---

  List<MasterMapping> getMappings() {
    final raw = _prefs.getString(_scopedKey(_keyMappings));
    if (raw == null) {
      return _defaultMappings();
    }
    return _readScopedList(_keyMappings, MasterMapping.fromJson);
  }

  Future<void> saveMappings(List<MasterMapping> mappings) async {
    await _writeScopedList(_keyMappings, mappings, (m) => m.toJson());
  }

  List<MasterMapping> _defaultMappings() {
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

  // --- User-Scoped Audit Trail ---

  List<AuditLog> getAuditLogs() {
    return _readScopedList(_keyAudit, AuditLog.fromJson);
  }

  Future<void> saveAuditLogs(List<AuditLog> logs) async {
    await _writeScopedList(_keyAudit, logs, (a) => a.toJson());
  }

  // --- Free Bill Quota & Pro Membership ---

  bool isUserExempt(String? username) {
    final normalized = _normalizeUsername(username);
    return normalized.isNotEmpty && _exemptAccounts.contains(normalized);
  }

  bool isUserPro(String? username) {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return false;
    if (_exemptAccounts.contains(normalized)) return true;
    return _prefs.getBool('$_keyProPrefix$normalized') ?? false;
  }

  Future<void> setUserPro(String? username, bool isPro) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return;
    await _prefs.setBool('$_keyProPrefix$normalized', isPro);
  }

  int getFreeScansUsed(String? username) {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return 0;
    return _prefs.getInt('$_keyFreeScansPrefix$normalized') ?? 0;
  }

  Future<void> incrementFreeScansUsed(String? username) async {
    final normalized = _normalizeUsername(username);
    if (normalized.isEmpty) return;
    final current = getFreeScansUsed(normalized);
    await _prefs.setInt('$_keyFreeScansPrefix$normalized', current + 1);
  }

  bool canUserScan(String? username) {
    if (isUserPro(username)) return true;
    return getFreeScansUsed(username) < 2;
  }
}
