import 'package:flutter/material.dart';

class HadithCategoryMeta {
  const HadithCategoryMeta({
    required this.icon,
    required this.label,
    required this.arabicLabel,
  });

  final IconData icon;
  final String label;
  final String arabicLabel;
}

class HadithCategoryPresentation {
  static const _icons = <String, IconData>{
    'adab': Icons.menu_book_outlined,
    'love_allah': Icons.favorite_border_outlined,
    'self_reflection': Icons.psychology_alt_outlined,
    'fasting': Icons.wb_sunny_outlined,
    'character': Icons.auto_awesome_outlined,
    'charity': Icons.volunteer_activism_outlined,
    'compassion': Icons.favorite_outline,
    'knowledge': Icons.school_outlined,
    'consistency': Icons.track_changes_outlined,
    'heart': Icons.favorite_outline,
    'dhikr': Icons.auto_awesome_outlined,
    'dua': Icons.pan_tool_outlined,
    'family': Icons.family_restroom_outlined,
    'brotherhood': Icons.people_outline,
    'gratitude': Icons.favorite_border_outlined,
    'haya': Icons.shield_outlined,
    'honesty': Icons.verified_user_outlined,
    'ihsan': Icons.stars_outlined,
    'intentions': Icons.lightbulb_outline,
    'istighfar': Icons.refresh_outlined,
    'justice': Icons.balance_outlined,
    'tongue': Icons.record_voice_over_outlined,
    'mosque': Icons.mosque_outlined,
    'mercy': Icons.favorite_outline,
    'patience': Icons.hourglass_bottom_outlined,
    'purification': Icons.water_drop_outlined,
    'quran': Icons.auto_stories_outlined,
    'provision': Icons.shopping_basket_outlined,
    'salah': Icons.access_time_outlined,
    'safety': Icons.shield_outlined,
    'service': Icons.handshake_outlined,
    'sincerity': Icons.verified_outlined,
    'taqwa': Icons.spa_outlined,
    'zuhd': Icons.landscape_outlined,
  };

  static const _spanishLabels = <String, String>{
    'adab': 'Adab',
    'love_allah': 'Amor de Ala',
    'self_reflection': 'Autorreflexion',
    'fasting': 'Ayuno',
    'character': 'Caracter',
    'charity': 'Caridad',
    'compassion': 'Compasion',
    'knowledge': 'Conocimiento',
    'consistency': 'Constancia',
    'heart': 'Corazon',
    'dhikr': 'Dhikr',
    'dua': 'Dua',
    'family': 'Familia',
    'brotherhood': 'Fraternidad',
    'gratitude': 'Gratitud',
    'haya': 'Haya',
    'honesty': 'Honestidad',
    'ihsan': 'Ihsan',
    'intentions': 'Intenciones',
    'istighfar': 'Istighfar',
    'justice': 'Justicia',
    'tongue': 'Lengua',
    'mosque': 'Mezquita',
    'mercy': 'Misericordia',
    'patience': 'Paciencia',
    'purification': 'Purificacion',
    'quran': 'Quran',
    'provision': 'Sustento',
    'salah': 'Salah',
    'safety': 'Seguridad',
    'service': 'Servicio',
    'sincerity': 'Sinceridad',
    'taqwa': 'Taqwa',
    'zuhd': 'Zuhd',
  };

  static const _englishLabels = <String, String>{
    'adab': 'Adab',
    'love_allah': 'Love of Allah',
    'self_reflection': 'Self-reflection',
    'fasting': 'Fasting',
    'character': 'Character',
    'charity': 'Charity',
    'compassion': 'Compassion',
    'knowledge': 'Knowledge',
    'consistency': 'Consistency',
    'heart': 'Heart',
    'dhikr': 'Dhikr',
    'dua': 'Dua',
    'family': 'Family',
    'brotherhood': 'Brotherhood',
    'gratitude': 'Gratitude',
    'haya': 'Haya',
    'honesty': 'Honesty',
    'ihsan': 'Ihsan',
    'intentions': 'Intentions',
    'istighfar': 'Istighfar',
    'justice': 'Justice',
    'tongue': 'Tongue',
    'mosque': 'Mosque',
    'mercy': 'Mercy',
    'patience': 'Patience',
    'purification': 'Purification',
    'quran': 'Quran',
    'provision': 'Provision',
    'salah': 'Salah',
    'safety': 'Safety',
    'service': 'Service',
    'sincerity': 'Sincerity',
    'taqwa': 'Taqwa',
    'zuhd': 'Zuhd',
  };

