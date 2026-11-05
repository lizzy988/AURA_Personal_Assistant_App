
import 'package:flutter/material.dart';
import 'api_service.dart';

const Color tealColor = Color(0xFF00C4C7);
const Color purpleColor = Color(0xFF7950F2);
const Color navyColor = Color(0xFF19172F);

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool hidePassword = true;
  bool hideConfirmPassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> createAccount() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty ||
        password.isEmpty || confirmPassword.isEmpty) {
      showMessage('Please fill in all fields.');
      return;
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      showMessage('Please enter a valid email address.');
      return;
    }

    if (password.length < 8) {
      showMessage('Password must contain at least 8 characters.');
      return;
    }

    if (password != confirmPassword) {
      showMessage('Your passwords do not match.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.register(
        fullName: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      final success = result['success'] == true ||
          result['status'] == 'success';

      if (success) {
        showMessage('Account created successfully! Please log in.');

        await Future.delayed(const Duration(milliseconds: 700));

        if (mounted) {
          Navigator.pop(context);
        }
      } else {
        showMessage(
          result['message']?.toString() ??
              result['error']?.toString() ??
              'Registration failed. Please try again.',
        );
      }
    } catch (e) {
      if (mounted) {
        showMessage('Could not connect to the server. Check that XAMPP is running.');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Widget buildTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    bool hideText = false,
    VoidCallback? toggleVisibility,
  }) {
    return TextField(
      controller: controller,
      obscureText: hideText,
      keyboardType: hint == 'Email Address'
          ? TextInputType.emailAddress
          : TextInputType.text,
      style: const TextStyle(color: navyColor),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: purpleColor),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  hideText ? Icons.visibility_off : Icons.visibility,
                  color: purpleColor,
                ),
                onPressed: toggleVisibility,
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: tealColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
            vertical: 20,
          ),
          child: Column(
            children: [
              const SizedBox(height: 15),

              Container(
                width: 85,
                height: 85,
                decoration: const BoxDecoration(
                  color: purpleColor,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 42,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              const Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Join AURA and organise your day smarter.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),

              const SizedBox(height: 30),

              buildTextField(
                hint: 'Full Name',
                icon: Icons.person_outline,
                controller: nameController,
              ),

              const SizedBox(height: 16),

              buildTextField(
                hint: 'Email Address',
                icon: Icons.email_outlined,
                controller: emailController,
              ),

              const SizedBox(height: 16),

              buildTextField(
                hint: 'Password',
                icon: Icons.lock_outline,
                controller: passwordController,
                isPassword: true,
                hideText: hidePassword,
                toggleVisibility: () {
                  setState(() {
                    hidePassword = !hidePassword;
                  });
                },
              ),

              const SizedBox(height: 16),

              buildTextField(
                hint: 'Confirm Password',
                icon: Icons.lock_outline,
                controller: confirmPasswordController,
                isPassword: true,
                hideText: hideConfirmPassword,
                toggleVisibility: () {
                  setState(() {
                    hideConfirmPassword = !hideConfirmPassword;
                  });
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: isLoading ? null : createAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purpleColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 22),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have an account? ',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: navyColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
