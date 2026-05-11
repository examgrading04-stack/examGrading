class ClassModel {
  String id;
  String sec;
  String subject;

  ClassModel({
    required this.id,
    String? sec,
    String? code,
    required this.subject,
  }) : sec = sec ?? code ?? '';

  String get code => sec;

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      sec: map['sec'] ?? map['code'] ?? '',
      subject: map['subject'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sec': sec,
      'subject': subject,
    };
  }
}
