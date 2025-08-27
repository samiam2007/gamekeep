import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/game_provider.dart';
import 'providers/user_provider.dart';
import 'services/auth_service.dart';
import 'screens/home_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        home: const HomeScreen(),
      ),
    );
  }
}