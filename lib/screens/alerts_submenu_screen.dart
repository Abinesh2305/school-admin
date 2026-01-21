import 'package:flutter/material.dart';
import 'post_management_screen.dart';
import 'homework_management_screen.dart';
import 'staff_posts_management_screen.dart';

class AlertsSubmenuScreen extends StatelessWidget {
  const AlertsSubmenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isTamil = Localizations.localeOf(context).languageCode == 'ta';

    final List<Map<String, dynamic>> menuItems = [
      {
        'icon': Icons.post_add,
        'label': 'Post',
        'action': 'post',
        'color': Colors.blue,
      },
      {
        'icon': Icons.book_outlined,
        'label': 'Homework',
        'action': 'homework',
        'color': Colors.green,
      },
      {
        'icon': Icons.people_outline,
        'label': 'Staff Posts',
        'action': 'staff_posts',
        'color': Colors.orange,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: InkWell(
                onTap: () {
                  switch (item['action']) {
                    case 'post':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PostManagementScreen(),
                        ),
                      );
                      break;
                    case 'homework':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HomeworkManagementScreen(),
                        ),
                      );
                      break;
                    case 'staff_posts':
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StaffPostsManagementScreen(),
                        ),
                      );
                      break;
                  }
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'],
                        size: 48,
                        color: item['color'],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['label'],
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

