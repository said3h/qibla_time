import 'package:flutter/material.dart';

class DuaCategoryMeta {
  const DuaCategoryMeta({
    required this.icon,
    required this.label,
    required this.hint,
    required this.arabicLabel,
  });

  final IconData icon;
  final String label;
  final String hint;
  final String arabicLabel;
}

class DuaLocalePresentation {
  static const _categoryIcons = <String, IconData>{
    'morning': Icons.wb_sunny_outlined,
    'night': Icons.nights_stay_outlined,
    'sleep': Icons.bedtime_outlined,
    'wudu': Icons.water_outlined,
    'after_prayer': Icons.access_time_outlined,
    'zikr': Icons.auto_awesome_outlined,
    'travel': Icons.connecting_airports_outlined,
    'food': Icons.restaurant_outlined,
    'sickness': Icons.local_hospital_outlined,
    'protection': Icons.shield_outlined,
    'repentance': Icons.refresh_outlined,
    'mosque': Icons.mosque_outlined,
    'rain': Icons.water_drop_outlined,
    'stress': Icons.self_improvement_outlined,
    'gratitude': Icons.favorite_border_outlined,
    'parents': Icons.family_restroom_outlined,
    'hajj': Icons.route_outlined,
    'waking_up': Icons.wb_twilight_outlined,
    'clothing': Icons.checkroom_outlined,
    'home': Icons.home_outlined,
    'witr': Icons.nights_stay_outlined,
    'funeral_grief': Icons.volunteer_activism_outlined,
    'weather_nature': Icons.air_outlined,
    'fasting': Icons.no_food_outlined,
    'social_manners': Icons.handshake_outlined,
    'marriage_family': Icons.diversity_1_outlined,
    'gatherings': Icons.groups_outlined,
  };

  static const _categoryArabicLabels = <String, String>{
    'morning': 'الصباح',
    'night': 'المساء',
    'sleep': 'النوم',
    'wudu': 'الوضوء',
    'after_prayer': 'بعد الصلاة',
    'zikr': 'الذكر',
    'travel': 'السفر',
    'food': 'الطعام',
    'sickness': 'المرض',
    'protection': 'التحصين',
    'repentance': 'التوبة',
    'mosque': 'المسجد',
    'rain': 'المطر',
    'stress': 'الكرب',
    'gratitude': 'الشكر',
    'parents': 'العائلة',
    'hajj': 'الحج',
    'waking_up': 'الاستيقاظ',
    'clothing': 'اللباس',
    'home': 'المنزل',
    'witr': 'الوتر',
    'funeral_grief': 'الجنائز والمواساة',
    'weather_nature': 'الطقس والطبيعة',
    'fasting': 'الصيام',
    'social_manners': 'آداب التعامل',
    'marriage_family': 'الزواج والأسرة',
    'gatherings': 'المجالس',
  };

  static const _categorySpanishLabels = <String, String>{
    'morning': 'Mañana',
    'night': 'Noche',
    'sleep': 'Sueño',
    'wudu': 'Ablución',
    'after_prayer': 'Después de orar',
    'zikr': 'Dhikr',
    'travel': 'Viaje',
    'food': 'Comida',
    'sickness': 'Enfermedad',
    'protection': 'Protección',
    'repentance': 'Arrepentimiento',
    'mosque': 'Mezquita',
    'rain': 'Lluvia',
    'stress': 'Dificultad',
    'gratitude': 'Gratitud',
    'parents': 'Familia',
    'hajj': 'Hajj y Umrah',
    'waking_up': 'Al despertar',
    'clothing': 'Ropa',
    'home': 'Hogar',
    'witr': 'Witr',
    'funeral_grief': 'Duelo y funeral',
    'weather_nature': 'Clima y naturaleza',
    'fasting': 'Ayuno',
    'social_manners': 'Buenos modales',
    'marriage_family': 'Matrimonio y familia',
    'gatherings': 'Reuniones',
  };

  static const _categorySpanishHints = <String, String>{
    'morning': 'Inicio del día',
    'night': 'Cierre del día',
    'sleep': 'Antes de dormir',
    'wudu': 'Wudu y pureza',
    'after_prayer': 'Tras cada oración',
    'zikr': 'Alabanza y recuerdo',
    'travel': 'Salida y trayecto',
    'food': 'Antes y después',
    'sickness': 'Curación y visita',
    'protection': 'Refugio y cuidado',
    'repentance': 'Perdón y vuelta',
    'mosque': 'Entrar y salir',
    'rain': 'Durante la lluvia',
    'stress': 'Tristeza y carga',
    'gratitude': 'Agradecimiento',
    'parents': 'Padres e hijos',
    'hajj': 'Peregrinación',
    'waking_up': 'Al despertar',
    'clothing': 'Vestirse y ropa',
    'home': 'Entrada y hogar',
    'witr': 'Oración nocturna',
    'funeral_grief': 'Consuelo y duelo',
    'weather_nature': 'Viento, trueno y luna',
    'fasting': 'Iftar y ayuno',
    'social_manners': 'Cortesía diaria',
    'marriage_family': 'Bendiciones familiares',
    'gatherings': 'Cierre de reuniones',
  };

