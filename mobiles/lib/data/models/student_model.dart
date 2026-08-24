class StudentModel {
  String id;
  String code;
  String name;
  String className;
  String? subjectCode;
  String? section;

  StudentModel({
    required this.id,
    required this.code,
    required this.name,
    required this.className,
    this.subjectCode,
    this.section,
  });

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    final rawSubjectCode =
        map['subjectCode']?.toString() ?? map['subject']?.toString();
    final rawSection =
        map['section']?.toString() ?? map['sectionId']?.toString();
    String className = map['class']?.toString() ?? '';
    if (className.isEmpty) {
      if (rawSubjectCode != null &&
          rawSubjectCode.isNotEmpty &&
          rawSection != null &&
          rawSection.isNotEmpty) {
        className = rawSection.contains('_')
            ? rawSection
            : '${rawSubjectCode}_$rawSection';
      } else if (rawSubjectCode != null && rawSubjectCode.isNotEmpty) {
        className = rawSubjectCode;
      } else if (rawSection != null && rawSection.isNotEmpty) {
        className = rawSection;
      }
    }

    String code = map['code']?.toString() ?? '';
    if (code.isEmpty) {
      code = id; // id is usually the student_code from db
    }

    return StudentModel(
      id: id,
      code: code,
      name: map['name']?.toString() ?? '',
      className: className,
      subjectCode: (rawSubjectCode != null && rawSubjectCode.isNotEmpty)
          ? rawSubjectCode
          : null,
      section:
          (rawSection != null && rawSection.isNotEmpty) ? rawSection : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'class': className,
      if (subjectCode != null) 'subjectCode': subjectCode,
      if (section != null) 'section': section,
    };
  }
}

