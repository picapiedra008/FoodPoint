import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabores de Mi Tierra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFE91E63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFE91E63),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        toggleDarkMode: _toggleDarkMode,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

// Modelo de datos para platos
class Dish {
  final String name;
  final String description;
  final double rating;
  final int restaurantCount;
  final double distance; // en kilómetros
  final String category;

  Dish({
    required this.name,
    required this.description,
    required this.rating,
    required this.restaurantCount,
    required this.distance,
    required this.category,
  });
}

class _HomePageState extends State<HomePage> {
  final String _location = 'Cochabamba - Bolivia';
  String _dateTime = '';
  String _temperature = '--';
  String _weatherIcon = '';
  bool _isLoadingWeather = false;
  
  // Búsqueda y filtros
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  String _searchQuery = '';
  int _resultCount = 0; // 0 significa sin límite
  
  // Lista de platos disponibles
  final List<Dish> _allDishes = [
    Dish(name: 'Pique Macho', description: 'Plato típico con carne, papas y verduras', rating: 4.8, restaurantCount: 15, distance: 0.5, category: 'Almuerzo'),
    Dish(name: 'Salteña Paceña', description: 'La salteña más auténtica de La Paz', rating: 4.9, restaurantCount: 12, distance: 0.8, category: 'Desayuno'),
    Dish(name: 'Chuleta de Cerdo', description: 'Chuleta jugosa con papas fritas', rating: 4.7, restaurantCount: 20, distance: 1.2, category: 'Almuerzo'),
    Dish(name: 'Sopa de Maní', description: 'Sopa tradicional boliviana', rating: 4.6, restaurantCount: 18, distance: 0.3, category: 'Almuerzo'),
    Dish(name: 'Silpancho', description: 'Carne empanizada con arroz y huevo', rating: 4.9, restaurantCount: 25, distance: 0.6, category: 'Almuerzo'),
    Dish(name: 'Fricase', description: 'Plato tradicional con carne de cerdo', rating: 4.8, restaurantCount: 10, distance: 1.5, category: 'Almuerzo'),
    Dish(name: 'Ají de Fideo', description: 'Fideos con ají y carne', rating: 4.5, restaurantCount: 14, distance: 0.9, category: 'Almuerzo'),
    Dish(name: 'Pollo a la Broaster', description: 'Pollo crujiente con papas', rating: 4.7, restaurantCount: 22, distance: 1.1, category: 'Almuerzo'),
    Dish(name: 'Tucumana', description: 'Empanada frita rellena', rating: 4.6, restaurantCount: 16, distance: 0.4, category: 'Desayuno'),
    Dish(name: 'Lawa', description: 'Sopa espesa de maíz', rating: 4.4, restaurantCount: 8, distance: 1.8, category: 'Almuerzo'),
    Dish(name: 'Chairo', description: 'Sopa de chuño y carne', rating: 4.7, restaurantCount: 12, distance: 0.7, category: 'Almuerzo'),
    Dish(name: 'Anticucho', description: 'Brochetas de corazón de res', rating: 4.8, restaurantCount: 19, distance: 1.0, category: 'Cena'),
  ];
  
  // TODO: Reemplaza con tu API key de OpenWeatherMap
  // Obtén tu API key gratis en: https://openweathermap.org/api
  static const String _apiKey = 'TU_API_KEY_AQUI';
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5/weather';
  
