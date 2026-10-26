import 'package:flutter/material.dart';
import '../models/mapping.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class MappingsScreen extends StatefulWidget {
  final StorageService storage;
  final List<MasterMapping> mappings;
  final ValueChanged<List<MasterMapping>> onMappingsChanged;

  const MappingsScreen({
    super.key,
    required this.storage,
    required this.mappings,
    required this.onMappingsChanged,
  });

  @override
  State<MappingsScreen> createState() => _MappingsScreenState();
}

class _MappingsScreenState extends State<MappingsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  void _showAddMappingDialog() {
    final rawController = TextEditingController();
    final tallyController = TextEditingController();
    String category = 'Purchase Accounts';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceWhite,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Add Master Mapping',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.amazonNavy),
              ),
              const SizedBox(height: 14),

              const Text('Raw OCR Text', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: rawController,
                decoration: InputDecoration(
                  hintText: 'e.g. GST Purchase 18%',
                  filled: true,
                  fillColor: AppColors.appleBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Tally Master Ledger', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: tallyController,
                decoration: InputDecoration(
                  hintText: 'e.g. Purchase - GST 18%',
                  filled: true,
                  fillColor: AppColors.appleBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),

              const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: category,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.appleBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
                items: const [
                  DropdownMenuItem(value: 'Purchase Accounts', child: Text('Purchase Accounts')),
                  DropdownMenuItem(value: 'Sundry Creditors', child: Text('Sundry Creditors')),
                  DropdownMenuItem(value: 'Duties & Taxes', child: Text('Duties & Taxes')),
                  DropdownMenuItem(value: 'Indirect Expenses', child: Text('Indirect Expenses')),
                  DropdownMenuItem(value: 'Units', child: Text('Units / Measures')),
                ],
                onChanged: (val) => setModalState(() => category = val ?? 'Purchase Accounts'),
              ),
              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  if (rawController.text.trim().isEmpty || tallyController.text.trim().isEmpty) {
                    return;
                  }
                  final newMapping = MasterMapping(
                    id: 'MAP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    raw: rawController.text.trim(),
                    tally: tallyController.text.trim(),
                    category: category,
                    status: 'VERIFIED',
                    date: DateTime.now().toString().substring(0, 10),
                  );
                  final updated = [newMapping, ...widget.mappings];
                  widget.onMappingsChanged(updated);
                  widget.storage.saveMappings(updated);
                  Navigator.pop(ctx);
                },
                child: const Text('Save Mapping'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.mappings.where((m) {
      final matchesSearch = m.raw.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.tally.toLowerCase().contains(_searchQuery.toLowerCase());
      if (_selectedCategory == 'ALL') return matchesSearch;
      return matchesSearch && m.category == _selectedCategory;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.blushIvory,
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppColors.surfaceWhite,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search raw pattern or Tally ledger...',
                    prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.blushIvory,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: AppColors.borderSubtle),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCatChip('ALL', 'All Mappings (${widget.mappings.length})'),
                      const SizedBox(width: 6),
                      _buildCatChip('Purchase Accounts', 'Purchase'),
                      const SizedBox(width: 6),
                      _buildCatChip('Duties & Taxes', 'Taxes'),
                      const SizedBox(width: 6),
                      _buildCatChip('Indirect Expenses', 'Expenses'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Mappings List
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No mappings found.', style: TextStyle(color: AppColors.textMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, idx) {
                      final m = filtered[idx];
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.mauveBg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      m.category,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.plumSlate),
                                    ),
                                  ),
                                  Text(
                                    m.id,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.receipt_outlined, size: 16, color: AppColors.mutedMauve),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Raw OCR String', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        Text(m.raw, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.inkNavy)),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.link_rounded, size: 16, color: AppColors.softSage),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Tally Master Ledger', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
                                        Text(
                                          m.tally,
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: AppColors.inkNavy),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMappingDialog,
        backgroundColor: AppColors.plumSlate,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Mapping', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildCatChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return ChoiceChip(
      avatar: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _selectedCategory = value);
      },
      selectedColor: AppColors.plumSlate,
      backgroundColor: AppColors.surfaceWhite,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.inkNavy,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 11,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.plumSlate : AppColors.borderSubtle,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }
}
