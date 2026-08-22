import 'dart:convert';
import 'dart:io';
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
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';

class AnswerSheetsScreen extends StatefulWidget {
  final ExamModel exam;
  final SubjectModel subject;
  const AnswerSheetsScreen({
    super.key,
    required this.exam,
    required this.subject,
  });
  @override
  State<AnswerSheetsScreen> createState() => _AnswerSheetsScreenState();
}

class _AnswerSheetsScreenState extends State<AnswerSheetsScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';
  static const int _pageSize = 10;
  int _currentPage = 1;
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
    // Always fetch from API to ensure it matches the database
    /*
    if (widget.exam.studentsSnapshot.isNotEmpty) {
      final snapStudents = widget.exam.studentsSnapshot
          .map((raw) => StudentModel.fromMap((raw['id'] ?? '').toString(), raw))
          .toList();
      setState(() {
        _students = snapStudents;
        _isLoadingStudents = false;
      });
      return;
    }
    */
    try {
      final snapDocs = await ApiService.instance.getCollection(
        _uid,
        'students',
      );
      final all = snapDocs
          .map(
            (d) => StudentModel.fromMap(
              d['id']?.toString() ?? d['student_id']?.toString() ?? '',
              d,
            ),
          )
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
    final type = widget.exam.sheetType;
    if (type != null && type.isNotEmpty) {
      if (type.startsWith('30')) return 'แบบ 30 ข้อ';
      if (type.startsWith('50')) return 'แบบ 50 ข้อ';
      if (type.startsWith('100')) return 'แบบ 100 ข้อ';
    }
    final q = widget.exam.questions;
    if (q <= 30) return 'แบบ 30 ข้อ';
    if (q <= 50) return 'แบบ 50 ข้อ';
    return 'แบบ 100 ข้อ';
  }

  Color _templateColor() {
    final type = widget.exam.sheetType;
    if (type != null && type.isNotEmpty) {
      if (type.startsWith('30')) return AppColors.success;
      if (type.startsWith('50')) return AppColors.info;
      if (type.startsWith('100')) return AppColors.warning;
    }
    final q = widget.exam.questions;
    if (q <= 30) return AppColors.success;
    if (q <= 50) return AppColors.info;
    return AppColors.warning;
  }

  Future<void> _downloadPdf() async {
    if (_students.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'ไม่พบรายชื่อผู้เรียน กรุณาเพิ่มผู้เรียนก่อน',
        confirmBtnColor: AppColors.primary,
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
              'students_snapshot': _students
                  .map((student) => student.toMap()..['id'] = student.id)
                  .toList(),
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
        if (!mounted || !context.mounted) return;
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
          confirmBtnColor: AppColors.primary,
        );
      } else {
        throw Exception(_errorMessage(response));
      }
    } catch (e) {
      if (!mounted || !context.mounted) return;
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
      /* ignore */
    }
    return 'เกิดข้อผิดพลาด (${response.statusCode}): ${response.body}';
  }

  @override
  Widget build(BuildContext context) {
    final exam = widget.exam;
    final subject = widget.subject;
    final templateColor = _templateColor();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'กระดาษคำตอบ',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: AppColors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors.textPrimary),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _fetchStudents,
            color: AppColors.primary,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                /* Exam Info Card */ SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border, width: 1.5),
                      boxShadow: AppColors.softShadow,
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
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: AppColors.primaryShadow,
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
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    subject.name,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1.5, color: AppColors.border),
                        const SizedBox(height: 20),
                        _infoRow(
                          FontAwesomeIcons.barcode,
                          'รหัสวิชา',
                          subject.code,
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          FontAwesomeIcons.book,
                          'ชื่อวิชา',
                          subject.name.isNotEmpty ? subject.name : '-',
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          FontAwesomeIcons.fileLines,
                          'ชื่อการทดสอบ',
                          exam.name.isNotEmpty ? exam.name : '-',
                        ),
                        const SizedBox(height: 12),
                        _infoRow(
                          FontAwesomeIcons.solidCalendarDays,
                          'วันที่สร้าง',
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
                            Text(
                              'Template: ',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: templateColor.withValues(alpha: 0.1),
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
                /* Student List Header */ SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          FontAwesomeIcons.users,
                          size: 13,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'รายชื่อผู้เรียน (${_students.length} คน)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                /* Student List */ if (_isLoadingStudents)
                  const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: SpinKitThreeBounce(
                          color: AppColors.primary,
                          size: 32,
                        ),
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
                        border: Border.all(color: AppColors.border, width: 1.5),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            FontAwesomeIcons.userSlash,
                            size: 32,
                            color: AppColors.textMuted,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'ยังไม่มีรายชื่อผู้เรียน\nกรุณาเพิ่มผู้เรียนในวิชานี้ก่อน',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
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
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final totalPages = (_students.length / _pageSize)
                              .ceil()
                              .clamp(1, 1000000);
                          final page = _currentPage.clamp(1, totalPages);
                          final start = (page - 1) * _pageSize;
                          final end = (start + _pageSize).clamp(
                            0,
                            _students.length,
                          );
                          final visibleStudents = _students.sublist(start, end);
                          if (index == visibleStudents.length) {
                            return Column(
                              children: [
                                Text(
                                  'แสดง ${start + 1}-$end จาก ${_students.length} รายการ',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                PaginationBar(
                                  page: page,
                                  totalPages: totalPages,
                                  onPageChanged: (nextPage) {
                                    setState(() => _currentPage = nextPage);
                                  },
                                ),
                              ],
                            );
                          }
                          final student = visibleStudents[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.5,
                              ),
                              boxShadow: AppColors.softShadow,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.primarySoft,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${start + index + 1}',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'รหัส: ${student.code.isNotEmpty ? student.code : student.id}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  FontAwesomeIcons.qrcode,
                                  size: 16,
                                  color: AppColors.textMuted,
                                ),
                              ],
                            ),
                          );
                        },
                        childCount: (_students.length > _pageSize
                            ? ((_students.length -
                                          ((_currentPage - 1) * _pageSize))
                                      .clamp(0, _pageSize) +
                                  1)
                            : _students.length),
                      ),
                    ),
                  ),
                /* Bottom Padding */ const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            ),
          ),

          /* Loading Overlay */
          if (_isGenerating)
            Container(
              color: AppColors.surface.withValues(alpha: 0.8),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SpinKitThreeBounce(color: AppColors.primary, size: 36),
                    SizedBox(height: 20),
                    Text(
                      'กำลังสร้างกระดาษคำตอบ...',
                      style: TextStyle(
                        color: AppColors.primaryDark,
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
      /* Download PDF Button */ bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border, width: 1.5)),
          boxShadow: AppColors.softShadow,
        ),
        child: Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: _students.isEmpty ? AppColors.border : AppColors.primary,
            boxShadow: _students.isEmpty ? null : AppColors.primaryShadow,
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
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
