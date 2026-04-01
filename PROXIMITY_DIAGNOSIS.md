# 🧪 Diagnóstico de Sensor de Proximidad - Rakaha

## Cambios Realizados

### 1. **MainActivity.kt** - Instrumentación Android
- ✅ Agregados logs con tag `QiblaProximity`
- ✅ Cambiado `SENSOR_DELAY_NORMAL` → `SENSOR_DELAY_FASTEST`
- ✅ **CORREGIDO: Lógica isNear ahora usa `distance < maximumRange`**
- ✅ Eliminada detección dual (no necesaria, todos los sensores siguen misma regla)
- ✅ Log de cada evento del sensor
- ✅ Log de valores enviados a Flutter

### 2. **focus_service.dart** - Instrumentación Dart
- ✅ Agregados logs con prefijo `[FOCUS]`
- ✅ Log de activación/desactivación
- ✅ Log de cada evento recibido
- ✅ Log de cuando se confirma proximidad
- ✅ Log de conteo de rakahs/sujud

---

## 📊 Comportamiento REAL del Sensor de Proximidad Android

Según documentación oficial de Android y StackOverflow:

| Estado | Valor Reportado | Ejemplo |
|--------|-----------------|---------|
| **Near** (cerca) | `distance < maximumRange` | `0.0 cm` |
| **Far** (lejos) | `distance == maximumRange` | `5.0 cm` |

**Esto aplica a TODOS los sensores**, tanto discretos (binarios) como continuos.

### Ejemplos Reales por Dispositivo

| Dispositivo | maximumRange | Near (cerca) | Far (lejos) |
|-------------|--------------|--------------|-------------|
| Samsung Galaxy S21 | 5.0 cm | 0.0 cm | 5.0 cm |
| Nexus S | 5.0 cm | 0.0 cm | 5.0 cm |
| THL T200 | 1.0 cm | 0.0 cm | 1.0 cm |
| Motorola Defy | 100.0 cm | 3.0 cm | 100.0 cm |

### Fórmula Correcta (ya implementada)

```kotlin
// ✅ CORRECTO - Funciona para TODOS los sensores
val isNear = distance < sensor.maximumRange
```

**No se necesita distinción entre discreto/continuo.** La misma fórmula funciona universalmente.

---

## ✅ Criterio para Validar en Logs que Near/Far está Correcto

### En logcat Android (`adb logcat -s QiblaProximity:D`):

**Cuando el teléfono está lejos (en el aire):**
```
D/QiblaProximity: onSensorChanged: distance=5.0 cm, maxRange=5.0 cm, isNear=false
D/QiblaProximity: onSensorChanged: Sent value=0 to Flutter
```

**Cuando el teléfono está cerca (boca abajo sobre mesa):**
```
D/QiblaProximity: onSensorChanged: distance=0.0 cm, maxRange=5.0 cm, isNear=true
D/QiblaProximity: onSensorChanged: Sent value=1 to Flutter
```

### Checklist de Validación:

- [ ] `maxRange` típicamente es `5.0` (puede variar por dispositivo)
- [ ] Cuando alejas el teléfono: `distance` ≈ `maxRange` (ej. `5.0`)
- [ ] Cuando acercas el teléfono: `distance` ≈ `0.0` (o valor bajo como `0.0-1.0`)
- [ ] `isNear=true` SOLO cuando `distance < maxRange`
- [ ] `isNear=false` SOLO cuando `distance == maxRange`
- [ ] `Sent value=1` cuando `isNear=true`
- [ ] `Sent value=0` cuando `isNear=false`

### ⚠️ Si ves esto, está INVERTIDO (mal):

```
// ❌ MAL - isNear=true cuando distance=5.0 (debería ser false)
D/QiblaProximity: onSensorChanged: distance=5.0 cm, maxRange=5.0 cm, isNear=true
```

### ✅ Si ves esto, está CORRECTO:

```
// ✅ BIEN - isNear=false cuando distance=5.0 (igual a maxRange)
D/QiblaProximity: onSensorChanged: distance=5.0 cm, maxRange=5.0 cm, isNear=false

// ✅ BIEN - isNear=true cuando distance=0.0 (menor que maxRange)
D/QiblaProximity: onSensorChanged: distance=0.0 cm, maxRange=5.0 cm, isNear=true
```