  static const _frenchLabels = <String, String>{
    'adab': 'Adab',
    'love_allah': 'Amour d\'Allah',
    'self_reflection': 'Introspection',
    'fasting': 'Jeune',
    'character': 'Caractere',
    'charity': 'Aumone',
    'compassion': 'Compassion',
    'knowledge': 'Connaissance',
    'consistency': 'Constance',
    'heart': 'Coeur',
    'dhikr': 'Dhikr',
    'dua': 'Doua',
    'family': 'Famille',
    'brotherhood': 'Fraternite',
    'gratitude': 'Gratitude',
    'haya': 'Haya',
    'honesty': 'Honnetete',
    'ihsan': 'Ihsan',
    'intentions': 'Intentions',
    'istighfar': 'Istighfar',
    'justice': 'Justice',
    'tongue': 'Langue',
    'mosque': 'Mosquee',
    'mercy': 'Misericorde',
    'patience': 'Patience',
    'purification': 'Purification',
    'quran': 'Coran',
    'provision': 'Subsistance',
    'salah': 'Salah',
    'safety': 'Securite',
    'service': 'Service',
    'sincerity': 'Sincerite',
    'taqwa': 'Taqwa',
    'zuhd': 'Zuhd',
  };

  static const _russianLabels = <String, String>{
    'adab': 'Адаб',
    'love_allah': 'Любовь к Аллаху',
    'self_reflection': 'Самоанализ',
    'fasting': 'Пост',
    'character': 'Нрав',
    'charity': 'Милостыня',
    'compassion': 'Милосердие',
    'knowledge': 'Знание',
    'consistency': 'Постоянство',
    'heart': 'Сердце',
    'dhikr': 'Зикр',
    'dua': 'Дуа',
    'family': 'Семья',
    'brotherhood': 'Братство',
    'gratitude': 'Благодарность',
    'haya': 'Хая',
    'honesty': 'Честность',
    'ihsan': 'Ихсан',
    'intentions': 'Намерения',
    'istighfar': 'Истигфар',
    'justice': 'Справедливость',
    'tongue': 'Язык',
    'mosque': 'Мечеть',
    'mercy': 'Милость',
    'patience': 'Терпение',
    'purification': 'Очищение',
    'quran': 'Коран',
    'provision': 'Удел',
    'salah': 'Намаз',
    'safety': 'Безопасность',
    'service': 'Служение',
    'sincerity': 'Искренность',
    'taqwa': 'Таква',
    'zuhd': 'Зухд',
  };

  static const _arabicLabels = <String, String>{
    'adab': 'الادب',
    'love_allah': 'محبة الله',
    'self_reflection': 'محاسبة النفس',
    'fasting': 'الصيام',
    'character': 'حسن الخلق',
    'charity': 'الصدقة',
    'compassion': 'الرحمة',
    'knowledge': 'العلم',
    'consistency': 'الثبات',
    'heart': 'القلب',
    'dhikr': 'الذكر',
    'dua': 'الدعاء',
    'family': 'الاسرة',
    'brotherhood': 'الاخوة',
    'gratitude': 'الشكر',
    'haya': 'الحياء',
    'honesty': 'الامانة',
    'ihsan': 'الاحسان',
    'intentions': 'النيات',
    'istighfar': 'الاستغفار',
    'justice': 'العدل',
    'tongue': 'اللسان',
    'mosque': 'المسجد',
    'mercy': 'الرحمة',
    'patience': 'الصبر',
    'purification': 'الطهارة',
    'quran': 'القرآن',
    'provision': 'الرزق',
    'salah': 'الصلاة',
    'safety': 'الامان',
    'service': 'خدمة الناس',
    'sincerity': 'الاخلاص',
    'taqwa': 'التقوى',
    'zuhd': 'الزهد',
  };

