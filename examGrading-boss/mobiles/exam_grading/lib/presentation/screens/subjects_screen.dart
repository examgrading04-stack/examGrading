import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/presentation/screens/sections_screen.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';
  static const int _pageSize = 10;
  int _currentPage = 1;

  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('subjects');

  void _showSubjectDialog([SubjectModel? subject]) {
    final isEdit = subject != null;
    final codeController = TextEditingController(text: subject?.code);
    final nameController = TextEditingController(text: subject?.name);
    final termController = TextEditingController(text: subject?.term);
    final yearController = TextEditingController(text: subject?.year);
    final teacherController = TextEditingController(text: subject?.teacher);

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
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'ภาคเรียน',
                    termController,
                    FontAwesomeIcons.layerGroup,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: _buildField(
                    'ปีการศึกษา',
                    yearController,
                    FontAwesomeIcons.solidCalendarDays,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildField(
              'ชื่ออาจารย์ผู้สอน',
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
                  await _subjectsRef
                      .doc(subject.id)
                      .update(data)
                      .timeout(const Duration(seconds: 15));
                } else {
                  await _subjectsRef
                      .doc(codeController.text.trim())
                      .set(data)
                      .timeout(const Duration(seconds: 15));
                }

                if (!mounted) return;
                Navigator.pop(context);
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
        if (!mounted) return;
        _success('ลบรายวิชาเรียบร้อย');
      },
    );
  }

  Future<void> _deleteSubjectCascade(String subjectId) async {
    final userRoot = FirebaseFirestore.instance.collection('users').doc(_uid);
    final subjectRef = userRoot.collection('subjects').doc(subjectId);
    final subjectSnap = await subjectRef.get();
    final subjectCode = (subjectSnap.data()?['code'] ?? subjectId).toString();

    final sectionsSnapshot = await subjectRef.collection('sections').get();
    final sectionDocIds = sectionsSnapshot.docs.map((d) => d.id).toSet();
    final sectionSecs = sectionsSnapshot.docs
        .map((d) => (d.data()['sec'] ?? d.id).toString())
        .toSet();
    final sectionFullIds = sectionDocIds
        .map((id) => '${subjectId}_$id')
        .toSet();
    final legacySectionFullIds = sectionSecs
        .map((sec) => '${subjectCode}_$sec')
        .toSet();

    final batch = FirebaseFirestore.instance.batch();
    for (final sectionDoc in sectionsSnapshot.docs) {
      batch.delete(sectionDoc.reference);
    }

    final studentsSnapshot = await userRoot.collection('students').get();
    for (final studentDoc in studentsSnapshot.docs) {
      final classId = (studentDoc.data()['class'] ?? '').toString();
      final shouldDelete =
          classId.startsWith('${subjectId}_') ||
          classId.startsWith('${subjectCode}_') ||
          classId == subjectId ||
          classId == subjectCode ||
          sectionFullIds.contains(classId) ||
          legacySectionFullIds.contains(classId);
      if (shouldDelete) batch.delete(studentDoc.reference);
    }

    batch.delete(subjectRef);
    await batch.commit().timeout(const Duration(seconds: 15));
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
      body: CustomScrollView(
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
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'จัดการข้อมูลรายวิชาและกลุ่มเรียน',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryDark,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          _buildSubjectsSection(),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSubjectsSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _uid.isNotEmpty ? _subjectsRef.snapshots() : const Stream.empty(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(child: ListSkeletonLoader());
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 48,
                  horizontal: 24,
                ),
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
        final subjects = docs
            .map((doc) => SubjectModel.fromMap(doc.id, doc.data()))
            .toList();
        return SliverToBoxAdapter(child: _buildSubjectsList(subjects));
      },
    );
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
          }).toList(),
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
