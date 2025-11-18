import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class RestaurantFormPage extends StatefulWidget {
  final String? initialName;
  final String? initialLocation;
  final String? initialDescription;
  final String? initialSchedule;
  final String? initialLogoUrl;
  final VoidCallback? onBack;
  final ValueChanged<Map<String, dynamic>>? onSave;

  const RestaurantFormPage({
    Key? key,
    this.initialName,
    this.initialLocation,
    this.initialDescription,
    this.initialSchedule,
    this.initialLogoUrl,
    this.onBack,
    this.onSave,
  }) : super(key: key);

  @override
  State<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _scheduleController;
  
  File? _logoImage;
  final MapController _mapController = MapController();
    final List<Marker> _markers = [];
  LatLng? _selectedLocation;
 

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _descriptionController = TextEditingController(text: widget.initialDescription ?? '');
    _scheduleController = TextEditingController(text: widget.initialSchedule ?? '');
    
    // Si hay una ubicación inicial, convertirla a LatLng
    if (widget.initialLocation != null) {
      _parseInitialLocation(widget.initialLocation!);
    }
  }

  void _parseInitialLocation(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          _selectedLocation = LatLng(lat, lng);
          _addMarker(_selectedLocation!);
        }
      }
    } catch (e) {
      print('Error parsing location: $e');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _scheduleController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final location = _selectedLocation != null 
          ? '${_selectedLocation!.latitude},${_selectedLocation!.longitude}'
          : '';
          
      widget.onSave?.call({
        'name': _nameController.text,
        'location': location,
        'description': _descriptionController.text,
        'schedule': _scheduleController.text,
        'logo': _logoImage,
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _logoImage = File(pickedFile.path);
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
      _markers.clear();
      _addMarker(latLng);
    });
  }

 void _addMarker(LatLng location) {
  _markers.add(
    Marker(
      point: location,
      width: 40,
      height: 40,
      builder: (context) => const Icon(
        Icons.location_pin,
        color: Colors.red,
        size: 40,
      ),
    ),
  );
}

Widget _buildMap() {
  return Container(
    height: 200,
    decoration: BoxDecoration(
      border: Border.all(color: Colors.grey),
      borderRadius: BorderRadius.circular(4),
    ),
    child: FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        center: _selectedLocation ?? LatLng(-17.397248, -66.161288), // Cochabamba
        zoom: 12.0,
        onTap: _onMapTapped,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.umssmovilaprogramming.foodpoint',
        ),
        MarkerLayer(
          markers: _markers,
        ),
      ],
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear/Editar Restaurante'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el nombre' : null,
              ),
              SizedBox(height: 16),
              
              // Mapa con flutter_map
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ubicación (Selecciona en el mapa)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildMap(),
                  SizedBox(height: 8),
                  if (_selectedLocation != null)
                    Text(
                      'Ubicación seleccionada: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese la descripción' : null,
              ),
              SizedBox(height: 16),
              
              TextFormField(
                controller: _scheduleController,
                decoration: InputDecoration(
                  labelText: 'Horario',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Ingrese el horario' : null,
              ),
              SizedBox(height: 16),
              
              // Selector de imagen para el logo
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Logo/Foto',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: Text('Seleccionar Imagen'),
                      ),
                      SizedBox(width: 16),
                      if (_logoImage != null)
                        Expanded(
                          child: Text(
                            'Imagen seleccionada',
                            style: TextStyle(color: Colors.green),
                          ),
                        ),
                    ],
                  ),
                  if (_logoImage != null) ...[
                    SizedBox(height: 8),
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.file(
                        _logoImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                      child: Text('Volver'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _handleSave,
                      child: Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}