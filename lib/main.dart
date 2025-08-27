import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'services/auth_service.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase - commented out for demo
  // await Firebase.initializeApp();
  
  // Initialize Mobile Ads - commented out for demo
  // MobileAds.instance.initialize();
  
  runApp(const GameKeepApp());
}

class GameKeepApp extends StatelessWidget {
  const GameKeepApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<GameProvider>(
          create: (context) => GameProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'GameKeep',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // DEMO MODE - Skip authentication for UI preview
    return const HomeScreen();
    
    // Original auth flow commented for demo
    // final authService = context.read<AuthService>();
    // 
    // return StreamBuilder(
    //   stream: authService.authStateChanges,
    //   builder: (context, snapshot) {
    //     if (snapshot.connectionState == ConnectionState.waiting) {
    //       return const SplashScreen();
    //     }
    //     
    //     if (snapshot.hasData) {
    //       return const HomeScreen();
    //     }
    //     
    //     return const LoginScreen();
    //   },
    // );
  }
}