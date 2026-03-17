import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart';
import '../../prayer_times/services/prayer_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../prayer_times/services/adhan_manager.dart';
import '../screens/support_tab.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool adhanFajr = true;
  bool adhanDhuhr = true;
  bool adhanAsr = true;
  bool adhanMaghrib = true;
  bool adhanIsha = true;
  String selectedAdhan = 'adhan_makkah';
  int timeOffset = 0;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      adhanFajr = prefs.getBool('adhan_fajr') ?? true;
      adhanDhuhr = prefs.getBool('adhan_dhuhr') ?? true;
      adhanAsr = prefs.getBool('adhan_asr') ?? true;
      adhanMaghrib = prefs.getBool('adhan_maghrib') ?? true;
      adhanIsha = prefs.getBool('adhan_isha') ?? true;
      selectedAdhan = prefs.getString('selected_adhan') ?? 'adhan_makkah';
      timeOffset = prefs.getInt('time_offset') ?? 0;
    });
  }

  Future<void> _toggleSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    
    // Reschedule adhans immediately
    ref.read(adhanManagerProvider).scheduleTodayAdhans();
    
    setState(() {
      switch (key) {
        case 'adhan_fajr': adhanFajr = value; break;
        case 'adhan_dhuhr': adhanDhuhr = value; break;
        case 'adhan_asr': adhanAsr = value; break;
        case 'adhan_maghrib': adhanMaghrib = value; break;
        case 'adhan_isha': adhanIsha = value; break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader('Adhan Notifications'),
          _buildAdhanTile('Fajr', adhanFajr, (v) => _toggleSetting('adhan_fajr', v)),
          _buildAdhanTile('Dhuhr', adhanDhuhr, (v) => _toggleSetting('adhan_dhuhr', v)),
          _buildAdhanTile('Asr', adhanAsr, (v) => _toggleSetting('adhan_asr', v)),
          _buildAdhanTile('Maghrib', adhanMaghrib, (v) => _toggleSetting('adhan_maghrib', v)),
          _buildAdhanTile('Isha', adhanIsha, (v) => _toggleSetting('adhan_isha', v)),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Prayer Calculation'),
          _buildCalculationMethodSelector(),
          _buildMadhabSelector(),
          _buildRegionalAdjustmentTile(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Adhan Sound Library'),
          _buildAdhanSoundLibrary(),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Quran & Content'),
          ListTile(
            title: const Text('Quran Language'),
            subtitle: const Text('Spanish (Asad)'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // Show language picker
            },
          ),
          
          const SizedBox(height: 24),
          _buildSectionHeader('Estrategia y Apoyo'),
          ListTile(
            title: const Text('Sadaqah Jariyah'),
            subtitle: const Text('Apoya el desarrollo de QiblaTime'),
            leading: const Icon(Icons.favorite, color: Colors.redAccent),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SupportTab()));
            },
          ),

          const SizedBox(height: 24),
          _buildSectionHeader('App Info'),
          ListTile(
            title: const Text('Version'),
            trailing: const Text('1.1.0 (PRO)'),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationMethodSelector() {
    return ListTile(
      title: const Text('Calculation Method'),
      subtitle: const Text('Muslim World League (Default)'),
      trailing: const Icon(Icons.more_vert),
      onTap: () async {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        
        showModalBottomSheet(
          context: context,
          builder: (context) => ListView(
            shrinkWrap: true,
            children: CalculationMethod.values.map((method) => ListTile(
              title: Text(method.name.replaceAll('_', ' ').toUpperCase()),
              onTap: () async {
                await prefs.setInt(AppConstants.keyCalculationMethod, method.index);
                ref.invalidate(calculationMethodProvider);
                if (mounted) Navigator.pop(context);
                setState(() {});
              },
            )).toList(),
          ),
        );
      },
    );
  }

  Widget _buildMadhabSelector() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snapshot) {
        final isHanafi = snapshot.data?.getBool('madhab_hanafi') ?? false;
        return SwitchListTile(
          title: const Text('Madhab (Asr calculation)'),
          subtitle: Text(isHanafi ? 'Hanafi' : 'Shafi (Standard)'),
          value: isHanafi,
          activeColor: AppTheme.primaryGreen,
          onChanged: (value) async {
            await snapshot.data?.setBool('madhab_hanafi', value);
            ref.invalidate(madhabProvider);
            setState(() {});
          },
        );
      }
    );
  }

  Widget _buildAdhanSoundLibrary() {
    final sounds = {
      'adhan_makkah': 'Makkah (Al-Haram)',
      'adhan_madinah': 'Madinah (An-Nabawi)',
      'adhan_alaqsa': 'Al-Aqsa (Jerusalén)',
      'adhan_istanbul': 'Estambul (Sultan Ahmed)',
      'adhan_cairo': 'El Cairo (Egipto)',
    };

    return Column(
      children: sounds.entries.map((entry) {
        final isSelected = selectedAdhan == entry.key;
        return ListTile(
          title: Text(entry.value),
          leading: Radio<String>(
            value: entry.key,
            groupValue: selectedAdhan,
            activeColor: AppTheme.primaryGreen,
            onChanged: (value) async {
              if (value != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('selected_adhan', value);
                setState(() => selectedAdhan = value);
                ref.read(adhanManagerProvider).scheduleTodayAdhans();
              }
            },
          ),
          trailing: IconButton(
            icon: const Icon(Icons.play_arrow, color: AppTheme.primaryGreen),
            onPressed: () {
              // Preview sound logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Reproduciendo vista previa de ${entry.value}...')),
              );
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRegionalAdjustmentTile() {
    return ListTile(
      title: const Text('Ajuste Regional (Buffer)'),
      subtitle: Text('$timeOffset minutos agregados a cada rezo'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _updateOffset(timeOffset - 1),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _updateOffset(timeOffset + 1),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOffset(int newValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('time_offset', newValue);
    ref.invalidate(prayerTimesProvider);
    setState(() => timeOffset = newValue);
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
      ),
    );
  }

  Widget _buildAdhanTile(String name, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      title: Text(name),
      secondary: const Icon(Icons.notifications_active_outlined),
      value: value,
      activeColor: AppTheme.primaryGreen,
      onChanged: onChanged,
    );
  }
}