### Paso 1: Construir la app en modo debug

```bash
flutter clean
flutter run --verbose
```

### Paso 2: Abrir logs de Android

En una terminal separada:

```bash
adb logcat -s QiblaProximity:D
```

O para ver TODO el logcat filtrado:

```bash
adb logcat | findstr "QiblaProximity"
```

### Paso 3: Abrir logs de Flutter

En la terminal donde corre `flutter run`, verás los logs con prefijo `[FOCUS]`

### Paso 4: Ejecutar el flujo completo

1. Abre la app
2. Toca "Rakaha" en el menú
3. **Observa los logs** - deberías ver esta secuencia:

#### Logs Android esperados (adb logcat):
```
D/QiblaProximity: onListen: Starting proximity sensor stream
D/QiblaProximity: onListen: Sensor found - maxRange=5.0, resolution=5.0, type=2
D/QiblaProximity: onListen: Sensor registered with SENSOR_DELAY_FASTEST
D/QiblaProximity: onSensorChanged: CONTINUOUS sensor - distance=0.0 cm, maxRange=5.0 cm, isNear=true
D/QiblaProximity: onSensorChanged: Sent value=1 to Flutter
```

#### Logs Flutter esperados:
```
[FOCUS] === ACTIVATE called ===
[FOCUS] _startSensor: Starting sensor subscription
[FOCUS] _proximityEvents: Setting up receiveBroadcastStream
[FOCUS] _startSensor: Sensor subscription established
[FOCUS] === ACTIVATE complete ===
[FOCUS] _proximityEvents: Received raw event=1 (type: int)
[FOCUS] _startSensor: event=1, isNear=true, wasNear=false
[FOCUS] _startSensor: PROXIMITY CONFIRMED - calling _onProximityConfirmed()
[FOCUS] _onProximityConfirmed: ENTER
[FOCUS] _onProximityConfirmed: newSujudCount=1, currentRakahs=0
[FOCUS] _onProximityConfirmed: SUDJUD #1 registered
```

### Paso 5: Prueba física de sujud

1. Coloca el teléfono boca abajo sobre una superficie (simulando sujud)
2. Deberías ver:
   - Log Android: `distance=0.0 cm, isNear=true`
   - Log Flutter: `PROXIMITY CONFIRMED`
   - Vibración ligera (primer sujud)
3. Levanta el teléfono
4. Vuelve a colocar boca abajo
5. Deberías ver:
   - Log Flutter: `RAKAH COMPLETED - incrementing rakahs`
   - Vibración media
   - UI actualiza: número de rakahs incrementa

---

## 🚨 Posibles Problemas y Diagnóstico

### Problema A: "PROXIMITY sensor NOT available"

**Síntoma en logcat:**
```
E/QiblaProximity: onListen: PROXIMITY sensor NOT available on this device
```

**Causa:** Tu dispositivo no tiene sensor de proximidad hardware.

**Solución:** 
- Verifica especificaciones del dispositivo
- Algunos dispositivos modernos eliminaron el sensor
- Usa un emulador con sensor simulado o cambia de dispositivo

---

### Problema B: Sensor no detecta nada

**Síntoma:**
- Logs Android muestran `distance=5.0 cm, isNear=false` siempre
- Nunca cambia aunque cubras el sensor

**Causa:** 
- El sensor está en otra ubicación del teléfono
- La funda del teléfono bloquea el sensor
- El sensor está sucio

**Solución:**
1. Busca dónde está el sensor (generalmente cerca del speaker frontal)
2. Limpia la zona
3. Quita la funda
4. Prueba cubriendo diferentes zonas del borde superior

---

### Problema C: Flutter no recibe eventos

**Síntoma:**
- Logs Android: `Sent value=1 to Flutter`
- Logs Flutter: NADA después de `Sensor subscription established`

**Causa:** 
- EventChannel no está bien configurado
- Flutter engine no está recibiendo los eventos

