class LectureVideo {
  final String id;
  final String title;
  final String className;
  final String subject;
  final String chapter;
  final String state;
  final String duration;
  final String videoUrl;
  final String status; // Added status field
  final String subtopic;
  final DateTime? uploadDate; // Add uploadDate field

  LectureVideo({
    required this.id,
    required this.title,
    required this.className,
    required this.subject,
    required this.chapter,
    required this.state,
    required this.duration,
    required this.videoUrl,
    required this.status, // Added status parameter
    required this.subtopic,
    this.uploadDate, // Make it optional
  });

  factory LectureVideo.fromJson(Map<String, dynamic> json) {
    return LectureVideo(
      id: json['id'].toString(),
      title: json['title'] ?? '${json['subject']} - ${json['chapter']} - ${json['subtopic']}',
      className: json['class'].toString(),
      subject: json['subject'] ?? '',
      chapter: json['chapter'] ?? '',
      state: json['state'] ?? '',
      duration: json['duration'] ?? 'N/A',
      videoUrl: json['videoUrl'] ?? '',
      status: json['status'] ?? 'Unknown',
      subtopic: json['subtopic'] ?? '',
      uploadDate: json['uploadDate'] != null 
          ? DateTime.parse(json['uploadDate']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'className': className,
      'subject': subject,
      'chapter': chapter,
      'state': state,
      'duration': duration,
      'videoUrl': videoUrl,
      'status': status,
      'subtopic': subtopic,
      'uploadDate': uploadDate?.toIso8601String(),
    };
  }
}