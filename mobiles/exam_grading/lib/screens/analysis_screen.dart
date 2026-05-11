import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/exam_model.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  List<ExamModel> _exams = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_uid.isEmpty) return;
    try {
      final examsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('exams')
          .get();
      final resultsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('results')
          .get();

      setState(() {
        _exams = examsSnapshot.docs
            .map((doc) => ExamModel.fromMap(doc.id, doc.data()))
            .toList();
        _results = resultsSnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF14B8A6),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'วิเคราะห์ผลการสอบ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF14B8A6), Color(0xFF0F766E)],
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
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(
                child: SpinKitCircle(color: Color(0xFF14B8A6), size: 50.0),
              ),
            )
          else if (_exams.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final exam = _exams[index];
                  final examResults = _results
                      .where((r) => r['examId'] == exam.id)
                      .toList();
                  final participantCount = examResults.length;

                  double average = 0;
                  int passCount = 0;

                  if (participantCount > 0) {
                    final totalScore = examResults.fold<double>(0, (sum, r) {
                      final s =
                          double.tryParse(r['score']?.toString() ?? '0') ?? 0;
                      return sum + s;
                    });
                    average = totalScore / participantCount;

                    // Pass criteria: >= 50%
                    passCount = examResults.where((r) {
                      final s =
                          double.tryParse(r['score']?.toString() ?? '0') ?? 0;
                      return (s / exam.questions) >= 0.5;
                    }).length;
                  }

                  return _buildAnalysisCard(
                    exam,
                    participantCount,
                    average,
                    passCount,
                  );
                }, childCount: _exams.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard(
    ExamModel exam,
    int participantCount,
    double average,
    int passCount,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    exam.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCCFBF1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    exam.subject,
                    style: const TextStyle(
                      color: Color(0xFF0D9488),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: FontAwesomeIcons.users,
                  gradient: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  value: participantCount.toString(),
                  label: 'ผู้เข้าสอบ',
                ),
                _buildStatItem(
                  icon: FontAwesomeIcons.chartPie,
                  gradient: const [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                  value: average.toStringAsFixed(2),
                  label: 'คะแนนเฉลี่ย',
                ),
                _buildStatItem(
                  icon: FontAwesomeIcons.checkDouble,
                  gradient: const [Color(0xFF10B981), Color(0xFF047857)],
                  value: passCount.toString(),
                  label: 'สอบผ่าน',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required List<Color> gradient,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: gradient[0].withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(child: Icon(icon, color: Colors.white, size: 18)),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Icon(
              FontAwesomeIcons.chartLine,
              size: 60,
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ยังไม่มีข้อมูลข้อสอบในระบบ',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
