/// Test/Dummy media files for testing document viewers
/// These are publicly accessible sample files that can be used for testing
class TestMediaFiles {
  // Sample PDF files
  static const String samplePdf1 = 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf';
  static const String samplePdf2 = 'https://www.africau.edu/images/default/sample.pdf';
  static const String samplePdf3 = 'https://www.learningcontainer.com/wp-content/uploads/2019/09/sample-pdf-file.pdf';

  // Sample DOCX files (using Google Docs Viewer compatible URLs)
  static const String sampleDocx1 = 'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/10/file_example_DOCX_10.docx';
  static const String sampleDocx2 = 'https://www.learningcontainer.com/wp-content/uploads/2019/09/sample-docx-file.docx';

  // Sample PPT/PPTX files
  static const String samplePpt1 = 'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/10/file_example_PPT_1MB.ppt';
  static const String samplePptx1 = 'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/10/file_example_PPT_1MB.pptx';

  // Sample Images
  static const String sampleImage1 = 'https://picsum.photos/800/600';
  static const String sampleImage2 = 'https://picsum.photos/1024/768';
  static const String sampleImage3 = 'https://via.placeholder.com/800x600.jpg';
  static const String sampleImage4 = 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800';

  // Sample Videos (MP4) - Using reliable test video sources
  static const String sampleVideo1 = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
  static const String sampleVideo2 = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4';
  static const String sampleVideo3 = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4';
  static const String sampleVideo4 = 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4';

  // Sample Audio (MP3)
  static const String sampleAudio1 = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
  static const String sampleAudio2 = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3';
  static const String sampleAudio3 = 'https://file-examples.com/storage/fe68c0c0e4c0a1a5a1a5a1a/2017/11/file_example_MP3_700KB.mp3';

  // Sample YouTube URLs
  static const String sampleYouTube1 = 'https://www.youtube.com/watch?v=dQw4w9WgXcQ';
  static const String sampleYouTube2 = 'https://www.youtube.com/watch?v=jNQXAC9IVRw';
  static const String sampleYouTube3 = 'https://youtu.be/dQw4w9WgXcQ';

  /// Get a list of all test PDF files
  static List<String> get testPdfs => [
        samplePdf1,
        samplePdf2,
        samplePdf3,
      ];

  /// Get a list of all test DOCX files
  static List<String> get testDocx => [
        sampleDocx1,
        sampleDocx2,
      ];

  /// Get a list of all test images
  static List<String> get testImages => [
        sampleImage1,
        sampleImage2,
        sampleImage3,
        sampleImage4,
      ];

  /// Get a list of all test videos
  static List<String> get testVideos => [
        sampleVideo1,
        sampleVideo2,
        sampleVideo3,
        sampleVideo4,
      ];

  /// Get a list of all test audio files
  static List<String> get testAudio => [
        sampleAudio1,
        sampleAudio2,
        sampleAudio3,
      ];

  /// Get a list of all test YouTube URLs
  static List<String> get testYouTube => [
        sampleYouTube1,
        sampleYouTube2,
        sampleYouTube3,
      ];

  /// Get a random test file of a specific type
  static String getRandomFile(TestFileType type) {
    switch (type) {
      case TestFileType.pdf:
        return testPdfs[DateTime.now().millisecond % testPdfs.length];
      case TestFileType.docx:
        return testDocx[DateTime.now().millisecond % testDocx.length];
      case TestFileType.pptx:
        return testPpt[DateTime.now().millisecond % testPpt.length];
      case TestFileType.image:
        return testImages[DateTime.now().millisecond % testImages.length];
      case TestFileType.video:
        return testVideos[DateTime.now().millisecond % testVideos.length];
      case TestFileType.audio:
        return testAudio[DateTime.now().millisecond % testAudio.length];
      case TestFileType.youtube:
        return testYouTube[DateTime.now().millisecond % testYouTube.length];
    }
  }

  /// Get all test files as a map for easy access
  static Map<String, List<String>> get allTestFiles => {
        'pdf': testPdfs,
        'docx': testDocx,
        'ppt': testPpt,
        'images': testImages,
        'videos': testVideos,
        'audio': testAudio,
        'youtube': testYouTube,
      };
}

enum TestFileType {
  pdf,
  docx,
  image,
  video,
  audio,
  youtube,
}

