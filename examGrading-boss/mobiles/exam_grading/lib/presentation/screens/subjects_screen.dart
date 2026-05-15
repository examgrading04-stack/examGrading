import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';

import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/presentation/screens/sections_screen.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({Key? key}) : super(key: key);

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';

  CollectionReference<Map<String, dynamic>> get _subjectsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('subjects');

  @override
  void initState() {
    super.initState();
  }

  void _showSubjectDialog([SubjectModel? subject]) {
    final codeController = TextEditingController(text: subject?.code);
    final nameController = TextEditingController(text: subject?.name);
    final termController = TextEditingController(text: subject?.term);
    final yearController = TextEditingController(text: subject?.year);
    final teacherController = TextEditingController(text: subject?.teacher);
    final isEdit = subject != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _SheetFrame(
          title: isEdit ? 'แก้ไขรายวิชา' : 'เพิ่มรายวิชา',
          children: [
            _buildField('รหัสวิชา', codeController, Icons.code),
            const SizedBox(height: 16),
            _buildField('ชื่อวิชา', nameController, Icons.book_outlined),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    'ภาคเรียน',
                    termController,
                    Icons.calendar_view_day,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildField(
                    'ปีการศึกษา',
                    yearController,
                    Icons.calendar_today,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildField(
              'อาจารย์ผู้สอน',
              teacherController,
              Icons.person_outline,
            ),
            const SizedBox(height: 28),
            _buildSubmitButton(
              color: const Color(0xFF2563EB),
              onPressed: () async {
                if (codeController.text.isEmpty ||
                    nameController.text.isEmpty) {
                  _warn('กรุณากรอกรหัสและชื่อวิชา');
                  return;
                }

                final data = {
                  'code': codeController.text,
                  'name': nameController.text,
                  'term': termController.text,
                  'year': yearController.text,
                  'teacher': teacherController.text,
                };

                if (isEdit) {
                  await _subjectsRef
                      .doc(subject.id)
                      .update(data)
                      .timeout(const Duration(seconds: 15));
                } else {
                  await _subjectsRef
                      .doc(codeController.text)
                      .set(data)
                      .timeout(const Duration(seconds: 15));
                }

                if (!mounted) return;
                Navigator.pop(context);
                _success(isEdit ? 'แก้ไขรายวิชาสำเร็จ' : 'เพิ่มรายวิชาสำเร็จ');
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
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            hintText: 'กรอก$label',
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton({
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
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
    );
  }

  void _deleteSubject(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'ยืนยันการลบ',
      text:
          'คุณแน่ใจหรือไม่ที่จะลบรายวิชานี้? กลุ่มเรียนในวิชานี้จะถูกลบไปด้วย',
      confirmBtnText: 'ลบ',
      cancelBtnText: 'ยกเลิก',
      showCancelBtn: true,
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await _subjectsRef
            .doc(id)
            .delete()
            .timeout(const Duration(seconds: 15));
        if (!mounted) return;
        _success('ลบรายวิชาเรียบร้อยแล้ว');
      },
    );
  }

  void _warn(String text) {
    QuickAlert.show(context: context, type: QuickAlertType.warning, text: text);
  }

  void _success(String text) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      text: text,
      confirmBtnColor: const Color(0xFF2563EB),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2563EB),
        onPressed: () => _showSubjectDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'รายวิชาทั้งหมด',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Text(
                'รายวิชา',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
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
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Center(
                child: Text(
                  'ยังไม่มีข้อมูลรายวิชา',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }

        final subjects = docs
            .map((doc) => SubjectModel.fromMap(doc.id, doc.data()))
            .toList();

        return SliverToBoxAdapter(child: _buildSubjectsTable(subjects));
      },
    );
  }

  Widget _buildSubjectsTable(List<SubjectModel> subjects) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(3),
              1: FlexColumnWidth(1.5),
              2: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: const [
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'รายวิชา',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'ปี/เทอม',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'จัดการ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
              ...subjects.map((subject) {
                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  children: [
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SectionsScreen(subject: subject),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subject.code,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              subject.name,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(
                                  0xFF2563EB,
                                ), // Make it look clickable
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        '${subject.year}/${subject.term}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.penToSquare,
                            color: Color(0xFF2563EB),
                            size: 16,
                          ),
                          onPressed: () => _showSubjectDialog(subject),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          icon: const Icon(
                            FontAwesomeIcons.trashCan,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                          onPressed: () => _deleteSubject(subject.id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ],
                );
              }).toList(),
            ],
          ),
        ),
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
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 24),
            ...children,
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
