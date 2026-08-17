import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/data/models/exam_model.dart';
import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/screens/answer_key_screen.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';
import 'package:exam_grading/presentation/screens/answer_sheets_screen.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/data/models/student_model.dart';
import 'package:exam_grading/data/models/section_model.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});
  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';
  static const int _pageSize = 5;
  int _currentPage = 1;
  List<SubjectModel> _subjects = [];
  List<SectionModel> _sections = [];
  List<ExamModel> _exams = [];
  List<StudentModel> _students = [];
  String? _selectedFilterSubject;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final subjectDocs = await ApiService.instance.getCollection(
        _uid,
        'subjects',
      );
      final sectionDocs = await ApiService.instance.getCollection(
        _uid,
        'sections',
      );
      final examDocs = await ApiService.instance.getCollection(_uid, 'exams');
      final studentDocs = await ApiService.instance.getCollection(
        _uid,
        'students',
      );
      if (mounted) {
        setState(() {
          _subjects = subjectDocs
              .map((d) => SubjectModel.fromMap(d['code']?.toString() ?? '', d))
              .toList();
          _sections = sectionDocs
              .map((d) => SectionModel.fromMap(d['id']?.toString() ?? '', d))
              .toList();
          _exams = examDocs
              .map(
                (d) => ExamModel.fromMap(
                  d['id']?.toString() ?? d['exam_id']?.toString() ?? '',
                  d,
                ),
              )
              .toList();
          _students = studentDocs
              .map(
                (d) => StudentModel.fromMap(
                  d['id']?.toString() ?? d['student_id']?.toString() ?? '',
                  d,
                ),
              )
              .toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _buildStudentsSnapshotForExam(
    String subjectCode,
    String? section,
  ) async {
    final studentDocs = await ApiService.instance.getCollection(
      _uid,
      'students',
    );
    final all = studentDocs
        .map(
          (d) => StudentModel.fromMap(
            d['id']?.toString() ?? d['student_id']?.toString() ?? '',
            d,
          ),
        )
        .toList();
    final examSection = (section ?? '').trim();
    final filtered = all.where((s) {
      final classStr = s.className;
      if (examSection.isNotEmpty) {
        return classStr == '${subjectCode}_$examSection' ||
            classStr == examSection;
      }
      return classStr == subjectCode || classStr.startsWith('${subjectCode}_');
    }).toList();
    final source = filtered.isNotEmpty ? filtered : all;
    return source
        .map(
          (s) => {
            'id': s.id,
            'code': s.code,
            'name': s.name,
            'class': s.className,
          },
        )
        .toList();
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
    String? selectedSection = exam?.section;
    String? selectedSheetType = exam?.sheetType ?? '30-A-E';
    if (selectedSection != null && selectedSection.isEmpty) {
      selectedSection = null;
    }

    List<String> getAvailableSections(String? subjectCode) {
      if (subjectCode == null) return [];
      return _students
          .where(
            (s) =>
                s.className.startsWith('${subjectCode}_') ||
                s.className == subjectCode,
          )
          .map(
            (s) => s.className.contains('_')
                ? s.className.split('_').last
                : s.className,
          )
          .toSet()
          .toList()
        ..sort();
    }

    final isEdit = exam != null;
    if (_subjects.isEmpty && !isEdit) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text: 'กรุณาเพิ่มรายวิชาก่อนสร้างกระดาษคำตอบ',
        confirmBtnColor: AppColors.warning,
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
            final availableSections = getAvailableSections(selectedSubjectCode);
            if (selectedSection != null &&
                !availableSections.contains(selectedSection)) {
              selectedSection = null;
            }
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
                      isEdit
                          ? 'แก้ไขข้อมูลกระดาษคำตอบ'
                          : 'สร้างกระดาษคำตอบใหม่',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningDark,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildDropdownField(
                      'รายวิชาที่สอบ',
                      selectedSubjectCode,
                      _subjects,
                      (val) => setModalState(() {
                        selectedSubjectCode = val;
                        selectedSection = null;
                      }),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionDropdownField(
                      'กลุ่มเรียน (Section)',
                      selectedSection,
                      availableSections,
                      selectedSubjectCode == null,
                      (val) => setModalState(() => selectedSection = val),
                    ),
                    const SizedBox(height: 20),
                    _buildPopupField(
                      'ชื่อกระดาษคำตอบ',
                      nameController,
                      FontAwesomeIcons.solidFileLines,
                    ),
                    const SizedBox(height: 20),
                    _buildPopupField(
                      'กำหนดเฉลยได้กี่ข้อ',
                      questionsController,
                      FontAwesomeIcons.circleQuestion,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    DropdownMenu<String>(
                      initialSelection: selectedSheetType,
                      expandedInsets: EdgeInsets.zero,
                      label: const Text('รูปแบบกระดาษคำตอบ'),
                      enableFilter: false,
                      enableSearch: false,
                      leadingIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 10),
                        child: Icon(
                          FontAwesomeIcons.fileLines,
                          color: AppColors.warning,
                          size: 13,
                        ),
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
                          color: AppColors.warning,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: AppColors.warning,
                            width: 2.0,
                          ),
                        ),
                      ),
                      onSelected: (val) =>
                          setModalState(() => selectedSheetType = val),
                      dropdownMenuEntries: const [
                        DropdownMenuEntry<String>(
                          value: '30-A-E',
                          label: '30 ข้อ (A-E)',
                        ),
                        DropdownMenuEntry<String>(
                          value: '50-A-E',
                          label: '50 ข้อ (A-E)',
                        ),
                        DropdownMenuEntry<String>(
                          value: '100-A-E',
                          label: '100 ข้อ (A-E)',
                        ),
                      ],
                    ),
                    const SizedBox(height: 36),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: AppColors.warning,
                        boxShadow: AppColors.warningShadow,
                      ),
                      child: ElevatedButton(
                        onPressed: () async {
                          if (nameController.text.isEmpty ||
                              selectedSubjectCode == null) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              text: 'กรุณากรอกข้อมูลให้ครบถ้วน',
                              confirmBtnColor: AppColors.warning,
                            );
                            return;
                          }
                          final subjectCode = selectedSubjectCode!;
                          final examSection = selectedSection ?? '';
                          final studentsSnapshot = isEdit
                              ? exam.studentsSnapshot
                              : await _buildStudentsSnapshotForExam(
                                  subjectCode,
                                  examSection,
                                );
                          final questionsCount =
                              int.tryParse(questionsController.text) ?? 100;
                          String finalSheetType = selectedSheetType ?? '30-A-E';
                          int templateSize = 100;
                          if (finalSheetType.startsWith('30')) {
                            templateSize = 30;
                          } else if (finalSheetType.startsWith('50')) {
                            templateSize = 50;
                          }
                          
                          if (questionsCount > templateSize) {
                            if (questionsCount <= 30) {
                              finalSheetType = '30-A-E';
                            } else if (questionsCount <= 50) {
                              finalSheetType = '50-A-E';
                            } else {
                              finalSheetType = '100-A-E';
                            }
                          }

                          final data = {
                            'name': nameController.text.trim(),
                            'subject': subjectCode,
                            'date': dateController.text,
                            'section': examSection,
                            'questions': questionsCount,
                            'options': 5,
                            'sets': 1,
                            'sheetType': finalSheetType,
                            'studentsSnapshot': studentsSnapshot,
                          };
                          if (isEdit) {
                            await ApiService.instance.updateDoc(
                              _uid,
                              'exams',
                              exam.id,
                              data,
                            );
                          } else {
                            data['answerKey'] = {};
                            await ApiService.instance.setDoc(
                              _uid,
                              'exams',
                              '${selectedSubjectCode}_${nameController.text.trim().replaceAll(' ', '_')}',
                              data,
                            );
                          }
                          if (!mounted || !context.mounted) return;
                          Navigator.pop(context);
                          if (!isEdit) {
                            final subjectObj = _subjects.firstWhere(
                              (s) => s.code == subjectCode,
                              orElse: () => _subjects.first,
                            );
                            final examId =
                                '${subjectCode}_${nameController.text.trim().replaceAll(' ', '_')}';
                            final newExam = ExamModel(
                              id: examId,
                              name: nameController.text.trim(),
                              subject: subjectCode,
                              date: dateController.text,
                              section: examSection,
                              questions: questionsCount,
                              options: 5,
                              sets: 1,
                              sheetType: finalSheetType,
                              answerKey: {},
                              studentsSnapshot: studentsSnapshot,
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
                              text: 'แก้ไขข้อมูลกระดาษคำตอบสำเร็จ',
                              confirmBtnColor: AppColors.warning,
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
                          'บันทึกกระดาษคำตอบ',
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
          color: AppColors.warning,
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
          child: Icon(icon, color: AppColors.warning, size: 13),
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
          borderSide: const BorderSide(color: AppColors.warning, width: 2.0),
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
    return DropdownMenu<String>(
      initialSelection: subjects.any((s) => s.code == value) ? value : null,
      expandedInsets: EdgeInsets.zero,
      label: Text(label),
      enableFilter: true,
      enableSearch: true,
      hintText: 'พิมพ์เพื่อค้นหา...',
      leadingIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 10),
        child: Icon(
          FontAwesomeIcons.bookOpen,
          color: AppColors.warning,
          size: 13,
        ),
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
          color: AppColors.warning,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.warning, width: 2.0),
        ),
      ),
      onSelected: onChanged,
      dropdownMenuEntries: subjects.map((s) {
        return DropdownMenuEntry<String>(
          value: s.code,
          label: '${s.code} ${s.name}',
        );
      }).toList(),
    );
  }

  Widget _buildSectionDropdownField(
    String label,
    String? value,
    List<String> sections,
    bool disabled,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownMenu<String>(
      initialSelection: value,
      expandedInsets: EdgeInsets.zero,
      label: Text(label),
      enabled: !disabled,
      enableFilter: true,
      enableSearch: true,
      hintText: 'พิมพ์เพื่อค้นหา...',
      leadingIcon: const Padding(
        padding: EdgeInsets.only(left: 16, right: 10),
        child: Icon(FontAwesomeIcons.users, color: AppColors.warning, size: 13),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: disabled ? Colors.grey[200] : AppColors.background,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 16,
        ),
        labelStyle: const TextStyle(
          fontSize: 12,
          color: AppColors.warning,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.warning, width: 2.0),
        ),
      ),
      onSelected: onChanged,
      dropdownMenuEntries: [
        const DropdownMenuEntry<String>(value: '', label: 'กรุณาเลือกกลุ่มเรียน'),
        ...sections.map((s) {
          final sectionName = _sections
              .firstWhere(
                (sec) => sec.id == s,
                orElse: () => SectionModel(id: s, sec: s),
              )
              .sec;
          return DropdownMenuEntry<String>(value: s, label: sectionName);
        }),
      ],
    );
  }

  Widget _buildFilterDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedFilterSubject,
          isExpanded: true,
          icon: Icon(
            FontAwesomeIcons.chevronDown,
            size: 14,
            color: AppColors.textSecondary,
          ),
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          hint: const Text(
            'ทุกรายวิชา',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          onChanged: (String? newValue) {
            setState(() {
              _selectedFilterSubject = (newValue == null || newValue.isEmpty)
                  ? null
                  : newValue;
              _currentPage = 1;
            });
          },
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('ทุกรายวิชา'),
            ),
            ..._subjects.map<DropdownMenuItem<String>>((SubjectModel s) {
              return DropdownMenuItem<String>(
                value: s.code,
                child: Text('วิชา: ${s.code} ${s.name}'),
              );
            }),
          ],
        ),
      ),
    );
  }

  void _deleteExam(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.warning,
      title: 'ยืนยันการลบ',
      text: 'คุณแน่ใจหรือไม่ที่จะลบกระดาษคำตอบนี้?',
      confirmBtnText: 'ลบ',
      cancelBtnText: 'ยกเลิก',
      showCancelBtn: true,
      confirmBtnColor: Colors.red,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        await ApiService.instance.deleteDoc(_uid, 'exams', id);
        await _fetchData();
        if (!mounted || !context.mounted) return;
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          text: 'ลบกระดาษคำตอบเรียบร้อยแล้ว',
          confirmBtnColor: AppColors.warning,
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
          color: AppColors.warning,
          boxShadow: AppColors.warningShadow,
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
      body: RefreshIndicator(
        onRefresh: _fetchData,
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
                  'จัดการกระดาษคำตอบ',
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
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: _buildFilterDropdown(),
              ),
            ),
            if (_isLoading)
              const SliverToBoxAdapter(child: ListSkeletonLoader())
            else if (_exams.isEmpty ||
                (_selectedFilterSubject != null &&
                    !_exams.any((e) => e.subject == _selectedFilterSubject)))
              SliverFillRemaining(
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
                            color: AppColors.warningSoft,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              FontAwesomeIcons.fileLines,
                              size: 24,
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'ยังไม่มีข้อมูลกระดาษคำตอบ',
                          style: TextStyle(
                            color: AppColors.warningDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'แตะปุ่มเครื่องหมาย + ด้านล่างเพื่อเริ่มสร้างกระดาษคำตอบ',
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
              )
            else
              SliverToBoxAdapter(child: _buildExamsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsList() {
    final docs = _selectedFilterSubject != null
        ? _exams.where((e) => e.subject == _selectedFilterSubject).toList()
        : _exams;
    final totalPages = (docs.length / _pageSize).ceil().clamp(1, 1000000);
    final page = _currentPage.clamp(1, totalPages);
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, docs.length);
    final visibleDocs = docs.sublist(start, end);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
      child: Column(
        children: [
          ...visibleDocs.map((exam) => _buildExamCard(exam)),
          if (docs.length > _pageSize) ...[
            Text(
              'แสดง ${start + 1}-$end จาก ${docs.length} รายการ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            PaginationBar(
              page: page,
              totalPages: totalPages,
              onPageChanged: (nextPage) =>
                  setState(() => _currentPage = nextPage),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExamCard(ExamModel exam) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openAnswerSheets(exam),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: AppColors.softShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'วิชา: ${exam.subject}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'วันที่: ${exam.date}',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${exam.questions} ข้อ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    children: [
                      _buildCompactAction(
                        icon: FontAwesomeIcons.key,
                        iconSize: 11,
                        color: AppColors.success,
                        bgColor: AppColors.successSoft,
                        onTap: () => _openAnswerKey(exam),
                      ),
                      const SizedBox(width: 8),
                      _buildCompactAction(
                        icon: FontAwesomeIcons.solidPenToSquare,
                        iconSize: 12,
                        color: AppColors.warning,
                        bgColor: AppColors.warningSoft,
                        onTap: () => _showExamDialog(exam),
                      ),
                      const SizedBox(width: 8),
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
          ),
        ),
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
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Center(
          child: Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}