**Solución:**
1. Verifica que el canal sea exactamente `com.qiblatime/proximity`
2. Rebuild la app: `flutter clean && flutter run`
3. Verifica que `configureFlutterEngine` se ejecuta

---

### Problema D: Eventos llegan pero no cuentan

**Síntoma:**
- Logs Flutter: `event=1, isNear=true, wasNear=true`
- Nunca entra en `PROXIMITY CONFIRMED`

**Causa:** 
- El sensor manda muchos eventos consecutivos
- El estado `isNear` ya era `true` antes

**Solución:** 
- Esto es NORMAL - el código solo cuenta cuando hay TRANSICIÓN far→near
- Asegúrate de levantar el teléfono entre cada sujud
- El sensor debe marcar `isNear=false` antes del siguiente `isNear=true`

---

## 📊 Valores Típicos de Sensor

### Sensor Continuo (ej. Samsung Galaxy):
```
maxRange=5.0 cm
resolution=5.0
distance=0.0 → cerca
distance=5.0 → lejos
```

### Sensor Discreto (ej. algunos Xiaomi):
```
maxRange=1.0
resolution=1.0
distance=0.0 → lejos
distance=1.0 → cerca
```

---

## ✅ Checklist de Verificación

- [ ] `flutter clean` ejecutado
- [ ] App rebuild desde cero
- [ ] Logs Android visibles con `adb logcat -s QiblaProximity:D`
- [ ] Logs Flutter visibles en terminal
- [ ] Sensor detectado (`Sensor found` en logcat)
- [ ] Eventos enviados (`Sent value=1` en logcat)
- [ ] Eventos recibidos (`Received raw event` en Flutter)
- [ ] Proximidad confirmada (`PROXIMITY CONFIRMED` en Flutter)
- [ ] Sujud registrado (`SUDJUD #1 registered`)
- [ ] Rakah completado (`RAKAH COMPLETED`)
- [ ] UI actualiza número de rakahs

---

## 🎯 Flujo Ideal Esperado

```
Usuario toca Rakaha
  ↓
[FOCUS] === ACTIVATE called ===
  ↓
Android: onListen: Starting proximity sensor stream
Android: onListen: Sensor found
Android: onListen: Sensor registered with SENSOR_DELAY_FASTEST
  ↓
[FOCUS] _startSensor: Sensor subscription established
  ↓
Usuario pone teléfono en sujud (boca abajo)
  ↓
Android: onSensorChanged: distance=0.0, isNear=true
Android: onSensorChanged: Sent value=1 to Flutter
  ↓
Flutter: Received raw event=1
Flutter: PROXIMITY CONFIRMED
Flutter: SUDJUD #1 registered
(Vibración ligera)
  ↓
Usuario levanta teléfono
  ↓
Android: onSensorChanged: distance=5.0, isNear=false
Android: onSensorChanged: Sent value=0 to Flutter
  ↓
Flutter: event=0, isNear=false
  ↓
Usuario repite sujud
  ↓
Flutter: PROXIMITY CONFIRMED
Flutter: RAKAH COMPLETED - incrementing rakahs
(Vibración media)
UI: Número cambia de 0 → 1
```

---

## 📝 Notas Importantes

1. **SENSOR_DELAY_FASTEST**: Ahora el sensor muestrea lo más rápido posible (antes era 200ms)

2. **Debounce de 800ms**: Se mantiene para evitar doble conteo accidental

3. **Transición far→near**: Solo cuenta cuando hay cambio de estado, no mientras está cerca

4. **2 sujuds = 1 rakah**: La lógica se mantiene (sujudCount >= 2)

5. **Logs en producción**: Los logs se pueden desactivar cambiando `_debugMode = false`

---

## 🔄 Si Sigue Sin Funcionar

1. **Ejecuta este comando y comparte el output:**

```bash
adb shell dumpsys sensorservice | findstr "proximity"
```

2. **Prueba en otro dispositivo** - algunos teléfonos tienen el sensor en diferente ubicación

3. **Verifica permisos** - aunque el sensor de proximidad no requiere permiso explícito

4. **Revisa si hay otra app interfiriendo** - algunas apps de "smart screen" usan el sensor
