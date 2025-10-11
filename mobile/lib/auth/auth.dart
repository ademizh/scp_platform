import 'package:flutter/material.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/auth/log_or_reg.dart';
//  When ready, import the Supabase package
// import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // ===================================================================
        //  SUPABASE AUTHENTICATION STREAM HERE
        //
        // This StreamBuilder will listen for login/logout events.
        // For now, we are returning 'LoginOrRegister()' directly to allow
        // UI development without a database connection.
        //
        // When you're ready to connect to Supabase, you will replace
        // the 'return LoginOrRegister();' line with the commented-out
        // StreamBuilder block below.
        // ===================================================================

        child: LoginOrRegister(), // <-- CURRENTLY shows the login page by default.

        /*
        // --- UNCOMMENT THIS BLOCK TO ENABLE SUPABASE AUTHENTICATION ---
        child: StreamBuilder<AuthState>(
          stream: Supabase.instance.client.auth.onAuthStateChange,
          builder: (context, snapshot) {
            // Show a loading indicator while connecting
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            // User is logged in if there is an active session
            if (snapshot.hasData && snapshot.data?.session != null) {
              return const HomePage();
            }
            
            // User is NOT logged in
            else {
              return const LoginOrRegister();
            }
          },
        ),
        */
      ),
    );
  }
}