  static const _categoryEnglishLabels = <String, String>{
    'morning': 'Morning',
    'night': 'Night',
    'sleep': 'Sleep',
    'wudu': 'Wudu',
    'after_prayer': 'After prayer',
    'zikr': 'Dhikr',
    'travel': 'Travel',
    'food': 'Food',
    'sickness': 'Illness',
    'protection': 'Protection',
    'repentance': 'Repentance',
    'mosque': 'Mosque',
    'rain': 'Rain',
    'stress': 'Difficulty',
    'gratitude': 'Gratitude',
    'parents': 'Family',
    'hajj': 'Hajj and Umrah',
    'waking_up': 'Waking up',
    'clothing': 'Clothing',
    'home': 'Home',
    'witr': 'Witr',
    'funeral_grief': 'Funeral and grief',
    'weather_nature': 'Weather and nature',
    'fasting': 'Fasting',
    'social_manners': 'Social manners',
    'marriage_family': 'Marriage and family',
    'gatherings': 'Gatherings',
  };

  static const _categoryEnglishHints = <String, String>{
    'morning': 'Start of the day',
    'night': 'Close of the day',
    'sleep': 'Before sleeping',
    'wudu': 'Wudu and purity',
    'after_prayer': 'After each prayer',
    'zikr': 'Remembrance and praise',
    'travel': 'Departure and journey',
    'food': 'Before and after eating',
    'sickness': 'Healing and visits',
    'protection': 'Refuge and care',
    'repentance': 'Forgiveness and return',
    'mosque': 'Entering and leaving',
    'rain': 'During rainfall',
    'stress': 'Sadness and burden',
    'gratitude': 'Thankfulness',
    'parents': 'Parents and children',
    'hajj': 'Pilgrimage',
    'waking_up': 'After waking',
    'clothing': 'Dressing and garments',
    'home': 'Entering the home',
    'witr': 'Night prayer',
    'funeral_grief': 'Condolence and grief',
    'weather_nature': 'Wind, thunder and moon',
    'fasting': 'Iftar and fasting',
    'social_manners': 'Everyday courtesy',
    'marriage_family': 'Family blessings',
    'gatherings': 'Closing gatherings',
  };

  static const _categoryTurkishLabels = <String, String>{
    'morning': 'Sabah',
    'night': 'Gece',
    'sleep': 'Uyku',
    'wudu': 'Abdest',
    'after_prayer': 'Namazdan sonra',
    'zikr': 'Zikir',
    'travel': 'Yolculuk',
    'food': 'Yemek',
    'sickness': 'Hastalık',
    'protection': 'Korunma',
    'repentance': 'Tövbe',
    'mosque': 'Mescit',
    'rain': 'Yağmur',
    'stress': 'Sıkıntı',
    'gratitude': 'Şükür',
    'parents': 'Aile',
    'hajj': 'Hac ve Umre',
    'waking_up': 'Uyanınca',
    'clothing': 'Giyim',
    'home': 'Ev',
    'witr': 'Vitir',
    'funeral_grief': 'Cenaze ve taziye',
    'weather_nature': 'Hava ve tabiat',
    'fasting': 'Oruç',
    'social_manners': 'Güzel ahlak',
    'marriage_family': 'Evlilik ve aile',
    'gatherings': 'Meclisler',
  };

  static const _categoryTurkishHints = <String, String>{
    'morning': 'Günün başlangıcı',
    'night': 'Günün sonu',
    'sleep': 'Uyumadan önce',
    'wudu': 'Abdest ve temizlik',
    'after_prayer': 'Her namazdan sonra',
    'zikr': 'Hamd ve zikir',
    'travel': 'Yola çıkış ve yolculuk',
    'food': 'Yemekten önce ve sonra',
    'sickness': 'Şifa ve ziyaret',
    'protection': 'Sığınma ve korunma',
    'repentance': 'Bağışlanma ve dönüş',
    'mosque': 'Mescide giriş ve çıkış',
    'rain': 'Yağmur sırasında',
    'stress': 'Hüzün ve yük',
    'gratitude': 'Şükretmek',
    'parents': 'Anne baba ve çocuklar',
    'hajj': 'Hac ve umre',
    'waking_up': 'Uyanma vakti',
    'clothing': 'Giyinme ve elbise',
    'home': 'Eve giriş',
    'witr': 'Gece namazı',
    'funeral_grief': 'Taziye ve hüzün',
    'weather_nature': 'Rüzgar, gök gürültüsü ve ay',
    'fasting': 'İftar ve oruç',
    'social_manners': 'Günlük nezaket',
    'marriage_family': 'Aile bereketi',
    'gatherings': 'Meclis kapanışı',
  };

  static const _categoryFrenchLabels = <String, String>{
    'morning': 'Matin',
    'night': 'Nuit',
    'sleep': 'Sommeil',
    'wudu': 'Wudu',
    'after_prayer': 'Après la prière',
    'zikr': 'Dhikr',
    'travel': 'Voyage',
    'food': 'Repas',
    'sickness': 'Maladie',
    'protection': 'Protection',
    'repentance': 'Repentance',
    'mosque': 'Mosquée',
    'rain': 'Pluie',
    'stress': 'Difficulté',
    'gratitude': 'Gratitude',
    'parents': 'Famille',
    'hajj': 'Hajj et Omra',
    'waking_up': 'Réveil',
    'clothing': 'Vêtements',
    'home': 'Foyer',
    'witr': 'Witr',
    'funeral_grief': 'Funérailles et deuil',
    'weather_nature': 'Temps et nature',
    'fasting': 'Jeûne',
    'social_manners': 'Bonnes manières',
    'marriage_family': 'Mariage et famille',
    'gatherings': 'Assemblées',
  };

