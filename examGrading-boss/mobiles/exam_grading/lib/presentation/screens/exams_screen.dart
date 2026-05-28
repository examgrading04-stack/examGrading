import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/data/models/exam_model.dart';
import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/presentation/screens/answer_key_screen.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';
import 'package:exam_grading/presentation/screens/answer_sheets_screen.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({Key? key}) : super(key: key);
  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';
  List<SubjectModel> _subjects = [];
  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  Future<void> _fetchSubjects() async {
    if (_uid.isEmpty) return;
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('subjects')
        .get();
    setState(() {
      _subjects = snapshot.docs
          .map((doc) => SubjectModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  void _showExamDialog([ExamModel? exam]) {
    final nameController = TextEditingController(text: exam?.name);
    final dateController = TextEditingController(
      text: exam?.date ?? DateTime.now().toString().split(' ')[0],
    );
    final questionsController = TextEditingController(
      text: exam?.questions.toString() ?? '100',
    );
    String? selectedSubjectCode = exam?.subject;
    final isEdit = exam != null;
    if (_subjects.isEmpty && !isEdit) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณาเพิ่มรายวิชาก่อนสร้างข้อสอบ',
        confirmBtnColor: AppColors.primary,
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                      isEdit ? 'แก้ไขข้อมูลข้อสอบ' : 'สร้างข้อสอบใหม่',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildPopupField(
                      'ชื่อการสอบ',
                      nameController,
                      FontAwesomeIcons.solidFileLines,
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      'รายวิชา',
                      selectedSubjectCode,
                      _subjects,
                      (val) => setModalState(() => selectedSubjectCode = val),
                    ),
                    const SizedBox(height: 20),
                    _buildDateField(
                      context,
                      'วันที่สอบ',
                      dateController,
                      (val) => setModalState(() => dateController.text = val),
                    ),
                    const SizedBox(height: 20),
                    _buildPopupField(
                      'จำนวนข้อ',
                      questionsController,
                      FontAwesomeIcons.circleQuestion,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 36),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: AppColors.primary,
                        boxShadow: AppColors.primaryShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              selectedSubjectCode == null) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              text: 'กรุณากรอกข้อมูลให้ครบถ้วน',
                              confirmBtnColor: AppColors.primary,
                            );
                            return;
                          }
                          final data = {
                            'name': nameController.text.trim(),
                            'subject': selectedSubjectCode,
                            'date': dateController.text,
                            'questions':
                                int.tryParse(questionsController.text) ?? 100,
                            'options': 4,
                            'sets': 1,
                          };
                          if (isEdit) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .collection('exams')
                                .doc(exam.id)
                                .update(data)
                                .timeout(const Duration(seconds: 15));
                          } else {
                            data['answerKey'] = {};
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .collection('exams')
                                .doc(
                                  '${selectedSubjectCode}_${nameController.text.trim().replaceAll(' ', '_')}',
                                )
                                .set(data)
                                .timeout(const Duration(seconds: 15));
                          }
                          if (!mounted) return;
                          Navigator.pop(context);
                          if (!isEdit) {
                            final subjectObj = _subjects.firstWhere(
                              (s) => s.code == selectedSubjectCode,
                              orElse: () => _subjects.first,
                            );
                            final examId =
                                '${selectedSubjectCode}_${nameController.text.trim().replaceAll(' ', '_')}';
                            final newExam = ExamModel(
                              id: examId,
                              name: nameController.text.trim(),
                              subject: selectedSubjectCode!,
                              date: dateController.text,
                              questions:
                                  int.tryParse(questionsController.text) ?? 100,
                              options: 4,
                              sets: 1,
                              answerKey: {},
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AnswerSheetsScreen(
                                  exam: newExam,
                                  subject: subjectObj,
                                ),
                              ),
                            );
                          } else {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                              text: 'แก้ไขข้อมูลข้อสอบสำเร็จ',
                              confirmBtnColor: AppColors.primary,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'บันทึกข้อสอบ',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPopupField(
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
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        hintText: 'กรอก$label',
        hintStyle: TextStyle(
          color: AppColors.textMuted.withValues(alpha: 0.5),
          fontWeight: FontWeight.normal,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(icon, color: AppColors.primary, size: 13),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<SubjectModel> subjects,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Icon(
            FontAwesomeIcons.bookOpen,
            color: AppColors.primary,
            size: 13,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
      ),
      value: subjects.any((s) => s.code == value) ? value : null,
      items: subjects
          .map(
            (s) => DropdownMenuItem(
              value: s.code,
              child: Text(
                '${s.code} ${s.name}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.primary,
        size: 20,
      ),
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    TextEditingController controller,
    ValueChanged<String> onSelected,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: AppColors.primary,
                  onPrimary: Colors.white,
                  onSurface: AppColors.textPrimary,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onSelected(date.toString().split(' ')[0]);
        }
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Icon(
            FontAwesomeIcons.solidCalendarDays,
            color: AppColors.primary,
            size: 13,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        filled: true,
        fillColor: AppColors.background,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
        ),
      ),
    );
  }

  void _deleteExam(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'ยืนยันการลบ',
      text: 'คุณแน่ใจหรือไม่ที่จะลบข้อสอบนี้?',
      confirmBtnText: 'ลบ',
      cancelBtnText: 'ยกเลิก',
      showCancelBtn: true,
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('exams')
            .doc(id)
            .delete()
            .timeout(const Duration(seconds: 15));
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'ลบข้อสอบเรียบร้อยแล้ว',
          confirmBtnColor: AppColors.primary,
        );
      },
    );
  }

  void _openAnswerKey(ExamModel exam) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AnswerKeyScreen(exam: exam)),
    );
  }

  void _openAnswerSheets(ExamModel exam) {
    final subjectObj = _subjects.firstWhere(
      (s) => s.code == exam.subject,
      orElse: () => SubjectModel(
        id: '',
        name: 'ไม่ระบุวิชา',
        code: exam.subject,
        term: '',
        year: '',
        teacher: '',
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AnswerSheetsScreen(exam: exam, subject: subjectObj),
      ),
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
          onPressed: () => _showExamDialog(),
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
                'จัดการข้อสอบ',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(color: AppColors.surface),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _uid.isNotEmpty
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(_uid)
                      .collection('exams')
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: ListSkeletonLoader());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
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
                                FontAwesomeIcons.fileLines,
                                size: 24,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'ยังไม่มีข้อมูลข้อสอบ',
                            style: TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'แตะปุ่มเครื่องหมาย + ด้านล่างเพื่อเริ่มสร้างข้อสอบชุดแรก',
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
              final docs = snapshot.data!.docs;
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final exam = ExamModel.fromMap(
                      docs[index].id,
                      docs[index].data() as Map<String, dynamic>,
                    );
                    return _buildExamCard(exam);
                  }, childCount: docs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'วิชา: ${exam.subject}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            FontAwesomeIcons.solidCalendarDays,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'วันที่: ${exam.date}',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppColors.border, width: 1.5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSmallInfo(
                      FontAwesomeIcons.circleQuestion,
                      '${exam.questions} ข้อ',
                    ),
                    const SizedBox(width: 16),
                    _buildSmallInfo(
                      FontAwesomeIcons.layerGroup,
                      '${exam.sets} ชุด',
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildCompactAction(
                      icon: FontAwesomeIcons.key,
                      iconSize: 11,
                      color: AppColors.success,
                      bgColor: AppColors.successSoft,
                      onTap: () => _openAnswerKey(exam),
                    ),
                    const SizedBox(width: 10),
                    _buildCompactAction(
                      icon: FontAwesomeIcons.filePdf,
                      iconSize: 12,
                      color: AppColors.info,
                      bgColor: AppColors.infoSoft,
                      onTap: () => _openAnswerSheets(exam),
                    ),
                    const SizedBox(width: 10),
                    _buildCompactAction(
                      icon: FontAwesomeIcons.solidPenToSquare,
                      iconSize: 12,
                      color: AppColors.warning,
                      bgColor: AppColors.warningSoft,
                      onTap: () => _showExamDialog(exam),
                    ),
                    const SizedBox(width: 10),
                    _buildCompactAction(
                      icon: FontAwesomeIcons.trash,
                      iconSize: 11,
                      color: AppColors.error,
                      bgColor: AppColors.errorSoft,
                      onTap: () => _deleteExam(exam.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactAction({
    required IconData icon,
    required double iconSize,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
