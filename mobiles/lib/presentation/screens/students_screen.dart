import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';
import 'package:exam_grading/data/models/student_model.dart';
import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';

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
  const StudentsScreen({super.key});
  @override
  State<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends State<StudentsScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';
  static const int _pageSize = 10;
  int _currentPage = 1;
  List<SubjectModel> _subjects = [];
  List<SectionOption> _sections = [];
  List<StudentModel> _students = [];
  bool _isLoading = true;
  String? _filterSubjectId;
  String? _filterSectionId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    final email = _uid;
    if (email.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final subjectDocs = await ApiService.instance.getCollection(
        email,
        'subjects',
      );
      final subjects = subjectDocs
          .map((d) => SubjectModel.fromMap(d['code']?.toString() ?? '', d))
          .toList();
      List<SectionOption> options = [];
      for (var subjectDoc in subjectDocs) {
        final subjectId =
            subjectDoc['id']?.toString() ??
            subjectDoc['subject_id']?.toString() ??
            subjectDoc['code']?.toString() ??
            '';
        final subjectCode = subjectDoc['code']?.toString() ?? '';
        final sectionDocs = await ApiService.instance.getNestedCollection(
          email,
          'subjects',
          subjectId,
          'sections',
        );
        for (var sectionDoc in sectionDocs) {
          final sectionId =
              sectionDoc['id']?.toString() ??
              sectionDoc['section_id']?.toString() ??
              '';
          final sec = sectionDoc['sec']?.toString() ?? '';
          final id = '${subjectCode}_$sectionId';
          options.add(
            SectionOption(id, subjectCode, sec, subjectId, sectionId),
          );
        }
      }
      final studentDocs = await ApiService.instance.getCollection(
        email,
        'students',
      );
      final students = studentDocs
          .map(
            (d) => StudentModel.fromMap(
              d['id']?.toString() ?? d['student_id']?.toString() ?? '',
              d,
            ),
          )
          .toList();
      if (!mounted || !context.mounted) return;
      setState(() {
        _subjects = subjects;
        _sections = options;
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showStudentDialog([StudentModel? student]) {
    final codeController = TextEditingController(text: student?.code);
    final nameController = TextEditingController(text: student?.name);
    String? selectedSectionId = student?.className;
    String? selectedSubjectId;
    if (selectedSectionId != null) {
      final sectionOpt = _sections.cast<SectionOption?>().firstWhere(
        (s) => s?.id == selectedSectionId,
        orElse: () => null,
      );
      selectedSubjectId = sectionOpt?.subjectId;
    }
    final isEdit = student != null;
    if (_sections.isEmpty && !isEdit) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'ยังไม่มีกลุ่มเรียน กรุณาสร้างกลุ่มเรียนก่อนเพิ่มผู้เรียน',
        confirmBtnColor: AppColors.success,
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
                      isEdit ? 'แก้ไขข้อมูลผู้เรียน' : 'เพิ่มผู้เรียน',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successDark,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildPopupField(
                      'รหัสนักเรียน',
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
                    _buildSubjectDropdownField(
                      'วิชา',
                      selectedSubjectId,
                      _subjects,
                      (val) => setModalState(() {
                        selectedSubjectId = val;
                        selectedSectionId = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionDropdownField(
                      'กลุ่มเรียน',
                      selectedSectionId,
                      selectedSubjectId,
                      _sections,
                      (val) => setModalState(() => selectedSectionId = val),
                    ),
                    const SizedBox(height: 36),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: AppColors.success,
                        boxShadow: AppColors.successShadow,
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
                              confirmBtnColor: AppColors.success,
                            );
                            return;
                          }
                          final selectedOpt = _sections.firstWhere(
                            (s) => s.id == selectedSectionId,
                          );
                          final data = {
                            'id': codeController.text,
                            'code': codeController.text,
                            'name': nameController.text,
                            'class': selectedSectionId,
                            'subjectCode': selectedOpt.subjectId,
                            'section': selectedOpt.sectionId,
                          };
                          if (isEdit) {
                            await ApiService.instance.updateDoc(
                              _uid,
                              'students',
                              student.id,
                              data,
                            );
                          } else {
                            await ApiService.instance.setDoc(
                              _uid,
                              'students',
                              codeController.text,
                              data,
                            );
                          }
                          await _fetchData();
                          if (!mounted || !context.mounted) return;
                          Navigator.pop(context);
                          QuickAlert.show(
                            context: context,
                            type: QuickAlertType.success,
                            text: isEdit
                                ? 'อัปเดตข้อมูลผู้เรียนสำเร็จ'
                                : 'เพิ่มผู้เรียนสำเร็จ',
                            confirmBtnColor: AppColors.success,
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
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.success,
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
          child: Icon(icon, color: AppColors.success, size: 13),
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
          borderSide: const BorderSide(color: AppColors.success, width: 2.0),
        ),
      ),
    );
  }

  Widget _buildSubjectDropdownField(
    String label,
    String? value,
    List<SubjectModel> subjects,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownMenu<String>(
      menuHeight: 300,
      initialSelection: subjects.any((s) => s.code == value) ? value : null,
      expandedInsets: EdgeInsets.zero,
      label: Text(label),
      enableFilter: true,
      enableSearch: true,
      hintText: 'พิมพ์เพื่อค้นหา...',
      leadingIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 10),
        child: Icon(FontAwesomeIcons.book, color: AppColors.success, size: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.success,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.success, width: 2.0),
        ),
      ),
      onSelected: onChanged,
      dropdownMenuEntries: subjects.map((s) {
        return DropdownMenuEntry<String>(
          value: s.code,
          label: '${s.code} - ${s.name}',
        );
      }).toList(),
    );
  }

  Widget _buildSectionDropdownField(
    String label,
    String? value,
    String? subjectId,
    List<SectionOption> sections,
    ValueChanged<String?> onChanged,
  ) {
    final filteredSections = sections
        .where((s) => s.subjectId == subjectId)
        .toList();
    return DropdownMenu<String>(
      menuHeight: 300,
      enabled: subjectId != null,
      initialSelection: filteredSections.any((s) => s.id == value)
          ? value
          : null,
      expandedInsets: EdgeInsets.zero,
      label: Text(label),
      enableFilter: true,
      enableSearch: true,
      hintText: subjectId == null ? 'กรุณาเลือกวิชาก่อน' : 'พิมพ์เพื่อค้นหา...',
      leadingIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 10),
        child: Icon(FontAwesomeIcons.users, color: AppColors.success, size: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.success,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.success, width: 2.0),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
      ),
      onSelected: onChanged,
      dropdownMenuEntries: filteredSections.map((s) {
        return DropdownMenuEntry<String>(value: s.id, label: 'Sec ${s.sec}');
      }).toList(),
    );
  }

  void _deleteStudent(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'ยืนยันการลบ',
      text: 'ต้องการลบผู้เรียนคนนี้ใช่หรือไม่',
      confirmBtnText: 'ลบ',
      cancelBtnText: 'ยกเลิก',
      showCancelBtn: true,
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await ApiService.instance.deleteDoc(_uid, 'students', id);
        await _fetchData();
        if (!mounted || !context.mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'ลบข้อมูลผู้เรียนเรียบร้อยแล้ว',
          confirmBtnColor: AppColors.success,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.success,
          boxShadow: AppColors.successShadow,
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
      body: RefreshIndicator(
        onRefresh: _fetchData,
        color: AppColors.success,
        child: CustomScrollView(
          controller: _scrollController,
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
                  'จัดการผู้เรียน',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                background: Container(color: AppColors.surface),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'กรองรายชื่อผู้เรียน',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.only(left: 14, right: 4),
                            decoration: BoxDecoration(
                              color: _filterSubjectId != null
                                  ? AppColors.successSoft
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _filterSubjectId != null
                                    ? AppColors.success
                                    : AppColors.border,
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
                                  color: _filterSubjectId != null
                                      ? AppColors.success
                                      : AppColors.textSecondary,
                                  size: 18,
                                ),
                                decoration: InputDecoration(
                                  filled: false,
                                  prefixIcon: Icon(
                                    FontAwesomeIcons.bookOpen,
                                    color: _filterSubjectId != null
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                    size: 13,
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  prefixIconConstraints: const BoxConstraints(
                                    minWidth: 28,
                                    minHeight: 0,
                                  ),
                                ),
                                initialValue: _filterSubjectId,
                                items: [
                                  DropdownMenuItem(
                                    value: null,
                                    child: Text(
                                      'ทุกวิชา',
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  ..._subjects.map(
                                    (s) => DropdownMenuItem<String>(
                                      value: s.id,
                                      child: Text(
                                        s.name,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (val) => setState(() {
                                  _filterSubjectId = val;
                                  _filterSectionId = null;
                                }),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textPrimary,
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
                              padding: const EdgeInsets.only(
                                left: 14,
                                right: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _filterSectionId != null
                                    ? AppColors.successSoft
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _filterSectionId != null
                                      ? AppColors.success
                                      : AppColors.border,
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
                                    color: _filterSectionId != null
                                        ? AppColors.success
                                        : AppColors.textSecondary,
                                    size: 18,
                                  ),
                                  decoration: InputDecoration(
                                    filled: false,
                                    prefixIcon: Icon(
                                      FontAwesomeIcons.users,
                                      color: _filterSectionId != null
                                          ? AppColors.success
                                          : AppColors.textSecondary,
                                      size: 13,
                                    ),
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                    ),
                                    prefixIconConstraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 0,
                                    ),
                                  ),
                                  initialValue: _filterSectionId,
                                  items: [
                                    DropdownMenuItem(
                                      value: null,
                                      child: Text(
                                        'ทุกกลุ่มเรียน',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    ..._sections
                                        .where(
                                          (s) =>
                                              s.subjectId == _filterSubjectId,
                                        )
                                        .map(
                                          (s) => DropdownMenuItem(
                                            value: s.id,
                                            child: Text(
                                              'Sec ${s.sec}',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                  ],
                                  onChanged: (val) =>
                                      setState(() => _filterSectionId = val),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
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
            if (_isLoading)
              const SliverToBoxAdapter(child: ListSkeletonLoader())
            else
              SliverToBoxAdapter(child: _buildStudentsContent()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentsContent() {
    final students = _students.where((student) {
      if (_filterSectionId != null) {
        return student.className == _filterSectionId;
      }
      if (_filterSubjectId != null) {
        final subjectCode = _subjects
            .firstWhere((s) => s.id == _filterSubjectId)
            .code;
        return student.className.startsWith('${subjectCode}_') ||
            student.className == subjectCode;
      }
      return true;
    }).toList();
    if (students.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.successSoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    FontAwesomeIcons.usersSlash,
                    size: 24,
                    color: AppColors.success,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ยังไม่มีรายชื่อผู้เรียน',
                style: TextStyle(
                  color: AppColors.successDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'เพิ่มผู้เรียนใหม่ หรือปรับตัวกรองเพื่อแสดงผลรายการ',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return _buildStudentsList(students);
  }

  Widget _buildStudentsList(List<StudentModel> students) {
    final totalPages = (students.length / _pageSize).ceil().clamp(1, 1000000);
    final page = _currentPage.clamp(1, totalPages);
    if (page != _currentPage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _currentPage = page);
      });
    }
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, students.length);
    final visibleStudents = students.sublist(start, end);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          ...visibleStudents.map((student) {
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
              /* ignore */
            }
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1.5),
                boxShadow: AppColors.softShadow,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.successSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Icon(
                          FontAwesomeIcons.solidUser,
                          color: AppColors.success,
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
                            student.name,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            student.code,
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'monospace',
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Sec $sectionName',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  subjectName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        GestureDetector(
                          onTap: () => _showStudentDialog(student),
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
                          onTap: () => _deleteStudent(student.id),
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
            );
          }),
          if (students.length > _pageSize) ...[
            const SizedBox(height: 4),
            Text(
              'แสดง ${start + 1}-$end จาก ${students.length} รายการ',
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
