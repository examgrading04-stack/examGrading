class ExamModel {
  String id;
  String name;
  String subject;
  String subjectName;
  String date;
  int questions;
  int options;
  int sets;
  String? section;
  String? sheetType;
  bool isCustomScore;
  double defaultScore;
  Map<String, Map<String, dynamic>> answerKey;
  List<Map<String, dynamic>> studentsSnapshot;

  ExamModel({
    required this.id,
    required this.name,
    required this.subject,
    this.subjectName = '',
    required this.date,
    required this.questions,
    required this.options,
    required this.sets,
    this.section,
    this.sheetType,
    this.isCustomScore = false,
    this.defaultScore = 1.0,
    required this.answerKey,
    this.studentsSnapshot = const [],
  });

  factory ExamModel.fromMap(String id, Map<String, dynamic> map) {
    final rawAnswerKey = map['answerKey'] ?? map['answerKeys'];

    return ExamModel(
      id: id,
      name: map['name']?.toString() ?? map['exam_name']?.toString() ?? '',
      subject: map['subject']?.toString() ??
          map['subject_id']?.toString() ??
          map['subjectCode']?.toString() ??
          '',
      subjectName: map['subjectName']?.toString() ??
          map['subject_name']?.toString() ??
          map['subject_title']?.toString() ??
          '',
      date: _parseDate(
        map['date']?.toString() ??
            map['examDate']?.toString() ??
            map['exam_date']?.toString() ??
            map['createdAt']?.toString() ??
            map['created_at']?.toString(),
      ),
      questions: int.tryParse(map['questions']?.toString() ?? '') ?? 0,
      options: int.tryParse(map['options']?.toString() ?? '') ?? 5,
      sets: int.tryParse(map['sets']?.toString() ?? '') ?? 1,
      section: map['section']?.toString(),
      sheetType: map['sheetType']?.toString() ?? map['template_id']?.toString(),
      isCustomScore: map['isCustomScore'] == true ||
          map['is_custom_score'] == 1 ||
          map['is_custom_score'] == true,
      defaultScore: double.tryParse(
            map['defaultScore']?.toString() ??
                map['default_score']?.toString() ??
                '1.0',
          ) ??
          1.0,
      answerKey: _parseAnswerKey(rawAnswerKey),
      studentsSnapshot: _parseStudentsSnapshot(map['studentsSnapshot']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'subject': subject,
      if (subjectName.isNotEmpty) 'subjectName': subjectName,
      'date': date,
      'questions': questions,
      'options': options,
      'sets': sets,
      if (section != null) 'section': section,
      if (sheetType != null) 'sheetType': sheetType,
      'isCustomScore': isCustomScore,
      'defaultScore': defaultScore,
      'answerKey': answerKey,
      'studentsSnapshot': studentsSnapshot,
    };
  }

  static String _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    if (raw.length >= 10) return raw.substring(0, 10);
    return raw;
  }

  double getTotalScore(String? setIndex) {
    if (answerKey.isEmpty) return questions.toDouble();

    double total = 0.0;
    Map<String, dynamic> targetSet = {};
    if (setIndex != null && answerKey.containsKey(setIndex)) {
      targetSet = answerKey[setIndex]!;
    } else if (answerKey.containsKey('0')) {
      targetSet = answerKey['0']!;
    } else if (answerKey.containsKey('1')) {
      targetSet = answerKey['1']!;
    } else {
      targetSet = answerKey.values.first;
    }

    if (targetSet.isEmpty) return questions.toDouble();

    for (var i = 1; i <= questions; i++) {
      final qNum = i.toString();
      double qScore = 1.0;
      if (targetSet.containsKey(qNum)) {
        final val = targetSet[qNum];
        if (val is Map && val.containsKey('score')) {
          qScore = double.tryParse(val['score'].toString()) ?? 1.0;
        }
      }
      total += qScore;
    }
    return total;
  }

  double getQuestionScore(String qNum, String? setIndex) {
    if (answerKey.isEmpty) return 1.0;

    Map<String, dynamic> targetSet = {};
    if (setIndex != null && answerKey.containsKey(setIndex)) {
      targetSet = answerKey[setIndex]!;
    } else if (answerKey.containsKey('0')) {
      targetSet = answerKey['0']!;
    } else if (answerKey.containsKey('1')) {
      targetSet = answerKey['1']!;
    } else {
      targetSet = answerKey.values.first;
    }

    if (targetSet.containsKey(qNum)) {
      final val = targetSet[qNum];
      if (val is Map && val.containsKey('score')) {
        return double.tryParse(val['score'].toString()) ?? 1.0;
      }
    }
    return 1.0;
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

    // Check if it's a flat map
    // A flat map can be {"1": "A", "2": "B"} (values are not maps)
    // OR {"1": {"answer": "A", "score": 1.0}} (values are maps, but contain "answer" or "score" keys)
    bool isFlatMap = false;
    if (raw.isNotEmpty) {
      final firstVal = raw.values.first;
      if (firstVal is! Map) {
        isFlatMap = true;
      } else if (firstVal.containsKey('answer') ||
          firstVal.containsKey('score')) {
        isFlatMap = true;
      }
    }

    if (isFlatMap) {
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
