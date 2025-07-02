import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app/dashboard/dashboard.dart';
import 'package:app/login/forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _checkingAutoLogin = true;

  @override
  void initState() {
    super.initState();
    _emailController.text = 'tumocare@gmail.com'; // Pre-fill for convenience
    _checkAutoLogin();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAutoLogin() async {
    try {
      final currentDeviceId = await _getDeviceId();
      if (currentDeviceId == null) {
        setState(() => _checkingAutoLogin = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('admin_auth')
          .select('device_id, email')
          .eq('email', 'tumocare@gmail.com')
          .maybeSingle();

      // Case 1: No device ID in DB - show login
      if (response == null || response['device_id'] == null) {
        setState(() => _checkingAutoLogin = false);
        return;
      }

      final storedDeviceId = response['device_id'] as String;
      final storedEmail = response['email'] as String;

      // Case 2: Device ID matches - auto login
      if (storedDeviceId == currentDeviceId) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => Dashboard(
              email: storedEmail,
              onPasswordChanged: (newPassword) async {
                await Supabase.instance.client
                    .from('admin_auth')
                    .update({'password': newPassword})
                    .eq('email', storedEmail);
              },
            ),
          ),
        );
      }
      // Case 3: Different device ID - show logout message
      else {
        _showSnackBar('Please login again - device changed');
        setState(() => _checkingAutoLogin = false);
      }
    } catch (e) {
      debugPrint('Auto-login check error: $e');
      setState(() => _checkingAutoLogin = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ), // This parenthesis was missing
    );
  }
  Future<String?> _getDeviceId() async {
    if (kIsWeb) return 'web';

    final deviceInfoPlugin = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        return iosInfo.identifierForVendor;
      }
      return null;
    } catch (e) {
      debugPrint('Device ID error: $e');
      return null;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final currentDeviceId = await _getDeviceId();

    try {
      // Verify credentials
      final authResponse = await Supabase.instance.client
          .from('admin_auth')
          .select()
          .eq('email', email)
          .eq('password', password)
          .maybeSingle();

      if (authResponse == null) {
        _showSnackBar('Invalid credentials');
        return;
      }

      // Update device ID in database
      await Supabase.instance.client
          .from('admin_auth')
          .update({'device_id': currentDeviceId})
          .eq('email', email);

      // Store login locally
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => Dashboard(
            email: email,
            onPasswordChanged: (newPassword) async {
              await Supabase.instance.client
                  .from('admin_auth')
                  .update({'password': newPassword})
                  .eq('email', email);
            },
          ),
        ),
      );
    } catch (e) {
      _showSnackBar('Login failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingAutoLogin) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.medical_services, size: 100, color: Colors.blue),
                const SizedBox(height: 30),
                Text(
                  'Medical Portal Login',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.isEmpty ? 'Enter email' : null,
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(_passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off),
                      onPressed: () => setState(
                              () => _passwordVisible = !_passwordVisible),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) =>
                  value!.length < 6 ? 'Minimum 6 characters' : null,
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('LOGIN'),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  ),
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}