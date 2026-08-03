# Configuración de Administradores y roles de cuenta

La administración de contenido (cursos, eventos, servicios, portfolio) se hace en la **web**:

**https://devlokos.com/admin**

La app móvil ya no incluye pantallas de admin. Si tu email está en la colección `admin` de Firestore, verás en Perfil el botón **Administrar en la web**.

## Roles de cuenta (`accountRole`)

Cada usuario de la app tiene un campo **`accountRole`** en Firestore:

```
{env}/{env}/users/{uid}
  └── accountRole: "user" | "member" | "admin"
```

| Rol | Quién lo asigna | Uso |
|-----|-----------------|-----|
| `user` | Automático al registrarse | Acceso base (p. ej. podcast) |
| `member` | Admin (Console / futuro CMS) | Beneficios (cursos, descuentos, etc.) — en evolución |
| `admin` | Admin (Console) | Acciones admin en app (TBD) |

Notas importantes:

- El campo de perfil **`role`** es el **cargo laboral** (texto libre). No es un permiso.
- Al registrarse siempre se escribe `accountRole: "user"`.
- El cliente **no puede** elevarse a `member`/`admin` (reglas Firestore).
- Para subir un rol: Firebase Console → documento del usuario → editar `accountRole`.
- Usuarios antiguos sin el campo se tratan como `user` al leerlos en la app.

### Ejemplo: hacer member

```
prod/prod/users/{uid}
  └── accountRole: "member"
```

## Agregar un administrador del CMS (colección `admin`)

El panel web `/admin` **sigue** autorizando con la colección `admin` por email (no con `accountRole` todavía).

1. Abre [Firebase Console](https://console.firebase.google.com/) → proyecto `devlokos`.
2. Ve a **Authentication** y asegúrate de que el usuario exista (email/password).
3. Ve a **Firestore Database** → **Datos**.
4. Crea o navega:
   - Colección: `prod` (o `dev` en desarrollo)
   - Documento: `prod` (o `dev`)
   - Subcolección: `admin`
5. Agrega un documento con:
   - Campo: `email` (string)
   - Valor: el email en minúsculas (ej. `kevin.morales@meniuz.com`)

```
prod/prod/admin/{docId}
  └── email: "usuario@ejemplo.com"
```

6. (Recomendado) En el doc del usuario, pon también `accountRole: "admin"` para alinear app y CMS.
7. En la web: entra a `/admin/login` con ese email y contraseña.

## Notas

- El email se compara en minúsculas y sin espacios.
- Las altas de admin CMS solo se hacen desde Firebase Console (las rules no permiten write a `admin` desde clients).
- El CMS escribe con Firebase Admin SDK; despliega rules actualizadas:

```bash
cd DevLokosDart
firebase deploy --only firestore:rules
```

## Variables Web requeridas

En el proyecto TypeScript (Vercel / `.env.local`):

- `NEXT_PUBLIC_FIREBASE_*` (Auth client)
- `FIREBASE_ADMIN_SDK_KEY` (service account JSON)
- `FIREBASE_ENV=prod` (o `dev`) — debe coincidir con la app (`DEVLOKOS_ENV`, default `prod`)
- `FIREBASE_STORAGE_BUCKET` / `NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET` para uploads

La app móvil lee `prod/prod/courses` y `prod/prod/events` por defecto. Si la web muestra cursos/eventos y la app no, casi siempre es porque el build usó `DEVLOKOS_ENV=dev`.