  @override
  void dispose() {
    _searchController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _startTimer();
    _fetchWeather();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final dayOfWeek = dayNames[now.weekday == 7 ? 0 : now.weekday - 1];
    final day = now.day.toString().padLeft(2, '0');
    final month = monthNames[now.month - 1];
    final year = now.year.toString().substring(2);
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final formattedDate = '$dayOfWeek $day-$month-$year @ $hour:$minute';
    setState(() {
      _dateTime = formattedDate;
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        _updateDateTime();
        _startTimer();
      }
    });
  }

  Future<void> _fetchWeather() async {
    // Si no tienes API key, usa datos de ejemplo
    if (_apiKey == 'TU_API_KEY_AQUI') {
      setState(() {
        _temperature = '24';
        _weatherIcon = '☀️';
        _isLoadingWeather = false;
      });
      return;
    }

    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // Obtener ubicación actual
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Servicio de ubicación deshabilitado');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Permisos de ubicación denegados permanentemente');
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );

      // Hacer petición a OpenWeatherMap
      final url = Uri.parse(
        '$_baseUrl?lat=${position.latitude}&lon=${position.longitude}&appid=$_apiKey&units=metric&lang=es',
      );

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al obtener el clima');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['main']['temp'].round().toString();
        final weatherMain = data['weather'][0]['main'].toLowerCase();
        final weatherIcon = _getWeatherIcon(weatherMain);

        setState(() {
          _temperature = temp;
          _weatherIcon = weatherIcon;
          _isLoadingWeather = false;
        });
      } else {
        throw Exception('Error al obtener el clima: ${response.statusCode}');
      }
    } catch (e) {
      // En caso de error, usar datos de ejemplo
      setState(() {
        _temperature = '24';
        _weatherIcon = '☀️';
        _isLoadingWeather = false;
      });
    }
  }

  String _getWeatherIcon(String weatherMain) {
    switch (weatherMain) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  List<Dish> get _filteredDishes {
    List<Dish> result;
    
    if (_searchQuery.isEmpty) {
      // Sin búsqueda: los más cercanos, al azar si no hay límite
      result = List<Dish>.from(_allDishes);
      if (_resultCount == 0) {
        // Al azar pero ordenados por distancia
        result.shuffle();
        result.sort((a, b) => a.distance.compareTo(b.distance));
      } else {
        // Ordenados por distancia (más cercanos primero)
        result.sort((a, b) => a.distance.compareTo(b.distance));
        result = result.take(_resultCount).toList();
      }
    } else {
      // Con búsqueda: filtrar y ordenar por distancia (más cercano al más lejano)
      result = _allDishes.where((dish) {
        return dish.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               dish.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               dish.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      result.sort((a, b) => a.distance.compareTo(b.distance));
      if (_resultCount > 0) {
        result = result.take(_resultCount).toList();
      }
    }
    
    return result;
  }

  // Método para obtener tamaños responsivos
  double _getResponsiveSize(BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return desktop;
    if (width > 600) return tablet;
    return mobile;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isDesktop = screenWidth > 1200;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(isTablet, isDesktop),
          Expanded(
            child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isDesktop) {
    final logoSize = _getResponsiveSize(
      context,
      mobile: 40.0,
      tablet: 50.0,
      desktop: 60.0,
    );

    final fontSizeLocation = _getResponsiveSize(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );

    final fontSizeDateTime = _getResponsiveSize(
      context,
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );

    final fontSizeTemp = _getResponsiveSize(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    final fontSizeAppName = _getResponsiveSize(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final iconSize = _getResponsiveSize(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 24.0),
        vertical: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 16.0),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo and icons row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo on the left
              Image.asset(
                widget.isDarkMode 
                    ? 'assets/images/logos/logo2.png' 
                    : 'assets/images/logos/logo.png',
                height: logoSize,
                width: logoSize,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.restaurant,
                    size: logoSize,
                    color: Theme.of(context).colorScheme.secondary,
                  );
                },
              ),
              const Spacer(),
              // Icons on the right
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.settings, size: iconSize),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Ajustes')),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: iconSize,
                    ),
                    color: Theme.of(context).colorScheme.onSurface,
                    onPressed: widget.toggleDarkMode,
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
          // Location, weather and date/time centered
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Location and Weather
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.secondary,
                      size: iconSize,
                    ),
                    SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                    Text(
                      _location,
                      style: TextStyle(
                        fontSize: fontSizeLocation,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(width: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                    // Weather
                    _isLoadingWeather
                        ? SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          )
                        : Text(
                            _weatherIcon,
                            style: TextStyle(fontSize: iconSize),
                          ),
                    SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                    Text(
                      '$_temperature°C',
                      style: TextStyle(
                        fontSize: fontSizeTemp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                // Date and Time
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      color: Theme.of(context).colorScheme.primary,
                      size: iconSize * 0.9,
                    ),
                    SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                    Text(
                      _dateTime,
                      style: TextStyle(
                        fontSize: fontSizeDateTime,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
          // App name centered at the bottom
          Center(
            child: Text(
              'Sabores de Mi Tierra',
              style: TextStyle(
                fontSize: fontSizeAppName,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    final fontSize = _getResponsiveSize(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    return Row(
      children: [
        // Nav
        Container(
          width: _getResponsiveSize(context, mobile: 200.0, tablet: 220.0, desktop: 250.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? const Color(0xFF2D1F24) 
                : const Color(0xFFFFE0E6),
          ),
          padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
          child: _buildNav(),
        ),
        // Main content area
        Expanded(
          child: Row(
            children: [
              // Main
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode 
                        ? const Color(0xFF1A1A1A) 
                        : const Color(0xFFFFF5F5),
                  ),
                  padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                  child: _buildDishOfTheDay(),
                ),
              ),
              // Aside
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode 
                        ? const Color(0xFF2D1F24) 
                        : const Color(0xFFFFCCD5),
                  ),
                  padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                  child: _buildAside(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final fontSize = _getResponsiveSize(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    return Column(
      children: [
        // Main
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDarkMode 
                  ? const Color(0xFF1A1A1A) 
                  : const Color(0xFFFFF5F5),
            ),
            padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
            child: _buildDishOfTheDay(),
          ),
        ),
        // Nav
        Container(
          width: double.infinity,
          height: _getResponsiveSize(context, mobile: 120.0, tablet: 140.0, desktop: 160.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? const Color(0xFF2D1F24) 
                : const Color(0xFFFFE0E6),
          ),
          padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
          child: _buildNav(),
        ),
        // Aside
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDarkMode 
                  ? const Color(0xFF2D1F24) 
                  : const Color(0xFFFFCCD5),
            ),
            padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
            child: _buildAside(),
          ),
        ),
        // Footer
        Container(
          width: double.infinity,
          height: _getResponsiveSize(context, mobile: 70.0, tablet: 80.0, desktop: 90.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? const Color(0xFF1A1A1A) 
                : const Color(0xFFFFF5F5),
          ),
          padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
          child: Center(
            child: Text(
              'Footer',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDishOfTheDay() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    
    final titleFontSize = _getResponsiveSize(
      context,
      mobile: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );

    final descriptionFontSize = _getResponsiveSize(
      context,
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );

    final infoFontSize = _getResponsiveSize(
      context,
      mobile: 11.0,
      tablet: 13.0,
      desktop: 15.0,
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Recomendado Hoy" header
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Theme.of(context).colorScheme.secondary,
                size: _getResponsiveSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
              ),
              SizedBox(width: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
              Text(
                'Recomendado Hoy',
                style: TextStyle(
                  fontSize: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
          // Dish card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image with "Plato del Día" tag
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/media/desserts/salteña.png',
                        width: double.infinity,
                        height: _getResponsiveSize(context, mobile: 200.0, tablet: 300.0, desktop: 400.0),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: _getResponsiveSize(context, mobile: 200.0, tablet: 300.0, desktop: 400.0),
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.image_not_supported, size: 50),
                            ),
                          );
                        },
                      ),
                    ),
                    // "Plato del Día" tag
                    Positioned(
                      top: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                      left: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                          vertical: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Plato del Día',
                          style: TextStyle(
                            fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Dish information
                Padding(
                  padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Dish name
                      Text(
                        'Salteña Paceña',
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                      // Description
                      Text(
                        'La salteña más auténtica de La Paz, con carne jugosa, papa, huevo duro,...',
                        style: TextStyle(
                          fontSize: descriptionFontSize,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      SizedBox(height: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                      // Restaurant count, rating and button
                      Row(
                        children: [
                          // Restaurant count
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                              Text(
                                '12 restaurantes',
                                style: TextStyle(
                                  fontSize: infoFontSize,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                          // Rating
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                                color: Colors.amber,
                              ),
                              SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                              Text(
                                '4.9',
                                style: TextStyle(
                                  fontSize: infoFontSize,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          // View Restaurant button
                          ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Ver Restaurante')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                horizontal: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                                vertical: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Ver Restaurante',
                              style: TextStyle(
                                fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                              ),
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
        ],
      ),
    );
  }

  Widget _buildNav() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Search bar
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar platos ...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Colors.grey[600],
                size: _getResponsiveSize(context, mobile: 20.0, tablet: 22.0, desktop: 24.0),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                vertical: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
              ),
            ),
            style: TextStyle(
              fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
        // Count input
        Row(
          children: [
            Text(
              'Cantidad:',
              style: TextStyle(
                fontSize: _getResponsiveSize(context, mobile: 11.0, tablet: 13.0, desktop: 15.0),
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(width: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _countController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: 'Sin límite',
                    hintStyle: TextStyle(
                      color: Colors.grey[400],
                      fontSize: _getResponsiveSize(context, mobile: 11.0, tablet: 13.0, desktop: 15.0),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
                      vertical: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, mobile: 11.0, tablet: 13.0, desktop: 15.0),
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _resultCount = int.tryParse(value) ?? 0;
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAside() {
    final dishes = _filteredDishes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Catálogo de Platos',
          style: TextStyle(
            fontSize: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
        // Dishes list
        Expanded(
          child: dishes.isEmpty
              ? Center(
                  child: Text(
                    'No se encontraron platos',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: dishes.length,
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    return Card(
                      margin: EdgeInsets.only(
                        bottom: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dish.name,
                                    style: TextStyle(
                                      fontSize: _getResponsiveSize(context, mobile: 13.0, tablet: 15.0, desktop: 17.0),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
                                    vertical: _getResponsiveSize(context, mobile: 2.0, tablet: 4.0, desktop: 6.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    dish.category,
                                    style: TextStyle(
                                      fontSize: _getResponsiveSize(context, mobile: 9.0, tablet: 11.0, desktop: 13.0),
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                            Text(
                              dish.description,
                              style: TextStyle(
                                fontSize: _getResponsiveSize(context, mobile: 11.0, tablet: 13.0, desktop: 15.0),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: _getResponsiveSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                                Text(
                                  '${dish.distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                                Icon(
                                  Icons.star,
                                  size: _getResponsiveSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                                  color: Colors.amber,
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                                Text(
                                  dish.rating.toString(),
                                  style: TextStyle(
                                    fontSize: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${dish.restaurantCount} rest.',
                                  style: TextStyle(
                                    fontSize: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
