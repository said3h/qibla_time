# Auditoría técnica — Qibla Time (Flutter, Android + iOS)

Proyecto auditado: `/Users/said3h/Documents/qibla_time`
Versión declarada: `1.6.0+47`
Fecha: 24 jun 2026
Tamaño del repo: ~98.5K líneas de Dart, 192 archivos `.dart`, 28 tests

---

## Resumen ejecutivo

Qibla Time es una aplicación Flutter de oración/Qibla/Quran/hadices con 11 idiomas, sin anuncios y sin tracking. La arquitectura general es sólida (Riverpod + Clean Architecture feature-first, logging centralizado, fallback offline, ProGuard+R8 bien preparados para notificaciones, cobertura razonable de tests). El proyecto está cerca de un release, pero arrastra varias decisiones pendientes que conviene cerrar antes de publicar: el módulo de **Tafsir está deshabilitado y marcado con TODOs legales**, los **assets de audio (`azan*.mp3/.caf`) están commiteados al repo y al IPA/AAB** (decenas de MB inflando cada build), **R8/ProGuard está deshabilitado en release** (`minifyEnabled false`) con un comentario TEMP que sigue ahí, las **plantillas de notificación para idiomas distintos del español** están sin traducir (`untranslated.json`), el **`teamID` de Apple está hardcodeado** en `ExportOptions.plist`/`release_ios.sh`, y la **app no tiene `PrivacyInfo.xcprivacy` propio** (obligatorio desde 2024 para nuevos submissions a App Store). La política de privacidad está bien redactada, pero el email de contacto es un Gmail personal (`support.qiblatime@gmail.com`) en vez del dominio `contact@qiblatime.app` que el usuario declara. La seguridad general es buena (sin secretos en el repo, sin tracking IDs, sin almacenamiento externo), aunque hay una superficie residual de red con HTTPS que conviene revisar antes del launch.

---

## Hallazgos críticos

### C-1. Tafsir deshabilitado con TODOs legales visibles en producción

- **Archivo afectado:** `lib/features/tafsir/services/tafsir_service.dart:82-83`, `lib/features/tafsir/services/tafsir_service.dart:206-207`, `lib/features/tafsir/services/tafsir_api_client.dart:387`, `lib/features/tafsir/screens/tafsir_debug_screen.dart:135`, `docs/tafsir_implementation_plan.md:272`.
- **Explicación:** El servicio de Tafsir tiene tres TODOs explícitos sobre verificación de licencias/redistribución/caché antes de release, más un license placeholder (`'TODO: Verify redistribution and caching terms before release'`) que llega al modelo de dominio (`TafsirEntry.license`). Además, la pantalla de debug de Tafsir está expuesta en el router de producción (`lib/main.dart:111-113`) gated solo por `kDebugMode`.
- **Riesgo:** Si se publica tal cual, un reviewer podría ver el TODO legal y rechazar el binario; si accidentalmente el flag se activa, la app muestra contenido con licencia desconocida (potencial infracción de copyright religiosa, delicado).
- **Prioridad:** Crítica.
- **Solución recomendada:** (1) Eliminar los TODOs o moverlos a issues; (2) quitar `TafsirDebugScreen` de `routes` (no compilar si no hay consumer); (3) sustituir el `license` placeholder por un valor real o nulo, y bloquear el path hasta verificar licencias con unIslamic/custodio.

### C-2. `PrivacyInfo.xcprivacy` ausente (obligatorio desde mayo 2024 para App Store)

- **Archivo afectado:** `ios/Runner/` (no existe), `ios/QiblaTimeWidget/`, `ios/PrayerWidget/`.
- **Explicación:** Apple exige desde Xcode 15.2/Submit 2024 que toda app que use UserDefaults, FileTimestamp, SystemBootTime, DiskSpace o API de disco declare motivos en `PrivacyInfo.xcprivacy`. La app usa `shared_preferences` (UserDefaults), `path_provider` (FileTimestamp/DiskSpace), `home_widget` (UserDefaults via App Group), `flutter_local_notifications` (DiskSpace vía `getApplicationSupportDirectory`). Solo `Pods/ReachabilitySwift/Sources/PrivacyInfo.xcprivacy` declara algo — la app principal y los dos widgets propios no declaran nada.
- **Riesgo:** App Store reject en la próxima submission, o eliminación retroactiva si Apple activa la validación.
- **Prioridad:** Crítica.
- **Solución recomendada:** Crear `ios/Runner/PrivacyInfo.xcprivacy`, `ios/QiblaTimeWidget/PrivacyInfo.xcprivacy` y `ios/PrayerWidget/PrivacyInfo.xcprivacy` declarando `NSPrivacyAccessedAPICategoryUserDefaults` (reason `CA92.1`), `NSPrivacyAccessedAPICategoryFileTimestamp` (reason `C617.1`), `NSPrivacyAccessedAPICategoryDiskSpace` (reason `E174.1`), `NSPrivacyAccessedAPICategorySystemBootTime` (reason `35F9.1`) si aplica. Incluir `NSPrivacyCollectedDataTypes` y `NSPrivacyTracking=false`.

### C-3. Email de contacto inconsistente entre marketing, política y código

