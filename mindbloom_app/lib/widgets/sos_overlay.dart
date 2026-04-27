import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../config/theme.dart';

class SOSOverlay extends StatefulWidget {
  const SOSOverlay({super.key});

  @override
  State<SOSOverlay> createState() => _SOSOverlayState();
}

class _SOSOverlayState extends State<SOSOverlay> with TickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _breathAnimation = Tween<double>(begin: 80, end: 140).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  Future<void> _makeCall(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendWhatsApp() async {
    final uri = Uri.parse('https://wa.me/919999666555?text=I%20need%20help.%20Please%20connect%20me%20with%20a%20counselor.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You are not alone 💛',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Take a deep breath. Help is here.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Breathing circle
          AnimatedBuilder(
            animation: _breathAnimation,
            builder: (context, child) {
              return Container(
                width: _breathAnimation.value,
                height: _breathAnimation.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primaryPurple.withValues(alpha: 0.3),
                      AppColors.primaryPurple.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primaryPurple.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    _breathAnimation.value > 110 ? 'Breathe out' : 'Breathe in',
                    style: TextStyle(
                      color: AppColors.primaryPurple,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _quickAction(
                    context,
                    Icons.chat_bubble_rounded,
                    'WhatsApp',
                    AppColors.softGreen,
                    _sendWhatsApp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _quickAction(
                    context,
                    Icons.local_hospital_rounded,
                    'Nearby Doctor',
                    AppColors.calmBlue,
                    () {
                      Navigator.pop(context);
                      // Navigate to nearby
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Helpline numbers
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: AppConstants.helplines.length,
              itemBuilder: (context, index) {
                final helpline = AppConstants.helplines[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1AE53935),
                      child: Icon(Icons.phone, color: Colors.red, size: 20),
                    ),
                    title: Text(
                      helpline['name']!,
                      style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                    subtitle: Text(
                      '${helpline['number']} • ${helpline['available']}',
                      style: TextStyle(fontSize: 12, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.call, color: AppColors.softGreen),
                      onPressed: () => _makeCall(helpline['number']!),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
