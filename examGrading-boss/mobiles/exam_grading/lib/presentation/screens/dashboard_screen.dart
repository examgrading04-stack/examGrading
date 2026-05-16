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
import 'package:exam_grading/presentation/widgets/vector_logo.dart';
import 'package:exam_grading/presentation/screens/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        user?.displayName ?? user?.email?.split('@')[0] ?? 'อาจารย์';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A';
    final email = user?.email ?? '';
    final photoUrl = user?.photoURL;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(FontAwesomeIcons.cameraRetro, size: 18),
        label: const Text(
          'สแกนตรวจ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Stack(
        children: [
          // Top Background Pattern
          Container(
            height: 240,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF1E40AF)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          // Main Content
          SafeArea(
            child: Column(
              children: [
                // Custom App Bar (No Drawer, Just Title and Profile)
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
                          const VectorLogo(size: 36),
                          const SizedBox(width: 10),
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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: photoUrl != null
                                ? Image.network(
                                    photoUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Text(
                                            initial,
                                            style: const TextStyle(
                                              color: Color(0xFF2563EB),
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  )
                                : Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Welcome Section (Compact)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 0,
                  ),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'สวัสดีครับ,',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Latest Result Card (Floating)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: email.isNotEmpty
                        ? FirebaseFirestore.instance
                              .collection('users')
                              .doc(email)
                              .collection('results')
                              .orderBy('timestamp', descending: true)
                              .limit(1)
                              .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      String title = 'พร้อมสำหรับการตรวจ';
                      String subtitle =
                          'เลือกเมนูด้านล่างเพื่อเริ่มต้นการใช้งาน';
                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        var latest = snapshot.data!.docs.first;
                        title = 'ล่าสุด: ${latest['examId']}';
                        subtitle = 'คะแนนที่ได้: ${latest['score']} คะแนน';
                      }
                      return _buildHeaderCard(title, subtitle);
                    },
                  ),
                ),

                // Flexible Grid Area (Fits to screen without scroll)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 96),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Row 1: Management
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                context,
                                FontAwesomeIcons.book,
                                'รายวิชาและ\nกลุ่มเรียน',
                                const Color(0xFF3B82F6),
                                const SubjectsScreen(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildGridItem(
                                context,
                                FontAwesomeIcons.userGraduate,
                                'ผู้เรียน',
                                const Color(0xFF10B981),
                                const StudentsScreen(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildGridItem(
                                context,
                                FontAwesomeIcons.filePen,
                                'ข้อสอบ',
                                const Color(0xFFF59E0B),
                                const ExamsScreen(),
                              ),
                            ),
                          ],
                        ),
                        // Row 2: Action / Core
                        Row(
                          children: [
                            Expanded(
                              child: _buildGridItem(
                                context,
                                FontAwesomeIcons.clockRotateLeft,
                                'ประวัติ',
                                const Color(0xFF06B6D4),
                                const ResultsScreen(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildGridItem(
                                context,
                                FontAwesomeIcons.chartLine,
                                'วิเคราะห์',
                                const Color(0xFF64748B),
                                const AnalysisScreen(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(child: SizedBox()),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDBEAFE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              FontAwesomeIcons.bullseye,
              color: Color(0xFF2563EB),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    IconData icon,
    String title,
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
      child: AspectRatio(
        aspectRatio: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
