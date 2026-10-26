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
import 'mappings_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    final needsReviewCount = _invoices.where((i) => i.status == 'NEEDS_REVIEW').length;

    // Build Current Body
    Widget body;
    String title;

    switch (_currentIndex) {
      case 0:
        title = 'Invoice Inbox';
        body = InboxScreen(
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
                    'Go to Inbox and tap "Review"\non any bill.',
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
        title = 'Master Mappings';
        body = MappingsScreen(
          storage: widget.storage,
          mappings: _mappings,
          onMappingsChanged: (updated) => setState(() => _mappings = updated),
        );
        break;
      case 3:
        title = 'Tally Connector';
        body = TallyConnectorScreen(
          storage: widget.storage,
          api: widget.api,
          draftSheets: _draftSheets,
          onDraftSheetsChanged: (updated) => setState(() => _draftSheets = updated),
        );
        break;
      case 4:
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
      backgroundColor: AppColors.blushIvory,
      appBar: AppBar(
        backgroundColor: AppColors.inkNavy,
        foregroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.accentOrange, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17, color: Colors.white)),
          ],
        ),
        actions: [
          // Safety Mode Pill
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.shield_outlined, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  widget.storage.postingEnabled ? 'LIVE' : 'TEST',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // User Profile Initials Avatar
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: CircleAvatar(
              backgroundColor: AppColors.accentOrange,
              radius: 14,
              child: Text(
                widget.user.initials,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
      body: body,
      bottomNavigationBar: _buildMockupBottomNav(needsReviewCount),
    );
  }

  Widget _buildMockupBottomNav(int needsReviewCount) {
    final navItems = [
      (Icons.all_inbox_rounded, 'Inbox'),
      (Icons.fact_check_rounded, 'Review'),
      (Icons.alt_route_rounded, 'Mappings'),
      (Icons.electrical_services_rounded, 'Tally'),
      (Icons.more_horiz_rounded, 'More'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceWhite,
        border: Border(top: BorderSide(color: AppColors.borderSubtle, width: 1)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(navItems.length, (index) {
            final isSelected = _currentIndex == index;
            final (iconData, label) = navItems[index];

            return InkWell(
              onTap: () => setState(() => _currentIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.plumSlate : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Badge(
                        isLabelVisible: index == 0 && needsReviewCount > 0,
                        label: Text('$needsReviewCount'),
                        backgroundColor: AppColors.accentOrange,
                        child: Icon(
                          iconData,
                          size: 20,
                          color: isSelected ? Colors.white : AppColors.mutedMauve,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? AppColors.plumSlate : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
