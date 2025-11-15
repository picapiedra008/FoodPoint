// lib/screens/home_screen.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_point/widgets/bottom_nav_var.dart'; // ajusta si la ruta es otra

/// Modelo local Food
class Food {
  final String id;
  final String nombre;
  final String? descripcion;
  final String tipo;
  final String? imagenUrl;     // url http/https
  final String? imageBase64;   // cadena base64 si existe
  final double rating;
  final int restaurantes;

  Food({
    required this.id,
    required this.nombre,
    this.descripcion,
    this.tipo = '',
    this.imagenUrl,
    this.imageBase64,
    this.rating = 0.0,
    this.restaurantes = 0,
  });

  /// Crea desde DocumentSnapshot (normaliza campos entre colecciones)
  factory Food.fromFirestoreDoc(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};

    final nombre = (data['nombre'] ?? data['name'] ?? 'Sin nombre').toString();
    final descripcion = (data['descripcion'] ?? data['description'] ?? data['desc'])?.toString();
    final tipo = (data['tipo'] ?? data['type'] ?? '').toString();

    // distintos nombres comunes para imágenes
    final imagenUrl = (data['imagen'] ?? data['imageUrl'] ?? data['image'])?.toString();
    final imageBase64 = (data['imageBase64'] ?? data['image_base64'] ?? data['image64'] ?? data['imagen'])?.toString();

    final rating = (data['rating'] is num) ? (data['rating'] as num).toDouble() : 0.0;
    final restaurantes = (data['restaurantes'] is num) ? (data['restaurantes'] as num).toInt() : 0;

