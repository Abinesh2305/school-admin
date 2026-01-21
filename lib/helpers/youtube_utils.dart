class YouTubeUtils {
  static String extractId(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return "";
    if (uri.queryParameters.containsKey("v")) {
      return uri.queryParameters["v"]!;
    }
    if (uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    return "";
  }

  static bool isYouTubeUrl(String url) {
    final lowerUrl = url.toLowerCase();
    return lowerUrl.contains('youtube.com') || 
           lowerUrl.contains('youtu.be') ||
           lowerUrl.contains('youtube-nocookie.com');
  }
}
