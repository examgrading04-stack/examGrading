import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';
import 'package:exam_grading/data/models/student_model.dart';
import 'package:exam_grading/data/models/subject_model.dart';

class SectionOption {
  final String id;
  final String subjectCode;
  final String sec;
  final String subjectId;
  final String sectionId;

  SectionOption(
    this.id,
    this.subjectCode,
    this.sec,
    this.subjectId,
    this.sectionId,
  );

  String get displayName => '$subjectCode - Sec $sec';
}

class StudentsScreen extends StatefulWidget {
  const StudentsScreen({Key? key}) : super(key: key);

  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';
  List<SubjectModel> _subjects = [];
  List<SectionOption> _sections = [];
  String? _filterSubjectId;
  String? _filterSectionId;

  @override
  void initState() {
    super.initState();
    _fetchSections();
  }

  Future<void> _fetchSections() async {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.isEmpty) return;

    try {
      final subjectsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('subjects')
          .get();

      List<SubjectModel> subjects = subjectsSnapshot.docs
          .map((doc) => SubjectModel.fromMap(doc.id, doc.data()))
          .toList();

      List<SectionOption> options = [];
      for (var subjectDoc in subjectsSnapshot.docs) {
        final subjectCode = subjectDoc.data()['code'] ?? '';
        final sectionsSnapshot = await subjectDoc.reference
            .collection('sections')
            .get();
        for (var sectionDoc in sectionsSnapshot.docs) {
          final sec = sectionDoc.data()['sec'] ?? '';
          final id = '${subjectDoc.id}_${sectionDoc.id}';
          options.add(
            SectionOption(id, subjectCode, sec, subjectDoc.id, sectionDoc.id),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _sections = options;
      });
    } catch (e) {
      debugPrint('Error fetching sections: $e');
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          text: 'ไม่สามารถโหลดข้อมูลกลุ่มเรียนได้: $e',
        );
      }
    }
  }

  void _showStudentDialog([StudentModel? student]) {
    final codeController = TextEditingController(text: student?.code);
    final nameController = TextEditingController(text: student?.name);
    String? selectedSectionId = student?.className;
    final isEdit = student != null;

    if (_sections.isEmpty && !isEdit) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณาเพิ่มกลุ่มเรียนก่อนเพิ่มผู้เรียน',
        confirmBtnColor: const Color(0xFF059669),
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
                      isEdit ? 'แก้ไขข้อมูลผู้เรียน' : 'เพิ่มผู้เรียนใหม่',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildPopupField(
                      'รหัสนักศึกษา',
                      codeController,
                      FontAwesomeIcons.idCard,
                    ),
                    const SizedBox(height: 20),
                    _buildPopupField(
                      'ชื่อ-นามสกุล',
                      nameController,
                      FontAwesomeIcons.solidUser,
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      'กลุ่มเรียน',
                      selectedSectionId,
                      _sections,
                      (val) => setModalState(() => selectedSectionId = val),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF059669), Color(0xFF10B981)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (codeController.text.isEmpty ||
                              nameController.text.isEmpty ||
                              selectedSectionId == null) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              text: 'กรุณากรอกข้อมูลให้ครบถ้วน',
                              confirmBtnColor: const Color(0xFF059669),
                            );
                            return;
                          }

                          final data = {
                            'code': codeController.text,
                            'name': nameController.text,
                            'class': selectedSectionId,
                          };

                          if (isEdit) {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .collection('students')
                                .doc(student.id)
                                .update(data)
                                .timeout(const Duration(seconds: 15));
                          } else {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(_uid)
                                .collection('students')
                                .doc(codeController.text)
                                .set(data)
                                .timeout(const Duration(seconds: 15));
                          }

                          if (!mounted) return;
                          Navigator.pop(context);
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            text: isEdit
                                ? 'แก้ไขข้อมูลผู้เรียนสำเร็จ'
                                : 'เพิ่มผู้เรียนสำเร็จ',
                            confirmBtnColor: const Color(0xFF059669),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'บันทึกข้อมูลผู้เรียน',
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
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF059669),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        hintText: 'กรอก$label',
        hintStyle: const TextStyle(
          color: Color(0xFFCBD5E1),
          fontWeight: FontWeight.normal,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(icon, color: const Color(0xFF059669), size: 13),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2.0),
        ),
      ),
    );
  }

  Widget _buildDropdownField(
    String label,
    String? value,
    List<SectionOption> sections,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      borderRadius: BorderRadius.circular(16),
      dropdownColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: Color(0xFF059669),
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Icon(FontAwesomeIcons.users, color: Color(0xFF059669), size: 13),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF10B981), width: 2.0),
        ),
      ),
      value: sections.any((s) => s.id == value) ? value : null,
      items: sections
          .map(
            (s) => DropdownMenuItem(
              value: s.id,
              child: Text(
                s.displayName,
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
      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF059669), size: 20),
    );
  }

  void _deleteStudent(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'ยืนยันการลบ',
      text: 'คุณแน่ใจหรือไม่ที่จะลบผู้เรียนนี้?',
      confirmBtnText: 'ลบ',
      cancelBtnText: 'ยกเลิก',
      showCancelBtn: true,
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('students')
            .doc(id)
            .delete()
            .timeout(const Duration(seconds: 15));
        if (!mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'ลบข้อมูลผู้เรียนเรียบร้อยแล้ว',
          confirmBtnColor: const Color(0xFF059669),
        );
      },
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
            colors: [Color(0xFF059669), Color(0xFF10B981)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10B981).withOpacity(0.35),
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
          onPressed: () => _showStudentDialog(),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF065F46),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'จัดการผู้เรียน',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF065F46), Color(0xFF10B981)],
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ตัวกรองวิชาและกลุ่มเรียน',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: _filterSubjectId != null ? const Color(0xFFECFDF5) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _filterSubjectId != null ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                              width: _filterSubjectId != null ? 1.8 : 1.0,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(16),
                              dropdownColor: Colors.white,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: _filterSubjectId != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                size: 18,
                              ),
                              decoration: InputDecoration(
                                prefixIcon: Icon(
                                  FontAwesomeIcons.bookOpen,
                                  color: _filterSubjectId != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                  size: 13,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
                              ),
                              value: _filterSubjectId,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text(
                                    'ทุกวิชาเรียน',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                  ),
                                ),
                                ..._subjects.map(
                                  (s) => DropdownMenuItem<String>(
                                    value: s.id,
                                    child: Text(
                                      s.name,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                    ),
                                  ),
                                ),
                              ],
                              onChanged: (val) => setState(() {
                                _filterSubjectId = val;
                                _filterSectionId = null;
                              }),
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                            ),
                          ),
                        ),
                      ),
                      if (_filterSubjectId != null) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: _filterSectionId != null ? const Color(0xFFECFDF5) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _filterSectionId != null ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                width: _filterSectionId != null ? 1.8 : 1.0,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                borderRadius: BorderRadius.circular(16),
                                dropdownColor: Colors.white,
                                icon: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: _filterSectionId != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                  size: 18,
                                ),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.users,
                                    color: _filterSectionId != null ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                                    size: 13,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 0),
                                ),
                                value: _filterSectionId,
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'ทุกกลุ่มเรียน',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                    ),
                                  ),
                                  ..._sections
                                      .where((s) => s.subjectId == _filterSubjectId)
                                      .map(
                                        (s) => DropdownMenuItem(
                                          value: s.id,
                                          child: Text(
                                            'Sec ${s.sec}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                          ),
                                        ),
                                      ),
                                ],
                                onChanged: (val) =>
                                    setState(() => _filterSectionId = val),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: (FirebaseAuth.instance.currentUser?.email ?? '').isNotEmpty
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.email)
                      .collection('students')
                      .where(
                        'class',
                        isGreaterThanOrEqualTo: _filterSubjectId != null
                            ? '${_filterSubjectId}_'
                            : null,
                      )
                      .where(
                        'class',
                        isLessThan: _filterSubjectId != null
                            ? '${_filterSubjectId}_\uf8ff'
                            : null,
                      )
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: ListSkeletonLoader());
              }

              var docs = snapshot.data?.docs ?? [];
              final students = docs
                  .map(
                    (doc) => StudentModel.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .where((student) {
                    if (_filterSectionId != null)
                      return student.className == _filterSectionId;
                    if (_filterSubjectId != null)
                      return student.className.startsWith(
                        '${_filterSubjectId}_',
                      );
                    return true;
                  })
                  .toList();

              if (students.isEmpty) {
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
                                FontAwesomeIcons.usersSlash,
                                size: 24,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            'ไม่พบข้อมูลผู้เรียน',
                            style: TextStyle(
                              color: Color(0xFF065F46),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'คุณยังไม่มีผู้เรียนในวิชานี้ หรือกรองข้อมูลไม่ตรง',
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

              return SliverToBoxAdapter(
                child: _buildStudentsTable(students),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStudentsTable(List<StudentModel> students) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF065F46).withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.8),
              1: FlexColumnWidth(2.2),
              2: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                children: const [
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Text(
                      'ผู้เรียน',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Text(
                      'กลุ่ม/วิชา',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    child: Text(
                      'จัดการ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              ...students.map((student) {
                String subjectName = '-';
                String sectionName = 'ไม่ระบุ';
                try {
                  final section = _sections.firstWhere(
                    (s) => s.id == student.className,
                  );
                  sectionName = section.sec;
                  subjectName = _subjects
                      .firstWhere((s) => s.id == section.subjectId)
                      .name;
                } catch (e) {
                  // ignore
                }

                return TableRow(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            student.code,
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
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD1FAE5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Sec $sectionName',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subjectName,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => _showStudentDialog(student),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD1FAE5),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.solidPenToSquare,
                                  color: Color(0xFF059669),
                                  size: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _deleteStudent(student.id),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFEF2F2),
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  FontAwesomeIcons.trash,
                                  color: Color(0xFFEF4444),
                                  size: 11,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
