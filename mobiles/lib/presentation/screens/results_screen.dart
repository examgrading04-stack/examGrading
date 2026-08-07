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
  static const int _pageSize = 10;
  int _currentPage = 1;
  String _selectedSubject = 'ทั้งหมด';
  DateTime? _readResultTime(Map<String, dynamic> data) {
    final dynamic createdAt = data['createdAt'];
    if (createdAt != null) return DateTime.tryParse(createdAt.toString());
    final dynamic timestamp = data['timestamp'];
    if (timestamp != null) return DateTime.tryParse(timestamp.toString());
    return null;
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
    if (setIndex != null &&
        exam.answerKey.containsKey(setIndex) &&
        exam.answerKey[setIndex]!.containsKey(qNum)) {
      return exam.answerKey[setIndex]![qNum].toString();
    }
    if (exam.answerKey.containsKey('0') &&
        exam.answerKey['0']!.containsKey(qNum)) {
      return exam.answerKey['0']![qNum].toString();
    }
    if (exam.answerKey.containsKey('1') &&
        exam.answerKey['1']!.containsKey(qNum)) {
      return exam.answerKey['1']![qNum].toString();
    }
    final firstSet = exam.answerKey.values.firstWhere(
      (_) => true,
      orElse: () => {},
    );
    if (firstSet.containsKey(qNum)) {
      return firstSet[qNum].toString();
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
                'ผลการสอบ',
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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Container(
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
                        final examId = data['examId']?.toString() ?? 'ไม่ระบุ';
                        final isPending = data['score'] == null;
                        ExamModel? currentExam;
                        try {
                          currentExam = _exams.firstWhere(
                            (e) => e.id == examId,
                          );
                        } catch (_) {}
                        int dynamicScore =
                            int.tryParse(data['score']?.toString() ?? '0') ?? 0;
                        if (currentExam != null &&
                            (data.containsKey('answers') ||
                                data.containsKey('itemResults'))) {
                          int calculatedScore = 0;
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
                            if (answers != null && answers.containsKey(qStr)) {
                              if (answers[qStr].toString() == correctAns &&
                                  correctAns != '-') {
                                calculatedScore++;
                              }
                            } else if (itemResults != null &&
                                itemResults.containsKey(qStr)) {
                              if (itemResults[qStr] == true) {
                                calculatedScore++;
                              }
                            }
                          }
                          dynamicScore = calculatedScore;
                        }
                        final scoreStr = isPending
                            ? 'กำลังประมวลผล...'
                            : dynamicScore.toString();
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
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                            const SizedBox(height: 4),
                                            Text(
                                              currentExam?.name ?? examName,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
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
                                                color: AppColors.textSecondary,
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
                                          color: isPending
                                              ? AppColors.surface
                                              : AppColors.infoSoft,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: Border.all(
                                            color: isPending
                                                ? AppColors.border
                                                : AppColors.info.withValues(
                                                    alpha: 0.2,
                                                  ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Text(
                                          isPending
                                              ? 'รอตรวจ'
                                              : '$scoreStr/${currentExam?.questions ?? 0} คะแนน',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: isPending
                                                ? AppColors.textSecondary
                                                : AppColors.infoDark,
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
    );
  }

  void _showAnswerDetails(
    BuildContext context,
    Map<String, dynamic> result,
    ExamModel exam,
    int dynamicScore,
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
    final imageUrl = result['imageUrl']?.toString().trim() ?? '';
    final hasImageUrl = imageUrl.isNotEmpty;
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
                            Text(
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
                              style: TextStyle(
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
                            color: AppColors.info,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.infoShadow,
                          ),
                          child: Text(
                            '$dynamicScore/${exam.questions} คะแนน',
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
                            studentAns = answers[qNum].toString();
                            if (studentAns == '-') {
                              isSkipped = true;
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
                            if (studentAns == '-') isSkipped = true;
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
