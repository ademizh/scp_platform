// lib/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mobile/pages/login_page.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/pages/consumer_homepage.dart';
import 'package:mobile/pages/supplier_homepage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _initialLoading = true;
  String? _initError;

  int? _userId;
  String? _loginRole; // 'consumer' or 'supplier'

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final userId = await SessionService.instance.getUserId();
      
      if (userId == null) {
        _goToLogin();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      String? loginRole = prefs.getString('role');

      final roles = await SessionService.instance.getRoles();
      if (loginRole == null) {
        if (roles.contains('consumer')) {
          loginRole = 'consumer';
        } else if (roles.contains('sales')) {
          loginRole = 'sales';
        }
      }

      if (!mounted) return;
      setState(() {
        _userId = userId;
        _loginRole = loginRole ?? 'consumer';
        _initialLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _initError = e.toString();
        _initialLoading = false;
      });
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginPage(onTap: () {}),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_initialLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('SCP')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Initialization error:\n$_initError',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (_userId == null) {

      _goToLogin();
      return const SizedBox.shrink();
    }

    if (_loginRole == 'sales') {
      return SupplierHomePage(userId: _userId!);
    }


    return ConsumerHomePage(userId: _userId!);
  }
}
