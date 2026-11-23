import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const LapticonApp());
}

class LapticonApp extends StatelessWidget {
  const LapticonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lapticon',
      debugShowCheckedModeBanner: false,
      theme: construirTema(),
      home: const AuthGate(),
    );
  }
}

/// Muestra el login o la app según haya sesión de Firebase.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(
              child: Image.asset('assets/icon/logo.png', width: 110),
            ),
          );
        }
        return snap.data == null ? const LoginScreen() : const HomeScreen();
      },
    );
  }
}
