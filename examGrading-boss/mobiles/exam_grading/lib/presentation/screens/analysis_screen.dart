import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';
import 'package:exam_grading/data/models/exam_model.dart';

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({Key? key}) : super(key: key);

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Header Background
          Container(
            height: 200,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const ListSkeletonLoader()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Custom App Bar
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                FontAwesomeIcons.chartSimple,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'วิเคราะห์ผลการสอบ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Global Stats Row
                      _buildSummaryStats(),

                      const SizedBox(height: 24),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'รายการข้อสอบ',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            Text(
                              'ทั้งหมด ${_exams.length}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      Expanded(
                        child: _exams.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                                itemCount: _exams.length,
                                itemBuilder: (context, index) {
                                  final exam = _exams[index];
                                  final examResults = _results
                                      .where((r) => r['examId'] == exam.id)
                                      .toList();
                                  
                                  return _buildAnalysisCard(exam, examResults);
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStats() {
    int totalStudents = _results.length;
    double avgScore = 0;
    if (_results.isNotEmpty) {
      avgScore = _results.fold<double>(0, (sum, r) => sum + (double.tryParse(r['score']?.toString() ?? '0') ?? 0)) / totalStudents;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryItem(
              '${_exams.length}',
              'ชุดข้อสอบ',
              FontAwesomeIcons.fileLines,
              const Color(0xFF3B82F6),
            ),
            Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),
            _buildSummaryItem(
              '$totalStudents',
              'ตรวจแล้ว',
              FontAwesomeIcons.userCheck,
              const Color(0xFF10B981),
            ),
            Container(width: 1, height: 40, color: const Color(0xFFF1F5F9)),
            _buildSummaryItem(
              avgScore.toStringAsFixed(1),
              'คะแนนเฉลี่ย',
              FontAwesomeIcons.star,
              const Color(0xFFF59E0B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.6), size: 16),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(ExamModel exam, List<Map<String, dynamic>> results) {
    int count = results.length;
    double avg = 0;
    int passed = 0;

    if (count > 0) {
      avg = results.fold<double>(0, (sum, r) => sum + (double.tryParse(r['score']?.toString() ?? '0') ?? 0)) / count;
      passed = results.where((r) => (double.tryParse(r['score']?.toString() ?? '0') ?? 0) >= (exam.questions / 2)).length;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.solidChartBar,
                    color: Color(0xFF0D9488),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        exam.subject,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  FontAwesomeIcons.chevronRight,
                  color: Color(0xFFCBD5E1),
                  size: 14,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('ผู้เข้าสอบ', '$count'),
                _buildMiniStat('เฉลี่ย', avg.toStringAsFixed(1)),
                _buildMiniStat('ผ่าน', '$passed', isSuccess: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, {bool isSuccess = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isSuccess ? const Color(0xFF10B981) : const Color(0xFF1E293B),
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
          Icon(
            FontAwesomeIcons.chartPie,
            size: 64,
            color: Colors.grey.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          const Text(
            'ยังไม่มีข้อมูลการวิเคราะห์',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
