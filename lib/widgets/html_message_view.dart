import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class HtmlMessageView extends StatefulWidget {
  final String html;
  final String activeWord;
  final int activeWordStart;
  final bool
  ignorePointer; // Allow disabling pointer events to pass taps through

  const HtmlMessageView({
    super.key,
    required this.html,
    required this.activeWord,
    this.activeWordStart = -1,
    this.ignorePointer = false,
  });

  @override
  State<HtmlMessageView> createState() => _HtmlMessageViewState();
}

class _HtmlMessageViewState extends State<HtmlMessageView> {
  double contentHeight = 50;
  InAppWebViewController? webController;
  String? originalHtmlContent;

  @override
  void didUpdateWidget(HtmlMessageView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Only highlight if we have a valid word and position, and the controller is ready
    if (widget.activeWord.isNotEmpty &&
        widget.activeWordStart >= 0 &&
        (widget.activeWord != oldWidget.activeWord ||
            widget.activeWordStart != oldWidget.activeWordStart) &&
        webController != null) {
      // Use a small delay to ensure WebView is ready
      Future.microtask(() {
        if (webController != null) {
          try {
            webController!.evaluateJavascript(
              source:
                  "if (typeof highlightWord === 'function') highlightWord('${widget.activeWord.replaceAll("'", "\\'")}', ${widget.activeWordStart});",
            );
          } catch (e) {
            debugPrint('Error calling highlightWord: $e');
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Clean and fix malformed HTML
    String clean = widget.html
        .replaceAll(RegExp(r'<figure[^>]*>'), '')
        .replaceAll('</figure>', '')
        // Fix malformed tags with spaces
        .replaceAll(RegExp(r'<\s+'), '<')
        .replaceAll(RegExp(r'>\s+'), '>')
        .replaceAll(RegExp(r'<\s*/\s*'), '</')
        // Fix unclosed tags
        .replaceAll(RegExp(r'<br\s*/?\s*>', caseSensitive: false), '<br/>')
        .replaceAll(RegExp(r'<br\s*</', caseSensitive: false), '<br/>');

    // Ensure table structure is valid
    if (clean.contains('<table') && !clean.contains('</table>')) {
      clean = '$clean</table>';
    }

    Widget webView = SizedBox(
      height: contentHeight,
      child: InAppWebView(
        initialOptions: InAppWebViewGroupOptions(
          crossPlatform: InAppWebViewOptions(
            transparentBackground: true,
            disableHorizontalScroll: widget.ignorePointer,
            disableVerticalScroll: widget.ignorePointer,
            supportZoom: !widget.ignorePointer,
          ),
        ),
        initialData: InAppWebViewInitialData(
          data:
              """
            <html>
            <head>
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <style>
                body {
                  margin: 0;
                  padding: 0;
                  background: transparent;
                  text-align: justify;
                }
                #content {
                  text-align: justify;
                }
                p {
                  text-align: justify;
                }
                div {
                  text-align: justify;
                }
                table {
                  width: 100%;
                  border-collapse: collapse;
                  background: transparent;
                }
                td, th {
                  border: 1px solid #777;
                  padding: 6px;
                  font-size: 14px;
                  background: transparent;
                  text-align: left;
                }
                mark.hl {
                  background: yellow;
                  color: black;
                  font-weight: bold;
                }
              </style>

              <script>
                var storedOriginalHtml = null;
                
                function highlightWord(word, startPos) {
                  if (!word || word.trim() === "") return;

                  var content = document.getElementById("content");

                  // Store original HTML on first call
                  if (storedOriginalHtml === null) {
                    storedOriginalHtml = content.innerHTML;
                  }
                  
                  // Restore original HTML to remove previous highlights
                  content.innerHTML = storedOriginalHtml;
                  
                  // Get plain text to find word positions - use textContent to match Dart's html_parser behavior
                  // textContent is closer to html_parser.body.text than innerText (which respects CSS)
                  var tempDiv = document.createElement("div");
                  tempDiv.innerHTML = storedOriginalHtml;
                  // Normalize whitespace to match Dart's behavior (collapse multiple spaces to single space)
                  var plainText = (tempDiv.textContent || tempDiv.innerText || "").replace(/[s\n\r]+/g, ' ').trim();

                  if (startPos !== undefined && startPos >= 0 && startPos < plainText.length) {
                    // Find word boundaries at startPos (including Unicode word characters)
                    var wordStart = startPos;
                    var wordEnd = startPos;
                    
                    // Go backwards to find word start (support Unicode)
                    while (wordStart > 0 && /[\\w\\u0080-\\uFFFF]/.test(plainText[wordStart - 1])) {
                      wordStart--;
                    }
                    
                    // Go forwards to find word end (support Unicode)
                    while (wordEnd < plainText.length && /[\\w\\u0080-\\uFFFF]/.test(plainText[wordEnd])) {
                      wordEnd++;
                    }
                    
                    var targetWord = plainText.substring(wordStart, wordEnd);
                    
                    if (targetWord.trim().length === 0) return;
                    
                    // Use Range API for more accurate text node manipulation
                    var range = document.createRange();
                    var walker = document.createTreeWalker(
                      content,
                      NodeFilter.SHOW_TEXT,
                      null,
                      false
                    );
                    
                    var charCount = 0;
                    var targetCharPos = wordStart;
                    var foundNode = null;
                    var nodeStartPos = 0;
                    
                    var node;
                    while (node = walker.nextNode()) {
                      var nodeText = node.textContent;
                      var nodeEndPos = charCount + nodeText.length;
                      
                      if (charCount <= targetCharPos && targetCharPos < nodeEndPos) {
                        foundNode = node;
                        nodeStartPos = charCount;
                        break;
                      }
                      
                      charCount = nodeEndPos;
                    }
                    
                    if (foundNode) {
                      var offsetInNode = targetCharPos - nodeStartPos;
                      var nodeText = foundNode.textContent;
                      
                      // Find word boundaries in this node
                      var wordStartInNode = offsetInNode;
                      var wordEndInNode = offsetInNode;
                      
                      while (wordStartInNode > 0 && /[\\w\\u0080-\\uFFFF]/.test(nodeText[wordStartInNode - 1])) {
                        wordStartInNode--;
                      }
                      
                      while (wordEndInNode < nodeText.length && /[\\w\\u0080-\\uFFFF]/.test(nodeText[wordEndInNode])) {
                        wordEndInNode++;
                      }
                      
                      // Split the text node and wrap the word
                      var beforeText = nodeText.substring(0, wordStartInNode);
                      var wordText = nodeText.substring(wordStartInNode, wordEndInNode);
                      var afterText = nodeText.substring(wordEndInNode);
                      
                      var parent = foundNode.parentNode;
                      
                      if (beforeText) {
                        parent.insertBefore(document.createTextNode(beforeText), foundNode);
                      }
                      
                      var mark = document.createElement("mark");
                      mark.className = "hl";
                      mark.textContent = wordText;
                      parent.insertBefore(mark, foundNode);
                      
                      if (afterText) {
                        parent.insertBefore(document.createTextNode(afterText), foundNode);
                      }
                      
                      parent.removeChild(foundNode);
                      
                      // Scroll to highlighted element
                      mark.scrollIntoView({ behavior: "smooth", block: "center", inline: "nearest" });
                    }
                  }
                }

                window.onload = function() {
                  var h = document.getElementById("content").scrollHeight;
                  window.flutter_inappwebview.callHandler("contentHeight", h);
                };
              </script>
            </head>

            <body>
              <div id="content">$clean</div>
            </body>
            </html>
          """,
        ),
        onWebViewCreated: (controller) {
          webController = controller;

          controller.addJavaScriptHandler(
            handlerName: "contentHeight",
            callback: (args) {
              double newHeight = (args.first as num).toDouble() + 10;

              if (mounted) {
                setState(() => contentHeight = newHeight);
              }
              return null;
            },
          );
        },
      ),
    );

    // Wrap with IgnorePointer if needed to allow parent GestureDetector to receive taps
    if (widget.ignorePointer) {
      return IgnorePointer(child: webView);
    }

    return webView;
  }
}
