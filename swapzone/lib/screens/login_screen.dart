import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../services/api_service.dart';
import '../models/user_model.dart';
import 'signup_screen.dart';
import 'forgetpassword_screen.dart';
import 'adminside/admin_screen.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;

  void _showPopupDialog(String message, Color bgColor) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 50, color: Colors.white),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                const CircularProgressIndicator(color: Colors.white),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleLogin() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showPopupDialog("⚠️ Please fill in both email and password.", Colors.orange);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
      return;
    }

    setState(() {
      isLoading = true;
    });

    final result = await ApiService.login(email, password);

    setState(() {
      isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      final user = result['user'] as UserModel;

      String message = '';
      Color color = Colors.green;

      if (user.role == 'admin') {
        message = "👑 Welcome Admin ${user.name}";
      } else if (user.role == 'user') {
        message = "👋 Welcome ${user.name}";
      } else {
        message = "⚠️ Unknown role: ${user.role}";
        color = Colors.orange;
      }

      _showPopupDialog(message, color);

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);

      if (user.role == 'admin') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
      } else if (user.role == 'user') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      }
    } else {
      _showPopupDialog("❌ ${result['message']}", Colors.red);
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _handleGoogleLogin() async {
    try {
      print("🔵 Starting Google login...");

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: '',
        scopes: ['email', 'profile'],
      );

      print("🔵 Calling googleSignIn.signIn()...");
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print("🟡 User canceled Google login.");
        return;
      }

      print("✅ Google user selected: ${googleUser.email}, name: ${googleUser.displayName}");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      print("🔵 Fetched Google Auth object.");

      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      print("🟢 idToken: ${idToken != null ? idToken.substring(0, 20) + '...' : 'NULL'}");
      print("🟢 accessToken: ${accessToken != null ? accessToken.substring(0, 20) + '...' : 'NULL'}");

      if (idToken == null) {
        _showPopupDialog("⚠️ Google login failed (no idToken)", Colors.red);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
        return;
      }

      print("🔵 Sending idToken to backend API...");
      final response = await ApiService.googleLogin(idToken);
      print("🟢 Backend response: $response");

      if (response['success'] == true) {
        final userData = response['data'] ?? response['user'] ?? {};
        // check token presence
        final token = userData['token'] ?? userData['jwt'] ?? response['token'] ?? response['data']?['token'];
        if (token == null) {
          print("❌ No token returned from backend");
          _showPopupDialog("❌ Login failed: missing token", Colors.red);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
          return;
        }

        // store to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("token", token.toString());
        if (userData['role'] != null) await prefs.setString("role", userData['role'].toString());
        if (userData['name'] != null) await prefs.setString("name", userData['name'].toString());
        if (userData['email'] != null) await prefs.setString("email", userData['email'].toString());
        if (userData['userId'] != null) await prefs.setString("userId", userData['userId'].toString());
        if (userData['profileImage'] != null) await prefs.setString("profileImage", userData['profileImage'].toString());

        print("✅ Stored user data in SharedPreferences.");

        // build message and navigate
        final role = userData['role']?.toString() ?? 'user';
        final name = userData['name']?.toString() ?? 'User';
        String message = role == 'admin' ? "👑 Welcome Admin $name" : "👋 Welcome $name";

        _showPopupDialog(message, Colors.green);
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pop(context);

        if (role == 'admin') {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomePage()));
        } else {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      } else {
        print("❌ Backend rejected Google login: ${response['message']}");
        _showPopupDialog("❌ ${response['message'] ?? 'Google login failed'}", Colors.red);
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      }
    } catch (e, stack) {
      print("❌ Exception during Google login: $e");
      print("📌 Stack trace: $stack");
      _showPopupDialog("❌ Error: $e", Colors.red);
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFFFFA726)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 500;
                return Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    width: isWide ? 400 : double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.login_rounded, size: 80, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'Welcome to SwapZone',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Google Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _handleGoogleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            icon: Image.asset("assets/images/googlemain.png", height: 24),
                            label: const Text(
                              "Sign in with Google",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email, color: Colors.white70),
                            labelText: 'Email',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        TextField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock, color: Colors.white70),
                            labelText: 'Password',
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ForgetPasswordPage(),
                                ),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.deepOrangeAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: isLoading
                                ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation(Colors.deepOrangeAccent),
                            )
                                : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Signup Link
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupPage()),
                            );
                          },
                          child: const Text(
                            "Don't have an account? Sign Up",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
