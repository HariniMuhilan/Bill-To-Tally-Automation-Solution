import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'liquid_glass.dart';

class ServerSettingsDialog extends StatefulWidget {
  final StorageService storage;
  final ApiService api;
  final VoidCallback? onSaved;

  const ServerSettingsDialog({
    super.key,
    required this.storage,
    required this.api,
    this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required StorageService storage,
    required ApiService api,
    VoidCallback? onSaved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ServerSettingsDialog(
        storage: storage,
        api: api,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<ServerSettingsDialog> createState() => _ServerSettingsDialogState();
}

class _ServerSettingsDialogState extends State<ServerSettingsDialog> {
  late final TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: widget.storage.apiBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    await widget.storage.setApiBaseUrl(url);
    final health = await widget.api.checkSystemHealth();

    setState(() {
      _isTesting = false;
      if (health['status'] == 'healthy' || health['status'] == 'ok' || health.containsKey('status')) {
        _testSuccess = true;
        _testResult = 'Connected successfully! Backend is online.';
      } else {
        _testSuccess = false;
        _testResult = 'Connection failed: ${health['error'] ?? 'Unreachable'}';
      }
    });
  }

  Future<void> _save() async {
    final url = _urlController.text.trim();
    if (url.isNotEmpty) {
      await widget.storage.setApiBaseUrl(url);
      widget.onSaved?.call();
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: LiquidGlass(
        borderRadius: 24,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.maroonDark.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.cloud_sync_rounded, color: AppColors.maroonDark, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Backend Server URL',
                    style: AppTypography.fontL(color: AppColors.brandInk, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Enter your local IP (e.g. http://192.168.29.57:8000) or your deployed cloud URL (e.g. https://xxx.up.railway.app):',
              style: AppTypography.fontS(color: AppColors.brandInk.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.8),
                hintText: 'http://192.168.29.57:8000',
                hintStyle: AppTypography.fontM(color: AppColors.brandInk.withValues(alpha: 0.4)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.maroonDark.withValues(alpha: 0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: AppColors.maroonDark.withValues(alpha: 0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.orange, width: 2),
                ),
              ),
              style: AppTypography.fontM(color: AppColors.brandInk),
            ),
            if (_testResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _testSuccess ? AppColors.successGreen.withValues(alpha: 0.12) : AppColors.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                      color: _testSuccess ? AppColors.successGreen : AppColors.errorRed,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testResult!,
                        style: AppTypography.fontS(
                          color: _testSuccess ? AppColors.successGreen : AppColors.errorRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isTesting ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: BorderSide(color: AppColors.maroonDark.withValues(alpha: 0.3)),
                    ),
                    child: _isTesting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text('Test', style: AppTypography.fontM(color: AppColors.maroonDark, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text('Save', style: AppTypography.fontM(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
