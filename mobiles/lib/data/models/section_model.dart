class SectionModel {
  String id;
  String sec;
  String subject;

  SectionModel({
    required this.id,
    required this.sec,
    this.subject = '',
  });

  factory SectionModel.fromMap(String id, Map<String, dynamic> map) {
    return SectionModel(
      id: id,
      sec: map['sec']?.toString() ?? map['code']?.toString() ?? '',
      subject: map['subject']?.toString() ??
          map['subject_id']?.toString() ??
          map['subjectCode']?.toString() ??
          '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sec': sec,
      if (subject.isNotEmpty) 'subject': subject,
    };
  }
}
