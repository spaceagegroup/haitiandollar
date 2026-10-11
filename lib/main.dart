import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'models/wallet_state.dart';
import 'screens/dashboard_screen.dart';
import 'screens/kiosk_screen.dart';
import 'theme/htd_theme.dart';

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

class HtdApp extends StatefulWidget {
  const HtdApp({super.key});

  @override
  State<HtdApp> createState() => _HtdAppState();
}

class _HtdAppState extends State<HtdApp> with WidgetsBindingObserver {
  Timer? _rateRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Periodically refresh rates while app is active (every 15 minutes)
    _rateRefreshTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      if (mounted) {
        context.read<WalletState>().refreshRates();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _rateRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      // Whenever the user returns to the app from the background or unlocks their phone,
      // refresh rates to mirror the web's live updates.
      context.read<WalletState>().refreshRates();
    }
  }

  @override
  Widget build(BuildContext context) {
    final mode = context.select<WalletState, AppMode>((w) => w.mode);
    final isOutdoor = context.select<WalletState, bool>((w) => w.isOutdoorMode);

    return MaterialApp(
      title: 'Haitian Dollar Wallet',
      debugShowCheckedModeBanner: false,
      themeMode: isOutdoor ? ThemeMode.light : ThemeMode.dark,
      theme: buildSunTheme(),
      darkTheme: buildNightTheme(),
      home: mode == AppMode.consumer
          ? const DashboardScreen()
          : const KioskScreen(),
    );
  }
}
