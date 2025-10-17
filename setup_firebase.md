# Configuración de Firebase para DevLokos

## Pasos para configurar Firebase:

### 1. Crear proyecto en Firebase Console
1. Ve a [Firebase Console](https://console.firebase.google.com/)
2. Haz clic en "Crear un proyecto"
3. Nombre del proyecto: `devlokos-podcast`
4. Habilita Google Analytics (opcional)
5. Selecciona tu cuenta de Google

### 2. Configurar Authentication
1. En el panel izquierdo, ve a "Authentication"
2. Haz clic en "Comenzar"
3. Ve a la pestaña "Sign-in method"
4. Habilita "Correo electrónico/contraseña"
5. Guarda los cambios

### 3. Configurar Firestore Database
1. En el panel izquierdo, ve a "Firestore Database"
2. Haz clic en "Crear base de datos"
3. Selecciona "Comenzar en modo de prueba" (para desarrollo)
4. Elige una ubicación (preferiblemente us-central1)
5. Haz clic en "Habilitar"

### 4. Configurar Android App
1. En la página principal del proyecto, haz clic en el ícono de Android
2. Nombre del paquete Android: `com.devlokos.devlokosdart`
3. Apodo de la aplicación: `DevLokos`
4. Certificado SHA-1: (opcional para desarrollo)
5. Haz clic en "Registrar aplicación"
6. Descarga el archivo `google-services.json`
7. Coloca el archivo en: `android/app/google-services.json`

### 5. Configurar iOS App (opcional)
1. En la página principal del proyecto, haz clic en el ícono de iOS
2. ID del paquete iOS: `com.devlokos.devlokosdart`
3. Apodo de la aplicación: `DevLokos`
4. Haz clic en "Registrar aplicación"
5. Descarga el archivo `GoogleService-Info.plist`
6. Coloca el archivo en: `ios/Runner/GoogleService-Info.plist`

### 6. Obtener credenciales de configuración
1. Ve a "Configuración del proyecto" (ícono de engranaje)
2. Ve a la pestaña "General"
3. En "Tus aplicaciones", selecciona tu app Android
4. Copia las credenciales de configuración

### 7. Actualizar firebase_options.dart
Reemplaza el contenido del archivo `lib/firebase_options.dart` con las credenciales reales de tu proyecto.

### 8. Agregar reglas de Firestore
En Firestore Database > Reglas, agrega:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para episodios (lectura pública)
    match /episodes/{episodeId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Reglas para usuarios
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 9. Datos de prueba
Puedes agregar episodios de prueba en Firestore con la siguiente estructura:

```json
{
  "title": "Introducción a Flutter",
  "description": "En este episodio hablamos sobre los fundamentos de Flutter...",
  "thumbnailUrl": "https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg",
  "videoId": "VIDEO_ID_DEL_YOUTUBE",
  "duration": "45:30",
  "publishedAt": 1704067200000,
  "viewCount": 1250,
  "tags": ["Flutter", "Dart", "Mobile Development"],
  "isFeatured": true
}
```

## Comandos útiles:

```bash
# Instalar dependencias
flutter pub get

# Ejecutar en Android
flutter run -d emulator-5554

# Ejecutar en iOS
flutter run -d "iPhone Simulator"

# Limpiar y reconstruir
flutter clean
flutter pub get
flutter run
```