- **Archivo afectado:** `lib/features/support/screens/support_screen.dart:78`, `lib/features/support/screens/support_screen.dart:118`, `PRIVACY_POLICY.md:153`, `README.md` (no aparece), `lib/features/onboarding/...` (no verificado), `pubspec.yaml` (no).
- **Explicación:** El README, el profile y la ficha de Play Store exponen `contact@qiblatime.app`, pero el `mailto:` real y la `description` de la tarjeta de soporte apuntan a `support.qiblatime@gmail.com` (Gmail personal, no dominio propio).
- **Riesgo:** (a) Apple/Google pueden marcar la app como "single-developer mismatch" si el email declarado en privacy no es respondible; (b) el desarrollador queda atado a una cuenta personal sin capacidad de delegación o recuperación.
- **Prioridad:** Crítica.
- **Solución recomendada:** Crear/confirmar `support@qiblatime.app` (o el que se decida), actualizar las dos líneas de `support_screen.dart` y la sección 11 de `PRIVACY_POLICY.md`, y verificar que el dominio está bajo control del desarrollador.

### C-4. Plantillas de notificación con claves sin traducir en 8 idiomas

- **Archivo afectado:** `lib/l10n/untranslated.json` (claves `settingsSectionQuran`, `settingsShowTafsir`, `settingsShowTafsirSubtitle` faltan en de/fr/id/it/nl/pt/ru/tr), `lib/features/support/screens/settings_screen.dart` (los consume).
- **Explicación:** `flutter gen-l10n` falla en CI cuando hay claves sin traducir. El proyecto lo evita con `--no-fatal-infos` en `codemagic.yaml` y `release_ios.sh`, así que el `untranslated.json` persiste y las claves se renderizan como claves crudas (`settingsSectionQuran`) en alemán/francés/italiano/holandés/portugués/ruso/turco/indonesio.
- **Riesgo:** (a) Pantallas de Settings en 8 idiomas muestran identificadores técnicos; (b) las plantillas de notificación (`notificationAdhanTitle`, `notificationAdhanBody`, etc.) pueden tener el mismo problema — sólo se ha verificado parcialmente en `untranslated.json`.
- **Prioridad:** Crítica (afecta a 8 de 11 mercados).
- **Solución recomendada:** (1) Traducir o eliminar las 3 claves huérfanas; (2) ejecutar `flutter gen-l10n` localmente hasta dejar `untranslated.json` vacío; (3) eliminar `--no-fatal-infos` de CI para que el fallo bloquee el build.

### C-5. R8/ProGuard deshabilitado en release (deuda técnica)

- **Archivo afectado:** `android/app/build.gradle:93-97`.
- **Explicación:** `buildTypes.release { minifyEnabled false; shrinkResources false }` con un comentario que dice "TEMP: disable R8/Proguard & resource shrinking to verify if minification breaks notifications". El `proguard-rules.pro` ya está cuidadosamente preparado para `flutter_local_notifications` (líneas 1-12), `home_widget`, `permission_handler`, Gson, etc. — esa preparación sugiere que el TEMP es resoluble pero nunca se cerró.
- **Riesgo:** APK/AAB más grande (~30-40% extra), código no ofuscado (reversibilidad trivial), sin tree-shaking de assets. Sin shrink, los `azan*.mp3` duplicados en `ios/Runner/` y los `res/raw/` de Android se quedan íntegros en cada build.
- **Prioridad:** Crítica.
- **Solución recomendada:** Re-habilitar `minifyEnabled true` + `shrinkResources true` en release, ejecutar smoke test del adhan (`NotificationService.sendTestNotification()`), commitear resultado. Mantener `minifyEnabled false` solo en debug. Las reglas proguard ya cubren `com.dexterous.**`.

---

## Hallazgos importantes

### I-1. `teamID` y Apple ID hardcodeados en scripts

- **Archivo afectado:** `ios/ExportOptions.plist:8` (`4XJTFN47FF`), `release_ios.sh:41`, `release_ios.sh:79` (`APPLE_ID` variable).
- **Explicación:** `teamID` está embebido tanto en el plist de export como en el shell script. La variable `APPLE_ID` se lee de `~/.zshrc` pero no se valida su existencia hasta tarde en el flujo (línea 75), y el shell script usa `xcrun altool --upload-app` (deprecated desde Xcode 14, App Store Connect API es lo correcto).
- **Riesgo:** Si en el futuro el proyecto cambia de equipo o cuenta de Apple, hay que tocar tres archivos. `altool` puede fallar silenciosamente y subir un IPA con credenciales cacheadas del usuario actual.
- **Prioridad:** Importante.
- **Solución recomendada:** (1) Extraer `APPLE_ID` y `APPLE_TEAM_ID` a un `.env` ignorado; (2) migrar `release_ios.sh` a `xcrun notarytool` + `xcrun altool` reemplazado por App Store Connect API (`xcrun appstoreconnect`); (3) añadir un `--dry-run` flag.

### I-2. Assets de audio azan commitados y duplicados MP3+CAF en el IPA

