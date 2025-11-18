import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/auth/auth.dart'; // 👈 from SCP platform
import 'package:mobile/screens/tabs.dart';
import 'package:mobile/services/session.dart';

final theme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    brightness: Brightness.dark,
    seedColor: const Color.fromARGB(255, 131, 57, 0),
  ),
);

void main() {
  runApp(const ProviderScope(child: App()));
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: theme,
      debugShowCheckedModeBanner: false,
      home: const RootPage(), // 👈 chooses between login or home
    );
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});

  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  bool _isLoggedIn = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

Future<void> _checkSession() async {
  final session = SessionService.instance; 
  final userId = await session.getUserId();
  setState(() {
    _isLoggedIn = userId != null; // user is logged in if userId exists
    _loading = false;
  });
}


  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 👇 if user logged in → show Meals home, else show Login/Register
    return _isLoggedIn ? const Tabs() : const AuthPage();
  }
}