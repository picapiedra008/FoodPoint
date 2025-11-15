import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:food_point/ui/formularioRestaurante/view_model/formularioRestaurante.dart';
import 'package:food_point/widgets/bottom_nav_var.dart';


class SaboresApp extends StatelessWidget {
  const SaboresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabores de Cochabamba',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8ECE3),
        textTheme: GoogleFonts.comfortaaTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6A00)),
        useMaterial3: true,
      ),
      home: const RestaurantesPage(),
    );
  }
}

class Restaurante {
  final String id;
  final String nombre;
  final String descripcion;
  final String horario;
  final double calificacion;
  final String? logoBase64;
  final bool abierto;
  final bool destacado;

  Restaurante({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.horario,
    required this.calificacion,
    this.logoBase64,
    this.abierto = true,
    this.destacado = false,
  });
}

class RestaurantesPage extends StatefulWidget {
  const RestaurantesPage({super.key});

  @override
  State<RestaurantesPage> createState() => _RestaurantesPageState();
}

class _RestaurantesPageState extends State<RestaurantesPage> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<Restaurante> restaurantes = [];
  bool _isLoading = true;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurantes();
  }

  Future<void> _loadRestaurantes() async {
    try {
      QuerySnapshot snapshot = await db.collection('restaurants').get();
      
      List<Restaurante> loadedRestaurantes = [];
      
      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        
        // Construir el horario desde openingTime y closingTime
        String horario = 'Horario no disponible';
        if (data['openingTime'] != null && data['closingTime'] != null) {
          horario = '${data['openingTime']} - ${data['closingTime']}';
        } else if (data['openingTime'] != null) {
          horario = 'Desde ${data['openingTime']}';
        } else if (data['closingTime'] != null) {
          horario = 'Hasta ${data['closingTime']}';
        }
        
        // Calificación por defecto si no existe
        double calificacion = data['calificacion']?.toDouble() ?? 4.0;
        
        loadedRestaurantes.add(Restaurante(
          id: doc.id,
          nombre: data['name'] ?? 'Sin nombre',
          descripcion: data['description'] ?? 'Sin descripción',
          horario: horario,
          calificacion: calificacion,
          logoBase64: data['logoBase64'],
          abierto: _estaAbierto(data['openingTime'], data['closingTime']),
          destacado: data['destacado'] ?? false,
        ));
      }

      setState(() {
        restaurantes = loadedRestaurantes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar restaurantes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _estaAbierto(String? openingTime, String? closingTime) {
    if (openingTime == null || closingTime == null) return true;
    
    try {
      final now = TimeOfDay.now();
      final opening = _parseTime(openingTime);
      final closing = _parseTime(closingTime);
      
      if (opening == null || closing == null) return true;
      
      // Convertir a minutos para comparar
      final nowMinutes = now.hour * 60 + now.minute;
      final openingMinutes = opening.hour * 60 + opening.minute;
      final closingMinutes = closing.hour * 60 + closing.minute;
      
      return nowMinutes >= openingMinutes && nowMinutes <= closingMinutes;
    } catch (e) {
      return true;
    }
  }

  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  void _editarRestaurante(String restauranteId) {

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantFormPage(restaurantId: restauranteId),
      ),
    );
    print('Editar restaurante: $restauranteId');
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = restaurantes
        .where(
          (r) =>
              r.nombre.toLowerCase().contains(searchText.toLowerCase()) ||
              r.descripcion.toLowerCase().contains(searchText.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Restaurantes"), 
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantFormPage(),
                ),
              );

        
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Encuentra un restaurante en especifico",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Buscar restaurantes...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                        ),
                        onChanged: (val) => setState(() => searchText = val),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          /*Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.star, color: Color(0xFFFF6A00)),
                              label: const Text("Mejor calificados"),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black87,
                                side: const BorderSide(color: Color(0xFFFF6A00)),
                              ),
                            ),
                          ),*/
                          const SizedBox(width: 8),
                          /*OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Color(0xFFFF6A00)),
                            ),
                            child: const Text("Filtros"),
                          ),*/
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final r = filteredList[index];
                      return _buildRestauranteCard(r);
                    },
                  ),
                ),
              ],
            ),


      bottomNavigationBar: const CustomBottomNav(selectedIndex: 2), // pestaña activa

    );
  }

  Widget _buildRestauranteCard(Restaurante r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                // Imagen del restaurante (logoBase64 o icono por defecto)
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[200],
                  ),
                  child: r.logoBase64 != null && r.logoBase64!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.memory(
                            _decodeBase64(r.logoBase64!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return _buildPlaceholderIcon();
                            },
                          ),
                        )
                      : _buildPlaceholderIcon(),
                ),
                if (r.destacado)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade700,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Destacado',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: r.abierto ? Colors.green : Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.abierto ? 'Abierto' : 'Cerrado',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.nombre,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text("${r.calificacion}"),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, color: Colors.grey, size: 18),
                const SizedBox(width: 4),
                Text(r.horario, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              r.descripcion,
              style: const TextStyle(color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            
            // Botón de editar (reemplaza los botones anteriores)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _editarRestaurante(r.id),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text("Editar Restaurante"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.restaurant,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }
}