import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_point/ui/formularioRestaurante/view_model/formularioRestaurante.dart';
import 'package:food_point/ui/listaRestaurantesUsuario/view_model/lista_restaurantes_usuario_screen.dart';
import 'firebase_options.dart';
import 'package:food_point/ui/core/themes/app_theme.dart';
import 'package:food_point/ui/auth/view_model/login_screen.dart';

// importa las páginas
import 'package:food_point/ui/home/view_model/home_screen.dart';
import 'widgets/catalogo_platos.dart';
import 'package:food_point/ui/listar_restaurantes/view_model/listar_restaurantes_screen.dart';
import 'package:food_point/ui/perfil_page/view_model/perfil_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseConnected = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseConnected = true;
  } catch (e) {
    firebaseConnected = false;
  }

  runApp(MyApp(firebaseConnected: firebaseConnected));
}

class MyApp extends StatelessWidget {
  final bool firebaseConnected;

  const MyApp({super.key, required this.firebaseConnected});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platos de mi tierra',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: firebaseConnected ? '/inicio' : '/firebaseError',
      routes: {
        '/login': (context) => LoginScreen(firebaseConnected: firebaseConnected),
        '/inicio': (context) => const HomeScreen(),
        '/catalogo': (context) => const DishCatalogPage(),
        '/restaurantes': (context) => const SaboresApp(),
        '/perfil': (context) => const PerfilPage(),
        '/perfil/restaurantes': (context) => const MisRestaurantesPage(),
        '/perfil/restaurantes/create': (context) => const RestaurantFormPage(),
        '/firebaseError': (context) => const _FirebaseErrorScreen(),
      },
      onGenerateRoute: (settings) {
        // Manejar rutas con parámetros
        if (settings.name!.startsWith('/perfil/restaurantes/edit/')) {
          final String id = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => RestaurantFormPage(restaurantId: id),
          );
        }
        return null;
      },
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  const _FirebaseErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline, size: 56, color: Colors.red),
            SizedBox(height: 12),
            Text(
              'No se pudo iniciar Firebase.\nRevisa tu conexión y configuración.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
