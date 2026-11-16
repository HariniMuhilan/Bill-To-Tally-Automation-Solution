import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/draft_sheet.dart';
import '../models/mapping.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/liquid_glass.dart';
import 'inbox_screen.dart';
import 'review_screen.dart';
import 'tally_connector_screen.dart';
import '../services/supabase_service.dart';

class HomeShell extends StatefulWidget {
  final StorageService storage;
  final ApiService api;
  final UserSession user;
  final VoidCallback onLogout;

  const HomeShell({
    super.key,
    required this.storage,
    required this.api,
    required this.user,
    required this.onLogout,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;
  List<Invoice> _invoices = [];
  List<DraftSheet> _draftSheets = [];
  List<MasterMapping> _mappings = [];
  Invoice? _selectedReviewInvoice;
  final GlobalKey<InboxScreenState> _inboxKey = GlobalKey<InboxScreenState>();

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _refreshSubscriptionAndSync();
  }

  void _loadInitialData() {
    setState(() {
      _invoices = widget.storage.getInvoices();
      _draftSheets = widget.storage.getDraftSheets();
      _mappings = widget.storage.getMappings();
      _selectedReviewInvoice = null;
    });
  }

  Future<void> _refreshSubscriptionAndSync() async {
    try {
      final statusRes = await widget.api.getSubscriptionStatus();
      if (statusRes.success && statusRes.data != null) {
        final data = statusRes.data!;
        final isAllowed = data['is_scan_allowed'] == true;
        await widget.storage.setScanAllowed(isAllowed);
        await widget.storage.setSubscriptionStatus(data['status']?.toString());
        await widget.storage.setSubscriptionStartDate(data['subscription_start']?.toString());
        await widget.storage.setSubscriptionEndDate(data['subscription_end']?.toString());
        if (mounted) setState(() {});
      }
    } catch (_) {}

    // Cross-device sync: fetch draft sheets from backend
    try {
      final sheetsRes = await widget.api.fetchDraftSheets();
      if (sheetsRes.success && sheetsRes.data != null) {
        final remoteList = sheetsRes.data!;
        if (remoteList.isNotEmpty) {
          final List<DraftSheet> remoteDrafts = [];
          for (final item in remoteList) {
            if (item is Map) {
              final rawRows = (item['rows_json'] as List?) ?? [];
              final invList = rawRows.map((r) => Invoice.fromJson(r as Map<String, dynamic>)).toList();
              remoteDrafts.add(
                DraftSheet(
                  id: item['sheet_id']?.toString() ?? '',
                  fileName: item['sheet_name']?.toString() ?? 'Vouchers.xlsx',
                  createdAt: item['updated_at']?.toString() ?? '',
                  updatedAt: item['updated_at']?.toString() ?? '',
                  totalAmount: invList.fold(0.0, (sum, i) => sum + i.grandTotal),
                  invoices: invList,
                ),
              );
            }
          }
          if (remoteDrafts.isNotEmpty) {
            final localMap = {for (var d in _draftSheets) d.id: d};
            for (final rd in remoteDrafts) {
              localMap[rd.id] = rd;
            }
            final merged = localMap.values.toList();
            if (mounted) {
              setState(() => _draftSheets = merged);
              widget.storage.saveDraftSheets(merged);
            }
          }
        }
      }
    } catch (_) {}
  }

  Future<void> _syncDraftSheetsToBackend(List<DraftSheet> sheets) async {
    try {
      final payload = sheets.map((s) => {
        'sheet_id': s.id,
        'sheet_name': s.fileName,
        'rows_json': s.invoices.map((i) => i.toJson()).toList(),
        'updated_at': s.updatedAt.isNotEmpty ? s.updatedAt : DateTime.now().toIso8601String(),
      }).toList();
      await widget.api.syncDraftSheets(payload);
    } catch (_) {}
  }

  void _selectInvoiceForReview(Invoice inv) {
    setState(() {
      _selectedReviewInvoice = inv;
      _currentIndex = 1;
    });
  }

  void _handleQuickCameraCapture() {
    if (!widget.storage.isScanAllowed) {
      _showScanDisabledDialog();
      return;
    }
    if (_currentIndex != 0) {
      setState(() => _currentIndex = 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _inboxKey.currentState?.handleCaptureCamera();
      });
    } else {
      _inboxKey.currentState?.handleCaptureCamera();
    }
  }

