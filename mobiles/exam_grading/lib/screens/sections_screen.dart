import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/subject_model.dart';
import '../models/section_model.dart';

class SectionsScreen extends StatefulWidget {
  final SubjectModel subject;

  const SectionsScreen({Key? key, required this.subject}) : super(key: key);

  @override
  State<SectionsScreen> createState() => _SectionsScreenState();
}

class _SectionsScreenState extends State<SectionsScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<SectionModel> _sections = [];

  void _showSectionDialog([SectionModel? section]) {
    final isEdit = section != null;
    final secController = TextEditingController(text: section?.sec);

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        FontAwesomeIcons.users,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      isEdit ? 'แก้ไขกลุ่มเรียน' : 'เพิ่มกลุ่มเรียนใหม่',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildPopupField('กลุ่มเรียน (Sec)', secController, FontAwesomeIcons.users),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'ยกเลิก',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          if (secController.text.trim().isEmpty) {
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.warning,
                              text: 'กรุณากรอกข้อมูลให้ครบถ้วน',
                              confirmBtnColor: const Color(0xFF10B981),
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
                                  .update(data);
                            } else {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(_uid)
                                  .collection('subjects')
                                  .doc(widget.subject.id)
                                  .collection('sections')
                                  .add(data);
                            }

                            if (!mounted) return;
                            Navigator.pop(context);
                            QuickAlert.show(
                              context: context,
                              type: QuickAlertType.success,
                              text: isEdit ? 'แก้ไขข้อมูลสำเร็จ' : 'เพิ่มข้อมูลสำเร็จ',
                              confirmBtnColor: const Color(0xFF10B981),
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
                          backgroundColor: const Color(0xFF10B981),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'บันทึก',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
      title: 'ยืนยันการลบ',
      text: 'คุณต้องการลบกลุ่มเรียนนี้ใช่หรือไม่?',
      confirmBtnText: 'ใช่, ลบเลย',
      cancelBtnText: 'ยกเลิก',
      confirmBtnColor: const Color(0xFFEF4444),
      onConfirmBtnTap: () async {
        Navigator.pop(context);
        try {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_uid)
              .collection('subjects')
              .doc(widget.subject.id)
              .collection('sections')
              .doc(id)
              .delete();
          if (!mounted) return;
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            text: 'ลบข้อมูลสำเร็จ',
            confirmBtnColor: const Color(0xFF10B981),
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

  Widget _buildPopupField(String label, TextEditingController controller, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 15, color: Color(0xFF1E293B)),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: const Color(0xFF94A3B8), size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF10B981),
        onPressed: () => _showSectionDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF10B981),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'กลุ่มเรียน: ${widget.subject.code}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: _uid.isNotEmpty
                ? FirebaseFirestore.instance
                    .collection('users')
                    .doc(_uid)
                    .collection('subjects')
                    .doc(widget.subject.id)
                    .collection('sections')
                    .orderBy('created_at', descending: true)
                    .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: SpinKitCircle(color: Color(0xFF10B981), size: 50.0),
                  ),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(FontAwesomeIcons.usersSlash, size: 60, color: Colors.grey.withOpacity(0.2)),
                        const SizedBox(height: 16),
                        const Text('ยังไม่มีกลุ่มเรียน', style: TextStyle(color: Color(0xFF64748B), fontSize: 16)),
                      ],
                    ),
                  ),
                );
              }

              final sections = docs.map((doc) => SectionModel.fromMap(doc.id, doc.data() as Map<String, dynamic>)).toList();

              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                          0: FlexColumnWidth(1),
                          1: FlexColumnWidth(1),
                          2: IntrinsicColumnWidth(),
                        },
                        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                        children: [
                          TableRow(
                            decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                            children: const [
                              Padding(padding: EdgeInsets.all(12), child: Text('ลำดับ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                              Padding(padding: EdgeInsets.all(12), child: Text('กลุ่มเรียน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                              Padding(padding: EdgeInsets.all(12), child: Text('จัดการ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF64748B)))),
                            ],
                          ),
                          ...sections.asMap().entries.map((entry) {
                            final index = entry.key;
                            final section = entry.value;
                            return TableRow(
                              decoration: const BoxDecoration(
                                border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text('${index + 1}', style: const TextStyle(fontSize: 13, color: Color(0xFF1E293B))),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(section.sec, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B))),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(FontAwesomeIcons.penToSquare, color: Color(0xFF2563EB), size: 16),
                                      onPressed: () => _showSectionDialog(section),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    const SizedBox(width: 16),
                                    IconButton(
                                      icon: const Icon(FontAwesomeIcons.trashCan, color: Color(0xFFEF4444), size: 16),
                                      onPressed: () => _deleteSection(section.id),
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
