import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../models/draft_sheet.dart';
import '../models/mapping.dart';
import '../models/user_session.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import 'inbox_screen.dart';
import 'review_screen.dart';
import 'tally_connector_screen.dart';
import 'audit_trail_screen.dart';
import 'settings_screen.dart';

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
      if (_invoices.isNotEmpty) {
        _selectedReviewInvoice = _invoices.first;
      }
    });
  }

  void _selectInvoiceForReview(Invoice inv) {
    setState(() {
      _selectedReviewInvoice = inv;
      _currentIndex = 1; // Switch to Review tab
    });
  }

  void _handleQuickCameraCapture() {
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

    // Build Current Body
    Widget body;
    String title;

    switch (_currentIndex) {
      case 0:
        title = 'Invoice Inbox';
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
        title = 'Review & Validate';
        if (_selectedReviewInvoice == null) {
          body = Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: AppColors.mauveBg,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Icon(Icons.touch_app_rounded, size: 40, color: AppColors.mutedMauve),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'No Invoice Selected\nfor Review',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.inkNavy,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Go to Inbox and tap "Review Now"\non any bill.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 22),
                  ElevatedButton.icon(
                    onPressed: () => setState(() => _currentIndex = 0),
                    icon: const Icon(Icons.all_inbox_rounded, size: 18),
                    label: const Text('Go to Inbox'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.plumSlate,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            draftSheets: _draftSheets,
            mappings: _mappings,
            onInvoiceUpdated: (updated) {
              final idx = _invoices.indexWhere((i) => i.id == updated.id);
              if (idx >= 0) {
                final list = List<Invoice>.from(_invoices);
                list[idx] = updated;
                setState(() {
                  _invoices = list;
                  _selectedReviewInvoice = updated;
                });
                widget.storage.saveInvoices(list);
              }
            },
            onDraftSheetsUpdated: (drafts) {
              setState(() => _draftSheets = drafts);
            },
            onBack: () => setState(() => _currentIndex = 0),
          );
        }
        break;
      case 2:
        title = 'Tally Connector';
        body = TallyConnectorScreen(
          storage: widget.storage,
          api: widget.api,
          draftSheets: _draftSheets,
          onDraftSheetsChanged: (updated) => setState(() => _draftSheets = updated),
        );
        break;
      case 3:
        title = 'Audit & Settings';
        body = DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: AppColors.surfaceWhite,
                child: const TabBar(
                  labelColor: AppColors.plumSlate,
                  unselectedLabelColor: AppColors.textMuted,
                  indicatorColor: AppColors.plumSlate,
                  tabs: [
                    Tab(icon: Icon(Icons.history), text: 'Audit Trail'),
                    Tab(icon: Icon(Icons.settings), text: 'Settings'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    AuditTrailScreen(storage: widget.storage),
                    SettingsScreen(storage: widget.storage, onLogout: widget.onLogout),
                  ],
                ),
              ),
            ],
          ),
        );
        break;
      default:
        title = 'Bill to Tally';
        body = const SizedBox();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F8),
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.receipt_long_rounded, color: Color(0xFFF59E0B), size: 22),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: Colors.white),
            ),
          ],
        ),
        actions: [
          // TEST Shield Pill matching reference mockup
          Container(
            margin: const EdgeInsets.symmetric(vertical: 13),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  'TEST',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // User Profile Initials Avatar (Soft Sage)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: AppColors.softSage,
              radius: 14,
              child: Text(
                widget.user.initials,
                style: const TextStyle(
                  color: AppColors.inkNavy,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: _buildPoppedOutCameraBottomNav(needsReviewCount),
    );
  }

  Widget _buildPoppedOutCameraBottomNav(int needsReviewCount) {
    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              // Navigation Bar Base
              Container(
                height: 68,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceWhite,
                  border: Border(top: BorderSide(color: Color(0xFFE8E0E5), width: 1)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 10,
                      offset: Offset(0, -3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Item 0: Inbox
                    Expanded(
                      child: _buildNavTab(
                        index: 0,
                        icon: Icons.all_inbox_rounded,
                        label: 'Inbox',
                        showActiveUnderline: true,
                      ),
                    ),
                    // Item 1: Review
                    Expanded(
                      child: _buildNavTab(
                        index: 1,
                        icon: Icons.assignment_turned_in_outlined,
                        label: 'Review',
                        badgeCount: needsReviewCount,
                        isAlertBadge: true,
                      ),
                    ),
                    // Center Spacer for Popped Out Camera Button
                    const SizedBox(width: 72),
                    // Item 2: Tally
                    Expanded(
                      child: _buildNavTab(
                        index: 2,
                        icon: Icons.sync_rounded,
                        label: 'Tally',
                      ),
                    ),
                    // Item 3: More
                    Expanded(
                      child: _buildNavTab(
                        index: 3,
                        icon: Icons.settings_outlined,
                        label: 'More',
                      ),
                    ),
                  ],
                ),
              ),

              // Popped Out Center Camera Action Button matching reference mockup
              Positioned(
                top: -20,
                child: GestureDetector(
                  onTap: _handleQuickCameraCapture,
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF487E64), // Fresh eucalyptus jade
                      border: Border.all(color: const Color(0xFF68A484), width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF487E64).withOpacity(0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
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

  Widget _buildNavTab({
    required int index,
    required IconData icon,
    required String label,
    int? badgeCount,
    bool isAlertBadge = false,
    bool showActiveUnderline = false,
  }) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount != null && badgeCount > 0,
              label: Text(
                '$badgeCount',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              backgroundColor: isAlertBadge ? const Color(0xFFE11D48) : AppColors.plumSlate,
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? AppColors.plumSlate : const Color(0xFF7E757D),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.plumSlate : const Color(0xFF7E757D),
              ),
            ),
            if (isSelected && showActiveUnderline)
              Container(
                margin: const EdgeInsets.only(top: 2),
                width: 22,
                height: 2,
                decoration: BoxDecoration(
                  color: AppColors.plumSlate,
                  borderRadius: BorderRadius.circular(1),
                ),
              )
            else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}
