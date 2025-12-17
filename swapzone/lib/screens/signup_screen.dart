import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phonenoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  void _handleSignup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneno = _phonenoController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    //  Name validation (only letters & spaces)
    if (name.isEmpty || !RegExp(r"^[a-zA-Z\s]+$").hasMatch(name)) {
      _showSnackBar('Full name must contain only letters');
      return;
    }

    //  Email validation
    if (email.isEmpty || !RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(email)) {
      _showSnackBar('Enter a valid email address');
      return;
    }

    //  Phone validation (10 digits only)
    if (phoneno.isEmpty || !RegExp(r"^\d{10}$").hasMatch(phoneno)) {
      _showSnackBar('Phone number must be exactly 10 digits');
      return;
    }

    //  Password validation
    if (password.isEmpty || confirmPassword.isEmpty) {
      _showSnackBar('Password fields cannot be empty');
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar('Passwords do not match');
      return;
    }

    //  If all validations pass, call API
    setState(() => _isLoading = true);
    final result = await ApiService.signupUser(name, email, phoneno, password);
    setState(() => _isLoading = false);

    if (result['success']) {
      _showPopupDialog("✅ Signup Successful!", Colors.green);

      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      }
    } else {
      _showPopupDialog(result['message'] ?? " Signup Failed!", Colors.red);

      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) {
        Navigator.pop(context); // Close the dialog
      }
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showPopupDialog(String message, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: color.withOpacity(0.9),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.error,
              color: Colors.white,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              "Please wait...",
              style: TextStyle(color: Colors.white70),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      IconData icon,
      String label, {
        bool isPassword = false,
        TextInputType inputType = TextInputType.text,
        required TextEditingController controller,
      }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00C9A7), Color(0xFFFFA726)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                color: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.person_add_alt_1, size: 80, color: Colors.white),
                      const SizedBox(height: 16),
                      const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildTextField(Icons.person, 'Full Name', controller: _nameController),
                      const SizedBox(height: 16),
                      _buildTextField(Icons.email, 'Email', controller: _emailController),
                      const SizedBox(height: 16),
                      _buildTextField(Icons.phone, 'Phone Number', inputType: TextInputType.phone, controller: _phonenoController),
                      const SizedBox(height: 16),
                      _buildTextField(Icons.lock, 'Password', isPassword: true, controller: _passwordController),
                      const SizedBox(height: 16),
                      _buildTextField(Icons.lock_outline, 'Confirm Password', isPassword: true, controller: _confirmPasswordController),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.teal)
                              : const Text(
                            'Sign Up',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                        },
                        child: const Text(
                          'Already have an account? Log in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
