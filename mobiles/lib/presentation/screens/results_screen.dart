import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quickalert/quickalert.dart';
import 'package:exam_grading/data/models/exam_model.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';
import 'package:exam_grading/presentation/widgets/pagination_bar.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});
  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';
  List<ExamModel> _exams = [];
  List<Map<String, dynamic>> _results = [];
  bool _isLoading = true;
  final bool _isExporting = false;
  static const int _pageSize = 10;
  int _currentPage = 1;
  String _selectedSubject = 'ทั้งหมด';
  DateTime? _readResultTime(Map<String, dynamic> data) {
    final dynamic val =
        data['createdAt'] ??
        data['created_at'] ??
        data['timestamp'] ??
        data['scanTime'];
    if (val == null) return null;
    if (val is int) {
      if (val > 1000000000000) return DateTime.fromMillisecondsSinceEpoch(val);
      return DateTime.fromMillisecondsSinceEpoch(val * 1000);
    }
    return DateTime.tryParse(val.toString());
  }

  List<String> get _subjects {
    final subjects = _exams
        .map((e) => e.subject)
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    subjects.sort();
    return ['ทั้งหมด', ...subjects];
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

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (_uid.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final examDocs = await ApiService.instance.getCollection(_uid, 'exams');
      final resultDocs = await ApiService.instance.getCollection(
        _uid,
        'results',
      );
      if (mounted) {
        setState(() {
          _exams = examDocs
              .map(
                (doc) => ExamModel.fromMap(
                  doc['id']?.toString() ?? doc['exam_id']?.toString() ?? '',
                  doc,
                ),
              )
              .toList();
          _results = resultDocs;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  'ผลการสอบ',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                background: Container(color: AppColors.surface),
              ),
              actions: [
                if (_isExporting)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedSubject,
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
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedSubject = newValue;
                                _currentPage = 1;
                              });
                            }
                          },
                          items: _subjects.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value == 'ทั้งหมด' ? 'ทุกวิชา' : 'วิชา: $value',
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: SpinKitThreeBounce(color: AppColors.info, size: 32.0),
                ),
              )
            else if (_results.isEmpty)
              SliverFillRemaining(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildEmptyState(),
                ),
              )
            else
              Builder(
                builder: (context) {
                  final docs = [..._results];
                  docs.sort((a, b) {
                    final at = _readResultTime(a);
                    final bt = _readResultTime(b);
                    if (at == null && bt == null) return 0;
                    if (at == null) return 1;
                    if (bt == null) return -1;
                    return bt.compareTo(at);
                  });
                  final filteredDocs = docs.where((data) {
                    if (_selectedSubject == 'ทั้งหมด') return true;
                    final examId = data['examId']?.toString() ?? '';
                    String subjectCode = '';
                    if (examId.contains('_')) {
                      subjectCode = examId.split('_')[0];
                    } else {
                      try {
                        final exam = _exams.firstWhere((e) => e.id == examId);
                        subjectCode = exam.subject;
                      } catch (e) {
                        /* Do nothing */
                      }
                    }
                    return subjectCode == _selectedSubject;
                  }).toList();
                  if (filteredDocs.isEmpty) {
                    return SliverFillRemaining(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _buildEmptyState(),
                      ),
                    );
                  }
                  final totalPages = (filteredDocs.length / _pageSize)
                      .ceil()
                      .clamp(1, 1000000);
                  final page = _currentPage.clamp(1, totalPages);
                  if (page != _currentPage) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _currentPage = page);
                    });
                  }
                  final start = (page - 1) * _pageSize;
                  final end = (start + _pageSize).clamp(0, filteredDocs.length);
                  final visibleDocs = filteredDocs.sublist(start, end);
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == visibleDocs.length) {
                            return Column(
                              children: [
                                Text(
                                  'แสดง ${start + 1}-$end จาก ${filteredDocs.length} รายการ',
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
                          final data = visibleDocs[index];
                          final examId =
                              data['examId']?.toString() ?? 'ไม่ระบุ';
                          final isPending = data['score'] == null;
                          final rawFlagged = data['flagged'];
                          final bool hasFlaggedData =
                              (rawFlagged is List && rawFlagged.isNotEmpty) ||
                              rawFlagged == true ||
                              rawFlagged == 1 ||
                              rawFlagged == '1' ||
                              rawFlagged == 'true';
                          final rawStatus = data['status']
                              ?.toString()
                              .toLowerCase();
                          final bool isError =
                              rawStatus == 'warning' ||
                              rawStatus == 'error' ||
                              rawStatus == 'failed' ||
                              rawStatus == 'flagged';
                          final bool isAbnormal =
                              isPending || isError || hasFlaggedData;

                          ExamModel? currentExam;
                          try {
                            currentExam = _exams.firstWhere(
                              (e) => e.id == examId,
                            );
                          } catch (_) {}

                          double dynamicScore =
                              double.tryParse(
                                data['score']?.toString() ?? '0',
                              ) ??
                              0;

                          if (!isAbnormal &&
                              currentExam != null &&
                              (data.containsKey('answers') ||
                                  data.containsKey('itemResults'))) {
                            double calculatedScore = 0;
                            final answers = data['answers'] as Map?;
                            final itemResults = data['itemResults'] as Map?;
                            final setIndex = data['set']?.toString();
                            for (int i = 1; i <= currentExam.questions; i++) {
                              final qStr = i.toString();
                              final correctAns = _getCorrectAnswer(
                                currentExam,
                                qStr,
                                setIndex,
                              );
                              final qScore = currentExam.getQuestionScore(
                                qStr,
                                setIndex,
                              );
                              if (answers != null &&
                                  answers.containsKey(qStr)) {
                                if (answers[qStr].toString() == correctAns &&
                                    correctAns != '-') {
                                  calculatedScore += qScore;
                                }
                              } else if (itemResults != null &&
                                  itemResults.containsKey(qStr)) {
                                if (itemResults[qStr] == true) {
                                  calculatedScore += qScore;
                                }
                              }
                            }
                            dynamicScore = calculatedScore;
                          }

                          String scoreStr = dynamicScore.toString();
                          if (isError || hasFlaggedData) {
                            scoreStr = 'พบปัญหา';
                          } else if (isPending) {
                            scoreStr = 'รอตรวจ';
                          }
                          /* Parse exam ID for a cleaner display */
                          String subjectCode = '';
                          String examName = examId;
                          if (examId.contains('_')) {
                            final parts = examId.split('_');
                            subjectCode = parts[0];
                            examName = parts
                                .sublist(1)
                                .join(' ')
                                .replaceAll('_', ' ');
                          }
                          final studentName =
                              data['studentName']?.toString() ??
                              'ไม่พบชื่อนักเรียน';
                          final studentCode =
                              data['studentCode']?.toString() ?? '';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                onTap: () {
                                  if (!isPending && currentExam != null) {
                                    _showAnswerDetails(
                                      context,
                                      data,
                                      currentExam,
                                      dynamicScore,
                                    );
                                  } else if (!isPending) {
                                    final exam = ExamModel(
                                      id: examId,
                                      name: examName,
                                      subject: subjectCode,
                                      date: '',
                                      questions: 0,
                                      options: 0,
                                      sets: 0,
                                      answerKey: {},
                                    );
                                    _showAnswerDetails(
                                      context,
                                      data,
                                      exam,
                                      dynamicScore,
                                    );
                                  }
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
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
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                studentName,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                  color: AppColors.textPrimary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (studentCode.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  studentCode,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppColors.textSecondary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                              const SizedBox(height: 4),
                                              Text(
                                                currentExam?.name ?? examName,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                currentExam?.subject ??
                                                    subjectCode,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: (isError || hasFlaggedData)
                                                ? Colors.amber.shade50
                                                : (isPending
                                                      ? AppColors.surface
                                                      : AppColors.infoSoft),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: (isError || hasFlaggedData)
                                                  ? Colors.amber.shade200
                                                  : (isPending
                                                        ? AppColors.border
                                                        : AppColors.info
                                                              .withValues(
                                                                alpha: 0.2,
                                                              )),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            isAbnormal
                                                ? scoreStr
                                                : '$scoreStr/${currentExam?.getTotalScore(data['set']?.toString()).toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '') ?? 0} คะแนน',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: (isError || hasFlaggedData)
                                                  ? Colors.amber.shade800
                                                  : (isPending
                                                        ? AppColors
                                                              .textSecondary
                                                        : AppColors.infoDark),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        childCount:
                            visibleDocs.length +
                            (filteredDocs.length > _pageSize ? 1 : 0),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAnswerDetails(
    BuildContext context,
    Map<String, dynamic> result,
    ExamModel exam,
    double dynamicScore,
  ) {
    if (result['answers'] == null && result['itemResults'] == null) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.info,
        text: 'ไม่พบข้อมูลคำตอบสำหรับผลสอบนี้',
        confirmBtnColor: AppColors.error,
      );
      return;
    }
    final answers = result['answers'] as Map<String, dynamic>? ?? {};
    final itemResults = result['itemResults'] as Map<String, dynamic>? ?? {};
    final skippedQs = (result['skipped'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    final rawFlagged = result['flagged'];
    final bool hasFlaggedData =
        (rawFlagged is List && rawFlagged.isNotEmpty) ||
        rawFlagged == true ||
        rawFlagged == 1 ||
        rawFlagged == '1' ||
        rawFlagged == 'true';

    final rawStatus = result['status']?.toString().toLowerCase();
    final bool isError =
        rawStatus == 'warning' ||
        rawStatus == 'error' ||
        rawStatus == 'failed' ||
        rawStatus == 'flagged';
    final bool isPending = result['score'] == null;

    final List<String> flaggedReasons = [];
    final Map<String, dynamic> flaggedMap = {};
    if (result['flagged'] is List) {
      for (var f in (result['flagged'] as List)) {
        if (f is Map && f['question'] != null) {
          flaggedMap[f['question'].toString()] = f;
        }
      }
    }

    final totalQCount = exam.questions > 0
        ? exam.questions
        : (answers.isNotEmpty ? answers.length : 20);

    for (int i = 1; i <= totalQCount; i++) {
      final qNum = i.toString();
      final flagInfo = flaggedMap[qNum];
      String studentAns = '-';
      bool isSkipped = false;
      bool isMultiMark = false;

      if (answers.isNotEmpty && answers.containsKey(qNum)) {
        studentAns = answers[qNum].toString().trim();
        if (studentAns == '-' ||
            studentAns.isEmpty ||
            skippedQs.contains(qNum)) {
          isSkipped = true;
        } else if (studentAns.contains(',') || studentAns.length > 1) {
          isMultiMark = true;
        }
      } else if (itemResults.isNotEmpty) {
        if (itemResults[qNum] == null || itemResults[qNum] == '-') {
          isSkipped = true;
        }
      }

      if (isMultiMark ||
          (flagInfo != null && flagInfo['reason'] == 'multiple_mark')) {
        flaggedReasons.add('ข้อ $qNum: ฝนมากกว่า 1 ตัวเลือก');
      } else if (flagInfo != null && flagInfo['reason'] == 'low_confidence') {
        flaggedReasons.add(
          'ข้อ $qNum: ไม่มั่นใจในการอ่านจุดฝน (อาจลบไม่สะอาด)',
        );
      } else if (flagInfo != null && flagInfo['reason'] == 'out_of_bounds') {
        flaggedReasons.add('ข้อ $qNum: ฝนเกินขอบเขตที่กำหนด');
      } else if (isSkipped) {
        flaggedReasons.add('ข้อ $qNum: ไม่ได้ฝนคำตอบ');
      }
    }

    if (result['flagged'] is List) {
      for (var f in (result['flagged'] as List)) {
        if (f is Map && f['reason'] == 'not_filled') {
          flaggedReasons.add('ข้อ ${f['question'] ?? "-"}: ไม่ได้ฝนคำตอบ');
        }
      }
    }

    final uniqueFlaggedReasons = flaggedReasons.toSet().toList();
    final bool isActuallyFlagged =
        uniqueFlaggedReasons.isNotEmpty ||
        hasFlaggedData ||
        isError ||
        isPending;

    final imageUrl = result['imageUrl']?.toString().trim() ?? '';
    final hasImageUrl = imageUrl.isNotEmpty;

    final formattedScore = isActuallyFlagged
        ? '-'
        : dynamicScore.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    final formattedTotal = exam
        .getTotalScore(result['set']?.toString())
        .toStringAsFixed(1)
        .replaceAll(RegExp(r'\.0$'), '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
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
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'รายละเอียดคำตอบ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exam.name,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isActuallyFlagged
                                ? Colors.amber.shade700
                                : AppColors.info,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isActuallyFlagged
                                ? []
                                : AppColors.infoShadow,
                          ),
                          child: Text(
                            '$formattedScore/$formattedTotal คะแนน',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (isActuallyFlagged) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            border: Border.all(color: Colors.amber.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      FontAwesomeIcons.triangleExclamation,
                                      color: Colors.amber.shade800,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'ผลสอบมีปัญหา กรุณาตรวจสอบ',
                                      style: TextStyle(
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (uniqueFlaggedReasons.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: uniqueFlaggedReasons.map((reason) {
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        left: 24,
                                        bottom: 4,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '• ',
                                            style: TextStyle(
                                              color: Colors.amber.shade800,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              reason,
                                              style: TextStyle(
                                                color: Colors.amber.shade900,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (hasImageUrl) ...[
                        GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => Dialog(
                                insetPadding: const EdgeInsets.all(12),
                                backgroundColor: Colors.black87,
                                child: Stack(
                                  children: [
                                    InteractiveViewer(
                                      minScale: 0.8,
                                      maxScale: 4,
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.contain,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return SizedBox(
                                            height: 320,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                color: AppColors.info,
                                                value:
                                                    progress.expectedTotalBytes !=
                                                        null
                                                    ? progress.cumulativeBytesLoaded /
                                                          progress
                                                              .expectedTotalBytes!
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder: (_, __, ___) =>
                                            const SizedBox(
                                              height: 220,
                                              child: Center(
                                                child: Text(
                                                  'โหลดรูปภาพไม่ได้',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 8,
                                      top: 8,
                                      child: IconButton(
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                        icon: const Icon(
                                          Icons.close,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'กระดาษคำตอบที่สแกน',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    imageUrl,
                                    height: 180,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return SizedBox(
                                        height: 180,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            color: AppColors.info,
                                            value:
                                                progress.expectedTotalBytes !=
                                                    null
                                                ? progress.cumulativeBytesLoaded /
                                                      progress
                                                          .expectedTotalBytes!
                                                : null,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 180,
                                      color: AppColors.surface,
                                      alignment: Alignment.center,
                                      child: Text(
                                        'โหลดรูปภาพไม่ได้',
                                        style: TextStyle(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'แตะที่รูปเพื่อขยายดูเต็มหน้าจอ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: exam.questions,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, qIndex) {
                          final qNum = (qIndex + 1).toString();
                          final setIndex = result['set']?.toString();
                          final correctAns = _getCorrectAnswer(
                            exam,
                            qNum,
                            setIndex,
                          );
                          String studentAns = '-';
                          bool isCorrect = false;
                          bool isSkipped = false;

                          if (answers.isNotEmpty && answers.containsKey(qNum)) {
                            studentAns = answers[qNum].toString().trim();
                            if (studentAns == '-' ||
                                studentAns.isEmpty ||
                                skippedQs.contains(qNum)) {
                              isSkipped = true;
                              studentAns = '-';
                            } else {
                              isCorrect =
                                  studentAns == correctAns && correctAns != '-';
                            }
                          } else if (result.containsKey('itemResults')) {
                            final itemResults =
                                result['itemResults'] as Map<String, dynamic>;
                            isCorrect = itemResults[qNum] == true;
                            if (isCorrect) {
                              studentAns = correctAns;
                            } else if (itemResults[qNum] == false) {
                              studentAns = 'X';
                            } else {
                              studentAns = '-';
                            }
                            if (studentAns == '-' ||
                                studentAns.isEmpty ||
                                skippedQs.contains(qNum)) {
                              isSkipped = true;
                              studentAns = '-';
                            }
                          }

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSkipped
                                    ? AppColors.border
                                    : (isCorrect
                                          ? AppColors.success.withValues(
                                              alpha: 0.3,
                                            )
                                          : AppColors.error.withValues(
                                              alpha: 0.3,
                                            )),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      (isSkipped
                                              ? Colors.black
                                              : (isCorrect
                                                    ? AppColors.success
                                                    : AppColors.error))
                                          .withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: isSkipped
                                        ? AppColors.surface
                                        : (isCorrect
                                              ? AppColors.success.withValues(
                                                  alpha: 0.1,
                                                )
                                              : AppColors.error.withValues(
                                                  alpha: 0.1,
                                                )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      qNum,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isSkipped
                                            ? AppColors.textSecondary
                                            : (isCorrect
                                                  ? AppColors.success
                                                  : AppColors.error),
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
                                        'ตอบ',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isSkipped ? '-' : studentAns,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isSkipped
                                              ? AppColors.textMuted
                                              : (isCorrect
                                                    ? AppColors.success
                                                    : AppColors.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: AppColors.border,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'เฉลย',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        correctAns,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isSkipped
                                        ? AppColors.surface
                                        : (isCorrect
                                              ? AppColors.success.withValues(
                                                  alpha: 0.1,
                                                )
                                              : AppColors.error.withValues(
                                                  alpha: 0.1,
                                                )),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Icon(
                                      isSkipped
                                          ? FontAwesomeIcons.minus
                                          : (isCorrect
                                                ? FontAwesomeIcons.check
                                                : FontAwesomeIcons.xmark),
                                      size: 14,
                                      color: isSkipped
                                          ? AppColors.textMuted
                                          : (isCorrect
                                                ? AppColors.success
                                                : AppColors.error),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
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
            child: Center(
              child: Icon(
                FontAwesomeIcons.folderOpen,
                size: 32,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'ยังไม่มีข้อมูลผลการสอบ',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เมื่อมีการสแกนและตรวจข้อสอบแล้ว ผลจะปรากฏที่หน้านี้',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