    return Food(
      id: doc.id,
      nombre: nombre,
      descripcion: descripcion,
      tipo: tipo,
      imagenUrl: (imagenUrl != null && imagenUrl.trim().isNotEmpty) ? imagenUrl.trim() : null,
      imageBase64: (imageBase64 != null && imageBase64.trim().isNotEmpty) ? imageBase64.trim() : null,
      rating: rating,
      restaurantes: restaurantes,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'Esperando stream...';

  Future<void> _fetchOnceAndLog() async {
    setState(() => _status = 'Leyendo colecciones (fetch once)...');
    try {
      final p = await FirebaseFirestore.instance.collection('platos').get();
      final f = await FirebaseFirestore.instance.collection('foods').get();
      debugPrint('🔥 fetch once - platos: ${p.docs.length}, foods: ${f.docs.length}');
      for (final d in p.docs) debugPrint('plato id=${d.id} data=${d.data()}');
      for (final d in f.docs) debugPrint('food id=${d.id} data=${d.data()}');
      setState(() => _status = 'Fetch completo: platos=${p.docs.length}, foods=${f.docs.length} (ver consola)');
    } catch (e, st) {
      debugPrint('❌ Error fetchOnce: $e\n$st');
      setState(() => _status = 'Error en fetch: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabores de Cochabamba'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Forzar lectura',
            onPressed: _fetchOnceAndLog,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('platos').snapshots(),
        builder: (context, platosSnap) {
          if (platosSnap.hasError) {
            return const Center(child: Text('Error al cargar platos (platos). Revisa consola.'));
          }
          if (platosSnap.connectionState == ConnectionState.waiting) {
            // dejamos cargar mientras llega datos
          }

          final platosDocs = platosSnap.data?.docs ?? [];
          final platosList = platosDocs.map((d) => Food.fromFirestoreDoc(d)).toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('foods').snapshots(),
            builder: (context, foodsSnap) {
              if (foodsSnap.hasError) {
                return const Center(child: Text('Error al cargar platos (foods). Revisa consola.'));
              }
              if (foodsSnap.connectionState == ConnectionState.waiting && platosList.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              final foodsDocs = foodsSnap.data?.docs ?? [];
              final foodsList = foodsDocs.map((d) => Food.fromFirestoreDoc(d)).toList();

              // unir sin duplicados por id (prioridad: platos sobre foods)
              final Map<String, Food> mapById = {};
              for (final f in platosList) mapById[f.id] = f;
              for (final f in foodsList) {
                if (!mapById.containsKey(f.id)) mapById[f.id] = f;
              }
              final allFoods = mapById.values.toList();

              if (allFoods.isEmpty) {
                return const Center(child: Text('No hay platos registrados en las colecciones.'));
              }

              // Plato del día (estable por día)
              final now = DateTime.now();
              final seed = now.year * 10000 + now.month * 100 + now.day;
              final random = Random(seed);
              final featured = allFoods[random.nextInt(allFoods.length)];
              final otros = allFoods.where((f) => f.id != featured.id).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recomendado hoy', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _FeaturedFoodCard(food: featured),
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Buscar platos...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: theme.colorScheme.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text('Catálogo de Platos', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Column(children: otros.map((food) => _CatalogFoodCard(food: food)).toList()),
                    const SizedBox(height: 30),
                    Align(alignment: Alignment.center, child: Text(_status, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Featured card
class _FeaturedFoodCard extends StatelessWidget {
  final Food food;
  const _FeaturedFoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(children: [
            SizedBox(height: 190, width: double.infinity, child: _buildFoodImage(food, fit: BoxFit.cover)),
            Positioned(
              top: 12,
              left: 12,
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)), child: const Text('Plato del Día', style: TextStyle(color: Colors.white, fontSize: 12))),
            ),
          ]),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(food.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              if (food.descripcion != null && food.descripcion!.isNotEmpty) Text(food.descripcion!, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.store_mall_directory, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${food.restaurantes} restaurantes', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text(food.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ]),
            ]),
          ),
        ],
      ),
    );
  }
}

/// Catalog card
class _CatalogFoodCard extends StatelessWidget {
  final Food food;
  const _CatalogFoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(borderRadius: BorderRadius.circular(10), child: SizedBox(width: 70, height: 70, child: _buildFoodImage(food, fit: BoxFit.cover))),
        title: Text(food.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          Text('${food.restaurantes} restaurantes'),
          const SizedBox(height: 4),
          Row(children: [
            Chip(label: Text(food.tipo.isNotEmpty ? food.tipo : 'Sin tipo'), backgroundColor: Colors.orange.shade100, labelStyle: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.star, color: Colors.amber, size: 20),
            Text(food.rating.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
        ]),
        onTap: () {
          // TODO: abrir detalle
        },
      ),
    );
  }
}

/// Construye la imagen: soporta base64 (data:...;base64,...) y URLs http/https
Widget _buildFoodImage(Food food, {BoxFit fit = BoxFit.cover}) {
  final base64Str = food.imageBase64;
  final url = food.imagenUrl;

  Widget placeholder([IconData icon = Icons.image]) {
    return Container(color: Colors.grey[300], alignment: Alignment.center, child: Icon(icon, size: 36, color: Colors.white70));
  }

  // 1) imageBase64
  if (base64Str != null && base64Str.trim().isNotEmpty) {
    String cleaned = base64Str.trim();

    // quitar comillas envolventes
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) || (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
      cleaned = cleaned.substring(1, cleaned.length - 1);
    }

    // quitar escapes y espacios
    cleaned = cleaned.replaceAll(r'\n', '');
    cleaned = cleaned.replaceAll('\n', '');
    cleaned = cleaned.replaceAll(' ', '');

    // si tiene prefijo data:..., obtener parte después de la coma
    if (cleaned.contains(',')) {
      final parts = cleaned.split(',');
      cleaned = parts.last;
    }

    try {
      final bytes = base64Decode(cleaned);
      if (bytes.isEmpty) throw Exception('bytes vacíos');
      return Image.memory(bytes, fit: fit, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) {
        debugPrint('Error Image.memory para doc ${food.id}');
        return placeholder(Icons.broken_image);
      });
    } catch (e, st) {
      debugPrint('❌ Error decodificando base64 doc ${food.id}: $e');
      debugPrint('--- cleaned (len=${cleaned.length}) start: ${cleaned.length > 120 ? cleaned.substring(0, 120) : cleaned}');
      debugPrint('--- stack: $st');
      return placeholder(Icons.broken_image);
    }
  }

  // 2) imagen por URL
  if (url != null && url.trim().isNotEmpty) {
    final safe = url.trim();
    if (safe.startsWith('http://') || safe.startsWith('https://')) {
      return Image.network(safe, fit: fit, width: double.infinity, height: double.infinity, errorBuilder: (_, __, ___) {
        debugPrint('Error Image.network para doc ${food.id} -> $safe');
        return placeholder(Icons.broken_image);
      });
    } else {
      debugPrint('URL no soportada para ${food.id}: $safe');
      return placeholder(Icons.link_off);
    }
  }

  // 3) placeholder por defecto
  return placeholder();
}