  void _showScanDisabledDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_rounded, color: AppColors.orange, size: 26),
            SizedBox(width: 10),
            Text(
              'Scanning Disabled',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.brandInk,
              ),
            ),
          ],
        ),
        content: const Text(
          'Your shop subscription is currently inactive, expired, or pending renewal.\n\nScanning new bills is temporarily disabled, but you can continue to view, edit, and export all your existing bills and Excel sheets.\n\nPlease contact your administrator to renew your monthly plan.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13.5, height: 1.4, color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.maroonDark)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final needsReviewCount = _invoices.where((i) => i.status == 'NEEDS_REVIEW' || i.status == 'NEEDS_CORRECTION').length;

    Widget body;
    switch (_currentIndex) {
      case 0:
        body = InboxScreen(
          key: _inboxKey,
          storage: widget.storage,
          api: widget.api,
          invoices: _invoices,
          onInvoicesChanged: (updated) => setState(() => _invoices = updated),
          onSelectInvoice: _selectInvoiceForReview,
        );
        break;
      case 1:
        if (_selectedReviewInvoice == null) {
          body = Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LiquidGlass(
                    borderRadius: 50,
                    width: 90,
                    height: 90,
                    child: Center(
                      child: Icon(
                        Icons.document_scanner_outlined,
                        size: 40,
                        color: AppColors.maroonDark.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Scan a Bill for Review',
                    style: AppTypography.fontL(
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No invoice is currently open. Take a new photo or tap any bill in the Inbox to start review.',
                    textAlign: TextAlign.center,
                    style: AppTypography.fontS(
                      fontWeight: FontWeight.w500,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          body = ReviewScreen(
            storage: widget.storage,
            invoice: _selectedReviewInvoice!,
            mappings: _mappings,
            draftSheets: _draftSheets,
            onInvoiceUpdated: (updated) {
              setState(() {
                _selectedReviewInvoice = updated;
                final idx = _invoices.indexWhere((i) => i.id == updated.id);
                if (idx != -1) {
                  _invoices[idx] = updated;
                  widget.storage.saveInvoices(_invoices);
                }
              });
            },
            onDraftSheetsUpdated: (sheets) {
              setState(() {
                _draftSheets = sheets;
                widget.storage.saveDraftSheets(_draftSheets);
              });
              _syncDraftSheetsToBackend(sheets);
            },
            onBack: () {
              setState(() {
                _selectedReviewInvoice = null;
                _currentIndex = 0;
              });
            },
          );
        }
        break;
      case 2:
        body = TallyConnectorScreen(
          storage: widget.storage,
          api: widget.api,
          draftSheets: _draftSheets,
          onDraftSheetsChanged: (updated) {
            setState(() => _draftSheets = updated);
            widget.storage.saveDraftSheets(updated);
            _syncDraftSheetsToBackend(updated);
          },
        );
        break;
      default:
        body = const SizedBox();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Organic Liquid Background with Radial Glows and Faint Wave Lines (Cached in RepaintBoundary)
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: LiquidBackgroundPainter(),
              ),
            ),
          ),

          // 2. Main Content Layout
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Top Header: Exact new BillBooks Logo artwork on the left, round maroon avatar on the right
                _buildHeader(),

                // Subscription Expiry View-Only Mode Banner
                if (!widget.storage.isScanAllowed)
                  _buildSubscriptionExpiryBanner(),

                // Screen Body
                Expanded(child: body),
              ],
            ),
          ),

          // 3. Floating Bottom Navigation Bar (rounded 40px glass bar, inset 14px from edges)
          Positioned(
            left: 14,
            right: 14,
            bottom: 12,
            child: _buildFloatingBottomNav(needsReviewCount),
          ),

          // 4. Separate Raised Circular Camera Action Button (popped out independently above the nav bar)
          Positioned(
            left: 0,
            right: 0,
            bottom: 30,
            child: Center(
              child: _buildSeparateCameraButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionExpiryBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warningAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warningAmber.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Subscription Inactive (View-Only Mode)\nScanning new bills is disabled. All existing vouchers and Excel sheets remain viewable and downloadable.',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.brandInk.withValues(alpha: 0.9),
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Exact BillBooks Logo with PURCHASE VOUCHER AUTOMATION
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/images/billbooks_header_logo.png',
                height: 28,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/images/billbooks_logo.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'PURCHASE VOUCHER AUTOMATION',
                  style: TextStyle(
                    fontFamily: 'DM Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: AppColors.maroonDark.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),

          // Round Maroon Avatar with User Initials (AU)
          PopupMenuButton<String>(
            tooltip: 'User Profile',
            offset: const Offset(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (val) {
              if (val == 'logout') {
                _handleLogout();
              } else if (val == 'delete_account') {
                _confirmDeleteAccount();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'user',
                enabled: false,
                child: Text(widget.user.fullName, style: AppTypography.fontM()),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded, color: AppColors.errorRed, size: 18),
                    const SizedBox(width: 8),
                    Text('Logout', style: AppTypography.fontM(color: AppColors.errorRed)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete_account',
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed, size: 18),
                    const SizedBox(width: 8),
                    Text('Delete Account', style: AppTypography.fontM(color: AppColors.errorRed)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.maroonLight, AppColors.maroonDark],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.maroonDark.withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  widget.user.initials,
                  style: AppTypography.fontS(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    try {
      await widget.api.releaseDeviceSession();
    } catch (_) {}
    await widget.storage.setActiveDeviceSessionId(null);
    try {
      await SupabaseService.signOut();
    } catch (_) {}
    widget.onLogout();
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 28),
            SizedBox(width: 8),
            Text(
              'Delete Account',
              style: TextStyle(
                fontFamily: 'DM Sans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: AppColors.brandInk,
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you sure you want to permanently delete your merchant account?\n\nThis will immediately remove your credentials, all uploaded invoice photos, and draft data from the servers. This action cannot be undone.',
          style: TextStyle(fontFamily: 'DM Sans', fontSize: 13.5, height: 1.4, color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.mutedText)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              _executeDeleteAccount();
            },
            child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteAccount() async {
    try {
      await widget.api.deleteAccount();
    } catch (_) {}
    await widget.storage.clearAllUserData();
    try {
      await SupabaseService.signOut();
    } catch (_) {}
    widget.onLogout();
  }

  Widget _buildFloatingBottomNav(int needsReviewCount) {
    return LiquidGlass(
      useBlur: true,
      borderRadius: 40,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 58),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // 0: Inbox
            Expanded(
              child: _buildNavItem(
                index: 0,
                icon: Icons.all_inbox_rounded,
                label: 'Inbox',
              ),
            ),
            // 1: Review
            Expanded(
              child: _buildNavItem(
                index: 1,
                icon: Icons.check_box_outlined,
                label: 'Review',
                badgeCount: needsReviewCount,
              ),
            ),
            // Center Spacer for Separate Raised Camera Button
            const SizedBox(width: 64),
            // 2: Tally
            Expanded(
              child: _buildNavItem(
                index: 2,
                icon: Icons.sync_rounded,
                label: 'Tally',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparateCameraButton() {
    return Tooltip(
      message: 'Capture invoice photo',
      child: Semantics(
        button: true,
        label: 'Capture invoice photo',
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.orangeEnd.withValues(alpha: 0.55),
                blurRadius: 18,
                spreadRadius: 2,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            shape: const CircleBorder(
              side: BorderSide(color: Colors.white, width: 3.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Ink(
              width: 62,
              height: 62,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppColors.orangeStart, AppColors.orangeEnd],
                ),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _handleQuickCameraCapture,
                child: const ExcludeSemantics(
                  child: Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
  }) {
    final isSelected = _currentIndex == index;
    final semanticSummary = (badgeCount != null && badgeCount > 0)
        ? '$label, $badgeCount pending'
        : label;

    return Semantics(
      button: true,
      selected: isSelected,
      label: semanticSummary,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            setState(() {
              _currentIndex = index;
              if (index != 1) _selectedReviewInvoice = null;
            });
          },
          borderRadius: BorderRadius.circular(18),
          child: ExcludeSemantics(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Nav Button Circle: Active (Maroon glass circle) vs Inactive (Light glass circle)
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isSelected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.maroonLight, AppColors.maroonDark],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.75),
                          AppColors.warmPeachTint.withValues(alpha: 0.45),
                        ],
                      ),
                border: Border.all(
                  color: isSelected
                      ? AppColors.pinkGlow.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? AppColors.maroonShadow.withValues(alpha: 0.35)
                        : AppColors.warmOrangeShadow.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : AppColors.maroonDark.withValues(alpha: 0.75),
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Label in DM Sans Size 12 (scales down gracefully at extreme OS font scales)
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: AppTypography.fontS(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.brandInk : AppColors.mutedText,
                ).copyWith(height: 1.1),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 2),
              width: 14,
              height: 2.5,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.maroonDark : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
          ),
        ),
        ),
      ),
    );
  }
}