- **Archivo afectado:** `ios/Runner/azan1.mp3` (670 KB) … `azan4.mp3` (981 KB) y sus `.caf` equivalentes (11 MB + 5.9 MB + 17 MB + 18 MB). `lib/features/prayer_times/services/notification_service.dart:340-346` consume ambos formatos.
- **Explicación:** Cada adán está commiteado dos veces en el bundle de iOS (un MP3 + un CAF). Como el repo los versiona, cualquier PR que toque audio infla el `.git` de forma innecesaria. Además, el repo no contiene `android/app/src/main/res/raw/adhan_*.mp3` (los sonidos de Android vienen de assets, no de `res/raw`, lo cual es correcto para `flutter_local_notifications`).
- **Riesgo:** Binarios inflados (~50 MB de audio por IPA), tiempos de upload a TestFlight/App Store innecesariamente largos.
- **Prioridad:** Importante.
- **Solución recomendada:** Mover los originales a `assets/audio/` (ya están en pubspec), eliminar las copias de `ios/Runner/`, y dejar que iOS genere los CAF en build time (o usar `actool --convert-to-caf`). Versionar audio solo en `assets/audio/`.

### I-3. Múltiples `SharedPreferences.getInstance()` paralelos en lugar de inyectar el singleton

- **Archivo afectado:** `lib/core/services/storage_service.dart:12-14`, `lib/core/services/cloud_sync_service.dart:46-67`, `lib/core/services/settings_service.dart` (todas las llamadas), `lib/features/prayer_times/services/daily_inspiration_notification_service.dart:46-74`.
- **Explicación:** `StorageService.prefs` existe pero se coexiste con `await SharedPreferences.getInstance()` repartido por todo el código. Cada llamada re-resuelve la cache de `SharedPreferences` (que es lazy en realidad pero rompe la inversión de dependencias). En tests es muy difícil mockear.
- **Riesgo:** Acoplamiento fuerte al plugin, dificulta testing, riesgos de race en primer arranque cuando `StorageService.init()` aún no ha terminado y otra feature hace `getInstance()` por su cuenta.
- **Prioridad:** Importante.
- **Solución recomendada:** Eliminar todas las llamadas directas a `SharedPreferences.getInstance()` y forzar a pasar por `StorageService.prefs`. Añadir tests que verifiquen que `prefs` está inicializado antes de leer.

### I-4. `flutter analyze --no-fatal-infos` en CI oculta regresiones

- **Archivo afectado:** `codemagic.yaml:11`, `codemagic.yaml:30`, `release_ios.sh:30`.
- **Explicación:** Los workflows de Android e iOS usan `--no-fatal-infos`, lo que permite subir un binario con `info` lints sin bloquear. Junto con C-4 (untranslated keys), esto significa que el CI nunca falla por quality.
- **Riesgo:** Degradación silenciosa del código, claves de i18n sin traducir pasando, etc.
- **Prioridad:** Importante.
- **Solución recomendada:** Quitar `--no-fatal-infos`, dejar `flutter analyze` estricto. Si rompe por `info`, resolverlo (no enmascararlo).

### I-5. CloudSync crea `device_id` anónimo persistente sin UI para revisarlo/borrarlo

- **Archivo afectado:** `lib/core/services/cloud_sync_service.dart:71-78`, `lib/features/support/screens/settings_screen.dart:2183` (`getDeviceId`).
- **Explicación:** El servicio genera y persiste un ID aleatorio `anon-<timestamp>-<rand>` en Hive. La política de privacidad (sección 4) enumera qué datos locales se almacenan pero no menciona este identificador. La sección 8 ("right to erasure") del privacy policy dice que se borra con uninstall — correcto — pero el usuario no tiene UI para revisarlo o resetearlo dentro de la app.
- **Riesgo:** GDPR: el usuario puede alegar que no se le informa claramente de este identificador. Si en el futuro el ID se sube a un servidor, podría interpretarse como dato personal.
- **Prioridad:** Importante.
- **Solución recomendada:** (1) Documentar el `device_id` en PRIVACY_POLICY.md sección 4; (2) añadir opción "Reset sync ID" en Settings; (3) evaluar si realmente se necesita (si no se sube nunca, mejor no generarlo).

### I-6. Uso de `print()` en `AppDelegate.swift` en release

- **Archivo afectado:** `ios/Runner/AppDelegate.swift:59` (`print("Failed to configure AVAudioSession for Quran playback: \(error)")`).
- **Explicación:** `print` en Swift llega a `os_log`/`NSLog` y se queda en logs de sistema. En producción queda ruido en consola del dispositivo.
- **Riesgo:** Logs innecesarios; en builds de TestFlight/App Store pueden aparecer en `Console.app` para cualquiera con acceso al dispositivo.
- **Prioridad:** Importante.
- **Solución recomendada:** Usar `os.Logger` con categoría y nivel `.error` solo en debug; o eliminar el `print` directamente.

### I-7. `rootBundle.loadString` en paths críticos de startup puede bloquear primer frame

- **Archivo afectado:** `lib/features/quran/services/quran_service.dart:28-56` (`_parseQuranOfflineJson`), `lib/features/hadith/services/hadith_service.dart:19-24` (`_decodeHadithsJson`), `lib/core/services/storage_service.dart:18-22`.
- **Explicación:** El JSON offline de Quran (3.7 MB) y el dataset de hadices (22 MB) se decodifican en `compute()` con isolate, lo cual está bien. Pero `StorageService.init()` abre 4 Hive boxes en serie en el main thread antes de mostrar el primer frame, y `main.dart` lo llama en `_prepareCriticalStartup`. Si Hive tiene IO bloqueante (primera apertura), el splash puede colgar.
- **Riesgo:** TTI alto en cold start, ANR en dispositivos low-end con bases de datos grandes.
- **Prioridad:** Importante.
- **Solución recommandée:** Medir el tiempo de cada `Hive.openBox`; si >100 ms, moverlos a un `Future.microtask` post-first-frame. Considerar `openBox` con `lazy: true` donde aplique.

