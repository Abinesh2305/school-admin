import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../services/contacts_service.dart';
import 'contacts_list_screen.dart';
import '../core/utils/error_handler.dart';
import '../presentation/core/widgets/error_widget.dart' as error_widget;
import '../presentation/core/widgets/empty_state_widget.dart';
import '../presentation/core/widgets/loading_indicator.dart';
import '../presentation/core/widgets/staggered_list.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  bool loading = true;
  List<dynamic> categories = [];
  String? errorMessage;
  String? errorCode;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    setState(() {
      loading = true;
      errorMessage = null;
      errorCode = null;
    });

    try {
      final res = await ContactsService().getContactsList();
      if (!mounted) return;

      final result = ErrorHandler.handleApiResponse(res);
      
      if (result.success) {
        final data = result.data;
        final categoriesList = ErrorHandler.extractList(data);
        
        setState(() {
          loading = false;
          categories = categoriesList;
          errorMessage = null;
          errorCode = null;
        });
      } else {
        setState(() {
          loading = false;
          categories = [];
          errorMessage = result.message;
          errorCode = result.errorCode;
        });
        
        ErrorHandler.logError(
          context: 'ContactsScreen.loadCategories',
          error: result.message,
          additionalInfo: {'errorCode': result.errorCode},
        );
      }
    } catch (e, stackTrace) {
      if (!mounted) return;
      
      final message = ErrorHandler.getErrorMessage(e);
      final code = ErrorHandler.getErrorCode(e);
      
      ErrorHandler.logError(
        context: 'ContactsScreen.loadCategories',
        error: e,
        stackTrace: stackTrace,
      );
      
      setState(() {
        loading = false;
        categories = [];
        errorMessage = message;
        errorCode = code;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(t.schoolContacts)),
      body: loading
          ? LoadingIndicator(message: 'Loading contacts...')
          : errorMessage != null
              ? error_widget.CustomErrorWidget(
                  message: errorMessage!,
                  errorCode: errorCode,
                  onRetry: loadCategories,
                )
              : categories.isEmpty
                  ? EmptyStateWidget(
                      message: t.noContacts,
                      icon: Icons.contacts_outlined,
                      actionLabel: 'Retry',
                      onAction: loadCategories,
                    )
                  : RefreshIndicator(
                      onRefresh: loadCategories,
                      color: cs.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: categories.length,
                        itemBuilder: (context, index) {
                          final c = categories[index];

                          return AnimatedListItem(
                            index: index,
                            child: Card(
                              elevation: 2,
                              color: cs.surface,
                              margin: const EdgeInsets.only(bottom: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            ContactsListScreen(
                                          categoryName: c['name']?.toString() ?? 'Unknown',
                                          contacts: ErrorHandler.extractList(c, key: 'contacts_list'),
                                        ),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          return SlideTransition(
                                            position: Tween<Offset>(
                                              begin: const Offset(1.0, 0.0),
                                              end: Offset.zero,
                                            ).animate(CurvedAnimation(
                                              parent: animation,
                                              curve: Curves.easeInOutCubic,
                                            )),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: ListTile(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    title: Text(
                                      c['name']?.toString() ?? 'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                        color: cs.primary,
                                      ),
                                    ),
                                    trailing: Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: cs.onSurface.withOpacity(0.5),
                                    ),
                                  ),
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
