import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.storage,
    required this.onLogout,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _apiBaseController;
  late TextEditingController _tallyHostController;
  late TextEditingController _tallyPortController;
  late TextEditingController _companyController;
  late bool _postingEnabled;

  @override
  void initState() {
    super.initState();
    _apiBaseController = TextEditingController(text: widget.storage.apiBaseUrl);
    _tallyHostController = TextEditingController(text: widget.storage.tallyHost);
    _tallyPortController = TextEditingController(text: widget.storage.tallyPort.toString());
    _companyController = TextEditingController(text: widget.storage.tallyCompany);
    _postingEnabled = widget.storage.postingEnabled;
  }

  @override
  void dispose() {
    _apiBaseController.dispose();
    _tallyHostController.dispose();
    _tallyPortController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    widget.storage.setApiBaseUrl(_apiBaseController.text.trim());
    widget.storage.setTallyHost(_tallyHostController.text.trim());
    widget.storage.setTallyPort(int.tryParse(_tallyPortController.text.trim()) ?? 9000);
    widget.storage.setTallyCompany(_companyController.text.trim());
    widget.storage.setPostingEnabled(_postingEnabled);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuration saved successfully!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.storage.getUser();

    return Scaffold(
      backgroundColor: AppColors.blushIvory,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current User Profile Card
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.inkNavy,
                    radius: 24,
                    child: Text(
                      user?.initials ?? 'AU',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Accounts User',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.inkNavy),
                        ),
                        Text(
                          '${user?.username} • ${user?.role}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: widget.onLogout,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.errorRed,
                      side: const BorderSide(color: AppColors.errorRed),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Log Out'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Backend API Configuration
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FastAPI Backend Server URL',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.inkNavy),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Use LAN IP (e.g. 192.168.1.X:8000) or Cloud URL for mobile phone access',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _apiBaseController,
                    decoration: InputDecoration(
                      hintText: 'http://127.0.0.1:8000',
                      filled: true,
                      fillColor: AppColors.blushIvory,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // TallyPrime Parameters
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tally Connection Settings',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.inkNavy),
                  ),
                  const SizedBox(height: 12),
                  const Text('Company Name', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.blushIvory,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Tally Host IP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _tallyHostController,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.blushIvory,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Port', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _tallyPortController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.blushIvory,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Live XML Posting (POSTING_ENABLED)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    subtitle: const Text('When disabled, safe test mode operates without mutating live accounts', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    value: _postingEnabled,
                    activeColor: AppColors.accentOrange,
                    onChanged: (val) => setState(() => _postingEnabled = val),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save Button
          ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.plumSlate,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Save Configuration'),
          ),
        ],
      ),
    );
  }
}
