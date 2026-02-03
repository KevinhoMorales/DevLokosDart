# Configuración de Push Notifications (FCM)

La app ya tiene integrado Firebase Cloud Messaging. Para que funcione en **iOS** necesitas completar estos pasos:

## iOS - Configuración en Xcode

1. Abre el proyecto en Xcode: `ios/Runner.xcworkspace`
2. Selecciona el target **Runner** → pestaña **Signing & Capabilities**
3. Haz clic en **+ Capability** y añade:
   - **Push Notifications**
   - **Background Modes** (y activa "Remote notifications" y "Background fetch")

## iOS - Vincular APNs con Firebase

1. En [Apple Developer](https://developer.apple.com/account), crea una **Key** con APNs habilitado
2. Descarga el archivo `.p8` y guarda el **Key ID**
3. En [Firebase Console](https://console.firebase.google.com) → Tu proyecto → **Configuración del proyecto** → pestaña **Cloud Messaging**
4. En "Configuración de la app iOS", sube el archivo `.p8` e ingresa Key ID y Team ID

## Probar notificaciones

1. **Android**: Desde Firebase Console → Cloud Messaging → "Enviar mensaje de prueba"
2. **iOS**: Necesitas un dispositivo físico (el simulador no recibe push)

## Token FCM

El token del dispositivo se imprime en la consola en modo debug. Puedes usar `PushNotificationService().fcmToken` para enviarlo a tu backend y guardar dispositivos por usuario.
