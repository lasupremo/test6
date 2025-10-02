import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:rekindle/theme/theme.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    try {
      if (_emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter your email address.")),
        );
        return;
      }

      await Supabase.instance.client.auth.resetPasswordForEmail(
        _emailController.text.trim(),
        redirectTo: 'http://localhost:1696/reset',
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password reset link sent!")),
      );
    Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: authTheme,
      child: Builder(
        builder: (BuildContext newContext) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(newContext).colorScheme.surface,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // Standard back navigation
                  context.go('/login');
                },
                color: Theme.of(newContext).colorScheme.inversePrimary,
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Image.asset(
                    'assets/images/flame_logo.png',
                    height: 24,
                  ),
                ),
              ],
            ),
            body: Stack(
              children: [
                _buildBackground(newContext),
                _buildForgotPwForm(newContext),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenHeight = constraints.maxHeight;
        final topShapeHeight = screenHeight * 0.85;
        final bottomColorTopPosition = screenHeight * 0.65;
        final redLineTopPosition = screenHeight * 0.78;
        final redLineHeight = 120.0;

        return Stack(
          children: [
            Positioned(
              top: bottomColorTopPosition,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(color: Theme.of(context).colorScheme.primary),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: topShapeHeight,
              child: SvgPicture.asset(
                'assets/images/auth_background.svg',
                fit: BoxFit.fill,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.surface, BlendMode.srcIn),
              ),
            ),
            Positioned(
              top: redLineTopPosition,
              left: 0,
              right: 0,
              height: redLineHeight,
              child: Transform.rotate(
                angle: -0.04,
                child: SvgPicture.asset(
                  'assets/images/auth_background_line.svg',
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildForgotPwForm(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Forgot your password?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Enter the email associated with your account and we'll send an email with instructions to reset your password.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 40),
              TextFormField(
                controller: _emailController, // Linked to existing controller
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(context).copyWith(hintText: 'Email'),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: resetPassword, // Linked to existing resetPassword method
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Recover Password',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context) {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 15.0),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : Colors.black.withAlpha(25),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primaryContainer, width: 2.0),
      ),
    );
  }
}
