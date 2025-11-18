import 'package:flutter/material.dart';

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController passwordController;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.nombreController,
    required this.emailController,
    required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    InputDecoration _inputDecoration(String label, IconData icon) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nombreController,
            decoration: _inputDecoration('Nombre completo', Icons.person),
            validator: (v) =>
                v == null || v.isEmpty ? 'Ingrese su nombre' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: _inputDecoration('Correo electrónico', Icons.email),
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                v != null && v.contains('@') ? null : 'Correo no válido',
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            decoration: _inputDecoration('Contraseña', Icons.lock),
            obscureText: true,
            validator: (v) =>
                v != null && v.length >= 6 ? null : 'Mínimo 6 caracteres',
          ),
        ],
      ),
    );
  }
}