  static const _categoryFrenchHints = <String, String>{
    'morning': 'Début de la journée',
    'night': 'Fin de la journée',
    'sleep': 'Avant de dormir',
    'wudu': 'Wudu et pureté',
    'after_prayer': 'Après chaque prière',
    'zikr': 'Rappel et louange',
    'travel': 'Départ et trajet',
    'food': 'Avant et après le repas',
    'sickness': 'Guérison et visite',
    'protection': 'Refuge et protection',
    'repentance': 'Pardon et retour',
    'mosque': 'Entrer et sortir',
    'rain': 'Pendant la pluie',
    'stress': 'Tristesse et épreuve',
    'gratitude': 'Reconnaissance',
    'parents': 'Parents et enfants',
    'hajj': 'Pèlerinage',
    'waking_up': 'Après le réveil',
    'clothing': 'S’habiller',
    'home': 'Entrer chez soi',
    'witr': 'Prière nocturne',
    'funeral_grief': 'Condoléances et deuil',
    'weather_nature': 'Vent, tonnerre et lune',
    'fasting': 'Iftar et jeûne',
    'social_manners': 'Courtoisie quotidienne',
    'marriage_family': 'Bénédictions familiales',
    'gatherings': 'Fin des assemblées',
  };

  static const _categoryGermanLabels = <String, String>{
    'morning': 'Morgen',
    'night': 'Nacht',
    'sleep': 'Schlaf',
    'wudu': 'Wudu',
    'after_prayer': 'Nach dem Gebet',
    'zikr': 'Dhikr',
    'travel': 'Reise',
    'food': 'Essen',
    'sickness': 'Krankheit',
    'protection': 'Schutz',
    'repentance': 'Reue',
    'mosque': 'Moschee',
    'rain': 'Regen',
    'stress': 'Belastung',
    'gratitude': 'Dankbarkeit',
    'parents': 'Familie',
    'hajj': 'Hadsch und Umra',
    'waking_up': 'Aufwachen',
    'clothing': 'Kleidung',
    'home': 'Zuhause',
    'witr': 'Witr',
    'funeral_grief': 'Trauer und Bestattung',
    'weather_nature': 'Wetter und Natur',
    'fasting': 'Fasten',
    'social_manners': 'Gutes Benehmen',
    'marriage_family': 'Ehe und Familie',
    'gatherings': 'Versammlungen',
  };

  static const _categoryGermanHints = <String, String>{
    'morning': 'Beginn des Tages',
    'night': 'Ende des Tages',
    'sleep': 'Vor dem Schlafen',
    'wudu': 'Wudu und Reinheit',
    'after_prayer': 'Nach jedem Gebet',
    'zikr': 'Gedenken und Lobpreis',
    'travel': 'Aufbruch und Reise',
    'food': 'Vor und nach dem Essen',
    'sickness': 'Heilung und Besuch',
    'protection': 'Zuflucht und Schutz',
    'repentance': 'Vergebung und Umkehr',
    'mosque': 'Beim Betreten und Verlassen',
    'rain': 'Waehrend des Regens',
    'stress': 'Traurigkeit und Belastung',
    'gratitude': 'Dank und Lob',
    'parents': 'Eltern und Kinder',
    'hajj': 'Pilgerfahrt',
    'waking_up': 'Nach dem Aufwachen',
    'clothing': 'Kleiden und Gewand',
    'home': 'Betreten des Hauses',
    'witr': 'Nachtgebet',
    'funeral_grief': 'Beileid und Trauer',
    'weather_nature': 'Wind, Donner und Mond',
    'fasting': 'Iftar und Fasten',
    'social_manners': 'Alltägliche Höflichkeit',
    'marriage_family': 'Familiärer Segen',
    'gatherings': 'Abschluss von Versammlungen',
  };

  static const _categoryItalianLabels = <String, String>{
    'morning': 'Mattina',
    'night': 'Sera',
    'sleep': 'Sonno',
    'wudu': 'Wudu',
    'after_prayer': 'Dopo la preghiera',
    'zikr': 'Dhikr',
    'travel': 'Viaggio',
    'food': 'Cibo',
    'sickness': 'Malattia',
    'protection': 'Protezione',
    'repentance': 'Pentimento',
    'mosque': 'Moschea',
    'rain': 'Pioggia',
    'stress': 'Difficolta',
    'gratitude': 'Gratitudine',
    'parents': 'Famiglia',
    'hajj': 'Hajj e Umrah',
    'waking_up': 'Risveglio',
    'clothing': 'Abbigliamento',
    'home': 'Casa',
    'witr': 'Witr',
    'funeral_grief': 'Funerale e lutto',
    'weather_nature': 'Meteo e natura',
    'fasting': 'Digiuno',
    'social_manners': 'Buone maniere',
    'marriage_family': 'Matrimonio e famiglia',
    'gatherings': 'Riunioni',
  };

  static const _categoryItalianHints = <String, String>{
    'morning': 'Inizio della giornata',
    'night': 'Fine della giornata',
    'sleep': 'Prima di dormire',
    'wudu': 'Wudu e purezza',
    'after_prayer': 'Dopo ogni preghiera',
    'zikr': 'Ricordo e lode',
    'travel': 'Partenza e percorso',
    'food': 'Prima e dopo aver mangiato',
    'sickness': 'Guarigione e visita',
    'protection': 'Rifugio e custodia',
    'repentance': 'Perdono e ritorno',
    'mosque': 'Entrare e uscire',
    'rain': 'Durante la pioggia',
    'stress': 'Tristezza e peso',
    'gratitude': 'Ringraziamento',
    'parents': 'Genitori e figli',
    'hajj': 'Pellegrinaggio',
    'waking_up': 'Dopo il risveglio',
    'clothing': 'Vestirsi e abiti',
    'home': 'Entrare in casa',
    'witr': 'Preghiera notturna',
    'funeral_grief': 'Condoglianze e lutto',
    'weather_nature': 'Vento, tuono e luna',
    'fasting': 'Iftar e digiuno',
    'social_manners': 'Cortesia quotidiana',
    'marriage_family': 'Benedizioni familiari',
    'gatherings': 'Chiusura delle riunioni',
  };

