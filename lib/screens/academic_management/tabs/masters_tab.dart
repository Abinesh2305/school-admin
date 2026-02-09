import 'package:flutter/material.dart';

class MastersTab extends StatelessWidget {
  const MastersTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        ListTile(title: Text("Department Master")),
        ListTile(title: Text("Subject Master")),
        ListTile(title: Text("Designation Master")),
      ],
    );
  }
}
