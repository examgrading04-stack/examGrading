import 'package:cloud_firestore/cloud_firestore.dart';

const sampleExamId = 'demo-midterm-math-m1';

const Map<String, dynamic> sampleExam = {
  'name': 'Demo Midterm Test',
  'subject': 'MATH101',
  'date': '2026-05-23',
  'questions': 10,
  'options': 4,
  'sets': 1,
  'section': '1',
  'answerKey': {
    '1': {
      '1': 'A',
      '2': 'C',
      '3': 'B',
      '4': 'D',
      '5': 'A',
      '6': 'B',
      '7': 'D',
      '8': 'C',
      '9': 'A',
      '10': 'B',
    },
  },
};

const List<Map<String, dynamic>> sampleStudents = [
  {
    'id': 'demo-student-001',
    'code': '67001',
    'name': 'Demo Student A',
    'class': 'M.1/1',
    'sec': '1',
    'section': '1',
  },
  {
    'id': 'demo-student-002',
    'code': '67002',
    'name': 'Demo Student B',
    'class': 'M.1/1',
    'sec': '1',
    'section': '1',
  },
  {
    'id': 'demo-student-003',
    'code': '67003',
    'name': 'Demo Student C',
    'class': 'M.1/1',
    'sec': '1',
    'section': '1',
  },
];

const List<Map<String, dynamic>> sampleResults = [
  {
    'id': 'demo-result-001',
    'examId': sampleExamId,
    'studentId': 'demo-student-001',
    'studentCode': '67001',
    'studentName': 'Demo Student A',
    'score': 9,
    'total': 10,
    'itemResults': {
      '1': true,
      '2': true,
      '3': true,
      '4': true,
      '5': true,
      '6': true,
      '7': true,
      '8': true,
      '9': true,
      '10': false,
    },
    'status': 'completed',
  },
  {
    'id': 'demo-result-002',
    'examId': sampleExamId,
    'studentId': 'demo-student-002',
    'studentCode': '67002',
    'studentName': 'Demo Student B',
    'score': 7,
    'total': 10,
    'itemResults': {
      '1': true,
      '2': true,
      '3': true,
      '4': false,
      '5': true,
      '6': false,
      '7': true,
      '8': true,
      '9': false,
      '10': true,
    },
    'status': 'completed',
  },
  {
    'id': 'demo-result-003',
    'examId': sampleExamId,
    'studentId': 'demo-student-003',
    'studentCode': '67003',
    'studentName': 'Demo Student C',
    'score': 4,
    'total': 10,
    'itemResults': {
      '1': true,
      '2': false,
      '3': true,
      '4': false,
      '5': false,
      '6': false,
      '7': true,
      '8': false,
      '9': false,
      '10': true,
    },
    'status': 'completed',
  },
];

Future<void> seedSampleExamResults(String uid) async {
  final root = FirebaseFirestore.instance.collection('users').doc(uid);
  final batch = FirebaseFirestore.instance.batch();

  batch.set(root.collection('exams').doc(sampleExamId), sampleExam);

  for (final student in sampleStudents) {
    final id = student['id'] as String;
    final payload = Map<String, dynamic>.from(student)..remove('id');
    batch.set(root.collection('students').doc(id), payload);
  }

  for (final result in sampleResults) {
    final id = result['id'] as String;
    final payload = Map<String, dynamic>.from(result)..remove('id');
    payload['timestamp'] = FieldValue.serverTimestamp();
    payload['createdBy'] = 'sample-data';
    batch.set(root.collection('results').doc(id), payload);
  }

  await batch.commit();
}
