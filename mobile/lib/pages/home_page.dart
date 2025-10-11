import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SCP"), 
        backgroundColor: Colors.blueGrey,
        actions: [

          IconButton(
            onPressed: () {
              // This is a placeholder function.
              // It does nothing for now, but allows the button to be pressed.
              // Later, you will add the Supabase signOut() logic here.
              print('Logout button tapped!');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Welcome to your home page!',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}