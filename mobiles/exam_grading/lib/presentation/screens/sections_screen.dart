import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/data/models/section_model.dart';
import 'package:exam_grading/data/models/subject_model.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';

class SectionsScreen extends StatefulWidget {
  final SubjectModel subject;
  const SectionsScreen({Key? key, required this.subject}) : super(key: key);

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';
  static const int _pageSize = 10;
  int _currentPage = 1;

  void _showSectionDialog([SectionModel? section]) {
    final isEdit = section != null;
    final secController = TextEditingController(text: section?.sec);

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
                _buildPopupField(
                  'รหัสกลุ่มเรียน (Sec)',
                  secController,
                  FontAwesomeIcons.users,
                ),
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
                            if (secController.text.trim().isEmpty) {
                              QuickAlert.show(
                                context: context,
                                type: QuickAlertType.warning,
                                text: 'กรุณากรอกข้อมูลให้ครบถ้วน',
                                confirmBtnColor: AppColors.primary,
                              );
                              return;
                            }

                            final data = {
                              'sec': secController.text.trim(),
                              'created_at': FieldValue.serverTimestamp(),
                            };

                            try {
                              if (isEdit) {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_uid)
                                    .collection('subjects')
                                    .doc(widget.subject.id)
                                    .collection('sections')
                                    .doc(section.id)
                                    .update(data)
                                    .timeout(const Duration(seconds: 15));
                              } else {
                                await FirebaseFirestore.instance
                                    .collection('users')
                                    .doc(_uid)
                                    .collection('subjects')
                                    .doc(widget.subject.id)
                                    .collection('sections')
                                    .doc(secController.text.trim())
                                    .set(data)
                                    .timeout(const Duration(seconds: 15));
                              }

                              if (!mounted) return;
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
                          child: const Text(
                            'บันทึก',
                            style: TextStyle(
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
          if (!mounted) return;
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
    final userRoot = FirebaseFirestore.instance.collection('users').doc(_uid);
    final subjectRef = userRoot.collection('subjects').doc(widget.subject.id);
    final sectionRef = subjectRef.collection('sections').doc(sectionId);
    final sectionSnap = await sectionRef.get();
    final subjectCode = widget.subject.code;
    final sectionSec = (sectionSnap.data()?['sec'] ?? sectionId).toString();
    final sectionFullId = '${widget.subject.id}_$sectionId';
    final legacySectionFullId = '${subjectCode}_$sectionSec';

    final batch = FirebaseFirestore.instance.batch();

    final studentsSnapshot = await userRoot.collection('students').get();
    for (final studentDoc in studentsSnapshot.docs) {
      final classId = (studentDoc.data()['class'] ?? '').toString();
      final shouldDelete =
          classId == sectionFullId ||
          classId == legacySectionFullId ||
          classId == sectionSec ||
          classId == sectionId;
      if (shouldDelete) batch.delete(studentDoc.reference);
    }

    batch.delete(sectionRef);
    await batch.commit().timeout(const Duration(seconds: 15));
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
          StreamBuilder<QuerySnapshot>(
            stream: (FirebaseAuth.instance.currentUser?.email ?? '').isNotEmpty
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser?.email)
                      .collection('subjects')
                      .doc(widget.subject.id)
                      .collection('sections')
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'โหลดข้อมูลไม่สำเร็จ: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: ListSkeletonLoader());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
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

              final sections = docs
                  .map(
                    (doc) => SectionModel.fromMap(
                      doc.id,
                      doc.data() as Map<String, dynamic>,
                    ),
                  )
                  .toList();
              final totalPages = (sections.length / _pageSize).ceil().clamp(
                1,
                1000000,
              );
              final page = _currentPage.clamp(1, totalPages);
              if (page != _currentPage) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) setState(() => _currentPage = page);
                });
              }
              final start = (page - 1) * _pageSize;
              final end = (start + _pageSize).clamp(0, sections.length);
              final visibleSections = sections.sublist(start, end);
              return SliverToBoxAdapter(
                child: Padding(
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
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.5,
                            ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => _deleteSection(section.id),
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
                      }).toList(),
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
                          onPageChanged: (nextPage) {
                            setState(() => _currentPage = nextPage);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
