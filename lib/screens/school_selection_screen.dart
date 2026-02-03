import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../main.dart';

// Constants

// Storage
import '../infrastructure/storage/auth_storage_service.dart';

class SchoolSelectionScreen extends StatefulWidget {
  final List schools;
  final String loginChallengeToken;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleLanguage;

  const SchoolSelectionScreen({
    super.key,
    required this.schools,
    required this.loginChallengeToken,
    required this.onToggleTheme,
    required this.onToggleLanguage,
  });

  @override
  State<SchoolSelectionScreen> createState() =>
      _SchoolSelectionScreenState();
}

class _SchoolSelectionScreenState
    extends State<SchoolSelectionScreen> {
  int? _loadingIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select School'),
        centerTitle: true,
      ),

      body: ListView.separated(
        itemCount: widget.schools.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1),

        itemBuilder: (context, index) {
          final school = widget.schools[index];
          final isLoading = _loadingIndex == index;

          final String name =
              school['displayName'] ??
              school['name'] ??
              'Unknown School';

          final String code =
              school['code']?.toString() ?? '';

          return ListTile(
            enabled: _loadingIndex == null,

            title: Text(
              isLoading ? 'Logging in…' : name,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),

            subtitle: Text(code),

            trailing: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),

            onTap: _loadingIndex != null
                ? null
                : () => _handleSchoolSelect(
                      index,
                      school,
                    ),
          );
        },
      ),
    );
  }

  // =====================================================
  // 🔐 HANDLE SCHOOL SELECTION
  // =====================================================

  Future<void> _handleSchoolSelect(
    int index,
    Map school,
  ) async {
    setState(() => _loadingIndex = index);

    try {
      final result =
          await AuthService().completeSchoolLogin(
        loginChallengeToken: widget.loginChallengeToken,
        schoolId: school['schoolId'],
      );

      if (!mounted) return;

      // ✅ Correct success check
      if (result['success'] == true) {

        debugPrint("✅ SCHOOL LOGIN SUCCESS");

        // Debug stored auth
        AuthStorage.debugPrintAuth();

        // Go to main screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainNavigationScreen(
              onToggleTheme: widget.onToggleTheme,
              onToggleLanguage: widget.onToggleLanguage,
            ),
          ),
          (route) => false,
        );

      } else {
        _showError(
          result['message'] ?? 'Login failed',
        );
      }
    } catch (e) {
      debugPrint("❌ SCHOOL SELECT ERROR: $e");

      _showError('Something went wrong');
    } finally {
      if (mounted) {
        setState(() => _loadingIndex = null);
      }
    }
  }

  // =====================================================
  // ❌ ERROR UI
  // =====================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
