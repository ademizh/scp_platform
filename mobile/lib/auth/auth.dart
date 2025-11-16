import 'package:flutter/material.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/auth/log_or_reg.dart';
import 'package:mobile/services/session.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  Future<bool> _hasSession() async {
    final userId = await SessionService.instance.getUserId();
    return userId != null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSession(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final loggedIn = snapshot.data!;
        if (loggedIn) {
          return const HomePage();
        } else {
          return const LoginOrRegister();
        }
      },
    );
  }
}
