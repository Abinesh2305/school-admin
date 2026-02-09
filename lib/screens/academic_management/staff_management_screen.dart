import 'package:flutter/material.dart';

import 'tabs/profile_tab.dart';
import 'tabs/ex_employee_tab.dart';
import 'tabs/candidate_tab.dart';
import 'tabs/masters_tab.dart';
import 'tabs/photos_tab.dart';

class StaffManagementScreen extends StatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  State<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends State<StaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _controller;

  final tabs = const [
    Tab(text: "Profile"),
    Tab(text: "Ex-Employee"),
    Tab(text: "Candidate"),
    Tab(text: "Masters"),
    Tab(text: "Photos"),
  ];

  @override
  void initState() {
    super.initState();

    _controller = TabController(
      length: tabs.length,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Staff Management"),
        bottom: TabBar(
          controller: _controller,
          tabs: tabs,
          isScrollable: true,
        ),
      ),
      body: TabBarView(
        controller: _controller,
        children: const [
          ProfileTab(),
          ExEmployeeTab(),
          CandidateTab(),
          MastersTab(),
          PhotosTab(),
        ],
      ),
    );
  }
}
