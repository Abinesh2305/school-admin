/// API endpoint constants
class ApiEndpoints {
  // Authentication
  static const String login = 'login';
  static const String logout = 'logout';
  static const String forgotPassword = 'forgot_password';
  static const String verifyOtp = 'verify_otp';
  static const String resendOtp = 'resend_otp';
  static const String resetPassword = 'reset_password';
  static const String changePassword = 'change_password';
  static const String updateLanguage = 'update-language';
  
  // User
  static const String getMobileScholars = 'getmobilescholars';
  static const String profileDetails = 'profile_details';
  static const String updateProfile = 'update_profile';
  
  // Home
  static const String homeContents = 'homecontents';
  
  // Notifications
  static const String postCommunications = 'postCommunications';
  static const String acknowledgeCommunication = 'admin/communication/acknowledge';
  static const String markReadCommunication = 'admin/communication/mark-read';
  static const String batchMarkReadCommunication = 'admin/communication/batch-mark-read';
  static const String categories = 'admin/categories';
  
  // Homework
  static const String homeworks = 'homeworks';
  static const String homeworksWithDate = 'homeworkswithdate';
  static const String homeworkRead = 'homework-read';
  static const String homeworkBatchRead = 'homework-batch-read';
  static const String homeworkAck = 'homework-ack';
  
  // Attendance
  static const String attendance = 'attendance';
  
  // Fees
  static const String scholarFeesPayments = 'getscholarfeespayments';
  static const String scholarFeesTransactions = 'getscholarfeestransactions';
  static const String banksList = 'getbankslist';
  
  // Leave
  static const String applyLeave = 'apply_leave';
  static const String appliedLeave = 'applied_leave';
  static const String unapprovedLeaves = 'unapproved_leaves';
  static const String cancelLeave = 'cancel_leave';
  
  // Exams
  static const String examDetails = 'examdetails';
  static const String examTimetable = 'examtimetable';
  
  // Documents
  static const String documentUpload = 'documents/upload';
  static const String documentStatus = 'documents/my-status';
  static const String documentList = 'documents/list';
  
  // Surveys
  static const String surveys = 'postsurveys';
  static const String surveyRespond = 'postsurveyrespond';
  
  // Gallery
  static const String galleryList = 'getgallerylist';
  
  // Topics/Notifications
  static const String subscribeTopic = 'subscribe_topic';
  static const String unsubscribeTopic = 'unsubscribe_topic';
  
  // App Version
  static const String appVersion = 'app/version';
  
  // Private constructor to prevent instantiation
  ApiEndpoints._();
}

