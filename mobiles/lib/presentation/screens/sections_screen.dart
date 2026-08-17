import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/data/models/section_model.dart';
import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';

class SectionsScreen extends StatefulWidget {
  final SubjectModel subject;
  const SectionsScreen({super.key, required this.subject});

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';
  static const int _pageSize = 10;
  int _currentPage = 1;
  List<SectionModel> _sections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  Future<void> _loadSections() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final docs = await ApiService.instance.getNestedCollection(
        _uid,
        'subjects',
        widget.subject.id,
        'sections',
      );
      if (mounted) {
        setState(() {
          _sections = docs
              .map(
                (d) => SectionModel.fromMap(
                  d['id']?.toString() ?? d['section_id']?.toString() ?? '',
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

  void _showSectionDialog([SectionModel? section]) {
    final isEdit = section != null;
    final secController = TextEditingController(text: section?.sec);
    final countController = TextEditingController(text: "1");

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.users,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      isEdit ? 'แก้ไขกลุ่มเรียน' : 'เพิ่มกลุ่มเรียน',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                if (isEdit) ...[
                  _buildPopupField(
                    'กลุ่มเรียน (Section)',
                    secController,
                    FontAwesomeIcons.users,
                  ),
                ] else ...[
                  _buildPopupField(
                    'จำนวนกลุ่มเรียนที่ต้องการเพิ่ม',
                    countController,
                    FontAwesomeIcons.users,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'ระบบจะสร้างหมายเลขกลุ่มเรียนถัดไปให้อัตโนมัติ (เช่น กลุ่ม 1, 2, 3...)',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          'ยกเลิก',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: AppColors.primary,
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              if (isEdit) {
                                if (secController.text.trim().isEmpty) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.warning,
                                    text: 'กรุณากรอกรหัสกลุ่มเรียน',
                                    confirmBtnColor: AppColors.primary,
                                  );
                                  return;
                                }
                                await ApiService.instance.setNestedDoc(
                                  _uid,
                                  'subjects',
                                  widget.subject.id,
                                  'sections',
                                  section.id,
                                  {
                                    'subject': widget.subject.id,
                                    'sec': secController.text.trim(),
                                    'created_at': DateTime.now()
                                        .toIso8601String(),
                                  },
                                );
                              } else {
                                final count =
                                    int.tryParse(countController.text.trim()) ??
                                    1;
                                if (count < 1) {
                                  QuickAlert.show(
                                    context: context,
                                    type: QuickAlertType.warning,
                                    text:
                                        'กรุณาระบุจำนวนกลุ่มเรียนที่ต้องการเพิ่มเป็นตัวเลขอย่างน้อย 1',
                                    confirmBtnColor: AppColors.primary,
                                  );
                                  return;
                                }
                                final existingNums = _sections
                                    .map((s) => int.tryParse(s.sec))
                                    .whereType<int>()
                                    .toList();
                                final maxNum = existingNums.isNotEmpty
                                    ? existingNums.reduce(
                                        (a, b) => a > b ? a : b,
                                      )
                                    : 0;

                                for (int i = 1; i <= count; i++) {
                                  final secNum = maxNum + i;
                                  final secStr = secNum.toString();
                                  final secId = '${widget.subject.id}_$secStr';
                                  await ApiService.instance.setNestedDoc(
                                    _uid,
                                    'subjects',
                                    widget.subject.id,
                                    'sections',
                                    secId,
                                    {
                                      'id': secId,
                                      'subject': widget.subject.id,
                                      'sec': secStr,
                                      'created_at': DateTime.now()
                                          .toIso8601String(),
                                    },
                                  );
                                }
                              }
                              await _loadSections();
                              if (!mounted || !context.mounted) return;
                              Navigator.pop(context);
                              QuickAlert.show(
                                context: context,
                                type: QuickAlertType.success,
                                text: isEdit
                                    ? 'แก้ไขกลุ่มเรียนสำเร็จ'
                                    : 'เพิ่มกลุ่มเรียนสำเร็จ',
                                confirmBtnColor: AppColors.primary,
                              );
                            } catch (e) {
                              QuickAlert.show(
                                context: context,
                                type: QuickAlertType.error,
                                title: 'เกิดข้อผิดพลาด',
                                text: e.toString(),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            isEdit ? 'บันทึก' : 'สร้างกลุ่มเรียน',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
      },
    );
  }

  void _deleteSection(String id) {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.confirm,
      title: 'ยืนยันการลบกลุ่มเรียน',
      text:
          'เมื่อลบกลุ่มเรียน รายชื่อผู้เรียนในกลุ่มนี้จะถูกลบออกด้วย แต่ผลสอบที่บันทึกไว้ยังคงอยู่',
      confirmBtnText: 'ลบ',
      cancelBtnText: 'ยกเลิก',
      confirmBtnColor: AppColors.error,
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        try {
          await _deleteSectionCascade(id);
          if (!mounted || !context.mounted) return;
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'ลบกลุ่มเรียนเรียบร้อยแล้ว',
            confirmBtnColor: AppColors.primary,
          );
        } catch (e) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'เกิดข้อผิดพลาด',
            text: e.toString(),
          );
        }
      },
    );
  }

  Future<void> _deleteSectionCascade(String sectionId) async {
    // Backend CASCADE จะจัดการลบ students ในกลุ่มนี้อัตโนมัติ
    await ApiService.instance.deleteDoc(_uid, 'sections', sectionId);
    await _loadSections();
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
          onPressed: () => _showSectionDialog(),
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
                'กลุ่มเรียน: ${widget.subject.code}',
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
            child: _isLoading
                ? const ListSkeletonLoader()
                : _buildSectionsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionsList() {
    final sections = _sections;
    if (sections.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    FontAwesomeIcons.usersSlash,
                    size: 24,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'ยังไม่มีกลุ่มเรียน',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'กดปุ่ม + เพื่อเพิ่มกลุ่มเรียนแรกของวิชานี้',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    final totalPages = (sections.length / _pageSize).ceil().clamp(1, 1000000);
    final page = _currentPage.clamp(1, totalPages);
    final start = (page - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, sections.length);
    final visibleSections = sections.sublist(start, end);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          ...visibleSections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
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
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '${start + index + 1}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'กลุ่มเรียน',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sec ${section.sec}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _showSectionDialog(section),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
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
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () => _deleteSection(section.id),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
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
          if (sections.length > _pageSize) ...[
            const SizedBox(height: 4),
            Text(
              'แสดง ${start + 1}-$end จาก ${sections.length} รายการ',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            PaginationBar(
              page: page,
              totalPages: totalPages,
              onPageChanged: (p) => setState(() => _currentPage = p),
            ),
          ],
        ],
      ),
    );
  }
}
