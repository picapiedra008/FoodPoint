import 'package:flutter/material.dart';
import 'package:food_point/data/services/auth_service.dart';
import 'package:food_point/ui/auth/view_model/login_screen.dart';
import 'package:food_point/ui/home/view_model/home_screen.dart';

class RegisterButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const RegisterButton({
    super.key,
    required this.formKey,
    required this.nombreController,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          if (formKey.currentState!.validate()) {
            final nombre = nombreController.text.trim();
            final email = emailController.text.trim();
            final password = passwordController.text.trim();

            try {
              await AuthService.instance.createUserWithEmailAndProfile(
                email: email,
                password: password,
                name: nombre,
              );

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginScreen(firebaseConnected: true),
                  ),
                );
              }
            } on Exception catch (e) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Error: $e')));
            }
          }
        },
        child: Text(
          'Registrarse',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
