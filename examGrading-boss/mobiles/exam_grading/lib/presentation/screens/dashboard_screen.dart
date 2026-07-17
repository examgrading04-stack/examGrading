import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:exam_grading/presentation/screens/scan_screen.dart';
import 'package:exam_grading/presentation/screens/results_screen.dart';
import 'package:exam_grading/presentation/screens/subjects_screen.dart';
import 'package:exam_grading/presentation/screens/students_screen.dart';
import 'package:exam_grading/presentation/screens/exams_screen.dart';
import 'package:exam_grading/presentation/screens/analysis_screen.dart';
import 'package:exam_grading/presentation/screens/profile_screen.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  int _profileRevision = 0;

  Future<void> _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    await FirebaseAuth.instance.currentUser?.reload();
    if (mounted) {
      setState(() => _profileRevision++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _DashboardHome(
        key: ValueKey(_profileRevision),
        onOpenProfile: _openProfile,
      ),
      const AnalysisScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
          ),
          child: const Center(
            child: Icon(FontAwesomeIcons.cameraRetro, size: 24),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 0),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.house,
                          color: _selectedIndex == 0
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'หน้าแรก',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedIndex == 0
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(
                width: 80,
              ), // Expanded space to avoid overlap with scan FAB
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedIndex = 1),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          FontAwesomeIcons.chartPie,
                          color: _selectedIndex == 1
                              ? AppColors.primary
                              : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'วิเคราะห์',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _selectedIndex == 1
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({Key? key, required this.onOpenProfile})
    : super(key: key);

  final VoidCallback onOpenProfile;

  DateTime? _readResultTime(Map<String, dynamic> data) {
    final dynamic createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    final dynamic timestamp = data['timestamp'];
    if (timestamp is Timestamp) return timestamp.toDate();
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'อาจารย์';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return Stack(
      children: [
        // Top Premium Gradient Header
        Container(
          height: 230,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
        ),
        // Decorative Circular Glows
        Positioned(
          top: -40,
          left: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          top: 60,
          right: -30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
        // Main Content
        SafeArea(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Premium App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            // decoration: BoxDecoration(
                            //   color: Colors.white.withValues(alpha: 0.15),
                            //   borderRadius: BorderRadius.circular(14),
                            //   border: Border.all(
                            //     color: Colors.white.withValues(alpha: 0.1),
                            //   ),
                            // ),
                            child: Image.asset(
                              'images/icon.png',
                              width: 40,
                              height: 40,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'EXAM GRADING',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: onOpenProfile,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            backgroundImage: photoUrl != null
                                ? NetworkImage(photoUrl)
                                : null,
                            child: photoUrl == null
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Welcome Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ยินดีต้อนรับ,',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Stunning Stats Banner Card
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: email.isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(email)
                              .collection('results')
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      String title = 'พร้อมสำหรับการตรวจ';
                      String subtitle =
                          'เลือกเมนูด้านล่างเพื่อเริ่มต้นการใช้งาน';
                      if (snapshot.hasError) {
                        title = 'โหลดข้อมูลผลสอบไม่สำเร็จ';
                        subtitle = 'กรุณาตรวจสอบการเชื่อมต่อและลองใหม่อีกครั้ง';
                        return _buildHeaderCard(title, subtitle);
                      }
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final docs = [...snapshot.data!.docs];
                        docs.sort((a, b) {
                          final aData = a.data() as Map<String, dynamic>;
                          final bData = b.data() as Map<String, dynamic>;
                          final at = _readResultTime(aData);
                          final bt = _readResultTime(bData);
                          if (at == null && bt == null) return 0;
                          if (at == null) return 1;
                          if (bt == null) return -1;
                          return bt.compareTo(at);
                        });
                        final latest =
                            docs.first.data() as Map<String, dynamic>;
                        final latestScore = latest['score'];
                        final latestTotal = latest['total'];
                        final latestStudent = (latest['studentName'] ?? '')
                            .toString();
                        if (latestScore != null && latestTotal != null) {
                          title =
                              'ผลตรวจล่าสุด: $latestScore/$latestTotal คะแนน';
                        } else {
                          title = 'มีผลสอบล่าสุดแล้ว';
                        }
                        if (latestStudent.isNotEmpty) {
                          subtitle = 'ล่าสุด: $latestStudent';
                        } else {
                          subtitle = 'สามารถดูรายละเอียดได้ในหน้า ประวัติ';
                        }
                      }
                      return _buildHeaderCard(title, subtitle);
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Section Label
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Text(
                        'เมนูหลัก',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Grid Menu 2x2 (Redesigned)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.15,
                    children: [
                      _buildGridItem(
                        context,
                        FontAwesomeIcons.book,
                        'รายวิชา',
                        'จัดการวิชาเรียน',
                        AppColors.primary,
                        const SubjectsScreen(),
                      ),
                      _buildGridItem(
                        context,
                        FontAwesomeIcons.userGraduate,
                        'ผู้เรียน',
                        'ข้อมูลและสถานะ',
                        AppColors.success,
                        const StudentsScreen(),
                      ),
                      _buildGridItem(
                        context,
                        FontAwesomeIcons.filePen,
                        'ข้อสอบ',
                        'ตรวจและวิเคราะห์',
                        AppColors.warning,
                        const ExamsScreen(),
                      ),
                      _buildGridItem(
                        context,
                        FontAwesomeIcons.clockRotateLeft,
                        'ประวัติ',
                        'ดูผลสอบทั้งหมด',
                        AppColors.info,
                        const ResultsScreen(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildHeaderCard(String title, String subtitle) {
  return Container(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      boxShadow: AppColors.softShadow,
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Background Vector Accents
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -30,
            bottom: -30,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    FontAwesomeIcons.circleCheck,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primaryDark,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildGridItem(
  BuildContext context,
  IconData icon,
  String title,
  String subtitle,
  Color color,
  Widget destination,
) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1.5),
        boxShadow: AppColors.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Soft Watermarked Backdrop Icon
            Positioned(
              right: -10,
              bottom: -10,
              child: Icon(icon, size: 60, color: color.withValues(alpha: 0.05)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
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
    ),
  );
}
