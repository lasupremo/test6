import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rekindle/auth/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rekindle/theme/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login() async{
    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      await authService.signInWithEmailPassword(email, password);
    }catch(e){
      if (mounted){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: authTheme, // Using the theme from the frontend code
      child: Builder(
        builder: (BuildContext newContext) {
          return Scaffold(
            body: Stack(
              children: [
                _buildBackground(newContext),
                _buildLoginForm(newContext),
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

  Widget _buildLoginForm(BuildContext context) {
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
                'Log In',
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
                controller: _emailController, // Linked to existing controller
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(context),
              ),
              const SizedBox(height: 20),
              Text('Password', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController, // Linked to existing controller
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
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () {
                    // Using navigation from original logic file
                    context.go('/reset-password');
                  },
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: login, // Linked to existing login method
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 40),
              Text.rich(
                TextSpan(
                  text: 'Don\'t have an account? ',
                  style: TextStyle(color: Theme.of(context).colorScheme.secondary),
                  children: [
                    TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.bold,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          context.go('/register');
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