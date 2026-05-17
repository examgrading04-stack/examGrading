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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [const _DashboardHome(), const AnalysisScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _pages[_selectedIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ScanScreen()),
          );
        },
        backgroundColor: const Color(0xFF8B5CF6),
        foregroundColor: Colors.white,
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(FontAwesomeIcons.cameraRetro, size: 24),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              InkWell(
                onTap: () => setState(() => _selectedIndex = 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FontAwesomeIcons.house,
                      color: _selectedIndex == 0
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'หน้าแรก',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _selectedIndex == 0
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 40), // Space for FAB
              InkWell(
                onTap: () => setState(() => _selectedIndex = 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      FontAwesomeIcons.chartPie,
                      color: _selectedIndex == 1
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF94A3B8),
                      size: 20,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'วิเคราะห์',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _selectedIndex == 1
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF94A3B8),
                      ),
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
}

class _DashboardHome extends StatelessWidget {
  const _DashboardHome({Key? key}) : super(key: key);

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
        // Top Background Pattern (Reduced height)
        Container(
          height: 210,
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
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12, // Reduced vertical padding
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const VectorLogo(size: 32), // Reduced logo size
                        const SizedBox(width: 8),
                        const Text(
                          'EXAM GRADING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14, // Reduced font size
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
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
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: photoUrl != null
                              ? Image.network(
                                  photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => Center(
                                    child: Text(
                                      initial,
                                      style: const TextStyle(
                                        color: Color(0xFF2563EB),
                                        fontSize: 16,
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
                                      fontSize: 16,
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

              // Welcome Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สวัสดีครับ,',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20, // Reduced font size
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16), // Reduced spacing

              // Latest Result Card
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
                    String subtitle = 'เลือกเมนูด้านล่างเพื่อเริ่มต้นการใช้งาน';
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      var latest = snapshot.data!.docs.first;
                      title = 'ล่าสุด: ${latest['examId']}';
                      subtitle = 'คะแนนที่ได้: ${latest['score']} คะแนน';
                    }
                    return _buildHeaderCard(title, subtitle);
                  },
                ),
              ),

              const SizedBox(height: 20), // Reduced spacing

              // Grid Menu 2x2
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 12, // Reduced spacing
                  crossAxisSpacing: 12, // Reduced spacing
                  childAspectRatio: 1.25, // Adjusted ratio for more compactness
                  children: [
                    _buildGridItem(
                      context,
                      FontAwesomeIcons.book,
                      'รายวิชา',
                      const Color(0xFF3B82F6),
                      const SubjectsScreen(),
                    ),
                    _buildGridItem(
                      context,
                      FontAwesomeIcons.userGraduate,
                      'ผู้เรียน',
                      const Color(0xFF10B981),
                      const StudentsScreen(),
                    ),
                    _buildGridItem(
                      context,
                      FontAwesomeIcons.filePen,
                      'ข้อสอบ',
                      const Color(0xFFF59E0B),
                      const ExamsScreen(),
                    ),
                    _buildGridItem(
                      context,
                      FontAwesomeIcons.clockRotateLeft,
                      'ประวัติ',
                      const Color(0xFF06B6D4),
                      const ResultsScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
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
