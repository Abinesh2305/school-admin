import 'package:flutter/material.dart';
import 'package:html_editor_enhanced/html_editor.dart';

/// Rich text editor widget for message compose areas with enhanced features
/// Fully responsive and mobile-optimized with overflow-safe toolbar
class RichTextEditor extends StatefulWidget {
  final HtmlEditorController controller;
  final String? hint;
  final String? label;
  final double? height;
  final bool readOnly;
  final Function(String)? onChanged;
  final bool enableImageUpload;
  final bool enableFileUpload;
  final Function(String)? onImageUpload;
  final Function(String)? onFileUpload;

  const RichTextEditor({
    super.key,
    required this.controller,
    this.hint,
    this.label,
    this.height,
    this.readOnly = false,
    this.onChanged,
    this.enableImageUpload = true,
    this.enableFileUpload = true,
    this.onImageUpload,
    this.onFileUpload,
  });

  @override
  State<RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<RichTextEditor> {
  // Helper to determine if device is mobile
  bool _isMobile(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width < 600; // Mobile breakpoint
  }

  // Helper to determine if device is in portrait mode
  bool _isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Calculate responsive toolbar height
  double _getToolbarHeight(BuildContext context) {
    if (_isMobile(context)) {
      return _isPortrait(context) ? 140 : 100; // More space in portrait
    }
    return 80; // Desktop: compact toolbar
  }

  // Calculate responsive editor content height
  double _getEditorContentHeight(BuildContext context, double totalHeight) {
    final toolbarHeight = _getToolbarHeight(context);
    return totalHeight - toolbarHeight;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = _isMobile(context);
    final totalHeight = widget.height ?? 300;
    final toolbarHeight = _getToolbarHeight(context);
    final editorHeight = _getEditorContentHeight(context, totalHeight);

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHighest.withOpacity(0.3)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label != null) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(16, 12, 16, isMobile ? 8 : 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label!,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (!widget.readOnly && !isMobile) ...[
                    // Desktop: show quick format buttons in label
                    IconButton(
                      icon: const Icon(Icons.format_bold, size: 18),
                      tooltip: 'Bold',
                      onPressed: () => widget.controller.execCommand('bold'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic, size: 18),
                      tooltip: 'Italic',
                      onPressed: () => widget.controller.execCommand('italic'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underlined, size: 18),
                      tooltip: 'Underline',
                      onPressed: () =>
                          widget.controller.execCommand('underline'),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ],
              ),
            ),
          ],
          // Editor with responsive toolbar
          ClipRRect(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            child: SizedBox(
              height: totalHeight,
              child: HtmlEditor(
                controller: widget.controller,
                htmlEditorOptions: HtmlEditorOptions(
                  hint: widget.hint ?? 'Enter your message...',
                  shouldEnsureVisible: true,
                  darkMode: isDark,
                  autoAdjustHeight: false,
                  adjustHeightForKeyboard: true,
                  initialText: '',
                ),
                htmlToolbarOptions: widget.readOnly
                    ? const HtmlToolbarOptions(
                        toolbarPosition: ToolbarPosition.custom,
                      )
                    : _buildResponsiveToolbar(
                        context,
                        isMobile,
                        isDark,
                        colorScheme,
                      ),
                otherOptions: OtherOptions(
                  height: editorHeight,
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    border: Border.fromBorderSide(BorderSide.none),
                  ),
                ),

                callbacks: Callbacks(
                  onInit: () {
                    // Editor initialized
                  },
                  onChangeContent: (String? changed) {
                    if (widget.onChanged != null && changed != null) {
                      widget.onChanged!(changed);
                    }
                  },
                  onEnter: () {
                    // Enter key pressed
                  },
                  onFocus: () {
                    // Editor focused
                  },
                  onBlur: () {
                    // Editor blurred
                  },
                  onKeyDown: (int? keyCode) {
                    // Key pressed
                  },
                  onKeyUp: (int? keyCode) {
                    // Key released
                  },
                  onMouseDown: () {
                    // Mouse down
                  },
                  onMouseUp: () {
                    // Mouse up
                  },
                  onPaste: () {
                    // Paste event
                  },
                  onScroll: () {
                    // Scroll event
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build responsive toolbar configuration based on device type
  /// Uses minimal configuration to avoid html_editor_enhanced v2.7.1 toggle button bug
  HtmlToolbarOptions _buildResponsiveToolbar(
    BuildContext context,
    bool isMobile,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    // Use minimal toolbar with default button configurations only
    // This avoids the toggle button assertion error in html_editor_enhanced v2.7.1
    return HtmlToolbarOptions(
      defaultToolbarButtons: [
        // Use only default configurations - no custom parameters
        const StyleButtons(),
        const FontButtons(),
        const ColorButtons(),
        const ListButtons(),
        const ParagraphButtons(),
        InsertButtons(
          video: widget.enableFileUpload,
          audio: widget.enableFileUpload,
          table: true,
          hr: true,
          otherFile: widget.enableFileUpload,
          picture: widget.enableImageUpload,
          link: true,
        ),
        const OtherButtons(),
      ],
      toolbarPosition: ToolbarPosition.aboveEditor,
      toolbarType: ToolbarType
          .nativeScrollable, // Use scrollable for all to avoid grid bug
      buttonColor: isDark ? Colors.white : Colors.black87,
      buttonSelectedColor: colorScheme.primary,
      buttonFillColor: isDark
          ? colorScheme.surfaceContainerHighest
          : Colors.grey[200],
      dropdownIconColor: isDark ? Colors.white : Colors.black87,
      dropdownIconSize: isMobile && _isPortrait(context) ? 18 : 16,
    );
  }
}

/// Helper class to create and manage HtmlEditorController
class RichTextEditorController {
  late HtmlEditorController _controller;

  RichTextEditorController({String? initialText}) {
    _controller = HtmlEditorController();
    if (initialText != null && initialText.isNotEmpty) {
      _controller.setText(initialText);
    }
  }

  HtmlEditorController get controller => _controller;

  Future<String> get plainText async {
    final html = await _controller.getText();
    // Convert HTML to plain text (simple version)
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  Future<String> get htmlText async {
    return await _controller.getText();
  }

  void setText(String text) {
    _controller.setText(text);
  }

  void clear() {
    _controller.clear();
  }

  void dispose() {
    // HtmlEditorController doesn't have dispose, but we can clear it
    _controller.clear();
  }
}
