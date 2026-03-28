import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SupportTab extends StatelessWidget {
  const SupportTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sadaqah Jariyah', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 64),
            const SizedBox(height: 24),
            Text(
              'Apoya el desarrollo',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Qibla Time es y siempre será gratuita para la ummah. Tu apoyo nos ayuda a cubrir los costes de servidores y API, y a seguir añadiendo funciones útiles.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textLight, height: 1.5),
            ),
            const SizedBox(height: 32),
            _buildSupportOption(
              context,
              'Ver un anuncio voluntario',
              'Una forma rápida y gratuita de ayudarnos.',
              Icons.play_circle_outline,
              Colors.orange,
              () => _simulateAd(context),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              context,
              'Sadaqah única',
              'Haz una pequeña donación para el mantenimiento.',
              Icons.volunteer_activism,
              AppTheme.primaryGreen,
              () => _showDonationInfo(context),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              context,
              'Suscripción mensual',
              'Apoyo continuo para el crecimiento del proyecto.',
              Icons.auto_awesome,
              AppTheme.accentGold,
              () => _showDonationInfo(context),
            ),
            const SizedBox(height: 48),
            const Divider(),
            const SizedBox(height: 24),
            Text(
              '¿A dónde va mi apoyo?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              '• Mantenimiento de servidores de oración.\n• Actualización de la biblioteca de duas.\n• Desarrollo de nuevas funciones offline.\n• Sin publicidad intrusiva, nunca.',
              style: TextStyle(color: AppTheme.textLight, height: 1.8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _simulateAd(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Gracias'),
        content: const Text('Has apoyado a Qibla Time viendo este "espacio" publicitario. ¡Que Allah te recompense!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _showDonationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Próximamente'),
        content: const Text('Estamos configurando una pasarela de pago segura para donaciones de sadaqah. ¡Gracias por tu intención!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }
}
