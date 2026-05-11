import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/exam_model.dart';
import '../models/subject_model.dart';
import 'answer_key_screen.dart';

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
    final optionsController = TextEditingController(
      text: exam?.options.toString() ?? '4',
    );
    final setsController = TextEditingController(
      text: exam?.sets.toString() ?? '1',
    );
    String? selectedSubjectCode = exam?.subject;
    final isEdit = exam != null;

    if (_subjects.isEmpty && !isEdit) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณาเพิ่มรายวิชาก่อนสร้างข้อสอบ',
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
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
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
                    const SizedBox(height: 20),
                    Text(
                      isEdit ? 'แก้ไขข้อมูลข้อสอบ' : 'สร้างข้อสอบใหม่',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'กรุณากรอกข้อมูลการสอบให้ครบถ้วน',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    _buildPopupField(
                      'ชื่อการสอบ',
                      nameController,
                      Icons.edit_note,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      'รายวิชา',
                      selectedSubjectCode,
                      _subjects,
                      (val) => setModalState(() => selectedSubjectCode = val),
                    ),
                    const SizedBox(height: 16),
                    _buildDateField(
                      context,
                      'วันที่สอบ',
                      dateController,
                      (val) => setModalState(() => dateController.text = val),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPopupField(
                            'จำนวนข้อ',
                            questionsController,
                            Icons.quiz_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildPopupField(
                            'ตัวเลือก',
                            optionsController,
                            Icons.list_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildPopupField(
                      'จำนวนชุดข้อสอบ',
                      setsController,
                      Icons.copy_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
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
                            );
                            return;
                          }

                          final data = {
                            'name': nameController.text,
                            'subject': selectedSubjectCode,
                            'date': dateController.text,
                            'questions':
                                int.tryParse(questionsController.text) ?? 100,
                            'options':
                                int.tryParse(optionsController.text) ?? 4,
                            'sets': int.tryParse(setsController.text) ?? 1,
                          };

                          if (isEdit) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .collection('exams')
                                .doc(exam.id)
                                .update(data);
                          } else {
                            data['answerKey'] = {};
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .collection('exams')
                                .doc('${selectedSubjectCode}_${nameController.text.trim()}').set(data);
                          }

                          if (!mounted) return;
                          Navigator.pop(context);
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            text: isEdit
                                ? 'แก้ไขข้อสอบสำเร็จ'
                                : 'สร้างข้อสอบสำเร็จ',
                            confirmBtnColor: const Color(0xFFF59E0B),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'บันทึกข้อมูล',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<SubjectModel> subjects,
    ValueChanged<String?> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.book_outlined,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            value: subjects.any((s) => s.code == value) ? value : null,
            items: subjects
                .map(
                  (s) => DropdownMenuItem(
                    value: s.code,
                    child: Text('${s.code} ${s.name}'),
                  ),
                )
                .toList(),
            onChanged: onChanged,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    TextEditingController controller,
    ValueChanged<String> onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF64748B),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            readOnly: true,
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) {
                onSelected(date.toString().split(' ')[0]);
              }
            },
            decoration: const InputDecoration(
              prefixIcon: Icon(
                Icons.calendar_today_outlined,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 12,
              ),
            ),
          ),
        ),
      ],
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
        Navigator.pop(context); // ปิด QuickAlert
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('exams')
            .doc(id)
            .delete();
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'ลบข้อสอบเรียบร้อยแล้ว',
          confirmBtnColor: const Color(0xFFF59E0B),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF59E0B),
        onPressed: () => _showExamDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFF59E0B),
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
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
                          color: Colors.white.withOpacity(0.1),
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
                return const SliverFillRemaining(
                  child: Center(
                    child: SpinKitCircle(color: Color(0xFFF59E0B), size: 50.0),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.fileLines,
                          size: 60,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ยังไม่มีข้อมูลข้อสอบ',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final docs = snapshot.data!.docs;
              return SliverPadding(
                padding: const EdgeInsets.all(20),
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
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
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
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
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
                      FontAwesomeIcons.filePen,
                      color: Colors.white,
                      size: 20,
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
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'วิชา: ${exam.subject}',
                        style: const TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'วันที่: ${exam.date}',
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12,
                        ),
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
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildSmallInfo(
                      FontAwesomeIcons.solidCircleQuestion,
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
                  children: [
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.key,
                        color: Color(0xFF059669),
                        size: 16,
                      ),
                      onPressed: () => _openAnswerKey(exam),
                      tooltip: 'กำหนดเฉลย',
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.penToSquare,
                        color: Color(0xFF64748B),
                        size: 16,
                      ),
                      onPressed: () => _showExamDialog(exam),
                    ),
                    IconButton(
                      icon: const Icon(
                        FontAwesomeIcons.trashCan,
                        color: Color(0xFFEF4444),
                        size: 16,
                      ),
                      onPressed: () => _deleteExam(exam.id),
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

  Widget _buildSmallInfo(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: const Color(0xFF64748B)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
