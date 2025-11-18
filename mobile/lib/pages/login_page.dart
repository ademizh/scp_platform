
import 'package:flutter/material.dart';
import 'package:mobile/components/button.dart';
import 'package:mobile/components/text_field.dart';
import 'package:mobile/services/api_client.dart';
import 'package:mobile/services/session.dart';
import 'package:mobile/pages/home_page.dart';
import 'package:mobile/pages/register_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  final Function()? onTap;
  const LoginPage({super.key, required this.onTap});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool _isLoading = false;
  String? _error;

  // true = supplier, false = consumer
  bool _isSupplier = true;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final loginAs = _isSupplier ? 'supplier' : 'consumer';

      
      final result = await ApiClient.instance.login(
        emailController.text.trim(),
        passwordController.text,
        loginAs: loginAs, 
      );

      
      await SessionService.instance.saveLogin(result);

      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('role', loginAs);
      await prefs.setBool('isLoggedIn', true);

      
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MyTextField(
                controller: emailController,
                hintText: 'Email',
                obscureText: false,
              ),
              const SizedBox(height: 12),
              MyTextField(
                controller: passwordController,
                hintText: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 16),

              
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Supplier'),
                      value: true,
                      groupValue: _isSupplier,
                      onChanged: (v) {
                        setState(() {
                          _isSupplier = v ?? true;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Consumer'),
                      value: false,
                      groupValue: _isSupplier,
                      onChanged: (v) {
                        setState(() {
                          _isSupplier = v ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              const SizedBox(height: 16),
              MyButton(
                text: _isLoading ? 'Loading...' : 'Login',
                onTap: _isLoading ? null : _login,
              ),
              const SizedBox(height: 8),

              
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RegisterPage(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                },
                child: const Text(
                  'New here? Register',
                  style: TextStyle(
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
