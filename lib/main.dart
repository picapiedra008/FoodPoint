import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_point/ui/auth/view_model/registro_screen.dart';
import 'package:food_point/ui/formularioRestaurante/view_model/formularioRestaurante.dart';
import 'package:food_point/ui/listaRestaurantesUsuario/view_model/lista_restaurantes_usuario_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:food_point/ui/core/themes/app_theme.dart';
import 'package:food_point/ui/auth/view_model/login_screen.dart';

import 'package:food_point/data/services/auth_service.dart';
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
    await GoogleSignIn.instance.initialize();
    firebaseConnected = true;
  } catch (e) {
    firebaseConnected = false;
  }

  runApp(MyApp(firebaseConnected: firebaseConnected));
}

class MyApp extends StatefulWidget {
  final bool firebaseConnected;

  const MyApp({super.key, required this.firebaseConnected});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Variable para controlar si hay un usuario logueado
  bool? isUserLoggedIn;
  
  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  // Método para verificar el estado de autenticación
  Future<void> _checkAuthState() async {
    if (!widget.firebaseConnected) {
      setState(() {
        isUserLoggedIn = false;
      });
      return;
    }

    // Verificar si hay un usuario autenticado
    final user = AuthService.instance.currentUser;
    setState(() {
      isUserLoggedIn = user != null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mostrar un loading mientras se verifica el estado de autenticación
    if (isUserLoggedIn == null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Verificando autenticación...'),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Platos de mi tierra',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      // Si hay usuario logueado, va directo a inicio, sino al login
      initialRoute: !widget.firebaseConnected 
          ? '/firebaseError'
          : isUserLoggedIn! 
            ? '/inicio' 
            : '/login',
      routes: {
        '/login': (context) =>
            LoginScreen(firebaseConnected: widget.firebaseConnected),
        '/registro': (context) => const RegisterScreen(),
        '/inicio': (context) => const HomeScreen(),
        '/catalogo': (context) => const DishCatalogPage(),
        '/restaurantes': (context) => const SaboresApp(),
        '/perfil': (context) => PerfilPage(),
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