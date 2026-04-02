import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'قبلة تايم';

  @override
  String get commonSkip => 'تخطي';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonContinue => 'متابعة';

  @override
  String get commonEnter => 'دخول';

  @override
  String get commonAllow => 'السماح';

  @override
  String get commonActivate => 'تفعيل';

  @override
  String get commonEnable => 'تفعيل';

  @override
  String get commonEnableGps => 'تفعيل GPS';

  @override
  String get commonOpenSettings => 'فتح الإعدادات';

  @override
  String get commonPending => 'قيد الانتظار';

  @override
  String get commonGranted => 'مفعّل';

  @override
  String get commonBlocked => 'محظور';

  @override
  String get commonReady => 'جاهزة';

  @override
  String get commonDisabled => 'معطّل';

  @override
  String get commonUnavailable => 'غير متاح';

  @override
  String get commonToday => 'اليوم';

  @override
  String get commonYesterday => 'أمس';

  @override
  String get commonLoading => 'جارٍ التحميل...';

  @override
  String get commonShare => 'مشاركة';

  @override
  String get commonManual => 'يدوي';

  @override
  String get commonImportJson => 'استيراد JSON';

  @override
  String get commonExport => 'تصدير';

  @override
  String get commonOpen => 'فتح';

  @override
  String get commonVersion => 'الإصدار';

  @override
  String get commonAbout => 'حول التطبيق';

  @override
  String get commonMethod => 'الطريقة';

  @override
  String get commonMadhab => 'المذهب';

  @override
  String get commonLocation => 'الموقع';

  @override
  String get commonNotifications => 'الإشعارات';

  @override
  String get commonNoData => 'لا توجد بيانات';

  @override
  String get commonNever => 'أبدًا';

  @override
  String get commonGenerating => 'جارٍ الإنشاء...';

  @override
  String get commonChecking => 'جارٍ التحقق...';

  @override
  String get commonDelete => 'حذف';

  @override
  String get commonSystemStatus => 'حالة النظام';

  @override
  String get commonCurrentStatus => 'الحالة الحالية';

  @override
  String get commonOffset => 'الإزاحة';

  @override
  String get commonAutomatic => 'تلقائي';

  @override
  String get commonPrepared => 'جاهزة';

  @override
  String get commonActivated => 'مفعّلة';

  @override
  String get commonPaused => 'متوقفة';

  @override
  String get commonSystem => 'النظام';

  @override
  String get onboardingWelcomeTitle => 'مرحبًا بك في قبلة تايم';

  @override
  String get onboardingWelcomeSubtitle => 'مواقيت الصلاة والقبلة والقرآن والتذكيرات في تطبيق خفيف لروتينك اليومي.';

  @override
  String get onboardingFeatureSchedulesTitle => 'مواقيت موثوقة';

  @override
  String get onboardingFeatureSchedulesBody => 'تُحسب حسب موقعك وطريقة الحساب المفضلة لديك.';

  @override
  String get onboardingFeaturePracticeTitle => 'القبلة والممارسة اليومية';

  @override
  String get onboardingFeaturePracticeBody => 'بوصلة وتسبيح وتتبع وغير ذلك في تجربة واحدة سلسة.';

  @override
  String get onboardingFeatureRemindersTitle => 'تذكيرات مفيدة';

  @override
  String get onboardingFeatureRemindersBody => 'إشعارات الأذان والإعدادات الأساسية جاهزة من اليوم الأول.';

  @override
  String get onboardingPermissionsTitle => 'أذونات مهمة';

  @override
  String get onboardingPermissionsSubtitle => 'نطلب فقط ما نحتاجه لحساب المواقيت واستخدام القبلة وتنبيهك في الوقت المناسب.';

  @override
  String get onboardingLocationReadyBody => 'جاهزة لحساب المواقيت والقبلة.';

  @override
  String get onboardingLocationBlockedBody => 'تم حظر إذن الموقع. يمكنك تفعيله لاحقًا من إعدادات النظام.';

  @override
  String get onboardingLocationGpsOffBody => 'خدمة GPS في جهازك متوقفة. يمكنك المتابعة وتفعيلها لاحقًا.';

  @override
  String get onboardingLocationPendingBody => 'مطلوب لمواقيت دقيقة وتحديد اتجاه مكة.';

  @override
  String get onboardingNotificationsReadyBody => 'جاهزة لتذكيرك بالصلوات.';

  @override
  String get onboardingNotificationsPendingBody => 'بهذا يمكنك تلقي تنبيهات الأذان والتذكيرات لاحقًا.';

  @override
  String get onboardingMethodTitle => 'طريقة الحساب';

  @override
  String get onboardingMethodSubtitle => 'يمكنك تغييرها لاحقًا، لكن هذا يضبط المواقيت بشكل صحيح من اليوم.';

  @override
  String get onboardingSelectedNow => 'محدد الآن';

  @override
  String get onboardingTapToChooseMethod => 'اضغط لاختيار هذه الطريقة';

  @override
  String get onboardingMadhabTitle => 'المذهب لصلاة العصر';

  @override
  String get onboardingMadhabSubtitle => 'يؤثر فقط في حساب صلاة العصر. إذا لم تكن متأكدًا، يمكنك إبقاء الشافعي وتغييره لاحقًا.';

  @override
  String get onboardingMadhabCommonTitle => 'شافعي / مالكي / حنبلي';

  @override
  String get onboardingMadhabCommonSubtitle => 'الخيار الأكثر شيوعًا للبداية';

  @override
  String get onboardingMadhabHanafiTitle => 'حنفي';

  @override
  String get onboardingMadhabHanafiSubtitle => 'استخدم الحساب الحنفي لصلاة العصر';

  @override
  String get onboardingAdhanTitle => 'الأذان والتنبيهات';

  @override
  String get onboardingAdhanSubtitle => 'يمكن لقبلة تايم تنبيهك لكل صلاة بأذان هادئ افتراضيًا. ويمكنك تغييره لاحقًا.';

  @override
  String get onboardingPrayerNotificationsTitle => 'إشعارات الصلاة';

  @override
  String get onboardingPrayerNotificationsSubtitle => 'يمكنك تفعيلها الآن أو المتابعة بدونها في الوقت الحالي.';

  @override
  String get onboardingAdhanPreviewTitle => 'معاينة سريعة للأذان';

  @override
  String get onboardingAdhanPreviewSubtitle => 'سيُستخدم الصوت الذي اخترته. ويمكنك تغييره لاحقًا من الإعدادات.';

  @override
  String get onboardingAdhanStopPreview => 'إيقاف المعاينة';

  @override
  String get onboardingAdhanListenPreview => 'الاستماع للمعاينة';

  @override
  String get onboardingDoneTitle => 'كل شيء جاهز';

  @override
  String get onboardingDoneSubtitle => 'يمكنك الآن البدء بمواقيتك وقبلتك وتتبعك اليومي. ويمكن تعديل كل ذلك لاحقًا.';

  @override
  String get onboardingSummaryLocationBlocked => 'محظورة حاليًا';

  @override
  String get onboardingSummaryNotificationsPrepared => 'جاهزة';

  @override
  String get methodMuslimWorldLeague => 'رابطة العالم الإسلامي';

  @override
  String get methodNorthAmerica => 'ISNA / أمريكا الشمالية';

  @override
  String get methodUmmAlQura => 'أم القرى';

  @override
  String get methodEgyptian => 'الهيئة المصرية';

  @override
  String get homeHeaderOnline => 'متصل';

  @override
  String get homeHeaderOffline => 'بدون شبكة';

  @override
  String get homeHeaderLocationUnavailable => 'الموقع غير متاح';

  @override
  String homeHeaderStatusLine(Object networkStatus, Object location) {
    return '$networkStatus · $location';
  }

  @override
  String get homeHeroNextPrayer => 'الصلاة القادمة';

  @override
  String get homeHeroTodayOverview => 'النظرة الرئيسية لليوم';

  @override
  String get homeHeroUsingSavedLocation => 'يتم استخدام آخر موقع محفوظ';

  @override
  String get homeSelectedDateToday => 'اليوم';

  @override
  String get homeSelectedDateCustom => 'التاريخ المحدد';

  @override
  String get homeCountdownUnavailable => 'العد التنازلي غير متاح';

  @override
  String get homeCountdownActive => 'العد التنازلي نشط';

  @override
  String homeCountdownUntil(Object prayer) {
    return 'حتى $prayer';
  }

  @override
  String get homeCountdownLabelUppercase => 'العد التنازلي';

  @override
  String homeDurationUntil(int hours, int minutes) {
    return 'خلال $hoursس $minutesد';
  }

  @override
  String homeDurationHoursMinutes(int hours, String minutes) {
    return '$hours س $minutes د';
  }

  @override
  String homeDurationMinutes(int minutes) {
    return '$minutes د';
  }

  @override
  String homeDurationSeconds(String seconds) {
    return '$seconds ث';
  }

  @override
  String get homePrayerSectionToday => 'صلوات اليوم';

  @override
  String homePrayerSectionForDate(Object date) {
    return 'مواقيت $date';
  }

  @override
  String homePrayerSectionWorshipDay(Object weekday) {
    return '$weekday، يوم عبادة';
  }

  @override
  String homePrayerSectionMarkedCount(int count) {
    return '$count/5 محددة';
  }

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get settingsTitleArabic => 'الإعدادات';

  @override
  String get settingsSectionAppearance => 'المظهر';

  @override
  String get settingsSectionAccessibility => 'إمكانية الوصول';

  @override
  String get settingsSectionAdhanNotifications => 'إشعارات الأذان';

  @override
  String get settingsSectionScheduleCalculation => 'حساب المواقيت';

  @override
  String get settingsSectionRamadanMode => 'وضع رمضان';

  @override
  String get settingsSectionHadith => 'الأحاديث';

  @override
  String get settingsSectionTravelerMode => 'وضع السفر';

  @override
  String get settingsSectionRecentPlaces => 'الأماكن الأخيرة';

  @override
  String get settingsSectionSmartCache => 'الذاكرة المؤقتة الذكية';

  @override
  String get settingsSectionSupport => 'الصدقة · الدعم';

  @override
  String get settingsSectionCloudBackup => 'النسخ الاحتياطي السحابي (بيتا)';

  @override
  String get settingsTextSize => 'حجم النص';

  @override
  String settingsCurrentScale(Object scale) {
    return 'المقياس الحالي: ${scale}x';
  }

  @override
  String get settingsHighContrast => 'تباين عالٍ';

  @override
  String get settingsHighContrastSubtitle => 'يحسن القراءة في جميع أجزاء التطبيق';

  @override
  String get settingsUseSystemBold => 'استخدام الخط العريض من النظام';

  @override
  String get settingsUseSystemBoldSubtitle => 'يحترم تفضيل VoiceOver وTalkBack';

  @override
  String get settingsResetAccessibility => 'إعادة ضبط إمكانية الوصول';

  @override
  String get settingsReset => 'إعادة ضبط';

  @override
  String get settingsThemeDarkTitle => 'داكن';

  @override
  String get settingsThemeDarkSubtitle => 'سماء ما قبل الفجر';

  @override
  String get settingsThemeLightTitle => 'فاتح';

  @override
  String get settingsThemeLightSubtitle => 'للاستخدام الخارجي';

  @override
  String get settingsThemeAmoledTitle => 'أموليد';

  @override
  String get settingsThemeAmoledSubtitle => 'أسود نقي ويوفر البطارية';

  @override
  String get settingsThemeDeuteranopiaTitle => 'عمى الألوان الأحمر/الأخضر';

  @override
  String get settingsThemeDeuteranopiaSubtitle => 'بدون الأحمر والأخضر';

  @override
  String get settingsThemeMonochromeTitle => 'أحادي اللون';

  @override
  String get settingsThemeMonochromeSubtitle => 'للاكروماتوبسيا وضعف البصر';

  @override
  String get settingsLanguage => 'لغة التطبيق';

  @override
  String get settingsLanguageSubtitle => 'اختر ما إذا كنت تريد أن يتبع التطبيق لغة الجهاز أو يستخدم لغة ثابتة في جميع أجزائه.';

  @override
  String get settingsLanguageDialogTitle => 'لغة التطبيق';

  @override
  String get settingsLanguageOptionSystem => 'اتباع لغة الجهاز';

  @override
  String settingsLanguageSystemValue(Object language) {
    return 'تلقائي ($language)';
  }

  @override
  String get settingsLanguageOptionSpanish => 'Español';

  @override
  String get settingsLanguageOptionEnglish => 'English';

  @override
  String get settingsLanguageOptionArabic => 'العربية';

  @override
  String get settingsAdhanSound => 'صوت الأذان';

  @override
  String get settingsAdhanSoundAction => 'اختيار ومعاينة';

  @override
  String get settingsGeneralNotifications => 'الإشعارات العامة';

  @override
  String get settingsGeneralNotificationsSubtitle => 'تفعيل أو إيقاف جميع تنبيهات الصلاة';

  @override
  String get settingsSystemPermissionPendingBody => 'تنبيهات الأذان مضبوطة، لكن إذن النظام ما زال معلقًا.';

  @override
  String get settingsHapticFeedback => 'الاهتزاز اللمسي';

  @override
  String get settingsRamadanAutomatic => 'وضع رمضان التلقائي';

  @override
  String get settingsRamadanAutomaticSubtitle => 'يعمل تلقائيًا عند دخول رمضان في التقويم الإسلامي';

  @override
  String get settingsRamadanForced => 'فرض وضع رمضان';

  @override
  String get settingsRamadanForcedSubtitle => 'تفعيل عرض رمضان يدويًا';

  @override
  String get settingsDailyNotification => 'إشعار يومي';

  @override
  String get settingsDailyNotificationSubtitle => 'استقبل حديثًا أو آية كل يوم';

  @override
  String get settingsNotificationHour => 'وقت الإشعار';

  @override
  String get settingsTravelerMode => 'وضع السفر';

  @override
  String get settingsTravelerModeSubtitle => 'يكتشف تغيّر المدينة تلقائيًا (>50 كم)';

  @override
  String get settingsTravelerModeLoadError => 'تعذر تحميل وضع السفر';

  @override
  String get settingsRecentPlaces => 'الأماكن الأخيرة';

  @override
  String get settingsNoRecentTrips => 'لا توجد رحلات حديثة';

  @override
  String get settingsLoadError => 'تعذر تحميله';

  @override
  String get settingsCacheValidUntil => 'الذاكرة المؤقتة صالحة حتى';

  @override
  String get settingsCacheEntries => 'عناصر الذاكرة المؤقتة';

  @override
  String get settingsClearCache => 'مسح الذاكرة المؤقتة';

  @override
  String get settingsSupportInfo => 'معلومات الدعم';

  @override
  String get settingsSupportCardTitle => 'ادعم التطوير';

  @override
  String get settingsSupportCardSubtitle => 'كل تبرع قد يكون صدقة جارية';

  @override
  String get settingsBackupMode => 'وضع النسخ الاحتياطي';

  @override
  String get settingsAnonymousId => 'معرّف مجهول';

  @override
  String get settingsLastBackup => 'آخر نسخة';

  @override
  String get settingsExportBackup => 'تصدير نسخة';

  @override
  String get settingsRestoreBackup => 'استعادة نسخة';

  @override
  String get settingsBackupInfoBody => 'يمكنك حفظ ومشاركة نسخة يدوية بصيغة JSON. الأتمتة والمزامنة بين الأجهزة غير متاحتين بعد.';

  @override
  String get settingsRestoreBackupDialogTitle => 'استعادة النسخة';

  @override
  String get settingsRestoreBackupSuccess => 'تمت استعادة النسخة';

  @override
  String get settingsRestoreBackupError => 'تعذر استعادة النسخة.';

  @override
  String get settingsDailyNotificationEnabled => 'تم تفعيل الإشعار اليومي';

  @override
  String get settingsDailyNotificationDisabled => 'تم إيقاف الإشعار اليومي';

  @override
  String get settingsSelectHourTitle => 'اختر الساعة';

  @override
  String get settingsToday => 'اليوم';

  @override
  String get settingsYesterday => 'أمس';

  @override
  String settingsDaysAgo(int count) {
    return 'منذ $count أيام';
  }

  @override
  String get settingsRamadanManualActive => 'مفعل يدويًا';

  @override
  String get settingsLocationBlocked => 'محظورة';

  @override
  String get settingsLocationPendingPermission => 'الإذن معلق';

  @override
  String get settingsLocationAutomatic => 'تلقائية';

  @override
  String get settingsLocationSavedUnavailable => 'لا يوجد موقع محفوظ';

  @override
  String get settingsLocationStatus => 'حالة الموقع';

  @override
  String get settingsGpsOff => 'GPS متوقف';

  @override
  String get settingsScheduleSource => 'مصدر المواقيت';

  @override
  String get settingsScheduleSourceReady => 'الذاكرة المؤقتة جاهزة';

  @override
  String get settingsNotificationSystem => 'إشعارات النظام';

  @override
  String get settingsNotificationApp => 'إشعارات التطبيق';

  @override
  String get settingsNotificationsGranted => 'مفعّلة';

  @override
  String get commonPlay => 'تشغيل';

  @override
  String get commonText => 'نص';

  @override
  String get commonVideo => 'فيديو';

  @override
  String get commonRemove => 'إزالة';

  @override
  String get shareBranding => 'التطبيق: قبلة تايم';

  @override
  String shareReferenceLabel(Object reference) {
    return 'المرجع: $reference';
  }

  @override
  String get shareSubjectDua => 'دعاء';

  @override
  String get shareSubjectHadithOfDay => 'حديث اليوم - قبلة تايم';

  @override
  String get shareSubjectHadithShared => 'حديث تمت مشاركته من قبلة تايم';

  @override
  String get shareBadgeHadith => 'حديث';

  @override
  String get shareBadgeDua => 'دعاء';

  @override
  String get shareBadgeQuran => 'القرآن';

  @override
  String get shareSectionStyle => 'النمط / الخلفية';

  @override
  String get shareSectionContent => 'المحتوى';

  @override
  String get shareLayoutCard => 'بطاقة';

  @override
  String get shareLayoutStory => 'قصة';

  @override
  String get shareContentBilingual => 'العربية + الترجمة';

  @override
  String get shareContentArabicOnly => 'العربية فقط';

  @override
  String get shareContentTranslationOnly => 'الترجمة فقط';

  @override
  String get shareActionShareImage => 'مشاركة صورة';

  @override
  String get shareActionShareText => 'مشاركة نص';

  @override
  String get shareHadithTitle => 'مشاركة حديث';

  @override
  String get shareHadithSubtitle => 'اختر التنسيق والمحتوى قبل المشاركة.';

  @override
  String get shareHadithTextError => 'تعذر علينا مشاركة نص الحديث.';

  @override
  String get shareHadithImageError => 'تعذر علينا إنشاء صورة الحديث.';

  @override
  String get shareDuaTitle => 'مشاركة دعاء';

  @override
  String shareDuaTitleNamed(Object title) {
    return 'مشاركة $title';
  }

  @override
  String get shareDuaSubtitle => 'استخدم نفس المعالجة البصرية الخاصة بالحديث للدعاء والأذكار.';

  @override
  String get shareDuaTextError => 'تعذر علينا مشاركة نص الدعاء.';

  @override
  String get shareDuaImageError => 'تعذر علينا إنشاء صورة الدعاء.';

  @override
  String shareAyahTitle(int number) {
    return 'مشاركة الآية $number';
  }

  @override
  String get shareAyahSubtitle => 'حافظ على العرض البصري نفسه للنص والصورة والفيديو.';

  @override
  String get shareAyahTextError => 'تعذر علينا مشاركة نص هذه الآية.';

  @override
  String get shareAyahImageError => 'تعذر علينا إنشاء صورة هذه الآية.';

  @override
  String get shareAyahVideoNoAudio => 'لا يوجد صوت متاح لإنشاء فيديو لهذه الآية.';

  @override
  String get shareAyahVideoGenerating => 'جارٍ إنشاء فيديو الآية...';

  @override
  String get shareAyahVideoError => 'تعذر علينا إنشاء فيديو هذه الآية.';

  @override
  String get notificationAdhanChannelName => 'الأذان';

  @override
  String get notificationAdhanChannelDescription => 'إشعارات مواقيت الصلاة';

  @override
  String notificationAdhanTitle(Object prayerName) {
    return 'قبلة تايم - $prayerName';
  }

  @override
  String get notificationAdhanBody => 'حان وقت الصلاة';

  @override
  String get notificationReminderChannelName => 'قبلة تايم - تذكيرات';

  @override
  String get notificationReminderChannelDescription => 'تذكيرات سياقية لرمضان والجمعة';

  @override
  String get notificationDailyReflectionChannelName => 'تأمل يومي';

  @override
  String get notificationDailyReflectionChannelDescription => 'آية من القرآن وحديث اليوم';

  @override
  String get notificationDailyReflectionTitle => 'تأمل اليوم';

  @override
  String get notificationDailyReflectionFallbackBody => 'تأملك الروحي اليومي في قبلة تايم.';

  @override
  String get notificationDailyReflectionErrorTitle => 'قبلة تايم · تأمل يومي';

  @override
  String get notificationDailyReflectionErrorBody => 'تذكيرك الروحي لهذا اليوم';

  @override
  String get notificationHadithReminderChannelName => 'تذكيرات الأحاديث';

  @override
  String get notificationHadithReminderChannelDescription => 'تذكيرات الأحاديث كل ساعة';

  @override
  String get notificationHadithReminderFallbackBody => 'تذكير: اقرأ حديثًا عن النبي ﷺ';

  @override
  String get notificationHadithReminderTitle => '📖 حديث هذه اللحظة';

  @override
  String get notificationHadithReminderTestBody => 'اختبار تذكير الحديث';

  @override
  String get notificationHadithReminderTestTitle => '📖 تذكير بحديث';

  @override
  String get notificationWeeklySummaryTitle => 'ملخصك الأسبوعي جاهز';

  @override
  String notificationWeeklySummaryBody(int prayersCompleted, int maxPossible, Object strongestDay) {
    return 'أكملت هذا الأسبوع $prayersCompleted/$maxPossible من الصلوات. وكان أفضل أيامك $strongestDay.';
  }

  @override
  String get quranDailyVerseFallbackTranslation => 'الله لا إله إلا هو الحي القيوم، لا تأخذه سنة ولا نوم.';

  @override
  String get quranDailyVerseFallbackTransliteration => 'Allahu la ilaha illa huwal hayyul qayyum...';

  @override
  String get quranDailyVerseFallbackReference => 'البقرة [2:255]';

  @override
  String get quranTitle => 'القرآن';

  @override
  String get quranSubtitle => '114 سورة · قراءة متواصلة';

  @override
  String get quranHafizLabel => 'حافظ';

  @override
  String get quranUtilityAyatAlKursi => 'آية الكرسي';

  @override
  String get quranUtilityAllahNames => '99 اسمًا';

  @override
  String get quranUtilityDownloaded => 'تم تنزيلها';

  @override
  String get quranProtectionTitle => 'التحصين اليومي';

  @override
  String get quranProtectionSubtitle => 'وصول سريع إلى آية الكرسي وسور الحماية. يمكنك فتحها للقراءة أو الاستماع ثم تسجيل تكرارها ثلاث مرات.';

  @override
  String get quranProtectionAyatAlKursiHelper => 'البقرة 2:255';

  @override
  String quranProtectionSurahHelper(int number) {
    return 'سورة $number';
  }

  @override
  String get quranProtectionIkhlasTitle => 'الإخلاص';

  @override
  String get quranProtectionFalaqTitle => 'الفلق';

  @override
  String get quranProtectionNasTitle => 'الناس';

  @override
  String quranProtectionRepeatCount(Object helper, int count) {
    return '$helper · $count/3 مرات';
  }

  @override
  String get quranProtectionCompleteTooltip => 'مكتمل';

  @override
  String get quranProtectionIncrementTooltip => '+1 تكرار';

  @override
  String get quranReadingHintTitle => 'قراءة متواصلة';

  @override
  String get quranReadingHintBody => 'افتح أي سورة وسنحفظ آخر آية قرأتها لتعود إليها لاحقًا.';

  @override
  String get quranReadingHintSecondary => 'يمكنك أيضًا حفظ العلامات بالضغط على أيقونة الإشارة أثناء القراءة.';

  @override
  String get quranContinueReadingTitle => 'متابعة القراءة';

  @override
  String get quranBookmarksTitle => 'العلامات';

  @override
  String get quranRevelationMecca => 'مكية';

  @override
  String get quranRevelationMedina => 'مدنية';

  @override
  String quranAyahCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آيات',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String quranLastReadingAyah(int ayah) {
    return 'آخر قراءة: الآية $ayah';
  }

  @override
  String quranBookmarkCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count علامات محفوظة',
      one: 'علامة محفوظة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get quranDownloadedFavoriteOffline => 'الصوت مُنزّل · مفضلة دون اتصال';

  @override
  String get quranDownloadedAudio => 'الصوت مُنزّل';

  @override
  String quranReadingPointSaved(int ayah) {
    return 'تم حفظ موضع القراءة عند الآية $ayah';
  }

  @override
  String quranBookmarkSaved(int ayah) {
    return 'تم حفظ العلامة عند الآية $ayah';
  }

  @override
  String quranBookmarkRemoved(int ayah) {
    return 'تمت إزالة العلامة من الآية $ayah';
  }

  @override
  String quranShareAyahTitle(int ayah) {
    return 'مشاركة الآية $ayah';
  }

  @override
  String get quranShareTextSubtitle => 'يتضمن النص العربي والترجمة والمرجع.';

  @override
  String get quranShareImageSubtitle => 'أنشئ صورة لهذه الآية.';

  @override
  String get quranShareVideoSubtitle => 'أنشئ فيديو بالبطاقة والتلاوة.';

  @override
  String get quranAyahImageError => 'تعذر علينا إنشاء صورة هذه الآية.';

  @override
  String get quranAyahVideoNoAudio => 'هذه الآية لا يتوفر لها صوت لإنشاء الفيديو.';

  @override
  String get quranAyahVideoGenerating => 'جارٍ إنشاء فيديو الآية...';

  @override
  String quranAyahVideoShareText(int ayah, Object surah) {
    return 'الآية $ayah من $surah';
  }

  @override
  String get quranAyahVideoError => 'تعذر علينا إنشاء فيديو هذه الآية.';

  @override
  String get quranDownloadCheckError => 'تعذر علينا التحقق من التنزيل على هذا الجهاز.';

  @override
  String get quranDownloadSuccess => 'تم تنزيل الصوت. يمكنك الآن الاستماع إلى هذه السورة دون اتصال.';

  @override
  String get quranDownloadDetailedError => 'تعذر علينا إكمال التنزيل. تحقق من اتصالك ثم حاول مرة أخرى.';

  @override
  String get quranDownloadShortError => 'تعذر علينا إكمال تنزيل الصوت.';

  @override
  String get quranDownloadedAudioPlaySubtitle => 'استمع إلى السورة بالصوت المحفوظ.';

  @override
  String get quranDownloadedAudioRemoveSubtitle => 'وفّر مساحة ثم استمع إليها عبر الإنترنت من جديد.';

  @override
  String get quranDownloadedAudioRemoved => 'تمت إزالة تنزيل هذه السورة.';

  @override
  String get quranDownloadedFavoriteAdded => 'تم حفظ السورة ضمن تنزيلاتك المفضلة.';

  @override
  String get quranDownloadedFavoriteRemoved => 'تمت إزالة السورة من تنزيلاتك المفضلة.';

  @override
  String get quranAyahAudioUnavailable => 'الصوت غير متاح لهذه الآية.';

  @override
  String get quranAyahAudioDownloaded => 'الصوت مُنزّل بالفعل على هذا الجهاز.';

  @override
  String get quranAyahAudioAvailable => 'يمكنك الاستماع إلى هذه الآية.';

  @override
  String get quranAyahAudioRequiresConnection => 'يمكنك الاستماع إلى هذه الآية إذا كان لديك اتصال.';

  @override
  String get quranSurahRecitationUnavailable => 'التلاوة الكاملة غير متاحة لهذه السورة.';

  @override
  String quranSurahAudioDownloading(int downloaded, int total) {
    return 'جارٍ تنزيل الصوت للاستماع إلى هذه السورة دون اتصال. $downloaded/$total آيات جاهزة.';
  }

  @override
  String get quranSurahAudioDownloaded => 'الصوت مُنزّل بالفعل على هذا الجهاز. يمكنك الاستماع إلى هذه السورة دون اتصال.';

  @override
  String quranSurahAudioMissingAyahs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'سيتم تجاوز $count آيات بلا صوت.',
      one: 'سيتم تجاوز آية واحدة بلا صوت.',
    );
    return '$_temp0';
  }

  @override
  String quranSurahAudioPartialDownload(int downloaded, int total) {
    return 'لديك بالفعل $downloaded/$total آيات محفوظة على هذا الجهاز.';
  }

  @override
  String get quranSurahAudioDownloadAvailable => 'يمكنك أيضًا تنزيلها للاستماع دون اتصال.';

  @override
  String get quranSurahAudioPlayOnline => 'يمكنك الاستماع إلى هذه السورة بشكل متواصل.';

  @override
  String get quranSurahAudioPlayWithConnection => 'يمكنك الاستماع إلى هذه السورة كاملة إذا كان لديك اتصال.';

  @override
  String get quranAyahPlaybackError => 'تعذر علينا تشغيل الصوت. تحقق من اتصالك ثم حاول مرة أخرى.';

  @override
  String get quranSurahPlaybackError => 'تعذر علينا بدء التلاوة الكاملة.';

  @override
  String get quranLastReadingBadge => 'آخر قراءة';

  @override
  String get quranPauseAudio => 'إيقاف الصوت مؤقتًا';

  @override
  String get quranResumeAudio => 'متابعة الصوت';

  @override
  String get quranPlayAudio => 'تشغيل الصوت';

  @override
  String get quranAudioUnavailable => 'الصوت غير متاح';

  @override
  String get quranRemoveBookmark => 'إزالة العلامة';

  @override
  String get quranSaveBookmark => 'حفظ العلامة';

  @override
  String quranAyahFooterHint(Object status) {
    return '$status اضغط على هذه الآية لحفظ موضع قراءتك هنا، واضغط مطولًا لمشاركتها.';
  }

  @override
  String get quranDetailLoadError => 'تعذر علينا تحميل هذه السورة. تحقق من اتصالك ثم حاول مرة أخرى.';

  @override
  String quranTopBannerResume(int ayah) {
    return 'استئناف من الآية $ayah.';
  }

  @override
  String get quranTopBannerOnline => 'تم تحميل المحتوى عبر الإنترنت. يمكنك الاستماع إلى صوت كل آية ما دام الاتصال متاحًا.';

  @override
  String get quranTopBannerOffline => 'تم تحميل النص دون اتصال. قد يحتاج صوت بعض الآيات إلى اتصال.';

  @override
  String get quranTopBannerPlaceholder => 'تم تحميل محتوى جزئي دون اتصال. الصوت غير متاح حاليًا.';

  @override
  String get quranSurahAudioCardTitle => 'الاستماع إلى السورة';

  @override
  String quranAvailableAyahs(int available, int total) {
    return '$available/$total آيات';
  }

  @override
  String get quranPauseSurah => 'إيقاف السورة مؤقتًا';

  @override
  String get quranResumeSurah => 'متابعة السورة';

  @override
  String get quranListenSurah => 'الاستماع إلى السورة';

  @override
  String get quranStop => 'إيقاف';

  @override
  String get quranCheckingAudio => 'جارٍ التحقق من الصوت';

  @override
  String quranDownloadingProgress(int downloaded, int total) {
    return 'جارٍ التنزيل $downloaded/$total';
  }

  @override
  String get quranDownloaded => 'تم التنزيل';

  @override
  String get quranDownloadAudio => 'تنزيل الصوت';

  @override
  String get quranDownloadedFavoriteLabel => 'مفضلة مُنزّلة';

  @override
  String get quranMarkFavorite => 'تمييز كمفضلة';

  @override
  String quranPlayingSurahAyah(int ayah) {
    return 'يتم تشغيل السورة · الآية $ayah';
  }

  @override
  String quranPausedSurahAyah(int ayah) {
    return 'السورة متوقفة مؤقتًا · الآية $ayah';
  }

  @override
  String quranPlayingAyah(int ayah) {
    return 'يتم تشغيل الآية $ayah';
  }

  @override
  String quranPausedAyah(int ayah) {
    return 'الآية $ayah متوقفة مؤقتًا';
  }

  @override
  String get quranActiveAudioSurahHint => 'ستستمر السورة تلقائيًا مع الآية التالية.';

  @override
  String get quranActiveAudioAyahHint => 'يمكنك الإيقاف المؤقت أو المتابعة أو الإيقاف لهذه التلاوة.';

  @override
  String get quranStopAudio => 'إيقاف الصوت';
}
