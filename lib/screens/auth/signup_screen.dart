import 'package:flutter/material.dart';

import '../../main.dart';
import '../../services/auth_service.dart';
import '../../utils.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  DateTime? _birthdate;
  String _role = 'player';
  bool _loading = false;

  /// Opens the calendar so the user picks the birthdate.
  Future<void> _pickBirthdate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthdate ?? DateTime(now.year - 18),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Select your birthdate',
    );
    if (picked != null) setState(() => _birthdate = picked);
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (_birthdate == null) {
      showMsg('Please choose your birthdate');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = await AuthService.signUp(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        birthdate: _birthdate!,
        role: _role,
      );
      if (!mounted) return;
      showMsg('Account created');
      // Remove login + sign-up screens and open the home screen
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => homeFor(user)), (_) => false);
    } catch (e) {
      showMsg(AuthService.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create account')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Full name', prefixIcon: Icon(Icons.person)),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.email)),
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Enter a valid email' : null,
              ),
              const SizedBox(height: 16),
              // Birthdate: tapping opens the calendar (showDatePicker)
              InkWell(
                onTap: _pickBirthdate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                      labelText: 'Birthdate', prefixIcon: Icon(Icons.cake)),
                  child: Text(_birthdate == null
                      ? 'Tap to choose'
                      : formatDate(_birthdate)),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Password', prefixIcon: Icon(Icons.lock)),
                validator: (v) => v == null || v.length < 6
                    ? 'At least 6 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline)),
                validator: (v) => v != _passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 16),
              const Text('Account type'),
              RadioGroup<String>(
                groupValue: _role,
                onChanged: (v) => setState(() => _role = v!),
                child: const Column(
                  children: [
                    RadioListTile(value: 'player', title: Text('Player')),
                    RadioListTile(
                        value: 'owner', title: Text('Facility owner')),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loading ? null : _signUp,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Sign up'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
