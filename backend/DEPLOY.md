# Mega Vital — Guía de deploy del servidor de IA

## Por qué necesitas esto

Si pones la clave de Gemini dentro de la app, cualquiera puede
extraerla del APK/IPA y usar tu cuota gratis a tu costa.

La solución: un servidor intermediario gratuito (Cloudflare Worker)
que guarda la clave de forma segura. La app solo habla con el Worker.

```
Usuario → App Flutter → Tu Worker (gratis) → Gemini API → Respuesta
```

## Paso 1: Obtén tu clave de Gemini (2 minutos)

1. Ve a https://aistudio.google.com/apikey
2. Inicia sesión con Gmail
3. "Create API Key" → copia la clave (AIzaSy...)
4. Plan gratuito: 1,500 análisis/día sin tarjeta

## Paso 2: Deploy en Cloudflare (3 minutos)

### Opción A — Desde el navegador (más fácil)

1. Ve a https://workers.cloudflare.com
2. "Sign Up" → crea cuenta gratis (no necesitas tarjeta)
3. Dashboard → "Workers & Pages" → "Create Worker"
4. Borra el código de ejemplo
5. Pega todo el contenido de `backend/worker.js`
6. Clic en "Save and Deploy"
7. Copia la URL que aparece (ej: https://megavital.tuusuario.workers.dev)

### Agregar la clave de Gemini como variable secreta

1. Worker → Settings → Variables → "Add variable"
2. Variable name: `GEMINI_KEY`
3. Value: `AIzaSy...tu-clave-de-gemini`
4. Activa "Encrypt" (toggle)
5. Clic "Save"

### Agregar tu token de app (opcional pero recomendado)

1. Agrega otra variable: `APP_TOKEN`
2. Value: pon el mismo string que tienes en app_config.dart → `appToken`
   (por defecto es `megavital-2024`, cámbialo a algo único tuyo)

## Paso 3: Conecta la app

Abre `lib/core/config/app_config.dart` y pon:

```dart
static const String workerUrl = 'https://megavital.tuusuario.workers.dev';
static const String appToken  = 'megavital-2024'; // o el que elegiste
```

## Paso 4: Prueba

```bash
flutter run
```

Ve a Nutrición → Agregar alimento → Tomar foto.
Todos los usuarios de tu app podrán usar la función.

## Límites gratuitos de Cloudflare

| Plan      | Requests/día | Costo     |
|-----------|-------------|-----------|
| Free      | 100,000     | $0/mes    |
| Workers Paid | Sin límite | $5/mes  |

Para una app de fitness con usuarios normales, 100,000/día
es más que suficiente para toda la base de usuarios.

## Monitoreo

En el dashboard de Cloudflare puedes ver:
- Cuántas requests ha recibido tu worker
- Errores y logs en tiempo real
- Gráficas de uso por día/semana

## Si tu app crece mucho

Si superas las 100,000 requests/día:
- Opción 1: Pasa a Workers Paid ($5/mes) → sin límite
- Opción 2: Agrega más claves de Gemini rotando en el Worker
- Opción 3: Agrega limitación por usuario (1 foto/minuto por UID)
