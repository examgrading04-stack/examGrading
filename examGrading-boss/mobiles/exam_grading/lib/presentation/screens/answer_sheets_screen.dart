import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
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
      // Fetch students registered under this subject
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('students')
          .get();

      final all = snap.docs
          .map((d) => StudentModel.fromMap(d.id, d.data()))
          .toList();

      // Filter students based on SUBJECT_SECTION format
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
        // Save temp PDF and open
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'สร้าง PDF สำเร็จ',
          text: 'กระดาษคำตอบสำหรับ ${_students.length} คนพร้อมแล้ว',
          confirmBtnText: 'ตกลง',
          confirmBtnColor: const Color(0xFF2563EB),
        );
      } else {
        final body = json.decode(response.body);
        throw Exception(body['detail'] ?? 'เกิดข้อผิดพลาด');
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
        backgroundColor: const Color(0xFF2563EB),
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
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              FontAwesomeIcons.fileLines,
                              color: Color(0xFF2563EB),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exam.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  subject.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      const SizedBox(height: 16),
                      _infoRow(
                        FontAwesomeIcons.barcode,
                        'รหัสวิชา',
                        subject.code,
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        FontAwesomeIcons.calendarDay,
                        'วันที่สอบ',
                        exam.date.isNotEmpty ? exam.date : '-',
                      ),
                      const SizedBox(height: 10),
                      _infoRow(
                        FontAwesomeIcons.circleQuestion,
                        'จำนวนข้อ',
                        '${exam.questions} ข้อ',
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.fileImage,
                            size: 14,
                            color: templateColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Template: ',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: templateColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _templateLabel(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
                    horizontal: 16,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        FontAwesomeIcons.users,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'รายชื่อผู้เรียน (${_students.length} คน)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 8)),

              // Student List
              if (_isLoadingStudents)
                const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: SpinKitCircle(color: Color(0xFF2563EB), size: 40),
                    ),
                  ),
                )
              else if (_students.isEmpty)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          FontAwesomeIcons.userXmark,
                          size: 36,
                          color: Color(0xFFCBD5E1),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'ยังไม่มีรายชื่อผู้เรียน\nกรุณาเพิ่มผู้เรียนในวิชานี้ก่อน',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final student = _students[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB).withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    student.name,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                  Text(
                                    'รหัส: ${student.code}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              FontAwesomeIcons.qrcode,
                              size: 14,
                              color: Color(0xFFCBD5E1),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _students.length),
                  ),
                ),

              // Bottom Padding for FAB
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),

          // Loading Overlay
          if (_isGenerating)
            Container(
              color: Colors.black.withOpacity(0.45),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitCircle(color: Colors.white, size: 60),
                    SizedBox(height: 16),
                    Text(
                      'กำลังสร้างกระดาษคำตอบ...',
                      style: TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),

      // Download PDF Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _isGenerating || _students.isEmpty ? null : _downloadPdf,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              disabledBackgroundColor: const Color(0xFFCBD5E1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: const Icon(
              FontAwesomeIcons.filePdf,
              color: Colors.white,
              size: 18,
            ),
            label: Text(
              _students.isEmpty
                  ? 'ไม่มีผู้เรียน'
                  : 'สร้างกระดาษคำตอบ (${_students.length} ชุด)',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
        Icon(icon, size: 14, color: const Color(0xFF64748B)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
