class ExamModel {
  String id;
  String name;
  String subject;
  String date;
  int questions;
  int options;
  int sets;
  String? section;
  String? sheetType;
  Map<String, Map<String, dynamic>> answerKey;
  List<Map<String, dynamic>> studentsSnapshot;

  ExamModel({
    required this.id,
    required this.name,
    required this.subject,
    required this.date,
    required this.questions,
    required this.options,
    required this.sets,
    this.section,
    this.sheetType,
    required this.answerKey,
    this.studentsSnapshot = const [],
  });

  factory ExamModel.fromMap(String id, Map<String, dynamic> map) {
    final rawAnswerKey = map['answerKey'] ?? map['answerKeys'];

    return ExamModel(
      id: id,
      name: map['name']?.toString() ?? '',
      subject: map['subject']?.toString() ?? '',
      date: _parseDate(
        map['date']?.toString() ??
            map['createdAt']?.toString() ??
            map['created_at']?.toString(),
      ),
      questions: int.tryParse(map['questions']?.toString() ?? '') ?? 0,
      options: int.tryParse(map['options']?.toString() ?? '') ?? 0,
      sets: int.tryParse(map['sets']?.toString() ?? '') ?? 0,
      section: map['section']?.toString(),
      sheetType: map['sheetType']?.toString(),
      answerKey: _parseAnswerKey(rawAnswerKey),
      studentsSnapshot: _parseStudentsSnapshot(map['studentsSnapshot']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      'date': date,
      'questions': questions,
      'options': options,
      'sets': sets,
      if (section != null) 'section': section,
      if (sheetType != null) 'sheetType': sheetType,
      'answerKey': answerKey,
      'studentsSnapshot': studentsSnapshot,
    };
  }

  static String _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }

  static List<Map<String, dynamic>> _parseStudentsSnapshot(dynamic raw) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (item) => {
            'id': (item['id'] ?? '').toString(),
            'code': (item['code'] ?? '').toString(),
            'name': (item['name'] ?? '').toString(),
            'class': (item['class'] ?? '').toString(),
          },
        )
        .toList();
  }

  static Map<String, Map<String, dynamic>> _parseAnswerKey(dynamic raw) {
    if (raw is! Map) return {};

    // Check if it's a flat map (e.g., {"1": "A", "2": "B"})
    if (raw.isNotEmpty && raw.values.first is! Map) {
      return {'0': raw.map((k, v) => MapEntry(k.toString(), v))};
    }

    return raw.map((setIndex, answers) {
      final answerMap = answers is Map ? answers : <dynamic, dynamic>{};
      return MapEntry(
        setIndex.toString(),
        answerMap.map(
          (question, answer) => MapEntry(question.toString(), answer),
        ),
      );
    });
  }
}
