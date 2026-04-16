import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_theme.dart';

class ManufacturerGuideScreen extends StatelessWidget {
  const ManufacturerGuideScreen({
    super.key,
    required this.manufacturer,
  });

  final String manufacturer;

  @override
  Widget build(BuildContext context) {
    final tokens = QiblaThemes.current;
    final brand = _normalizeManufacturer(manufacturer);
    final steps = _stepsForBrand(brand);
    final isHuawei = brand.toLowerCase() == 'huawei';

    return Scaffold(
      backgroundColor: tokens.bgPage,
      appBar: AppBar(
        title: Text('Guía para $brand'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              'Cómo permitir que QiblaTime se ejecute en segundo plano',
              style: GoogleFonts.amiri(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: tokens.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'En algunos dispositivos $brand el sistema bloquea el adhan si la app no tiene permisos de batería y ejecución en segundo plano.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                height: 1.6,
                color: tokens.textSecondary,
              ),
            ),
            if (isHuawei) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tokens.primaryBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.primaryBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.settings_power,
                          color: tokens.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Abre los ajustes directamente',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => openAppSettings(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tokens.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Abrir ajustes de la app'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Luego ve a Batería > Inicio de aplicaciones y activa QiblaTime',
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: tokens.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...steps.indexed.map(
              (entry) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: tokens.bgSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: tokens.border),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.primaryBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: tokens.primaryBorder),
                      ),
                      child: Text(
                        '${entry.$1 + 1}',
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: tokens.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.$2,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          height: 1.6,
                          color: tokens.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _normalizeManufacturer(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return 'Android';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  List<String> _stepsForBrand(String brand) {
    switch (brand.toLowerCase()) {
      case 'huawei':
        return const [
          'Abre Ajustes > Batería > Inicio de aplicaciones.',
          'Busca QiblaTime y desactiva la gestión automática.',
          'Activa inicio automático, inicio secundario y ejecución en segundo plano.',
          'Después abre Ajustes > Apps > QiblaTime > Batería y permite actividad en segundo plano.',
        ];
      case 'samsung':
        return const [
          'Abre Ajustes > Batería y cuidado del dispositivo > Batería.',
          'Entra en Límites de uso en segundo plano.',
          'Asegúrate de que QiblaTime no esté en Apps en suspensión ni en suspensión profunda.',
          'Luego abre Ajustes > Apps > QiblaTime > Batería y selecciona Sin restricciones.',
        ];
      case 'xiaomi':
        return const [
          'Abre Ajustes > Apps > Administrar apps > QiblaTime.',
          'Entra en Ahorro de batería y selecciona Sin restricciones.',
          'Vuelve atrás, entra en Otros permisos y permite Inicio automático si aparece.',
          'En Seguridad > Batería, comprueba también que QiblaTime no esté limitado.',
        ];
      default:
        return const [
          'Abre Ajustes > Apps > QiblaTime.',
          'Busca la opción de Batería y permite ejecución en segundo plano o Sin restricciones.',
          'Si existe Inicio automático, Optimización de batería o Apps protegidas, habilita QiblaTime.',
          'Reinicia la app y vuelve a probar el sonido del adhan.',
        ];
    }
  }
}