### I-8. Hadith offline service es un stub

- **Archivo afectado:** `lib/features/hadith/services/hadith_offline_service.dart:27-31` (`markCollectionAsDownloaded`, `markAllCollectionsAsDownloaded`, `removeCollection` son no-ops), `:58-60` (`isAllHadithsAvailable` retorna `true` siempre).
- **Explicación:** El servicio "offline" reporta estado que no refleja la realidad: `getStatus()` siempre devuelve `isFullyOffline: true` y todos los "marcadores" no hacen nada. Como el hadith principal vive en `hadiths_multilang_v2.json` (assets), el stub puede no importar — pero si el usuario entra a Settings → Hadices → "Downloaded collections", verá una UI inconsistente con la realidad.
- **Riesgo:** UX confusa si la feature "Download collections" está visible; fricción si más adelante se quiere realmente sincronizar.
- **Prioridad:** Importante.
- **Solución recomendada:** Eliminar los métodos stub o documentar `// TODO: implement when backend exists`; limpiar Settings de las opciones que llaman a estos métodos.

---

## Hallazgos medios

### M-1. `qiblaService.dart` no se compila si `flutter_compass` no expone eventos

- **Archivo afectado:** `lib/features/qibla/services/qibla_service.dart:8-17`.
- **Explicación:** `_compassEventStream = FlutterCompass.events;` se evalúa en top-level al cargar el módulo. Si la plataforma no expone eventos, `compassProvider` entra en estado de error y la pantalla muestra `qiblaCompassInitError` correctamente — pero `FlutterCompass.events` es una property no-nullable en versiones recientes, lo que puede causar warnings.
- **Riesgo:** Build verde con `flutter analyze` mostrando un lint, no falla.
- **Prioridad:** Media.
- **Solución recomendada:** Mover la inicialización a `compassProvider` y verificar `events == null` en runtime, no en top-level.

### M-2. `qiblaScreen.dart` tiene 509 líneas con varios sub-builders privados

- **Archivo afectado:** `lib/features/qibla/screens/qibla_screen.dart`.
- **Explicación:** Una sola clase `ConsumerWidget` con 7 builders privados (`_buildHeader`, `_buildDistanceCard`, `_buildStat`, `_buildCompass`, `_buildLoading`, `_buildError`, `_buildLocationIssue`, `_buildInfoDialog`, `_infoRow`). El método `build` (línea 18-123) anida 5 `when()` con lógica de UI.
- **Riesgo:** Difícil de leer/testear; cualquier cambio toca un único archivo gigante.
- **Prioridad:** Media.
- **Solución recomendada:** Extraer `QiblaCompassDial`, `QiblaDistanceCard`, `QiblaDirectionLabel` a `widgets/`.

### M-3. Logger escribe a `debugPrint` que va a `print` en release

- **Archivo afectado:** `lib/core/services/logger_service.dart:14` (`minimumLevel = kDebugMode ? debug : info`), `:45-53` (usa `debugPrint`).
- **Explicación:** En release, `debugPrint` se sigue imprimiendo (con throttling). El nivel mínimo es `info`, así que cada `info()` queda en logs. Si tienes 100 `info()` por arranque, son 100 líneas en `adb logcat`/`Console.app`.
- **Riesgo:** Ruido en logs, en `adb logcat` puede competir con crashes reales.
- **Prioridad:** Media.
- **Solución recomendada:** En release, elevar el nivel mínimo a `warning` o `error`. O enviar a Crashlytics/Sentry solo errores.

### M-4. Métodos `sendTestNotification` y `scheduleTestAdhanInOneMinute` en producción

- **Archivo afectado:** `lib/features/prayer_times/services/notification_service.dart:591-603`, `:608-691`. Consumidos en `lib/features/support/screens/settings_screen.dart:733` y `lib/features/prayer_times/services/daily_inspiration_notification_service.dart:215-224`.
- **Explicación:** Settings tiene un botón "Test adhan in 1 minute" que dispara un adhan real 60 segundos después. Útil en QA pero cualquier usuario puede tocarlo accidentalmente y escuchar el adhan completo en mitad de una reunión.
- **Riesgo:** UX hostil, falsa alarma en la familia del usuario.
- **Prioridad:** Media.
- **Solución recomendada:** Mantenerlo detrás de un toggle debug en Settings, o requerir doble confirmación. Eliminar `sendTestNotification` del flujo de Settings en release.

### M-5. `TafsirDebugScreen` registrado como ruta de MaterialApp (gated por `kDebugMode`)

- **Archivo afectado:** `lib/main.dart:111-113`.
- **Explicación:** Aunque está gated por `kDebugMode`, el archivo existe y se compila en release builds (Dart no elimina rutas por constante). Solo el routing lo oculta. Si en algún build de release `kDebugMode` se desactiva por error (p.ej. un `flutter build apk --release --debug`), la pantalla es accesible vía deep link `/debug/tafsir`.
- **Riesgo:** Acceso a debug interno.
- **Prioridad:** Media.
- **Solución recomendada:** Mover el archivo a `lib/features/tafsir/debug/`, importar solo dentro de un `if (kDebugMode)` wrapper, o eliminarlo de `routes` y mantenerlo solo accesible por navegación interna debug.

