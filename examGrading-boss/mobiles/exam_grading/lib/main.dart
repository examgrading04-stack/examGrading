import 'package:exam_grading/app/exam_scanner_app.dart';
import 'package:exam_grading/config/api_config.dart';
import 'package:exam_grading/config/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(options: firebaseOptions);
  debugPrint('FastAPI URL: ${ApiConfig.baseUrl} (${ApiConfig.source})');

  runApp(const ExamScannerApp());
}
