# Configuración de OpenWeatherMap

## Cómo obtener tu API Key

1. Ve a https://openweathermap.org/api
2. Crea una cuenta gratuita (si no tienes una)
3. Después de registrarte, ve a la sección "API keys" en tu dashboard
4. Copia tu API key (puede tardar unos minutos en activarse)
5. En `lib/main.dart`, busca la línea:
   ```dart
   static const String _apiKey = 'TU_API_KEY_AQUI';
   ```
6. Reemplaza `'TU_API_KEY_AQUI'` con tu API key real

## Nota importante

- La API key gratuita tiene límites: 60 llamadas por minuto, 1,000,000 por mes
- Si no configuras la API key, la app usará datos de ejemplo (24°C, ☀️)
- La app solicitará permisos de ubicación para obtener el clima basado en tu posición actual

## Permisos necesarios

### Android
En `android/app/src/main/AndroidManifest.xml`, asegúrate de tener:
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS
En `ios/Runner/Info.plist`, añade:
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Necesitamos tu ubicación para mostrar el clima actual</string>
```




