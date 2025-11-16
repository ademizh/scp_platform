import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/pages/login_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  
  Future<String?> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role'); 
  }


  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('role');
    await prefs.remove('isLoggedIn');
    await prefs.remove('userId');
    await prefs.remove('supplierId');
    await prefs.remove('consumerId');
    await prefs.remove('accessToken');
    await prefs.remove('refreshToken');

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(onTap: () {}),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SCP'),
        backgroundColor: Colors.blueGrey,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: FutureBuilder<String?>(
        future: _loadRole(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final role = snapshot.data;

          if (role == 'supplier') {
            return _buildSupplierHome();
          } else if (role == 'consumer') {
            return _buildConsumerHome();
          } else {
            return const Center(
              child: Text(
                'Role not found. Please login again.',
                textAlign: TextAlign.center,
              ),
            );
          }
        },
      ),
    );
  }

  // -------- supplier home --------
  Widget _buildSupplierHome() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supplier Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('Here you will later add:'),
          SizedBox(height: 8),
          Text('• Manage products'),
          Text('• View incoming orders'),
          Text('• Manage supplier staff, etc.'),
        ],
      ),
    );
  }

  // -------- consumer home --------
  Widget _buildConsumerHome() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consumer Home Page',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Text('Here you will later add:'),
          SizedBox(height: 8),
          Text('• Browse suppliers/products'),
          Text('• Place orders'),
          Text('• Track order status'),
        ],
      ),
    );
  }
}
