import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserDetailsScreen extends StatefulWidget {
  const UserDetailsScreen({super.key});

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Future<void> getUserData() async {
    try {
      // 📍 Referencia al documento "user1" dentro de la colección "users"
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc('user1')
          .get();

      if (doc.exists) {
        setState(() {
          userData = doc.data() as Map<String, dynamic>;
        });
      } else {
        print('❌ El documento no existe');
      }
    } catch (e) {
      print('Error al obtener datos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalles del Usuario')),
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nombre: ${userData!['nombres']}"),
                  Text("Apellidos: ${userData!['apellidos']}"),
                  Text("Correo: ${userData!['correo']}"),
                  Text("Teléfono: ${userData!['telefono']}"),
                ],
              ),
            ),
    );
  }
}