### M-6. `AudioSession` configurado en `AppDelegate` pero `AudioService` también lo setea

- **Archivo afectado:** `ios/Runner/AppDelegate.swift:55-60`, `lib/core/services/audio_service.dart:11-15` (`_defaultAudioContext`).
- **Explicación:** Doble configuración: Swift pone `.playback` al iniciar la app, luego Dart lo reespecifica. No causa problema, pero el comentario de Swift dice "for Quran playback" cuando realmente la app reproduce audio de adhan también.
- **Riesgo:** Confusión sobre quién controla la sesión; en un futuro debug de audio mixto (adhan + quran), puede no quedar claro qué política aplicar.
- **Prioridad:** Media.
- **Solución recomendada:** Centralizar la configuración en `AudioService._configuredPlayer()` (ya existe) y dejar Swift sin tocar `AVAudioSession`.

### M-7. `adhan` library 2.0.0+1 sin sobrescribir; verificar método de cálculo por defecto

- **Archivo afectado:** `lib/core/services/settings_service.dart:81-82` (`getCalculationMethod() ?? 1`).
- **Explicación:** El default es `1` (Muslim World League), razonable para occidente/Europa, pero Arabia Saudí usa Umm Al-Qura (4). No es un bug, pero la primera ejecución en un usuario de Riad verá horarios MWL hasta que cambie el método manualmente.
- **Riesgo:** Discrepancia con horarios oficiales locales en mercados musulmanes.
- **Prioridad:** Media.
- **Solución recomendada:** Auto-detectar por `Locale.countryCode` (p.ej. `SA` → 4, `TR` → 5, `PK` → 1, `IR` → 7) en el primer arranque.

### M-8. `adhan-checklist.txt`, `PROXIMITY_DIAGNOSIS.md`, `flutter_NN.log` commiteados

- **Archivo afectado:** raíz del repo.
- **Explicación:** Varios archivos de operativa/diagnóstico en la raíz que no aportan al repo público. `flutter_*.log` se regeneran en cada `flutter run`; `PROXIMITY_DIAGNOSIS.md` es un análisis histórico; `adhan-checklist.txt` es un planning note.
- **Riesgo:** Repo más grande de lo necesario; reviewers distraídos.
- **Prioridad:** Media.
- **Solución recomendada:** Mover a `docs/internal/` y añadir al `.gitignore` los `.log`.

### M-9. Scripts Python de mantenimiento (root level) sin documentación de cuándo correrlos

- **Archivo afectado:** `download_hadiths.py`, `generate_quran_offline.py`, y ~25 archivos `add_*.py`, `check_*.py`, `translate_*.py`, etc. en raíz (ya filtrados por `.gitignore` pero los que quedan visibles como `download_hadiths.py` están sueltos).
- **Explicación:** Hay un ecosistema de scripts Python de mantenimiento mezclados con la app Flutter. No hay un `Makefile` o equivalente que diga "para regenerar X corre Y".
- **Riesgo:** Si vienen nuevos colaboradores o vuelves en 6 meses, no sabes qué script toca qué.
- **Prioridad:** Media.
- **Solución recomendada:** Mover todos los `.py` a `tools/` o `scripts/`, crear un `tools/README.md` con tabla: script → propósito → cuándo correr.

### M-10. `Tafsir` devuelve `TafsirLoadSource.unavailable` con un debugInfo persistente

- **Archivo afectado:** `lib/features/tafsir/services/tafsir_service.dart:201-227`.
- **Explicación:** Cuando Tafsir falla, se devuelve un `TafsirLoadResult` con `debugInfo` que puede contener detalles del último intento. Si el UI los muestra al usuario final, se filtra info interna.
- **Riesgo:** Information disclosure menor.
- **Prioridad:** Media.
- **Solución recomendada:** Sanitizar `debugInfo` antes de exponerlo al UI; mantenerlo solo en logs.

### M-11. `package-lock.json` en raíz no excluido explícitamente de git (solo ignorado)

- **Archivo afectado:** `.gitignore:61` (`package-lock.json`), `package.json` raíz.
- **Explicación:** El repo tiene un `package.json` raíz (scripts Node de traducción) pero el `.gitignore` ignora `package-lock.json`. Si dos personas corren `npm install` obtendrán versiones distintas.
- **Riesgo:** Builds de traducción no reproducibles.
- **Prioridad:** Media.
- **Solución recomendada:** Commitear `package-lock.json` o mover el `package.json` a `scripts/` y commitear el lock de ahí.

### M-12. `quranService.dart` mezcla `_baseUrl` y `_quranComBaseUrl` con timeouts iguales

- **Archivo afectado:** `lib/features/quran/services/quran_service.dart:108-114`, `:280-290`.
- **Explicación:** `api.alquran.cloud` y `api.quran.com` se llaman en paralelo con el mismo timeout de 8s. Si una está lenta y la otra rápida, el usuario espera 8s cuando podría tener la rápida en 2s.
- **Riesgo:** Latencia percibida mayor de la necesaria.
- **Prioridad:** Media.
- **Solución recomendada:** `Future.wait` con `eagerError: false` y fallback progresivo, o usar `any.completer` con timeouts escalonados.

