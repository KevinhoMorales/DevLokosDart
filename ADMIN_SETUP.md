# Configuración de Administradores

Para que un usuario vea el botón **Administración** en su perfil, su email debe estar registrado en Firestore.

## Pasos para agregar un administrador

1. Abre [Firebase Console](https://console.firebase.google.com/) y selecciona tu proyecto.

2. Ve a **Firestore Database** → **Datos**.

3. Navega o crea la siguiente estructura:
   - Colección: `dev`
   - Documento: `dev`
   - Subcolección: `admin`

4. En la subcolección `admin`, agrega un **nuevo documento** con:
   - **ID del documento**: puedes dejarlo en auto-generado o usar algo como `kevin_morales`
   - **Campo**: `email` (tipo: string)
   - **Valor**: `kevin.morales@meniuz.com` (el email del administrador)

5. Despliega las reglas de Firestore actualizadas:
   ```bash
   firebase deploy --only firestore:rules
   ```

## Estructura en Firestore

```
dev (colección)
  └── dev (documento)
        └── admin (subcolección)
              └── [documento con ID cualquiera]
                    └── email: "kevin.morales@meniuz.com"
```

## Nota

- El email se compara en **minúsculas** y sin espacios.
- En ambiente de producción, la ruta sería `prod/prod/admin`.
- Después de agregar el email, cierra sesión y vuelve a iniciar sesión, o recarga la app para que se actualice el estado de administrador.
