import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Qibla Time';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonBack => 'Retour';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonEnter => 'Entrer';

  @override
  String get commonAllow => 'Autoriser';

  @override
  String get commonActivate => 'Activer';

  @override
  String get commonEnable => 'Activer';

  @override
  String get commonEnableGps => 'Activer le GPS';

  @override
  String get commonOpenSettings => 'Ouvrir les réglages';

  @override
  String get commonPending => 'En attente';

  @override
  String get commonGranted => 'Accordé';

  @override
  String get commonBlocked => 'Bloqué';

  @override
  String get commonReady => 'Prêt';

  @override
  String get commonDisabled => 'Désactivé';

  @override
  String get commonUnavailable => 'Indisponible';

  @override
  String get commonToday => 'Aujourd\'hui';

  @override
  String get commonYesterday => 'Hier';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get commonShare => 'Partager';

  @override
  String get commonManual => 'Manuel';

  @override
  String get commonImportJson => 'Importer un JSON';

  @override
  String get commonExport => 'Exporter';

  @override
  String get commonOpen => 'Ouvrir';

  @override
  String get commonVersion => 'Version';

  @override
  String get commonAbout => 'À propos';

  @override
  String get commonMethod => 'Méthode';

  @override
  String get commonMadhab => 'Madhab';

  @override
  String get commonLocation => 'Localisation';

  @override
  String get commonNotifications => 'Notifications';

  @override
  String get commonNoData => 'Aucune donnée';

  @override
  String get commonNever => 'Jamais';

  @override
  String get commonGenerating => 'Génération...';

  @override
  String get commonChecking => 'Vérification...';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonSystemStatus => 'État du système';

  @override
  String get commonCurrentStatus => 'État actuel';

  @override
  String get commonOffset => 'Décalage';

  @override
  String get commonAutomatic => 'Automatique';

  @override
  String get commonPrepared => 'Prêt';

  @override
  String get commonActivated => 'Activé';

  @override
  String get commonPaused => 'En pause';

  @override
  String get commonSystem => 'Système';

  @override
  String get onboardingWelcomeTitle => 'Bienvenue sur Qibla Time';

  @override
  String get onboardingWelcomeSubtitle => 'Horaires de prière, Qibla, Coran et rappels dans une application légère pour votre routine quotidienne.';

  @override
  String get onboardingFeatureSchedulesTitle => 'Horaires fiables';

  @override
  String get onboardingFeatureSchedulesBody => 'Calculés selon votre position et la méthode choisie.';

  @override
  String get onboardingFeaturePracticeTitle => 'Qibla et pratique quotidienne';

  @override
  String get onboardingFeaturePracticeBody => 'Boussole, tasbih, suivi et plus encore dans un flux fluide.';

  @override
  String get onboardingFeatureRemindersTitle => 'Rappels utiles';

  @override
  String get onboardingFeatureRemindersBody => 'Notifications d\'adhan et réglages essentiels prêts dès le premier jour.';

  @override
  String get onboardingPermissionsTitle => 'Autorisations importantes';

  @override
  String get onboardingPermissionsSubtitle => 'Nous demandons uniquement ce qui est nécessaire pour calculer les horaires, utiliser la Qibla et vous prévenir à temps.';

  @override
  String get onboardingLocationReadyBody => 'Prêt à calculer les horaires et la Qibla.';

  @override
  String get onboardingLocationBlockedBody => 'L’accès à la localisation est bloqué. Vous pourrez l’activer plus tard dans les réglages du système.';

  @override
  String get onboardingLocationGpsOffBody => 'Le GPS de votre appareil est désactivé. Vous pouvez continuer et l\'activer plus tard.';

  @override
  String get onboardingLocationPendingBody => 'Nécessaire pour des horaires précis et la direction vers La Mecque.';

  @override
  String get onboardingNotificationsReadyBody => 'Prêtes à vous rappeler chaque prière.';

  @override
  String get onboardingNotificationsPendingBody => 'Cela vous permettra de recevoir plus tard les alertes d\'adhan et d\'autres rappels.';

  @override
  String get onboardingMethodTitle => 'Méthode de calcul';

  @override
  String get onboardingMethodSubtitle => 'Vous pourrez la modifier plus tard, mais cela permet de configurer correctement vos horaires dès aujourd’hui.';

  @override
  String get onboardingSelectedNow => 'Sélectionné maintenant';

  @override
  String get onboardingTapToChooseMethod => 'Touchez pour choisir cette méthode';

  @override
  String get onboardingMadhabTitle => 'Madhab pour Asr';

  @override
  String get onboardingMadhabSubtitle => 'Cela n\'affecte que le calcul de Asr. Si vous avez un doute, gardez Shafi et changez-le plus tard.';

  @override
  String get onboardingMadhabCommonTitle => 'Shafi / Maliki / Hanbali';

  @override
  String get onboardingMadhabCommonSubtitle => 'L\'option la plus courante pour commencer';

  @override
  String get onboardingMadhabHanafiTitle => 'Hanafi';

  @override
  String get onboardingMadhabHanafiSubtitle => 'Utiliser le calcul hanafite pour Asr';

  @override
  String get onboardingAdhanTitle => 'Adhan et alertes';

  @override
  String get onboardingAdhanSubtitle => 'Qibla Time peut vous avertir pour chaque prière avec un adhan doux par défaut. Vous pourrez le changer plus tard.';

  @override
  String get onboardingPrayerNotificationsTitle => 'Notifications de prière';

  @override
  String get onboardingPrayerNotificationsSubtitle => 'Vous pouvez les activer maintenant ou continuer sans elles pour le moment.';

  @override
  String get onboardingAdhanPreviewTitle => 'Aperçu rapide de l\'adhan';

  @override
  String get onboardingAdhanPreviewSubtitle => 'Le son sélectionné sera utilisé. Vous pourrez le changer plus tard dans Réglages.';

  @override
  String get onboardingAdhanStopPreview => 'Arrêter l\'aperçu';

  @override
  String get onboardingAdhanListenPreview => 'Écouter l\'aperçu';

  @override
  String get onboardingDoneTitle => 'Tout est prêt';

  @override
  String get onboardingDoneSubtitle => 'Vous pouvez maintenant commencer avec vos horaires, votre Qibla et votre suivi quotidien. Tout pourra être ajusté plus tard.';

  @override
  String get onboardingSummaryLocationBlocked => 'Bloqué pour le moment';

  @override
  String get onboardingSummaryNotificationsPrepared => 'Prêtes';

  @override
  String get methodMuslimWorldLeague => 'Ligue musulmane mondiale';

  @override
  String get methodNorthAmerica => 'ISNA / Amérique du Nord';

  @override
  String get methodUmmAlQura => 'Umm al-Qura';

  @override
  String get methodEgyptian => 'Autorité égyptienne';

  @override
  String get homeHeaderOnline => 'En ligne';

  @override
  String get homeHeaderOffline => 'Hors ligne';

  @override
  String get homeHeaderLocationUnavailable => 'Localisation indisponible';

  @override
  String homeHeaderStatusLine(Object networkStatus, Object location) {
    return '$networkStatus · $location';
  }

  @override
  String get homeHeroNextPrayer => 'PROCHAINE PRIÈRE';

  @override
  String get homeHeroTodayOverview => 'Vue principale d\'aujourd\'hui';

  @override
  String get homeHeroUsingSavedLocation => 'Utilisation de votre dernière localisation enregistrée';

  @override
  String get homeSelectedDateToday => 'AUJOURD\'HUI';

  @override
  String get homeSelectedDateCustom => 'DATE SÉLECTIONNÉE';

  @override
  String get homeCountdownUnavailable => 'Compte à rebours indisponible';

  @override
  String get homeCountdownActive => 'Compte à rebours actif';

  @override
  String homeCountdownUntil(Object prayer) {
    return 'jusqu’à $prayer';
  }

  @override
  String get homeCountdownLabelUppercase => 'COMPTE À REBOURS';

  @override
  String homeDurationUntil(int hours, int minutes) {
    return 'dans $hours h $minutes min';
  }

  @override
  String homeDurationHoursMinutes(int hours, String minutes) {
    return '$hours h $minutes min';
  }

  @override
  String homeDurationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String homeDurationSeconds(String seconds) {
    return '$seconds s';
  }

  @override
  String get homePrayerSectionToday => 'Prières d\'aujourd\'hui';

  @override
  String homePrayerSectionForDate(Object date) {
    return 'Horaires du $date';
  }

  @override
  String homePrayerSectionWorshipDay(Object weekday) {
    return '$weekday, jour d\'adoration';
  }

  @override
  String homePrayerSectionMarkedCount(int count) {
    return '$count/5 marquées';
  }

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsTitleArabic => 'الإعدادات';

  @override
  String get settingsSectionAppearance => 'Apparence';

  @override
  String get settingsSectionAccessibility => 'Accessibilité';

  @override
  String get settingsSectionAdhanNotifications => 'Notifications d\'adhan';

  @override
  String get settingsSectionScheduleCalculation => 'Calcul des horaires';

  @override
  String get settingsSectionRamadanMode => 'Mode Ramadan';

  @override
  String get settingsSectionHadith => 'Hadiths';

  @override
  String get settingsSectionTravelerMode => 'Mode voyageur';

  @override
  String get settingsSectionRecentPlaces => 'LIEUX RÉCENTS';

  @override
  String get settingsSectionSmartCache => 'Cache intelligent';

  @override
  String get settingsSectionSupport => 'Sadaqah · Soutien';

  @override
  String get settingsSectionCloudBackup => 'Sauvegarde cloud (bêta)';

  @override
  String get settingsTextSize => 'Taille du texte';

  @override
  String settingsCurrentScale(Object scale) {
    return 'Échelle actuelle : ${scale}x';
  }

  @override
  String get settingsHighContrast => 'Contraste élevé';

  @override
  String get settingsHighContrastSubtitle => 'Améliore la lisibilité dans toute l\'application';

  @override
  String get settingsUseSystemBold => 'Utiliser le texte gras du système';

  @override
  String get settingsUseSystemBoldSubtitle => 'Respecte la préférence VoiceOver/TalkBack';

  @override
  String get settingsResetAccessibility => 'Réinitialiser l\'accessibilité';

  @override
  String get settingsReset => 'Réinitialiser';

  @override
  String get settingsThemeDarkTitle => 'Sombre';

  @override
  String get settingsThemeDarkSubtitle => 'Ciel avant le Fajr';

  @override
  String get settingsThemeLightTitle => 'Clair';

  @override
  String get settingsThemeLightSubtitle => 'Pour l\'usage en extérieur';

  @override
  String get settingsThemeAmoledTitle => 'AMOLED';

  @override
  String get settingsThemeAmoledSubtitle => 'Noir pur, économise la batterie';

  @override
  String get settingsThemeDeuteranopiaTitle => 'Deuteranopia';

  @override
  String get settingsThemeDeuteranopiaSubtitle => 'Sans rouge/vert';

  @override
  String get settingsThemeMonochromeTitle => 'Monochrome';

  @override
  String get settingsThemeMonochromeSubtitle => 'Pour l\'achromatopsie et la basse vision';

  @override
  String get settingsLanguage => 'Langue de l\'application';

  @override
  String get settingsLanguageSubtitle => 'Choisissez si l\'application doit suivre la langue de votre appareil ou utiliser une langue fixe partout.';

  @override
  String get settingsLanguageDialogTitle => 'Langue de l\'application';

  @override
  String get settingsLanguageOptionSystem => 'Suivre la langue de l\'appareil';

  @override
  String settingsLanguageSystemValue(Object language) {
    return 'Automatique ($language)';
  }

  @override
  String get settingsLanguageOptionSpanish => 'Espagnol';

  @override
  String get settingsLanguageOptionEnglish => 'English';

  @override
  String get settingsLanguageOptionFrench => 'Français';

  @override
  String get settingsLanguageOptionGerman => 'Allemand';

  @override
  String get settingsLanguageOptionArabic => 'العربية';

  @override
  String get settingsAdhanSound => 'Son de l\'adhan';

  @override
  String get settingsAdhanSoundAction => 'Choisir et prévisualiser';

  @override
  String get settingsGeneralNotifications => 'Notifications générales';

  @override
  String get settingsGeneralNotificationsSubtitle => 'Activer ou mettre en pause toutes les alertes de prière';

  @override
  String get settingsSystemPermissionPendingBody => 'Les alertes d\'adhan sont configurées, mais l\'autorisation du système est encore en attente.';

  @override
  String get settingsHapticFeedback => 'Retour haptique';

  @override
  String get settingsRamadanAutomatic => 'Mode Ramadan automatique';

  @override
  String get settingsRamadanAutomaticSubtitle => 'S\'active automatiquement lorsque le calendrier islamique entre en Ramadan';

  @override
  String get settingsRamadanForced => 'Forcer le mode Ramadan';

  @override
  String get settingsRamadanForcedSubtitle => 'Activer manuellement la vue Ramadan';

  @override
  String get settingsDailyNotification => 'Notification quotidienne';

  @override
  String get settingsDailyNotificationSubtitle => 'Recevoir chaque jour un hadith ou un verset';

  @override
  String get settingsNotificationHour => 'Heure de notification';

  @override
  String get settingsTravelerMode => 'Mode voyageur';

  @override
  String get settingsTravelerModeSubtitle => 'Détecte automatiquement les changements de ville (>50 km)';

  @override
  String get settingsTravelerModeLoadError => 'Nous n\'avons pas pu charger le mode voyageur';

  @override
  String get settingsRecentPlaces => 'Lieux récents';

  @override
  String get settingsNoRecentTrips => 'Aucun voyage récent';

  @override
  String get settingsLoadError => 'Nous n\'avons pas pu le charger';

  @override
  String get settingsCacheValidUntil => 'Cache valide jusqu\'au';

  @override
  String get settingsCacheEntries => 'Entrées en cache';

  @override
  String get settingsClearCache => 'Vider le cache';

  @override
  String get settingsSupportInfo => 'Informations de soutien';

  @override
  String get settingsSupportCardTitle => 'Soutenir le développement';

  @override
  String get settingsSupportCardSubtitle => 'Chaque don peut devenir une sadaqah jariyah';

  @override
  String get settingsBackupMode => 'Mode de sauvegarde';

  @override
  String get settingsAnonymousId => 'ID anonyme';

  @override
  String get settingsLastBackup => 'Dernière sauvegarde';

  @override
  String get settingsExportBackup => 'Exporter la sauvegarde';

  @override
  String get settingsRestoreBackup => 'Restaurer la sauvegarde';

  @override
  String get settingsBackupInfoBody => 'Vous pouvez enregistrer et partager une sauvegarde manuelle au format JSON. L\'automatisation et la synchronisation entre appareils ne sont pas encore disponibles.';

  @override
  String get settingsRestoreBackupDialogTitle => 'Restaurer la sauvegarde';

  @override
  String get settingsRestoreBackupSuccess => 'Sauvegarde restaurée';

  @override
  String get settingsRestoreBackupError => 'Nous n\'avons pas pu restaurer la sauvegarde.';

  @override
  String get settingsDailyNotificationEnabled => 'Notification quotidienne activée';

  @override
  String get settingsDailyNotificationDisabled => 'Notification quotidienne désactivée';

  @override
  String get settingsSelectHourTitle => 'Sélectionner l\'heure';

  @override
  String get settingsToday => 'Aujourd\'hui';

  @override
  String get settingsYesterday => 'Hier';

  @override
  String settingsDaysAgo(int count) {
    return 'Il y a $count jours';
  }

  @override
  String get settingsRamadanManualActive => 'Actif manuellement';

  @override
  String get settingsLocationBlocked => 'Bloqué';

  @override
  String get settingsLocationPendingPermission => 'Autorisation en attente';

  @override
  String get settingsLocationAutomatic => 'Automatique';

  @override
  String get settingsLocationSavedUnavailable => 'Aucune localisation enregistrée';

  @override
  String get settingsLocationStatus => 'État de la localisation';

  @override
  String get settingsGpsOff => 'GPS désactivé';

  @override
  String get settingsScheduleSource => 'Source des horaires';

  @override
  String get settingsScheduleSourceReady => 'Cache prêt';

  @override
  String get settingsNotificationSystem => 'Notif. système';

  @override
  String get settingsNotificationApp => 'Notif. app';

  @override
  String get settingsNotificationsGranted => 'Accordées';

  @override
  String get commonPlay => 'Lire';

  @override
  String get commonText => 'Texte';

  @override
  String get commonVideo => 'Vidéo';

  @override
  String get commonRemove => 'Retirer';

  @override
  String get shareBranding => 'App : Qibla Time';

  @override
  String shareReferenceLabel(Object reference) {
    return 'Référence : $reference';
  }

  @override
  String get shareSubjectDua => 'Dua';

  @override
  String get shareSubjectHadithOfDay => 'Hadith du jour - Qibla Time';

  @override
  String get shareSubjectHadithShared => 'Hadith partagé depuis Qibla Time';

  @override
  String get shareBadgeHadith => 'HADITH';

  @override
  String get shareBadgeDua => 'DUA';

  @override
  String get shareBadgeQuran => 'CORAN';

  @override
  String get shareSectionStyle => 'Style / fond';

  @override
  String get shareSectionContent => 'Contenu';

  @override
  String get shareLayoutCard => 'Carte';

  @override
  String get shareLayoutStory => 'Story';

  @override
  String get shareContentBilingual => 'Arabe + traduction';

  @override
  String get shareContentArabicOnly => 'Arabe uniquement';

  @override
  String get shareContentTranslationOnly => 'Traduction uniquement';

  @override
  String get shareActionShareImage => 'Partager l\'image';

  @override
  String get shareActionShareText => 'Partager le texte';

  @override
  String get shareHadithTitle => 'Partager le hadith';

  @override
  String get shareHadithSubtitle => 'Choisissez le format et le contenu avant de partager.';

  @override
  String get shareHadithTextError => 'Nous n\'avons pas pu partager le texte du hadith.';

  @override
  String get shareHadithImageError => 'Nous n\'avons pas pu générer l\'image du hadith.';

  @override
  String get shareDuaTitle => 'Partager la doua';

  @override
  String shareDuaTitleNamed(Object title) {
    return 'Partager $title';
  }

  @override
  String get shareDuaSubtitle => 'Utilisez le même traitement visuel que pour le hadith pour la doua et les adhkar.';

  @override
  String get shareDuaTextError => 'Nous n\'avons pas pu partager le texte de la doua.';

  @override
  String get shareDuaImageError => 'Nous n\'avons pas pu générer l\'image de la doua.';

  @override
  String shareAyahTitle(int number) {
    return 'Partager le verset $number';
  }

  @override
  String get shareAyahSubtitle => 'Conservez la même présentation visuelle pour le texte, l’image et la vidéo.';

  @override
  String get shareAyahTextError => 'Nous n\'avons pas pu partager ce verset en texte.';

  @override
  String get shareAyahImageError => 'Nous n\'avons pas pu générer l\'image de ce verset.';

  @override
  String get shareAyahVideoNoAudio => 'Aucun audio n\'est disponible pour générer une vidéo de ce verset.';

  @override
  String get shareAyahVideoGenerating => 'Génération de la vidéo du verset...';

  @override
  String get shareAyahVideoError => 'Nous n\'avons pas pu générer la vidéo de ce verset.';

  @override
  String get notificationAdhanChannelName => 'Adhan';

  @override
  String get notificationAdhanChannelDescription => 'Notifications des horaires de prière';

  @override
  String notificationAdhanTitle(Object prayerName) {
    return 'Qibla Time - $prayerName';
  }

  @override
  String get notificationAdhanBody => 'C\'est l\'heure de la prière';

  @override
  String get notificationReminderChannelName => 'Qibla Time - Rappels';

  @override
  String get notificationReminderChannelDescription => 'Rappels contextuels pour le Ramadan et la Jumu’ah';

  @override
  String get notificationDailyReflectionChannelName => 'Réflexion quotidienne';

  @override
  String get notificationDailyReflectionChannelDescription => 'Verset du Coran et hadith du jour';

  @override
  String get notificationDailyReflectionTitle => 'Réflexion du jour';

  @override
  String get notificationDailyReflectionFallbackBody => 'Votre réflexion spirituelle quotidienne dans Qibla Time.';

  @override
  String get notificationDailyReflectionErrorTitle => 'Qibla Time · Réflexion quotidienne';

  @override
  String get notificationDailyReflectionErrorBody => 'Votre rappel spirituel d\'aujourd\'hui';

  @override
  String get notificationHadithReminderChannelName => 'Rappels de hadith';

  @override
  String get notificationHadithReminderChannelDescription => 'Rappels horaires de hadith';

  @override
  String get notificationHadithReminderFallbackBody => 'Rappel : lisez un hadith du Prophète.';

  @override
  String get notificationHadithReminderTitle => 'Hadith du moment';

  @override
  String get notificationHadithReminderTestBody => 'Test de rappel de hadith';

  @override
  String get notificationHadithReminderTestTitle => 'Rappel de hadith';

  @override
  String get notificationWeeklySummaryTitle => 'Votre résumé hebdomadaire est prêt';

  @override
  String notificationWeeklySummaryBody(int prayersCompleted, int maxPossible, Object strongestDay) {
    return 'Cette semaine, vous avez accompli $prayersCompleted/$maxPossible prières. Votre meilleur jour a été $strongestDay.';
  }

  @override
  String get quranDailyVerseFallbackTranslation => 'Allah : il n\'y a de divinité digne d\'adoration que Lui, le Vivant, Celui qui subsiste par Lui-même. Ni somnolence ni sommeil ne Le saisissent.';

  @override
  String get quranDailyVerseFallbackTransliteration => 'Allahu la ilaha illa huwal hayyul qayyum...';

  @override
  String get quranDailyVerseFallbackReference => 'Al-Baqara [2:255]';

  @override
  String get quranTitle => 'Coran';

  @override
  String get quranSubtitle => '114 sourates à lecture continue';

  @override
  String get quranHafizLabel => 'Hafiz';

  @override
  String get quranUtilityAyatAlKursi => 'Ayat al-Kursi';

  @override
  String get quranUtilityAllahNames => '99 noms';

  @override
  String get quranUtilityDownloaded => 'Téléchargées';

  @override
  String get quranProtectionTitle => 'PROTECTION QUOTIDIENNE';

  @override
  String get quranProtectionSubtitle => 'Accès rapide à Ayat al-Kursi et aux sourates de protection. Ouvrez-les pour lire ou écouter, puis marquez vos trois répétitions.';

  @override
  String get quranProtectionAyatAlKursiHelper => 'Al-Baqara 2:255';

  @override
  String quranProtectionSurahHelper(int number) {
    return 'Sourate $number';
  }

  @override
  String get quranProtectionIkhlasTitle => 'Al-Ikhlas';

  @override
  String get quranProtectionFalaqTitle => 'Al-Falaq';

  @override
  String get quranProtectionNasTitle => 'An-Nas';

  @override
  String quranProtectionRepeatCount(Object helper, int count) {
    return '$helper · $count/3 répétitions';
  }

  @override
  String get quranProtectionCompleteTooltip => 'Terminé';

  @override
  String get quranProtectionIncrementTooltip => '+1 répétition';

  @override
  String get quranReadingHintTitle => 'LECTURE CONTINUE';

  @override
  String get quranReadingHintBody => 'Ouvrez n’importe quelle sourate et nous enregistrerons votre dernier verset pour que vous puissiez reprendre plus tard.';

  @override
  String get quranReadingHintSecondary => 'Vous pourrez aussi enregistrer des marque-pages en touchant l’icône de signet pendant la lecture.';

  @override
  String get quranContinueReadingTitle => 'REPRENDRE LA LECTURE';

  @override
  String get quranBookmarksTitle => 'MARQUE-PAGES';

  @override
  String get quranRevelationMecca => 'La Mecque';

  @override
  String get quranRevelationMedina => 'Médine';

  @override
  String quranAyahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versets',
      one: '1 verset',
    );
    return '$_temp0';
  }

  @override
  String quranLastReadingAyah(int ayah) {
    return 'Dernière lecture : verset $ayah';
  }

  @override
  String quranBookmarkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count marque-pages enregistrès',
      one: '1 marque-page enregistré',
    );
    return '$_temp0';
  }

  @override
  String get quranDownloadedFavoriteOffline => 'Audio téléchargé · favori hors ligne';

  @override
  String get quranDownloadedAudio => 'Audio téléchargé';

  @override
  String quranReadingPointSaved(int ayah) {
    return 'Point de lecture enregistré au verset $ayah';
  }

  @override
  String quranBookmarkSaved(int ayah) {
    return 'Marque-page enregistré au verset $ayah';
  }

  @override
  String quranBookmarkRemoved(int ayah) {
    return 'Marque-page supprimé du verset $ayah';
  }

  @override
  String quranShareAyahTitle(int ayah) {
    return 'Partager le verset $ayah';
  }

  @override
  String get quranShareTextSubtitle => 'Inclut le texte arabe, la traduction et la référence.';

  @override
  String get quranShareImageSubtitle => 'Créer une image avec le verset.';

  @override
  String get quranShareVideoSubtitle => 'Créer une vidéo avec la carte et la récitation.';

  @override
  String get quranAyahImageError => 'Nous n\'avons pas pu générer l\'image de ce verset.';

  @override
  String get quranAyahVideoNoAudio => 'Ce verset n\'a pas d\'audio disponible pour générer une vidéo.';

  @override
  String get quranAyahVideoGenerating => 'Nous générons la vidéo du verset...';

  @override
  String quranAyahVideoShareText(int ayah, Object surah) {
    return 'Verset $ayah de $surah';
  }

  @override
  String get quranAyahVideoError => 'Nous n\'avons pas pu générer la vidéo de ce verset.';

  @override
  String get quranDownloadCheckError => 'Nous n\'avons pas pu vérifier le téléchargement sur cet appareil.';

  @override
  String get quranDownloadSuccess => 'Audio téléchargé. Vous pouvez maintenant Écouter cette sourate hors ligne.';

  @override
  String get quranDownloadDetailedError => 'Nous n\'avons pas pu terminer le téléchargement. Vérifiez votre connexion et réessayez.';

  @override
  String get quranDownloadShortError => 'Nous n\'avons pas pu terminer le téléchargement audio.';

  @override
  String get quranDownloadedAudioPlaySubtitle => 'Écouter la sourate avec l’audio enregistré.';

  @override
  String get quranDownloadedAudioRemoveSubtitle => 'Libérer de l’espace et la réécouter en ligne.';

  @override
  String get quranDownloadedAudioRemoved => 'Le téléchargement de cette sourate a été supprimé.';

  @override
  String get quranDownloadedFavoriteAdded => 'Sourate enregistrée parmi vos favoris téléchargés.';

  @override
  String get quranDownloadedFavoriteRemoved => 'Sourate retirée de vos favoris téléchargés.';

  @override
  String get quranAyahAudioUnavailable => 'Aucun audio n’est disponible pour ce verset.';

  @override
  String get quranAyahAudioDownloaded => 'L’audio est déjà téléchargé sur cet appareil.';

  @override
  String get quranAyahAudioAvailable => 'Vous pouvez Écouter ce verset.';

  @override
  String get quranAyahAudioRequiresConnection => 'Vous pouvez Écouter ce verset si vous avez une connexion.';

  @override
  String get quranSurahRecitationUnavailable => 'La récitation complète n’est pas disponible pour cette sourate.';

  @override
  String quranSurahAudioDownloading(int downloaded, int total) {
    return 'Nous téléchargeons l’audio afin que vous puissiez Écouter cette sourate hors ligne. $downloaded/$total versets prêts.';
  }

  @override
  String get quranSurahAudioDownloaded => 'L’audio est déjà téléchargé sur cet appareil. Vous pouvez Écouter cette sourate hors ligne.';

  @override
  String quranSurahAudioMissingAyahs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versets sans audio seront ignorés.',
      one: '1 verset sans audio sera ignoré.',
    );
    return '$_temp0';
  }

  @override
  String quranSurahAudioPartialDownload(int downloaded, int total) {
    return 'Vous avez déjà $downloaded/$total versets enregistrès sur cet appareil.';
  }

  @override
  String get quranSurahAudioDownloadAvailable => 'Vous pouvez aussi le télécharger pour Écouter hors ligne.';

  @override
  String get quranSurahAudioPlayOnline => 'Vous pouvez Écouter cette sourate en lecture continue.';

  @override
  String get quranSurahAudioPlayWithConnection => 'Vous pouvez Écouter cette sourate entière si vous avez une connexion.';

  @override
  String get quranAyahPlaybackError => 'Nous n\'avons pas pu lire l\'audio. Vérifiez votre connexion et réessayez.';

  @override
  String get quranSurahPlaybackError => 'Nous n\'avons pas pu lancer la récitation complète.';

  @override
  String get quranLastReadingBadge => 'Dernière lecture';

  @override
  String get quranPauseAudio => 'Mettre l\'audio en pause';

  @override
  String get quranResumeAudio => 'Reprendre l\'audio';

  @override
  String get quranPlayAudio => 'Lire l\'audio';

  @override
  String get quranAudioUnavailable => 'Audio indisponible';

  @override
  String get quranRemoveBookmark => 'Retirer le marque-page';

  @override
  String get quranSaveBookmark => 'Enregistrer le marque-page';

  @override
  String quranAyahFooterHint(Object status) {
    return '$status Touchez ce verset pour enregistrer ici votre point de lecture. Appui long pour le partager.';
  }

  @override
  String get quranDetailLoadError => 'Nous n\'avons pas pu charger cette sourate. Vérifiez votre connexion et réessayez.';

  @override
  String quranTopBannerResume(int ayah) {
    return 'Reprise au verset $ayah.';
  }

  @override
  String get quranTopBannerOnline => 'Contenu chargé en ligne. Vous pouvez Écouter l’audio de chaque verset tant que vous avez une connexion.';

  @override
  String get quranTopBannerOffline => 'Texte chargé hors ligne. L’audio de certains versets peut encore nécessiter une connexion.';

  @override
  String get quranTopBannerPlaceholder => 'Contenu partiel chargé hors ligne. L’audio n’est pas disponible pour le moment.';

  @override
  String get quranSurahAudioCardTitle => 'ÉCOUTER LA SOURATE';

  @override
  String quranAvailableAyahs(int available, int total) {
    return '$available/$total versets';
  }

  @override
  String get quranPauseSurah => 'Mettre la sourate en pause';

  @override
  String get quranResumeSurah => 'Reprendre la sourate';

  @override
  String get quranListenSurah => 'Écouter la sourate';

  @override
  String get quranStop => 'Arrêter';

  @override
  String get quranCheckingAudio => 'Vérification de l’audio';

  @override
  String quranDownloadingProgress(int downloaded, int total) {
    return 'Téléchargement $downloaded/$total';
  }

  @override
  String get quranDownloaded => 'Téléchargé';

  @override
  String get quranDownloadAudio => 'Télécharger l\'audio';

  @override
  String get quranDownloadedFavoriteLabel => 'Favori téléchargé';

  @override
  String get quranMarkFavorite => 'Marquer comme favori';

  @override
  String quranPlayingSurahAyah(int ayah) {
    return 'Lecture de la sourate · verset $ayah';
  }

  @override
  String quranPausedSurahAyah(int ayah) {
    return 'Sourate en pause · verset $ayah';
  }

  @override
  String quranPlayingAyah(int ayah) {
    return 'Lecture du verset $ayah';
  }

  @override
  String quranPausedAyah(int ayah) {
    return 'Verset $ayah en pause';
  }

  @override
  String get quranActiveAudioSurahHint => 'La sourate continuera automatiquement avec le verset suivant.';

  @override
  String get quranActiveAudioAyahHint => 'Vous pouvez mettre en pause, reprendre ou arrêter cette récitation.';

  @override
  String get quranStopAudio => 'Arrêter l\'audio';

  @override
  String get commonAuthenticity => 'Authenticité';

  @override
  String get commonBooks => 'Livres';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonCategory => 'Catégorie';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonCollection => 'Collection';

  @override
  String get commonCopy => 'Copier';

  @override
  String get commonDone => 'Terminé';

  @override
  String get commonDownload => 'Télécharger';

  @override
  String get commonFeatured => 'À la une';

  @override
  String get commonFilter => 'Filtrer';

  @override
  String get commonGeneral => 'Général';

  @override
  String get commonHadiths => 'Hadiths';

  @override
  String get commonInformation => 'Informations';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonOther => 'Autre';

  @override
  String get commonPause => 'Pause';

  @override
  String get commonPrayers => 'prières';

  @override
  String get commonQuran => 'Coran';

  @override
  String get commonRead => 'Lire';

  @override
  String get commonReference => 'Référence';

  @override
  String get commonResume => 'Reprendre';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonSaved => 'Enregistré';

  @override
  String get commonStatistics => 'Statistiques';

  @override
  String get commonTotal => 'Total';

  @override
  String get achievementFirstPrayerTitle => 'Première prière';

  @override
  String get achievementFirstPrayerDescription => 'Vous avez marqué votre première prière dans l’application.';

  @override
  String get achievementFullDayTitle => 'Journée complète';

  @override
  String get achievementFullDayDescription => 'Vous avez accompli les cinq prières en une seule journée.';

  @override
  String get achievementStreak3Title => 'Série de 3 jours';

  @override
  String get achievementStreak3Description => 'Vous avez gardé votre régularité pendant trois jours d’affilée.';

  @override
  String get achievementStreak7Title => 'Série de 7 jours';

  @override
  String get achievementStreak7Description => 'Sept jours de suivi sans interruption. Très beau rythme.';

  @override
  String get achievementStreak30Title => 'Série de 30 jours';

  @override
  String get achievementStreak30Description => 'Trente jours d’affilée. Une constance extraordinaire.';

  @override
  String get achievementTotal100Title => '100 prières';

  @override
  String get achievementTotal100Description => 'Vous avez enregistré 100 prières accomplies.';

  @override
  String get achievementFirstRamadanTitle => 'Premier Ramadan';

  @override
  String get achievementFirstRamadanDescription => 'Vous avez terminé votre première journée active de Ramadan.';

  @override
  String get analyticsAchievementsTitle => 'Succès';

  @override
  String get analyticsAchievementsEmpty => 'Aucun succès débloqué pour le moment.';

  @override
  String get analyticsAchievementsLoadError => 'Nous n\'avons pas pu charger vos succès.';

  @override
  String get analyticsBestDayLabel => 'Meilleur jour';

  @override
  String analyticsBestStreakHint(Object count) {
    return 'Votre meilleure série : $count jours';
  }

  @override
  String get analyticsBestStreakLabel => 'Meilleure série';

  @override
  String get analyticsByPrayerTitle => 'Par prière';

  @override
  String get analyticsCollectionsLabel => 'Collections';

  @override
  String get analyticsCompletedPrayersLabel => 'Prières accomplies';

  @override
  String get analyticsCurrentStreakLabel => 'Série actuelle';

  @override
  String analyticsDaysValue(Object count) {
    return '$count jours';
  }

  @override
  String get analyticsEmptyBody => 'Commencez à marquer vos prières et vous verrez ici votre régularité.';

  @override
  String get analyticsEmptyHint => 'Accomplissez votre première prière pour débloquer ce panneau.';

  @override
  String get analyticsEmptyTitle => 'Pas encore de statistiques';

  @override
  String get analyticsFavoritesLabel => 'Favoris';

  @override
  String get analyticsFullDaysLabel => 'Jours complets';

  @override
  String get analyticsGradesLabel => 'Grades';

  @override
  String get analyticsHadithStatsLoadError => 'Impossible de charger les statistiques des hadiths.';

  @override
  String get analyticsLast30DaysTitle => '30 derniers jours';

  @override
  String get analyticsLessLabel => 'Moins';

  @override
  String get analyticsMoreLabel => 'Plus';

  @override
  String get analyticsNoActiveStreak => 'Aucune série active';

  @override
  String get analyticsRecordBadge => 'Record';

  @override
  String get analyticsSavedFavoritesLabel => 'Favoris enregistrès';

  @override
  String get analyticsShareError => 'Nous n\'avons pas pu partager votre progression.';

  @override
  String get analyticsShareImage => 'Partager l\'image';

  @override
  String get analyticsShareProgressTooltip => 'Partager la progression';

  @override
  String get analyticsShareText => 'Partager le texte';

  @override
  String get analyticsStartStreakHint => 'Commencez une nouvelle série aujourd’hui.';

  @override
  String analyticsStreakDays(Object count) {
    return '$count jours de série';
  }

  @override
  String get analyticsThisWeekLabel => 'Cette semaine';

  @override
  String get analyticsWeekInterpretationEmpty => 'Il n\'y a pas encore assez d\'activité cette semaine.';

  @override
  String get analyticsWeekInterpretationEncouragement => 'Continuez petit à petit. Chaque prière compte.';

  @override
  String get analyticsWeekInterpretationGood => 'Vous avancez bien cette semaine. Un peu plus de régularité fera la différence.';

  @override
  String get analyticsWeekInterpretationStrong => 'Très belle semaine. Vous gardez un excellent rythme.';

  @override
  String get analyticsWeeklySummaryTitle => 'Résumé hebdomadaire';

  @override
  String get booksAboutBody => 'Cette bibliothèque rassemble les livres IslamHouse pour une lecture rapide dans l’application.';

  @override
  String get booksAboutBulletCatalog => 'Un catalogue soigné et facile à parcourir';

  @override
  String get booksAboutBulletCategories => 'Des catégories pour trouver plus vite la bonne lecture';

  @override
  String get booksAboutBulletVerified => 'Un contenu provenant d’une bibliothèque islamique reconnue';

  @override
  String get booksAllCategories => 'Toutes les catégories';

  @override
  String get booksCategoriesTab => 'Catégories';

  @override
  String get booksDescription => 'Description';

  @override
  String get booksEmptyCategories => 'Aucune catégorie disponible.';

  @override
  String get booksEmptyFeatured => 'Aucun livre mis en avant pour le moment.';

  @override
  String get booksEmptySearch => 'Nous n\'avons pas trouvé de livres pour cette recherche.';

  @override
  String get booksLibraryTitle => 'Livres';

  @override
  String get booksLoadErrorTitle => 'Nous n\'avons pas pu charger la bibliothèque';

  @override
  String get booksMainCategoryAcademicLessons => 'Leçons académiques';

  @override
  String get booksMainCategoryArabicLanguage => 'Langue arabe';

  @override
  String get booksMainCategoryCallToIslam => 'Appel à l’islam';

  @override
  String get booksMainCategoryHistory => 'Histoire';

  @override
  String get booksMainCategoryIslamicBelief => 'Croyance islamique';

  @override
  String get booksMainCategoryIslamicCulture => 'Culture islamique';

  @override
  String get booksMainCategoryIslamicJurisprudence => 'Jurisprudence islamique';

  @override
  String get booksMainCategoryMajorSins => 'Grands péchés';

  @override
  String get booksMainCategoryNobleQuran => 'Noble Coran';

  @override
  String get booksMainCategoryPresentingIslam => 'Présentation de l’islam';

  @override
  String get booksMainCategoryPropheticBiography => 'Biographie prophétique';

  @override
  String get booksMainCategoryProphetSunnah => 'Sunnah du Prophète';

  @override
  String get booksMainCategorySermons => 'Sermons';

  @override
  String get booksMainCategoryVirtues => 'Vertus';

  @override
  String booksPageCount(Object pages) {
    return '$pages pages';
  }

  @override
  String get booksPlaceholderDescription => 'Les livres apparaîtront bientôt ici.';

  @override
  String get booksPlaceholderTitle => 'Bibliothèque en cours';

  @override
  String get booksSearchHint => 'Rechercher un livre ou un auteur';

  @override
  String get booksUnnamedCategory => 'Catégorie sans nom';

  @override
  String get booksUntitled => 'Sans titre';

  @override
  String get booksVisitIslamHouse => 'Visiter IslamHouse';

  @override
  String get calendarCurrentMonth => 'CE MOIS-CI';

  @override
  String get calendarEventAshura => 'Ashura';

  @override
  String get calendarEventDayOfArafah => 'Jour de Arafah';

  @override
  String get calendarEventEidAdha => 'Aïd al-Adha';

  @override
  String get calendarEventEidFitr => 'Aïd al-Fitr';

  @override
  String get calendarEventIslamicNewYear => 'Nouvel an islamique';

  @override
  String get calendarEventRamadanStart => 'Début du Ramadan';

  @override
  String calendarImportantDatesTitle(Object year) {
    return 'Dates importantes de $year';
  }

  @override
  String get calendarSelectDate => 'Sélectionner une date';

  @override
  String get calendarSelectedDateUppercase => 'DATE SÉLECTIONNÉE';

  @override
  String get calendarTitle => 'Calendrier islamique';

  @override
  String calendarTodayLabel(Object date) {
    return 'Aujourd’hui · $date';
  }

  @override
  String get dhikrChooseCustomValue => 'Choisir une valeur personnalisée';

  @override
  String get dhikrDailyGoalCompletedMessage => 'Vous avez atteint votre objectif quotidien de dhikr.';

  @override
  String get dhikrDailyGoalHelper => 'Choisissez combien de répétitions vous voulez atteindre aujourd’hui.';

  @override
  String get dhikrDailyGoalShort => 'Objectif quotidien';

  @override
  String get dhikrDailyGoalTitle => 'Objectif quotidien';

  @override
  String dhikrDailyGoalUpdated(Object value) {
    return 'Objectif quotidien mis à jour · $value';
  }

  @override
  String get dhikrFeedbackAlmostThere => 'Vous avancez très bien. Vous Êtes proche de votre objectif quotidien.';

  @override
  String get dhikrFeedbackCompleted => 'Objectif quotidien atteint. Qu’Allah accepte votre dhikr.';

  @override
  String get dhikrFeedbackCycleCompleted => 'Cycle terminé. Vous pouvez continuer avec calme.';

  @override
  String get dhikrFeedbackGoodPace => 'Bon rythme. Continuez ces répétitions avec sérénité.';

  @override
  String get dhikrFeedbackStart => 'Commencez par quelques répétitions douces et régulières.';

  @override
  String get dhikrFeedbackTakeYourTime => 'Prenez votre temps. Chaque répétition compte.';

  @override
  String get dhikrGoalsSection => 'OBJECTIFS';

  @override
  String get dhikrHistoryEmptyBody => 'Il n’y a pas encore assez d’historique pour cette vue.';

  @override
  String get dhikrHistorySavedBody => 'Votre progression récente est enregistrée automatiquement.';

  @override
  String get dhikrLast7Days => '7 jours';

  @override
  String get dhikrMeaningAlhamdulillah => 'Louange à Allah';

  @override
  String get dhikrMeaningAllahuAkbar => 'Allah est le Plus Grand';

  @override
  String get dhikrMeaningSubhanAllah => 'Gloire à Allah';

  @override
  String get dhikrRepetitionsFieldHint => 'Exemple : 100';

  @override
  String get dhikrRepetitionsFieldLabel => 'Répétitions';

  @override
  String get dhikrResetSession => 'Réinitialiser la session';

  @override
  String dhikrSessionCountOf(Object count) {
    return 'sur $count';
  }

  @override
  String get dhikrSessionCycleCompleted => 'Vous avez terminé ce cycle de dhikr.';

  @override
  String get dhikrSessionGoalHelper => 'Définissez combien de répétitions vous voulez par cycle.';

  @override
  String get dhikrSessionGoalShort => 'Objectif de session';

  @override
  String get dhikrSessionGoalTitle => 'Objectif de session';

  @override
  String dhikrSessionGoalUpdated(Object value) {
    return 'Objectif de session mis à jour · $value';
  }

  @override
  String get dhikrSessionResetMessage => 'La session a été réinitialisée.';

  @override
  String get dhikrSubtitle => 'Un rappel conscient pour votre journée';

  @override
  String get dhikrSummarySection => 'RÉSUMÉ';

  @override
  String get dhikrTitle => 'Dhikr';

  @override
  String dhikrTodayCycle(Object current, Object today, Object total) {
    return 'Aujourd’hui : $today · cycle $current/$total';
  }

  @override
  String get hadithDailyBadge => 'HADITH DU JOUR';

  @override
  String get hadithDailyOpenLibrary => 'Ouvrir les hadiths';

  @override
  String get hadithDailyUnavailable => 'Nous n\'avons pas pu charger le hadith du jour.';

  @override
  String get hadithDetailArabicText => 'Texte arabe';

  @override
  String get hadithDetailCopied => 'Hadith copié';

  @override
  String get hadithDetailCopyText => 'Copier le texte';

  @override
  String hadithDetailGrade(Object grade) {
    return 'Grade : $grade';
  }

  @override
  String get hadithDetailHideArabic => 'Masquer l\'arabe';

  @override
  String get hadithDetailHideTranslation => 'Masquer la traduction';

  @override
  String hadithDetailId(Object id) {
    return 'ID : $id';
  }

  @override
  String get hadithDetailInfoBody => 'Ce hadith peut varier selon la collection, le grade et la traduction disponible.';

  @override
  String get hadithDetailNoCategory => 'Sans catégorie';

  @override
  String get hadithDetailRemovedFromFavorites => 'Hadith retiré des favoris';

  @override
  String get hadithDetailSavedToFavorites => 'Hadith enregistré dans les favoris';

  @override
  String get hadithDetailShowArabic => 'Afficher l\'arabe';

  @override
  String get hadithDetailShowTranslation => 'Afficher la traduction';

  @override
  String get hadithDetailTitle => 'Détail du hadith';

  @override
  String get hadithDetailTranslation => 'Traduction';

  @override
  String get hadithLibraryAllCollections => 'Toutes les collections';

  @override
  String get hadithLibraryAllGrades => 'Tous les grades';

  @override
  String get hadithLibraryAllCategories => 'Toutes les catégories';

  @override
  String hadithLibraryAllHadiths(Object count) {
    return '$count hadiths';
  }

  @override
  String get hadithLibraryEmptyBody => 'Aucun hadith n’est disponible pour le moment.';

  @override
  String get hadithLibraryEmptySearchBody => 'Essayez une autre recherche ou retirez les filtres.';

  @override
  String hadithLibraryEmptySearchTitle(Object query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get hadithLibraryEmptyTitle => 'Aucun hadith disponible';

  @override
  String get hadithLibraryFiltersError => 'Nous n\'avons pas pu charger les filtres.';

  @override
  String get hadithLibraryFiltersLoading => 'Chargement des filtres...';

  @override
  String hadithLibraryLoadError(Object error) {
    return 'Nous n\'avons pas pu charger les hadiths.\n$error';
  }

  @override
  String hadithLibraryResultsCount(Object count) {
    return '$count résultats';
  }

  @override
  String get hadithLibrarySearchHint => 'Rechercher un hadith ou une référence';

  @override
  String get hadithLibraryTitle => 'Hadiths';

  @override
  String hadithOfflineAvailability(Object progress) {
    return '$progress disponible hors ligne';
  }

  @override
  String get hadithOfflineAvailable => 'Disponible';

  @override
  String get hadithOfflineCollectionsTitle => 'Collections incluses';

  @override
  String get hadithOfflineIncludedSubtitle => 'Tout le contenu est intégré à l’application';

  @override
  String get hadithOfflineIncludedTitle => 'Hors ligne dès le départ';

  @override
  String get hadithOfflineInfoBody => 'Les hadiths affichés ici sont déjà disponibles sans téléchargement supplémentaire.';

  @override
  String get hadithOfflineTitle => 'Hadiths hors ligne';

  @override
  String get hafizActivePlans => 'Plans actifs';

  @override
  String hafizAyahRange(Object end, Object start) {
    return 'Versets $start-$end';
  }

  @override
  String get hafizConfigureSession => 'Configurer la session';

  @override
  String get hafizEmptyBody => 'Vous n’avez encore créé aucun plan de mémorisation.';

  @override
  String get hafizEmptyHint => 'Choisissez une sourate et définissez un court passage pour commencer.';

  @override
  String get hafizEmptyTitle => 'Commencez votre révision';

  @override
  String hafizEndAyah(Object ayah) {
    return 'Verset final : $ayah';
  }

  @override
  String get hafizLoadError => 'Nous n\'avons pas pu charger cette sourate.';

  @override
  String get hafizLogRepetition => 'Enregistrer une répétition';

  @override
  String get hafizPlanSaved => 'Plan enregistré';

  @override
  String get hafizRepetitionLogged => 'Répétition enregistrée';

  @override
  String get hafizReviewedSurahs => 'Sourates révisées';

  @override
  String get hafizSavePlan => 'Enregistrer le plan';

  @override
  String get hafizSelectedSegment => 'Passage sélectionné';

  @override
  String hafizStartAyah(Object ayah) {
    return 'Verset initial : $ayah';
  }

  @override
  String get hafizSubtitle => 'Organisez des révisions courtes et constantes';

  @override
  String hafizSurahNoPlan(Object count) {
    return '$count versets · aucun plan';
  }

  @override
  String hafizSurahProgress(Object end, Object percent, Object start) {
    return '$start-$end · $percent% complété';
  }

  @override
  String hafizTargetRepetitions(Object count) {
    return 'Objectif : $count';
  }

  @override
  String get homeCalendarStripTitle => 'CALENDRIER SACRÉ';

  @override
  String get homeGoalCompleted => 'accompli';

  @override
  String get homeGoalInProgress => 'en cours';

  @override
  String get homeInsightAlmostCompleteTodayMessage => 'Il vous reste très peu pour conclure une bonne journée.';

  @override
  String get homeInsightAlmostCompleteTodayTitle => 'Presque terminé aujourd\'hui';

  @override
  String homeInsightBetterThanLastWeekMessage(Object delta) {
    return 'Vous avez accompli $delta prières de plus que la semaine dernière.';
  }

  @override
  String get homeInsightBetterThanLastWeekTitle => 'Mieux que la semaine dernière';

  @override
  String homeInsightDhikrDoneMessage(Object count) {
    return 'Vous avez fait $count répétitions aujourd’hui. Très belle fin de journée.';
  }

  @override
  String get homeInsightDhikrDoneTitle => 'Dhikr accompli';

  @override
  String homeInsightDhikrGoodPaceMessage(Object current, Object goal) {
    return 'Vous êtes à $current/$goal répétitions aujourd’hui.';
  }

  @override
  String get homeInsightDhikrGoodPaceTitle => 'Bon rythme de dhikr';

  @override
  String homeInsightGoodPaceTodayMessage(Object count) {
    return 'Vous avez accompli $count prières aujourd’hui.';
  }

  @override
  String get homeInsightGoodPaceTodayTitle => 'Bon rythme aujourd\'hui';

  @override
  String homeInsightMostConsistentPrayerMessage(Object prayer) {
    return '$prayer est actuellement votre moment le plus stable.';
  }

  @override
  String get homeInsightMostConsistentPrayerTitle => 'Votre prière la plus constante';

  @override
  String homeInsightPrayerToStrengthenMessage(Object prayer) {
    return '$prayer demande un peu plus d’attention.';
  }

  @override
  String get homeInsightPrayerToStrengthenTitle => 'Prière à renforcer';

  @override
  String get homeInsightRamadanConsistencyMessage => 'Votre pratique d’aujourd’hui montre déjà un bon équilibre.';

  @override
  String get homeInsightRamadanConsistencyTitle => 'Régularité en Ramadan';

  @override
  String get homeInsightRamadanMomentumMessage => 'Profitez de ce moment de la journée pour garder votre élan.';

  @override
  String get homeInsightRamadanMomentumTitle => 'élan du Ramadan';

  @override
  String get homeInsightRamadanSmallStepsMessage => 'Pendant le Ramadan, les petits pas réguliers comptent énormément.';

  @override
  String get homeInsightStartTodayFirstMessage => 'Votre journée est encore ouverte. Marquez votre première prière et créez de l’élan.';

  @override
  String get homeInsightStartTodayMoreMessage => 'Vous avez encore le temps de commencer sereinement.';

  @override
  String get homeInsightStartTodayTitle => 'Commencez aujourd\'hui';

  @override
  String get homeInsightStillCanStartMessage => 'Un petit pas maintenant peut changer le ton de votre journée.';

  @override
  String get homeInsightStillCanStartTitle => 'Vous pouvez encore commencer';

  @override
  String homeInsightStreakInMotionMessage(Object streak) {
    return 'Vous êtes à $streak jours d’affilée. Protégez cette régularité.';
  }

  @override
  String get homeInsightStreakInMotionTitle => 'Série en mouvement';

  @override
  String get homeInsightTodayLabel => 'INSIGHT D\'AUJOURD\'HUI';

  @override
  String get homeLoadingScheduleBody => 'Préparation de votre prochaine prière';

  @override
  String get homeLoadingScheduleTitle => 'Chargement des horaires';

  @override
  String get homeLocationCachedBody => 'Nous préparons vos horaires en utilisant votre dernière localisation enregistrée.';

  @override
  String get homeLocationEnableDeviceLocation => 'Activer la localisation de l’appareil';

  @override
  String get homeLocationGpsDisabledBody => 'Sans GPS actif, nous ne pouvons pas calculer des horaires précis ni orienter la Qibla.';

  @override
  String get homeLocationPendingBody => 'L’écran principal reste visible même si les horaires ne sont pas encore prêts.';

  @override
  String get homeLocationPermissionBlocked => 'Autorisation de localisation bloquée';

  @override
  String get homeLocationPermissionBlockedBody => 'Vous pourrez activer la localisation pour Qibla Time plus tard dans les réglages du système.';

  @override
  String get homeLocationPermissionNeeded => 'Autorisez la localisation pour voir vos horaires';

  @override
  String get homeLocationPermissionNeededBody => 'Qibla Time a besoin de votre localisation pour afficher des horaires fiables pour votre ville.';

  @override
  String get homeLocationPreparingTitle => 'Préparation de vos horaires';

  @override
  String homeNextPrayerStartsAt(Object time) {
    return 'Commence à $time';
  }

  @override
  String get homeNotificationPaused => 'Les alertes générales de prière sont actuellement en pause.';

  @override
  String get homeNotificationPermissionPending => 'Vos rappels d\'adhan sont configurés, mais l\'autorisation du système est encore en attente.';

  @override
  String get homePrayerDescriptionCompleted => 'Vous avez déjà marqué cette prière comme accomplie.';

  @override
  String get homePrayerDescriptionNext => 'C\'est la prochaine prière dans le rythme d\'aujourd\'hui.';

  @override
  String get homePrayerDescriptionNow => 'Cette prière est actuellement en cours.';

  @override
  String get homePrayerDescriptionPendingToday => 'Encore en attente dans le parcours d\'aujourd\'hui.';

  @override
  String get homePrayerDescriptionReviewDate => 'Disponible à consulter pour cette date.';

  @override
  String homePrayerSectionSelectedDaySubtitle(Object date) {
    return 'Consultez et marquez les horaires du $date';
  }

  @override
  String get homePrayerSectionSelectedDayTitle => 'HORAIRES DU JOUR';

  @override
  String get homePrayerSectionTodaySubtitle => 'Le rythme complet de vos cinq prières quotidiennes';

  @override
  String get homePrayerSectionTodayTitle => 'PRIÈRES D\'AUJOURD\'HUI';

  @override
  String get homePrayerStatusCompleted => 'Accomplie';

  @override
  String get homePrayerStatusNext => 'Suivante';

  @override
  String get homePrayerStatusNow => 'Maintenant';

  @override
  String get homePrayerStatusUpcoming => 'À venir';

  @override
  String get homeQuickActionsTitle => 'RACCOURCIS SACRÉS';

  @override
  String get homeRamadanClosingSoon => 'bientôt la fin';

  @override
  String get homeRamadanContinueReading => 'Continuer la lecture';

  @override
  String homeRamadanCountdownIftar(Object duration) {
    return '$duration avant l’iftar';
  }

  @override
  String homeRamadanCountdownImsak(Object duration) {
    return '$duration avant l’imsak';
  }

  @override
  String homeRamadanCountdownTomorrowImsak(Object duration) {
    return '$duration avant l’imsak de demain';
  }

  @override
  String homeRamadanDhikrCompletedBody(Object current, Object goal) {
    return '$current/$goal répétitions aujourd’hui. Objectif quotidien atteint.';
  }

  @override
  String homeRamadanDhikrInProgressBody(Object current, Object goal) {
    return '$current/$goal répétitions aujourd’hui. Vous avez déjà commencé.';
  }

  @override
  String get homeRamadanDhikrPreparingBody => 'Préparation de votre progression quotidienne de dhikr.';

  @override
  String homeRamadanDhikrStartBody(Object goal) {
    return 'Votre objectif aujourd’hui est de $goal. Même quelques répétitions comptent déjà.';
  }

  @override
  String homeRamadanFastingCompleted(Object time) {
    return 'Vous pouvez faire l’iftar à partir de $time.';
  }

  @override
  String homeRamadanFastingInProgress(Object time) {
    return 'Journée de jeûne en cours jusqu’à $time.';
  }

  @override
  String get homeRamadanFastingLabel => 'Jeûne';

  @override
  String get homeRamadanFastingTitle => 'Jeûne';

  @override
  String get homeRamadanGoalsCompleteMessage => 'Une très belle journée de Ramadan. Gardez ce rythme avec sérénité.';

  @override
  String get homeRamadanGoalsProgressMessage => 'Vous avancez bien aujourd’hui. Un petit pas de plus peut conclure votre journée avec force.';

  @override
  String homeRamadanGoalsReady(Object completed, Object total) {
    return '$completed/$total prêts';
  }

  @override
  String get homeRamadanGoalsStartMessage => 'Commencez par quelque chose de simple : une prière, quelques versets ou quelques minutes de dhikr.';

  @override
  String get homeRamadanGoalsTitle => 'OBJECTIFS DU RAMADAN';

  @override
  String get homeRamadanModeTitle => 'MODE RAMADAN';

  @override
  String get homeRamadanNextFocus => 'prochain objectif';

  @override
  String get homeRamadanNightLabel => 'Nuit';

  @override
  String get homeRamadanOpenQuran => 'Ouvrir le Coran';

  @override
  String get homeRamadanOpenTasbih => 'Ouvrir le tasbih';

  @override
  String homeRamadanPrayerGoal(Object count) {
    return '$count/5 accomplies aujourd’hui';
  }

  @override
  String homeRamadanQuranRecentProgress(Object ayah, Object surah) {
    return 'Reprenez $surah, verset $ayah. Vous avez une progression récente.';
  }

  @override
  String homeRamadanQuranReturnBody(Object ayah, Object surah) {
    return 'Votre dernier point était $surah, verset $ayah. Cela vaut la peine de le reprendre aujourd’hui.';
  }

  @override
  String homeRamadanQuranSavedToday(Object ayah, Object surah) {
    return 'Lecture enregistrée aujourd’hui dans $surah, verset $ayah.';
  }

  @override
  String get homeRamadanQuranStartBody => 'Lisez un court passage aujourd’hui et vous pourrez le reprendre facilement plus tard.';

  @override
  String get homeRamadanStartAction => 'Commencer';

  @override
  String get homeRamadanSuhoorLabel => 'Suhoor';

  @override
  String get homeRamadanUntilIftar => 'avant l’iftar';

  @override
  String get homeSelectedDateCustomBody => 'Consultez ci-dessous les horaires complets du jour sélectionné.';

  @override
  String get homeSelectedDateTodayBody => 'Consultez ci-dessous les horaires complets du jour.';

  @override
  String homeWeeklyBestDayHelper(Object count) {
    return '$count/5 lors de votre meilleur jour';
  }

  @override
  String get qiblaCompassInitError => 'Nous n\'avons pas pu démarrer la boussole.';

  @override
  String get qiblaCompassReadError => 'Nous n\'avons pas pu lire le capteur de la boussole.';

  @override
  String get qiblaDirectionEast => 'Est';

  @override
  String get qiblaDirectionLoadError => 'Nous n\'avons pas pu charger la direction vers la Kaaba.';

  @override
  String get qiblaDirectionNorth => 'Nord';

  @override
  String get qiblaDirectionNorthEast => 'Nord-est';

  @override
  String get qiblaDirectionNorthWest => 'Nord-ouest';

  @override
  String get qiblaDirectionSouth => 'Sud';

  @override
  String get qiblaDirectionSouthEast => 'Sud-est';

  @override
  String get qiblaDirectionSouthWest => 'Sud-ouest';

  @override
  String qiblaDirectionSummary(Object direction) {
    return 'Direction vers la Kaaba : $direction';
  }

  @override
  String get qiblaDirectionWest => 'Ouest';

  @override
  String get qiblaDistanceLabel => 'Distance';

  @override
  String get qiblaEnableLocationMessage => 'Activez la localisation pour calculer la direction vers la Kaaba.';

  @override
  String get qiblaGpsDisabledMessage => 'Activez le GPS de votre appareil pour obtenir une direction fiable.';

  @override
  String get qiblaGuidanceBody => 'Gardez l’appareil à plat et tournez doucement jusqu’à aligner l’indicateur.';

  @override
  String get qiblaHowToUseAvoidMagnetsBody => 'Éloignez-le des aimants, des coques métalliques ou des appareils pouvant perturber le capteur.';

  @override
  String get qiblaHowToUseAvoidMagnetsTitle => 'Évitez les interférences';

  @override
  String get qiblaHowToUseCalibrateBody => 'Si la boussole Échoue, bougez le téléphone en formant un huit pour la recalibrer.';

  @override
  String get qiblaHowToUseCalibrateTitle => 'Calibrer si nécessaire';

  @override
  String get qiblaHowToUseKeepFlatBody => 'Gardez l’appareil à plat pour améliorer la précision de la boussole.';

  @override
  String get qiblaHowToUseKeepFlatTitle => 'Gardez l’appareil à plat';

  @override
  String get qiblaHowToUseTitle => 'Comment utiliser la boussole';

  @override
  String get qiblaLoading => 'Calcul de la direction...';

  @override
  String get qiblaPermissionBlockedMessage => 'L’autorisation de localisation est bloquée. Activez-la dans les réglages du système.';

  @override
  String get qiblaPermissionNeededMessage => 'Nous avons besoin de la localisation pour vous orienter vers la Kaaba.';

  @override
  String get qiblaPrecisionLabel => 'Précision';

  @override
  String get qiblaSubtitle => 'Direction vers la Kaaba';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get adhanSelectorHeaderBody => 'Écoutez un court aperçu avant de choisir l’adhan utilisé pour vos rappels.';

  @override
  String get adhanSelectorHeaderTitle => 'Choisissez votre appel à la prière';

  @override
  String get adhanSelectorListenPreview => 'Écouter l’aperçu';

  @override
  String get adhanSelectorPausePreview => 'Mettre l’aperçu en pause';

  @override
  String get adhanSelectorPreviewError => 'Nous n\'avons pas pu lire l\'aperçu de l\'adhan.';

  @override
  String get adhanSelectorPreviewIdle => 'Touchez pour Écouter un aperçu';

  @override
  String get adhanSelectorPreviewPaused => 'Aperçu en pause';

  @override
  String get adhanSelectorPreviewPlaying => 'Aperçu en cours';

  @override
  String get adhanSelectorResumePreview => 'Reprendre l’aperçu';

  @override
  String adhanSelectorSelected(Object name) {
    return 'Vous avez sélectionné $name';
  }

  @override
  String get adhanSelectorTitle => 'Adhan';

  @override
  String get navHome => 'Accueil';

  @override
  String get navQibla => 'Qibla';

  @override
  String get navTasbih => 'Tasbih';

  @override
  String get navDua => 'Dua';

  @override
  String get navQuran => 'Coran';

  @override
  String travelModeBannerLocationDetected(Object label, int distanceKm) {
    return 'Nouvelle position détectée : $label - $distanceKm km';
  }

  @override
  String get travelModeNotificationTitle => 'Qibla Time - Nouvelle position';

  @override
  String travelModeNotificationBody(Object label) {
    return '$label - Horaires mis à jour';
  }

  @override
  String get analyticsAchievementUnlocked => 'Débloqué';

  @override
  String navigationMiniPlayerAyah(Object surah, int ayah) {
    return '$surah · Verset $ayah';
  }

  @override
  String get onboardingGatePreparing => 'Préparation de Qibla Time';

  @override
  String get supportScreenTitle => 'Soutenir Qibla Time';

  @override
  String get supportScreenThankYou => 'Merci d’être ici';

  @override
  String get supportScreenBody => 'Votre soutien nous aide à prendre soin de Qibla Time, à garder l’application vivante et à continuer à créer des outils utiles pour votre quotidien.';

  @override
  String get supportScreenRateTitle => 'Noter l’application';

  @override
  String get supportScreenRateBody => 'Une bonne note aide davantage de personnes à découvrir Qibla Time.';

  @override
  String get supportScreenShareTitle => 'Partager Qibla Time';

  @override
  String get supportScreenShareBody => 'Recommander l’application à votre famille et à vos proches est aussi une forme de sadaqah.';

  @override
  String get supportScreenSadaqahTitle => 'Soutenir avec intention';

  @override
  String get supportScreenSadaqahBody => 'Si Qibla Time vous aide, vous pouvez soutenir le projet avec une petite contribution sincère.';

  @override
  String get supportScreenQuote => 'Celui qui aide les autres à accéder à un bien partage aussi sa récompense, si Allah le veut.';

  @override
  String get allahNamesTitle => 'Les 99 noms d’Allah';

  @override
  String get allahNamesIntro => 'Explorez une sélection soignée des noms d’Allah, avec translittération et signification pour les retenir avec sérénité.';

  @override
  String get allahNamesLoadError => 'Nous n\'avons pas pu charger les noms d’Allah.';

  @override
  String get allahNamesUseInTasbih => 'Utiliser dans le tasbih';

  @override
  String get downloadedSurahsTitle => 'Sourates téléchargées';

  @override
  String get downloadedSurahsEmpty => 'Vous n’avez encore téléchargé aucune sourate.';

  @override
  String get downloadedSurahsFavorite => 'Favori';

  @override
  String get downloadedSurahsMarkFavorite => 'Marquer comme favorite';

  @override
  String get downloadedSurahsRemoveDownload => 'Supprimer le téléchargement';

  @override
  String get downloadedSurahsLoadError => 'Nous n\'avons pas pu charger vos sourates téléchargées.';

  @override
  String get focusModeDndActive => 'RAKAHA ACTIVE · NE PAS DÉRANGER ACTIVÉ';

  @override
  String get focusModeOpenDndSettings => 'Activer Ne pas déranger dans les réglages';

  @override
  String get focusModeTitle => 'RAKAHA';

  @override
  String get focusModeSujudCount => '+ sujud';

  @override
  String get focusModeDndHint => 'SANS INTERRUPTIONS, C’EST MIEUX AVEC NE PAS DÉRANGER';

  @override
  String get focusModeReleaseToCancel => 'Relâchez pour annuler';

  @override
  String get focusModeHoldToExit => 'Maintenez pour quitter';

  @override
  String get settingsMadhabAsr => 'Madhab (Asr)';

  @override
  String get settingsManualAdjustment => 'Ajustement manuel';

  @override
  String get settingsOpenSourceLicenses => 'Licences open source';

  @override
  String get settingsProfileUser => 'Utilisateur';

  @override
  String get settingsProfileStreak => 'série';

  @override
  String get settingsProfilePrayers => 'prières';

  @override
  String get settingsProfileTasbih => 'tasbih';

  @override
  String get commonShafii => 'Shafi\'i';

  @override
  String get commonRestore => 'Restaurer';

  @override
  String get settingsRestoreBackupPasteHint => 'Collez ici le JSON exporté';

  @override
  String get dailyBookBadge => 'LIVRE DU JOUR';

  @override
  String get dailyBookUnavailable => 'La bibliothèque n’est pas disponible pour le moment.';

  @override
  String get dailyBookOpenLibrary => 'Ouvrir les livres';

  @override
  String get hadithOfflineIncludedInApp => 'Inclus dans l’application';

  @override
  String hadithOfflineAgoDays(int count) {
    return 'Il y a $count jours';
  }

  @override
  String hadithOfflineAgoHours(int count) {
    return 'Il y a $count heures';
  }

  @override
  String hadithOfflineAgoMinutes(int count) {
    return 'Il y a $count minutes';
  }

  @override
  String get hadithOfflineNow => 'À l’instant';

  @override
  String get analyticsShareWeekTitle => 'Résumé hebdomadaire';

  @override
  String analyticsShareCurrentStreak(int count) {
    return 'Série actuelle : $count';
  }

  @override
  String analyticsShareThisWeek(int completed, int maxPossible) {
    return 'Cette semaine : $completed/$maxPossible prières';
  }

  @override
  String analyticsShareBestDay(Object day) {
    return 'Meilleur jour : $day';
  }

  @override
  String get analyticsShareWeekHeading => 'RÉSUMÉ HEBDOMADAIRE';

  @override
  String get analyticsShareStreakDaySingular => 'jour de série';

  @override
  String get analyticsShareStreakDayPlural => 'jours de série';

  @override
  String get analyticsShareWeeklyPrayersLabel => 'Prières cette semaine';

  @override
  String analyticsShareBestDayLabel(int count) {
    return 'Meilleur jour · $count/5';
  }

  @override
  String get analyticsShareFullDaysLabel => 'Jours complets';

  @override
  String get analyticsShareFooter => 'Votre progression dans Qibla Time';

  @override
  String get analyticsShareImageError => 'Nous n\'avons pas pu générer l\'image de progression.';

  @override
  String quranDownloadAyahAudioError(int ayah) {
    return 'Nous n\'avons pas pu télécharger l\'audio du verset $ayah.';
  }

  @override
  String get recentLocationUnknown => 'Position inconnue';

  @override
  String get cloudSyncRestoreInvalid => 'Sauvegarde invalide';

  @override
  String get cloudSyncRestoreFailed => 'Nous n\'avons pas pu restaurer la sauvegarde';

  @override
  String get bookLinkUnavailable => 'Ce lien n’est pas disponible.';

  @override
  String get bookLinkOpenError => 'Nous n\'avons pas pu ouvrir le lien.';

  @override
  String ramadanStatusHeaderDay(int day) {
    return 'Ramadan jour $day';
  }

  @override
  String get ramadanStatusHeaderManual => 'Mode Ramadan manuel';

  @override
  String get ramadanStatusBlessingDetected => 'Qu’Allah accepte votre jeûne et vos œuvres d’aujourd’hui.';

  @override
  String get ramadanStatusBlessingManual => 'Vue spéciale Ramadan activée manuellement pour les tests.';

  @override
  String get ramadanStatusSuggestionDhikr => 'Pensez à augmenter votre dhikr aujourd’hui.';

  @override
  String get ramadanStatusSuggestionQuran => 'Essayez de lire un peu plus de Coran aujourd’hui.';

  @override
  String get ramadanStatusSuggestionDua => 'Profitez de cette journée pour faire des doua avec sérénité.';

  @override
  String get ramadanStatusSuggestionSadaqah => 'Même une petite sadaqah compte pendant le Ramadan.';

  @override
  String adhanSelectorOptionDescription(int number) {
    return 'Appel à la prière $number';
  }

  @override
  String get prayerNotificationImsakTitle => 'Imsak approche';

  @override
  String get prayerNotificationImsakBody => 'Il reste 15 minutes avant l’imsak. Si vous Êtes encore au suhoor, c’est le bon moment pour terminer.';

  @override
  String get prayerNotificationIftarTitle => 'L’iftar approche';

  @override
  String get prayerNotificationIftarBody => 'Il reste 15 minutes avant l’iftar. Qu’Allah accepte votre jeûne aujourd’hui.';

  @override
  String get prayerNotificationJumuahTitle => 'Jumu’ah aujourd’hui';

  @override
  String get prayerNotificationJumuahBody => 'Préparez-vous pour la Jumu’ah avant Dhuhr et gardez un moment de calme pour vous rendre à la mosquée.';
}
