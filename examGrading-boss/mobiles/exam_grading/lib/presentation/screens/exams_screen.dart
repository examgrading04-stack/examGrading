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
        confirmBtnColor: const Color(0xFFD97706),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      isEdit ? 'แก้ไขข้อมูลข้อสอบ' : 'สร้างข้อสอบใหม่',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC2410C),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              selectedSubjectCode == null) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              text: 'กรุณากรอกข้อมูลให้ครบถ้วน',
                              confirmBtnColor: const Color(0xFFD97706),
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
                              confirmBtnColor: const Color(0xFFD97706),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
        hintText: 'กรอก$label',
        hintStyle: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontWeight: FontWeight.normal,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(icon, color: const Color(0xFF64748B), size: 13),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD97706), width: 1.5),
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
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(FontAwesomeIcons.bookOpen, color: Color(0xFF64748B), size: 13),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD97706), width: 1.5),
        ),
      ),
      value: subjects.any((s) => s.code == value) ? value : null,
      items: subjects
          .map(
            (s) => DropdownMenuItem(
              value: s.code,
              child: Text(
                '${s.code} ${s.name}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF64748B)),
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
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
                colorScheme: const ColorScheme.light(
                  primary: Color(0xFFD97706),
                  onPrimary: Colors.white,
                  onSurface: Color(0xFF0F172A),
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
          color: Color(0xFF94A3B8),
          fontWeight: FontWeight.w600,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(FontAwesomeIcons.solidCalendarDays, color: Color(0xFF64748B), size: 13),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFD97706), width: 1.5),
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
          confirmBtnColor: const Color(0xFFD97706),
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
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.35),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
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
            backgroundColor: const Color(0xFFC2410C),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'จัดการข้อสอบ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFC2410C), Color(0xFFF59E0B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.04),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                            decoration: const BoxDecoration(
                              color: Color(0xFFE2E8F0),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(
                                FontAwesomeIcons.fileLines,
                                size: 24,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'ยังไม่มีข้อมูลข้อสอบ',
                            style: TextStyle(
                              color: Color(0xFFC2410C),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'แตะปุ่มเครื่องหมาย + ด้านล่างเพื่อเริ่มสร้างข้อสอบชุดแรก',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
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
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC2410C).withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.2),
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
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'วิชา: ${exam.subject}',
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(FontAwesomeIcons.solidCalendarDays, size: 10, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Text(
                            'วันที่: ${exam.date}',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 11,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
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
                    const SizedBox(width: 12),
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
                      iconSize: 10,
                      color: const Color(0xFF059669),
                      bgColor: const Color(0xFFD1FAE5),
                      onTap: () => _openAnswerKey(exam),
                    ),
                    const SizedBox(width: 10),
                    _buildCompactAction(
                      icon: FontAwesomeIcons.filePdf,
                      iconSize: 11,
                      color: const Color(0xFF2563EB),
                      bgColor: const Color(0xFFDBEAFE),
                      onTap: () => _openAnswerSheets(exam),
                    ),
                    const SizedBox(width: 10),
                    _buildCompactAction(
                      icon: FontAwesomeIcons.solidPenToSquare,
                      iconSize: 11,
                      color: const Color(0xFFD97706),
                      bgColor: const Color(0xFFFFFBEB),
                      onTap: () => _showExamDialog(exam),
                    ),
                    const SizedBox(width: 10),
                    _buildCompactAction(
                      icon: FontAwesomeIcons.trash,
                      iconSize: 10,
                      color: const Color(0xFFEF4444),
                      bgColor: const Color(0xFFFEF2F2),
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
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildSmallInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 11, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
