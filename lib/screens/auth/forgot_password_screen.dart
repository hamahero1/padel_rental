import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils.dart';

/// Firebase emails the user a link to set a new password.
class ForgotPasswordScreen extends StatefulWidget {
  final String email;
  const ForgotPasswordScreen({super.key, this.email = ''});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  late final _emailController = TextEditingController(text: widget.email);
  bool _loading = false;

  Future<void> _send() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      showMsg('Enter a valid email');
      return;
    }
    setState(() => _loading = true);
    try {
      await AuthService.resetPassword(email);
      showMsg('Reset link sent. Check your email (and spam folder).');
      if (mounted) Navigator.pop(context);
    } catch (e) {
      showMsg(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
                'Enter your email and we will send you a link to reset your password.'),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _loading ? null : _send,
              child: const Text('Send reset link'),
            ),
          ],
        ),
      ),
    );
  }
}
