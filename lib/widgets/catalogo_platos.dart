import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dish.dart';
import '../models/restaurant.dart';
import '../data/services/dish_service.dart';

class DishCatalogPage extends StatelessWidget {
  const DishCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = DishService();

    return Scaffold(
      backgroundColor: const Color(0xFFFEF3F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catálogo de Platos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Expanded(
                child: StreamBuilder<List<Dish>>(
                  stream: service.streamDishes(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final dishes = snapshot.data ?? [];
                    if (dishes.isEmpty) {
                      return const Center(child: Text('No hay platos aún'));
                    }

                    return ListView.separated(
                      itemCount: dishes.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final d = dishes[index];
                        return _DishCard(dish: d);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DishCard extends StatelessWidget {
  final Dish dish;
  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => DishDetailSheet(dish: dish),
        );
      },
      child: Card(
        elevation: 2.5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildDishImage(
                  dish,
                  width: 100,
                  height: 90,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${dish.restaurantes} restaurantes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: dish.tipo == 'Cena' ? Colors.orange[400] : Colors.amber[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dish.tipo.isEmpty ? '—' : dish.tipo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            dish.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DishDetailSheet extends StatelessWidget {
  final Dish dish;
  const DishDetailSheet({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    final themeText = const TextStyle(color: Colors.black87);
    final service = DishService();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dish.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Imagen grande
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _buildDishImage(
                  dish,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: dish.tipo == 'Cena' ? Colors.orange[400] : Colors.amber[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dish.tipo.isEmpty ? '—' : dish.tipo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(dish.rating.toStringAsFixed(1), style: themeText),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.group_outlined, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    'Restaurantes Disponibles (${dish.restaurantes})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              FutureBuilder<List<Restaurant>>(
                future: service.fetchRestaurantsForDish(dish.id),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snap.hasError) {
                    return Text('Error al cargar restaurantes: ${snap.error}');
                  }
                  final rs = snap.data ?? [];
                  if (rs.isEmpty) {
                    return const Text('Aún sin restaurantes vinculados a este plato.');
                  }
                  return Column(
                    children: rs.map((r) => _RestaurantCard(r)).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final Restaurant r;
  const _RestaurantCard(this.r);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 2),
            color: Color(0x14000000),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  r.nombre,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                '${r.distanciaKm.toStringAsFixed(1)} km',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(r.direccion, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(
                r.rating.toStringAsFixed(1),
                style: const TextStyle(color: Colors.black87),
              ),
              const SizedBox(width: 16),
              const Text('•', style: TextStyle(color: Colors.black26)),
              const SizedBox(width: 16),
              Text(
                'Abierto hasta ${r.horario.split(" ").last}',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// --------- Helpers de imagen (Base64 o URL) ---------

Widget _buildDishImage(
  Dish dish, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  // 1) Base64 primero
  if (dish.imagenBase64 != null && dish.imagenBase64!.isNotEmpty) {
    try {
      final bytes = _decodeBase64Image(dish.imagenBase64!);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
      );
    } catch (e) {
      debugPrint('Error decodificando Base64: $e');
      // sigue abajo a URL / placeholder
    }
  }

  // 2) Luego URL normal
  if (dish.imagenUrl.isNotEmpty) {
    return Image.network(
      dish.imagenUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('Error cargando imagen por URL: $error');
        return _dishImagePlaceholder(width, height);
      },
    );
  }

  // 3) Si no hay nada, placeholder
  return _dishImagePlaceholder(width, height);
}

Uint8List _decodeBase64Image(String base64String) {
  // Si viene como 'data:image/png;base64,AAAA...'
  if (base64String.contains(',')) {
    base64String = base64String.split(',').last;
  }

  // Quitar espacios / saltos
  base64String = base64String.trim();

  // Ajustar padding si hace falta (longitud múltiplo de 4)
  final remainder = base64String.length % 4;
  if (remainder != 0) {
    base64String =
        base64String.padRight(base64String.length + (4 - remainder), '=');
  }

  return base64Decode(base64String);
}

Widget _dishImagePlaceholder(double? width, double? height) {
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
