import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_point/domain/models/food.dart';
import 'package:food_point/widgets/bottom_nav_var.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabores de Cochabamba'),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('foods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los platos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay platos registrados.'));
          }

          final docs = snapshot.data!.docs;
          final foods = docs.map((d) => Food.fromFirestore(d)).toList();

          // 🔥 Plato del día aleatorio pero estable por día
          final now = DateTime.now();
          final seed = now.year * 10000 + now.month * 100 + now.day;
          final random = Random(seed);
          final featured = foods[random.nextInt(foods.length)];

          final otrosPlatos =
              foods.where((food) => food.id != featured.id).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendado hoy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 🟥 Carta del "Plato del Día"
                _FeaturedFoodCard(food: featured),

                const SizedBox(height: 20),

                // Buscador (solo vista por ahora)
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar platos...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Catálogo de Platos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Column(
                  children: otrosPlatos
                      .map((food) => _CatalogFoodCard(food: food))
                      .toList(),
                ),
                
              ],
            ),
            
          );
        },
      ),
    );
  }
}

class _FeaturedFoodCard extends StatelessWidget {
  final Food food;

  const _FeaturedFoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(food: food),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen + etiqueta
            Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: _buildFoodImage(
                    food.imagen,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Plato del Día',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 12, bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (food.descripcion != null &&
                      food.descripcion!.isNotEmpty)
                    Text(
                      food.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.store_mall_directory,
                          size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${food.restaurantes} restaurantes',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        food.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      
    );
  }
}

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
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildFoodImage(
            food.imagen,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          food.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${food.restaurantes} restaurantes'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(food.tipo),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 20),
                Text(
                  food.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(food: food),
            ),
          );
        },
      ),
    );
  }
}

/// 🆕 Pantalla de detalle del plato
class FoodDetailScreen extends StatelessWidget {
  final Food food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(food.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen grande
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildFoodImage(
                  food.imagen,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rating + restaurantes
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  food.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.store_mall_directory, size: 20),
                const SizedBox(width: 4),
                Text(
                  '${food.restaurantes} restaurantes',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tipo de plato
            Chip(
              label: Text(food.tipo),
              backgroundColor: Colors.orange.shade100,
              labelStyle: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Descripción completa
            if (food.descripcion != null && food.descripcion!.isNotEmpty)
              Text(
                food.descripcion!,
                style: theme.textTheme.bodyMedium,
              )
            else
              Text(
                'Sin descripción disponible.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: Colors.grey.shade600),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// ------------ Helpers para imagen (Base64 o URL) ------------

Widget _buildFoodImage(
  String imagen, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (imagen.isEmpty) {
    return _foodImagePlaceholder(width, height);
  }

  // 1) Intentar como Base64
  try {
    String base64String = imagen;

    // Si viene como 'data:image/png;base64,AAAA...'
    if (base64String.startsWith('data:image')) {
      base64String = base64String.split(',').last;
    }

    base64String = base64String.trim();

    // Ajustar padding (longitud múltiplo de 4)
    final remainder = base64String.length % 4;
    if (remainder != 0) {
      base64String =
          base64String.padRight(base64String.length + (4 - remainder), '=');
    }

    final bytes = base64Decode(base64String);

    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
    );
  } catch (e) {
    debugPrint('No es Base64 válido o falló decode: $e');
  }

  // 2) Si no era Base64, probar como URL normal
  return Image.network(
    imagen,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      debugPrint('Error cargando imagen por URL: $error');
      return _foodImagePlaceholder(width, height);
    },
  );
}

Widget _foodImagePlaceholder(double? width, double? height) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: const Icon(
      Icons.image_not_supported,
      color: Colors.grey,
      size: 40,
    ),
  );
}
