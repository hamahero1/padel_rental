import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'models/app_user.dart';
import 'screens/auth/login_screen.dart';
import 'screens/owner/owner_home_screen.dart';
import 'screens/player/player_home_screen.dart';
import 'services/auth_service.dart';

void main() async {
  // Needed before using any plugin (Firebase) in main()
  WidgetsFlutterBinding.ensureInitialized();
  // Reads android/app/google-services.json (same setup as Lab 3)
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Padel Rental',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
        inputDecorationTheme:
            const InputDecorationTheme(border: OutlineInputBorder()),
      ),
      home: const StartScreen(),
    );
  }
}

/// Opens the right first screen when the app starts:
/// - "Remember me" was ticked -> straight to the player/owner home
/// - otherwise -> login screen
class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  // Created once, so rebuilding the screen doesn't log in again
  final Future<AppUser?> _autoLogin = AuthService.autoLogin();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: _autoLogin,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return homeFor(user);
      },
    );
  }
}

/// Owners and players see different home screens.
Widget homeFor(AppUser user) {
  return user.isOwner
      ? OwnerHomeScreen(user: user)
      : PlayerHomeScreen(user: user);
}
