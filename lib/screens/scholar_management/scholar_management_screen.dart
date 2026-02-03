import 'package:flutter/material.dart';

// Tabs
import 'tabs/profile_tab.dart';
import 'tabs/update_tab.dart';
import 'tabs/shuffling_tab.dart';
import 'tabs/reports_tab.dart';
import 'tabs/groups_tab.dart';
import 'tabs/pre_admission_tab.dart';
import 'tabs/alumni_tab.dart';
import 'tabs/masters_tab.dart';
import 'tabs/photos_tab.dart';

class ScholarManagementScreen extends StatelessWidget {
  const ScholarManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 9,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Scholar Management'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Profile'),
              Tab(text: 'Update'),
              Tab(text: 'Shuffling'),
              Tab(text: 'Reports'),
              Tab(text: 'Groups'),
              Tab(text: 'Pre-Admission'),
              Tab(text: 'Alumni'),
              Tab(text: 'Masters'),
              Tab(text: 'Photos'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ProfileTab(),
            UpdateTab(),
            ScholarShufflingScreen(), 
            ReportsTab(),
            GroupsTab(),
            PreAdmissionTab(),
            AlumniTab(),
            MastersTab(),
            PhotosTab(),
          ],
        ),
      ),
    );
  }
}