  static const _categoryPortugueseLabels = <String, String>{
    'morning': 'Manhã',
    'night': 'Noite',
    'sleep': 'Sono',
    'wudu': 'Wudu',
    'after_prayer': 'Após a oração',
    'zikr': 'Dhikr',
    'travel': 'Viagem',
    'food': 'Comida',
    'sickness': 'Doença',
    'protection': 'Proteção',
    'repentance': 'Arrependimento',
    'mosque': 'Mesquita',
    'rain': 'Chuva',
    'stress': 'Dificuldade',
    'gratitude': 'Gratidão',
    'parents': 'Família',
    'hajj': 'Hajj e Umrah',
    'waking_up': 'Ao acordar',
    'clothing': 'Roupa',
    'home': 'Casa',
    'witr': 'Witr',
    'funeral_grief': 'Funeral e luto',
    'weather_nature': 'Clima e natureza',
    'fasting': 'Jejum',
    'social_manners': 'Boas maneiras',
    'marriage_family': 'Casamento e família',
    'gatherings': 'Reuniões',
  };

  static const _categoryPortugueseHints = <String, String>{
    'morning': 'Início do dia',
    'night': 'Fim do dia',
    'sleep': 'Antes de dormir',
    'wudu': 'Wudu e pureza',
    'after_prayer': 'Após cada oração',
    'zikr': 'Recordação e louvor',
    'travel': 'Partida e viagem',
    'food': 'Antes e depois de comer',
    'sickness': 'Cura e visita',
    'protection': 'Refúgio e proteção',
    'repentance': 'Perdão e retorno',
    'mosque': 'Entrar e sair',
    'rain': 'Durante a chuva',
    'stress': 'Tristeza e peso',
    'gratitude': 'Agradecimento',
    'parents': 'Pais e filhos',
    'hajj': 'Peregrinação',
    'waking_up': 'Depois de acordar',
    'clothing': 'Vestir e roupa',
    'home': 'Entrar em casa',
    'witr': 'Oração noturna',
    'funeral_grief': 'Consolo e luto',
    'weather_nature': 'Vento, trovão e lua',
    'fasting': 'Iftar e jejum',
    'social_manners': 'Cortesia diária',
    'marriage_family': 'Bênçãos familiares',
    'gatherings': 'Encerrar reuniões',
  };

  static const _categoryDutchLabels = <String, String>{
    'morning': 'Ochtend',
    'night': 'Nacht',
    'sleep': 'Slaap',
    'wudu': 'Wudu',
    'after_prayer': 'Na het gebed',
    'zikr': 'Dhikr',
    'travel': 'Reizen',
    'food': 'Eten',
    'sickness': 'Ziekte',
    'protection': 'Bescherming',
    'repentance': 'Berouw',
    'mosque': 'Moskee',
    'rain': 'Regen',
    'stress': 'Moeilijkheid',
    'gratitude': 'Dankbaarheid',
    'parents': 'Familie',
    'hajj': 'Hadj en Omra',
    'waking_up': 'Wakker worden',
    'clothing': 'Kleding',
    'home': 'Thuis',
    'witr': 'Witr',
    'funeral_grief': 'Begrafenis en rouw',
    'weather_nature': 'Weer en natuur',
    'fasting': 'Vasten',
    'social_manners': 'Goede manieren',
    'marriage_family': 'Huwelijk en familie',
    'gatherings': 'Bijeenkomsten',
  };

  static const _categoryDutchHints = <String, String>{
    'morning': 'Begin van de dag',
    'night': 'Einde van de dag',
    'sleep': 'Voor het slapen',
    'wudu': 'Wudu en zuiverheid',
    'after_prayer': 'Na elk gebed',
    'zikr': 'Gedenken en lofprijzing',
    'travel': 'Vertrek en reis',
    'food': 'Voor en na het eten',
    'sickness': 'Genezing en bezoek',
    'protection': 'Toevlucht en bescherming',
    'repentance': 'Vergeving en terugkeer',
    'mosque': 'Bij het betreden en verlaten',
    'rain': 'Tijdens de regen',
    'stress': 'Verdriet en last',
    'gratitude': 'Dank en lof',
    'parents': 'Ouders en kinderen',
    'hajj': 'Bedevaart',
    'waking_up': 'Na het wakker worden',
    'clothing': 'Aankleden en kleding',
    'home': 'Het huis binnengaan',
    'witr': 'Nachtgebed',
    'funeral_grief': 'Troost en rouw',
    'weather_nature': 'Wind, donder en maan',
    'fasting': 'Iftar en vasten',
    'social_manners': 'Dagelijkse hoffelijkheid',
    'marriage_family': 'Familiezegeningen',
    'gatherings': 'Bijeenkomsten afsluiten',
  };