### M-13. `QuranWordRemoteService` no tiene rate limiting ni backoff

- **Archivo afectado:** `lib/features/quran/services/quran_word_service.dart:148-227`.
- **Explicación:** Bucle paginado a Quran.com API sin retry/backoff. Si la API responde 429, se lanza `FormatException` y se cae al asset local.
- **Riesgo:** Caídas innecesarias al fallback en picos de tráfico.
- **Prioridad:** Media.
- **Solución recomendada:** Backoff exponencial + respeto de headers `Retry-After`.

---

## Hallazgos menores

### m-1. `LICENSE` dice "Copyright (c) 2026" — confirmar año correcto

- **Archivo afectado:** `LICENSE:3`.
- **Explicación:** Año 2026 en un repo que aún está en desarrollo. Probablemente intencional (la app no se libera hasta 2026), pero conviene verificar.
- **Riesgo:** Cosmético/legal.
- **Prioridad:** Menor.
- **Solución recomendada:** Confirmar con el mantenedor.

### m-2. `README.md` menciona `go_router` pero pubspec no lo incluye

- **Archivo afectado:** `README.md:71`, `pubspec.yaml`.
- **Explicación:** La sección "Tech Stack" lista go_router pero pubspec no lo declara. Probablemente se cambió a Navigator 2.0 manual.
- **Riesgo:** Documentación desactualizada.
- **Prioridad:** Menor.
- **Solución recomendada:** Quitar la fila de go_router o añadir el paquete.

### m-3. `pubspec.yaml` lista `home_widget: 0.9.0` (versión desactualizada)

- **Archivo afectado:** `pubspec.yaml:37`.
- **Explicación:** La última versión estable de `home_widget` es 0.7+; 0.9.0 puede no existir todavía o ser pre-release.
- **Riesgo:** Confusión al hacer `flutter pub upgrade`.
- **Prioridad:** Menor.
- **Solución recomendada:** Confirmar que 0.9.0 existe en pub.dev; si no, fijar la última estable.

### m-4. `analysis_options.yaml` sin reglas adicionales al set de Flutter

- **Archivo afectado:** `analysis_options.yaml:23-25`.
- **Explicación:** Las reglas personalizadas están comentadas (`# avoid_print: false`, `# prefer_single_quotes: true`). El proyecto podría beneficiarse de `prefer_single_quotes`, `require_trailing_commas`, `unawaited_futures`, `sort_constructors_first`.
- **Riesgo:** Inconsistencias de estilo.
- **Prioridad:** Menor.
- **Solución recomendada:** Habilitar `prefer_single_quotes` y `require_trailing_commas` para mejorar diff legibility.

### m-5. `scheduleTestAdhanInOneMinute` retorna `AdhanScheduleResult` pero `AdhanManager` lo invoca con `await` ignorando el resultado

- **Archivo afectado:** `lib/features/prayer_times/services/notification_service.dart:591-603`, `lib/features/support/screens/settings_screen.dart:259`.
- **Explicación:** El caller ignora el `AdhanScheduleResult`, así que si el permiso de exact-alarm falta, el usuario toca "Test" y no pasa nada sin mensaje.
- **Riesgo:** UX confusa en QA.
- **Prioridad:** Menor.
- **Solución recomendada:** Mostrar SnackBar según el resultado.

### m-6. `QuranService.allSurahs` es estática pero `_offlineCache` también lo es

- **Archivo afectado:** `lib/features/quran/services/quran_service.dart:82-83` (provider estático), `:116` (cache estática).
- **Explicación:** En tests, no hay forma de resetear el cache entre casos. Los 3 tests de quran en `test/features/quran/` lo confirman (smoke tests, no reset).
- **Riesgo:** Estado compartido entre tests.
- **Prioridad:** Menor.
- **Solución recomendada:** Añadir `@visibleForTesting static void resetForTesting()`.

### m-7. `AppLogger` no envía a Crashlytics/Sentry — pero la app declara "no tracking"

- **Archivo afectado:** `lib/core/services/logger_service.dart`.
- **Explicación:** Sin telemetría, no hay forma de detectar crashes en producción. Esto es coherente con la política de privacidad (no tracking) pero operacionalmente limitante.
- **Riesgo:** Ceguera operativa post-release.
- **Prioridad:** Menor.
- **Solución recomendada:** Considerar un logger local que vuelque a un archivo accesible desde Settings → "Export logs" para soporte.

### m-8. `home_widget` references en `lib/features/prayer_times/services/widget_sync_service.dart` — el widget Android existe, el iOS existe, pero el sincronizado se hace solo desde el lado Dart

- **Archivo afectado:** `lib/features/prayer_times/services/widget_sync_service.dart:9-11`, `lib/main.dart:40-41` (`WidgetSyncService().configure` solo en startup).
- **Explicación:** El widget solo se sincroniza en arranque y cuando alguien llama `syncNextPrayer`. No hay un Timer/Stream que empuje periódicamente.
- **Riesgo:** El widget puede mostrar datos viejos si el usuario deja la app cerrada varios días.
- **Prioridad:** Menor.
- **Solución recomendada:** Cada vez que `AdhanManager.scheduleTodayAdhans` corre, también llamar `syncNextPrayer`. El `scheduleTodayAdhans` ya se ejecuta en `main()` post-startup.

