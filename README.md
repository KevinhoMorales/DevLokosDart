# DevLokos Podcast App

Una aplicación móvil moderna para el podcast DevLokos, desarrollada con Flutter y Firebase. La aplicación permite a los usuarios registrarse, iniciar sesión y explorar episodios del podcast con reproducción integrada de YouTube.

## 🚀 Características Principales

### 🔐 **Sistema de Autenticación Completo**
- **Registro de usuario** con email y contraseña
- **Inicio de sesión** seguro con validaciones
- **Recuperación de contraseña** por email
- **Gestión de sesiones** con Firebase Auth
- **Validaciones** de formularios en tiempo real

### 📱 **Gestión de Episodios**
- **Lista de episodios** obtenida desde la API de YouTube
- **Reproductor de YouTube** integrado
- **Búsqueda** de episodios en tiempo real
- **Episodios destacados** con carrusel horizontal
- **Filtrado** por categorías y tags
- **Información detallada** de cada episodio

### 🎨 **Experiencia de Usuario**
- **Diseño moderno** con Material Design 3
- **Modo oscuro** automático basado en sistema
- **Animaciones fluidas** y transiciones
- **Responsive design** para diferentes pantallas
- **Estados de carga** y manejo de errores

## 📱 Pantallas de la Aplicación

### 🔐 **Autenticación**
- **Splash Screen** - Pantalla de carga con animaciones y verificación de sesión
- **Login Screen** - Inicio de sesión con email y contraseña
- **Register Screen** - Registro de nuevo usuario con validaciones
- **Forgot Password Screen** - Recuperación de contraseña por email

### 🏠 **Contenido Principal**
- **Home Screen** - Lista de episodios con búsqueda y episodios destacados
- **Episode Detail Screen** - Reproductor de YouTube y información completa del episodio

### ⚙️ **Administración**
- **Admin Screen** - Gestión de datos de prueba y configuración

## 🛠️ Stack Tecnológico

### **Frontend**
- **Flutter** 3.35.3 - Framework de desarrollo móvil
- **Dart** - Lenguaje de programación
- **Material Design 3** - Sistema de diseño

### **Backend & Servicios**
- **Firebase Authentication** - Autenticación de usuarios
- **Firestore Database** - Base de datos NoSQL en tiempo real
- **YouTube Data API** - Obtención de episodios del podcast

### **Arquitectura & Estado**
- **BLoC** - Gestión de estado (MVVM Architecture)
- **Repository Pattern** - Capa de abstracción de datos
- **GoRouter** - Navegación declarativa

### **Dependencias Principales**
- **youtube_player_flutter** - Reproductor de videos de YouTube
- **cached_network_image** - Caché de imágenes de red
- **http** - Cliente HTTP para APIs
- **html** - Parser HTML para scraping

## 📋 Prerequisitos

- Flutter SDK (3.0.0 o superior)
- Android Studio / Xcode
- Cuenta de Google para Firebase
- Dispositivo Android/iOS o emulador

## ⚙️ Configuración

### 1. Clonar el repositorio
```bash
git clone <tu-repositorio>
cd DevLokosDart
```

### 2. Instalar dependencias
```bash
flutter pub get
```

### 3. Configurar Firebase

#### Crear proyecto en Firebase Console
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Crea un nuevo proyecto llamado `devlokos-podcast`
3. Habilita Google Analytics (opcional)

#### Configurar Authentication
1. Ve a **Authentication** > **Sign-in method**
2. Habilita **Email/Password**
3. Configura **Email link (passwordless sign-in)** si lo deseas

#### Configurar Firestore Database
1. Ve a **Firestore Database**
2. Crea base de datos en **modo de prueba**
3. Selecciona ubicación (us-central1 recomendado)

#### Configurar Android
1. Agrega una app Android en Firebase Console
2. Nombre del paquete: `com.devlokos.devlokosdart`
3. Apodo: `DevLokos Podcast`
4. Descarga `google-services.json`
5. Coloca en `android/app/google-services.json`

#### Configurar iOS (opcional)
1. Agrega una app iOS en Firebase Console
2. ID del paquete: `com.devlokos.devlokosdart`
3. Descarga `GoogleService-Info.plist`
4. Coloca en `ios/Runner/GoogleService-Info.plist`

#### Configurar YouTube Data API
1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Habilita **YouTube Data API v3**
3. Crea credenciales API Key
4. Actualiza `youtubeApiKey` en `lib/constants/app_constants.dart`