  static const _categoryRussianLabels = <String, String>{
    'morning': 'Утро',
    'night': 'Вечер',
    'sleep': 'Сон',
    'wudu': 'Вуду',
    'after_prayer': 'После намаза',
    'zikr': 'Зикр',
    'travel': 'Путешествие',
    'food': 'Еда',
    'sickness': 'Болезнь',
    'protection': 'Защита',
    'repentance': 'Покаяние',
    'mosque': 'Мечеть',
    'rain': 'Дождь',
    'stress': 'Трудность',
    'gratitude': 'Благодарность',
    'parents': 'Родители',
    'hajj': 'Хадж и умра',
    'waking_up': 'Пробуждение',
    'clothing': 'Одежда',
    'home': 'Дом',
    'witr': 'Витр',
    'funeral_grief': 'Похороны и утешение',
    'weather_nature': 'Погода и природа',
    'fasting': 'Пост',
    'social_manners': 'Адаб общения',
    'marriage_family': 'Брак и семья',
    'gatherings': 'Собрания',
  };

  static const _categoryRussianHints = <String, String>{
    'morning': 'Начало дня',
    'night': 'Завершение дня',
    'sleep': 'Перед сном',
    'wudu': 'Вуду и очищение',
    'after_prayer': 'После каждого намаза',
    'zikr': 'Поминание и восхваление',
    'travel': 'Выход и дорога',
    'food': 'До и после еды',
    'sickness': 'Исцеление и посещение больного',
    'protection': 'Прибежище и защита',
    'repentance': 'Прощение и возвращение',
    'mosque': 'Вход и выход из мечети',
    'rain': 'Во время дождя',
    'stress': 'Печаль и тягость',
    'gratitude': 'Благодарность и хвала',
    'parents': 'Родители и дети',
    'hajj': 'Паломничество',
    'waking_up': 'После пробуждения',
    'clothing': 'Одежда и одевание',
    'home': 'Вход в дом',
    'witr': 'Ночная молитва',
    'funeral_grief': 'Соболезнование и скорбь',
    'weather_nature': 'Ветер, гром и луна',
    'fasting': 'Ифтар и пост',
    'social_manners': 'Повседневная вежливость',
    'marriage_family': 'Семейные благословения',
    'gatherings': 'Завершение собраний',
  };

  static const _categoryIndonesianLabels = <String, String>{
    'morning': 'Pagi',
    'night': 'Malam',
    'sleep': 'Tidur',
    'wudu': 'Wudu',
    'after_prayer': 'Setelah Sholat',
    'zikr': 'Zikir',
    'travel': 'Perjalanan',
    'food': 'Makanan',
    'sickness': 'Sakit',
    'protection': 'Perlindungan',
    'repentance': 'Taubat',
    'mosque': 'Masjid',
    'rain': 'Hujan',
    'stress': 'Stres',
    'gratitude': 'Syukur',
    'parents': 'Orang Tua',
    'hajj': 'Haji',
    'waking_up': 'Bangun tidur',
    'clothing': 'Pakaian',
    'home': 'Rumah',
    'witr': 'Witir',
    'funeral_grief': 'Jenazah dan duka',
    'weather_nature': 'Cuaca dan alam',
    'fasting': 'Puasa',
    'social_manners': 'Adab sosial',
    'marriage_family': 'Pernikahan dan keluarga',
    'gatherings': 'Majelis',
  };

  static const _categoryIndonesianHints = <String, String>{
    'morning': 'Awal hari',
    'night': 'Akhir hari',
    'sleep': 'Sebelum tidur',
    'wudu': 'Wudu dan kesucian',
    'after_prayer': 'Setelah setiap sholat',
    'zikr': 'Pujian dan zikir',
    'travel': 'Keberangkatan dan perjalanan',
    'food': 'Sebelum dan sesudah makan',
    'sickness': 'Penyembuhan dan kunjungan',
    'protection': 'Perlindungan dan penjagaan',
    'repentance': 'Pengampunan dan taubat',
    'mosque': 'Masuk dan keluar masjid',
    'rain': 'Saat hujan turun',
    'stress': 'Kesedihan dan beban',
    'gratitude': 'Rasa syukur',
    'parents': 'Orang tua dan anak',
    'hajj': 'Ibadah haji',
    'waking_up': 'Setelah bangun',
    'clothing': 'Berpakaian dan pakaian',
    'home': 'Masuk rumah',
    'witr': 'Salat malam',
    'funeral_grief': 'Takziah dan duka',
    'weather_nature': 'Angin, petir, dan bulan',
    'fasting': 'Iftar dan puasa',
    'social_manners': 'Kesopanan sehari-hari',
    'marriage_family': 'Berkah keluarga',
    'gatherings': 'Penutup majelis',
  };

  static const _categoryArabicHints = <String, String>{
    'morning': 'بداية اليوم',
    'night': 'ختام اليوم',
    'sleep': 'قبل النوم',
    'wudu': 'الوضوء والطهارة',
    'after_prayer': 'بعد كل صلاة',
    'zikr': 'التسبيح والذكر',
    'travel': 'الخروج والطريق',
    'food': 'قبل الطعام وبعده',
    'sickness': 'الشفاء والزيارة',
    'protection': 'التحصين والرعاية',
    'repentance': 'الاستغفار والرجوع',
    'mosque': 'الدخول والخروج',
    'rain': 'وقت المطر',
    'stress': 'الحزن والضيق',
    'gratitude': 'الحمد والشكر',
    'parents': 'الوالدان والأبناء',
    'hajj': 'النسك والمناسك',
    'waking_up': 'بعد الاستيقاظ',
    'clothing': 'اللباس والثوب',
    'home': 'دخول المنزل',
    'witr': 'قيام الليل',
    'funeral_grief': 'العزاء والحزن',
    'weather_nature': 'الريح والرعد والهلال',
    'fasting': 'الإفطار والصيام',
    'social_manners': 'آداب يومية',
    'marriage_family': 'بركات الأسرة',
    'gatherings': 'ختام المجالس',
  };