### m-9. `flutter_compass` 0.8.1 tiene conocido issue con iOS 17+ (calibración falsa)

- **Archivo afectado:** `pubspec.yaml:19`.
- **Explicación:** Reportes en pub.dev sobre heading inexacto en iOS 17+.
- **Riesgo:** Brújula puede mostrar 20-30° off en ciertos dispositivos.
- **Prioridad:** Menor (no es bug de la app).
- **Solución recomendada:** Esperar upstream; añadir fallback "calibra tu brújula" en UI.

### m-10. No hay archivo `CONTRIBUTING.md`

- **Archivo afectado:** raíz.
- **Explicación:** El README dice "Pull requests are reviewed on a best-effort basis" pero no hay guidelines.
- **Riesgo:** PRs de baja calidad.
- **Prioridad:** Menor.
- **Solución recomendada:** Añadir `CONTRIBUTING.md` con checklist de tests, lints, screenshots.

---

## Top 10 problemas detectados

| # | ID | Archivo afectado | Resumen | Prioridad |
|---|---|---|---|---|
| 1 | C-1 | `lib/features/tafsir/services/tafsir_service.dart:82-83,206-207` | Tafsir con TODOs legales y license placeholder en producción | Crítica |
| 2 | C-2 | `ios/Runner/` | Falta `PrivacyInfo.xcprivacy` (obligatorio Apple 2024) | Crítica |
| 3 | C-3 | `lib/features/support/screens/support_screen.dart:78,118` | Email de contacto inconsistente (Gmail vs dominio propio) | Crítica |
| 4 | C-4 | `lib/l10n/untranslated.json` | Claves i18n sin traducir en 8 idiomas (de/fr/id/it/nl/pt/ru/tr) | Crítica |
| 5 | C-5 | `android/app/build.gradle:93-97` | R8/ProGuard deshabilitado en release con TEMP sin cerrar | Crítica |
| 6 | I-1 | `ios/ExportOptions.plist`, `release_ios.sh` | `teamID` hardcodeado + `altool` deprecated | Importante |
| 7 | I-2 | `ios/Runner/azan*.mp3/.caf` | ~50 MB de audio duplicado MP3+CAF en cada IPA | Importante |
| 8 | I-5 | `lib/core/services/cloud_sync_service.dart:71-78` | `device_id` anónimo persistente no documentado en privacy policy | Importante |
| 9 | I-7 | `lib/core/services/storage_service.dart:18-22` | 4 Hive `openBox` en serie en main thread antes de primer frame | Importante |
| 10 | M-4 | `lib/features/prayer_times/services/notification_service.dart:591,608` | `sendTestNotification` accesible desde Settings en producción | Media |

---

## Top 10 mejoras recomendadas

| # | Mejora | Impacto | Esfuerzo |
|---|---|---|---|
| 1 | Crear `PrivacyInfo.xcprivacy` para Runner, QiblaTimeWidget y PrayerWidget con motivos CA92.1, C617.1, E174.1 | Desbloquea App Store submission | Bajo (1-2h) |
| 2 | Re-habilitar `minifyEnabled true` + `shrinkResources true` en release de Android y validar flujo de adhan | -30-40% tamaño AAB, código ofuscado | Bajo-Medio (medio día con QA) |
| 3 | Traducir las 3 claves de `untranslated.json` (o eliminarlas) y quitar `--no-fatal-infos` de CI | Calidad 8/11 idiomas; CI estricto | Bajo (1 día con traductor) |
| 4 | Eliminar TODOs legales de Tafsir o mover a issues; quitar `TafsirDebugScreen` de producción | Reduce riesgo de App Store reject | Bajo (2-3h) |
| 5 | Mover audio azan a `assets/audio/` y eliminar duplicados MP3+CAF de `ios/Runner/`; generar CAF en build time | -50 MB por IPA | Bajo (1h + testflight) |
| 6 | Centralizar `SharedPreferences.getInstance()` en `StorageService.prefs` y migrar callers | Testabilidad, robustez | Medio (1-2 días) |
| 7 | Sustituir `support.qiblatime@gmail.com` por email de dominio propio y actualizar privacy policy + UI | Coherencia de marca, GDPR | Bajo (30 min) |
| 8 | Migrar `release_ios.sh` a App Store Connect API (no `altool`) y externalizar `APPLE_ID`/`TEAM_ID` a `.env` | Pipeline robusto | Medio (medio día) |
| 9 | Refactor `qibla_screen.dart` (509 líneas) en widgets separados (`QiblaCompassDial`, `QiblaDistanceCard`) | Mantenibilidad | Bajo-Medio (medio día) |
| 10 | Documentar `device_id` del CloudSync en PRIVACY_POLICY.md sección 4 y añadir opción "Reset sync ID" | Compliance GDPR | Bajo (1h) |

---

## Checklist antes de publicar

