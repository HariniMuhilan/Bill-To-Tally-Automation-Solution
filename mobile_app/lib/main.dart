import 'package:flutter/material.dart';
import 'models/user_session.dart';
import 'services/api_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'widgets/laptop_mobile_frame.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.init();
  final api = ApiService(storage);

  runApp(BillToTallyApp(storage: storage, api: api));
}

class BillToTallyApp extends StatefulWidget {
  final StorageService storage;
  final ApiService api;

  const BillToTallyApp({
    super.key,
    required this.storage,
    required this.api,
  });

  @override
  State<BillToTallyApp> createState() => _BillToTallyAppState();
}

class _BillToTallyAppState extends State<BillToTallyApp> {
  UserSession? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = widget.storage.getUser();
  }

  void _handleLoginSuccess(UserSession user) {
    setState(() => _currentUser = user);
  }

  void _handleLogout() {
    widget.storage.saveUser(null);
    setState(() => _currentUser = null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bill to Tally Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      builder: (context, child) {
        return LaptopMobileFrame(
          child: child ?? const SizedBox(),
        );
      },
      home: _currentUser == null
          ? LoginScreen(
              storage: widget.storage,
              onLoginSuccess: _handleLoginSuccess,
            )
          : HomeShell(
              storage: widget.storage,
              api: widget.api,
              user: _currentUser!,
              onLogout: _handleLogout,
            ),
    );
  }
}
