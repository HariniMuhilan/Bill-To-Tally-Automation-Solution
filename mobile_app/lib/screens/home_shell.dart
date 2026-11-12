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
import 'audit_trail_screen.dart';
import 'upgrade_screen.dart';
import '../widgets/upgrade_paywall_dialog.dart';

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
  }

  void _loadInitialData() {
    setState(() {
      _invoices = widget.storage.getInvoices();
      _draftSheets = widget.storage.getDraftSheets();
      _mappings = widget.storage.getMappings();
      _selectedReviewInvoice = null;
    });
  }

  void _selectInvoiceForReview(Invoice inv) {
    setState(() {
      _selectedReviewInvoice = inv;
      _currentIndex = 1;
    });
  }

  void _handleQuickCameraCapture() {
    if (!widget.storage.canUserScan(widget.user.username)) {
      UpgradePaywallDialog.show(
        context,
        onUpgrade: () => setState(() => _currentIndex = 3),
      );
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
          onNavigateToUpgrade: () => setState(() => _currentIndex = 3),
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
          onDraftSheetsChanged: (updated) => setState(() => _draftSheets = updated),
        );
        break;
      case 3:
        body = UpgradeScreen(storage: widget.storage);
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
              Text(
                'PURCHASE VOUCHER AUTOMATION',
                style: TextStyle(
                  fontFamily: 'DM Sans',
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: AppColors.maroonDark.withValues(alpha: 0.75),
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
                widget.onLogout();
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
            ],
            child: Container(
              width: 42,
              height: 42,
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

  Widget _buildFloatingBottomNav(int needsReviewCount) {
    return LiquidGlass(
      useBlur: true,
      borderRadius: 40,
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 0: Inbox
          _buildNavItem(
            index: 0,
            icon: Icons.all_inbox_rounded,
            label: 'Inbox',
          ),
          // 1: Review
          _buildNavItem(
            index: 1,
            icon: Icons.check_box_outlined,
            label: 'Review',
            badgeCount: needsReviewCount,
          ),
          // Center Spacer for Separate Raised Camera Button
          const SizedBox(width: 64),
          // 2: Tally
          _buildNavItem(
            index: 2,
            icon: Icons.sync_rounded,
            label: 'Tally',
          ),
          // 3: Upgrade (Future Payment Gateway)
          _buildNavItem(
            index: 3,
            icon: Icons.workspace_premium_rounded,
            label: 'Upgrade',
          ),
        ],
      ),
    );
  }

  Widget _buildSeparateCameraButton() {
    return GestureDetector(
      onTap: _handleQuickCameraCapture,
      child: Container(
        width: 62,
        height: 62,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.orangeStart, AppColors.orangeEnd],
          ),
          border: Border.all(
            color: Colors.white,
            width: 3.0,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF0580E).withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: 2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt_rounded,
            color: Colors.white,
            size: 28,
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

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
          if (index != 1) _selectedReviewInvoice = null;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
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
                          const Color(0xFFFFF0E6).withValues(alpha: 0.45),
                        ],
                      ),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFFFBED7).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.8),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? const Color(0xFF6A1634).withValues(alpha: 0.35)
                        : const Color(0xFFC86E46).withValues(alpha: 0.12),
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
                        constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
                        child: Text(
                          '$badgeCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            // Label in DM Sans Size 11
            Text(
              label,
              style: AppTypography.fontS(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.brandInk : AppColors.mutedText,
              ).copyWith(fontSize: 10.5, height: 1.1),
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
    );
  }
}
