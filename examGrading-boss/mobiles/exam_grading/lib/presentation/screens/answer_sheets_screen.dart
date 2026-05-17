import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quickalert/quickalert.dart';

import 'package:exam_grading/config/api_config.dart';
import 'package:exam_grading/data/models/exam_model.dart';
import 'package:exam_grading/data/models/student_model.dart';
import 'package:exam_grading/data/models/subject_model.dart';

class AnswerSheetsScreen extends StatefulWidget {
  final ExamModel exam;
  final SubjectModel subject;

  const AnswerSheetsScreen({
    Key? key,
    required this.exam,
    required this.subject,
  }) : super(key: key);

  @override
  State<AnswerSheetsScreen> createState() => _AnswerSheetsScreenState();
}

class _AnswerSheetsScreenState extends State<AnswerSheetsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';
  List<StudentModel> _students = [];
  bool _isLoadingStudents = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    if (_uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('students')
          .get();

      final all = snap.docs
          .map((d) => StudentModel.fromMap(d.id, d.data()))
          .toList();

      final filtered = all.where((s) {
        final classStr = s.className;
        final examSec = widget.exam.section?.toString() ?? '';
        if (examSec.isNotEmpty) {
          return classStr == '${widget.subject.code}_$examSec';
        }
        return classStr.startsWith('${widget.subject.code}_');
      }).toList();

      setState(() {
        _students = filtered.isNotEmpty ? filtered : all;
        _isLoadingStudents = false;
      });
    } catch (e) {
      setState(() => _isLoadingStudents = false);
    }
  }

  String _templateLabel() {
    final q = widget.exam.questions;
    if (q <= 30) return 'แบบ 30 ข้อ';
    if (q <= 50) return 'แบบ 50 ข้อ';
    return 'แบบ 100 ข้อ';
  }

  Color _templateColor() {
    final q = widget.exam.questions;
    if (q <= 30) return const Color(0xFF10B981);
    if (q <= 50) return const Color(0xFF2563EB);
    return const Color(0xFFF59E0B);
  }

  Future<void> _downloadPdf() async {
    if (_students.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'ไม่พบรายชื่อผู้เรียน กรุณาเพิ่มผู้เรียนก่อน',
        confirmBtnColor: const Color(0xFF4F46E5),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final response = await http
          .post(
            ApiConfig.endpoint('/api/sheets/pdf/download'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'exam_id': widget.exam.id,
              'student_ids': _students.map((student) => student.id).toList(),
              'user_email': _uid,
              'upload_to_storage': false,
            }),
          )
          .timeout(
            const Duration(seconds: 180),
            onTimeout: () => throw Exception(
              'หมดเวลาเชื่อมต่อ Server: ${ApiConfig.baseUrl}',
            ),
          );

      if (response.statusCode == 200) {
        final file = await _savePdf(response.bodyBytes);
        final openResult = await OpenFilex.open(
          file.path,
          type: 'application/pdf',
        );

        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: openResult.type == ResultType.done
              ? QuickAlertType.success
              : QuickAlertType.warning,
          title: openResult.type == ResultType.done
              ? 'เปิด PDF แล้ว'
              : 'บันทึก PDF แล้ว',
          text: openResult.type == ResultType.done
              ? 'กระดาษคำตอบสำหรับ ${_students.length} คนพร้อมใช้งาน'
              : 'ไฟล์ถูกบันทึกไว้ที่ ${file.path}\n${openResult.message}',
          confirmBtnText: 'ตกลง',
          confirmBtnColor: const Color(0xFF4F46E5),
        );
      } else {
        throw Exception(_errorMessage(response));
      }
    } catch (e) {
      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<File> _savePdf(List<int> bytes) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final outputDir = Directory('${documentsDir.path}/answer_sheets');
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    final examName = _safeFileName(
      widget.exam.name.isNotEmpty ? widget.exam.name : widget.exam.id,
    );
    final subjectCode = _safeFileName(widget.subject.code);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${outputDir.path}/${examName}_${subjectCode}_answer_sheets_$timestamp.pdf',
    );

    return file.writeAsBytes(bytes, flush: true);
  }

  String _safeFileName(String value) {
    final cleaned = value
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    return cleaned.isEmpty ? 'exam' : cleaned;
  }

  String _errorMessage(http.Response response) {
    try {
      final body = json.decode(utf8.decode(response.bodyBytes));
      if (body is Map && body['detail'] != null) {
        return body['detail'].toString();
      }
    } catch (_) {
      // ignore
    }
    return 'เกิดข้อผิดพลาด (${response.statusCode}): ${response.body}';
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final subject = widget.subject;
    final templateColor = _templateColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'กระดาษคำตอบ',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Exam Info Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                FontAwesomeIcons.solidFileLines,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.name,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  subject.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 20),
                      _infoRow(
                        FontAwesomeIcons.barcode,
                        'รหัสวิชา',
                        subject.code,
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        FontAwesomeIcons.solidCalendarDays,
                        'วันที่สอบ',
                        exam.date.isNotEmpty ? exam.date : '-',
                      ),
                      const SizedBox(height: 12),
                      _infoRow(
                        FontAwesomeIcons.circleQuestion,
                        'จำนวนข้อ',
                        '${exam.questions} ข้อ',
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.solidFileImage,
                            size: 13,
                            color: templateColor,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Template: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: templateColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _templateLabel(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: templateColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Student List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.users,
                        size: 13,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'รายชื่อผู้เรียน (${_students.length} คน)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // Student List
              if (_isLoadingStudents)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: SpinKitThreeBounce(color: Color(0xFF4F46E5), size: 32),
                    ),
                  ),
                )
              else if (_students.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.userSlash,
                          size: 32,
                          color: Color(0xFF94A3B8),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'ยังไม่มีรายชื่อผู้เรียน\nกรุณาเพิ่มผู้เรียนในวิชานี้ก่อน',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final student = _students[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F172A).withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFEEF2FF),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF4F46E5),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'รหัส: ${student.code}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontFamily: 'monospace',
                                      color: Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              FontAwesomeIcons.qrcode,
                              size: 14,
                              color: Color(0xFF94A3B8),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _students.length),
                  ),
                ),

              // Bottom Padding
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Loading Overlay
          if (_isGenerating)
            Container(
              color: const Color(0xFF0F172A).withOpacity(0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitThreeBounce(color: Colors.white, size: 36),
                    SizedBox(height: 20),
                    Text(
                      'กำลังสร้างกระดาษคำตอบ...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // Download PDF Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F172A).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: _students.isEmpty
                ? null
                : const LinearGradient(
                    colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                  ),
            color: _students.isEmpty ? const Color(0xFFE2E8F0) : null,
            boxShadow: _students.isEmpty
                ? null
                : [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withOpacity(0.35),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: ElevatedButton.icon(
            onPressed: _isGenerating || _students.isEmpty ? null : _downloadPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              disabledBackgroundColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: const Icon(
              FontAwesomeIcons.solidFilePdf,
              color: Colors.white,
              size: 16,
            ),
            label: Text(
              _students.isEmpty
                  ? 'ไม่มีผู้เรียน'
                  : 'สร้างกระดาษคำตอบ (${_students.length} ชุด)',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
