import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String nombre;
  final String? descripcion;
  /// Aquí guardamos lo que usemos para mostrar la imagen (puede ser URL o Base64)
  final String imagen;
  final String? imagenBase64;
  final int restaurantes;
  final String tipo;
  final double rating;

  Food({
    required this.id,
    required this.nombre,
    required this.imagen,
    required this.imagenBase64,
    required this.restaurantes,
    required this.tipo,
    required this.rating,
    this.descripcion,
  });

  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() ?? {}) as Map<String, dynamic>;

    // Nombre: intentar con 'nombre' o 'name'
    final nombre = (data['nombre'] ?? data['name'] ?? 'Sin nombre') as String;

    // Descripción: en Firestore es 'description'
    final descripcion =
        (data['descripcion'] ?? data['description']) as String?;

    // Imagen:
    // - si tienes campo 'imagen' o 'imageUrl' se usan
    // - si no, usamos 'imageBase64' (lo que tienes ahora en foods)
    final imagen = (data['imagen'] ??
            data['imageUrl'] ??
            data['image'] ??
            data['imageBase64'] ??
            '') as String;

    final imagenBase64 =
        (data['imageBase64'] ?? data['imagenBase64']) as String?;

    // Restaurantes: si no existe, 0
    final rawRest = data['restaurantes'] ?? data['restaurantsCount'] ?? 0;
    final restaurantes = rawRest is int
        ? rawRest
        : int.tryParse(rawRest.toString()) ?? 0;

    // Tipo / categoría
    final tipo = (data['tipo'] ?? data['category'] ?? '') as String;

    // Rating
    final rawRating = data['rating'] ?? 0;
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating.toString()) ?? 0.0;

    return Food(
      id: doc.id,
      nombre: nombre,
      descripcion: descripcion,
      imagen: imagen,
      imagenBase64: imagenBase64,
      restaurantes: restaurantes,
      tipo: tipo,
      rating: rating,
    );
  }
}
