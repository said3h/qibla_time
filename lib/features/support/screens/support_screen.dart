import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: AppTheme.backgroundWhite,
       appBar: AppBar(
         title: const Text('Apoya Qibla Time', style: TextStyle(fontWeight: FontWeight.bold)),
       ),
       body: ListView(
         padding: const EdgeInsets.all(24.0),
         children: [
           const Icon(Icons.favorite, color: Colors.red, size: 80),
           const SizedBox(height: 24),
            Text(
              'Jazak Allahu khayran',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
           const SizedBox(height: 16),
            Text(
              'Qibla Time es completamente gratuita y no tiene anuncios intrusivos.\n\nDesarrollar y mantener algoritmos astronómicos precisos, además de probar la app en varios dispositivos, requiere tiempo y dedicación.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: AppTheme.textDark, height: 1.5),
            ),
           const SizedBox(height: 48),
            Text(
              'Cómo puedes ayudar:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
           const SizedBox(height: 16),
           _buildSupportCard(
             icon: Icons.star_rate,
             title: 'Valora la app',
             description: 'Deja una reseña de 5 estrellas en App Store o Play Store. Ayuda a que más personas nos encuentren.',
             onTap: () {
               // Usually requires the specific App ID
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El enlace a la tienda estará disponible próximamente.')));
             },
           ),
           _buildSupportCard(
             icon: Icons.share,
             title: 'Compártela con tus amigos',
             description: 'Recomienda Qibla Time a tu familia y a tus amistades.',
             onTap: () {
                // Implementing this would use the `share_plus` package
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('La opción para compartir estará disponible próximamente.')));
             },
           ),
           _buildSupportCard(
             icon: Icons.coffee,
             title: 'Sadaqah (haz una donación)',
             description: 'Ayuda directamente a cubrir los costes de desarrollo.',
             onTap: () => _launchUrl('https://example.com/donate'), // Placeholder for real donation link (e.g., BuyMeACoffee or similar platform)
           ),
           const SizedBox(height: 24),
           const Divider(),
           const SizedBox(height: 16),
            Text(
              '"La caridad no disminuye la riqueza."\n— Profeta Muhammad (la paz y las bendiciones sean con él)',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: AppTheme.textLight),
           )
         ],
       ),
    );
  }

  Widget _buildSupportCard({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(
                   color: AppTheme.primaryGreen.withOpacity(0.1),
                   shape: BoxShape.circle,
                 ),
                 child: Icon(icon, color: AppTheme.primaryGreen, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                     Text(description, style: TextStyle(color: AppTheme.textLight, fontSize: 14)),
                  ],
                ),
              ),
               Icon(Icons.chevron_right, color: AppTheme.textLight)
            ],
          ),
        ),
      ),
    );
  }
}