  static HadithCategoryMeta metaFor(String category, String languageCode) {
    final key = _canonicalKey(category);
    final normalizedLanguage = switch (languageCode) {
      'ar' => 'ar',
      'en' => 'en',
      'fr' => 'fr',
      'ru' => 'ru',
      _ => 'es',
    };

    if (key == null) {
      return HadithCategoryMeta(
        icon: Icons.auto_awesome_outlined,
        label: category,
        arabicLabel: _containsArabicText(category) ? category : '',
      );
    }

    final label = switch (normalizedLanguage) {
      'ar' => _arabicLabels[key] ?? category,
      'en' => _englishLabels[key] ?? category,
      'fr' => _frenchLabels[key] ?? category,
      'ru' => _russianLabels[key] ?? category,
      _ => _spanishLabels[key] ?? category,
    };

    return HadithCategoryMeta(
      icon: _icons[key] ?? Icons.auto_awesome_outlined,
      label: label,
      arabicLabel: _arabicLabels[key] ?? '',
    );
  }

  static bool _containsArabicText(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  static String? _canonicalKey(String category) {
    final value = category.trim().toLowerCase();
    if (value.isEmpty) return null;

    if (value == 'adab' || value.contains('ادب')) return 'adab';
    if (value.contains('amor de ala') ||
        value.contains('amor de alá') ||
        value.contains('love of allah') ||
        value.contains("amour d'allah") ||
        value.contains('любовь к аллаху') ||
        value.contains('محبة')) {
      return 'love_allah';
    }
    if (value.contains('autorreflexion') ||
        value.contains('autorreflexión') ||
        value.contains('self-reflection') ||
        value.contains('introspection') ||
        value.contains('самоанализ') ||
        value.contains('محاسبة')) {
      return 'self_reflection';
    }
    if (value.contains('ayuno') ||
        value.contains('fasting') ||
        value.contains('jeune') ||
        value.contains('jeûne') ||
        value.contains('пост') ||
        value.contains('صيام')) {
      return 'fasting';
    }
    if (value.contains('caracter') ||
        value.contains('carácter') ||
        value.contains('character') ||
        value.contains('caractere') ||
        value.contains('caractère') ||
        value.contains('нрав') ||
        value.contains('خلق')) {
      return 'character';
    }
    if (value.contains('caridad') ||
        value.contains('charity') ||
        value.contains('aumone') ||
        value.contains('aumône') ||
        value.contains('милостын') ||
        value.contains('صدقة')) {
      return 'charity';
    }
    if (value.contains('compasion') ||
        value.contains('compasión') ||
        value.contains('compassion') ||
        value.contains('милосерд') ||
        value.contains('رحمة')) {
      return 'compassion';
    }
    if (value.contains('conocimiento') ||
        value.contains('knowledge') ||
        value.contains('connaissance') ||
        value.contains('знани') ||
        value.contains('علم')) {
      return 'knowledge';
    }
    if (value.contains('constancia') ||
        value.contains('consistency') ||
        value.contains('constance') ||
        value.contains('постоянств') ||
        value.contains('ثبات')) {
      return 'consistency';
    }
    if (value.contains('corazon') ||
        value.contains('corazón') ||
        value.contains('heart') ||
        value.contains('coeur') ||
        value.contains('cœur') ||
        value.contains('сердц') ||
        value.contains('قلب')) {
      return 'heart';
    }
    if (value == 'dhikr' || value.contains('ذكر') || value.contains('зикр')) {
      return 'dhikr';
    }
    if (value == 'dua' ||
        value.contains('دعاء') ||
        value.contains('doua') ||
        value.contains('дуа')) {
      return 'dua';
    }
    if (value.contains('familia') ||
        value.contains('family') ||
        value.contains('famille') ||
        value.contains('семь') ||
        value.contains('اسرة') ||
        value.contains('أسرة')) {
      return 'family';
    }
    if (value.contains('fraternidad') ||
        value.contains('brotherhood') ||
        value.contains('fraternite') ||
        value.contains('fraternité') ||
        value.contains('братств') ||
        value.contains('اخوة') ||
        value.contains('أخوة')) {
      return 'brotherhood';
    }
    if (value.contains('gratitud') ||
        value.contains('gratitude') ||
        value.contains('благодар') ||
        value.contains('شكر')) {
      return 'gratitude';
    }
    if (value == 'haya' || value.contains('حياء') || value.contains('хая')) {
      return 'haya';
    }
    if (value.contains('honestidad') ||
        value.contains('honesty') ||
        value.contains('honnetete') ||
        value.contains('honnêteté') ||
        value.contains('честност') ||
        value.contains('امانة') ||
        value.contains('أمانة')) {
      return 'honesty';
    }
    if (value == 'ihsan' ||
        value.contains('احسان') ||
        value.contains('إحسان') ||
        value.contains('ихсан')) {
      return 'ihsan';
    }
    if (value.contains('intenciones') ||
        value.contains('intentions') ||
        value.contains('намерени') ||
        value.contains('نيات')) {
      return 'intentions';
    }
    if (value == 'istighfar' ||
        value.contains('استغفار') ||
        value.contains('истигфар')) {
      return 'istighfar';
    }
    if (value.contains('justicia') ||
        value.contains('justice') ||
        value.contains('справедлив') ||
        value.contains('عدل')) {
      return 'justice';
    }
    if (value.contains('lengua') ||
        value.contains('tongue') ||
        value.contains('langue') ||
        value.contains('язык') ||
        value.contains('لسان')) {
      return 'tongue';
    }
    if (value.contains('mezquita') ||
        value.contains('mosque') ||
        value.contains('mosquee') ||
        value.contains('mosquée') ||
        value.contains('мечет') ||
        value.contains('مسجد')) {
      return 'mosque';
    }
    if (value.contains('misericordia') ||
        value.contains('mercy') ||
        value.contains('милост') ||
        value.contains('misericorde')) {
      return 'mercy';
    }
    if (value.contains('paciencia') ||
        value.contains('patience') ||
        value.contains('терпен') ||
        value.contains('صبر')) {
      return 'patience';
    }
    if (value.contains('purificacion') ||
        value.contains('purificación') ||
        value.contains('purification') ||
        value.contains('очищен') ||
        value.contains('طهارة')) {
      return 'purification';
    }
    if (value == 'quran' ||
        value == 'coran' ||
        value.contains('коран') ||
        value.contains('قرآن')) {
      return 'quran';
    }
    if (value == 'rizq' ||
        value.contains('sustento') ||
        value.contains('provision') ||
        value.contains('subsistance') ||
        value.contains('удел') ||
        value.contains('رزق')) {
      return 'provision';
    }
    if (value == 'salah' ||
        value.contains('prayer') ||
        value.contains('priere') ||
        value.contains('prière') ||
        value.contains('намаз') ||
        value.contains('صلاة')) {
      return 'salah';
    }
    if (value.contains('seguridad') ||
        value.contains('safety') ||
        value.contains('securite') ||
        value.contains('sécurité') ||
        value.contains('безопас') ||
        value.contains('امان') ||
        value.contains('أمان')) {
      return 'safety';
    }
    if (value.contains('servicio') ||
        value.contains('service') ||
        value.contains('служени') ||
        value.contains('خدمة')) {
      return 'service';
    }
    if (value.contains('sinceridad') ||
        value.contains('sincerity') ||
        value.contains('sincerite') ||
        value.contains('sincérité') ||
        value.contains('искренност') ||
        value.contains('اخلاص') ||
        value.contains('إخلاص')) {
      return 'sincerity';
    }
    if (value == 'taqwa' || value.contains('تقوى') || value.contains('таква')) {
      return 'taqwa';
    }
    if (value == 'zuhd' || value.contains('زهد') || value.contains('зухд')) {
      return 'zuhd';
    }

    return null;
  }
}
