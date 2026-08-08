import 'package:flutter/material.dart';

import 'constants/app_theme.dart';
import 'logic/ad_service.dart';
import 'logic/game_state.dart';
import 'logic/premium_service.dart';
import 'logic/role_overrides_store.dart';
import 'screens/intro_poster_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Needed before first use of RoleData, since role lookups apply any
  // saved overrides synchronously.
  await RoleOverridesStore.loadIntoCache();
  // Needed before the player-count screen can decide whether to show
  // the paywall (see PremiumService).
  await PremiumService.loadIsPremium();
  // Fire-and-forget: if there's no internet, this just never finishes
  // initializing and ads silently never show. Nothing else in the app
  // waits on it.
  AdService.initialize();
  runApp(const MafiaRolesApp());
}

/// Root widget.
///
/// A single [GameState] instance is created once here and threaded down
/// through the screens. There is no database and no accounts anywhere in
/// the app - role assignments live purely in memory until "End Game"
/// clears them. The only network use anywhere is the optional ads.
class MafiaRolesApp extends StatelessWidget {
  const MafiaRolesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final gameState = GameState();

    return MaterialApp(
      title: 'Mafia Roles',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      locale: const Locale('fa'),
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child!,
        );
      },
      home: IntroPosterScreen(gameState: gameState),
    );
  }
}
