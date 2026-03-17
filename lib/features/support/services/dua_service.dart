import '../models/dua_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final duaServiceProvider = Provider((ref) => DuaService());

class DuaService {
  final List<Dua> _duas = [
    // Morning/Evening
    const Dua(
      title: 'Morning Remembrance (Alhamdulillah)',
      arabicText: 'الْحَمْدُ لِلَّهِ الَّذِي أَحْيَانَا بَعْدَ مَا أَمَاتَنَا وَإِلَيْهِ النُّشُورُ',
      transliteration: 'Alhamdu lillahil-ladhi ahyana ba\'da ma amatana wa ilayhin-nushur',
      translation: 'All praise is for Allah who gave us life after causing us to die, and to Him is the resurrection.',
      category: 'Daily',
      reference: 'Sahih al-Bukhari 6324',
    ),
    const Dua(
      title: 'Dua for Knowledge',
      arabicText: 'رَّبِّ زِدْنِي عِلْمًا',
      transliteration: 'Rabbi zidni \'ilma',
      translation: 'O my Lord, increase me in knowledge.',
      category: 'Daily',
      reference: 'Quran 20:114',
    ),
    const Dua(
      title: 'Dua for Traveling',
      arabicText: 'سُبْحَانَ الَّذِي سَخَّرَ لَنَا هَذَا وَمَا كُنَّا لَهُ مُقْرِنِينَ وَإِنَّا إِلَى رَبِّنَا لَمُنْقَلِبُونَ',
      transliteration: 'Subhanal-ladhi sakh-khara lana hadha wa ma kunna lahu muqrinina wa inna ila Rabbina lamunqalibun',
      translation: 'Glory is to Him Who has provided this for us, and we could never have had it by our efforts. Surely, unto our Lord we are returning.',
      category: 'Special',
      reference: 'Quran 43:13-14',
    ),
    const Dua(
      title: 'Dua for Parents',
      arabicText: 'رَّبِّ ارْحَمْهُمَا كَمَا رَبَّيَانِي صَغِيرًا',
      transliteration: 'Rabbi irhamhuma kama rabbayani saghira',
      translation: 'My Lord, have mercy upon them as they brought me up [when I was] small.',
      category: 'Special',
      reference: 'Quran 17:24',
    ),
  ];

  List<Dua> getByCategory(String category) {
    return _duas.where((dua) => dua.category == category).toList();
  }

  List<String> getCategories() {
    return _duas.map((dua) => dua.category).toSet().toList();
  }
}
