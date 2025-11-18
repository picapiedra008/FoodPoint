import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String nombre;
  final String direccion;
  final double distanciaKm;
  final double rating;
  final String horario;

  Restaurant({
    required this.nombre,
    required this.direccion,
    required this.distanciaKm,
    required this.rating,
    required this.horario,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});
    return Restaurant(
      nombre:      (d['nombre'] ?? '') as String,
      direccion:   (d['direccion'] ?? '') as String,
      distanciaKm: (d['distanciaKm'] ?? 0).toDouble(),
      rating:      (d['rating'] ?? 0).toDouble(),
      horario:     (d['horario'] ?? '') as String,
    );
  }
}
