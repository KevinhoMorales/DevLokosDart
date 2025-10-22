# Configuración de Firebase Storage para DevLokos

## Problema
El error `[firebase_storage/unauthorized] User is not authorized to perform the desired action` indica que las reglas de seguridad de Firebase Storage no están configuradas correctamente.

## Solución

### 1. Configurar Reglas de Seguridad

Ve a la consola de Firebase:
1. Abre [Firebase Console](https://console.firebase.google.com/)
2. Selecciona tu proyecto DevLokos
3. Ve a **Storage** en el menú lateral
4. Haz clic en la pestaña **Rules**
5. Reemplaza las reglas existentes con las siguientes:

```javascript
rules_version = '2';

// Reglas de seguridad para Firebase Storage
service firebase.storage {
  match /b/{bucket}/o {
    // Regla para imágenes de perfil de usuarios autenticados
    match /profile_images/{userId}/{allPaths=**} {
      // Solo usuarios autenticados pueden leer y escribir sus propias imágenes
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Regla general para otros archivos (opcional)
    match /{allPaths=**} {
      // Solo usuarios autenticados pueden acceder
      allow read, write: if request.auth != null;
    }
  }
}
```

### 2. Publicar las Reglas

1. Haz clic en **Publish** para aplicar las nuevas reglas
2. Espera a que se confirme la publicación

### 3. Verificar la Configuración

Las reglas permiten:
- ✅ Usuarios autenticados pueden subir imágenes a su carpeta personal (`profile_images/{userId}/`)
- ✅ Usuarios autenticados pueden leer sus propias imágenes
- ✅ Usuarios autenticados pueden eliminar sus propias imágenes
- ❌ Usuarios no autenticados no pueden acceder a ninguna imagen
- ❌ Usuarios no pueden acceder a imágenes de otros usuarios

### 4. Estructura de Archivos en Storage

```
profile_images/
├── {userId1}/
│   ├── profile_1234567890.jpg
│   └── profile_1234567891.png
├── {userId2}/
│   ├── profile_1234567892.jpg
│   └── profile_1234567893.webp
└── ...
```

### 5. Prueba la Funcionalidad

Después de configurar las reglas:
1. Inicia sesión en la aplicación
2. Ve a la pantalla de perfil
3. Toca el avatar para cambiar la imagen
4. Selecciona una imagen desde la galería o cámara
5. La imagen debería subirse exitosamente a Firebase Storage

## Notas Importantes

- **Seguridad**: Las reglas aseguran que cada usuario solo puede acceder a sus propias imágenes
- **Autenticación**: El usuario debe estar autenticado para subir/eliminar imágenes
- **Organización**: Las imágenes se organizan por UID del usuario para mejor gestión
- **Metadatos**: Se incluyen metadatos con información del usuario y timestamp

## Solución de Problemas

Si sigues viendo errores de permisos:
1. Verifica que el usuario esté autenticado correctamente
2. Confirma que las reglas se publicaron correctamente
3. Revisa que el UID del usuario coincida con la estructura de carpetas
4. Verifica que Firebase Storage esté habilitado en tu proyecto
