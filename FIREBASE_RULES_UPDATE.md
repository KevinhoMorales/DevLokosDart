# Actualizar Reglas de Firebase

## Problema
Los datos no se están guardando en Firestore ni Storage porque las reglas están bloqueando las escrituras.

## Solución

### 1. Actualizar Reglas de Firestore

1. Ve a la [Consola de Firebase](https://console.firebase.google.com/)
2. Selecciona tu proyecto
3. Ve a **Firestore Database** > **Rules**
4. Reemplaza las reglas actuales con:

```javascript
rules_version = '2';

// Reglas de seguridad para Firebase Firestore
service cloud.firestore {
  match /databases/{database}/documents {
    // Reglas para usuarios en desarrollo
    match /dev_users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reglas para usuarios en producción
    match /prod_users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Reglas para otras colecciones (solo lectura para usuarios autenticados)
    match /dev_{document=**} {
      allow read: if request.auth != null;
    }
    
    match /prod_{document=**} {
      allow read: if request.auth != null;
    }
  }
}
```

5. Haz clic en **Publish**

### 2. Actualizar Reglas de Storage

1. Ve a **Storage** > **Rules**
2. Reemplaza las reglas actuales con:

```javascript
rules_version = '2';

// Reglas de seguridad para Firebase Storage
service firebase.storage {
  match /b/{bucket}/o {
    // Reglas más permisivas para desarrollo
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

3. Haz clic en **Publish**

### 3. Verificar

Después de actualizar las reglas:
1. Intenta registrar un nuevo usuario en la app
2. Verifica que aparezcan datos en Firestore
3. Verifica que se puedan subir imágenes a Storage

## Nota de Seguridad

Estas reglas son muy permisivas y solo deben usarse para desarrollo. Para producción, deberías usar reglas más restrictivas que validen específicamente los paths y permisos de cada usuario.
