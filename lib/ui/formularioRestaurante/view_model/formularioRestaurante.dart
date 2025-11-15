import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:food_point/ui/listar_restaurantes/view_model/listar_restaurantes_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

class RestaurantFormPage extends StatefulWidget {
  final String? restaurantId;

  const RestaurantFormPage({
    Key? key,
    this.restaurantId,
  }) : super(key: key);

  @override
  State<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  String user_id = "user1";// Cuando este listo el login, deben poner el metodo para obtener el id del usuario logeado

  File? _logoImage;
  String? _logoBase64;
  LatLng? _selectedLocation;
  final List<Marker> _markers = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _foods = [];
  
  List<Map<String, dynamic>> _openingHours = [];
  String _restaurantVisibility = 'publico';

  // Nombres de los días
  final List<String> _dayNames = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
  final List<String> _fullDayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

  @override
  void initState() {
    super.initState();
    
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _foods = [];
    _openingHours = [];

    if (widget.restaurantId != null) {
      _loadRestaurantData();
    } else {
      _addOpeningHour();
    }
  }

  // Widget para selección de días con botones
  Widget _buildDaySelector(List<bool> days, Function(int) onDaySelected) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Días:'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(7, (index) {
            return FilterChip(
              label: Text(_dayNames[index]),
              selected: days[index],
              onSelected: (selected) => onDaySelected(index),
              showCheckmark: false,
            );
          }),
        ),
      ],
    );
  }

  void _addOpeningHour() {
    setState(() {
      _openingHours.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'openingTime': TimeOfDay(hour: 8, minute: 0),
        'closingTime': TimeOfDay(hour: 22, minute: 0),
        'days': List.generate(7, (_) => false), // 7 días de la semana
        'visibility': 'publico',
      });
    });
  }

  void _removeOpeningHour(int index) {
    setState(() {
      _openingHours.removeAt(index);
    });
  }

  bool _hasDayOverlap(List<bool> days1, List<bool> days2) {
    for (int i = 0; i < 7; i++) {
      if (days1[i] && days2[i]) {
        return true;
      }
    }
    return false;
  }

  String? _validateOpeningHours() {
    if (_openingHours.isEmpty) {
      return 'Debe haber al menos un horario';
    }

    for (int i = 0; i < _openingHours.length; i++) {
      final hour = _openingHours[i];
      if (!hour['days'].contains(true)) {
        return 'El horario ${i + 1} debe tener al menos un día seleccionado';
      }
    }

    for (int i = 0; i < _openingHours.length; i++) {
      for (int j = i + 1; j < _openingHours.length; j++) {
        if (_hasDayOverlap(_openingHours[i]['days'], _openingHours[j]['days'])) {
          return 'Los horarios ${i + 1} y ${j + 1} tienen días que se solapan';
        }
      }
    }

    return null;
  }

  Future<void> _selectTimeForHour(int hourIndex, bool isOpening) async {
    final currentTime = isOpening 
        ? _openingHours[hourIndex]['openingTime'] 
        : _openingHours[hourIndex]['closingTime'];
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay(hour: 8, minute: 0),
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingHours[hourIndex]['openingTime'] = picked;
        } else {
          _openingHours[hourIndex]['closingTime'] = picked;
        }
      });
    }
  }

  Widget _buildOpeningHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Horarios de Atención'),
            ElevatedButton.icon(
              onPressed: _addOpeningHour,
              icon: const Icon(Icons.add),
              label: const Text('Añadir Horario'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        for (int i = 0; i < _openingHours.length; i++) 
          _buildOpeningHourCard(i),
      ],
    );
  }

  Widget _buildOpeningHourCard(int index) {
    final hour = _openingHours[index];
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Horario ${index + 1}'),
                if (_openingHours.length > 1)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _removeOpeningHour(index),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Selector de días
            _buildDaySelector(
              hour['days'],
              (dayIndex) {
                setState(() {
                  _openingHours[index]['days'][dayIndex] = 
                      !_openingHours[index]['days'][dayIndex];
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Horas
            Row(
              children: [
                Expanded(
                  child: _buildTimePickerForHour(
                    'Apertura',
                    hour['openingTime'],
                    index,
                    true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimePickerForHour(
                    'Cierre',
                    hour['closingTime'],
                    index,
                    false,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
           
          ],
        ),
      ),
    );
  }

  Widget _buildTimePickerForHour(String label, TimeOfDay? currentTime, int hourIndex, bool isOpening) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTime != null 
                  ? '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}'
                  : 'Seleccionar',
              ),
              IconButton(
                icon: const Icon(Icons.access_time, size: 20),
                onPressed: () => _selectTimeForHour(hourIndex, isOpening),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _addFood() {
    setState(() {
      _foods.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': '',
        'description': '',
        'days': List.generate(7, (_) => false),
        'category': 'cualquiera',
        'visibility': 'publico',
        'imageFile': null,
        'imageBase64': null,
      });
    });
  }

  void _removeFood(int index) {
    setState(() {
      _foods.removeAt(index);
    });
  }

  Widget _buildFoodForm(int index) {
    final food = _foods[index];
    final nameController = TextEditingController(text: food['name'] ?? '');
    final descriptionController = TextEditingController(text: food['description'] ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Plato ${index + 1}'),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _removeFood(index),
                ),
              ],
            ),
            
            _buildFoodImageSection(index),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del plato *',
              ),
              maxLength: 150,
              onChanged: (v) => _foods[index]['name'] = v,
              validator: (v) => v == null || v.isEmpty ? 'Ingrese el nombre del plato' : null,
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Descripción',
              ),
              maxLines: 3,
              onChanged: (v) => _foods[index]['description'] = v,
            ),
            const SizedBox(height: 12),
            
            // Días disponibles con botones
            _buildDaySelector(
              food['days'],
              (dayIndex) {
                setState(() {
                  _foods[index]['days'][dayIndex] = !_foods[index]['days'][dayIndex];
                });
              },
            ),
            const SizedBox(height: 12),
            
            // Categoría y visibilidad
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: food['category'],
                    decoration: const InputDecoration(
                      labelText: 'Categoría',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'desayuno', child: Text('Desayuno')),
                      DropdownMenuItem(value: 'almuerzo', child: Text('Almuerzo')),
                      DropdownMenuItem(value: 'cena', child: Text('Cena')),
                      DropdownMenuItem(value: 'cualquiera', child: Text('Cualquiera')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _foods[index]['category'] = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: food['visibility'],
                    decoration: const InputDecoration(
                      labelText: 'Visibilidad',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'publico', child: Text('Público')),
                      DropdownMenuItem(value: 'oculto', child: Text('Oculto')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _foods[index]['visibility'] = value;
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadRestaurantData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot restaurantDoc = await db.collection('restaurants').doc(widget.restaurantId!).get();

      if (restaurantDoc.exists) {
        var data = restaurantDoc.data() as Map<String, dynamic>;
        
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _logoBase64 = data['logoBase64'];
          _restaurantVisibility = data['visibility'] ?? 'publico';
          
          if (data['openingHours'] != null) {
            _openingHours = List<Map<String, dynamic>>.from(data['openingHours']).map((hour) {
              return {
                'id': hour['id'],
                'openingTime': _stringToTimeOfDay(hour['openingTime']),
                'closingTime': _stringToTimeOfDay(hour['closingTime']),
                'days': List<bool>.from(hour['days'] ?? List.generate(7, (_) => false)),
                'visibility': hour['visibility'] ?? 'publico',
              };
            }).toList();
          }
          
          if (data['location'] != null) {
            _parseInitialLocation(data['location']);
          }
        });

        await _loadRestaurantFoods();
      }
    } catch (e) {
      print('Error al cargar datos del restaurante: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRestaurantFoods() async {
    try {
      QuerySnapshot foodsSnapshot = await db
          .collection('foods')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      List<Map<String, dynamic>> loadedFoods = [];
      
      for (var doc in foodsSnapshot.docs) {
        var foodData = doc.data() as Map<String, dynamic>;
        loadedFoods.add({
          'id': doc.id,
          'name': foodData['name'] ?? '',
          'description': foodData['description'] ?? '',
          'days': List<bool>.from(foodData['days'] ?? List.generate(7, (_) => false)),
          'category': foodData['category'] ?? 'cualquiera',
          'visibility': foodData['visibility'] ?? 'publico',
          'imageBase64': foodData['imageBase64'] ?? '',
        });
      }

      setState(() {
        _foods = loadedFoods;
      });
    } catch (e) {
      print('Error al cargar platos: $e');
    }
  }

  TimeOfDay _stringToTimeOfDay(String timeString) {
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
    return TimeOfDay(hour: 0, minute: 0);
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _saveOrUpdateRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    final hoursError = _validateOpeningHours();
    if (hoursError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(hoursError)),
      );
      return;
    }

    final isEditing = widget.restaurantId != null;

    if (isEditing) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Guardar Cambios"),
          content: const Text("¿Estás seguro de que quieres guardar los cambios realizados?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Guardar"),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final location = _selectedLocation != null
          ? '${_selectedLocation!.latitude},${_selectedLocation!.longitude}'
          : '';

      String? logoBase64;
      if (_logoImage != null) {
        final bytes = await _logoImage!.readAsBytes();
        logoBase64 = base64Encode(bytes);
      } else if (_logoBase64 != null) {
        logoBase64 = _logoBase64;
      }

      final openingHoursData = _openingHours.map((hour) {
        return {
          'id': hour['id'],
          'openingTime': _timeOfDayToString(hour['openingTime']),
          'closingTime': _timeOfDayToString(hour['closingTime']),
          'days': hour['days'],
        };
      }).toList();

      final restaurantData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': location,
        'visibility': _restaurantVisibility,
        'openingHours': openingHoursData,
        'updatedAt': FieldValue.serverTimestamp(),
        'userId': user_id,
      };

      if (logoBase64 != null) {
        restaurantData['logoBase64'] = logoBase64;
      }

      String restaurantId;
      String message;

      if (isEditing) {
        restaurantId = widget.restaurantId!;
        await db.collection('restaurants').doc(restaurantId).update(restaurantData);
        await _replaceAllFoods(restaurantId);
        message = 'Restaurante actualizado exitosamente';
      } else {
        restaurantData['createdAt'] = FieldValue.serverTimestamp();
        DocumentReference docRef = await db.collection('restaurants').add(restaurantData);
        restaurantId = docRef.id;
        await _createFoods(restaurantId);
        message = 'Restaurante creado exitosamente';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/perfil/restaurantes',
          (route) => false,
        );
      }

    } catch (e) {
      print('Error al guardar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _replaceAllFoods(String restaurantId) async {
    try {
      QuerySnapshot existingFoods = await db
          .collection('foods')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      WriteBatch batch = db.batch();
      for (var doc in existingFoods.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await _createFoods(restaurantId);
      
    } catch (e) {
      print('Error al reemplazar platos: $e');
      throw e;
    }
  }

  Future<void> _createFoods(String restaurantId) async {
    try {
      for (var food in _foods) {
        String? imageBase64;
        
        if (food['imageFile'] != null) {
          final bytes = await (food['imageFile'] as File).readAsBytes();
          imageBase64 = base64Encode(bytes);
        } else if (food['imageBase64'] != null) {
          imageBase64 = food['imageBase64'];
        }

        final foodData = {
          'restaurantId': restaurantId,
          'name': food['name']?.toString().trim() ?? '',
          'description': food['description']?.toString().trim() ?? '',
          'days': food['days'],
          'category': food['category'],
          'visibility': food['visibility'],
          'createdAt': FieldValue.serverTimestamp(),
        };

        if (imageBase64 != null) {
          foodData['imageBase64'] = imageBase64;
        }

        await db.collection('foods').add(foodData);
      }
    } catch (e) {
      print('Error al crear platos: $e');
      throw e;
    }
  }


  Future<void> _pickImage({bool isLogo = true, int? foodIndex}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = File(pickedFile.path);
          _logoBase64 = null;
        } else if (foodIndex != null) {
          _foods[foodIndex]['imageFile'] = File(pickedFile.path);
          _foods[foodIndex]['imageBase64'] = null;
        }
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _addMarker(location);
    });
  }

  void _addMarker(LatLng location) {
    _markers.add(
      Marker(
        point: location,
        width: 40,
        height: 40,
        builder: (_) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
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
          center: _selectedLocation ?? const LatLng(-17.397248, -66.161288),
          zoom: 12.0,
          onTap: _onMapTapped,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.foodapp.restaurant',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: _logoImage != null
              ? Image.file(_logoImage!, fit: BoxFit.cover)
              : _logoBase64 != null && _logoBase64!.isNotEmpty
                  ? Image.memory(
                      base64Decode(_logoBase64!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.restaurant, size: 60);
                      },
                    )
                  : const Icon(Icons.restaurant, size: 60),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _pickImage(),
          icon: const Icon(Icons.photo_library),
          label: const Text('Seleccionar Logo'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFoodImageSection(int index) {
    final food = _foods[index];
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: food['imageFile'] != null
              ? Image.file(food['imageFile']!, fit: BoxFit.cover)
              : food['imageBase64'] != null && food['imageBase64'].isNotEmpty
                  ? Image.memory(
                      base64Decode(food['imageBase64']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.fastfood, size: 40);
                      },
                    )
                  : const Icon(Icons.fastfood, size: 40),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () => _pickImage(isLogo: false, foodIndex: index),
          icon: const Icon(Icons.photo_library),
          label: const Text('Seleccionar Imagen del Plato'),
        ),
      ],
    );
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
          _mapController.move(_selectedLocation!, 15.0);
        }
      }
    } catch (e) {
      print('Error parsing location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.restaurantId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Restaurante' : 'Crear Restaurante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildLogoSection(),

                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del restaurante *',
                      ),
                      maxLength: 120,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese el nombre' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                      ),
                      maxLines: 3,
                      maxLength: 500,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese la descripción' : null,
                    ),
                    const SizedBox(height: 16),

                    const Text('Ubicación en mapa'),
                    const SizedBox(height: 8),
                    _buildMap(),
                    const SizedBox(height: 8),
                    if (_selectedLocation != null)
                      Text(
                        '(${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                        '${_selectedLocation!.longitude.toStringAsFixed(4)})',
                      ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      value: _restaurantVisibility,
                      decoration: const InputDecoration(
                        labelText: 'Visibilidad del Restaurante',
                      ),
                      items: const [
                        DropdownMenuItem(value: 'publico', child: Text('Público')),
                        DropdownMenuItem(value: 'oculto', child: Text('Oculto')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _restaurantVisibility = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildOpeningHoursSection(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Platos'),
                        ElevatedButton.icon(
                          onPressed: _addFood,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir Plato'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_foods.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text('No hay platos añadidos aún'),
                        ),
                      ),
                    
                    for (int i = 0; i < _foods.length; i++) _buildFoodForm(i),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveOrUpdateRestaurant,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Actualizar' : 'Guardar'),
                    ),

                    if (isEditing) ...[
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _confirmarEliminacion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Eliminar Restaurante"),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _confirmarEliminacion() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar Eliminación"),
        content: const Text("¿Estás seguro de que quieres eliminar este restaurante? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _eliminarRestaurante();
    }
  }

  Future<void> _eliminarRestaurante() async {
    if (widget.restaurantId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final foodsSnapshot = await db
          .collection('foods')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      WriteBatch batch = db.batch();
      for (var doc in foodsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      await db.collection('restaurants').doc(widget.restaurantId!).delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Restaurante eliminado exitosamente")),
        );
      }

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/perfil/restaurantes',
          (route) => false,
        );
      }

    } catch (e) {
      print('Error al eliminar restaurante: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al eliminar: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}