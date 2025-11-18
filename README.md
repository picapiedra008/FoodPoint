# Food Point System

## Estructura de carpetas

```
lib
├─┬─ ui
│ ├─┬─ core
│ │ ├─┬─ ui
│ │ │ └─── <shared widgets>
│ │ └─── themes
│ └─┬─ <FEATURE NAME>
│   ├─┬─ view_model
│   │ └─── <view_model class>.dart
│   └─┬─ widgets
│     ├── <feature name>_screen.dart
│     └── <other widgets>
├─┬─ domain
│ └─┬─ models
│   └─── <model name>.dart
├─┬─ data
│ ├─┬─ repositories
│ │ └─── <repository class>.dart
│ ├─┬─ services
│ │ └─── <service class>.dart
│ └─┬─ model
│   └─── <api model class>.dart
├─── config
├─── utils
├─── routing
├─── main_staging.dart
├─── main_development.dart
└─── main.dart

// The test folder contains unit and widget tests
test
├─── data
├─── domain
├─── ui
└─── utils

// The testing folder contains mocks other classes need to execute tests
testing
├─── fakes
└─── models
```

---

## 🧩 Descripción de carpetas

### 🖼️ **ui/**

Contiene la **capa de presentación** del proyecto (todo lo que el usuario ve e interactúa).

- **`core/ui/`** → Widgets reutilizables en toda la aplicación (botones, inputs, loaders, etc.).
- **`core/themes/`** → Archivos de configuración de temas, colores y tipografías globales.
- **`<FEATURE NAME>/view_model/`** → Clases que manejan el estado y la lógica de presentación de cada funcionalidad.
- **`<FEATURE NAME>/widgets/`** → Pantallas principales (`_screen.dart`) y widgets específicos de ese feature.

---

### ⚙️ **domain/**

Define la **lógica de negocio pura**, sin depender de frameworks ni de infraestructura.

- **`models/`** → Modelos o entidades del dominio. Representan los datos y reglas del negocio.

---

### 🧠 **data/**

Capa responsable de la **obtención, almacenamiento y envío de datos** (API, base de datos local, etc.).

- **`repositories/`** → Clases que gestionan la comunicación entre el dominio y los servicios.
- **`services/`** → Clases que interactúan directamente con APIs o fuentes externas de datos.
- **`model/`** → Modelos de datos usados en las respuestas o solicitudes a APIs (con serialización JSON).

---

### ⚙️ **config/**

Configuraciones globales del proyecto:
variables de entorno, inyección de dependencias, configuración de APIs, etc.

---

### 🧰 **utils/**

Funciones o clases de utilidad compartidas en toda la aplicación:
formateadores, validadores, conversores, manejo de fechas, etc.

---

### 🧭 **routing/**

Definición de rutas y navegación entre pantallas.
Puede incluir configuración de `GoRouter`, `AutoRoute` u otro gestor de rutas.

---

### 🚀 **main.dart**, **main_staging.dart**, **main_development.dart**

Puntos de entrada de la aplicación según el entorno:

- `main.dart` → producción
- `main_staging.dart` → pruebas intermedias
- `main_development.dart` → entorno de desarrollo

Cada uno puede configurar endpoints, temas o dependencias distintas.

---

## 🧪 **Carpetas de pruebas**

### **test/**

Contiene las pruebas **unitarias y de widgets**, organizadas de forma similar al código fuente:

- `data/` → Pruebas para repositorios, servicios y modelos de datos.
- `domain/` → Pruebas de lógica de negocio y modelos del dominio.
- `ui/` → Pruebas de widgets y `view_models`.
- `utils/` → Pruebas para funciones o clases utilitarias.

---

### **testing/**

Incluye recursos usados **para ejecutar pruebas** (fakes, mocks, datos de ejemplo).

- `fakes/` → Clases falsas que simulan servicios o repositorios reales durante los tests.
- `models/` → Modelos o datos estáticos de prueba (por ejemplo, objetos con información simulada).
