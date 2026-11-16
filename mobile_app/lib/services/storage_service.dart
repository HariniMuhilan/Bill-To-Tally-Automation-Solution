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
  static const String _keyActiveSessionId = 'bill_to_tally_active_session_id';
  static const String _keyScanAllowed = 'bill_to_tally_is_scan_allowed';
  static const String _keySubStatus = 'bill_to_tally_sub_status';
  static const String _keySubStart = 'bill_to_tally_sub_start';
  static const String _keySubEnd = 'bill_to_tally_sub_end';

  static final RegExp _scopeSanitizer = RegExp(r'[^a-z0-9_@.-]');

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

  // --- Device Session (Single-Device Enforcement) ---

  String? get activeDeviceSessionId => _prefs.getString(_keyActiveSessionId);

  Future<void> setActiveDeviceSessionId(String? sessionId) async {
    if (sessionId == null || sessionId.isEmpty) {
      await _prefs.remove(_keyActiveSessionId);
    } else {
      await _prefs.setString(_keyActiveSessionId, sessionId);
    }
  }

  // --- Subscription State (Admin-Provisioned & Expiry-Gated) ---

  bool get isScanAllowed => _prefs.getBool(_keyScanAllowed) ?? true;

  Future<void> setScanAllowed(bool allowed) async {
    await _prefs.setBool(_keyScanAllowed, allowed);
  }

  String? get subscriptionStatus => _prefs.getString(_keySubStatus);

  Future<void> setSubscriptionStatus(String? status) async {
    if (status == null) {
      await _prefs.remove(_keySubStatus);
    } else {
      await _prefs.setString(_keySubStatus, status);
    }
  }

  String? get subscriptionStartDate => _prefs.getString(_keySubStart);

  Future<void> setSubscriptionStartDate(String? date) async {
    if (date == null) {
      await _prefs.remove(_keySubStart);
    } else {
      await _prefs.setString(_keySubStart, date);
    }
  }

  String? get subscriptionEndDate => _prefs.getString(_keySubEnd);

  Future<void> setSubscriptionEndDate(String? date) async {
    if (date == null) {
      await _prefs.remove(_keySubEnd);
    } else {
      await _prefs.setString(_keySubEnd, date);
    }
  }

  /// Wipes all user data, cached vouchers, drafts, and device credentials (for account deletion or logout)
  Future<void> clearAllUserData() async {
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keyActiveSessionId);
    await _prefs.remove(_keyScanAllowed);
    await _prefs.remove(_keySubStatus);
    await _prefs.remove(_keySubStart);
    await _prefs.remove(_keySubEnd);
    await _prefs.remove(_scopedKey(_keyInvoices));
    await _prefs.remove(_scopedKey(_keyDrafts));
    await _prefs.remove(_scopedKey(_keyMappings));
    await _prefs.remove(_scopedKey(_keyAudit));
    _cachedUser = null;
  }
}
