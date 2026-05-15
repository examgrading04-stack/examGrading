import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import '../widgets/skeleton_loader.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/student_model.dart';
import '../models/subject_model.dart';

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

  String get displayName => '$subjectCode - $sec';
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
          final id =
              '${subjectDoc.id}_${sectionDoc.id}'; // Unique ID for dropdown
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
                      isEdit ? 'แก้ไขข้อมูลผู้เรียน' : 'เพิ่มผู้เรียนใหม่',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'กรุณากรอกข้อมูลผู้เรียนให้ครบถ้วน',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 24),
                    _buildPopupField(
                      'รหัสนักศึกษา',
                      codeController,
                      Icons.badge_outlined,
                    ),
                    const SizedBox(height: 16),
                    _buildPopupField(
                      'ชื่อ-นามสกุล',
                      nameController,
                      Icons.person_outline,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdownField(
                      'กลุ่มเรียน',
                      selectedSectionId,
                      _sections,
                      (val) => setModalState(() => selectedSectionId = val),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
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
                                ? 'แก้ไขข้อมูลสำเร็จ'
                                : 'เพิ่มผู้เรียนสำเร็จ',
                            confirmBtnColor: const Color(0xFF8B5CF6),
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
    IconData icon,
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
            style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
              hintText: 'กรอก$label',
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
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
    List<SectionOption> sections,
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
                Icons.group_outlined,
                color: Color(0xFF94A3B8),
                size: 18,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            value: sections.any((s) => s.id == value) ? value : null,
            items: sections
                .map(
                  (s) =>
                      DropdownMenuItem(value: s.id, child: Text(s.displayName)),
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
        Navigator.pop(context); // ปิด QuickAlert
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
          confirmBtnColor: const Color(0xFF8B5CF6),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B5CF6),
        onPressed: () => _showStudentDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF8B5CF6),
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
                    colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
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
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'กรองข้อมูล',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(
                              Icons.book_outlined,
                              color: Color(0xFF94A3B8),
                              size: 16,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 4),
                            hintText: 'กรองวิชา',
                          ),
                          value: _filterSubjectId,
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text(
                                'ทุกวิชา',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                            ..._subjects.map(
                              (s) => DropdownMenuItem<String>(
                                value: s.id,
                                child: Text(
                                  s.name,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) => setState(() {
                            _filterSubjectId = val;
                            _filterSectionId = null; // Reset section filter
                          }),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      if (_filterSubjectId != null)
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(
                                Icons.filter_list,
                                color: Color(0xFF94A3B8),
                                size: 16,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              hintText: 'กลุ่มเรียน',
                            ),
                            value: _filterSectionId,
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text(
                                  'ทุกกลุ่ม',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                              ..._sections
                                  .where((s) => s.subjectId == _filterSubjectId)
                                  .map(
                                    (s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(
                                        s.sec,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ),
                            ],
                            onChanged: (val) =>
                                setState(() => _filterSectionId = val),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
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
                return const SliverToBoxAdapter(
                  child: ListSkeletonLoader(),
                );
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
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.userGraduate,
                          size: 60,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'ยังไม่มีข้อมูลผู้เรียน',
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

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final student = students[index];

                    String subjectName = '-';
                    String sectionName = 'ไม่ทราบ';
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

                    return _buildStudentCard(student, subjectName, sectionName);
                  }, childCount: students.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildStudentCard(
    StudentModel student,
    String subjectName,
    String sectionName,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Icon(
              FontAwesomeIcons.userGraduate,
              color: Colors.white,
              size: 22,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              student.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'วิชา: $subjectName',
              style: const TextStyle(
                color: Color(0xFF8B5CF6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'กลุ่ม: $sectionName',
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'รหัส: ${student.code}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: Color(0xFF94A3B8),
              letterSpacing: 1,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.penToSquare,
                color: Color(0xFF64748B),
                size: 16,
              ),
              onPressed: () => _showStudentDialog(student),
            ),
            IconButton(
              icon: const Icon(
                FontAwesomeIcons.trashCan,
                color: Color(0xFFEF4444),
                size: 16,
              ),
              onPressed: () => _deleteStudent(student.id),
            ),
          ],
        ),
      ),
    );
  }
}
