# Lapticon – App móvil (Flutter)

App del Taller de Computación Móvil que consume el backend de Lapticon
(`https://lapticon-backend.onrender.com`).

**Incluye:** registro de usuarios, login, crear encomienda (remitente),
registrar viaje (viajero), tomar encomiendas de la ruta, chat en tiempo real
remitente ↔ viajero y marcar la encomienda como recibida/entregada.

## Cómo correrla

Requisitos: Flutter 3.27 o superior, Android Studio y un emulador o un teléfono Android.

```bash
# 1. Entra a la carpeta descomprimida
cd lapticon_app

# 2. Genera las carpetas de plataforma (no sobrescribe lib/ ni pubspec.yaml)
flutter create --org com.lapticon --project-name app --platforms android .

# 3. Instala dependencias
flutter pub get

# 4. Ejecuta
flutter run
```

Esto deja el `applicationId` como **`com.lapticon.app`**, el mismo que trae
tu `google-services.json`.

### Si algo falla

- **Error de minSdk** (`cloud_firestore requires minSdk 23`): en
  `android/app/build.gradle.kts` cambia `minSdk = flutter.minSdkVersion` por
  `minSdk = 23`.
- **Conflicto de versiones al hacer `pub get`**: ejecuta
  `flutter pub upgrade --major-versions`.
- **La primera petición tarda mucho o da "el servidor tardó demasiado"**: el
  backend está en el plan gratuito de Render y se duerme. Espera ~1 minuto y
  reintenta.
- **APK release sin internet**: agrega
  `<uses-permission android:name="android.permission.INTERNET"/>` en
  `android/app/src/main/AndroidManifest.xml` (en debug ya viene).

> Firebase se inicializa con `lib/firebase_options.dart` (valores tomados de
> `google-services.json`), así que **no** necesitas el plugin de Gradle de
> google-services. Si quieres, igual puedes copiar el JSON a `android/app/`.

## Estructura

```
lib/
├── main.dart                  # Firebase + AuthGate (login ↔ home)
├── config.dart                # URL del backend
├── firebase_options.dart      # Config de Firebase (Android)
├── utils.dart                 # Fechas y normalización de texto
├── models/                    # Encomienda, Viaje
├── services/
│   ├── api_client.dart        # Todas las llamadas REST con Bearer idToken
│   └── chat_service.dart      # Chat en Firestore
├── widgets/                   # RutaSelector (ciudades del backend filtradas: Colombia ↔ Miami/Mexico City/New York)
└── screens/
    ├── login_screen.dart
    ├── register_screen.dart   # Firebase Auth + POST /api/users/register
    ├── home_screen.dart       # Pestañas: Enviar / Viajar / Perfil
    ├── remitente_screen.dart  # GET /api/encomiendas, agrupadas por estado
    ├── crear_encomienda_screen.dart   # POST /api/encomiendas
    ├── viajero_screen.dart    # Mi viaje + encomiendas de la ruta
    ├── registrar_viaje_screen.dart    # POST /api/viajes
    ├── chat_screen.dart       # Firestore + GET /api/chats/estado/:chatId
    └── perfil_screen.dart
```

## Flujo para probar (con dos cuentas)

1. **Cuenta A (remitente):** pestaña *Enviar* → *Nueva encomienda*
   (p. ej. Bogota → Miami).
2. **Cuenta B (viajero):** pestaña *Viajar* → *Registrar viaje* con la misma
   ruta → aparece la encomienda en "Disponibles" → *Tomar encomienda*.
3. Ambos abren el **Chat** desde la tarjeta de la encomienda.
4. El viajero pulsa *Entregada* (estado `entregada`) y el remitente
   confirma con *Recibida* (estado `recibida`).
5. El remitente puede *Retirar* una encomienda que nadie ha tomado: la API no
   tiene DELETE ni estado `cancelada`, así que queda como `vencida`.

Un mismo usuario puede ser remitente y viajero: ambos roles están siempre
disponibles como pestañas, así el rol no se pierde al cambiar de teléfono.

## Endpoints usados

| Acción | Endpoint |
|---|---|
| Guardar perfil | `POST /api/users/register` |
| Ver perfil | `GET /api/users/{uid}` |
| Mis encomiendas | `GET /api/encomiendas` |
| Crear encomienda | `POST /api/encomiendas` |
| Encomiendas de mi ruta | `GET /api/encomiendas/buscar?origen=&destino=` |
| Tomar encomienda | `PUT /api/encomiendas/tomar/{id}` |
| Entregada / recibida / retirar | `PUT /api/encomiendas/{id}/estado` con `entregada`, `recibida` o `vencida` |
| Mi viaje activo | `GET /api/viajes/disponible` |
| Registrar viaje | `POST /api/viajes` |
| Completar/cancelar viaje | `PATCH /api/viajes/{id}/estado` |
| Estado del chat | `GET /api/chats/estado/{chatId}` |
| Ciudades (filtradas a las 6 permitidas) | `GET /api/ciudades/ciudades` |

## Chat (Firestore)

- ID del chat: `uid1_uid2` con los uid ordenados.
- Mensajes en `chats/{chatId}/mensajes` con `{ texto, autorId, fecha }`.
- Si Firestore responde *permission-denied*, las reglas de seguridad del
  proyecto no permiten esa ruta. Unas reglas mínimas serían:

```
match /chats/{chatId} {
  allow read, write: if request.auth != null
    && chatId.split('_').hasAny([request.auth.uid]);
  match /mensajes/{msgId} {
    allow read, write: if request.auth != null
      && chatId.split('_').hasAny([request.auth.uid]);
  }
}
```

## Fuera de alcance (siguientes pasos)

Calificaciones (`POST /api/ratings`), matching con IA y chatbot.
