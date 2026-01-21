import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'dart:math';

/// Mock backend service that returns dummy data for all API endpoints
class MockBackend {
  static final Random _random = Random();

  /// Generate mock response for any endpoint
  static Response getMockResponse(RequestOptions options) {
    final path = options.path.toLowerCase();
    final method = options.method.toUpperCase();
    final data = options.data as Map<String, dynamic>? ?? {};

    // Add artificial delay to simulate network
    Future.delayed(const Duration(milliseconds: 300));

    if (path.contains('login')) {
      return _mockLogin(data);
    } else if (path.contains('homecontents')) {
      return _mockHomeContents(data);
    } else if (path.contains('getmobilescholars')) {
      return _mockMobileScholars(data);
    } else if (path.contains('postcommunications') || path.contains('postcommunications')) {
      return _mockPostCommunications(data);
    } else if (path.contains('admin/communication/acknowledge')) {
      return _mockAcknowledge(data);
    } else if (path.contains('admin/communication/mark-read')) {
      return _mockMarkRead(data);
    } else if (path.contains('admin/communication/batch-mark-read')) {
      return _mockBatchMarkRead(data);
    } else if (path.contains('admin/categories')) {
      return _mockCategories(data);
    } else if (path.contains('attendance')) {
      return _mockAttendance(data);
    } else if (path.contains('homeworkswithdate')) {
      return _mockHomeworks(data); // Same format as homeworks
    } else if (path.contains('homeworks') && !path.contains('read') && !path.contains('ack')) {
      return _mockHomeworks(data);
    } else if (path.contains('homework-read')) {
      return _mockHomeworkRead(data);
    } else if (path.contains('homework-batch-read')) {
      return _mockHomeworkBatchRead(data);
    } else if (path.contains('homework-ack')) {
      return _mockHomeworkAck(data);
    } else if (path.contains('getscholarfeespayments')) {
      return _mockFeesPayments(data);
    } else if (path.contains('getscholarfeestransactions')) {
      return _mockFeesTransactions(data);
    } else if (path.contains('getbankslist')) {
      return _mockBanksList(data);
    } else if (path.contains('profile_details')) {
      return _mockProfileDetails(data);
    } else if (path.contains('update_profile')) {
      return _mockUpdateProfile(data);
    } else if (path.contains('postsurveys')) {
      return _mockSurveys(data);
    } else if (path.contains('postsurveyrespond')) {
      return _mockSurveyRespond(data);
    } else if (path.contains('update-language')) {
      return _mockUpdateLanguage(data);
    } else if (path.contains('logout')) {
      return _mockLogout(data);
    } else if (path.contains('forgot-password') || path.contains('forgotpassword')) {
      return _mockForgotPassword(data);
    } else if (path.contains('otp-verification') || path.contains('otpverification') || path.contains('verify_otp')) {
      return _mockOtpVerification(data);
    } else if (path.contains('resend-otp') || path.contains('resendotp') || path.contains('resend_otp')) {
      return _mockResendOtp(data);
    } else if (path.contains('reset-password') || path.contains('resetpassword')) {
      return _mockResetPassword(data);
    } else if (path.contains('change-password') || path.contains('changepassword')) {
      return _mockChangePassword(data);
    } else if (path.contains('documents/upload')) {
      return _mockDocumentUpload(data);
    } else if (path.contains('documents/my-status')) {
      return _mockDocumentStatus(data);
    } else if (path.contains('documents/list')) {
      return _mockDocumentList(data);
    } else if (path.contains('apply_leave')) {
      return _mockApplyLeave(data);
    } else if (path.contains('applied_leave')) {
      return _mockAppliedLeaves(data);
    } else if (path.contains('unapproved_leaves')) {
      return _mockUnapprovedLeaves(data);
    } else if (path.contains('cancel_leave')) {
      return _mockCancelLeave(data);
    } else if (path.contains('examdetails')) {
      return _mockExamDetails(data);
    } else if (path.contains('examtimetable')) {
      return _mockExamTimetable(data);
    } else if (path.contains('getsmscommunications')) {
      return _mockSMSCommunications(data);
    } else if (path.contains('getgallerylist')) {
      return _mockGalleryList(data);
    } else if (path.contains('getevents')) {
      return _mockEvents(data);
    } else if (path.contains('app/version') || path.contains('version')) {
      // For GET requests, get data from queryParameters
      final versionData = options.queryParameters.isNotEmpty 
          ? Map<String, dynamic>.from(options.queryParameters)
          : data;
      return _mockAppVersion(versionData);
    } else {
      // Default mock response for unknown endpoints
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'status': 1,
          'message': 'Mock response',
          'data': {},
        },
      );
    }
  }

  static Response _mockLogin(Map<String, dynamic> data) {
    // Accept any email/password for demo
    final email = data['email'] ?? 'demo@example.com';
    final userId = _random.nextInt(1000) + 1;

    return Response(
      requestOptions: RequestOptions(path: 'login'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Login successful',
        'data': {
          'id': userId,
          'name': 'John Doe',
          'email': email,
          'api_token': 'mock_token_${userId}_${DateTime.now().millisecondsSinceEpoch}',
          'language': 'en',
          'is_app_installed': 1,
          'school_college_id': 1,
          'main_ref_no': 'STU${userId.toString().padLeft(5, '0')}',
          'is_profile_image': 'https://via.placeholder.com/150',
          'userdetails': {
            'is_class_name': 'Grade 10',
            'is_section_name': 'A',
            'is_class_id': 10,
            'is_section_id': 1,
            'school_id': 1,
            'school_college_id': 1,
          },
          'groups': [],
        },
      },
    );
  }

  static Response _mockHomeContents(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'homecontents'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': {
          'notifications': 5,
          'homeworks': 3,
          'attendance': 85.5,
        },
      },
    );
  }

  static Response _mockMobileScholars(Map<String, dynamic> data) {
    final userId = data['user_id'] ?? 1;
    return Response(
      requestOptions: RequestOptions(path: 'getmobilescholars'),
      statusCode: 200,
      data: {
        'status': 1,
        'data': [
          {
            'id': userId,
            'name': 'John Doe',
            'api_token': 'mock_token_$userId',
            'is_profile_image': 'https://via.placeholder.com/150',
            'userdetails': {
              'is_class_name': 'Grade 10',
              'is_section_name': 'A',
            },
          },
          {
            'id': userId + 1,
            'name': 'Jane Smith',
            'api_token': 'mock_token_${userId + 1}',
            'is_profile_image': 'https://via.placeholder.com/150',
            'userdetails': {
              'is_class_name': 'Grade 9',
              'is_section_name': 'B',
            },
          },
        ],
      },
    );
  }

  static Response _mockPostCommunications(Map<String, dynamic> data) {
    // Import test media files for dummy attachments
    const testPdfs = [
      'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      'https://www.africau.edu/images/default/sample.pdf',
    ];
    const testDocx = [
      'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/10/file_example_DOCX_10.docx',
    ];
    const testPpt = [
      'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/10/file_example_PPT_1MB.ppt',
      'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/10/file_example_PPT_1MB.pptx',
    ];
    const testImages = [
      'https://picsum.photos/800/600',
      'https://picsum.photos/1024/768',
      'https://via.placeholder.com/800x600.jpg',
    ];
    const testVideos = [
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
    ];
    const testAudio = [
      'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/11/file_example_MP3_700KB.mp3',
    ];
    const testYouTube = [
      'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      'https://www.youtube.com/watch?v=jNQXAC9IVRw',
    ];
    final pageNo = data['page_no'] ?? 0;
    final type = data['type'] ?? 0;
    
    // Realistic dummy notification messages
    final List<Map<String, dynamic>> notificationTemplates = [
      {
        'title': 'Annual Day Celebration',
        'body': '''Dear Parents,

We are thrilled to announce our much-anticipated Annual Day Celebration, scheduled for March 25th, 2024. The event will be hosted in the main auditorium and promises to be a vibrant showcase of our students’ diverse talents and the school’s spirit of togetherness.

The festivities will commence at 4:00 PM with an inauguration ceremony led by our respected Principal. This will be followed by a series of cultural performances, including traditional dances, choir recitations, skits, and a spectacular musical finale presented by Grade 10 students. Each class has worked diligently to prepare an item that symbolizes the values and culture that make our school unique.

For your convenience, refreshments and light snacks will be served in the school canteen during the intermission. We kindly ask parents to be seated by 3:45 PM to ensure a smooth start to the proceedings.

Dress code for the students is the school’s formal attire. Participants are requested to remain backstage by 3:00 PM for costume checks and sound rehearsals. Please ensure your child has all necessary props and costumes as instructed by their respective class teachers.

Due to limited parking on campus, we recommend carpooling or using public transportation whenever possible. Security personnel will be stationed to assist with directions and crowd management.

To make this event a memorable one, we kindly urge all parents to encourage and cheer for every performer. Your enthusiastic participation goes a long way in motivating our students and fostering a sense of community.

Photographers and videographers will be present to capture candid moments throughout the event. High-resolution images and edited event footage will be made available to all registered families after the celebration.

Any questions regarding the program order or stage arrangements can be addressed to the event coordinator, Ms. Anjali Mehra, either through the app or by contacting the school office directly. If your child requires special assistance for their presentation, please notify us beforehand.

On behalf of the entire staff and organizing committee, we extend our heartfelt invitation for you to join us on this special occasion. Let us come together as a school family to celebrate our achievements, creativity, and the year gone by.

We look forward to your gracious presence and hope to make this Annual Day a joyful experience for all!

Warm regards,
School Management''',
        'category': 'Events',
        'sender': 'Principal Office',
      },
      {
        'title': 'Parent-Teacher Meeting',
        'body': '''
<div>
  <table style="width:100%;border-collapse:collapse;">
    <tr>
      <td style="font-weight:bold;">Meeting</td>
      <td>Parent-Teacher Conference</td>
    </tr>
    <tr>
      <td style="font-weight:bold;">Date</td>
      <td>March 20th, 2024</td>
    </tr>
    <tr>
      <td style="font-weight:bold;">Time</td>
      <td>10:00 AM – 2:00 PM</td>
    </tr>
    <tr>
      <td style="font-weight:bold;">Details</td>
      <td>
        <div>
          This is an opportunity to discuss your child's academic progress and address any concerns. Please <b>book your slot through the app</b> or contact your class teacher.<br />
          <br />
          We encourage all parents to attend and make the most of this interactive session.<br />
          <br />
          For inquiries, reach out to your child's teacher via the app messaging or call the school office.
        </div>
      </td>
    </tr>
  </table>
  <br />
</div>
''',
        'category': 'Academic',
        'sender': 'Class Teacher',
      },
      {
        'title': 'Fee Payment Reminder',
        'body': 'This is a reminder that the second term fee payment of ₹15,000 is due on March 15th, 2024. Please ensure payment is made before the due date to avoid late fees. Payment can be made online through the app or at the school office.',
        'category': 'Fees',
        'sender': 'Accounts Department',
      },
      {
        'title': 'Sports Day Registration',
        'body': 'Sports Day will be held on April 10th, 2024. Students can participate in various events including athletics, team sports, and fun activities. Registration closes on March 30th. Please register your child through the app.',
        'category': 'Sports',
        'sender': 'Sports Department',
      },
      {
        'title': 'Science Exhibition',
        'body': 'The Annual Science Exhibition will be conducted on March 28th, 2024. Students from Grade 6-10 will showcase their innovative projects. Parents are welcome to visit between 2:00 PM and 5:00 PM. Looking forward to your presence.',
        'category': 'Academic',
        'sender': 'Science Department',
      },
      {
        'title': 'Holiday Notice',
        'body': 'The school will remain closed on March 21st, 2024 (Holi) and March 29th, 2024 (Good Friday). Classes will resume on April 1st, 2024. Wishing you and your family a joyful holiday season.',
        'category': 'Announcements',
        'sender': 'Principal Office',
      },
      {
        'title': 'Library Book Return',
        'body': 'This is to inform you that your child has borrowed books from the library that are due for return on March 18th, 2024. Please ensure the books are returned on time to avoid any penalties. For any queries, contact the librarian.',
        'category': 'Academic',
        'sender': 'Library',
      },
      {
        'title': 'School Trip - Botanical Garden',
        'body': 'An educational trip to the Botanical Garden is organized for Grade 5-7 students on March 22nd, 2024. The cost per student is ₹500 (includes transportation and entry fees). Please provide consent and payment by March 15th through the app.',
        'category': 'Events',
        'sender': 'Class Teacher',
      },
      {
        'title': 'Uniform Purchase Notice',
        'body': 'Summer uniforms are now available for purchase at the school store. Store timings: Monday to Friday, 9:00 AM to 3:00 PM. New students and those requiring size changes can visit the store. Cash and card payments accepted.',
        'category': 'General',
        'sender': 'Administration',
      },
      {
        'title': 'Online Classes Schedule',
        'body': 'Due to unforeseen circumstances, online classes will be conducted on March 19th, 2024 for all grades. Class links will be shared via email and the school app. Students are expected to attend all sessions as per the regular timetable.',
        'category': 'Academic',
        'sender': 'Principal Office',
      },
      {
        'title': 'Art Competition Results',
        'body': 'Congratulations! Your child has won the first prize in the Inter-School Art Competition in the drawing category. The prize distribution ceremony will be held on March 26th at 11:00 AM in the school auditorium. Please join us to celebrate this achievement.',
        'category': 'Academic',
        'sender': 'Art Department',
      },
      {
        'title': 'Medical Check-up',
        'body': 'A general health check-up camp will be conducted on March 23rd, 2024 from 9:00 AM to 12:00 PM. This is mandatory for all students. Parents need to provide consent through the app by March 20th. The check-up is free of cost.',
        'category': 'Health',
        'sender': 'Health Department',
      },
      {
        'title': 'Exam Schedule - Mid Term',
        'body': 'The Mid-Term Examination schedule for all grades has been published. Exams will commence on April 2nd, 2024. Please ensure your child attends all exams with required stationery. Detailed timetable is available in the app under the Exams section.',
        'category': 'Academic',
        'sender': 'Examination Department',
      },
      {
        'title': 'Canteen Menu Update',
        'body': 'The school canteen menu has been updated with new healthy snack options. A new section for organic and vegan snacks has been added. Parents can pre-order meals for their children through the app. The updated menu is now available in the app.',
        'category': 'General',
        'sender': 'Canteen',
      },
      {
        'title': 'Bus Route Change',
        'body': 'Due to road construction, Bus Route 5 will have a temporary route change from March 18th to March 25th, 2024. The new route and pickup timings have been updated in the app. Please check the updated schedule and inform the bus coordinator if you have any concerns.',
        'category': 'Transport',
        'sender': 'Transport Department',
      },
      {
        'title': 'Book Fair',
        'body': 'A three-day Book Fair is being organized in the school library from March 25th to 27th, 2024. Various educational and story books will be available at discounted prices. Parents can visit from 10:00 AM to 5:00 PM. Special discounts for students.',
        'category': 'Events',
        'sender': 'Library',
      },
      {
        'title': 'Yoga Session',
        'body': 'Free yoga sessions for parents will be conducted every Saturday starting from March 23rd, 2024 from 8:00 AM to 9:00 AM in the school auditorium. This is a great opportunity to stay fit and healthy. No prior registration required. All parents are welcome.',
        'category': 'Health',
        'sender': 'Physical Education Department',
      },
      {
        'title': 'Scholarship Application',
        'body': 'Applications are now open for the Merit Scholarship program for students of Grade 9-12. Students with 90% and above in the previous year are eligible. Application deadline is March 31st, 2024. Forms are available at the principal\'s office and on the school website.',
        'category': 'Academic',
        'sender': 'Principal Office',
      },
      {
        'title': 'Workshop on Digital Safety',
        'body': 'An informative workshop on Digital Safety and Cyber Security for parents will be conducted on March 24th, 2024 at 3:00 PM. Learn about keeping your children safe online. Limited seats available. Please register through the app by March 20th.',
        'category': 'Workshops',
        'sender': 'Principal Office',
      },
      {
        'title': 'Summer Camp Registration',
        'body': 'Summer Camp registration is now open! Various activities including swimming, dance, music, coding, and sports will be available from May 1st to May 31st, 2024. Early bird discount available till March 25th. Register now through the app to secure your spot.',
        'category': 'Events',
        'sender': 'Activity Coordinator',
      },
      {
        'title': 'Test HTML Message - Malformed Table',
        'body': '<div> < > dgfdg</td > erte 54<td >56456</td> </tr> <tr> < td > <td>dfghg</td> > <br </td> <td>gfdcb</td> </tr> </table> <br /',
        'category': 'Test',
        'sender': 'System Test',
      },
    ];
    
    return Response(
      requestOptions: RequestOptions(path: 'postCommunications'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': List.generate(
          notificationTemplates.length > 20 ? 20 : notificationTemplates.length, 
          (index) {
          final template = notificationTemplates[index % notificationTemplates.length];
          final notificationId = (pageNo * 10) + index + 1;
          
          // Add test attachments to some notifications for testing
          Map<String, dynamic> notification = {
            'id': notificationId,
            'title': template['title'],
            'body': template['body'],
            'message': template['body'], // Some APIs use 'message' instead of 'body'
            'date': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
            'category': template['category'],
            'type': type == 1 ? 'post' : type == 2 ? 'sms' : 'all',
            'read_status': index < 3 ? 'READ' : 'UNREAD',
            'ack_status': index < 2 ? 'ACKNOWLEDGED' : 'PENDING',
            'sender_name': template['sender'],
            'created_at': DateTime.now().subtract(Duration(days: index % notificationTemplates.length)).toIso8601String(),
            'post_category': template['category'],
            'category_id': index % 5 + 1,
            'is_notify_datetime': '${index + 1} days ago',
            'request_acknowledge': index % 3 == 0 ? '1' : '0',
            'is_acknowledged': index < 2 ? '1' : '0',
          };
          
          // Add test attachments based on index for testing different file types
          if (index == 0) {
            // First notification: PDF, DOCX, and PPT files
            notification['is_files_attachment'] = [
              testPdfs[0],
              testDocx[0],
              testPpt[0],
            ];
            notification['is_image_attachment'] = [testImages[0]];
          } else if (index == 1) {
            // Second notification: Video and Audio
            notification['is_video_attachment'] = testVideos[0];
            notification['is_attachment'] = testAudio[0];
            notification['is_image_attachment'] = [testImages[1], testImages[2]];
          } else if (index == 2) {
            // Third notification: YouTube link
            notification['youtube_link'] = testYouTube[0];
            notification['is_files_attachment'] = [testPdfs[1]];
          } else if (index == 3) {
            // Fourth notification: Multiple images
            notification['is_image_attachment'] = testImages;
          } else if (index == 4) {
            // Fifth notification: Video file
            notification['is_video_attachment'] = testVideos[1];
            notification['is_files_attachment'] = [testDocx[0]];
          } else if (index == 5) {
            // Sixth notification: Audio file
            notification['is_attachment'] = testAudio[1];
            notification['is_image_attachment'] = [testImages[0]];
          } else if (index == 6) {
            // Seventh notification: Mixed attachments
            notification['is_files_attachment'] = [testPdfs[0], testDocx[0]];
            notification['is_image_attachment'] = [testImages[1]];
            notification['is_video_attachment'] = testVideos[0];
          } else if (index == 7) {
            // Eighth notification: YouTube and PDF
            notification['youtube_link'] = testYouTube[1];
            notification['is_files_attachment'] = [testPdfs[1]];
            notification['is_image_attachment'] = [testImages[2]];
          } else if (index == 8) {
            // Ninth notification: Audio and images
            notification['is_attachment'] = testAudio[0];
            notification['is_image_attachment'] = [testImages[0], testImages[1]];
          } else if (index == 9) {
            // Tenth notification: All types
            notification['youtube_link'] = testYouTube[0];
            notification['is_video_attachment'] = testVideos[0];
            notification['is_attachment'] = testAudio[0];
            notification['is_files_attachment'] = [testPdfs[0], testDocx[0]];
            notification['is_image_attachment'] = testImages;
          }
          
          return notification;
        }),
      },
    );
  }

  static Response _mockAcknowledge(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'admin/communication/acknowledge'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Acknowledged successfully',
      },
    );
  }

  static Response _mockMarkRead(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'admin/communication/mark-read'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Marked as read',
      },
    );
  }

  static Response _mockBatchMarkRead(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'admin/communication/batch-mark-read'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Batch marked as read',
      },
    );
  }

  static Response _mockCategories(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'admin/categories'),
      statusCode: 200,
      data: {
        'status': 1,
        'data': [
          {'id': 1, 'name': 'General'},
          {'id': 2, 'name': 'Academic'},
          {'id': 3, 'name': 'Sports'},
          {'id': 4, 'name': 'Events'},
          {'id': 5, 'name': 'Announcements'},
        ],
      },
    );
  }

  static Response _mockAttendance(Map<String, dynamic> data) {
    final monthYear = data['monthyr'] ?? '2024-01';
    final daysInMonth = 31;
    
    return Response(
      requestOptions: RequestOptions(path: 'attendance'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': {
          'total_days': daysInMonth,
          'present_days': 25,
          'absent_days': 4,
          'leave_days': 2,
          'percentage': 80.6,
          'attendance': List.generate(daysInMonth, (index) {
            final day = index + 1;
            final status = _random.nextInt(3); // 0=absent, 1=present, 2=leave
            return {
              'date': '$monthYear-${day.toString().padLeft(2, '0')}',
              'status': status == 0 ? 'A' : status == 1 ? 'P' : 'L',
            };
          }),
        },
      },
    );
  }

  static Response _mockHomeworks(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'homeworks'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': List.generate(5, (index) {
          return {
            'id': index + 1,
            'main_ref_no': 'HW${(index + 1).toString().padLeft(5, '0')}',
            'is_subject_name': ['Mathematics', 'Science', 'English', 'History', 'Geography'][index],
            'hw_description': 'Complete exercises from chapter ${index + 1}. This is a sample homework description.',
            'is_hw_date': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
            'is_hw_submission_date': DateTime.now().add(Duration(days: 3 - index)).toIso8601String(),
            'is_file_attachments': [],
            'read_status': index < 2 ? 'READ' : 'UNREAD',
            'ack_status': index < 1 ? 'ACKNOWLEDGED' : 'PENDING',
            'ack_required': 1,
          };
        }),
      },
    );
  }

  static Response _mockHomeworkRead(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'homework-read'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Marked as read',
      },
    );
  }

  static Response _mockHomeworkBatchRead(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'homework-batch-read'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Batch marked as read',
      },
    );
  }

  static Response _mockHomeworkAck(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'homework-ack'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Acknowledged successfully',
      },
    );
  }

  static Response _mockFeesPayments(Map<String, dynamic> data) {
    final batch = data['batch'] ?? '2024-2025';
    
    return Response(
      requestOptions: RequestOptions(path: 'getscholarfeespayments'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': {
          'total_fees': 50000,
          'paid_fees': 30000,
          'pending_fees': 20000,
          'batch': batch,
          'payments': [
            {
              'id': 1,
              'fee_type': 'Tuition Fee',
              'amount': 20000,
              'status': 'Paid',
              'due_date': '2024-04-01',
              'paid_date': '2024-03-25',
            },
            {
              'id': 2,
              'fee_type': 'Library Fee',
              'amount': 5000,
              'status': 'Paid',
              'due_date': '2024-04-15',
              'paid_date': '2024-04-10',
            },
            {
              'id': 3,
              'fee_type': 'Sports Fee',
              'amount': 5000,
              'status': 'Pending',
              'due_date': '2024-05-01',
              'paid_date': null,
            },
            {
              'id': 4,
              'fee_type': 'Lab Fee',
              'amount': 10000,
              'status': 'Pending',
              'due_date': '2024-05-15',
              'paid_date': null,
            },
          ],
        },
      },
    );
  }

  static Response _mockFeesTransactions(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'getscholarfeestransactions'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': {
          'transactions': [
            {
              'id': 1,
              'transaction_id': 'TXN001',
              'fee_type': 'Tuition Fee',
              'amount': 20000,
              'payment_date': '2024-03-25',
              'payment_mode': 'Online',
              'status': 'Success',
            },
            {
              'id': 2,
              'transaction_id': 'TXN002',
              'fee_type': 'Library Fee',
              'amount': 5000,
              'payment_date': '2024-04-10',
              'payment_mode': 'Cash',
              'status': 'Success',
            },
          ],
        },
      },
    );
  }

  static Response _mockBanksList(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'getbankslist'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': [
          {
            'id': 1,
            'name': 'State Bank of India',
            'account_number': '1234567890',
            'ifsc_code': 'SBIN0001234',
            'branch': 'Main Branch',
          },
          {
            'id': 2,
            'name': 'HDFC Bank',
            'account_number': '0987654321',
            'ifsc_code': 'HDFC0005678',
            'branch': 'City Branch',
          },
        ],
      },
    );
  }

  static Response _mockProfileDetails(Map<String, dynamic> data) {
    final userId = data['user_id'] ?? 1;
    
    return Response(
      requestOptions: RequestOptions(path: 'profile_details'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': {
          'id': userId,
          'name': 'John Doe',
          'email': 'john.doe@example.com',
          'mobile': '9876543210',
          'mobile1': '9876543211',
          'address': '123 Main Street, City, State',
          'is_profile_image': 'https://via.placeholder.com/150',
          'userdetails': {
            'is_class_name': 'Grade 10',
            'is_section_name': 'A',
            'admission_no': 'ADM${userId.toString().padLeft(5, '0')}',
            'roll_no': 'R${userId.toString().padLeft(3, '0')}',
          },
        },
      },
    );
  }

  static Response _mockUpdateProfile(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'update_profile'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Profile updated successfully',
      },
    );
  }

  static Response _mockSurveys(Map<String, dynamic> data) {
    final pageNo = data['page_no'] ?? 0;
    
    return Response(
      requestOptions: RequestOptions(path: 'postsurveys'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': List.generate(5, (index) {
          return {
            'id': (pageNo * 5) + index + 1,
            'title': 'Survey ${(pageNo * 5) + index + 1}',
            'description': 'This is a sample survey description',
            'questions': [
              {
                'id': 1,
                'question': 'How satisfied are you with the school?',
                'options': ['Very Satisfied', 'Satisfied', 'Neutral', 'Dissatisfied'],
              },
            ],
            'responded': index < 2,
          };
        }),
      },
    );
  }

  static Response _mockSurveyRespond(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'postsurveyrespond'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Survey response submitted successfully',
      },
    );
  }

  static Response _mockUpdateLanguage(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'update-language'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Language updated successfully',
      },
    );
  }

  static Response _mockLogout(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'logout'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Logged out successfully',
      },
    );
  }

  static Response _mockForgotPassword(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'forgot-password'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'OTP sent to your registered mobile number',
      },
    );
  }

  static Response _mockOtpVerification(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'otp-verification'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'OTP verified successfully',
      },
    );
  }

  static Response _mockResendOtp(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'resend-otp'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'OTP resent successfully',
      },
    );
  }

  static Response _mockResetPassword(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'reset-password'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Password reset successfully',
      },
    );
  }

  static Response _mockChangePassword(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'change-password'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Password changed successfully',
      },
    );
  }

  static Response _mockDocumentUpload(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'documents/upload'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Document uploaded successfully',
        'data': {
          'document_id': _random.nextInt(1000) + 1,
          'url': 'https://via.placeholder.com/150',
        },
      },
    );
  }

  static Response _mockDocumentStatus(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'documents/my-status'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': {
          'pending': [
            {'id': 1, 'document_type': 'Birth Certificate', 'status': 'Pending'},
          ],
          'approved': [
            {'id': 2, 'document_type': 'Aadhar Card', 'status': 'Approved'},
          ],
          'rejected': [],
        },
      },
    );
  }

  static Response _mockDocumentList(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'documents/list'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': [
          {
            'id': 1,
            'document_type': 'Birth Certificate',
            'url': 'https://via.placeholder.com/150',
            'uploaded_date': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
          },
          {
            'id': 2,
            'document_type': 'Aadhar Card',
            'url': 'https://via.placeholder.com/150',
            'uploaded_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
          },
        ],
      },
    );
  }

  static Response _mockApplyLeave(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'apply_leave'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Leave applied successfully',
        'data': {
          'leave_id': _random.nextInt(1000) + 1,
        },
      },
    );
  }

  static Response _mockAppliedLeaves(Map<String, dynamic> data) {
    final monthYear = data['monthyr'] ?? '2024-01';
    
    return Response(
      requestOptions: RequestOptions(path: 'applied_leave'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': [
          {
            'id': 1,
            'leave_reason': 'Family function',
            'leave_date': '$monthYear-15',
            'leave_end_date': '$monthYear-16',
            'leave_type': 'Sick Leave',
            'status': 'Approved',
          },
          {
            'id': 2,
            'leave_reason': 'Personal work',
            'leave_date': '$monthYear-20',
            'leave_end_date': null,
            'leave_type': 'Casual Leave',
            'status': 'Pending',
          },
        ],
      },
    );
  }

  static Response _mockUnapprovedLeaves(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'unapproved_leaves'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': [
          {
            'id': 2,
            'leave_reason': 'Personal work',
            'leave_date': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
            'leave_type': 'Casual Leave',
            'status': 'Pending',
          },
        ],
      },
    );
  }

  static Response _mockCancelLeave(Map<String, dynamic> data) {
    return Response(
      requestOptions: RequestOptions(path: 'cancel_leave'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Leave cancelled successfully',
      },
    );
  }

  static Response _mockExamDetails(Map<String, dynamic> data) {
    final examId = int.tryParse(data['exam_id']?.toString() ?? '0') ?? 0;
    
    if (examId > 0) {
      // Return exam results
      return Response(
        requestOptions: RequestOptions(path: 'examdetails'),
        statusCode: 200,
        data: {
          'status': 1,
          'message': 'Success',
          'data': [
            {
              'marksentryitems': [
                {'subject': 'Mathematics', 'marks_obtained': 85, 'max_marks': 100, 'grade': 'A'},
                {'subject': 'Science', 'marks_obtained': 90, 'max_marks': 100, 'grade': 'A+'},
                {'subject': 'English', 'marks_obtained': 78, 'max_marks': 100, 'grade': 'B+'},
                {'subject': 'History', 'marks_obtained': 82, 'max_marks': 100, 'grade': 'A'},
              ],
            },
          ],
        },
      );
    } else {
      // Return exam list
      return Response(
        requestOptions: RequestOptions(path: 'examdetails'),
        statusCode: 200,
        data: {
          'status': 1,
          'message': 'Success',
          'data': [
            {'id': 1, 'name': 'Mid-Term Exam', 'start_date': '2024-03-01', 'end_date': '2024-03-15'},
            {'id': 2, 'name': 'Final Exam', 'start_date': '2024-05-01', 'end_date': '2024-05-20'},
            {'id': 3, 'name': 'Unit Test 1', 'start_date': '2024-02-01', 'end_date': '2024-02-05'},
          ],
        },
      );
    }
  }

  static Response _mockExamTimetable(Map<String, dynamic> data) {
    final examId = data['exam_id'] ?? '1';
    
    return Response(
      requestOptions: RequestOptions(path: 'examtimetable'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': [
          {
            'date': '2024-03-01',
            'subject': 'Mathematics',
            'time': '09:00 AM - 12:00 PM',
            'room': 'Room 101',
          },
          {
            'date': '2024-03-02',
            'subject': 'Science',
            'time': '09:00 AM - 12:00 PM',
            'room': 'Room 102',
          },
          {
            'date': '2024-03-03',
            'subject': 'English',
            'time': '09:00 AM - 12:00 PM',
            'room': 'Room 103',
          },
        ],
      },
    );
  }

  static Response _mockGalleryList(Map<String, dynamic> data) {
    final pageNo = data['page_no'] ?? 0;
    
    return Response(
      requestOptions: RequestOptions(path: 'getgallerylist'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': List.generate(10, (index) {
          return {
            'id': (pageNo * 10) + index + 1,
            'title': 'Gallery Image ${(pageNo * 10) + index + 1}',
            'image_url': 'https://via.placeholder.com/400x300',
            'date': DateTime.now().subtract(Duration(days: index)).toIso8601String(),
            'category': 'Events',
          };
        }),
      },
    );
  }

  static Response _mockSMSCommunications(Map<String, dynamic> data) {
    final now = DateTime.now();
    
    return Response(
      requestOptions: RequestOptions(path: 'getSMSCommunications'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': [
          {
            'id': 1,
            'type': 'sms',
            'title': 'SMS Communication',
            'final_content': 'Dear Parent, This is a test SMS communication message. Please acknowledge receipt.',
            'content': 'Dear Parent, This is a test SMS communication message. Please acknowledge receipt.',
            'notify_datetime': DateFormat('dd MMM yyyy, hh:mm a').format(now.subtract(const Duration(days: 2))),
            'post_category': 'General',
            'is_category_text_color': '#2196F3',
            'post_theme': null,
          },
          {
            'id': 2,
            'type': 'attendance',
            'title': 'Attendance Notification',
            'final_content': 'Your child was marked present today. Thank you for ensuring regular attendance.',
            'content': 'Your child was marked present today. Thank you for ensuring regular attendance.',
            'notify_datetime': DateFormat('dd MMM yyyy, hh:mm a').format(now.subtract(const Duration(days: 1))),
            'post_category': 'Attendance',
            'is_category_text_color': '#FF9800',
            'post_theme': null,
          },
          {
            'id': 3,
            'type': 'birthday',
            'title': 'Birthday Wish',
            'final_content': 'Happy Birthday! Wishing your child a wonderful year ahead filled with joy and success.',
            'content': 'Happy Birthday! Wishing your child a wonderful year ahead filled with joy and success.',
            'notify_datetime': DateFormat('dd MMM yyyy, hh:mm a').format(now.subtract(const Duration(hours: 5))),
            'post_category': 'Birthday',
            'is_category_text_color': '#E91E63',
            'post_theme': null,
          },
          {
            'id': 4,
            'type': 'sms',
            'title': 'SMS Communication',
            'final_content': 'Reminder: Parent-Teacher meeting scheduled for next week. Please confirm your attendance.',
            'content': 'Reminder: Parent-Teacher meeting scheduled for next week. Please confirm your attendance.',
            'notify_datetime': DateFormat('dd MMM yyyy, hh:mm a').format(now.subtract(const Duration(days: 3))),
            'post_category': 'Announcement',
            'is_category_text_color': '#4CAF50',
            'post_theme': null,
          },
        ],
      },
    );
  }

  static Response _mockEvents(Map<String, dynamic> data) {
    final now = DateTime.now();
    
    return Response(
      requestOptions: RequestOptions(path: 'getevents'),
      statusCode: 200,
      data: {
        'status': 1,
        'message': 'Success',
        'data': [
          {
            'id': 1,
            'event_title': 'Annual Sports Day',
            'event_description': 'Join us for our annual sports day celebration with various competitions and activities for all students.',
            'event_date': now.add(const Duration(days: 15)).toIso8601String().split('T')[0],
            'event_time': '09:00 AM',
            'event_location': 'School Ground',
            'event_image': 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800',
            'event_type': 'Sports',
            'is_registration_required': true,
            'registration_deadline': now.add(const Duration(days: 10)).toIso8601String().split('T')[0],
          },
          {
            'id': 2,
            'event_title': 'Science Fair Exhibition',
            'event_description': 'Students will showcase their innovative science projects and experiments. Parents are welcome to attend.',
            'event_date': now.add(const Duration(days: 8)).toIso8601String().split('T')[0],
            'event_time': '02:00 PM',
            'event_location': 'Science Lab & Auditorium',
            'event_image': 'https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800',
            'event_type': 'Academic',
            'is_registration_required': false,
            'registration_deadline': null,
          },
          {
            'id': 3,
            'event_title': 'Cultural Day Celebration',
            'event_description': 'A vibrant celebration of our diverse culture with performances, traditional dances, and food stalls.',
            'event_date': now.add(const Duration(days: 22)).toIso8601String().split('T')[0],
            'event_time': '10:00 AM',
            'event_location': 'Main Auditorium',
            'event_image': 'https://images.unsplash.com/photo-1514525253161-7a46d19cd819?w=800',
            'event_type': 'Cultural',
            'is_registration_required': true,
            'registration_deadline': now.add(const Duration(days: 18)).toIso8601String().split('T')[0],
          },
          {
            'id': 4,
            'event_title': 'Parent-Teacher Meeting',
            'event_description': 'Quarterly parent-teacher meeting to discuss student progress and academic performance.',
            'event_date': now.add(const Duration(days: 5)).toIso8601String().split('T')[0],
            'event_time': '09:00 AM - 04:00 PM',
            'event_location': 'Classrooms',
            'event_image': 'https://images.unsplash.com/photo-1503676260728-1c00da094a0b?w=800',
            'event_type': 'Meeting',
            'is_registration_required': true,
            'registration_deadline': now.add(const Duration(days: 3)).toIso8601String().split('T')[0],
          },
          {
            'id': 5,
            'event_title': 'Math Olympiad Competition',
            'event_description': 'Inter-school mathematics competition. Students from grades 6-12 can participate.',
            'event_date': now.add(const Duration(days: 12)).toIso8601String().split('T')[0],
            'event_time': '08:00 AM',
            'event_location': 'Computer Lab',
            'event_image': 'https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800',
            'event_type': 'Competition',
            'is_registration_required': true,
            'registration_deadline': now.add(const Duration(days: 7)).toIso8601String().split('T')[0],
          },
          {
            'id': 6,
            'event_title': 'Field Trip to Science Museum',
            'event_description': 'Educational field trip for all students to explore science and technology exhibits.',
            'event_date': now.add(const Duration(days: 20)).toIso8601String().split('T')[0],
            'event_time': '08:00 AM - 05:00 PM',
            'event_location': 'City Science Museum',
            'event_image': 'https://images.unsplash.com/photo-1532619675605-1ede6c9ed2d7?w=800',
            'event_type': 'Field Trip',
            'is_registration_required': true,
            'registration_deadline': now.add(const Duration(days: 15)).toIso8601String().split('T')[0],
          },
          {
            'id': 7,
            'event_title': 'Art & Craft Exhibition',
            'event_description': 'Showcasing creative artworks and crafts made by our talented students.',
            'event_date': now.add(const Duration(days: 25)).toIso8601String().split('T')[0],
            'event_time': '11:00 AM',
            'event_location': 'Art Gallery',
            'event_image': 'https://images.unsplash.com/photo-1513475382585-d06e58bcb0e0?w=800',
            'event_type': 'Exhibition',
            'is_registration_required': false,
            'registration_deadline': null,
          },
          {
            'id': 8,
            'event_title': 'Book Fair',
            'event_description': 'Annual book fair with a wide collection of books for all age groups. Special discounts available.',
            'event_date': now.add(const Duration(days: 30)).toIso8601String().split('T')[0],
            'event_time': '09:00 AM - 06:00 PM',
            'event_location': 'Library & School Hall',
            'event_image': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800',
            'event_type': 'Fair',
            'is_registration_required': false,
            'registration_deadline': null,
          },
        ],
      },
    );
  }

  static Response _mockAppVersion(Map<String, dynamic> data) {
    // Get current version from query params (GET request)
    final currentVersion = data['current_version']?.toString() ?? '3.1.24';
    
    // Mock latest version
    // For testing: Change this to a version higher than current to test version comparison
    // When FORCE_UPDATE_TEST_MODE is false, set this to same or lower version to disable force update
    final latestVersion = '3.1.24'; // Set same as current version to disable force update (or higher to test)
    
    // Compare versions (simple string comparison - in production use proper version comparison)
    // For testing, you can set FORCE_UPDATE_TEST_MODE to true to enable force update
    final forceUpdate = _shouldForceUpdate(currentVersion, latestVersion);
    
    return Response(
      requestOptions: RequestOptions(path: 'app/version'),
      statusCode: 200,
      data: {
        'success': true,
        'message': 'Version check successful',
        'data': {
          'current_version': currentVersion,
          'latest_version': latestVersion,
          'force_update': forceUpdate,
          'message': forceUpdate
              ? 'A new version ($latestVersion) is available. Please update the app to continue.'
              : 'You are using the latest version.',
          'update_url_android': 'https://play.google.com/store/apps/details?id=com.example.app',
          'update_url_ios': 'https://apps.apple.com/app/id123456789',
        },
      },
    );
  }
  
  /// Helper to determine if force update is needed
  /// For testing: return true to enable force update
  static bool _shouldForceUpdate(String currentVersion, String latestVersion) {
    // Simple version comparison (in production, use proper semantic versioning comparison)
    // For now, just compare strings - you can modify this logic as needed
    // Return false by default - set to true for testing force update
    // ⚠️ TESTING FLAG - Set to true to test force update overlay
    // TODO: Remove or set to false in production
    // For admin app, force update is disabled by default
    const bool forceUpdateTestMode = false; // ← Change this to true to test
    const bool adminAppMode = true; // Admin app doesn't require force updates
    
    // For admin app, disable force updates
    if (adminAppMode) {
      return false; // Admin app doesn't block on updates
    }
    
    if (forceUpdateTestMode) {
      return true; // Force update for testing
    }
    
    // Production version comparison logic
    // Compare versions: major.minor.patch
    try {
      final current = currentVersion.split('.').map(int.parse).toList();
      final latest = latestVersion.split('.').map(int.parse).toList();
      
      // Compare major version
      if (latest[0] > current[0]) return true;
      // Compare minor version
      if (latest[0] == current[0] && latest.length > 1 && current.length > 1) {
        if (latest[1] > current[1]) return true;
        // Compare patch version
        if (latest[1] == current[1] && latest.length > 2 && current.length > 2) {
          if (latest[2] > current[2]) return true;
        }
      }
    } catch (e) {
      // If version parsing fails, don't force update
      return false;
    }
    
    return false;
  }
}

