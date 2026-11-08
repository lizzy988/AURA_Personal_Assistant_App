
import 'package:flutter/material.dart';
import 'api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  static const Color purple = Color(0xFF7950F2);
  static const Color teal = Color(0xFF00C4C7);
  static const Color navy = Color(0xFF19172F);

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Colors.red : teal,
      ),
    );
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showMessage('Please enter a valid email address.',
          error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result =
          await ApiService.requestPasswordReset(email: email);

      if (!mounted) return;

      setState(() => _codeSent = true);

      _showMessage(result['message'] ??
          'If your account exists, a reset code has been sent.');
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (code.length != 6) {
      _showMessage('Enter the six-digit verification code.',
          error: true);
      return;
    }

    if (password.length < 8) {
      _showMessage('Password must have at least 8 characters.',
          error: true);
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Your passwords do not match.',
          error: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.resetPassword(
        email: email,
        code: code,
        newPassword: password,
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Password Reset Successful!'),
          content: Text(
            result['message'] ??
                'Your password has been updated. Please log in.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pop(context);
              },
              child: const Text('Go to Login'),
            ),
          ],
        ),
      );
    } catch (e) {
      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.grey.shade100,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: purple),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: navy,
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 85,
                    width: 85,
                    decoration: BoxDecoration(
                      color: purple.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_reset_rounded,
                      color: purple,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 25),

                  const Text(
                    'Reset Your Password',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: navy,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    _codeSent
                        ? 'Enter the verification code sent to your email and choose a new password.'
                        : 'Forgot your password? Enter your registered email address and we will send you a verification code.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 30),

                  _buildField(
                    label: 'Email Address',
                    hint: 'Enter your registered email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                  ),

                  if (!_codeSent) ...[
                    const SizedBox(height: 25),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text('Send Verification Code'),
                    ),
                  ],

                  if (_codeSent) ...[
                    const SizedBox(height: 22),

                    _buildField(
                      label: 'Verification Code',
                      hint: 'Enter your 6-digit code',
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                    ),

                    const SizedBox(height: 20),

                    _buildField(
                      label: 'New Password',
                      hint: 'Enter your new password',
                      controller: _passwordController,
                      obscure: !_showPassword,
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    _buildField(
                      label: 'Confirm New Password',
                      hint: 'Re-enter your new password',
                      controller: _confirmPasswordController,
                      obscure: !_showConfirmPassword,
                      suffix: IconButton(
                        icon: Icon(
                          _showConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _showConfirmPassword =
                                !_showConfirmPassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed:
                          _isLoading ? null : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text('Reset Password'),
                    ),

                    TextButton(
                      onPressed:
                          _isLoading ? null : _sendCode,
                      child: const Text(
                        'Resend Verification Code',
                        style: TextStyle(color: teal),
                      ),
                    ),
                  ],

                  const SizedBox(height: 15),

                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        color: purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