#### Actualizar credenciales
1. Ve a **Configuración del proyecto** > **General**
2. Copia las credenciales de configuración
3. Actualiza `lib/firebase_options.dart` con tus credenciales

### 4. Configurar reglas de Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /episodes/{episodeId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚀 Ejecutar la aplicación

### Android
```bash
# Verificar dispositivos
flutter devices

# Ejecutar en emulador
flutter run -d emulator-5554

# O ejecutar en dispositivo físico
flutter run
```

### iOS
```bash
# Ejecutar en simulador
flutter run -d "iPhone Simulator"

# O ejecutar en dispositivo físico
flutter run
```

## 📊 Flujo de la Aplicación

### **Flujo de Autenticación**
1. **Splash Screen** - Verifica si hay sesión activa
2. **Login/Register** - Usuario se autentica o registra
3. **Home Screen** - Acceso a episodios del podcast

### **Flujo de Episodios**
1. **Carga de episodios** desde YouTube Data API
2. **Lista de episodios** con búsqueda y filtros
3. **Reproducción** integrada de YouTube
4. **Información detallada** de cada episodio

### **Datos de prueba**
La aplicación incluye una pantalla de administración para gestionar datos:

1. Ejecuta la aplicación
2. Ve a la pantalla de administración (ícono de engranaje)
3. Haz clic en "Agregar Datos de Prueba"
4. Los episodios aparecerán en la pantalla principal

## 🎨 Personalización

### Colores
Edita `lib/utils/app_theme.dart` para cambiar los colores de la aplicación.

### Constantes
Modifica `lib/constants/app_constants.dart` para ajustar configuraciones.

### YouTube Playlist
Actualiza `youtubePlaylistId` en `app_constants.dart` con tu playlist de YouTube.

## 📁 Estructura del proyecto

```
lib/
├── bloc/              # BLoC Components (MVVM Architecture)
│   └── episode/       # Episode BLoC (Events, States, Logic)
├── constants/         # Constantes de la aplicación
├── models/            # Modelos de datos
├── repository/        # Data Layer (Repository Pattern)
├── screens/           # Pantallas de la aplicación
│   ├── admin/         # Pantalla de administración
│   ├── auth/          # Login y registro
│   ├── episode/       # Detalle de episodio
│   └── home/          # Pantalla principal
├── services/          # Servicios externos (YouTube, Firebase)
├── utils/             # Utilidades (tema, etc.)
└── widgets/           # Widgets reutilizables
```

## 🏗️ Arquitectura MVVM con BLoC

Este proyecto implementa una arquitectura **MVVM (Model-View-ViewModel)** usando **BLoC** como patrón de gestión de estado:

- **Model**: Estructura de datos (`Episode`)
- **View**: UI Components (`HomeScreen`, `EpisodeCard`)
- **ViewModel**: BLoC (`EpisodeBloc`)

### Ventajas:
- ✅ **Separación clara** de responsabilidades
- ✅ **Fácil testing** con estados predecibles
- ✅ **Escalabilidad** para proyectos grandes
- ✅ **Mantenibilidad** mejorada

Ver [ARCHITECTURE.md](ARCHITECTURE.md) para más detalles sobre la arquitectura.

## 🔧 Comandos útiles

```bash
# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run

# Verificar dependencias
flutter pub deps

# Análisis de código
flutter analyze

# Formatear código
dart format .
```

## 📝 Notas de desarrollo

### **Arquitectura**
- La aplicación usa **BLoC** para gestión de estado (no Provider)
- Implementa patrón **MVVM** con separación clara de responsabilidades
- **Repository Pattern** para abstracción de datos

### **Rendimiento**
- Las animaciones están optimizadas para rendimiento
- Caché de imágenes con `cached_network_image`
- Estados de carga y error bien manejados

### **Dependencias**
- El reproductor de YouTube requiere conexión a internet
- Los datos se obtienen de YouTube Data API
- Firebase Auth maneja la autenticación de usuarios
- Firestore para almacenamiento de preferencias de usuario

### **Seguridad**
- Validaciones de formularios en tiempo real
- Reglas de Firestore configuradas para seguridad
- Autenticación segura con Firebase Auth

## 🤝 Contribuir

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

Este proyecto está bajo la Licencia MIT. Ver `LICENSE` para más detalles.

## 📞 Contacto

DevLokos Podcast - [@devlokos](https://twitter.com/devlokos)

Link del proyecto: [https://github.com/tu-usuario/DevLokosDart](https://github.com/tu-usuario/DevLokosDart)
DevLokos Podcast 
