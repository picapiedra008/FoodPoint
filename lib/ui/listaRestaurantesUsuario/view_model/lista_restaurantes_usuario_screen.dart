import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:food_point/ui/formularioRestaurante/view_model/formularioRestaurante.dart';

class MisRestaurantesPage extends StatefulWidget {
  const MisRestaurantesPage({super.key});

  @override
  State<MisRestaurantesPage> createState() => _MisRestaurantesPageState();
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
  final String userId;
  final String visibility;

  Restaurante({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.horario,
    required this.calificacion,
    this.logoBase64,
    this.abierto = true,
    this.destacado = false,
    required this.userId,
    required this.visibility,
  });
}

class _MisRestaurantesPageState extends State<MisRestaurantesPage> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  
  // User ID estático por el momento
  final String userId = "user1";

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
      // Filtrar restaurantes por user_id
      QuerySnapshot snapshot = await db
          .collection('restaurants')
          .where('user_id', isEqualTo: userId)
          .get();
      
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
          destacado: data['destacado'] ?? false,
          userId: data['userId'] ?? '',
          visibility: data['visibility'] ?? 'public',
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




  void _editarRestaurante(String restauranteId) {
    Navigator.pushNamed(
      context, 
      '/perfil/restaurantes/edit/$restauranteId'
    );
  }

  void _agregarRestaurante() {
    Navigator.pushNamed(
      context, 
      '/perfil/restaurantes/create'
    );
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
        title: const Text("Mis Restaurantes"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {

            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _agregarRestaurante,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header informativo
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    color: const Color(0xFFFF6A00).withOpacity(0.1),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Color(0xFFFF6A00)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Gestiona tus ${restaurantes.length} restaurante${restaurantes.length != 1 ? 's' : ''}",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Barra de búsqueda
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar en mis restaurantes...',
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
                ),
                
                const SizedBox(height: 4),
                
                // Lista de restaurantes
                Expanded(
                  child: filteredList.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.restaurant,
            size: 80,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            "No tienes restaurantes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Agrega tu primer restaurante para comenzar",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _agregarRestaurante,
            icon: const Icon(Icons.add),
            label: const Text("Agregar Restaurante"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
            ),
          ),
        ],
      ),
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
                // Imagen del restaurante
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
                // Badge de visibilidad
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: r.visibility == 'publico' ? Colors.green : Colors.blueGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.visibility == 'publico' ? 'Público' : 'Privado',
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
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _editarRestaurante(r.id),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text("Editar"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
              ],
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