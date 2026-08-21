import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:exam_grading/data/models/exam_model.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/widgets/skeleton_loader.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';

class _ItemAnalysis {
  const _ItemAnalysis({
    required this.question,
    required this.answer,
    required this.difficulty,
    required this.discrimination,
    required this.correctCount,
    required this.totalCount,
    required this.upperCorrectCount,
    required this.upperGroupLength,
    required this.lowerCorrectCount,
    required this.lowerGroupLength,
    this.choiceCounts = const {},
  });
  final String question;
  final String answer;
  final double difficulty;
  final double discrimination;
  final int correctCount;
  final int totalCount;
  final int upperCorrectCount;
  final int upperGroupLength;
  final int lowerCorrectCount;
  final int lowerGroupLength;
  final Map<String, int> choiceCounts;
}

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});
  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';
  static const int _pageSize = 3;
  int _currentPage = 1;
  List<ExamModel> _exams = [];
  List<Map<String, dynamic>> _results = [];
  Map<String, String> _subjectNames = {};
  final Map<String, Map<String, dynamic>> _examStats = {};
  int _uniqueExamineesCount = 0;
  bool _isLoading = true;
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_uid.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }
    try {
      final examsData = await ApiService.instance.getCollection(_uid, 'exams');
      final resultsData = await ApiService.instance.getCollection(
        _uid,
        'results',
      );
      final subjectsData = await ApiService.instance.getCollection(
        _uid,
        'subjects',
      );

      if (!mounted || !context.mounted) return;

      setState(() {
        _exams = examsData
            .map(
              (data) =>
                  ExamModel.fromMap(data['exam_id'] ?? data['id'] ?? '', data),
            )
            .toList();
        _results = resultsData;

        _subjectNames = {
          for (var item in subjectsData)
            item['subject_id'] ?? item['id'] ?? '':
                item['subject_name'] ?? item['name'] ?? '',
        };

        Set<String> uniqueExaminees = {};
        for (var result in _results) {
          final code = result['studentCode']?.toString() ?? '';
          if (code.isNotEmpty) uniqueExaminees.add(code);
        }
        _uniqueExamineesCount = uniqueExaminees.length;

        _examStats.clear();
        for (final exam in _exams) {
          final results = _results
              .where((r) => r['examId'] == exam.id)
              .toList();
          final count = results.length;

          final scores = results
              .map((r) => _getDynamicScore(r, exam).toDouble())
              .toList();
          scores.sort();

          final average = count == 0
              ? 0.0
              : scores.fold<double>(0, (a, b) => a + b) / count;
          final passed = scores
              .where((s) => s >= (exam.getTotalScore(null) / 2))
              .length;
          final passRate = count == 0 ? 0.0 : passed / count;

          final maxScore = scores.isEmpty ? 0.0 : scores.last;
          final minScore = scores.isEmpty ? 0.0 : scores.first;

          double median = 0.0;
          if (scores.isNotEmpty) {
            final middle = scores.length ~/ 2;
            if (scores.length % 2 == 1) {
              median = scores[middle];
            } else {
              median = (scores[middle - 1] + scores[middle]) / 2.0;
            }
          }

          String modeStr = '-';
          if (scores.isNotEmpty) {
            final counts = <double, int>{};
            for (var s in scores) {
              counts[s] = (counts[s] ?? 0) + 1;
            }
            int maxCount = 0;
            for (var c in counts.values) {
              if (c > maxCount) maxCount = c;
            }

            if (maxCount <= 1 || counts.values.every((c) => c == maxCount)) {
              modeStr = 'ไม่มี';
            } else {
              final modes = counts.entries
                  .where((e) => e.value == maxCount)
                  .map((e) => e.key)
                  .toList();
              modes.sort();
              modeStr = modes
                  .map(
                    (m) => m.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), ''),
                  )
                  .join(', ');
            }
          }

          double sd = 0.0;
          if (scores.length > 1) {
            final sumSq = scores.fold<double>(
              0.0,
              (acc, s) => acc + (s - average) * (s - average),
            );
            sd = math.sqrt(sumSq / (scores.length - 1));
          }

          final itemAnalysis = _calculateItemAnalysis(exam, results);
          final avgDifficulty = _average(
            itemAnalysis.map((item) => item.difficulty).toList(),
          );
          final avgDiscrimination = _average(
            itemAnalysis.map((item) => item.discrimination).toList(),
          );

          _examStats[exam.id] = {
            'count': count,
            'average': average,
            'sd': sd,
            'passRate': passRate,
            'maxScore': maxScore,
            'minScore': minScore,
            'median': median,
            'modeStr': modeStr,
            'avgDifficulty': avgDifficulty,
            'avgDiscrimination': avgDiscrimination,
          };
        }

        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching analysis data: $error');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getCorrectAnswer(ExamModel exam, String qNum, String? setIndex) {
    if (exam.answerKey.isEmpty) return '-';

    String extractAnswer(dynamic val) {
      if (val is Map) return val['answer']?.toString() ?? '-';
      return val.toString();
    }

    if (setIndex != null &&
        exam.answerKey.containsKey(setIndex) &&
        exam.answerKey[setIndex]!.containsKey(qNum)) {
      return extractAnswer(exam.answerKey[setIndex]![qNum]);
    }
    if (exam.answerKey.containsKey('0') &&
        exam.answerKey['0']!.containsKey(qNum)) {
      return extractAnswer(exam.answerKey['0']![qNum]);
    }
    if (exam.answerKey.containsKey('1') &&
        exam.answerKey['1']!.containsKey(qNum)) {
      return extractAnswer(exam.answerKey['1']![qNum]);
    }
    final firstSet = exam.answerKey.values.firstWhere(
      (_) => true,
      orElse: () => {},
    );
    if (firstSet.containsKey(qNum)) {
      return extractAnswer(firstSet[qNum]);
    }
    return '-';
  }

  double _getDynamicScore(Map<String, dynamic> result, ExamModel exam) {
    if (exam.answerKey.isEmpty) {
      return double.tryParse(result['score']?.toString() ?? '0') ?? 0;
    }
    double calcScore = 0;
    final answers = result['answers'] as Map?;
    final itemResults = result['itemResults'] as Map?;
    final setIndex = result['set']?.toString();
    for (int i = 1; i <= exam.questions; i++) {
      final qStr = i.toString();
      final correctAns = _getCorrectAnswer(exam, qStr, setIndex);
      final qScore = exam.getQuestionScore(qStr, setIndex);
      if (answers != null && answers.containsKey(qStr)) {
        if (answers[qStr].toString() == correctAns && correctAns != '-') {
          calcScore += qScore;
        }
      } else if (itemResults != null && itemResults.containsKey(qStr)) {
        if (itemResults[qStr] == true) {
          calcScore += qScore;
        }
      }
    }
    return calcScore;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const SafeArea(child: ListSkeletonLoader())
          : RefreshIndicator(
              onRefresh: _fetchData,
              color: AppColors.info,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        /* Top Premium Gradient Header */ Container(
                          height: 250,
                          decoration: const BoxDecoration(
                            color: AppColors.info,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(36),
                              bottomRight: Radius.circular(36),
                            ),
                          ),
                        ),
                        /* Decorative Circular Glows */ Positioned(
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
                        /* Header Content */ SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                /* Title row */ Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 1.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        FontAwesomeIcons.chartPie,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'ภาพรวมการวิเคราะห์',
                                          style: TextStyle(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        const Text(
                                          'สถิติผลการสอบทั้งหมด',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                _buildSummaryGrid(),
                                const SizedBox(height: 24),
                                _buildGuidancePanel(),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'รายการข้อสอบ',
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_exams.length} ชุด',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_exams.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEmptyState(),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                      sliver: SliverList.separated(
                        itemCount: (() {
                          final totalPages = (_exams.length / _pageSize)
                              .ceil()
                              .clamp(1, 1000000);
                          final page = _currentPage.clamp(1, totalPages);
                          final start = (page - 1) * _pageSize;
                          final end = (start + _pageSize).clamp(
                            0,
                            _exams.length,
                          );
                          final visible = _exams.sublist(start, end);
                          return visible.length +
                              (_exams.length > _pageSize ? 1 : 0);
                        })(),
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final totalPages = (_exams.length / _pageSize)
                              .ceil()
                              .clamp(1, 1000000);
                          final page = _currentPage.clamp(1, totalPages);
                          if (page != _currentPage) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) setState(() => _currentPage = page);
                            });
                          }
                          final start = (page - 1) * _pageSize;
                          final end = (start + _pageSize).clamp(
                            0,
                            _exams.length,
                          );
                          final visible = _exams.sublist(start, end);
                          if (index == visible.length) {
                            return Column(
                              children: [
                                Text(
                                  'แสดง ${start + 1}-$end จาก ${_exams.length} รายการ',
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
                            );
                          }
                          final exam = visible[index];
                          final results = _results
                              .where((result) => result['examId'] == exam.id)
                              .toList();
                          return InkWell(
                            onTap: () =>
                                _showItemAnalysisBottomSheet(exam, results),
                            borderRadius: BorderRadius.circular(20),
                            child: _buildAnalysisCard(exam, results),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryGrid() {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _buildStatCard(
              value: '${_exams.length}',
              label: 'ข้อสอบ',
              icon: FontAwesomeIcons.fileLines,
              color: AppColors.info,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              value: '${_results.length}',
              label: 'ตรวจแล้ว',
              icon: FontAwesomeIcons.userCheck,
              color: AppColors.success,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildStatCard(
              value: '$_uniqueExamineesCount',
              label: 'ผู้เข้าสอบ',
              icon: FontAwesomeIcons.users,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGuidancePanel() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.circleInfo,
                    color: AppColors.info,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'เกณฑ์คุณภาพ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.info.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Text(
                              'p',
                              style: TextStyle(
                                color: AppColors.infoDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'ความยากง่าย',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.infoDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCriteriaRow(
                        '0.80-1.00',
                        'ง่ายไป',
                        AppColors.error,
                        AppColors.error.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        '0.40-0.79',
                        'เหมาะสม',
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.1),
                        isBold: true,
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        '0.00-0.39',
                        'ยากไป',
                        AppColors.error,
                        AppColors.error.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 85,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Text(
                              'D',
                              style: TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              'อำนาจจำแนก',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.success,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildCriteriaRow(
                        '≥ 0.40',
                        'ดีมาก',
                        AppColors.success,
                        AppColors.success.withValues(alpha: 0.1),
                        isBold: true,
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        '0.20-0.39',
                        'พอใช้',
                        AppColors.warning,
                        AppColors.warning.withValues(alpha: 0.1),
                      ),
                      const SizedBox(height: 6),
                      _buildCriteriaRow(
                        '< 0.20',
                        'ปรับปรุง',
                        AppColors.error,
                        AppColors.error.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriteriaRow(
    String range,
    String label,
    Color color,
    Color bgColor, {
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          range,
          style: TextStyle(
            fontSize: 10,
            color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisCard(
    ExamModel exam,
    List<Map<String, dynamic>> results,
  ) {
    final stats = _examStats[exam.id] ?? {};
    final count = stats['count'] ?? 0;
    final average = stats['average'] ?? 0.0;
    final maxScore = stats['maxScore'] ?? 0.0;
    final minScore = stats['minScore'] ?? 0.0;
    final median = stats['median'] ?? 0.0;
    final modeStr = stats['modeStr'] ?? '-';
    final avgDifficulty = stats['avgDifficulty'] ?? 0.0;
    final avgDiscrimination = stats['avgDiscrimination'] ?? 0.0;

    final sd = stats['sd'] ?? 0.0;
    final String sdStr = count > 1 ? (sd as double).toStringAsFixed(2) : '-';

    String fmt(double val) =>
        val.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    final String maxMinStr = count == 0
        ? '-'
        : '${fmt(maxScore)} / ${fmt(minScore)}';
    final String medianStr = count == 0 ? '-' : fmt(median);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.infoSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    FontAwesomeIcons.solidChartBar,
                    color: AppColors.info,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'วิชา: ${_subjectNames[exam.subject] ?? exam.subject}${exam.section == null ? '' : ' · Sec ${exam.section}'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final width3 = (constraints.maxWidth - 16) / 3;
                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: width3,
                          child: _buildMiniStat('ผู้เข้าสอบ', '$count'),
                        ),
                        SizedBox(
                          width: width3,
                          child: _buildMiniStat(
                            'คะแนนเฉลี่ย',
                            average.toStringAsFixed(1),
                          ),
                        ),
                        SizedBox(
                          width: width3,
                          child: _buildMiniStat('ส่วนเบี่ยงเบน (SD)', sdStr),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: width3,
                          child: _buildMiniStat('มัธยฐาน', medianStr),
                        ),
                        SizedBox(
                          width: width3,
                          child: _buildMiniStat('ฐานนิยม', modeStr),
                        ),
                        SizedBox(
                          width: width3,
                          child: _buildMiniStat('สูงสุด/ต่ำสุด', maxMinStr),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stackMeters = constraints.maxWidth < 360;
                final meterWidth = stackMeters
                    ? constraints.maxWidth
                    : (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: meterWidth,
                      child: _buildQualityMeter(
                        label: 'ความยากง่าย',
                        short: 'p',
                        value: avgDifficulty,
                        valueLabel: _difficultyLabel(avgDifficulty),
                        color: _difficultyColor(avgDifficulty),
                      ),
                    ),
                    SizedBox(
                      width: meterWidth,
                      child: _buildQualityMeter(
                        label: 'อำนาจจำแนก',
                        short: 'D',
                        value: avgDiscrimination,
                        valueLabel: _discriminationLabel(avgDiscrimination),
                        color: _discriminationColor(avgDiscrimination),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.infoDark,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityMeter({
    required String label,
    required String short,
    required double value,
    required String valueLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 7),
          Text(
            '$short ${value.toStringAsFixed(2)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valueLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: value.clamp(0.0, 1.0),
              color: color,
              backgroundColor: AppColors.border,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  List<_ItemAnalysis> _calculateItemAnalysis(
    ExamModel exam,
    List<Map<String, dynamic>> results,
  ) {
    if (results.isEmpty || exam.questions <= 0) return [];
    final sorted = [...results]
      ..sort(
        (a, b) =>
            _getDynamicScore(b, exam).compareTo(_getDynamicScore(a, exam)),
      );
    final groupSize = (sorted.length * 0.27)
        .ceil()
        .clamp(1, sorted.length)
        .toInt();
    final upperGroup = sorted.take(groupSize).toList();
    final lowerGroup = sorted.skip(sorted.length - groupSize).toList();
    final items = <_ItemAnalysis>[];
    for (
      var questionIndex = 1;
      questionIndex <= exam.questions;
      questionIndex++
    ) {
      final question = questionIndex.toString();
      final hasItemData = results.any(
        (result) =>
            (result['itemResults'] as Map?)?.containsKey(question) == true ||
            (result['answers'] as Map?)?.containsKey(question) == true,
      );
      if (!hasItemData) continue;

      final correctAns = _getCorrectAnswer(
        exam,
        question,
        results.isNotEmpty ? results.first['set']?.toString() : null,
      );

      final choiceCounts = <String, int>{
        'A': 0,
        'B': 0,
        'C': 0,
        'D': 0,
        'E': 0,
        '-': 0,
      };

      bool isCorrect(Map<String, dynamic> result) {
        final currentCorrectAns = _getCorrectAnswer(
          exam,
          question,
          result['set']?.toString(),
        );
        final answers = result['answers'] as Map?;
        if (answers != null && answers.containsKey(question)) {
          final sAns = answers[question]?.toString().trim() ?? '';
          if (choiceCounts.containsKey(sAns)) {
            choiceCounts[sAns] = (choiceCounts[sAns] ?? 0) + 1;
          } else {
            choiceCounts['-'] = (choiceCounts['-'] ?? 0) + 1;
          }
          return sAns == currentCorrectAns && currentCorrectAns != '-';
        }
        final isCorr = (result['itemResults'] as Map?)?[question] == true;
        if (isCorr) {
          choiceCounts[currentCorrectAns] =
              (choiceCounts[currentCorrectAns] ?? 0) + 1;
        } else {
          choiceCounts['-'] = (choiceCounts['-'] ?? 0) + 1;
        }
        return isCorr;
      }

      final correctCount = results.where(isCorrect).length;
      final upperCorrectCount = upperGroup.where(isCorrect).length;
      final lowerCorrectCount = lowerGroup.where(isCorrect).length;
      final upperCorrect =
          upperGroup.isNotEmpty ? upperCorrectCount / upperGroup.length : 0.0;
      final lowerCorrect =
          lowerGroup.isNotEmpty ? lowerCorrectCount / lowerGroup.length : 0.0;

      items.add(
        _ItemAnalysis(
          question: question,
          answer: correctAns,
          difficulty: correctCount / results.length,
          discrimination: upperCorrect - lowerCorrect,
          correctCount: correctCount,
          totalCount: results.length,
          upperCorrectCount: upperCorrectCount,
          upperGroupLength: upperGroup.length,
          lowerCorrectCount: lowerCorrectCount,
          lowerGroupLength: lowerGroup.length,
          choiceCounts: choiceCounts,
        ),
      );
    }
    return items;
  }

  double _average(List<double> values) {
    if (values.isEmpty) return 0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  String _difficultyLabel(double value) {
    if (value >= 0.8) return 'ง่ายเกินไป';
    if (value >= 0.4) return 'เหมาะสม';
    return 'ยากเกินไป';
  }

  String _discriminationLabel(double value) {
    if (value >= 0.4) return 'ดีมาก';
    if (value >= 0.2) return 'พอใช้';
    return 'ควรปรับปรุง';
  }

  Color _difficultyColor(double value) {
    if (value >= 0.8) return AppColors.warning;
    if (value >= 0.4) return AppColors.success;
    return AppColors.error;
  }

  Color _discriminationColor(double value) {
    if (value >= 0.4) return AppColors.success;
    if (value >= 0.2) return AppColors.warning;
    return AppColors.error;
  }

  Future<void> _exportItemAnalysisCsv(
    ExamModel exam,
    List<_ItemAnalysis> items,
  ) async {
    try {
      final header = [
        'ข้อ',
        'เฉลย',
        'ตอบถูก',
        'ทั้งหมด',
        'p (ความยาก)',
        'ระดับความยาก',
        'กลุ่มสูงตอบถูก',
        'กลุ่มต่ำตอบถูก',
        'D (อำนาจจำแนก)',
        'ผลลัพธ์',
      ];

      final rows = items.map((r) => [
            r.question,
            r.answer,
            '${r.correctCount}',
            '${r.totalCount}',
            r.difficulty.toStringAsFixed(3),
            _difficultyLabel(r.difficulty),
            '${r.upperCorrectCount}/${r.upperGroupLength} (${(r.upperGroupLength > 0 ? (r.upperCorrectCount * 100 / r.upperGroupLength).round() : 0)}%)',
            '${r.lowerCorrectCount}/${r.lowerGroupLength} (${(r.lowerGroupLength > 0 ? (r.lowerCorrectCount * 100 / r.lowerGroupLength).round() : 0)}%)',
            r.discrimination.toStringAsFixed(3),
            _discriminationLabel(r.discrimination),
          ]);

      final csvContent = [header, ...rows]
          .map((row) => row.map((c) => '"${c.replaceAll('"', '""')}"').join(','))
          .join('\n');

      final dir = await getApplicationDocumentsDirectory();
      final filename =
          'Item_Analysis_${exam.name.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${dir.path}/$filename');
      await file.writeAsString('\uFEFF$csvContent', encoding: utf8);

      await OpenFilex.open(file.path);
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.success,
          title: 'ส่งออก CSV สำเร็จ',
          text: 'บันทึกและเปิดไฟล์เรียบร้อยแล้ว',
        );
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'เกิดข้อผิดพลาด',
          text: e.toString(),
        );
      }
    }
  }

  void _showQuestionDetailDialog(
    ExamModel exam,
    _ItemAnalysis item,
    List<Map<String, dynamic>> results,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final upperRate = item.upperGroupLength > 0
            ? (item.upperCorrectCount * 100 / item.upperGroupLength).round()
            : 0;
        final lowerRate = item.lowerGroupLength > 0
            ? (item.lowerCorrectCount * 100 / item.lowerGroupLength).round()
            : 0;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.infoSoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ข้อ ${item.question}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.infoDark,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'เฉลย: ${item.answer}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'ตอบถูก ${item.correctCount}/${item.totalCount} คน (${(item.difficulty * 100).round()}%)',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'กลุ่มคะแนน (27% Upper/Lower):',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'กลุ่มสูงตอบถูก',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.upperCorrectCount}/${item.upperGroupLength} ($upperRate%)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'กลุ่มต่ำตอบถูก',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${item.lowerCorrectCount}/${item.lowerGroupLength} ($lowerRate%)',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'สถิติการเลือกตอบ:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ...['A', 'B', 'C', 'D', 'E', '-'].map((choice) {
                  final cnt = item.choiceCounts[choice] ?? 0;
                  final isAnswer = choice == item.answer;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isAnswer
                                ? AppColors.success
                                : AppColors.background,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            choice == '-' ? 'ไม่ฝน' : choice,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isAnswer ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.totalCount > 0
                                  ? cnt / item.totalCount
                                  : 0,
                              color: isAnswer
                                  ? AppColors.success
                                  : AppColors.info,
                              backgroundColor: AppColors.border,
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '$cnt คน',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isAnswer
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        );
      },
    );
  }

  void _showItemAnalysisBottomSheet(
    ExamModel exam,
    List<Map<String, dynamic>> results,
  ) {
    if (results.isEmpty) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        text: 'ยังไม่มีข้อมูลการวิเคราะห์รายข้อ',
        confirmBtnColor: AppColors.info,
      );
      return;
    }
    final itemAnalysis = _calculateItemAnalysis(exam, results);
    final isLowN = results.length < 15;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.infoSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            FontAwesomeIcons.chartPie,
                            color: AppColors.info,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'วิเคราะห์คุณภาพข้อสอบ',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${exam.name} (${results.length} คน)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _exportItemAnalysisCsv(exam, itemAnalysis),
                          icon: const Icon(FontAwesomeIcons.fileCsv, size: 13),
                          label: const Text(
                            'CSV',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.infoSoft,
                            foregroundColor: AppColors.infoDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isLowN) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'จำนวนผู้สอบน้อยกว่า 15 คน ผลวิเคราะห์ 27% อาจคลาดเคลื่อน',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.warning,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      /* Table Header */ Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft,
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Expanded(
                              flex: 1,
                              child: Text(
                                'ข้อ',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.infoDark,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ตอบถูก',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.infoDark,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ความยาก (p)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.infoDark,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'จำแนก (D)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppColors.infoDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      /* Table Body */ Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: itemAnalysis.length,
                          itemBuilder: (context, index) {
                            final item = itemAnalysis[index];
                            return InkWell(
                              onTap: () => _showQuestionDetailDialog(
                                exam,
                                item,
                                results,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: AppColors.border,
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          item.question,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.textPrimary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${item.correctCount}/${item.totalCount}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.difficulty.toStringAsFixed(2),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _difficultyColor(
                                                item.difficulty,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _difficultyColor(
                                                item.difficulty,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _difficultyLabel(item.difficulty),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: _difficultyColor(
                                                  item.difficulty,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.discrimination.toStringAsFixed(
                                              2,
                                            ),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: _discriminationColor(
                                                item.discrimination,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _discriminationColor(
                                                item.discrimination,
                                              ).withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _discriminationLabel(
                                                item.discrimination,
                                              ),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: _discriminationColor(
                                                  item.discrimination,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                FontAwesomeIcons.chartPie,
                color: AppColors.textMuted,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'ยังไม่มีข้อมูลการวิเคราะห์',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'เพิ่มข้อสอบและผลสอบตัวอย่างก่อน เพื่อดูสถิติและคุณภาพข้อสอบ',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
