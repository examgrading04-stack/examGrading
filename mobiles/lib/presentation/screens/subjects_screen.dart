import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/screens/sections_screen.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';
  static const int _pageSize = 10;
  int _currentPage = 1;
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  // Academic settings จาก /api/settings/academic_year
  String _academicYear = '';
  String _academicTerm = '1';

  @override
  void initState() {
    super.initState();
    _loadSubjects();
    _loadAcademicSettings();
  }

  Future<void> _loadAcademicSettings() async {
    try {
      final settings = await ApiService.instance.getAcademicSettings();
      if (mounted) {
        setState(() {
          _academicYear =
              settings['year']?.toString() ??
              (DateTime.now().year + 543).toString();
          _academicTerm = settings['term']?.toString() ?? '1';
        });
      }
    } catch (_) {
      // ใช้ค่า default ถ้าโหลดไม่ได้
      if (mounted) {
        setState(() {
          _academicYear = (DateTime.now().year + 543).toString();
          _academicTerm = '1';
        });
      }
    }
  }

  Future<void> _loadSubjects() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final docs = await ApiService.instance.getCollection(_uid, 'subjects');
      if (mounted) {
        setState(() {
          _subjects = docs
              .map((d) => SubjectModel.fromMap(d['code']?.toString() ?? '', d))
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSubjectDialog([SubjectModel? subject]) {
    final isEdit = subject != null;
    final codeController = TextEditingController(text: subject?.code);
    final nameController = TextEditingController(text: subject?.name);
    final termText = (subject?.term != null && subject!.term.isNotEmpty)
        ? subject.term
        : _academicTerm;
    final termController = TextEditingController(text: termText);
    final yearController = TextEditingController(
      text: subject?.year.isNotEmpty == true ? subject!.year : _academicYear,
    );
    // ตั้งค่า teacher เริ่มต้นเป็น displayName ของ user เหมือน Web
    final defaultTeacher =
        AuthService.instance.currentUser?['displayName'] as String? ??
        AuthService.instance.currentEmail ??
        '';
    final teacherController = TextEditingController(
      text: subject?.teacher.isNotEmpty == true
          ? subject!.teacher
          : defaultTeacher,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SheetFrame(
          title: isEdit ? 'แก้ไขข้อมูลรายวิชา' : 'เพิ่มข้อมูลรายวิชาใหม่',
          children: [
            _buildField('รหัสวิชา', codeController, FontAwesomeIcons.barcode),
            const SizedBox(height: 20),
            _buildField('ชื่อวิชา', nameController, FontAwesomeIcons.bookOpen),
            const SizedBox(height: 20),
            // ภาคเรียน / ปีการศึกษา - แสดงค่าจากระบบ (read-only เหมือน Web)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    FontAwesomeIcons.layerGroup,
                    color: AppColors.textSecondary,
                    size: 13,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ภาคเรียน / ปีการศึกษา (ค่าจากระบบ)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${termController.text} / ${yearController.text}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildField(
              'ชื่อผู้สอน',
              teacherController,
              FontAwesomeIcons.userTie,
            ),
            const SizedBox(height: 36),
            _buildSubmitButton(
              onPressed: () async {
                if (codeController.text.trim().isEmpty ||
                    nameController.text.trim().isEmpty) {
                  _warn('กรุณากรอกรหัสวิชาและชื่อวิชา');
                  return;
                }

                final data = {
                  'code': codeController.text.trim(),
                  'name': nameController.text.trim(),
                  'term': termController.text.trim(),
                  'year': yearController.text.trim(),
                  'teacher': teacherController.text.trim(),
                };

                if (isEdit) {
                  await ApiService.instance.updateDoc(
                    _uid,
                    'subjects',
                    subject.id,
                    data,
                  );
                } else {
                  final subjectCode = codeController.text.trim();
                  await ApiService.instance.setDoc(
                    _uid,
                    'subjects',
                    subjectCode,
                    data,
                  );
                  // สร้าง default section กลุ่ม 1 อัตโนมัติ (เหมือน Web)
                  final secId = '${subjectCode}_1';
                  await ApiService.instance.setNestedDoc(
                    _uid,
                    'subjects',
                    subjectCode,
                    'sections',
                    secId,
                    {
                      'id': secId,
                      'subject': subjectCode,
                      'sec': '1',
                      'created_at': DateTime.now().toIso8601String(),
                    },
                  );
                }

                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                await _loadSubjects();
                _success(
                  isEdit
                      ? 'แก้ไขข้อมูลรายวิชาเรียบร้อย'
                      : 'เพิ่มข้อมูลรายวิชาเรียบร้อย',
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 12,
          color: AppColors.textMuted,
          fontWeight: FontWeight.w600,
        ),
        hintText: 'กรอก$label',
        hintStyle: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(icon, color: AppColors.textSecondary, size: 13),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSubmitButton({required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: AppColors.primary,
        boxShadow: AppColors.primaryShadow,
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: const Text(
          'บันทึกข้อมูลรายวิชา',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _deleteSubject(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'ยืนยันการลบรายวิชา',
      text:
          'การลบรายวิชาจะลบกลุ่มเรียนและรายชื่อผู้เรียนในรายวิชานี้ด้วย แต่ผลการสอบยังคงเก็บไว้',
      confirmBtnText: 'ลบ',
      cancelBtnText: 'ยกเลิก',
      showCancelBtn: true,
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await _deleteSubjectCascade(id);
        if (!mounted || !context.mounted) return;
        _success('ลบรายวิชาเรียบร้อย');
      },
    );
  }

  Future<void> _deleteSubjectCascade(String subjectId) async {
    // Backend CASCADE จะจัดการลบ sections, enrollments อัตโนมัติ
    await ApiService.instance.deleteDoc(_uid, 'subjects', subjectId);
    await _loadSubjects();
  }

  void _warn(String text) {
    QuickAlert.show(context: context, type: QuickAlertType.warning, text: text);
  }

  void _success(String text) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: text,
      confirmBtnColor: AppColors.primary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          boxShadow: AppColors.primaryShadow,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          hoverElevation: 0,
          focusElevation: 0,
          highlightElevation: 0,
          onPressed: () => _showSubjectDialog(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSubjects,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 60,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.surface,
              iconTheme: IconThemeData(color: AppColors.textPrimary),
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'รายวิชาทั้งหมด',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                background: Container(color: AppColors.surface),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 16)),
            ),
            _buildSubjectsSection(),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectsSection() {
    if (_isLoading) {
      return const SliverToBoxAdapter(child: ListSkeletonLoader());
    }
    return _buildSubjectsSectionContent();
  }

  Widget _buildSubjectsSectionContent() {
    final docs = _subjects;
    if (docs.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      FontAwesomeIcons.folderOpen,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'ยังไม่มีข้อมูลรายวิชา',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'เพิ่มรายวิชาและกลุ่มเรียนก่อน เพื่อเริ่มจัดการข้อมูลผู้เรียนและการสอบ',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return SliverToBoxAdapter(child: _buildSubjectsList(docs));
  }

  Widget _buildSubjectsList(List<SubjectModel> subjects) {
    final totalPages = (subjects.length / _pageSize).ceil().clamp(1, 1000000);
    final page = _currentPage.clamp(1, totalPages);
    if (page != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = page);
      });
    }
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, subjects.length);
    final visibleSubjects = subjects.sublist(start, end);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          ...visibleSubjects.map((subject) {
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: AppColors.softShadow,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SectionsScreen(subject: subject),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(
                          child: Icon(
                            FontAwesomeIcons.book,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  subject.code,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${subject.year}/${subject.term}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              subject.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (subject.teacher.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                subject.teacher,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        children: [
                          GestureDetector(
                            onTap: () => _showSubjectDialog(subject),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.infoSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.solidPenToSquare,
                                  color: AppColors.info,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _deleteSubject(subject.id),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: AppColors.errorSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.trash,
                                  color: AppColors.error,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (subjects.length > _pageSize) ...[
            const SizedBox(height: 4),
            Text(
              'แสดง ${start + 1}-$end จาก ${subjects.length} รายการ',
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
        ],
      ),
    );
  }
}

class _SheetFrame extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SheetFrame({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 28,
        right: 28,
        top: 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 32),
            ...children,
          ],
        ),
      ),
    );
  }
}
