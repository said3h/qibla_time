import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen_l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('es')
  ];

  /// No description provided for @appTitle.
  ///
  /// In es, this message translates to:
  /// **'Qibla Time'**
  String get appTitle;

  /// No description provided for @commonSkip.
  ///
  /// In es, this message translates to:
  /// **'Saltar'**
  String get commonSkip;

  /// No description provided for @commonBack.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get commonBack;

  /// No description provided for @commonContinue.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get commonContinue;

  /// No description provided for @commonEnter.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get commonEnter;

  /// No description provided for @commonAllow.
  ///
  /// In es, this message translates to:
  /// **'Permitir'**
  String get commonAllow;

  /// No description provided for @commonActivate.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get commonActivate;

  /// No description provided for @commonEnable.
  ///
  /// In es, this message translates to:
  /// **'Activar'**
  String get commonEnable;

  /// No description provided for @commonEnableGps.
  ///
  /// In es, this message translates to:
  /// **'Activar GPS'**
  String get commonEnableGps;

  /// No description provided for @commonOpenSettings.
  ///
  /// In es, this message translates to:
  /// **'Abrir ajustes'**
  String get commonOpenSettings;

  /// No description provided for @commonPending.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get commonPending;

  /// No description provided for @commonGranted.
  ///
  /// In es, this message translates to:
  /// **'Concedido'**
  String get commonGranted;

  /// No description provided for @commonBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueado'**
  String get commonBlocked;

  /// No description provided for @commonReady.
  ///
  /// In es, this message translates to:
  /// **'Lista'**
  String get commonReady;

  /// No description provided for @commonDisabled.
  ///
  /// In es, this message translates to:
  /// **'Desactivado'**
  String get commonDisabled;

  /// No description provided for @commonUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No disponible'**
  String get commonUnavailable;

  /// No description provided for @commonToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get commonYesterday;

  /// No description provided for @commonLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando...'**
  String get commonLoading;

  /// No description provided for @commonShare.
  ///
  /// In es, this message translates to:
  /// **'Compartir'**
  String get commonShare;

  /// No description provided for @commonManual.
  ///
  /// In es, this message translates to:
  /// **'Manual'**
  String get commonManual;

  /// No description provided for @commonImportJson.
  ///
  /// In es, this message translates to:
  /// **'Importar JSON'**
  String get commonImportJson;

  /// No description provided for @commonExport.
  ///
  /// In es, this message translates to:
  /// **'Exportar'**
  String get commonExport;

  /// No description provided for @commonOpen.
  ///
  /// In es, this message translates to:
  /// **'Abrir'**
  String get commonOpen;

  /// No description provided for @commonVersion.
  ///
  /// In es, this message translates to:
  /// **'Versión'**
  String get commonVersion;

  /// No description provided for @commonAbout.
  ///
  /// In es, this message translates to:
  /// **'Acerca de'**
  String get commonAbout;

  /// No description provided for @commonMethod.
  ///
  /// In es, this message translates to:
  /// **'Método'**
  String get commonMethod;

  /// No description provided for @commonMadhab.
  ///
  /// In es, this message translates to:
  /// **'Madhab'**
  String get commonMadhab;

  /// No description provided for @commonLocation.
  ///
  /// In es, this message translates to:
  /// **'Ubicación'**
  String get commonLocation;

  /// No description provided for @commonNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones'**
  String get commonNotifications;

  /// No description provided for @commonNoData.
  ///
  /// In es, this message translates to:
  /// **'Sin datos'**
  String get commonNoData;

  /// No description provided for @commonNever.
  ///
  /// In es, this message translates to:
  /// **'Nunca'**
  String get commonNever;

  /// No description provided for @commonGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando...'**
  String get commonGenerating;

  /// No description provided for @commonChecking.
  ///
  /// In es, this message translates to:
  /// **'Comprobando...'**
  String get commonChecking;

  /// No description provided for @commonDelete.
  ///
  /// In es, this message translates to:
  /// **'Borrar'**
  String get commonDelete;

  /// No description provided for @commonSystemStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado del sistema'**
  String get commonSystemStatus;

  /// No description provided for @commonCurrentStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado actual'**
  String get commonCurrentStatus;

  /// No description provided for @commonOffset.
  ///
  /// In es, this message translates to:
  /// **'Offset'**
  String get commonOffset;

  /// No description provided for @commonAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Automática'**
  String get commonAutomatic;

  /// No description provided for @commonPrepared.
  ///
  /// In es, this message translates to:
  /// **'Preparadas'**
  String get commonPrepared;

  /// No description provided for @commonActivated.
  ///
  /// In es, this message translates to:
  /// **'Activadas'**
  String get commonActivated;

  /// No description provided for @commonPaused.
  ///
  /// In es, this message translates to:
  /// **'Pausadas'**
  String get commonPaused;

  /// No description provided for @commonSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get commonSystem;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Qibla Time'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios, Qibla, Corán y recordatorios en una app ligera para tu rutina diaria.'**
  String get onboardingWelcomeSubtitle;

  /// No description provided for @onboardingFeatureSchedulesTitle.
  ///
  /// In es, this message translates to:
  /// **'Horarios fiables'**
  String get onboardingFeatureSchedulesTitle;

  /// No description provided for @onboardingFeatureSchedulesBody.
  ///
  /// In es, this message translates to:
  /// **'Calculados según tu ubicación y tu método preferido.'**
  String get onboardingFeatureSchedulesBody;

  /// No description provided for @onboardingFeaturePracticeTitle.
  ///
  /// In es, this message translates to:
  /// **'Qibla y práctica diaria'**
  String get onboardingFeaturePracticeTitle;

  /// No description provided for @onboardingFeaturePracticeBody.
  ///
  /// In es, this message translates to:
  /// **'Brújula, tasbih, seguimiento y más en el mismo flujo.'**
  String get onboardingFeaturePracticeBody;

  /// No description provided for @onboardingFeatureRemindersTitle.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios útiles'**
  String get onboardingFeatureRemindersTitle;

  /// No description provided for @onboardingFeatureRemindersBody.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones de adhan y ajustes listos desde el primer día.'**
  String get onboardingFeatureRemindersBody;

  /// No description provided for @onboardingPermissionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Permisos importantes'**
  String get onboardingPermissionsTitle;

  /// No description provided for @onboardingPermissionsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te pedimos solo lo necesario para calcular horarios, usar Qibla y avisarte a tiempo.'**
  String get onboardingPermissionsSubtitle;

  /// No description provided for @onboardingLocationReadyBody.
  ///
  /// In es, this message translates to:
  /// **'Lista para calcular horarios y Qibla.'**
  String get onboardingLocationReadyBody;

  /// No description provided for @onboardingLocationBlockedBody.
  ///
  /// In es, this message translates to:
  /// **'El permiso está bloqueado. Puedes activarlo después desde los ajustes del sistema.'**
  String get onboardingLocationBlockedBody;

  /// No description provided for @onboardingLocationGpsOffBody.
  ///
  /// In es, this message translates to:
  /// **'El GPS del dispositivo está desactivado. Puedes seguir y activarlo después.'**
  String get onboardingLocationGpsOffBody;

  /// No description provided for @onboardingLocationPendingBody.
  ///
  /// In es, this message translates to:
  /// **'Necesaria para horarios precisos y dirección a La Meca.'**
  String get onboardingLocationPendingBody;

  /// No description provided for @onboardingNotificationsReadyBody.
  ///
  /// In es, this message translates to:
  /// **'Listas para recordarte las oraciones.'**
  String get onboardingNotificationsReadyBody;

  /// No description provided for @onboardingNotificationsPendingBody.
  ///
  /// In es, this message translates to:
  /// **'Así podrás recibir avisos de adhan y recordatorios más adelante.'**
  String get onboardingNotificationsPendingBody;

  /// No description provided for @onboardingMethodTitle.
  ///
  /// In es, this message translates to:
  /// **'Método de cálculo'**
  String get onboardingMethodTitle;

  /// No description provided for @onboardingMethodSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Puedes cambiarlo más tarde, pero esto deja los horarios bien configurados desde hoy.'**
  String get onboardingMethodSubtitle;

  /// No description provided for @onboardingSelectedNow.
  ///
  /// In es, this message translates to:
  /// **'Seleccionado ahora'**
  String get onboardingSelectedNow;

  /// No description provided for @onboardingTapToChooseMethod.
  ///
  /// In es, this message translates to:
  /// **'Toca para elegir este método'**
  String get onboardingTapToChooseMethod;

  /// No description provided for @onboardingMadhabTitle.
  ///
  /// In es, this message translates to:
  /// **'Madhab para Asr'**
  String get onboardingMadhabTitle;

  /// No description provided for @onboardingMadhabSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Solo afecta al cálculo de la oración de Asr. Si dudas, puedes dejar Shafi y cambiarlo después.'**
  String get onboardingMadhabSubtitle;

  /// No description provided for @onboardingMadhabCommonTitle.
  ///
  /// In es, this message translates to:
  /// **'Shafi / Maliki / Hanbali'**
  String get onboardingMadhabCommonTitle;

  /// No description provided for @onboardingMadhabCommonSubtitle.
  ///
  /// In es, this message translates to:
  /// **'La opción más común para empezar'**
  String get onboardingMadhabCommonSubtitle;

  /// No description provided for @onboardingMadhabHanafiTitle.
  ///
  /// In es, this message translates to:
  /// **'Hanafi'**
  String get onboardingMadhabHanafiTitle;

  /// No description provided for @onboardingMadhabHanafiSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa el cálculo hanafí para Asr'**
  String get onboardingMadhabHanafiSubtitle;

  /// No description provided for @onboardingAdhanTitle.
  ///
  /// In es, this message translates to:
  /// **'Adhan y avisos'**
  String get onboardingAdhanTitle;

  /// No description provided for @onboardingAdhanSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Qibla Time puede avisarte de cada oración con un adhan suave por defecto. Después podrás cambiarlo.'**
  String get onboardingAdhanSubtitle;

  /// No description provided for @onboardingPrayerNotificationsTitle.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones de oración'**
  String get onboardingPrayerNotificationsTitle;

  /// No description provided for @onboardingPrayerNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Puedes activarlas o seguir sin ellas por ahora.'**
  String get onboardingPrayerNotificationsSubtitle;

  /// No description provided for @onboardingAdhanPreviewTitle.
  ///
  /// In es, this message translates to:
  /// **'Prueba rápida del adhan'**
  String get onboardingAdhanPreviewTitle;

  /// No description provided for @onboardingAdhanPreviewSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se usará el sonido que tengas seleccionado. Puedes cambiarlo después en Ajustes.'**
  String get onboardingAdhanPreviewSubtitle;

  /// No description provided for @onboardingAdhanStopPreview.
  ///
  /// In es, this message translates to:
  /// **'Detener prueba'**
  String get onboardingAdhanStopPreview;

  /// No description provided for @onboardingAdhanListenPreview.
  ///
  /// In es, this message translates to:
  /// **'Escuchar prueba'**
  String get onboardingAdhanListenPreview;

  /// No description provided for @onboardingDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo listo'**
  String get onboardingDoneTitle;

  /// No description provided for @onboardingDoneSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ya puedes empezar con tus horarios, tu Qibla y tu seguimiento diario. Todo esto se puede ajustar después.'**
  String get onboardingDoneSubtitle;

  /// No description provided for @onboardingSummaryLocationBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueada por ahora'**
  String get onboardingSummaryLocationBlocked;

  /// No description provided for @onboardingSummaryNotificationsPrepared.
  ///
  /// In es, this message translates to:
  /// **'Preparadas'**
  String get onboardingSummaryNotificationsPrepared;

  /// No description provided for @methodMuslimWorldLeague.
  ///
  /// In es, this message translates to:
  /// **'Muslim World League'**
  String get methodMuslimWorldLeague;

  /// No description provided for @methodNorthAmerica.
  ///
  /// In es, this message translates to:
  /// **'ISNA / Norteamérica'**
  String get methodNorthAmerica;

  /// No description provided for @methodUmmAlQura.
  ///
  /// In es, this message translates to:
  /// **'Umm al-Qura'**
  String get methodUmmAlQura;

  /// No description provided for @methodEgyptian.
  ///
  /// In es, this message translates to:
  /// **'Egyptian Authority'**
  String get methodEgyptian;

  /// No description provided for @homeHeaderOnline.
  ///
  /// In es, this message translates to:
  /// **'En línea'**
  String get homeHeaderOnline;

  /// No description provided for @homeHeaderOffline.
  ///
  /// In es, this message translates to:
  /// **'Sin red'**
  String get homeHeaderOffline;

  /// No description provided for @homeHeaderLocationUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Ubicación no disponible'**
  String get homeHeaderLocationUnavailable;

  /// No description provided for @homeHeaderStatusLine.
  ///
  /// In es, this message translates to:
  /// **'{networkStatus} · {location}'**
  String homeHeaderStatusLine(Object networkStatus, Object location);

  /// No description provided for @homeHeroNextPrayer.
  ///
  /// In es, this message translates to:
  /// **'PRÓXIMA ORACIÓN'**
  String get homeHeroNextPrayer;

  /// No description provided for @homeHeroTodayOverview.
  ///
  /// In es, this message translates to:
  /// **'Consulta central de hoy'**
  String get homeHeroTodayOverview;

  /// No description provided for @homeHeroUsingSavedLocation.
  ///
  /// In es, this message translates to:
  /// **'Usando tu última ubicación guardada'**
  String get homeHeroUsingSavedLocation;

  /// No description provided for @homeSelectedDateToday.
  ///
  /// In es, this message translates to:
  /// **'HOY'**
  String get homeSelectedDateToday;

  /// No description provided for @homeSelectedDateCustom.
  ///
  /// In es, this message translates to:
  /// **'FECHA SELECCIONADA'**
  String get homeSelectedDateCustom;

  /// No description provided for @homeCountdownUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Cuenta atrás no disponible'**
  String get homeCountdownUnavailable;

  /// No description provided for @homeCountdownActive.
  ///
  /// In es, this message translates to:
  /// **'Cuenta atrás activa'**
  String get homeCountdownActive;

  /// No description provided for @homeCountdownUntil.
  ///
  /// In es, this message translates to:
  /// **'hasta {prayer}'**
  String homeCountdownUntil(Object prayer);

  /// No description provided for @homeCountdownLabelUppercase.
  ///
  /// In es, this message translates to:
  /// **'CUENTA ATRÁS'**
  String get homeCountdownLabelUppercase;

  /// No description provided for @homeDurationUntil.
  ///
  /// In es, this message translates to:
  /// **'en {hours}h {minutes}min'**
  String homeDurationUntil(int hours, int minutes);

  /// No description provided for @homeDurationHoursMinutes.
  ///
  /// In es, this message translates to:
  /// **'{hours} h {minutes} min'**
  String homeDurationHoursMinutes(int hours, String minutes);

  /// No description provided for @homeDurationMinutes.
  ///
  /// In es, this message translates to:
  /// **'{minutes} min'**
  String homeDurationMinutes(int minutes);

  /// No description provided for @homeDurationSeconds.
  ///
  /// In es, this message translates to:
  /// **'{seconds} s'**
  String homeDurationSeconds(String seconds);

  /// No description provided for @homePrayerSectionToday.
  ///
  /// In es, this message translates to:
  /// **'Oraciones de hoy'**
  String get homePrayerSectionToday;

  /// No description provided for @homePrayerSectionForDate.
  ///
  /// In es, this message translates to:
  /// **'Horarios de {date}'**
  String homePrayerSectionForDate(Object date);

  /// No description provided for @homePrayerSectionWorshipDay.
  ///
  /// In es, this message translates to:
  /// **'{weekday}, día de adoración'**
  String homePrayerSectionWorshipDay(Object weekday);

  /// No description provided for @homePrayerSectionMarkedCount.
  ///
  /// In es, this message translates to:
  /// **'{count}/5 marcadas'**
  String homePrayerSectionMarkedCount(int count);

  /// No description provided for @settingsTitle.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get settingsTitle;

  /// No description provided for @settingsTitleArabic.
  ///
  /// In es, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitleArabic;

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In es, this message translates to:
  /// **'Apariencia'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionAccessibility.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get settingsSectionAccessibility;

  /// No description provided for @settingsSectionAdhanNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones de adhan'**
  String get settingsSectionAdhanNotifications;

  /// No description provided for @settingsSectionScheduleCalculation.
  ///
  /// In es, this message translates to:
  /// **'Cálculo de horarios'**
  String get settingsSectionScheduleCalculation;

  /// No description provided for @settingsSectionRamadanMode.
  ///
  /// In es, this message translates to:
  /// **'Modo Ramadán'**
  String get settingsSectionRamadanMode;

  /// No description provided for @settingsSectionHadith.
  ///
  /// In es, this message translates to:
  /// **'Hadices'**
  String get settingsSectionHadith;

  /// No description provided for @settingsSectionTravelerMode.
  ///
  /// In es, this message translates to:
  /// **'Modo viajero'**
  String get settingsSectionTravelerMode;

  /// No description provided for @settingsSectionRecentPlaces.
  ///
  /// In es, this message translates to:
  /// **'LUGARES RECIENTES'**
  String get settingsSectionRecentPlaces;

  /// No description provided for @settingsSectionSmartCache.
  ///
  /// In es, this message translates to:
  /// **'Caché inteligente'**
  String get settingsSectionSmartCache;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In es, this message translates to:
  /// **'Sadaqah · Apoyo'**
  String get settingsSectionSupport;

  /// No description provided for @settingsSectionCloudBackup.
  ///
  /// In es, this message translates to:
  /// **'Copia de seguridad en la nube (beta)'**
  String get settingsSectionCloudBackup;

  /// No description provided for @settingsTextSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño de texto'**
  String get settingsTextSize;

  /// No description provided for @settingsCurrentScale.
  ///
  /// In es, this message translates to:
  /// **'Escala actual: {scale}x'**
  String settingsCurrentScale(Object scale);

  /// No description provided for @settingsHighContrast.
  ///
  /// In es, this message translates to:
  /// **'Alto contraste'**
  String get settingsHighContrast;

  /// No description provided for @settingsHighContrastSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mejora la legibilidad en toda la app'**
  String get settingsHighContrastSubtitle;

  /// No description provided for @settingsUseSystemBold.
  ///
  /// In es, this message translates to:
  /// **'Usar negrita del sistema'**
  String get settingsUseSystemBold;

  /// No description provided for @settingsUseSystemBoldSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Respeta la preferencia de VoiceOver/TalkBack'**
  String get settingsUseSystemBoldSubtitle;

  /// No description provided for @settingsResetAccessibility.
  ///
  /// In es, this message translates to:
  /// **'Restablecer accesibilidad'**
  String get settingsResetAccessibility;

  /// No description provided for @settingsReset.
  ///
  /// In es, this message translates to:
  /// **'Restablecer'**
  String get settingsReset;

  /// No description provided for @settingsThemeDarkTitle.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get settingsThemeDarkTitle;

  /// No description provided for @settingsThemeDarkSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cielo antes del Fajr'**
  String get settingsThemeDarkSubtitle;

  /// No description provided for @settingsThemeLightTitle.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get settingsThemeLightTitle;

  /// No description provided for @settingsThemeLightSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Para uso en exteriores'**
  String get settingsThemeLightSubtitle;

  /// No description provided for @settingsThemeAmoledTitle.
  ///
  /// In es, this message translates to:
  /// **'AMOLED'**
  String get settingsThemeAmoledTitle;

  /// No description provided for @settingsThemeAmoledSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Negro puro, ahorra batería'**
  String get settingsThemeAmoledSubtitle;

  /// No description provided for @settingsThemeDeuteranopiaTitle.
  ///
  /// In es, this message translates to:
  /// **'Deuteranopia'**
  String get settingsThemeDeuteranopiaTitle;

  /// No description provided for @settingsThemeDeuteranopiaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Sin rojo/verde'**
  String get settingsThemeDeuteranopiaSubtitle;

  /// No description provided for @settingsThemeMonochromeTitle.
  ///
  /// In es, this message translates to:
  /// **'Monocromía'**
  String get settingsThemeMonochromeTitle;

  /// No description provided for @settingsThemeMonochromeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Acromatopsia y baja visión'**
  String get settingsThemeMonochromeSubtitle;

  /// No description provided for @settingsLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige si quieres seguir el idioma del dispositivo o usar uno fijo en toda la app.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la app'**
  String get settingsLanguageDialogTitle;

  /// No description provided for @settingsLanguageOptionSystem.
  ///
  /// In es, this message translates to:
  /// **'Seguir el idioma del dispositivo'**
  String get settingsLanguageOptionSystem;

  /// No description provided for @settingsLanguageSystemValue.
  ///
  /// In es, this message translates to:
  /// **'Automático ({language})'**
  String settingsLanguageSystemValue(Object language);

  /// No description provided for @settingsLanguageOptionSpanish.
  ///
  /// In es, this message translates to:
  /// **'Español'**
  String get settingsLanguageOptionSpanish;

  /// No description provided for @settingsLanguageOptionEnglish.
  ///
  /// In es, this message translates to:
  /// **'English'**
  String get settingsLanguageOptionEnglish;

  /// No description provided for @settingsLanguageOptionArabic.
  ///
  /// In es, this message translates to:
  /// **'العربية'**
  String get settingsLanguageOptionArabic;

  /// No description provided for @settingsAdhanSound.
  ///
  /// In es, this message translates to:
  /// **'Sonido del adhan'**
  String get settingsAdhanSound;

  /// No description provided for @settingsAdhanSoundAction.
  ///
  /// In es, this message translates to:
  /// **'Elegir y previsualizar'**
  String get settingsAdhanSoundAction;

  /// No description provided for @settingsGeneralNotifications.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones generales'**
  String get settingsGeneralNotifications;

  /// No description provided for @settingsGeneralNotificationsSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activa o pausa todos los avisos de oración'**
  String get settingsGeneralNotificationsSubtitle;

  /// No description provided for @settingsSystemPermissionPendingBody.
  ///
  /// In es, this message translates to:
  /// **'Los avisos de adhan están configurados, pero el permiso del sistema sigue pendiente.'**
  String get settingsSystemPermissionPendingBody;

  /// No description provided for @settingsHapticFeedback.
  ///
  /// In es, this message translates to:
  /// **'Vibración háptica'**
  String get settingsHapticFeedback;

  /// No description provided for @settingsRamadanAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Modo Ramadán automático'**
  String get settingsRamadanAutomatic;

  /// No description provided for @settingsRamadanAutomaticSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Se activa solo cuando el calendario islámico entra en Ramadán'**
  String get settingsRamadanAutomaticSubtitle;

  /// No description provided for @settingsRamadanForced.
  ///
  /// In es, this message translates to:
  /// **'Forzar modo Ramadán'**
  String get settingsRamadanForced;

  /// No description provided for @settingsRamadanForcedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Activar vista de Ramadán manualmente'**
  String get settingsRamadanForcedSubtitle;

  /// No description provided for @settingsDailyNotification.
  ///
  /// In es, this message translates to:
  /// **'Notificación diaria'**
  String get settingsDailyNotification;

  /// No description provided for @settingsDailyNotificationSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recibe un hadiz o versículo cada día'**
  String get settingsDailyNotificationSubtitle;

  /// No description provided for @settingsNotificationHour.
  ///
  /// In es, this message translates to:
  /// **'Hora de notificación'**
  String get settingsNotificationHour;

  /// No description provided for @settingsTravelerMode.
  ///
  /// In es, this message translates to:
  /// **'Modo viajero'**
  String get settingsTravelerMode;

  /// No description provided for @settingsTravelerModeSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Detecta automáticamente cambios de ciudad (>50 km)'**
  String get settingsTravelerModeSubtitle;

  /// No description provided for @settingsTravelerModeLoadError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar el modo viajero'**
  String get settingsTravelerModeLoadError;

  /// No description provided for @settingsRecentPlaces.
  ///
  /// In es, this message translates to:
  /// **'Lugares recientes'**
  String get settingsRecentPlaces;

  /// No description provided for @settingsNoRecentTrips.
  ///
  /// In es, this message translates to:
  /// **'Sin viajes recientes'**
  String get settingsNoRecentTrips;

  /// No description provided for @settingsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargarlo'**
  String get settingsLoadError;

  /// No description provided for @settingsCacheValidUntil.
  ///
  /// In es, this message translates to:
  /// **'Caché válida hasta'**
  String get settingsCacheValidUntil;

  /// No description provided for @settingsCacheEntries.
  ///
  /// In es, this message translates to:
  /// **'Entradas en caché'**
  String get settingsCacheEntries;

  /// No description provided for @settingsClearCache.
  ///
  /// In es, this message translates to:
  /// **'Limpiar caché'**
  String get settingsClearCache;

  /// No description provided for @settingsSupportInfo.
  ///
  /// In es, this message translates to:
  /// **'Información de apoyo'**
  String get settingsSupportInfo;

  /// No description provided for @settingsSupportCardTitle.
  ///
  /// In es, this message translates to:
  /// **'Apoya el desarrollo'**
  String get settingsSupportCardTitle;

  /// No description provided for @settingsSupportCardSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Cada donación puede ser una sadaqah jariyah'**
  String get settingsSupportCardSubtitle;

  /// No description provided for @settingsBackupMode.
  ///
  /// In es, this message translates to:
  /// **'Modo de copia'**
  String get settingsBackupMode;

  /// No description provided for @settingsAnonymousId.
  ///
  /// In es, this message translates to:
  /// **'ID anónimo'**
  String get settingsAnonymousId;

  /// No description provided for @settingsLastBackup.
  ///
  /// In es, this message translates to:
  /// **'Última copia'**
  String get settingsLastBackup;

  /// No description provided for @settingsExportBackup.
  ///
  /// In es, this message translates to:
  /// **'Exportar copia'**
  String get settingsExportBackup;

  /// No description provided for @settingsRestoreBackup.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia'**
  String get settingsRestoreBackup;

  /// No description provided for @settingsBackupInfoBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes guardar y compartir una copia manual en formato JSON. La automatización y la sincronización entre dispositivos aún no están disponibles.'**
  String get settingsBackupInfoBody;

  /// No description provided for @settingsRestoreBackupDialogTitle.
  ///
  /// In es, this message translates to:
  /// **'Restaurar copia'**
  String get settingsRestoreBackupDialogTitle;

  /// No description provided for @settingsRestoreBackupSuccess.
  ///
  /// In es, this message translates to:
  /// **'Copia restaurada'**
  String get settingsRestoreBackupSuccess;

  /// No description provided for @settingsRestoreBackupError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido restaurar la copia.'**
  String get settingsRestoreBackupError;

  /// No description provided for @settingsDailyNotificationEnabled.
  ///
  /// In es, this message translates to:
  /// **'Notificación diaria activada'**
  String get settingsDailyNotificationEnabled;

  /// No description provided for @settingsDailyNotificationDisabled.
  ///
  /// In es, this message translates to:
  /// **'Notificación diaria desactivada'**
  String get settingsDailyNotificationDisabled;

  /// No description provided for @settingsSelectHourTitle.
  ///
  /// In es, this message translates to:
  /// **'Seleccionar hora'**
  String get settingsSelectHourTitle;

  /// No description provided for @settingsToday.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get settingsToday;

  /// No description provided for @settingsYesterday.
  ///
  /// In es, this message translates to:
  /// **'Ayer'**
  String get settingsYesterday;

  /// No description provided for @settingsDaysAgo.
  ///
  /// In es, this message translates to:
  /// **'Hace {count} días'**
  String settingsDaysAgo(int count);

  /// No description provided for @settingsRamadanManualActive.
  ///
  /// In es, this message translates to:
  /// **'Activo manual'**
  String get settingsRamadanManualActive;

  /// No description provided for @settingsLocationBlocked.
  ///
  /// In es, this message translates to:
  /// **'Bloqueada'**
  String get settingsLocationBlocked;

  /// No description provided for @settingsLocationPendingPermission.
  ///
  /// In es, this message translates to:
  /// **'Permiso pendiente'**
  String get settingsLocationPendingPermission;

  /// No description provided for @settingsLocationAutomatic.
  ///
  /// In es, this message translates to:
  /// **'Automática'**
  String get settingsLocationAutomatic;

  /// No description provided for @settingsLocationSavedUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Sin ubicación guardada'**
  String get settingsLocationSavedUnavailable;

  /// No description provided for @settingsLocationStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado de la ubicación'**
  String get settingsLocationStatus;

  /// No description provided for @settingsGpsOff.
  ///
  /// In es, this message translates to:
  /// **'GPS apagado'**
  String get settingsGpsOff;

  /// No description provided for @settingsScheduleSource.
  ///
  /// In es, this message translates to:
  /// **'Fuente horarios'**
  String get settingsScheduleSource;

  /// No description provided for @settingsScheduleSourceReady.
  ///
  /// In es, this message translates to:
  /// **'Caché preparada'**
  String get settingsScheduleSourceReady;

  /// No description provided for @settingsNotificationSystem.
  ///
  /// In es, this message translates to:
  /// **'Notif. sistema'**
  String get settingsNotificationSystem;

  /// No description provided for @settingsNotificationApp.
  ///
  /// In es, this message translates to:
  /// **'Notif. app'**
  String get settingsNotificationApp;

  /// No description provided for @settingsNotificationsGranted.
  ///
  /// In es, this message translates to:
  /// **'Concedidas'**
  String get settingsNotificationsGranted;

  /// No description provided for @commonPlay.
  ///
  /// In es, this message translates to:
  /// **'Reproducir'**
  String get commonPlay;

  /// No description provided for @commonText.
  ///
  /// In es, this message translates to:
  /// **'Texto'**
  String get commonText;

  /// No description provided for @commonVideo.
  ///
  /// In es, this message translates to:
  /// **'Video'**
  String get commonVideo;

  /// No description provided for @commonRemove.
  ///
  /// In es, this message translates to:
  /// **'Quitar'**
  String get commonRemove;

  /// No description provided for @shareBranding.
  ///
  /// In es, this message translates to:
  /// **'App: Qibla Time'**
  String get shareBranding;

  /// No description provided for @shareReferenceLabel.
  ///
  /// In es, this message translates to:
  /// **'Referencia: {reference}'**
  String shareReferenceLabel(Object reference);

  /// No description provided for @shareSubjectDua.
  ///
  /// In es, this message translates to:
  /// **'Dua'**
  String get shareSubjectDua;

  /// No description provided for @shareSubjectHadithOfDay.
  ///
  /// In es, this message translates to:
  /// **'Hadiz del día - Qibla Time'**
  String get shareSubjectHadithOfDay;

  /// No description provided for @shareSubjectHadithShared.
  ///
  /// In es, this message translates to:
  /// **'Hadiz compartido desde Qibla Time'**
  String get shareSubjectHadithShared;

  /// No description provided for @shareBadgeHadith.
  ///
  /// In es, this message translates to:
  /// **'HADIZ'**
  String get shareBadgeHadith;

  /// No description provided for @shareBadgeDua.
  ///
  /// In es, this message translates to:
  /// **'DUA'**
  String get shareBadgeDua;

  /// No description provided for @shareBadgeQuran.
  ///
  /// In es, this message translates to:
  /// **'CORÁN'**
  String get shareBadgeQuran;

  /// No description provided for @shareSectionStyle.
  ///
  /// In es, this message translates to:
  /// **'Estilo / fondo'**
  String get shareSectionStyle;

  /// No description provided for @shareSectionContent.
  ///
  /// In es, this message translates to:
  /// **'Contenido'**
  String get shareSectionContent;

  /// No description provided for @shareLayoutCard.
  ///
  /// In es, this message translates to:
  /// **'Tarjeta'**
  String get shareLayoutCard;

  /// No description provided for @shareLayoutStory.
  ///
  /// In es, this message translates to:
  /// **'Historia'**
  String get shareLayoutStory;

  /// No description provided for @shareContentBilingual.
  ///
  /// In es, this message translates to:
  /// **'Árabe + traducción'**
  String get shareContentBilingual;

  /// No description provided for @shareContentArabicOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo árabe'**
  String get shareContentArabicOnly;

  /// No description provided for @shareContentTranslationOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo traducción'**
  String get shareContentTranslationOnly;

  /// No description provided for @shareActionShareImage.
  ///
  /// In es, this message translates to:
  /// **'Compartir imagen'**
  String get shareActionShareImage;

  /// No description provided for @shareActionShareText.
  ///
  /// In es, this message translates to:
  /// **'Compartir texto'**
  String get shareActionShareText;

  /// No description provided for @shareHadithTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir hadiz'**
  String get shareHadithTitle;

  /// No description provided for @shareHadithSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Elige el formato y el contenido antes de compartir.'**
  String get shareHadithSubtitle;

  /// No description provided for @shareHadithTextError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido compartir el texto del hadiz.'**
  String get shareHadithTextError;

  /// No description provided for @shareHadithImageError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido generar la imagen del hadiz.'**
  String get shareHadithImageError;

  /// No description provided for @shareDuaTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir dua'**
  String get shareDuaTitle;

  /// No description provided for @shareDuaTitleNamed.
  ///
  /// In es, this message translates to:
  /// **'Compartir {title}'**
  String shareDuaTitleNamed(Object title);

  /// No description provided for @shareDuaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Usa la misma presentación visual del hadiz para la dua y los adhkar.'**
  String get shareDuaSubtitle;

  /// No description provided for @shareDuaTextError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido compartir el texto de la dua.'**
  String get shareDuaTextError;

  /// No description provided for @shareDuaImageError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido generar la imagen de la dua.'**
  String get shareDuaImageError;

  /// No description provided for @shareAyahTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir aleya {number}'**
  String shareAyahTitle(int number);

  /// No description provided for @shareAyahSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Mantén la misma presentación visual para texto, imagen y video.'**
  String get shareAyahSubtitle;

  /// No description provided for @shareAyahTextError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido compartir el texto de esta aleya.'**
  String get shareAyahTextError;

  /// No description provided for @shareAyahImageError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido generar la imagen de esta aleya.'**
  String get shareAyahImageError;

  /// No description provided for @shareAyahVideoNoAudio.
  ///
  /// In es, this message translates to:
  /// **'No hay audio disponible para generar el video de esta aleya.'**
  String get shareAyahVideoNoAudio;

  /// No description provided for @shareAyahVideoGenerating.
  ///
  /// In es, this message translates to:
  /// **'Generando video de la aleya...'**
  String get shareAyahVideoGenerating;

  /// No description provided for @shareAyahVideoError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido generar el video de esta aleya.'**
  String get shareAyahVideoError;

  /// No description provided for @notificationAdhanChannelName.
  ///
  /// In es, this message translates to:
  /// **'Adhan'**
  String get notificationAdhanChannelName;

  /// No description provided for @notificationAdhanChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Notificaciones del horario de oración'**
  String get notificationAdhanChannelDescription;

  /// No description provided for @notificationAdhanTitle.
  ///
  /// In es, this message translates to:
  /// **'Qibla Time - {prayerName}'**
  String notificationAdhanTitle(Object prayerName);

  /// No description provided for @notificationAdhanBody.
  ///
  /// In es, this message translates to:
  /// **'Es la hora de la oración'**
  String get notificationAdhanBody;

  /// No description provided for @notificationReminderChannelName.
  ///
  /// In es, this message translates to:
  /// **'Qibla Time - Recordatorios'**
  String get notificationReminderChannelName;

  /// No description provided for @notificationReminderChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios contextuales de Ramadán y Yumu\'ah'**
  String get notificationReminderChannelDescription;

  /// No description provided for @notificationDailyReflectionChannelName.
  ///
  /// In es, this message translates to:
  /// **'Reflexión diaria'**
  String get notificationDailyReflectionChannelName;

  /// No description provided for @notificationDailyReflectionChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Versículo del Corán y hadiz del día'**
  String get notificationDailyReflectionChannelDescription;

  /// No description provided for @notificationDailyReflectionTitle.
  ///
  /// In es, this message translates to:
  /// **'Reflexión del día'**
  String get notificationDailyReflectionTitle;

  /// No description provided for @notificationDailyReflectionFallbackBody.
  ///
  /// In es, this message translates to:
  /// **'Tu reflexión espiritual diaria en Qibla Time.'**
  String get notificationDailyReflectionFallbackBody;

  /// No description provided for @notificationDailyReflectionErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'Qibla Time · Reflexión diaria'**
  String get notificationDailyReflectionErrorTitle;

  /// No description provided for @notificationDailyReflectionErrorBody.
  ///
  /// In es, this message translates to:
  /// **'Tu recordatorio espiritual de hoy'**
  String get notificationDailyReflectionErrorBody;

  /// No description provided for @notificationHadithReminderChannelName.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios de hadices'**
  String get notificationHadithReminderChannelName;

  /// No description provided for @notificationHadithReminderChannelDescription.
  ///
  /// In es, this message translates to:
  /// **'Recordatorios horarios de hadices'**
  String get notificationHadithReminderChannelDescription;

  /// No description provided for @notificationHadithReminderFallbackBody.
  ///
  /// In es, this message translates to:
  /// **'Recordatorio: lee un hadiz del Profeta ﷺ'**
  String get notificationHadithReminderFallbackBody;

  /// No description provided for @notificationHadithReminderTitle.
  ///
  /// In es, this message translates to:
  /// **'📖 Hadiz del momento'**
  String get notificationHadithReminderTitle;

  /// No description provided for @notificationHadithReminderTestBody.
  ///
  /// In es, this message translates to:
  /// **'Prueba de recordatorio de hadiz'**
  String get notificationHadithReminderTestBody;

  /// No description provided for @notificationHadithReminderTestTitle.
  ///
  /// In es, this message translates to:
  /// **'📖 Recordatorio de hadiz'**
  String get notificationHadithReminderTestTitle;

  /// No description provided for @notificationWeeklySummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu resumen semanal ya está listo'**
  String get notificationWeeklySummaryTitle;

  /// No description provided for @notificationWeeklySummaryBody.
  ///
  /// In es, this message translates to:
  /// **'Esta semana completaste {prayersCompleted}/{maxPossible} oraciones. Tu mejor día fue {strongestDay}.'**
  String notificationWeeklySummaryBody(int prayersCompleted, int maxPossible, Object strongestDay);

  /// No description provided for @quranDailyVerseFallbackTranslation.
  ///
  /// In es, this message translates to:
  /// **'Allah: no hay divinidad salvo Él, el Viviente, el Sustentador. Ni la somnolencia ni el sueño Lo alcanzan.'**
  String get quranDailyVerseFallbackTranslation;

  /// No description provided for @quranDailyVerseFallbackTransliteration.
  ///
  /// In es, this message translates to:
  /// **'Allahu la ilaha illa huwal hayyul qayyum...'**
  String get quranDailyVerseFallbackTransliteration;

  /// No description provided for @quranDailyVerseFallbackReference.
  ///
  /// In es, this message translates to:
  /// **'Al-Baqara [2:255]'**
  String get quranDailyVerseFallbackReference;

  /// No description provided for @quranTitle.
  ///
  /// In es, this message translates to:
  /// **'Corán'**
  String get quranTitle;

  /// No description provided for @quranSubtitle.
  ///
  /// In es, this message translates to:
  /// **'114 suras · lectura continua'**
  String get quranSubtitle;

  /// No description provided for @quranHafizLabel.
  ///
  /// In es, this message translates to:
  /// **'Hafiz'**
  String get quranHafizLabel;

  /// No description provided for @quranUtilityAyatAlKursi.
  ///
  /// In es, this message translates to:
  /// **'Ayat al-Kursi'**
  String get quranUtilityAyatAlKursi;

  /// No description provided for @quranUtilityAllahNames.
  ///
  /// In es, this message translates to:
  /// **'99 nombres'**
  String get quranUtilityAllahNames;

  /// No description provided for @quranUtilityDownloaded.
  ///
  /// In es, this message translates to:
  /// **'Descargadas'**
  String get quranUtilityDownloaded;

  /// No description provided for @quranProtectionTitle.
  ///
  /// In es, this message translates to:
  /// **'PROTECCIÓN DIARIA'**
  String get quranProtectionTitle;

  /// No description provided for @quranProtectionSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso rápido a Ayat al-Kursi y las suras de protección. Puedes abrirlas para leer o escuchar y marcar tu repetición tres veces.'**
  String get quranProtectionSubtitle;

  /// No description provided for @quranProtectionAyatAlKursiHelper.
  ///
  /// In es, this message translates to:
  /// **'Al-Baqara 2:255'**
  String get quranProtectionAyatAlKursiHelper;

  /// No description provided for @quranProtectionSurahHelper.
  ///
  /// In es, this message translates to:
  /// **'Sura {number}'**
  String quranProtectionSurahHelper(int number);

  /// No description provided for @quranProtectionIkhlasTitle.
  ///
  /// In es, this message translates to:
  /// **'Al-Ikhlas'**
  String get quranProtectionIkhlasTitle;

  /// No description provided for @quranProtectionFalaqTitle.
  ///
  /// In es, this message translates to:
  /// **'Al-Falaq'**
  String get quranProtectionFalaqTitle;

  /// No description provided for @quranProtectionNasTitle.
  ///
  /// In es, this message translates to:
  /// **'An-Nas'**
  String get quranProtectionNasTitle;

  /// No description provided for @quranProtectionRepeatCount.
  ///
  /// In es, this message translates to:
  /// **'{helper} · {count}/3 repeticiones'**
  String quranProtectionRepeatCount(Object helper, int count);

  /// No description provided for @quranProtectionCompleteTooltip.
  ///
  /// In es, this message translates to:
  /// **'Completo'**
  String get quranProtectionCompleteTooltip;

  /// No description provided for @quranProtectionIncrementTooltip.
  ///
  /// In es, this message translates to:
  /// **'+1 repetición'**
  String get quranProtectionIncrementTooltip;

  /// No description provided for @quranReadingHintTitle.
  ///
  /// In es, this message translates to:
  /// **'LECTURA CONTINUA'**
  String get quranReadingHintTitle;

  /// No description provided for @quranReadingHintBody.
  ///
  /// In es, this message translates to:
  /// **'Abre cualquier sura y guardaremos tu última aleya para que puedas retomar más tarde.'**
  String get quranReadingHintBody;

  /// No description provided for @quranReadingHintSecondary.
  ///
  /// In es, this message translates to:
  /// **'También podrás guardar marcadores tocando el icono de marcador dentro de la lectura.'**
  String get quranReadingHintSecondary;

  /// No description provided for @quranContinueReadingTitle.
  ///
  /// In es, this message translates to:
  /// **'CONTINUAR LECTURA'**
  String get quranContinueReadingTitle;

  /// No description provided for @quranBookmarksTitle.
  ///
  /// In es, this message translates to:
  /// **'MARCADORES'**
  String get quranBookmarksTitle;

  /// No description provided for @quranRevelationMecca.
  ///
  /// In es, this message translates to:
  /// **'La Meca'**
  String get quranRevelationMecca;

  /// No description provided for @quranRevelationMedina.
  ///
  /// In es, this message translates to:
  /// **'Medina'**
  String get quranRevelationMedina;

  /// No description provided for @quranAyahCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 aleya} other{{count} aleyas}}'**
  String quranAyahCount(int count);

  /// No description provided for @quranLastReadingAyah.
  ///
  /// In es, this message translates to:
  /// **'Última lectura: aleya {ayah}'**
  String quranLastReadingAyah(int ayah);

  /// No description provided for @quranBookmarkCount.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{1 marcador guardado} other{{count} marcadores guardados}}'**
  String quranBookmarkCount(int count);

  /// No description provided for @quranDownloadedFavoriteOffline.
  ///
  /// In es, this message translates to:
  /// **'Audio descargado · favorita sin conexión'**
  String get quranDownloadedFavoriteOffline;

  /// No description provided for @quranDownloadedAudio.
  ///
  /// In es, this message translates to:
  /// **'Audio descargado'**
  String get quranDownloadedAudio;

  /// No description provided for @quranReadingPointSaved.
  ///
  /// In es, this message translates to:
  /// **'Punto de lectura guardado en la aleya {ayah}'**
  String quranReadingPointSaved(int ayah);

  /// No description provided for @quranBookmarkSaved.
  ///
  /// In es, this message translates to:
  /// **'Marcador guardado en la aleya {ayah}'**
  String quranBookmarkSaved(int ayah);

  /// No description provided for @quranBookmarkRemoved.
  ///
  /// In es, this message translates to:
  /// **'Marcador eliminado de la aleya {ayah}'**
  String quranBookmarkRemoved(int ayah);

  /// No description provided for @quranShareAyahTitle.
  ///
  /// In es, this message translates to:
  /// **'Compartir aleya {ayah}'**
  String quranShareAyahTitle(int ayah);

  /// No description provided for @quranShareTextSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Incluye el árabe, la traducción y la referencia.'**
  String get quranShareTextSubtitle;

  /// No description provided for @quranShareImageSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea una imagen con la aleya.'**
  String get quranShareImageSubtitle;

  /// No description provided for @quranShareVideoSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Crea un video con la tarjeta y la recitación.'**
  String get quranShareVideoSubtitle;

  /// No description provided for @quranAyahImageError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido generar la imagen de esta aleya.'**
  String get quranAyahImageError;

  /// No description provided for @quranAyahVideoNoAudio.
  ///
  /// In es, this message translates to:
  /// **'Esta aleya no tiene audio disponible para generar el video.'**
  String get quranAyahVideoNoAudio;

  /// No description provided for @quranAyahVideoGenerating.
  ///
  /// In es, this message translates to:
  /// **'Estamos generando el video de la aleya...'**
  String get quranAyahVideoGenerating;

  /// No description provided for @quranAyahVideoShareText.
  ///
  /// In es, this message translates to:
  /// **'Aleya {ayah} de {surah}'**
  String quranAyahVideoShareText(int ayah, Object surah);

  /// No description provided for @quranAyahVideoError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido generar el video de esta aleya.'**
  String get quranAyahVideoError;

  /// No description provided for @quranDownloadCheckError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido comprobar la descarga en este dispositivo.'**
  String get quranDownloadCheckError;

  /// No description provided for @quranDownloadSuccess.
  ///
  /// In es, this message translates to:
  /// **'Audio descargado. Ya puedes escuchar esta sura sin conexión.'**
  String get quranDownloadSuccess;

  /// No description provided for @quranDownloadDetailedError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido completar la descarga. Revisa tu conexión y vuelve a intentarlo.'**
  String get quranDownloadDetailedError;

  /// No description provided for @quranDownloadShortError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido completar la descarga del audio.'**
  String get quranDownloadShortError;

  /// No description provided for @quranDownloadedAudioPlaySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Escucha la sura con el audio ya guardado.'**
  String get quranDownloadedAudioPlaySubtitle;

  /// No description provided for @quranDownloadedAudioRemoveSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Libera espacio y vuelve a escucharla en línea.'**
  String get quranDownloadedAudioRemoveSubtitle;

  /// No description provided for @quranDownloadedAudioRemoved.
  ///
  /// In es, this message translates to:
  /// **'La descarga de esta sura se ha eliminado.'**
  String get quranDownloadedAudioRemoved;

  /// No description provided for @quranDownloadedFavoriteAdded.
  ///
  /// In es, this message translates to:
  /// **'Sura guardada entre tus descargas favoritas.'**
  String get quranDownloadedFavoriteAdded;

  /// No description provided for @quranDownloadedFavoriteRemoved.
  ///
  /// In es, this message translates to:
  /// **'Sura retirada de tus descargas favoritas.'**
  String get quranDownloadedFavoriteRemoved;

  /// No description provided for @quranAyahAudioUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Audio no disponible para esta aleya.'**
  String get quranAyahAudioUnavailable;

  /// No description provided for @quranAyahAudioDownloaded.
  ///
  /// In es, this message translates to:
  /// **'El audio ya está descargado en este dispositivo.'**
  String get quranAyahAudioDownloaded;

  /// No description provided for @quranAyahAudioAvailable.
  ///
  /// In es, this message translates to:
  /// **'Puedes escuchar esta aleya.'**
  String get quranAyahAudioAvailable;

  /// No description provided for @quranAyahAudioRequiresConnection.
  ///
  /// In es, this message translates to:
  /// **'Puedes escuchar esta aleya si tienes conexión.'**
  String get quranAyahAudioRequiresConnection;

  /// No description provided for @quranSurahRecitationUnavailable.
  ///
  /// In es, this message translates to:
  /// **'La recitación completa no está disponible para esta sura.'**
  String get quranSurahRecitationUnavailable;

  /// No description provided for @quranSurahAudioDownloading.
  ///
  /// In es, this message translates to:
  /// **'Estamos descargando el audio para escuchar esta sura sin conexión. {downloaded}/{total} aleyas listas.'**
  String quranSurahAudioDownloading(int downloaded, int total);

  /// No description provided for @quranSurahAudioDownloaded.
  ///
  /// In es, this message translates to:
  /// **'El audio ya está descargado en este dispositivo. Puedes escuchar esta sura sin conexión.'**
  String get quranSurahAudioDownloaded;

  /// No description provided for @quranSurahAudioMissingAyahs.
  ///
  /// In es, this message translates to:
  /// **'{count, plural, =1{Se omitirá 1 aleya sin audio.} other{Se omitirán {count} aleyas sin audio.}}'**
  String quranSurahAudioMissingAyahs(int count);

  /// No description provided for @quranSurahAudioPartialDownload.
  ///
  /// In es, this message translates to:
  /// **'Ya tienes {downloaded}/{total} aleyas guardadas en el dispositivo.'**
  String quranSurahAudioPartialDownload(int downloaded, int total);

  /// No description provided for @quranSurahAudioDownloadAvailable.
  ///
  /// In es, this message translates to:
  /// **'También puedes descargarla para escucharla sin conexión.'**
  String get quranSurahAudioDownloadAvailable;

  /// No description provided for @quranSurahAudioPlayOnline.
  ///
  /// In es, this message translates to:
  /// **'Puedes escuchar esta sura seguida, en reproducción continua.'**
  String get quranSurahAudioPlayOnline;

  /// No description provided for @quranSurahAudioPlayWithConnection.
  ///
  /// In es, this message translates to:
  /// **'Puedes escuchar esta sura completa si tienes conexión.'**
  String get quranSurahAudioPlayWithConnection;

  /// No description provided for @quranAyahPlaybackError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido reproducir el audio. Revisa tu conexión y vuelve a intentarlo.'**
  String get quranAyahPlaybackError;

  /// No description provided for @quranSurahPlaybackError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido iniciar la recitación completa.'**
  String get quranSurahPlaybackError;

  /// No description provided for @quranLastReadingBadge.
  ///
  /// In es, this message translates to:
  /// **'Última lectura'**
  String get quranLastReadingBadge;

  /// No description provided for @quranPauseAudio.
  ///
  /// In es, this message translates to:
  /// **'Pausar audio'**
  String get quranPauseAudio;

  /// No description provided for @quranResumeAudio.
  ///
  /// In es, this message translates to:
  /// **'Reanudar audio'**
  String get quranResumeAudio;

  /// No description provided for @quranPlayAudio.
  ///
  /// In es, this message translates to:
  /// **'Reproducir audio'**
  String get quranPlayAudio;

  /// No description provided for @quranAudioUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Audio no disponible'**
  String get quranAudioUnavailable;

  /// No description provided for @quranRemoveBookmark.
  ///
  /// In es, this message translates to:
  /// **'Quitar marcador'**
  String get quranRemoveBookmark;

  /// No description provided for @quranSaveBookmark.
  ///
  /// In es, this message translates to:
  /// **'Guardar marcador'**
  String get quranSaveBookmark;

  /// No description provided for @quranAyahFooterHint.
  ///
  /// In es, this message translates to:
  /// **'{status} Toca esta aleya para guardar tu punto de lectura aquí. Mantén pulsado para compartirla.'**
  String quranAyahFooterHint(Object status);

  /// No description provided for @quranDetailLoadError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar esta sura. Revisa la conexión y vuelve a intentarlo.'**
  String get quranDetailLoadError;

  /// No description provided for @quranTopBannerResume.
  ///
  /// In es, this message translates to:
  /// **'Retomando desde la aleya {ayah}.'**
  String quranTopBannerResume(int ayah);

  /// No description provided for @quranTopBannerOnline.
  ///
  /// In es, this message translates to:
  /// **'Contenido cargado en línea. Puedes escuchar el audio de cada aleya mientras tengas conexión.'**
  String get quranTopBannerOnline;

  /// No description provided for @quranTopBannerOffline.
  ///
  /// In es, this message translates to:
  /// **'Texto cargado sin conexión. El audio de algunas aleyas puede requerir conexión.'**
  String get quranTopBannerOffline;

  /// No description provided for @quranTopBannerPlaceholder.
  ///
  /// In es, this message translates to:
  /// **'Contenido parcial sin conexión. El audio no está disponible por ahora.'**
  String get quranTopBannerPlaceholder;

  /// No description provided for @quranSurahAudioCardTitle.
  ///
  /// In es, this message translates to:
  /// **'ESCUCHAR SURA'**
  String get quranSurahAudioCardTitle;

  /// No description provided for @quranAvailableAyahs.
  ///
  /// In es, this message translates to:
  /// **'{available}/{total} aleyas'**
  String quranAvailableAyahs(int available, int total);

  /// No description provided for @quranPauseSurah.
  ///
  /// In es, this message translates to:
  /// **'Pausar sura'**
  String get quranPauseSurah;

  /// No description provided for @quranResumeSurah.
  ///
  /// In es, this message translates to:
  /// **'Reanudar sura'**
  String get quranResumeSurah;

  /// No description provided for @quranListenSurah.
  ///
  /// In es, this message translates to:
  /// **'Escuchar sura'**
  String get quranListenSurah;

  /// No description provided for @quranStop.
  ///
  /// In es, this message translates to:
  /// **'Detener'**
  String get quranStop;

  /// No description provided for @quranCheckingAudio.
  ///
  /// In es, this message translates to:
  /// **'Comprobando audio'**
  String get quranCheckingAudio;

  /// No description provided for @quranDownloadingProgress.
  ///
  /// In es, this message translates to:
  /// **'Descargando {downloaded}/{total}'**
  String quranDownloadingProgress(int downloaded, int total);

  /// No description provided for @quranDownloaded.
  ///
  /// In es, this message translates to:
  /// **'Descargado'**
  String get quranDownloaded;

  /// No description provided for @quranDownloadAudio.
  ///
  /// In es, this message translates to:
  /// **'Descargar audio'**
  String get quranDownloadAudio;

  /// No description provided for @quranDownloadedFavoriteLabel.
  ///
  /// In es, this message translates to:
  /// **'Favorita descargada'**
  String get quranDownloadedFavoriteLabel;

  /// No description provided for @quranMarkFavorite.
  ///
  /// In es, this message translates to:
  /// **'Marcar favorita'**
  String get quranMarkFavorite;

  /// No description provided for @quranPlayingSurahAyah.
  ///
  /// In es, this message translates to:
  /// **'Reproduciendo la sura · aleya {ayah}'**
  String quranPlayingSurahAyah(int ayah);

  /// No description provided for @quranPausedSurahAyah.
  ///
  /// In es, this message translates to:
  /// **'Sura en pausa · aleya {ayah}'**
  String quranPausedSurahAyah(int ayah);

  /// No description provided for @quranPlayingAyah.
  ///
  /// In es, this message translates to:
  /// **'Reproduciendo aleya {ayah}'**
  String quranPlayingAyah(int ayah);

  /// No description provided for @quranPausedAyah.
  ///
  /// In es, this message translates to:
  /// **'Aleya {ayah} en pausa'**
  String quranPausedAyah(int ayah);

  /// No description provided for @quranActiveAudioSurahHint.
  ///
  /// In es, this message translates to:
  /// **'La sura seguirá automáticamente con la siguiente aleya.'**
  String get quranActiveAudioSurahHint;

  /// No description provided for @quranActiveAudioAyahHint.
  ///
  /// In es, this message translates to:
  /// **'Puedes pausar, reanudar o detener esta recitación.'**
  String get quranActiveAudioAyahHint;

  /// No description provided for @quranStopAudio.
  ///
  /// In es, this message translates to:
  /// **'Detener audio'**
  String get quranStopAudio;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar': return AppLocalizationsAr();
    case 'en': return AppLocalizationsEn();
    case 'es': return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
