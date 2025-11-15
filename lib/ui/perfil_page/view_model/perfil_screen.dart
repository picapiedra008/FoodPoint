import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_point/widgets/bottom_nav_var.dart';
import 'package:food_point/ui/listaRestaurantesUsuario/view_model/lista_restaurantes_usuario_screen.dart';
class PerfilPage extends StatelessWidget {
  const PerfilPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Información estática del usuario (por ahora)
    final usuario = {
      'nombre': 'Juan Pérez',
      'email': 'juan.perez@email.com',
      'telefono': '+591 12345678',
      'miembroDesde': 'Enero 2024',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Perfil"),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Card con información del usuario
            Card(
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Avatar del usuario
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                        border: Border.all(
                          color: const Color(0xFFFF6A00),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Información del usuario
                    _buildInfoItem(
                      icon: Icons.person_outline,
                      label: 'Nombre',
                      value: usuario['nombre']!,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: usuario['email']!,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: usuario['telefono']!,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoItem(
                      icon: Icons.calendar_today_outlined,
                      label: 'Miembro desde',
                      value: usuario['miembroDesde']!,
                    ),
                  ],
                ),
              ),
            ),

            // Botón Editar Información
            _buildActionButton(
              icon: FontAwesomeIcons.userEdit,
              text: 'Editar Información',
              onPressed: () {
                // Navegar a pantalla de edición
                print('Editar información');
              },
            ),
            const SizedBox(height: 12),

            // Botón Mis Restaurantes
            _buildActionButton(
              icon: FontAwesomeIcons.store,
              text: 'Mis Restaurantes',
              onPressed: () {
                Navigator.pushNamed(context, '/perfil/restaurantes');
              },
            ),
            const SizedBox(height: 12),

            // Separador antes de cerrar sesión
            const Divider(
              color: Colors.grey,
              height: 30,
            ),

            // Botón Cerrar Sesión
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  _mostrarDialogoCerrarSesion(context);
                },
                icon: const Icon(Icons.logout, size: 18),
                label: const Text("Cerrar Sesión"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: const Color(0xFFFF6A00),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: FaIcon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF6A00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Cerrar Sesión"),
          content: const Text("¿Estás seguro de que quieres cerrar sesión?"),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancelar",
                style: TextStyle(color: Colors.black54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Aquí iría la lógica para cerrar sesión
                print('Sesión cerrada');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text("Cerrar Sesión"),
            ),
          ],
        );
      },
    );
  }
}