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
    return StudentModel(
      id: id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      className: map['class'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {'code': code, 'name': name, 'class': className};
  }
}
