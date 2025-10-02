import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekindle/auth/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rekindle/theme/theme.dart';
import 'package:rekindle/text/policy_strings.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;

  @override
    void dispose() {
      _emailController.dispose();
      _passwordController.dispose();
      _confirmPasswordController.dispose();
      super.dispose();
    }

  void signUp() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please agree to the Terms & Conditions and Data Privacy Act.")),
      );
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")));
      return;
    }

    try {
      await authService.signUpWithEmailPassword(email, password);
      
    }catch(e){
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  void _showPolicy(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: authTheme,
      child: Builder(
        builder: (BuildContext newContext) {
          return Scaffold(
            body: Stack(
              children: [
                _buildBackground(newContext),
                _buildSignUpForm(newContext),
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
        final topShapeHeight = screenHeight * 0.6;
        final bottomColorTopPosition = screenHeight * 0.45;
        final redLineTopPosition = screenHeight * 0.52;
        final redLineHeight = 120.0;

        return Stack(
          children: [
            Positioned(
              top: bottomColorTopPosition,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Theme.of(context).colorScheme.primary,
              ),
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

  Widget _buildSignUpForm(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('assets/images/flame_logo.png', height: 80),
              const SizedBox(height: 24),
              Text(
                'Sign Up',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.inversePrimary,
                ),
              ),
              const SizedBox(height: 40),
              Text('Email', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(context),
              ),
              const SizedBox(height: 20),
              Text('Password', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration(context).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text('Confirm Password', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: _inputDecoration(context).copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _agreeToTerms,
                    onChanged: (value) => setState(() => _agreeToTerms = value!),
                    activeColor: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  Flexible(
                    child: Text.rich(
                      TextSpan(
                        text: 'I have read and agree to the ',
                        style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                        children: [
                          TextSpan(
                            text: 'Terms & Condition',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                _showPolicy(context, 'Terms & Conditions', termsAndConditionsText);
                              },
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Data Privacy Act',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.tertiary,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                 _showPolicy(context, 'Data Privacy Act', dataPrivacyActText);
                              },
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text.rich(
                TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  children: [
                    TextSpan(
                      text: 'Log In',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context.go('/login');
                        },
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
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
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primaryContainer, width: 2.0),
      ),
    );
  }
}
