import 'package:cloud_firestore/cloud_firestore.dart';

class Dish {
  final String id;
  final String nombre;
  final String imagenUrl;
  final String? imagenBase64; 
  final String tipo;        // p.ej. "Almuerzo" | "Cena"
  final int restaurantes;   // cantidad total
  final double rating;      // 0.0 - 5.0

  Dish({
    required this.id,
    required this.nombre,
    required this.imagenUrl,
    this.imagenBase64,
    required this.tipo,
    required this.restaurantes,
    required this.rating,
  });

  factory Dish.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});
    return Dish(
      id: doc.id,
      nombre:       (d['nombre'] ?? '') as String,
      imagenUrl:    (d['imagen'] ?? '') as String,
      imagenBase64: (d['imagenBase64'] ?? '') as String?,
      tipo:         (d['tipo'] ?? '') as String,
      restaurantes: (d['restaurantes'] ?? 0) as int,
      rating:       (d['rating'] ?? 0).toDouble(),
    );
  }
}
