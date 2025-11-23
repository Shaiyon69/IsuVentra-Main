import "package:flutter/material.dart";
import '../services/auth_service.dart';
import '../app_providers_wrapper.dart';
import '../services/api_service.dart';
// import 'register.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final AuthService _authService = AuthService();
  TextEditingController txtEmail = TextEditingController();
  TextEditingController txtPassword = TextEditingController();
  bool isLoading = false;

  void login() async {
    String email = txtEmail.text.trim();
    String password = txtPassword.text.trim();

    setState(() {
      isLoading = true;
    });

    final loginData = await _authService.login(email, password);

    if (!mounted) return;

    setState(() {
      isLoading = false;
    });

    if (loginData != null) {
      if (loginData['token'] != null) {
        ApiService().setToken(loginData['token']);
      }
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AppProvidersWrapper()),
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid email or password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login Page")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: txtEmail,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              enabled: !isLoading,
            ),
            const SizedBox(height: 10),
            TextField(
              controller: txtPassword,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              enabled: !isLoading,
            ),
            const SizedBox(height: 20),
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: login, child: const Text("Login")),
            const SizedBox(height: 10),
            // TextButton(
            //   onPressed: () {
            //     Navigator.pushReplacement(
            //       context,
            //       MaterialPageRoute(builder: (context) => const Register()),
            //     );
            //   },
            //   child: const Text("Don't have an account? Register"),
            // ),
          ],
        ),
      ),
    );
  }
}
