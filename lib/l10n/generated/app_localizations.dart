import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
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
  String notificationWeeklySummaryBody(
      int prayersCompleted, int maxPossible, Object strongestDay);

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

  /// No description provided for @commonAuthenticity.
  ///
  /// In es, this message translates to:
  /// **'Autenticidad'**
  String get commonAuthenticity;

  /// No description provided for @commonBooks.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get commonBooks;

  /// No description provided for @commonCancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get commonCancel;

  /// No description provided for @commonCategory.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get commonCategory;

  /// No description provided for @commonClose.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get commonClose;

  /// No description provided for @commonCollection.
  ///
  /// In es, this message translates to:
  /// **'Colección'**
  String get commonCollection;

  /// No description provided for @commonCopy.
  ///
  /// In es, this message translates to:
  /// **'Copiar'**
  String get commonCopy;

  /// No description provided for @commonDone.
  ///
  /// In es, this message translates to:
  /// **'Hecho'**
  String get commonDone;

  /// No description provided for @commonDownload.
  ///
  /// In es, this message translates to:
  /// **'Descargar'**
  String get commonDownload;

  /// No description provided for @commonFeatured.
  ///
  /// In es, this message translates to:
  /// **'Destacados'**
  String get commonFeatured;

  /// No description provided for @commonFilter.
  ///
  /// In es, this message translates to:
  /// **'Filtrar'**
  String get commonFilter;

  /// No description provided for @commonGeneral.
  ///
  /// In es, this message translates to:
  /// **'General'**
  String get commonGeneral;

  /// No description provided for @commonHadiths.
  ///
  /// In es, this message translates to:
  /// **'Hadices'**
  String get commonHadiths;

  /// No description provided for @commonInformation.
  ///
  /// In es, this message translates to:
  /// **'Información'**
  String get commonInformation;

  /// No description provided for @commonNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get commonNext;

  /// No description provided for @commonOther.
  ///
  /// In es, this message translates to:
  /// **'Otros'**
  String get commonOther;

  /// No description provided for @commonPause.
  ///
  /// In es, this message translates to:
  /// **'Pausar'**
  String get commonPause;

  /// No description provided for @commonPrayers.
  ///
  /// In es, this message translates to:
  /// **'oraciones'**
  String get commonPrayers;

  /// No description provided for @commonQuran.
  ///
  /// In es, this message translates to:
  /// **'Corán'**
  String get commonQuran;

  /// No description provided for @commonRead.
  ///
  /// In es, this message translates to:
  /// **'Leer'**
  String get commonRead;

  /// No description provided for @commonReference.
  ///
  /// In es, this message translates to:
  /// **'Referencia'**
  String get commonReference;

  /// No description provided for @commonResume.
  ///
  /// In es, this message translates to:
  /// **'Reanudar'**
  String get commonResume;

  /// No description provided for @commonSave.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get commonSave;

  /// No description provided for @commonSaved.
  ///
  /// In es, this message translates to:
  /// **'Guardado'**
  String get commonSaved;

  /// No description provided for @commonStatistics.
  ///
  /// In es, this message translates to:
  /// **'Estadísticas'**
  String get commonStatistics;

  /// No description provided for @commonTotal.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get commonTotal;

  /// No description provided for @achievementFirstPrayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Primera oración'**
  String get achievementFirstPrayerTitle;

  /// No description provided for @achievementFirstPrayerDescription.
  ///
  /// In es, this message translates to:
  /// **'Has marcado tu primera oración en la app.'**
  String get achievementFirstPrayerDescription;

  /// No description provided for @achievementFullDayTitle.
  ///
  /// In es, this message translates to:
  /// **'Día completo'**
  String get achievementFullDayTitle;

  /// No description provided for @achievementFullDayDescription.
  ///
  /// In es, this message translates to:
  /// **'Has completado las cinco oraciones de un mismo día.'**
  String get achievementFullDayDescription;

  /// No description provided for @achievementStreak3Title.
  ///
  /// In es, this message translates to:
  /// **'Racha de 3 días'**
  String get achievementStreak3Title;

  /// No description provided for @achievementStreak3Description.
  ///
  /// In es, this message translates to:
  /// **'Has mantenido tu constancia durante tres días seguidos.'**
  String get achievementStreak3Description;

  /// No description provided for @achievementStreak7Title.
  ///
  /// In es, this message translates to:
  /// **'Racha de 7 días'**
  String get achievementStreak7Title;

  /// No description provided for @achievementStreak7Description.
  ///
  /// In es, this message translates to:
  /// **'Siete días seguidos de seguimiento. Muy buen ritmo.'**
  String get achievementStreak7Description;

  /// No description provided for @achievementStreak30Title.
  ///
  /// In es, this message translates to:
  /// **'Racha de 30 días'**
  String get achievementStreak30Title;

  /// No description provided for @achievementStreak30Description.
  ///
  /// In es, this message translates to:
  /// **'Treinta días seguidos. Una constancia extraordinaria.'**
  String get achievementStreak30Description;

  /// No description provided for @achievementTotal100Title.
  ///
  /// In es, this message translates to:
  /// **'100 oraciones'**
  String get achievementTotal100Title;

  /// No description provided for @achievementTotal100Description.
  ///
  /// In es, this message translates to:
  /// **'Has registrado 100 oraciones completadas.'**
  String get achievementTotal100Description;

  /// No description provided for @achievementFirstRamadanTitle.
  ///
  /// In es, this message translates to:
  /// **'Primer Ramadán'**
  String get achievementFirstRamadanTitle;

  /// No description provided for @achievementFirstRamadanDescription.
  ///
  /// In es, this message translates to:
  /// **'Has completado tu primera jornada activa de Ramadán.'**
  String get achievementFirstRamadanDescription;

  /// No description provided for @analyticsAchievementsTitle.
  ///
  /// In es, this message translates to:
  /// **'Logros'**
  String get analyticsAchievementsTitle;

  /// No description provided for @analyticsAchievementsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay logros desbloqueados.'**
  String get analyticsAchievementsEmpty;

  /// No description provided for @analyticsAchievementsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar tus logros.'**
  String get analyticsAchievementsLoadError;

  /// No description provided for @analyticsBestDayLabel.
  ///
  /// In es, this message translates to:
  /// **'Mejor día'**
  String get analyticsBestDayLabel;

  /// No description provided for @analyticsBestStreakHint.
  ///
  /// In es, this message translates to:
  /// **'Tu mejor racha: {count} días'**
  String analyticsBestStreakHint(Object count);

  /// No description provided for @analyticsBestStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'Mejor racha'**
  String get analyticsBestStreakLabel;

  /// No description provided for @analyticsByPrayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Por oración'**
  String get analyticsByPrayerTitle;

  /// No description provided for @analyticsCollectionsLabel.
  ///
  /// In es, this message translates to:
  /// **'Colecciones'**
  String get analyticsCollectionsLabel;

  /// No description provided for @analyticsCompletedPrayersLabel.
  ///
  /// In es, this message translates to:
  /// **'Oraciones completadas'**
  String get analyticsCompletedPrayersLabel;

  /// No description provided for @analyticsCurrentStreakLabel.
  ///
  /// In es, this message translates to:
  /// **'Racha actual'**
  String get analyticsCurrentStreakLabel;

  /// No description provided for @analyticsDaysValue.
  ///
  /// In es, this message translates to:
  /// **'{count} días'**
  String analyticsDaysValue(Object count);

  /// No description provided for @analyticsEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Empieza a marcar tus oraciones y aquí verás cómo avanza tu constancia.'**
  String get analyticsEmptyBody;

  /// No description provided for @analyticsEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Completa tu primera oración para desbloquear este panel.'**
  String get analyticsEmptyHint;

  /// No description provided for @analyticsEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay estadísticas'**
  String get analyticsEmptyTitle;

  /// No description provided for @analyticsFavoritesLabel.
  ///
  /// In es, this message translates to:
  /// **'Favoritos'**
  String get analyticsFavoritesLabel;

  /// No description provided for @analyticsFullDaysLabel.
  ///
  /// In es, this message translates to:
  /// **'Días completos'**
  String get analyticsFullDaysLabel;

  /// No description provided for @analyticsGradesLabel.
  ///
  /// In es, this message translates to:
  /// **'Grados'**
  String get analyticsGradesLabel;

  /// No description provided for @analyticsHadithStatsLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las estadísticas de hadices.'**
  String get analyticsHadithStatsLoadError;

  /// No description provided for @analyticsLast30DaysTitle.
  ///
  /// In es, this message translates to:
  /// **'Últimos 30 días'**
  String get analyticsLast30DaysTitle;

  /// No description provided for @analyticsLessLabel.
  ///
  /// In es, this message translates to:
  /// **'Menos'**
  String get analyticsLessLabel;

  /// No description provided for @analyticsMoreLabel.
  ///
  /// In es, this message translates to:
  /// **'Más'**
  String get analyticsMoreLabel;

  /// No description provided for @analyticsNoActiveStreak.
  ///
  /// In es, this message translates to:
  /// **'Sin racha activa'**
  String get analyticsNoActiveStreak;

  /// No description provided for @analyticsRecordBadge.
  ///
  /// In es, this message translates to:
  /// **'Récord'**
  String get analyticsRecordBadge;

  /// No description provided for @analyticsSavedFavoritesLabel.
  ///
  /// In es, this message translates to:
  /// **'Favoritos guardados'**
  String get analyticsSavedFavoritesLabel;

  /// No description provided for @analyticsShareError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido compartir tu progreso.'**
  String get analyticsShareError;

  /// No description provided for @analyticsShareImage.
  ///
  /// In es, this message translates to:
  /// **'Compartir imagen'**
  String get analyticsShareImage;

  /// No description provided for @analyticsShareProgressTooltip.
  ///
  /// In es, this message translates to:
  /// **'Compartir progreso'**
  String get analyticsShareProgressTooltip;

  /// No description provided for @analyticsShareText.
  ///
  /// In es, this message translates to:
  /// **'Compartir texto'**
  String get analyticsShareText;

  /// No description provided for @analyticsStartStreakHint.
  ///
  /// In es, this message translates to:
  /// **'Empieza hoy una nueva racha.'**
  String get analyticsStartStreakHint;

  /// No description provided for @analyticsStreakDays.
  ///
  /// In es, this message translates to:
  /// **'{count} días de racha'**
  String analyticsStreakDays(Object count);

  /// No description provided for @analyticsThisWeekLabel.
  ///
  /// In es, this message translates to:
  /// **'Esta semana'**
  String get analyticsThisWeekLabel;

  /// No description provided for @analyticsWeekInterpretationEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no hay suficiente actividad esta semana.'**
  String get analyticsWeekInterpretationEmpty;

  /// No description provided for @analyticsWeekInterpretationEncouragement.
  ///
  /// In es, this message translates to:
  /// **'Sigue poco a poco. Cada oración cuenta.'**
  String get analyticsWeekInterpretationEncouragement;

  /// No description provided for @analyticsWeekInterpretationGood.
  ///
  /// In es, this message translates to:
  /// **'Vas bien esta semana. Un poco más de constancia marcará diferencia.'**
  String get analyticsWeekInterpretationGood;

  /// No description provided for @analyticsWeekInterpretationStrong.
  ///
  /// In es, this message translates to:
  /// **'Semana muy sólida. Estás manteniendo un ritmo excelente.'**
  String get analyticsWeekInterpretationStrong;

  /// No description provided for @analyticsWeeklySummaryTitle.
  ///
  /// In es, this message translates to:
  /// **'Resumen semanal'**
  String get analyticsWeeklySummaryTitle;

  /// No description provided for @booksAboutBody.
  ///
  /// In es, this message translates to:
  /// **'Esta biblioteca reúne libros de IslamHouse para una consulta rápida desde la app.'**
  String get booksAboutBody;

  /// No description provided for @booksAboutBulletCatalog.
  ///
  /// In es, this message translates to:
  /// **'Catálogo cuidado y fácil de explorar'**
  String get booksAboutBulletCatalog;

  /// No description provided for @booksAboutBulletCategories.
  ///
  /// In es, this message translates to:
  /// **'Categorías para encontrar lecturas más rápido'**
  String get booksAboutBulletCategories;

  /// No description provided for @booksAboutBulletVerified.
  ///
  /// In es, this message translates to:
  /// **'Contenido procedente de una biblioteca islámica reconocida'**
  String get booksAboutBulletVerified;

  /// No description provided for @booksAllCategories.
  ///
  /// In es, this message translates to:
  /// **'Todas las categorías'**
  String get booksAllCategories;

  /// No description provided for @booksCategoriesTab.
  ///
  /// In es, this message translates to:
  /// **'Categorías'**
  String get booksCategoriesTab;

  /// No description provided for @booksDescription.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get booksDescription;

  /// No description provided for @booksEmptyCategories.
  ///
  /// In es, this message translates to:
  /// **'No hay categorías disponibles.'**
  String get booksEmptyCategories;

  /// No description provided for @booksEmptyFeatured.
  ///
  /// In es, this message translates to:
  /// **'No hay libros destacados por ahora.'**
  String get booksEmptyFeatured;

  /// No description provided for @booksEmptySearch.
  ///
  /// In es, this message translates to:
  /// **'No encontramos libros con esa búsqueda.'**
  String get booksEmptySearch;

  /// No description provided for @booksLibraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Libros'**
  String get booksLibraryTitle;

  /// No description provided for @booksLoadErrorTitle.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar la biblioteca'**
  String get booksLoadErrorTitle;

  /// No description provided for @booksMainCategoryAcademicLessons.
  ///
  /// In es, this message translates to:
  /// **'Lecciones académicas'**
  String get booksMainCategoryAcademicLessons;

  /// No description provided for @booksMainCategoryArabicLanguage.
  ///
  /// In es, this message translates to:
  /// **'Lengua árabe'**
  String get booksMainCategoryArabicLanguage;

  /// No description provided for @booksMainCategoryCallToIslam.
  ///
  /// In es, this message translates to:
  /// **'Llamada al islam'**
  String get booksMainCategoryCallToIslam;

  /// No description provided for @booksMainCategoryHistory.
  ///
  /// In es, this message translates to:
  /// **'Historia'**
  String get booksMainCategoryHistory;

  /// No description provided for @booksMainCategoryIslamicBelief.
  ///
  /// In es, this message translates to:
  /// **'Creencia islámica'**
  String get booksMainCategoryIslamicBelief;

  /// No description provided for @booksMainCategoryIslamicCulture.
  ///
  /// In es, this message translates to:
  /// **'Cultura islámica'**
  String get booksMainCategoryIslamicCulture;

  /// No description provided for @booksMainCategoryIslamicJurisprudence.
  ///
  /// In es, this message translates to:
  /// **'Jurisprudencia islámica'**
  String get booksMainCategoryIslamicJurisprudence;

  /// No description provided for @booksMainCategoryMajorSins.
  ///
  /// In es, this message translates to:
  /// **'Pecados mayores'**
  String get booksMainCategoryMajorSins;

  /// No description provided for @booksMainCategoryNobleQuran.
  ///
  /// In es, this message translates to:
  /// **'Noble Corán'**
  String get booksMainCategoryNobleQuran;

  /// No description provided for @booksMainCategoryPresentingIslam.
  ///
  /// In es, this message translates to:
  /// **'Presentar el islam'**
  String get booksMainCategoryPresentingIslam;

  /// No description provided for @booksMainCategoryPropheticBiography.
  ///
  /// In es, this message translates to:
  /// **'Biografía profética'**
  String get booksMainCategoryPropheticBiography;

  /// No description provided for @booksMainCategoryProphetSunnah.
  ///
  /// In es, this message translates to:
  /// **'Sunna del Profeta'**
  String get booksMainCategoryProphetSunnah;

  /// No description provided for @booksMainCategorySermons.
  ///
  /// In es, this message translates to:
  /// **'Sermones'**
  String get booksMainCategorySermons;

  /// No description provided for @booksMainCategoryVirtues.
  ///
  /// In es, this message translates to:
  /// **'Virtudes'**
  String get booksMainCategoryVirtues;

  /// No description provided for @booksPageCount.
  ///
  /// In es, this message translates to:
  /// **'{pages} págs'**
  String booksPageCount(Object pages);

  /// No description provided for @booksPlaceholderDescription.
  ///
  /// In es, this message translates to:
  /// **'Pronto aparecerán libros aquí.'**
  String get booksPlaceholderDescription;

  /// No description provided for @booksPlaceholderTitle.
  ///
  /// In es, this message translates to:
  /// **'Biblioteca en preparación'**
  String get booksPlaceholderTitle;

  /// No description provided for @booksSearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar libro o autor'**
  String get booksSearchHint;

  /// No description provided for @booksUnnamedCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get booksUnnamedCategory;

  /// No description provided for @booksUntitled.
  ///
  /// In es, this message translates to:
  /// **'Sin título'**
  String get booksUntitled;

  /// No description provided for @booksVisitIslamHouse.
  ///
  /// In es, this message translates to:
  /// **'Visitar IslamHouse'**
  String get booksVisitIslamHouse;

  /// No description provided for @calendarCurrentMonth.
  ///
  /// In es, this message translates to:
  /// **'ESTE MES'**
  String get calendarCurrentMonth;

  /// No description provided for @calendarEventAshura.
  ///
  /// In es, this message translates to:
  /// **'Ashura'**
  String get calendarEventAshura;

  /// No description provided for @calendarEventDayOfArafah.
  ///
  /// In es, this message translates to:
  /// **'Día de Arafah'**
  String get calendarEventDayOfArafah;

  /// No description provided for @calendarEventEidAdha.
  ///
  /// In es, this message translates to:
  /// **'Eid al-Adha'**
  String get calendarEventEidAdha;

  /// No description provided for @calendarEventEidFitr.
  ///
  /// In es, this message translates to:
  /// **'Eid al-Fitr'**
  String get calendarEventEidFitr;

  /// No description provided for @calendarEventIslamicNewYear.
  ///
  /// In es, this message translates to:
  /// **'Año nuevo islámico'**
  String get calendarEventIslamicNewYear;

  /// No description provided for @calendarEventRamadanStart.
  ///
  /// In es, this message translates to:
  /// **'Inicio de Ramadán'**
  String get calendarEventRamadanStart;

  /// No description provided for @calendarImportantDatesTitle.
  ///
  /// In es, this message translates to:
  /// **'Fechas importantes de {year}'**
  String calendarImportantDatesTitle(Object year);

  /// No description provided for @calendarSelectDate.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una fecha'**
  String get calendarSelectDate;

  /// No description provided for @calendarSelectedDateUppercase.
  ///
  /// In es, this message translates to:
  /// **'FECHA SELECCIONADA'**
  String get calendarSelectedDateUppercase;

  /// No description provided for @calendarTitle.
  ///
  /// In es, this message translates to:
  /// **'Calendario islámico'**
  String get calendarTitle;

  /// No description provided for @calendarTodayLabel.
  ///
  /// In es, this message translates to:
  /// **'Hoy · {date}'**
  String calendarTodayLabel(Object date);

  /// No description provided for @dhikrChooseCustomValue.
  ///
  /// In es, this message translates to:
  /// **'Elegir valor personalizado'**
  String get dhikrChooseCustomValue;

  /// No description provided for @dhikrDailyGoalCompletedMessage.
  ///
  /// In es, this message translates to:
  /// **'Has completado tu meta diaria de dhikr.'**
  String get dhikrDailyGoalCompletedMessage;

  /// No description provided for @dhikrDailyGoalHelper.
  ///
  /// In es, this message translates to:
  /// **'Elige cuántas repeticiones quieres alcanzar hoy.'**
  String get dhikrDailyGoalHelper;

  /// No description provided for @dhikrDailyGoalShort.
  ///
  /// In es, this message translates to:
  /// **'Meta diaria'**
  String get dhikrDailyGoalShort;

  /// No description provided for @dhikrDailyGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta diaria'**
  String get dhikrDailyGoalTitle;

  /// No description provided for @dhikrDailyGoalUpdated.
  ///
  /// In es, this message translates to:
  /// **'Meta diaria actualizada a {value}'**
  String dhikrDailyGoalUpdated(Object value);

  /// No description provided for @dhikrFeedbackAlmostThere.
  ///
  /// In es, this message translates to:
  /// **'Vas muy bien. Estás cerca de tu meta diaria.'**
  String get dhikrFeedbackAlmostThere;

  /// No description provided for @dhikrFeedbackCompleted.
  ///
  /// In es, this message translates to:
  /// **'Meta diaria completada. Que Allah acepte tu dhikr.'**
  String get dhikrFeedbackCompleted;

  /// No description provided for @dhikrFeedbackCycleCompleted.
  ///
  /// In es, this message translates to:
  /// **'Ciclo completado. Puedes seguir con calma.'**
  String get dhikrFeedbackCycleCompleted;

  /// No description provided for @dhikrFeedbackGoodPace.
  ///
  /// In es, this message translates to:
  /// **'Buen ritmo. Mantén estas repeticiones con serenidad.'**
  String get dhikrFeedbackGoodPace;

  /// No description provided for @dhikrFeedbackStart.
  ///
  /// In es, this message translates to:
  /// **'Empieza con unas repeticiones suaves y constantes.'**
  String get dhikrFeedbackStart;

  /// No description provided for @dhikrFeedbackTakeYourTime.
  ///
  /// In es, this message translates to:
  /// **'Tómate tu tiempo. Cada repetición cuenta.'**
  String get dhikrFeedbackTakeYourTime;

  /// No description provided for @dhikrGoalsSection.
  ///
  /// In es, this message translates to:
  /// **'OBJETIVOS'**
  String get dhikrGoalsSection;

  /// No description provided for @dhikrHistoryEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay historial suficiente para esta vista.'**
  String get dhikrHistoryEmptyBody;

  /// No description provided for @dhikrHistorySavedBody.
  ///
  /// In es, this message translates to:
  /// **'Tu progreso reciente se guarda automáticamente.'**
  String get dhikrHistorySavedBody;

  /// No description provided for @dhikrLast7Days.
  ///
  /// In es, this message translates to:
  /// **'7 días'**
  String get dhikrLast7Days;

  /// No description provided for @dhikrMeaningAlhamdulillah.
  ///
  /// In es, this message translates to:
  /// **'Alabado sea Allah'**
  String get dhikrMeaningAlhamdulillah;

  /// No description provided for @dhikrMeaningAllahuAkbar.
  ///
  /// In es, this message translates to:
  /// **'Allah es el más Grande'**
  String get dhikrMeaningAllahuAkbar;

  /// No description provided for @dhikrMeaningSubhanAllah.
  ///
  /// In es, this message translates to:
  /// **'Gloria a Allah'**
  String get dhikrMeaningSubhanAllah;

  /// No description provided for @dhikrRepetitionsFieldHint.
  ///
  /// In es, this message translates to:
  /// **'Ejemplo: 100'**
  String get dhikrRepetitionsFieldHint;

  /// No description provided for @dhikrRepetitionsFieldLabel.
  ///
  /// In es, this message translates to:
  /// **'Repeticiones'**
  String get dhikrRepetitionsFieldLabel;

  /// No description provided for @dhikrResetSession.
  ///
  /// In es, this message translates to:
  /// **'Reiniciar sesión'**
  String get dhikrResetSession;

  /// No description provided for @dhikrSessionCountOf.
  ///
  /// In es, this message translates to:
  /// **'de {count}'**
  String dhikrSessionCountOf(Object count);

  /// No description provided for @dhikrSessionCycleCompleted.
  ///
  /// In es, this message translates to:
  /// **'Has completado este ciclo de dhikr.'**
  String get dhikrSessionCycleCompleted;

  /// No description provided for @dhikrSessionGoalHelper.
  ///
  /// In es, this message translates to:
  /// **'Define cuántas repeticiones quieres hacer por ciclo.'**
  String get dhikrSessionGoalHelper;

  /// No description provided for @dhikrSessionGoalShort.
  ///
  /// In es, this message translates to:
  /// **'Meta de sesión'**
  String get dhikrSessionGoalShort;

  /// No description provided for @dhikrSessionGoalTitle.
  ///
  /// In es, this message translates to:
  /// **'Meta de sesión'**
  String get dhikrSessionGoalTitle;

  /// No description provided for @dhikrSessionGoalUpdated.
  ///
  /// In es, this message translates to:
  /// **'Meta de sesión actualizada a {value}'**
  String dhikrSessionGoalUpdated(Object value);

  /// No description provided for @dhikrSessionResetMessage.
  ///
  /// In es, this message translates to:
  /// **'La sesión se ha reiniciado.'**
  String get dhikrSessionResetMessage;

  /// No description provided for @dhikrSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Recuerdo consciente para tu día'**
  String get dhikrSubtitle;

  /// No description provided for @dhikrSummarySection.
  ///
  /// In es, this message translates to:
  /// **'RESUMEN'**
  String get dhikrSummarySection;

  /// No description provided for @dhikrTitle.
  ///
  /// In es, this message translates to:
  /// **'Dhikr'**
  String get dhikrTitle;

  /// No description provided for @dhikrTodayCycle.
  ///
  /// In es, this message translates to:
  /// **'Hoy: {today} · ciclo {current}/{total}'**
  String dhikrTodayCycle(Object current, Object today, Object total);

  /// No description provided for @hadithDailyBadge.
  ///
  /// In es, this message translates to:
  /// **'HADIZ DEL DÍA'**
  String get hadithDailyBadge;

  /// No description provided for @hadithDailyOpenLibrary.
  ///
  /// In es, this message translates to:
  /// **'Ver hadices'**
  String get hadithDailyOpenLibrary;

  /// No description provided for @hadithDailyUnavailable.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar el hadiz del día.'**
  String get hadithDailyUnavailable;

  /// No description provided for @hadithDetailArabicText.
  ///
  /// In es, this message translates to:
  /// **'Texto árabe'**
  String get hadithDetailArabicText;

  /// No description provided for @hadithDetailCopied.
  ///
  /// In es, this message translates to:
  /// **'Hadiz copiado'**
  String get hadithDetailCopied;

  /// No description provided for @hadithDetailCopyText.
  ///
  /// In es, this message translates to:
  /// **'Copiar texto'**
  String get hadithDetailCopyText;

  /// No description provided for @hadithDetailGrade.
  ///
  /// In es, this message translates to:
  /// **'Grado: {grade}'**
  String hadithDetailGrade(Object grade);

  /// No description provided for @hadithDetailHideArabic.
  ///
  /// In es, this message translates to:
  /// **'Ocultar árabe'**
  String get hadithDetailHideArabic;

  /// No description provided for @hadithDetailHideTranslation.
  ///
  /// In es, this message translates to:
  /// **'Ocultar traducción'**
  String get hadithDetailHideTranslation;

  /// No description provided for @hadithDetailId.
  ///
  /// In es, this message translates to:
  /// **'ID: {id}'**
  String hadithDetailId(Object id);

  /// No description provided for @hadithDetailInfoBody.
  ///
  /// In es, this message translates to:
  /// **'Este hadiz puede variar según la colección, el grado y la traducción disponible.'**
  String get hadithDetailInfoBody;

  /// No description provided for @hadithDetailNoCategory.
  ///
  /// In es, this message translates to:
  /// **'Sin categoría'**
  String get hadithDetailNoCategory;

  /// No description provided for @hadithDetailRemovedFromFavorites.
  ///
  /// In es, this message translates to:
  /// **'Hadiz quitado de favoritos'**
  String get hadithDetailRemovedFromFavorites;

  /// No description provided for @hadithDetailSavedToFavorites.
  ///
  /// In es, this message translates to:
  /// **'Hadiz guardado en favoritos'**
  String get hadithDetailSavedToFavorites;

  /// No description provided for @hadithDetailShowArabic.
  ///
  /// In es, this message translates to:
  /// **'Mostrar árabe'**
  String get hadithDetailShowArabic;

  /// No description provided for @hadithDetailShowTranslation.
  ///
  /// In es, this message translates to:
  /// **'Mostrar traducción'**
  String get hadithDetailShowTranslation;

  /// No description provided for @hadithDetailTitle.
  ///
  /// In es, this message translates to:
  /// **'Detalle del hadiz'**
  String get hadithDetailTitle;

  /// No description provided for @hadithDetailTranslation.
  ///
  /// In es, this message translates to:
  /// **'Traducción'**
  String get hadithDetailTranslation;

  /// No description provided for @hadithLibraryAllCollections.
  ///
  /// In es, this message translates to:
  /// **'Todas las colecciones'**
  String get hadithLibraryAllCollections;

  /// No description provided for @hadithLibraryAllGrades.
  ///
  /// In es, this message translates to:
  /// **'Todos los grados'**
  String get hadithLibraryAllGrades;

  /// No description provided for @hadithLibraryAllHadiths.
  ///
  /// In es, this message translates to:
  /// **'{count} hadices'**
  String hadithLibraryAllHadiths(Object count);

  /// No description provided for @hadithLibraryEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'No hay hadices disponibles ahora mismo.'**
  String get hadithLibraryEmptyBody;

  /// No description provided for @hadithLibraryEmptySearchBody.
  ///
  /// In es, this message translates to:
  /// **'Prueba con otra búsqueda o quita los filtros.'**
  String get hadithLibraryEmptySearchBody;

  /// No description provided for @hadithLibraryEmptySearchTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin resultados para “{query}”'**
  String hadithLibraryEmptySearchTitle(Object query);

  /// No description provided for @hadithLibraryEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin hadices disponibles'**
  String get hadithLibraryEmptyTitle;

  /// No description provided for @hadithLibraryFiltersError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar los filtros.'**
  String get hadithLibraryFiltersError;

  /// No description provided for @hadithLibraryFiltersLoading.
  ///
  /// In es, this message translates to:
  /// **'Cargando filtros…'**
  String get hadithLibraryFiltersLoading;

  /// No description provided for @hadithLibraryLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar los hadices.\n{error}'**
  String hadithLibraryLoadError(Object error);

  /// No description provided for @hadithLibraryResultsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} resultados'**
  String hadithLibraryResultsCount(Object count);

  /// No description provided for @hadithLibrarySearchHint.
  ///
  /// In es, this message translates to:
  /// **'Buscar hadiz o referencia'**
  String get hadithLibrarySearchHint;

  /// No description provided for @hadithLibraryTitle.
  ///
  /// In es, this message translates to:
  /// **'Hadices'**
  String get hadithLibraryTitle;

  /// No description provided for @hadithOfflineAvailability.
  ///
  /// In es, this message translates to:
  /// **'{progress} disponible sin conexión'**
  String hadithOfflineAvailability(Object progress);

  /// No description provided for @hadithOfflineAvailable.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get hadithOfflineAvailable;

  /// No description provided for @hadithOfflineCollectionsTitle.
  ///
  /// In es, this message translates to:
  /// **'Colecciones incluidas'**
  String get hadithOfflineCollectionsTitle;

  /// No description provided for @hadithOfflineIncludedSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Todo el contenido viene integrado en la app'**
  String get hadithOfflineIncludedSubtitle;

  /// No description provided for @hadithOfflineIncludedTitle.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión desde el principio'**
  String get hadithOfflineIncludedTitle;

  /// No description provided for @hadithOfflineInfoBody.
  ///
  /// In es, this message translates to:
  /// **'Los hadices incluidos aquí ya están disponibles sin descarga adicional.'**
  String get hadithOfflineInfoBody;

  /// No description provided for @hadithOfflineTitle.
  ///
  /// In es, this message translates to:
  /// **'Hadices sin conexión'**
  String get hadithOfflineTitle;

  /// No description provided for @hafizActivePlans.
  ///
  /// In es, this message translates to:
  /// **'Planes activos'**
  String get hafizActivePlans;

  /// No description provided for @hafizAyahRange.
  ///
  /// In es, this message translates to:
  /// **'Aleyas {start}-{end}'**
  String hafizAyahRange(Object end, Object start);

  /// No description provided for @hafizConfigureSession.
  ///
  /// In es, this message translates to:
  /// **'Configurar sesión'**
  String get hafizConfigureSession;

  /// No description provided for @hafizEmptyBody.
  ///
  /// In es, this message translates to:
  /// **'Todavía no has creado ningún plan de memorización.'**
  String get hafizEmptyBody;

  /// No description provided for @hafizEmptyHint.
  ///
  /// In es, this message translates to:
  /// **'Elige una sura y define un tramo corto para empezar.'**
  String get hafizEmptyHint;

  /// No description provided for @hafizEmptyTitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza tu repaso'**
  String get hafizEmptyTitle;

  /// No description provided for @hafizEndAyah.
  ///
  /// In es, this message translates to:
  /// **'Aleya final: {ayah}'**
  String hafizEndAyah(Object ayah);

  /// No description provided for @hafizLoadError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar esta sura.'**
  String get hafizLoadError;

  /// No description provided for @hafizLogRepetition.
  ///
  /// In es, this message translates to:
  /// **'Registrar repetición'**
  String get hafizLogRepetition;

  /// No description provided for @hafizPlanSaved.
  ///
  /// In es, this message translates to:
  /// **'Plan guardado'**
  String get hafizPlanSaved;

  /// No description provided for @hafizRepetitionLogged.
  ///
  /// In es, this message translates to:
  /// **'Repetición registrada'**
  String get hafizRepetitionLogged;

  /// No description provided for @hafizReviewedSurahs.
  ///
  /// In es, this message translates to:
  /// **'Suras repasadas'**
  String get hafizReviewedSurahs;

  /// No description provided for @hafizSavePlan.
  ///
  /// In es, this message translates to:
  /// **'Guardar plan'**
  String get hafizSavePlan;

  /// No description provided for @hafizSelectedSegment.
  ///
  /// In es, this message translates to:
  /// **'Tramo seleccionado'**
  String get hafizSelectedSegment;

  /// No description provided for @hafizStartAyah.
  ///
  /// In es, this message translates to:
  /// **'Aleya inicial: {ayah}'**
  String hafizStartAyah(Object ayah);

  /// No description provided for @hafizSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Organiza repasos breves y constantes'**
  String get hafizSubtitle;

  /// No description provided for @hafizSurahNoPlan.
  ///
  /// In es, this message translates to:
  /// **'{count} aleyas · sin plan'**
  String hafizSurahNoPlan(Object count);

  /// No description provided for @hafizSurahProgress.
  ///
  /// In es, this message translates to:
  /// **'{start}-{end} · {percent}% completado'**
  String hafizSurahProgress(Object end, Object percent, Object start);

  /// No description provided for @hafizTargetRepetitions.
  ///
  /// In es, this message translates to:
  /// **'Objetivo: {count}'**
  String hafizTargetRepetitions(Object count);

  /// No description provided for @homeCalendarStripTitle.
  ///
  /// In es, this message translates to:
  /// **'CALENDARIO SAGRADO'**
  String get homeCalendarStripTitle;

  /// No description provided for @homeGoalCompleted.
  ///
  /// In es, this message translates to:
  /// **'cumplido'**
  String get homeGoalCompleted;

  /// No description provided for @homeGoalInProgress.
  ///
  /// In es, this message translates to:
  /// **'en progreso'**
  String get homeGoalInProgress;

  /// No description provided for @homeInsightAlmostCompleteTodayMessage.
  ///
  /// In es, this message translates to:
  /// **'Te queda muy poco para cerrar un día fuerte.'**
  String get homeInsightAlmostCompleteTodayMessage;

  /// No description provided for @homeInsightAlmostCompleteTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Casi completo hoy'**
  String get homeInsightAlmostCompleteTodayTitle;

  /// No description provided for @homeInsightBetterThanLastWeekMessage.
  ///
  /// In es, this message translates to:
  /// **'Has completado {delta} oraciones más que la semana pasada.'**
  String homeInsightBetterThanLastWeekMessage(Object delta);

  /// No description provided for @homeInsightBetterThanLastWeekTitle.
  ///
  /// In es, this message translates to:
  /// **'Mejor que la semana pasada'**
  String get homeInsightBetterThanLastWeekTitle;

  /// No description provided for @homeInsightDhikrDoneMessage.
  ///
  /// In es, this message translates to:
  /// **'Has hecho {count} repeticiones hoy. Muy buen cierre.'**
  String homeInsightDhikrDoneMessage(Object count);

  /// No description provided for @homeInsightDhikrDoneTitle.
  ///
  /// In es, this message translates to:
  /// **'Dhikr completado'**
  String get homeInsightDhikrDoneTitle;

  /// No description provided for @homeInsightDhikrGoodPaceMessage.
  ///
  /// In es, this message translates to:
  /// **'Llevas {current}/{goal} repeticiones hoy.'**
  String homeInsightDhikrGoodPaceMessage(Object current, Object goal);

  /// No description provided for @homeInsightDhikrGoodPaceTitle.
  ///
  /// In es, this message translates to:
  /// **'Buen ritmo de dhikr'**
  String get homeInsightDhikrGoodPaceTitle;

  /// No description provided for @homeInsightGoodPaceTodayMessage.
  ///
  /// In es, this message translates to:
  /// **'Llevas {count} oraciones completadas hoy.'**
  String homeInsightGoodPaceTodayMessage(Object count);

  /// No description provided for @homeInsightGoodPaceTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Buen ritmo hoy'**
  String get homeInsightGoodPaceTodayTitle;

  /// No description provided for @homeInsightMostConsistentPrayerMessage.
  ///
  /// In es, this message translates to:
  /// **'{prayer} está siendo tu momento más estable.'**
  String homeInsightMostConsistentPrayerMessage(Object prayer);

  /// No description provided for @homeInsightMostConsistentPrayerTitle.
  ///
  /// In es, this message translates to:
  /// **'Tu oración más constante'**
  String get homeInsightMostConsistentPrayerTitle;

  /// No description provided for @homeInsightPrayerToStrengthenMessage.
  ///
  /// In es, this message translates to:
  /// **'{prayer} necesita un poco más de atención.'**
  String homeInsightPrayerToStrengthenMessage(Object prayer);

  /// No description provided for @homeInsightPrayerToStrengthenTitle.
  ///
  /// In es, this message translates to:
  /// **'Oración a reforzar'**
  String get homeInsightPrayerToStrengthenTitle;

  /// No description provided for @homeInsightRamadanConsistencyMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu práctica de hoy ya refleja un buen equilibrio.'**
  String get homeInsightRamadanConsistencyMessage;

  /// No description provided for @homeInsightRamadanConsistencyTitle.
  ///
  /// In es, this message translates to:
  /// **'Constancia en Ramadán'**
  String get homeInsightRamadanConsistencyTitle;

  /// No description provided for @homeInsightRamadanMomentumMessage.
  ///
  /// In es, this message translates to:
  /// **'Aprovecha este tramo del día para sostener el impulso.'**
  String get homeInsightRamadanMomentumMessage;

  /// No description provided for @homeInsightRamadanMomentumTitle.
  ///
  /// In es, this message translates to:
  /// **'Momento de Ramadán'**
  String get homeInsightRamadanMomentumTitle;

  /// No description provided for @homeInsightRamadanSmallStepsMessage.
  ///
  /// In es, this message translates to:
  /// **'En Ramadán, los pasos pequeños y constantes cuentan mucho.'**
  String get homeInsightRamadanSmallStepsMessage;

  /// No description provided for @homeInsightStartTodayFirstMessage.
  ///
  /// In es, this message translates to:
  /// **'Tu día aún está abierto. Marca tu primera oración y crea impulso.'**
  String get homeInsightStartTodayFirstMessage;

  /// No description provided for @homeInsightStartTodayMoreMessage.
  ///
  /// In es, this message translates to:
  /// **'Todavía estás a tiempo de empezar con calma.'**
  String get homeInsightStartTodayMoreMessage;

  /// No description provided for @homeInsightStartTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'Empieza hoy'**
  String get homeInsightStartTodayTitle;

  /// No description provided for @homeInsightStillCanStartMessage.
  ///
  /// In es, this message translates to:
  /// **'Un paso pequeño ahora puede cambiar el tono del día.'**
  String get homeInsightStillCanStartMessage;

  /// No description provided for @homeInsightStillCanStartTitle.
  ///
  /// In es, this message translates to:
  /// **'Aún puedes empezar'**
  String get homeInsightStillCanStartTitle;

  /// No description provided for @homeInsightStreakInMotionMessage.
  ///
  /// In es, this message translates to:
  /// **'Llevas {streak} días seguidos. Protege esa constancia.'**
  String homeInsightStreakInMotionMessage(Object streak);

  /// No description provided for @homeInsightStreakInMotionTitle.
  ///
  /// In es, this message translates to:
  /// **'Racha en movimiento'**
  String get homeInsightStreakInMotionTitle;

  /// No description provided for @homeInsightTodayLabel.
  ///
  /// In es, this message translates to:
  /// **'INSIGHT DE HOY'**
  String get homeInsightTodayLabel;

  /// No description provided for @homeLoadingScheduleBody.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu próxima oración'**
  String get homeLoadingScheduleBody;

  /// No description provided for @homeLoadingScheduleTitle.
  ///
  /// In es, this message translates to:
  /// **'Cargando horarios'**
  String get homeLoadingScheduleTitle;

  /// No description provided for @homeLocationCachedBody.
  ///
  /// In es, this message translates to:
  /// **'Estamos preparando tus horarios usando la última ubicación guardada.'**
  String get homeLocationCachedBody;

  /// No description provided for @homeLocationEnableDeviceLocation.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación del dispositivo'**
  String get homeLocationEnableDeviceLocation;

  /// No description provided for @homeLocationGpsDisabledBody.
  ///
  /// In es, this message translates to:
  /// **'Sin GPS activo no podemos calcular horarios precisos ni orientar la Qibla.'**
  String get homeLocationGpsDisabledBody;

  /// No description provided for @homeLocationPendingBody.
  ///
  /// In es, this message translates to:
  /// **'La pantalla principal sigue visible aunque los horarios aún no estén listos.'**
  String get homeLocationPendingBody;

  /// No description provided for @homeLocationPermissionBlocked.
  ///
  /// In es, this message translates to:
  /// **'Permiso de ubicación bloqueado'**
  String get homeLocationPermissionBlocked;

  /// No description provided for @homeLocationPermissionBlockedBody.
  ///
  /// In es, this message translates to:
  /// **'Puedes activar la ubicación para Qibla Time desde los ajustes del sistema cuando quieras.'**
  String get homeLocationPermissionBlockedBody;

  /// No description provided for @homeLocationPermissionNeeded.
  ///
  /// In es, this message translates to:
  /// **'Permite la ubicación para ver tus horarios'**
  String get homeLocationPermissionNeeded;

  /// No description provided for @homeLocationPermissionNeededBody.
  ///
  /// In es, this message translates to:
  /// **'Qibla Time necesita tu ubicación para mostrar horarios fiables según tu ciudad.'**
  String get homeLocationPermissionNeededBody;

  /// No description provided for @homeLocationPreparingTitle.
  ///
  /// In es, this message translates to:
  /// **'Preparando tus horarios'**
  String get homeLocationPreparingTitle;

  /// No description provided for @homeNextPrayerStartsAt.
  ///
  /// In es, this message translates to:
  /// **'Comienza a las {time}'**
  String homeNextPrayerStartsAt(Object time);

  /// No description provided for @homeNotificationPaused.
  ///
  /// In es, this message translates to:
  /// **'Los avisos generales de oración están pausados ahora mismo.'**
  String get homeNotificationPaused;

  /// No description provided for @homeNotificationPermissionPending.
  ///
  /// In es, this message translates to:
  /// **'Tus recordatorios de adhan están configurados, pero el permiso del sistema sigue pendiente.'**
  String get homeNotificationPermissionPending;

  /// No description provided for @homePrayerDescriptionCompleted.
  ///
  /// In es, this message translates to:
  /// **'Ya la marcaste como completada.'**
  String get homePrayerDescriptionCompleted;

  /// No description provided for @homePrayerDescriptionNext.
  ///
  /// In es, this message translates to:
  /// **'Es la siguiente en el ritmo de hoy.'**
  String get homePrayerDescriptionNext;

  /// No description provided for @homePrayerDescriptionNow.
  ///
  /// In es, this message translates to:
  /// **'Esta oración está en curso ahora mismo.'**
  String get homePrayerDescriptionNow;

  /// No description provided for @homePrayerDescriptionPendingToday.
  ///
  /// In es, this message translates to:
  /// **'Pendiente dentro del recorrido de hoy.'**
  String get homePrayerDescriptionPendingToday;

  /// No description provided for @homePrayerDescriptionReviewDate.
  ///
  /// In es, this message translates to:
  /// **'Disponible para revisar esta fecha.'**
  String get homePrayerDescriptionReviewDate;

  /// No description provided for @homePrayerSectionSelectedDaySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Consulta y marca los horarios de {date}'**
  String homePrayerSectionSelectedDaySubtitle(Object date);

  /// No description provided for @homePrayerSectionSelectedDayTitle.
  ///
  /// In es, this message translates to:
  /// **'HORARIOS DEL DÍA'**
  String get homePrayerSectionSelectedDayTitle;

  /// No description provided for @homePrayerSectionTodaySubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ritmo completo de tus cinco oraciones'**
  String get homePrayerSectionTodaySubtitle;

  /// No description provided for @homePrayerSectionTodayTitle.
  ///
  /// In es, this message translates to:
  /// **'ORACIONES DE HOY'**
  String get homePrayerSectionTodayTitle;

  /// No description provided for @homePrayerStatusCompleted.
  ///
  /// In es, this message translates to:
  /// **'Completada'**
  String get homePrayerStatusCompleted;

  /// No description provided for @homePrayerStatusNext.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get homePrayerStatusNext;

  /// No description provided for @homePrayerStatusNow.
  ///
  /// In es, this message translates to:
  /// **'Ahora'**
  String get homePrayerStatusNow;

  /// No description provided for @homePrayerStatusUpcoming.
  ///
  /// In es, this message translates to:
  /// **'Próxima'**
  String get homePrayerStatusUpcoming;

  /// No description provided for @homeQuickActionsTitle.
  ///
  /// In es, this message translates to:
  /// **'ACCESOS SAGRADOS'**
  String get homeQuickActionsTitle;

  /// No description provided for @homeRamadanClosingSoon.
  ///
  /// In es, this message translates to:
  /// **'cierre cercano'**
  String get homeRamadanClosingSoon;

  /// No description provided for @homeRamadanContinueReading.
  ///
  /// In es, this message translates to:
  /// **'Continuar lectura'**
  String get homeRamadanContinueReading;

  /// No description provided for @homeRamadanCountdownIftar.
  ///
  /// In es, this message translates to:
  /// **'Faltan {duration} para Iftar'**
  String homeRamadanCountdownIftar(Object duration);

  /// No description provided for @homeRamadanCountdownImsak.
  ///
  /// In es, this message translates to:
  /// **'Faltan {duration} para Imsak'**
  String homeRamadanCountdownImsak(Object duration);

  /// No description provided for @homeRamadanCountdownTomorrowImsak.
  ///
  /// In es, this message translates to:
  /// **'Faltan {duration} para Imsak de mañana'**
  String homeRamadanCountdownTomorrowImsak(Object duration);

  /// No description provided for @homeRamadanDhikrCompletedBody.
  ///
  /// In es, this message translates to:
  /// **'{current}/{goal} repeticiones hoy. Meta diaria cumplida.'**
  String homeRamadanDhikrCompletedBody(Object current, Object goal);

  /// No description provided for @homeRamadanDhikrInProgressBody.
  ///
  /// In es, this message translates to:
  /// **'{current}/{goal} repeticiones hoy. Ya has empezado.'**
  String homeRamadanDhikrInProgressBody(Object current, Object goal);

  /// No description provided for @homeRamadanDhikrPreparingBody.
  ///
  /// In es, this message translates to:
  /// **'Preparando tu progreso diario de dhikr.'**
  String get homeRamadanDhikrPreparingBody;

  /// No description provided for @homeRamadanDhikrStartBody.
  ///
  /// In es, this message translates to:
  /// **'Tu objetivo de hoy es {goal}. Unas pocas repeticiones ya suman.'**
  String homeRamadanDhikrStartBody(Object goal);

  /// No description provided for @homeRamadanFastingCompleted.
  ///
  /// In es, this message translates to:
  /// **'Ya puedes hacer iftar desde las {time}.'**
  String homeRamadanFastingCompleted(Object time);

  /// No description provided for @homeRamadanFastingInProgress.
  ///
  /// In es, this message translates to:
  /// **'Día de ayuno en curso hasta las {time}.'**
  String homeRamadanFastingInProgress(Object time);

  /// No description provided for @homeRamadanFastingLabel.
  ///
  /// In es, this message translates to:
  /// **'Ayuno'**
  String get homeRamadanFastingLabel;

  /// No description provided for @homeRamadanFastingTitle.
  ///
  /// In es, this message translates to:
  /// **'Ayuno'**
  String get homeRamadanFastingTitle;

  /// No description provided for @homeRamadanGoalsCompleteMessage.
  ///
  /// In es, this message translates to:
  /// **'Jornada de Ramadán muy completa. Mantén este ritmo con calma.'**
  String get homeRamadanGoalsCompleteMessage;

  /// No description provided for @homeRamadanGoalsProgressMessage.
  ///
  /// In es, this message translates to:
  /// **'Vas bien hoy. Un pequeño paso más puede cerrar tu día con fuerza.'**
  String get homeRamadanGoalsProgressMessage;

  /// No description provided for @homeRamadanGoalsReady.
  ///
  /// In es, this message translates to:
  /// **'{completed}/{total} listos'**
  String homeRamadanGoalsReady(Object completed, Object total);

  /// No description provided for @homeRamadanGoalsStartMessage.
  ///
  /// In es, this message translates to:
  /// **'Empieza por algo pequeño: una oración, unas aleyas o unos minutos de dhikr.'**
  String get homeRamadanGoalsStartMessage;

  /// No description provided for @homeRamadanGoalsTitle.
  ///
  /// In es, this message translates to:
  /// **'OBJETIVOS DE RAMADÁN'**
  String get homeRamadanGoalsTitle;

  /// No description provided for @homeRamadanModeTitle.
  ///
  /// In es, this message translates to:
  /// **'MODO RAMADÁN'**
  String get homeRamadanModeTitle;

  /// No description provided for @homeRamadanNextFocus.
  ///
  /// In es, this message translates to:
  /// **'próximo foco'**
  String get homeRamadanNextFocus;

  /// No description provided for @homeRamadanNightLabel.
  ///
  /// In es, this message translates to:
  /// **'Noche'**
  String get homeRamadanNightLabel;

  /// No description provided for @homeRamadanOpenQuran.
  ///
  /// In es, this message translates to:
  /// **'Abrir Corán'**
  String get homeRamadanOpenQuran;

  /// No description provided for @homeRamadanOpenTasbih.
  ///
  /// In es, this message translates to:
  /// **'Abrir tasbih'**
  String get homeRamadanOpenTasbih;

  /// No description provided for @homeRamadanPrayerGoal.
  ///
  /// In es, this message translates to:
  /// **'{count}/5 completadas hoy'**
  String homeRamadanPrayerGoal(Object count);

  /// No description provided for @homeRamadanQuranRecentProgress.
  ///
  /// In es, this message translates to:
  /// **'Retoma {surah}, aleya {ayah}. Tienes progreso reciente.'**
  String homeRamadanQuranRecentProgress(Object ayah, Object surah);

  /// No description provided for @homeRamadanQuranReturnBody.
  ///
  /// In es, this message translates to:
  /// **'Tu último punto fue {surah}, aleya {ayah}. Merece la pena retomarlo hoy.'**
  String homeRamadanQuranReturnBody(Object ayah, Object surah);

  /// No description provided for @homeRamadanQuranSavedToday.
  ///
  /// In es, this message translates to:
  /// **'Lectura guardada hoy en {surah}, aleya {ayah}.'**
  String homeRamadanQuranSavedToday(Object ayah, Object surah);

  /// No description provided for @homeRamadanQuranStartBody.
  ///
  /// In es, this message translates to:
  /// **'Haz una lectura corta hoy y luego podrás retomarla fácilmente.'**
  String get homeRamadanQuranStartBody;

  /// No description provided for @homeRamadanStartAction.
  ///
  /// In es, this message translates to:
  /// **'Empezar'**
  String get homeRamadanStartAction;

  /// No description provided for @homeRamadanSuhoorLabel.
  ///
  /// In es, this message translates to:
  /// **'Suhoor'**
  String get homeRamadanSuhoorLabel;

  /// No description provided for @homeRamadanUntilIftar.
  ///
  /// In es, this message translates to:
  /// **'hasta iftar'**
  String get homeRamadanUntilIftar;

  /// No description provided for @homeSelectedDateCustomBody.
  ///
  /// In es, this message translates to:
  /// **'Consulta abajo los horarios completos del día seleccionado.'**
  String get homeSelectedDateCustomBody;

  /// No description provided for @homeSelectedDateTodayBody.
  ///
  /// In es, this message translates to:
  /// **'Consulta abajo los horarios completos de hoy.'**
  String get homeSelectedDateTodayBody;

  /// No description provided for @homeWeeklyBestDayHelper.
  ///
  /// In es, this message translates to:
  /// **'{count}/5 en tu mejor día'**
  String homeWeeklyBestDayHelper(Object count);

  /// No description provided for @qiblaCompassInitError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido iniciar la brújula.'**
  String get qiblaCompassInitError;

  /// No description provided for @qiblaCompassReadError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido leer el sensor de la brújula.'**
  String get qiblaCompassReadError;

  /// No description provided for @qiblaDirectionEast.
  ///
  /// In es, this message translates to:
  /// **'Este'**
  String get qiblaDirectionEast;

  /// No description provided for @qiblaDirectionLoadError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido cargar la dirección a la Kaaba.'**
  String get qiblaDirectionLoadError;

  /// No description provided for @qiblaDirectionNorth.
  ///
  /// In es, this message translates to:
  /// **'Norte'**
  String get qiblaDirectionNorth;

  /// No description provided for @qiblaDirectionNorthEast.
  ///
  /// In es, this message translates to:
  /// **'Noreste'**
  String get qiblaDirectionNorthEast;

  /// No description provided for @qiblaDirectionNorthWest.
  ///
  /// In es, this message translates to:
  /// **'Noroeste'**
  String get qiblaDirectionNorthWest;

  /// No description provided for @qiblaDirectionSouth.
  ///
  /// In es, this message translates to:
  /// **'Sur'**
  String get qiblaDirectionSouth;

  /// No description provided for @qiblaDirectionSouthEast.
  ///
  /// In es, this message translates to:
  /// **'Sureste'**
  String get qiblaDirectionSouthEast;

  /// No description provided for @qiblaDirectionSouthWest.
  ///
  /// In es, this message translates to:
  /// **'Suroeste'**
  String get qiblaDirectionSouthWest;

  /// No description provided for @qiblaDirectionSummary.
  ///
  /// In es, this message translates to:
  /// **'Dirección a la Kaaba: {direction}'**
  String qiblaDirectionSummary(Object direction);

  /// No description provided for @qiblaDirectionWest.
  ///
  /// In es, this message translates to:
  /// **'Oeste'**
  String get qiblaDirectionWest;

  /// No description provided for @qiblaDistanceLabel.
  ///
  /// In es, this message translates to:
  /// **'Distancia'**
  String get qiblaDistanceLabel;

  /// No description provided for @qiblaEnableLocationMessage.
  ///
  /// In es, this message translates to:
  /// **'Activa la ubicación para calcular la dirección a la Kaaba.'**
  String get qiblaEnableLocationMessage;

  /// No description provided for @qiblaGpsDisabledMessage.
  ///
  /// In es, this message translates to:
  /// **'Activa el GPS del dispositivo para obtener una dirección fiable.'**
  String get qiblaGpsDisabledMessage;

  /// No description provided for @qiblaGuidanceBody.
  ///
  /// In es, this message translates to:
  /// **'Mantén el dispositivo plano y gira suavemente hasta alinear el indicador.'**
  String get qiblaGuidanceBody;

  /// No description provided for @qiblaHowToUseAvoidMagnetsBody.
  ///
  /// In es, this message translates to:
  /// **'Aléjalo de imanes, fundas metálicas o dispositivos que afecten al sensor.'**
  String get qiblaHowToUseAvoidMagnetsBody;

  /// No description provided for @qiblaHowToUseAvoidMagnetsTitle.
  ///
  /// In es, this message translates to:
  /// **'Evita interferencias'**
  String get qiblaHowToUseAvoidMagnetsTitle;

  /// No description provided for @qiblaHowToUseCalibrateBody.
  ///
  /// In es, this message translates to:
  /// **'Si la brújula falla, mueve el teléfono en forma de ocho para recalibrarlo.'**
  String get qiblaHowToUseCalibrateBody;

  /// No description provided for @qiblaHowToUseCalibrateTitle.
  ///
  /// In es, this message translates to:
  /// **'Calibra si hace falta'**
  String get qiblaHowToUseCalibrateTitle;

  /// No description provided for @qiblaHowToUseKeepFlatBody.
  ///
  /// In es, this message translates to:
  /// **'Mantén el dispositivo plano para mejorar la precisión de la brújula.'**
  String get qiblaHowToUseKeepFlatBody;

  /// No description provided for @qiblaHowToUseKeepFlatTitle.
  ///
  /// In es, this message translates to:
  /// **'Mantén el dispositivo plano'**
  String get qiblaHowToUseKeepFlatTitle;

  /// No description provided for @qiblaHowToUseTitle.
  ///
  /// In es, this message translates to:
  /// **'Cómo usar la brújula'**
  String get qiblaHowToUseTitle;

  /// No description provided for @qiblaLoading.
  ///
  /// In es, this message translates to:
  /// **'Calculando dirección…'**
  String get qiblaLoading;

  /// No description provided for @qiblaPermissionBlockedMessage.
  ///
  /// In es, this message translates to:
  /// **'El permiso de ubicación está bloqueado. Actívalo en los ajustes del sistema.'**
  String get qiblaPermissionBlockedMessage;

  /// No description provided for @qiblaPermissionNeededMessage.
  ///
  /// In es, this message translates to:
  /// **'Necesitamos permiso de ubicación para orientarte hacia la Kaaba.'**
  String get qiblaPermissionNeededMessage;

  /// No description provided for @qiblaPrecisionLabel.
  ///
  /// In es, this message translates to:
  /// **'Precisión'**
  String get qiblaPrecisionLabel;

  /// No description provided for @qiblaSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Dirección a la Kaaba'**
  String get qiblaSubtitle;

  /// No description provided for @qiblaTitle.
  ///
  /// In es, this message translates to:
  /// **'Qibla'**
  String get qiblaTitle;

  /// No description provided for @adhanSelectorHeaderBody.
  ///
  /// In es, this message translates to:
  /// **'Escucha una vista previa corta antes de elegir el adhan que sonará en tus recordatorios.'**
  String get adhanSelectorHeaderBody;

  /// No description provided for @adhanSelectorHeaderTitle.
  ///
  /// In es, this message translates to:
  /// **'Elige tu llamada a la oración'**
  String get adhanSelectorHeaderTitle;

  /// No description provided for @adhanSelectorListenPreview.
  ///
  /// In es, this message translates to:
  /// **'Escuchar vista previa'**
  String get adhanSelectorListenPreview;

  /// No description provided for @adhanSelectorPausePreview.
  ///
  /// In es, this message translates to:
  /// **'Pausar vista previa'**
  String get adhanSelectorPausePreview;

  /// No description provided for @adhanSelectorPreviewError.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido reproducir la vista previa del adhan.'**
  String get adhanSelectorPreviewError;

  /// No description provided for @adhanSelectorPreviewIdle.
  ///
  /// In es, this message translates to:
  /// **'Toca para escuchar una vista previa'**
  String get adhanSelectorPreviewIdle;

  /// No description provided for @adhanSelectorPreviewPaused.
  ///
  /// In es, this message translates to:
  /// **'Vista previa en pausa'**
  String get adhanSelectorPreviewPaused;

  /// No description provided for @adhanSelectorPreviewPlaying.
  ///
  /// In es, this message translates to:
  /// **'Escuchando vista previa'**
  String get adhanSelectorPreviewPlaying;

  /// No description provided for @adhanSelectorResumePreview.
  ///
  /// In es, this message translates to:
  /// **'Reanudar vista previa'**
  String get adhanSelectorResumePreview;

  /// No description provided for @adhanSelectorSelected.
  ///
  /// In es, this message translates to:
  /// **'Has seleccionado {name}'**
  String adhanSelectorSelected(Object name);

  /// No description provided for @adhanSelectorTitle.
  ///
  /// In es, this message translates to:
  /// **'Adhan'**
  String get adhanSelectorTitle;

  /// No description provided for @analyticsAchievementUnlocked.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get analyticsAchievementUnlocked;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
