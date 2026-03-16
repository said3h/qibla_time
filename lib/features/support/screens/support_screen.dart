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
         title: const Text('Support QiblaTime', style: TextStyle(fontWeight: FontWeight.bold)),
       ),
       body: ListView(
         padding: const EdgeInsets.all(24.0),
         children: [
           const Icon(Icons.favorite, color: Colors.red, size: 80),
           const SizedBox(height: 24),
           const Text(
             'JazakAllah Khair!',
             textAlign: TextAlign.center,
             style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
           ),
           const SizedBox(height: 16),
           const Text(
             'QiblaTime is completely free and contains absolutely zero intrusive ads.\n\nDeveloping and maintaining accurate astronomical algorithms and testing on multiple devices takes considerable time and effort.',
             textAlign: TextAlign.center,
             style: TextStyle(fontSize: 16, color: AppTheme.textDark, height: 1.5),
           ),
           const SizedBox(height: 48),
           const Text(
             'How you can help:',
             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark),
           ),
           const SizedBox(height: 16),
           _buildSupportCard(
             icon: Icons.star_rate,
             title: 'Rate the App',
             description: 'Leave a 5-star review on the App Store / Play Store. It helps others find us!',
             onTap: () {
               // Usually requires the specific App ID
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('App store link coming soon!')));
             },
           ),
           _buildSupportCard(
             icon: Icons.share,
             title: 'Share with Friends',
             description: 'Recommend QiblaTime to your family and friends.',
             onTap: () {
                // Implementing this would use the `share_plus` package
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sharing feature coming soon!')));
             },
           ),
           _buildSupportCard(
             icon: Icons.coffee,
             title: 'Sadaqah (Make a Donation)',
             description: 'Support development costs directly.',
             onTap: () => _launchUrl('https://example.com/donate'), // Placeholder for real donation link (e.g., BuyMeACoffee or similar platform)
           ),
           const SizedBox(height: 24),
           const Divider(),
           const SizedBox(height: 16),
           const Text(
             '"Charity does not decrease wealth."\n— Prophet Muhammad (PBUH)',
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
                    Text(description, style: const TextStyle(color: AppTheme.textLight, fontSize: 14)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textLight)
            ],
          ),
        ),
      ),
    );
  }
}
