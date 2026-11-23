/// URL del backend de Lapticon (Render). Sin "/" al final.
const String kBaseUrl = 'https://lapticon-backend.onrender.com';

/// Render (plan gratuito) apaga el servidor cuando no se usa: la primera
/// petición puede tardar ~1 minuto en responder.
const Duration kTimeout = Duration(seconds: 75);
