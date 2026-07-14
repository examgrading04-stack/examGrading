class SubjectModel {
  String id;
  String code;
  String name;
  String term;
  String year;
  String teacher;

  SubjectModel({
    required this.id,
    required this.code,
    required this.name,
    required this.term,
    required this.year,
    required this.teacher,
  });

  factory SubjectModel.fromMap(String id, Map<String, dynamic> map) {
    return SubjectModel(
      id: id,
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      term: map['term'] ?? '',
      year: map['year'] ?? '',
      teacher: map['teacher'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'name': name,
      'term': term,
      'year': year,
      'teacher': teacher,
    };
  }
}
