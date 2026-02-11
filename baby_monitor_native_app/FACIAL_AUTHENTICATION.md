# Validación de Reconocimiento Facial - KOA Baby Monitor

## 📋 Descripción

Se ha implementado un sistema de **validación de reconocimiento facial** que garantiza que solo el usuario registrado pueda acceder a la aplicación. Si el rostro detectado no coincide con el registrado, el acceso será **DENEGADO**.

## 🔐 Cómo Funciona

### 1. Registro del Usuario (FaceRegistrationPage)

Cuando el usuario registra su rostro:
- Se captura una foto del rostro usando la cámara frontal
- Se extraen **características faciales únicas** usando Google ML Kit:
  - Ancho y alto del rostro
  - Proporción (aspect ratio)
  - Ángulos de rotación de la cabeza (Euler Y/Z)
  - Probabilidades de características (ojos abiertos, sonrisa)
- Estas características se guardan en SharedPreferences como:
  - `user_face_photo` - Foto del rostro en base64
  - `user_face_features` - JSON con características faciales

### 2. Autenticación (BiometricLoginPage)

Cuando alguien intenta acceder a la app:
1. Se detecta y captura el rostro actual
2. Se extraen las mismas características faciales
3. Se **comparan** con las características registradas
4. Se calcula un **porcentaje de similitud** (0% - 100%)
5. **Umbral de aceptación: 75%**
   - ✅ Si similitud ≥ 75% → Acceso permitido
   - ❌ Si similitud < 75% → **Acceso DENEGADO**

## 🎯 Características del Sistema de Comparación

### Extracción de Características (`_extractFaceFeatures`)
```dart
{
  'width': double,           // Ancho del rostro
  'height': double,          // Alto del rostro
  'aspect_ratio': double,    // Proporción (más importante)
  'head_euler_y': double,    // Rotación horizontal
  'head_euler_z': double,    // Rotación inclinación
  'smiling_prob': double,    // Probabilidad de sonrisa
  'left_eye_open': double,   // Ojo izquierdo abierto
  'right_eye_open': double   // Ojo derecho abierto
}
```

### Comparación Ponderada (`_compareFaceFeatures`)

El algoritmo usa **pesos** para dar más importancia a ciertas características:

| Característica | Peso | Importancia |
|---------------|------|-------------|
| `aspect_ratio` | 2.0 | ⭐⭐⭐ Muy alta |
| `width/height` | 1.0 | ⭐⭐ Media |
| `head_euler_*` | 0.5 | ⭐ Baja |
| `probabilities` | 0.3 | ⭐ Muy baja |

El **aspect ratio** (proporción del rostro) es la característica más importante porque es única para cada persona y muy estable.

## 🛡️ Seguridad

### ✅ Ventajas del Sistema Implementado
- **No acepta cualquier rostro** - Solo el registrado
- **Umbral ajustable** - Puede configurarse según necesidad
- **Tolerancia a variaciones** - Permite cambios menores (iluminación, ángulo)
- **Rápido** - Comparación en milisegundos
- **Sin conexión** - Todo funciona offline

### ⚠️ Limitaciones Actuales
- Usa características básicas de ML Kit (no embeddings profundos)
- Podría confundirse con personas muy similares físicamente
- Sensible a cambios drásticos (gafas, barba, maquillaje)

### 🔧 Recomendaciones para Producción

Para un sistema de producción de alta seguridad:

1. **Agregar TensorFlow Lite con FaceNet**
   ```yaml
   dependencies:
     tflite_flutter: ^0.10.1
   ```
   Usar embeddings de 128/512 dimensiones

2. **Implementar liveness detection**
   - Detectar si es una persona real vs foto
   - Pedir parpadeos o movimientos de cabeza

3. **Múltiples registros**
   - Capturar 3-5 fotos en diferentes ángulos
   - Promediar características para mayor precisión

4. **Autenticación de dos factores**
   - Combinar con PIN o huella digital
   - Como respaldo si falla reconocimiento facial

## 🚀 Cómo Probar

1. **Primera vez**: Registrar tu rostro
   - La app te pedirá capturar tu rostro
   - Se guardan tus características faciales

2. **Intentar acceder con el mismo usuario**
   - ✅ Debería permitir el acceso

3. **Intentar acceder con otra persona**
   - ❌ Debería DENEGAR el acceso
   - Mensaje: "Rostro no autorizado. Acceso denegado."

## 📝 Ajustar el Umbral de Similitud

En `lib/main.dart`, línea ~852:

```dart
const double similarityThreshold = 0.75; // 75%
```

- **Más restrictivo**: Aumentar a 0.85 (85%)
- **Más permisivo**: Reducir a 0.65 (65%)

⚠️ **Advertencia**: Un umbral muy bajo puede permitir rostros no autorizados.

## 🐛 Debug y Logs

El sistema imprime información útil en la consola:

```dart
debugPrint('Rostro registrado con características: $faceFeatures');
debugPrint('Error en verificación facial: $e');
```

Para ver los logs en tiempo real:
```bash
flutter run
```

## 📊 Datos Guardados

Los siguientes datos se almacenan en SharedPreferences:

```dart
'user_face_photo'     // String base64 - Foto del rostro
'user_face_features'  // String JSON - Características faciales
'has_infant_profile'  // bool - Si hay perfil de bebé
'infant_name'         // String - Nombre del bebé
// ... otros datos del perfil
```

## 🔄 Próximos Pasos Recomendados

1. ✅ **Implementado**: Comparación de características faciales
2. 🔜 **Sugerido**: Agregar TensorFlow Lite + FaceNet
3. 🔜 **Sugerido**: Implementar liveness detection
4. 🔜 **Sugerido**: Opción de re-registro del rostro
5. 🔜 **Sugerido**: Contador de intentos fallidos (3 intentos máximo)

## 📄 Licencia y Créditos

Desarrollado para KOA Baby Monitor App
Implementación de validación facial: 2026
