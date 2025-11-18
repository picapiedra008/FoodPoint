import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_point/data/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_point/widgets/bottom_nav_var.dart';
import 'package:food_point/ui/listaRestaurantesUsuario/view_model/lista_restaurantes_usuario_screen.dart';

class PerfilPage extends StatelessWidget {
  PerfilPage({super.key});
  
  Future<Map<String, dynamic>?> _getUsuario() async {
    final user = AuthService.instance.currentUser;
    if (user == null) return null; // Retorna null en lugar de lanzar excepción

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      // Fallback si no hay doc en Firestore
      return {
        'nombre': user.displayName ?? 'Sin nombre',
        'email': user.email ?? 'Sin email',
        'telefono': user.phoneNumber ?? 'Sin teléfono',
        'foto': user.photoURL ?? '',
        'miembroDesde': _formatearFecha(user.metadata.creationTime),
      };
    }

    final data = doc.data()!;
    return {
      'nombre': data['name'] ?? 'Sin nombre',
      'email': data['email'] ?? 'Sin email',
      'telefono': data['phoneNumber'] ?? 'Sin teléfono',
      'foto': data['photoUrl'] ?? '',
      'miembroDesde': _formatearFecha(
        (data['createdAt'] as Timestamp).toDate(),
      ),
    };
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
  }

  final List<Color> avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];
  
  Color getColorFromName(String name) {
    final index = name.codeUnitAt(0) % avatarColors.length;
    return avatarColors[index];
  }

// Widget para mostrar cuando no hay usuario logueado
Widget _buildNoUserScreen(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text("Mi Perfil"), 
      centerTitle: true
    ),
    bottomNavigationBar: const CustomBottomNav(selectedIndex: 3),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icono
            Icon(
              Icons.person_outline,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            // Mensaje
            Text(
              "No estás logueado",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              "Inicia sesión para acceder a tu perfil y gestionar tu información",
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Botón de iniciar sesión
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Iniciar Sesión",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Botón secundario de registrarse
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/registro',
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6A00),
                  side: const BorderSide(color: Color(0xFFFF6A00)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Crear Cuenta",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUsuario(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Si no hay usuario (retornó null) o hay error
        if (snapshot.data == null) {
          return _buildNoUserScreen(context);
        }

        final usuario = snapshot.data!;
        final user = AuthService.instance.currentUser;
        final firestorePhoto = usuario['foto']; // de Firestore
        final authPhoto = user?.photoURL; // de FirebaseAuth
        final photoUrl = (firestorePhoto != null && firestorePhoto.isNotEmpty)
            ? firestorePhoto
            : authPhoto;
        final name = usuario['nombre'] ?? 'U';
        final bgColor = getColorFromName(name);
        
        return Scaffold(
          appBar: AppBar(title: const Text("Mi Perfil"), centerTitle: true),
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
                        // Avatar
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
                          child: ClipOval(
                            child: photoUrl != null && photoUrl.isNotEmpty
                                ? Image.network(photoUrl, fit: BoxFit.cover)
                                : Container(
                                    color: bgColor,
                                    child: Center(
                                      child: Text(
                                        _getInitials(name),
                                        style: const TextStyle(
                                          fontSize: 36,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
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
                const Divider(color: Colors.grey, height: 30),

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
      },
    );
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return "Desconocido";

    const meses = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];

    return "${meses[fecha.month - 1]} ${fecha.year}";
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF6A00), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
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
              onPressed: () async {
                Navigator.of(context).pop();

                // 🔥 Cerrar sesión Firebase + Google
                await AuthService.instance.signOut();

                // 🔄 Redirigir al login
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/login',
                  (route) => false,
                );
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