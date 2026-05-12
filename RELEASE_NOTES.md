# Mega Vital — Notas de Versión

---

## v1.0.4+14 — 12 de mayo de 2026

### Nuevas funcionalidades

- **Selección de tipo de cuenta en el registro:** Los nuevos usuarios ahora eligen su tipo de cuenta antes de registrarse, mejorando la personalización desde el primer acceso.
- **Videos de ejercicios:** Se reemplazaron los GIFs por videos MP4 almacenados en Supabase. Los videos muestran una miniatura estática y se reproducen al tocar, con pausa automática.
- **Video como prueba en retos:** Los usuarios pueden subir videos como evidencia en retos/desafíos. El video de prueba se muestra en el marcador del reto.
- **Video en la comunidad:** El feed de comunidad ahora soporta publicaciones con video, además de mayor compresión en imágenes.
- **Restricciones premium (Nutrición y Comunidad):** Las secciones de Nutrición y Comunidad requieren acceso premium para ser utilizadas.
- **Códigos únicos de registro:** Se reemplazó la contraseña de administrador por un sistema de códigos únicos para el registro de nuevos usuarios. La pantalla de código muestra un bloque de contacto.
- **Pausar y reanudar rutinas:** Los usuarios pueden pausar una rutina activa y continuar desde donde se quedaron sin perder el progreso ni el tiempo.
- **Gráfica de progreso de peso:** La pantalla de inicio muestra una gráfica del progreso de peso con recordatorio mensual para registrar mediciones.
- **Pantalla de progreso por ejercicio:** Nueva pantalla con gráficas de líneas que muestran el historial de rendimiento por ejercicio.
- **Login con nombre de usuario:** Se reemplazó el inicio de sesión por email con un sistema de nombre de usuario único. La recuperación de contraseña se redirige a contactar al administrador.
- **Sistema premium completo:** Se añadieron las tablas SQL y funciones RPC del sistema de acceso premium en la base de datos.
- **Página de política de privacidad:** Disponible en `privacidad.html` para cumplimiento con tiendas de aplicaciones.

### Correcciones

- **Estimación de calorías mejorada:** Mayor precisión al analizar fotos de alimentos.
- **Login con Gmail:** Se corrigió un error que impedía iniciar sesión a cuentas existentes con correo `@gmail.com`.
- **Validación de nombre de usuario:** Se corrigió la validación para evitar que se acepten emails como nombre de usuario.
- **Persistencia de sesión:** La sesión del usuario ahora se mantiene entre aperturas de la app y se conecta correctamente con el estado premium.
- **Panel de administrador:** El botón de acceso al panel admin ahora solo es visible para correos autorizados.
- **Subida de video de prueba:** Se corrigió la ruta de subida para cumplir con la política RLS del bucket de almacenamiento.

### Infraestructura y despliegue

- Configuración de firma de release y workflow de Android para distribución en Google Play.
- Actualización de `codemagic.yaml` y `build.gradle.kts` para soportar el pipeline de CI/CD.
- Publicación en Google Play y App Store (versiones 1.0.2, 1.0.3 y 1.0.4 durante el ciclo de aprobación de las tiendas).

---

## Historial de versiones anteriores

| Versión    | Build | Cambio principal                                      |
|------------|-------|-------------------------------------------------------|
| 1.0.3+13   | 13    | Bump requerido por Apple (versión mayor a 1.0.2)      |
| 1.0.2+13   | 13    | Primera versión enviada a Google Play y App Store     |
| 1.0.2+12   | 12    | Corrección de build number duplicado en App Store     |
| 1.0.1      | —     | Versión aprobada por App Store anteriormente          |
