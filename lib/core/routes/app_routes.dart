/// Application route names
class AppRoutes {
  // Authentication
  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String otpVerification = '/otp-verification';
  static const String resetPassword = '/reset-password';
  static const String changePassword = '/change-password';
  
  // Main Navigation
  static const String home = '/home';
  static const String homework = '/homework';
  static const String notifications = '/notifications';
  static const String attendance = '/attendance';
  static const String fees = '/fees';
  static const String leave = '/leave';
  static const String menu = '/menu';
  
  // Profile & Settings
  static const String profile = '/profile';
  
  // Academic
  static const String exams = '/exams';
  static const String examDetail = '/exam-detail';
  static const String examResult = '/exam-result';
  
  // Documents
  static const String documents = '/documents';
  static const String uploadDocument = '/upload-document';
  static const String downloadDocument = '/download-document';
  
  // Media
  static const String gallery = '/gallery';
  static const String pdfViewer = '/pdf-viewer';
  static const String videoFullScreen = '/video-fullscreen';
  static const String youtubePlayer = '/youtube-player';
  
  // Communication
  static const String contacts = '/contacts';
  static const String contactsList = '/contacts-list';
  static const String smsCommunications = '/sms-communications';
  static const String surveys = '/surveys';
  static const String rewards = '/rewards';
  
  // Private constructor to prevent instantiation
  AppRoutes._();
}