  static String normalizeLanguageCode(String languageCode) {
    return switch (languageCode) {
      'ar' => 'ar',
      'de' => 'de',
      'en' => 'en',
      'fr' => 'fr',
      'id' => 'id',
      'it' => 'it',
      'nl' => 'nl',
      'pt' => 'pt',
      'ru' => 'ru',
      'tr' => 'tr',
      _ => 'es',
    };
  }

  static bool isArabicOnly(String languageCode) {
    return normalizeLanguageCode(languageCode) == 'ar';
  }

  static bool containsArabicText(String value) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
  }

  static DuaCategoryMeta categoryMetaFor(String key, String languageCode) {
    final normalized = normalizeLanguageCode(languageCode);
    final icon = _categoryIcons[key] ?? Icons.auto_awesome_outlined;
    final arabicLabel = _categoryArabicLabels[key] ?? 'قسم';

    return switch (normalized) {
      'it' => DuaCategoryMeta(
          icon: icon,
          label:
              _categoryItalianLabels[key] ?? _categoryEnglishLabels[key] ?? key,
          hint: _categoryItalianHints[key] ?? 'Categoria',
          arabicLabel: arabicLabel,
        ),
      'pt' => DuaCategoryMeta(
          icon: icon,
          label: _categoryPortugueseLabels[key] ??
              _categoryEnglishLabels[key] ??
              key,
          hint: _categoryPortugueseHints[key] ?? 'Categoria',
          arabicLabel: arabicLabel,
        ),
      'ru' => DuaCategoryMeta(
          icon: icon,
          label:
              _categoryRussianLabels[key] ?? _categoryEnglishLabels[key] ?? key,
          hint: _categoryRussianHints[key] ?? 'Категория',
          arabicLabel: arabicLabel,
        ),
      'de' => DuaCategoryMeta(
          icon: icon,
          label:
              _categoryGermanLabels[key] ?? _categoryEnglishLabels[key] ?? key,
          hint: _categoryGermanHints[key] ?? 'Kategorie',
          arabicLabel: arabicLabel,
        ),
      'id' => DuaCategoryMeta(
          icon: icon,
          label: _categoryIndonesianLabels[key] ??
              _categoryEnglishLabels[key] ??
              key,
          hint: _categoryIndonesianHints[key] ?? 'Kategori',
          arabicLabel: arabicLabel,
        ),
      'nl' => DuaCategoryMeta(
          icon: icon,
          label:
              _categoryDutchLabels[key] ?? _categoryEnglishLabels[key] ?? key,
          hint: _categoryDutchHints[key] ?? 'Categorie',
          arabicLabel: arabicLabel,
        ),
      'en' => DuaCategoryMeta(
          icon: icon,
          label: _categoryEnglishLabels[key] ?? key,
          hint: _categoryEnglishHints[key] ?? 'Category',
          arabicLabel: arabicLabel,
        ),
      'tr' => DuaCategoryMeta(
          icon: icon,
          label:
              _categoryTurkishLabels[key] ?? _categoryEnglishLabels[key] ?? key,
          hint: _categoryTurkishHints[key] ?? 'Kategori',
          arabicLabel: arabicLabel,
        ),
      'fr' => DuaCategoryMeta(
          icon: icon,
          label: _categoryFrenchLabels[key] ?? key,
          hint: _categoryFrenchHints[key] ?? 'Catégorie',
          arabicLabel: arabicLabel,
        ),
      'ar' => DuaCategoryMeta(
          icon: icon,
          label: _categoryArabicLabels[key] ?? arabicLabel,
          hint: _categoryArabicHints[key] ?? 'قسم',
          arabicLabel: arabicLabel,
        ),
      _ => DuaCategoryMeta(
          icon: icon,
          label: _categorySpanishLabels[key] ?? key,
          hint: _categorySpanishHints[key] ?? 'Categoría',
          arabicLabel: arabicLabel,
        ),
    };
  }

  static String screenTitle(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'Dua and adhkar',
      'it' => 'Dua e adhkar',
      'pt' => 'Dua e adhkar',
      'ru' => 'Дуа и азкар',
      'fr' => "Dou'a et adhkar",
      'ar' => 'الدعاء والأذكار',
      'de' => 'Dua und Adhkar',
      'id' => 'Doa dan Adhkar',
      'nl' => 'Dua en adhkar',
      'tr' => 'Dua ve ezkâr',
      _ => 'Dua y adhkar',
    };
  }

  static String screenSubtitle(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'Daily invocations to accompany your day',
      'it' => 'Invocazioni quotidiane per accompagnare la tua giornata',
      'pt' => 'Invocações diárias para acompanhar o dia',
      'ru' => 'Ежедневные мольбы на каждый день',
      'fr' => 'Invocations quotidiennes pour accompagner votre journée',
      'ar' => 'مختارات يومية للذكر والدعاء',
      'de' => 'Tägliche Bittgebete für deinen Tag',
      'id' => 'Doa harian untuk menemanimu',
      'nl' => 'Dagelijkse smeekbeden om je dag te begeleiden',
      'tr' => 'Gününe eşlik eden günlük dualar',
      _ => 'Invocaciones diarias para acompañar tu día',
    };
  }

  static String introBody(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' =>
        'A curated collection of duas and adhkar for everyday life. Tap a category to see all available duas.',
      'it' =>
        'Una raccolta curata di dua e adhkar per la vita quotidiana. Tocca una categoria per vedere tutte le dua disponibili.',
      'pt' =>
        'Uma coleção cuidada de dua e adhkar para o dia a dia. Toque numa categoria para ver todas as duas disponíveis.',
      'ru' =>
        'Подборка дуа и азкар для повседневной жизни. Нажмите на категорию, чтобы увидеть все доступные дуа.',
      'fr' =>
        "Une collection soignée de dou'a et d'adhkar pour le quotidien. Touchez une catégorie pour voir toutes les dou'a disponibles.",
      'de' =>
        'Eine sorgfältig zusammengestellte Sammlung von Duas und Adhkar für den Alltag. Tippe auf eine Kategorie, um alle verfügbaren Duas zu sehen.',
      'id' =>
        'Koleksi doa dan adhkar pilihan untuk kehidupan sehari-hari. Ketuk kategori untuk melihat semua doa yang tersedia.',
      'nl' =>
        "Een zorgvuldige verzameling dua's en adhkar voor het dagelijks leven. Tik op een categorie om alle beschikbare dua's te zien.",
      'tr' =>
        'Günlük hayat için özenle seçilmiş dua ve ezkâr koleksiyonu. Tüm duaları görmek için bir kategoriye dokun.',
      'ar' =>
        'مجموعة مختارة من الأدعية والأذكار لليوم والليلة. افتح أي قسم لرؤية جميع الأدعية المتاحة.',
      _ =>
        'Una colección cuidada de duas y adhkar para el día a día. Toca una categoría para ver todas las duas disponibles.',
    };
  }

  static String searchHint(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'Search dua or adhkar',
      'it' => 'Cerca dua o adhkar',
      'pt' => 'Pesquisar dua ou adhkar',
      'ru' => 'Искать дуа или азкар',
      'de' => 'Dua oder Adhkar suchen',
      'fr' => "Rechercher une dou'a ou un dhikr",
      'ar' => 'ابحث عن دعاء أو ذكر',
      'id' => 'Cari doa atau adhkar',
      'nl' => 'Zoek dua of adhkar',
      'tr' => 'Dua veya zikir ara',
      _ => 'Buscar dua o adhkar',
    };
  }

  static String clearSearchTooltip(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'Clear search',
      'it' => 'Cancella ricerca',
      'pt' => 'Limpar pesquisa',
      'ru' => 'Очистить поиск',
      'de' => 'Suche löschen',
      'fr' => 'Effacer la recherche',
      'ar' => 'مسح البحث',
      'id' => 'Hapus pencarian',
      'nl' => 'Zoekopdracht wissen',
      'tr' => 'Aramayı temizle',
      _ => 'Limpiar búsqueda',
    };
  }

  static String resultsMessage(
    String languageCode,
    String query,
    int count,
  ) {
    final normalized = normalizeLanguageCode(languageCode);
    if (count == 0) {
      return switch (normalized) {
        'en' => 'No results found for "$query".',
        'it' => 'Nessun risultato per "$query".',
        'pt' => 'Nenhum resultado para "$query".',
        'ru' => 'По запросу "$query" ничего не найдено.',
        'de' => 'Keine Ergebnisse für "$query".',
        'fr' => 'Aucun résultat pour "$query".',
        'ar' => 'لم نجد نتائج لعبارة "$query".',
        'id' => 'Tidak ada hasil untuk "$query".',
        'nl' => 'Geen resultaten gevonden voor "$query".',
        'tr' => '"$query" için sonuç bulunamadı.',
        _ => 'No encontramos resultados para "$query".',
      };
    }

    return switch (normalized) {
      'en' => '$count result${count == 1 ? '' : 's'} for "$query".',
      'it' => '$count risultat${count == 1 ? 'o' : 'i'} per "$query".',
      'pt' => '$count resultado${count == 1 ? '' : 's'} para "$query".',
      'ru' => 'Найдено: $count по запросу "$query".',
      'de' => '$count Ergebnis${count == 1 ? '' : 'se'} für "$query".',
      'fr' => '$count résultat${count == 1 ? '' : 's'} pour "$query".',
      'ar' => '$count نتيجة لعبارة "$query".',
      'id' => '$count hasil untuk "$query".',
      'nl' => '$count resultaat${count == 1 ? '' : 's'} voor "$query".',
      'tr' => '"$query" için $count sonuç.',
      _ => '$count resultado${count == 1 ? '' : 's'} para "$query".',
    };
  }

  static String noResultsTitle(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'No results',
      'it' => 'Nessun risultato',
      'pt' => 'Sem resultados',
      'ru' => 'Ничего не найдено',
      'de' => 'Keine Ergebnisse',
      'fr' => 'Aucun résultat',
      'ar' => 'لا توجد نتائج',
      'id' => 'Tidak ada hasil',
      'nl' => 'Geen resultaten',
      'tr' => 'Sonuç yok',
      _ => 'Sin resultados',
    };
  }

  static String noResultsBody(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'Try words like rain, travel, protection, sleep or gratitude.',
      'it' =>
        'Prova parole come pioggia, viaggio, protezione, sonno o gratitudine.',
      'pt' =>
        'Experimente palavras como chuva, viagem, proteção, sono ou gratidão.',
      'ru' =>
        'Попробуйте слова вроде дождь, путешествие, защита, сон или благодарность.',
      'de' =>
        'Versuche Begriffe wie Regen, Reise, Schutz, Schlaf oder Dankbarkeit.',
      'fr' =>
        'Essayez des mots comme pluie, voyage, protection, sommeil ou gratitude.',
      'ar' => 'جرّب كلمات مثل المطر أو السفر أو التحصين أو النوم أو الشكر.',
      'id' =>
        'Coba kata-kata seperti hujan, perjalanan, perlindungan, tidur atau rasa syukur.',
      'nl' =>
        'Probeer woorden als regen, reizen, bescherming, slaap of dankbaarheid.',
      'tr' => 'Yağmur, yolculuk, korunma, uyku veya şükür gibi kelimeler dene.',
      _ =>
        'Prueba con palabras como lluvia, viaje, protección, sueño o gratitud.',
    };
  }

  static String categoriesLabel(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'CATEGORIES',
      'it' => 'CATEGORIE',
      'pt' => 'CATEGORIAS',
      'ru' => 'КАТЕГОРИИ',
      'de' => 'KATEGORIEN',
      'fr' => 'CATÉGORIES',
      'ar' => 'الأقسام',
      'id' => 'KATEGORI',
      'nl' => 'CATEGORIEËN',
      'tr' => 'KATEGORİLER',
      _ => 'CATEGORÍAS',
    };
  }

  static String featuredLabel(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'en' => 'FEATURED',
      'it' => 'IN EVIDENZA',
      'pt' => 'EM DESTAQUE',
      'ru' => 'РЕКОМЕНДОВАННОЕ',
      'de' => 'EMPFOHLEN',
      'fr' => 'À LA UNE',
      'ar' => 'مختارات',
      'id' => 'UNGGULAN',
      'nl' => 'AANBEVOLEN',
      'tr' => 'ÖNE ÇIKANLAR',
      _ => 'DESTACADAS',
    };
  }

  static String categoryCountLabel(
    String languageCode,
    int count,
    String hint,
  ) {
    return switch (normalizeLanguageCode(languageCode)) {
      'it' => '$count adhkar · $hint',
      'pt' => '$count adhkar · $hint',
      'ru' => '$count азкар · $hint',
      'de' => '$count Adhkar · $hint',
      'en' => '$count adhkar · $hint',
      'fr' => '$count adhkar · $hint',
      'ar' => '$count ذكر · $hint',
      'id' => '$count adhkar · $hint',
      'nl' => '$count adhkar · $hint',
      'tr' => '$count ezkâr · $hint',
      _ => '$count adhkar · $hint',
    };
  }

  static String loadError(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'it' => 'Non siamo riusciti a caricare il contenuto delle dua.',
      'pt' => 'Não foi possível carregar o conteúdo das duas.',
      'ru' => 'Не удалось загрузить содержимое дуа.',
      'de' => 'Der Inhalt der Duas konnte nicht geladen werden.',
      'en' => 'We could not load the dua content.',
      'fr' => "Nous n'avons pas pu charger le contenu des dou'a.",
      'ar' => 'تعذر علينا تحميل محتوى الدعاء.',
      'id' => 'Konten Doa tidak dapat dimuat.',
      'nl' => 'We konden de dua-inhoud niet laden.',
      'tr' => 'Dua içeriği yüklenemedi.',
      _ => 'No hemos podido cargar el contenido de Dua.',
    };
  }

  static String emptyCategory(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'it' => 'Non ci sono dua in questa categoria.',
      'pt' => 'Não há duas nesta categoria.',
      'ru' => 'В этой категории нет дуа',
      'de' => 'Keine Duas in dieser Kategorie',
      'en' => 'There are no duas in this category.',
      'fr' => "Il n'y a aucune dou'a dans cette catégorie.",
      'ar' => 'لا توجد أدعية في هذا القسم.',
      'id' => 'Tidak ada doa dalam kategori ini',
      'nl' => "Er zijn geen dua's in deze categorie.",
      'tr' => 'Bu kategoride dua yok.',
      _ => 'No hay duas en esta categoría',
    };
  }

  static String detailLoadError(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'it' => 'Errore nel caricamento delle dua.',
      'pt' => 'Erro ao carregar as duas.',
      'ru' => 'Ошибка при загрузке дуа',
      'de' => 'Fehler beim Laden der Duas',
      'en' => 'Error loading duas.',
      'fr' => "Erreur lors du chargement des dou'a.",
      'ar' => 'حدث خطأ أثناء تحميل الأدعية.',
      'id' => 'Gagal memuat doa',
      'nl' => "Fout bij het laden van dua's.",
      'tr' => 'Dualar yüklenirken hata oluştu.',
      _ => 'Error al cargar las duas',
    };
  }

  static String repeatCountLabel(String languageCode, int count) {
    return switch (normalizeLanguageCode(languageCode)) {
      'it' => '$count volte',
      'pt' => '$count vezes',
      'ru' => '$count раз',
      'de' => '$count Mal',
      'en' => '$count times',
      'fr' => '$count fois',
      'ar' => '$count مرات',
      'id' => '$count kali',
      'nl' => '$count keer',
      'tr' => '$count kez',
      _ => '$count veces',
    };
  }

  static String shareTooltip(String languageCode) {
    return switch (normalizeLanguageCode(languageCode)) {
      'es' => 'Compartir',
      'it' => 'Condividi',
      'pt' => 'Partilhar',
      'ru' => 'Поделиться',
      'de' => 'Teilen',
      'en' => 'Share',
      'fr' => 'Partager',
      'ar' => 'مشاركة',
      'id' => 'Bagikan',
      'nl' => 'Delen',
      'tr' => 'Paylaş',
      _ => 'Share', // neutral English fallback for any unhandled locale
    };
  }
}
