import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../l10n/app_localizations.dart';
import '../main.dart';
import '../screens/profile_screen.dart';
import 'alerts_submenu_screen.dart';
import 'staff_attendance_screen.dart';

class MenuScreen extends StatelessWidget {
  final VoidCallback onLogout;

  const MenuScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Icons.person_outline, 'label': t.profile, 'action': 'profile'},
      {
        'icon': Icons.notifications_none,
        'label': 'Noticeboard',
        'action': 'noticeboard'
      },
      {
        'icon': Icons.warning_amber_outlined,
        'label': 'Alerts',
        'action': 'alerts'
      },
      {
        'icon': Icons.calendar_month,
        'label': t.attendance,
        'action': 'attendance'
      },
    ];

    return Scaffold(
      appBar: AppBar(title: Text(t.menuTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: isTamil ? 0.63 : 0.85,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return _buildMenuItem(
              icon: item['icon'],
              label: item['label'],
              colorScheme: cs,
              isTamil: isTamil,
              onTap: () => _handleMenuAction(context, item['action']),
            );
          },
        ),
      ),
    );
  }

  /* ================= MENU ACTION HANDLER ================= */

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(onLogout: onLogout),
          ),
        );
        break;

      case 'noticeboard':
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              onToggleTheme: () {},
              onToggleLanguage: () {},
              openNotificationTab: true,
            ),
          ),
          (_) => false,
        );
        break;

      case 'alerts':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AlertsSubmenuScreen()),
        );
        break;


      case 'attendance':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StaffAttendanceScreen(),
          ),
        );
        break;

    }
  }

  /* ================= MENU TILE ================= */

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
    required bool isTamil,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: colorScheme.primary),
              const SizedBox(height: 8),
              AutoSizeText(
                label,
                maxLines: 2,
                minFontSize: 10,
                maxFontSize: 12,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: const TextStyle(
                fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
