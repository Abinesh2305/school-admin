import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String studentName;
  final VoidCallback? onProfileTap;
  final VoidCallback onToggleTheme;
  final bool showProfileButton;

  const TopNavBar({
    super.key,
    required this.studentName,
    this.onProfileTap,
    required this.onToggleTheme,
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,

      // LEFT SIDE
      leading: showProfileButton
          ? IconButton(
              onPressed: onProfileTap,
              icon: const Icon(Icons.home, color: Colors.white),
            )
          : null,

      // CENTER
      title: LayoutBuilder(
        builder: (context, constraints) {
          return Text(
            studentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: constraints.maxWidth > 150 ? 20 : 16,
            ),
          );
        },
      ),
      centerTitle: true,

      // RIGHT SIDE
      actions: [
        IconButton(
          icon: Icon(
            brightness == Brightness.light ? Icons.dark_mode : Icons.light_mode,
            color: Colors.white,
          ),
          onPressed: onToggleTheme,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
