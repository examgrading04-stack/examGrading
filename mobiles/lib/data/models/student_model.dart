class StudentModel {
  String id;
  String code;
  String name;
  String className;

  StudentModel({
    required this.id,
    required this.code,
    required this.name,
    required this.className,
  });

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    String className = map['class']?.toString() ?? '';
    if (className.isEmpty) {
      final subjectCode = map['subjectCode']?.toString() ?? '';
      final section = map['section']?.toString() ?? '';
      if (subjectCode.isNotEmpty && section.isNotEmpty) {
        className = '${subjectCode}_$section';
      } else if (subjectCode.isNotEmpty) {
        className = subjectCode;
      } else if (section.isNotEmpty) {
        className = section;
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
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'code': code, 'name': name, 'class': className};
  }
}
