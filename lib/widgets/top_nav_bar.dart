import 'package:flutter/material.dart';

class TopNavBar extends StatelessWidget implements PreferredSizeWidget {
  final String title; // school name
  final VoidCallback? onHomeTap;
  final VoidCallback onToggleTheme;
  final VoidCallback? onSwitchTap; // 👈 NEW
  final bool showProfileButton;

  const TopNavBar({
    super.key,
    required this.title,
    this.onHomeTap,
    required this.onToggleTheme,
    this.onSwitchTap, // 👈 NEW
    this.showProfileButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return AppBar(
      backgroundColor: cs.primary,
      elevation: 0,

      // LEFT SIDE (HOME)
      leading: showProfileButton
          ? IconButton(
              onPressed: onHomeTap,
              icon: const Icon(Icons.home, color: Colors.white),
            )
          : null,

      // CENTER (SCHOOL NAME)
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),

          // 🔁 SWITCH ICON
          if (onSwitchTap != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onSwitchTap,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.sync_alt,
                  size: 18,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),

      centerTitle: true,

      // RIGHT SIDE (THEME)
      actions: [
        IconButton(
          icon: Icon(
            brightness == Brightness.light
                ? Icons.dark_mode
                : Icons.light_mode,
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
