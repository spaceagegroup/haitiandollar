import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/wallet_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/kiosk_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ChangeNotifierProvider(
      create: (_) => WalletState()..refreshRates(),
      child: const HtdApp(),
    ),
  );
}

class HtdApp extends StatelessWidget {
  const HtdApp({super.key});

  @override
  Widget build(BuildContext context) {
    final mode = context.select<WalletState, AppMode>((w) => w.mode);

    return MaterialApp(
      title: 'Haitian Dollar Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        fontFamily: 'sans-serif',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFCC419),
          secondary: Color(0xFFE03131),
          surface: Color(0xFF141414),
        ),
      ),
      home: mode == AppMode.consumer
          ? const DashboardScreen()
          : const KioskScreen(),
    );
  }
}