### Código y configuración
- [ ] Eliminar/quitar TODOs de `lib/features/tafsir/services/tafsir_service.dart` y `tafsir_api_client.dart`
- [ ] Eliminar `TafsirDebugScreen` de `routes` en `lib/main.dart:111-113` o compilar condicional
- [ ] Re-habilitar `minifyEnabled true` y `shrinkResources true` en `android/app/build.gradle`
- [ ] Re-correr `flutter build apk --release` y verificar que el adhan suena (ProGuard no rompió `com.dexterous.**`)
- [ ] Re-correr `flutter build ipa --release` sin `ExportOptions.plist` y validar tamaño
- [ ] Mover archivos de audio de `ios/Runner/azan*.mp3` y `azan*.caf` a `assets/audio/` (o a `ios/Resources/`) y versionar solo los originales
- [ ] Mover scripts Python sueltos de raíz a `tools/` y crear `tools/README.md`
- [ ] Quitar `adhan-checklist.txt`, `PROXIMITY_DIAGNOSIS.md`, `flutter_*.log` del repo (añadir a `.gitignore`)
- [ ] Resolver el `teamID` hardcodeado: o commitear el correcto (es público) o dejarlo a través de variable de CI
- [ ] Sustituir `print(...)` de `ios/Runner/AppDelegate.swift:59` por `os.Logger` o eliminarlo
- [ ] Subir el nivel mínimo de `AppLogger` a `warning` en release (o enviar errores a Crashlytics local)

### Localización
- [ ] Vaciar `lib/l10n/untranslated.json` (traducir las 3 claves o eliminarlas)
- [ ] Ejecutar `flutter gen-l10n` y verificar 0 warnings
- [ ] Quitar `--no-fatal-infos` de `codemagic.yaml` y `release_ios.sh`
- [ ] Revisar manualmente las pantallas de Settings en alemán, francés, italiano, holandés, portugués, ruso, turco e indonesio
- [ ] Verificar plantillas de notificación (`notificationAdhanTitle`, `notificationAdhanBody`, `notificationAdhanChannelName/Description`) en los 11 idiomas

### iOS
- [ ] Crear `ios/Runner/PrivacyInfo.xcprivacy`, `ios/QiblaTimeWidget/PrivacyInfo.xcprivacy`, `ios/PrayerWidget/PrivacyInfo.xcprivacy`
- [ ] Declarar `NSPrivacyAccessedAPICategoryUserDefaults` (CA92.1), `NSPrivacyAccessedAPICategoryFileTimestamp` (C617.1), `NSPrivacyAccessedAPICategoryDiskSpace` (E174.1) si aplica
- [ ] Añadir `NSPrivacyTracking=false` y `NSPrivacyCollectedDataTypes=[]`
- [ ] Verificar que `UIBackgroundModes` solo contiene `audio` (es correcto, no tocar)
- [ ] Validar Info.plist en Xcode para ATS: solo HTTPS permitido
- [ ] Migrar de `xcrun altool` a `xcrun notarytool` + App Store Connect API
- [ ] Confirmar App Store ID `id6771987364` está bien y coincide con la cuenta

### Android
- [ ] Confirmar `compileSdk 36` y `targetSdk 35` en línea con la política de Play Store
- [ ] Re-validar permisos en `AndroidManifest.xml`: `WRITE_EXTERNAL_STORAGE` está limitado a SDK 28 — confirmar que ya no se usa en runtime
- [ ] Validar `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` declarando claramente el motivo (ya hay un comentario, OK)
- [ ] Verificar `multiDexEnabled true` (correcto para muchas dependencias)
- [ ] Confirmar `signingConfigs.release` lee de `key.properties` con el placeholder-check (ya implementado, OK)

### Privacidad y legal
- [ ] Actualizar PRIVACY_POLICY.md sección 11 con email de dominio propio
- [ ] Añadir mención del `device_id` anónimo de CloudSync en sección 4
- [ ] Verificar que la sección 5.4 (Tafsir) sigue vigente — si Tafsir sigue deshabilitado, moverlo a "Future" o eliminarlo
- [ ] Confirmar que el texto de marketing (README, Play Store listing) coincide con lo implementado (especialmente "Tafsir" y "Word-by-Word")
- [ ] Verificar que las URLs externas declaradas (everyayah.com, islamhouse.com, alquran.cloud, quran.com, cdn.islamic.network) están operativas y tienen TOS compatibles

### Tests
- [ ] Confirmar que `flutter test` pasa (28 tests, ejecutar localmente)
- [ ] Añadir test que valide `_canScheduleExactAlarm` retorna false en Android 12 sin permiso
- [ ] Añadir test que valide el fallback offline cuando `api.alquran.cloud` no responde
- [ ] Validar manualmente el flow de adhan en un dispositivo físico (Xiaomi/Samsung con battery saver agresivo)

### Verificación final
- [ ] `flutter analyze` limpio (sin `--no-fatal-infos`)
- [ ] `flutter test --coverage` con cobertura >60% en `lib/core/` y `lib/features/prayer_times/`
- [ ] Build de Android (AAB) reproducible con `--split-per-abi` opcional
- [ ] Build de iOS (IPA) reproducible y subido a TestFlight con grupo de testers internos
- [ ] Smoke test del flujo completo: onboarding → permisos → primera oración → qibla → quran play → adhan test → settings backup
- [ ] Verificar `flutter build appbundle --release` tamaño final <30 MB
- [ ] Verificar `flutter build ipa --release` tamaño final <50 MB (idealmente <40 tras deduplicar audio)
