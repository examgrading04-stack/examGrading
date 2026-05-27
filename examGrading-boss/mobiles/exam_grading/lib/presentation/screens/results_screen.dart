import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:quickalert/quickalert.dart';

import 'package:exam_grading/data/models/exam_model.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<ExamModel> _exams = [];
  String _selectedSubject = 'ทั้งหมด';

  DateTime? _readResultTime(Map<String, dynamic> data) {
    final dynamic createdAt = data['createdAt'];
    if (createdAt is Timestamp) return createdAt.toDate();
    final dynamic timestamp = data['timestamp'];
    if (timestamp is Timestamp) return timestamp.toDate();
    return null;
  }

  List<String> get _subjects {
    final subjects = _exams.map((e) => e.subject).where((s) => s.isNotEmpty).toSet().toList();
    subjects.sort();
    return ['ทั้งหมด', ...subjects];
  }

  String _getCorrectAnswer(ExamModel exam, String qNum, String? setIndex) {
    if (exam.answerKey.isEmpty) return '-';
    if (setIndex != null && exam.answerKey.containsKey(setIndex) && exam.answerKey[setIndex]!.containsKey(qNum)) {
      return exam.answerKey[setIndex]![qNum].toString();
    }
    if (exam.answerKey.containsKey('0') && exam.answerKey['0']!.containsKey(qNum)) {
      return exam.answerKey['0']![qNum].toString();
    }
    if (exam.answerKey.containsKey('1') && exam.answerKey['1']!.containsKey(qNum)) {
      return exam.answerKey['1']![qNum].toString();
    }
    final firstSet = exam.answerKey.values.firstWhere((_) => true, orElse: () => {});
    if (firstSet.containsKey(qNum)) {
      return firstSet[qNum].toString();
    }
    return '-';
  }

  @override
  void initState() {
    super.initState();
    _fetchExams();
  }

  Future<void> _fetchExams() async {
    final uid = FirebaseAuth.instance.currentUser?.email ?? '';
    if (uid.isEmpty) {
      return;
    }
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('exams')
          .get();
      if (mounted) {
        setState(() {
          _exams = snapshot.docs
              .map((doc) => ExamModel.fromMap(doc.id, doc.data()))
              .toList();
        });
      }
    } catch (e) {
      debugPrint('Error fetching exams for results filter: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            iconTheme: IconThemeData(color: AppColors.textPrimary),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 0, 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ผลคะแนนสอบ',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'แสดงผลการตรวจข้อสอบล่าสุด',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
              background: Container(
                color: AppColors.surface,
              ),
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
                    icon: Icon(FontAwesomeIcons.chevronDown, size: 14, color: AppColors.textSecondary),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedSubject = newValue;
                        });
                      }
                    },
                    items: _subjects.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value == 'ทั้งหมด' ? 'รายวิชาทั้งหมด' : 'วิชา: $value'),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: uid.isNotEmpty
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('results')
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: SpinKitThreeBounce(
                      color: AppColors.primary,
                      size: 32.0,
                    ),
                  ),
                );
              }
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(FontAwesomeIcons.triangleExclamation, color: AppColors.error, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'โหลดผลสอบไม่สำเร็จ: ${snapshot.error}',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildEmptyState(),
                  ),
                );
              }

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

              final filteredDocs = docs.where((doc) {
                if (_selectedSubject == 'ทั้งหมด') return true;
                final data = doc.data() as Map<String, dynamic>;
                final examId = data['examId'] ?? '';
                
                String subjectCode = '';
                if (examId.contains('_')) {
                  subjectCode = examId.split('_')[0];
                } else {
                  try {
                    final exam = _exams.firstWhere((e) => e.id == examId);
                    subjectCode = exam.subject;
                  } catch (e) {
                    // Do nothing
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

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data = filteredDocs[index].data() as Map<String, dynamic>;
                    final examId = data['examId'] ?? 'ไม่ระบุ';
                    final isPending = data['score'] == null;
                    
                    ExamModel? currentExam;
                    try {
                      currentExam = _exams.firstWhere((e) => e.id == examId);
                    } catch (_) {}

                    int dynamicScore = int.tryParse(data['score']?.toString() ?? '0') ?? 0;
                    
                    if (currentExam != null && (data.containsKey('answers') || data.containsKey('itemResults'))) {
                      int calculatedScore = 0;
                      final answers = data['answers'] as Map?;
                      final itemResults = data['itemResults'] as Map?;
                      final setIndex = data['set']?.toString();

                      for (int i = 1; i <= currentExam.questions; i++) {
                        final qStr = i.toString();
                        final correctAns = _getCorrectAnswer(currentExam, qStr, setIndex);
                        
                        if (answers != null && answers.containsKey(qStr)) {
                          if (answers[qStr].toString() == correctAns && correctAns != '-') {
                            calculatedScore++;
                          }
                        } else if (itemResults != null && itemResults.containsKey(qStr)) {
                          if (itemResults[qStr] == true) {
                            calculatedScore++;
                          }
                        }
                      }
                      dynamicScore = calculatedScore;
                    }
                    
                    final scoreStr = isPending ? 'กำลังประมวลผล...' : dynamicScore.toString();
                    final readTime = _readResultTime(data);
                    final dateString = readTime != null
                        ? "${readTime.day}/${readTime.month}/${readTime.year} ${readTime.hour}:${readTime.minute.toString().padLeft(2, '0')} น."
                        : 'ไม่ทราบเวลา';

                    // Parse exam ID for a cleaner display
                    String subjectCode = '';
                    String examName = examId;
                    if (examId.contains('_')) {
                      final parts = examId.split('_');
                      subjectCode = parts[0];
                      examName = parts.sublist(1).join(' ').replaceAll('_', ' ');
                    }

                    final studentName = data['studentName']?.toString() ?? 'นักเรียนไม่ทราบชื่อ';
                    final studentCode = data['studentCode']?.toString() ?? '';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                              if (!isPending && currentExam != null) {
                                _showAnswerDetails(context, data, currentExam, dynamicScore);
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
                                _showAnswerDetails(context, data, exam, dynamicScore);
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
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isPending
                                            ? [
                                                const Color(0xFF9CA3AF),
                                                const Color(0xFFD1D5DB),
                                              ]
                                            : AppColors.primaryGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        if (!isPending) ...AppColors.primaryShadow,
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        isPending
                                            ? FontAwesomeIcons.clockRotateLeft
                                            : FontAwesomeIcons.fileSignature,
                                        color: Colors.white,
                                        size: 20,
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
                                          studentName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (studentCode.isNotEmpty) ...[
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
                                                child: Text('รหัส: $studentCode', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 9)),
                                              ),
                                              const SizedBox(width: 6),
                                            ],
                                            Expanded(
                                              child: Text(
                                                examName,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            Icon(FontAwesomeIcons.solidClock, size: 10, color: AppColors.textMuted),
                                            const SizedBox(width: 6),
                                            Text(dateString, style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500)),
                                          ],
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
                                          : AppColors.primarySoft,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: isPending
                                            ? AppColors.border
                                            : AppColors.primary.withValues(alpha: 0.2),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      isPending ? 'รอตรวจ' : '$scoreStr คะแนน',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isPending
                                            ? AppColors.textSecondary
                                            : AppColors.primaryDark,
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
                  }, childCount: filteredDocs.length),
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
        text: 'ไม่มีข้อมูลคำตอบสำหรับผลสอบนี้',
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
                            gradient: const LinearGradient(
                              colors: AppColors.primaryGradient,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.primaryShadow,
                          ),
                          child: Text(
                            '$dynamicScore คะแนน',
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(24),
                  itemCount: exam.questions + (hasImageUrl ? 1 : 0),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    if (hasImageUrl && index == 0) {
                      return GestureDetector(
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
                                              color: AppColors.primary,
                                              value: progress.expectedTotalBytes != null
                                                  ? progress.cumulativeBytesLoaded /
                                                      progress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (_, __, ___) => const SizedBox(
                                        height: 220,
                                        child: Center(
                                          child: Text(
                                            'โหลดรูปไม่สำเร็จ',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: IconButton(
                                      onPressed: () => Navigator.of(ctx).pop(),
                                      icon: const Icon(Icons.close, color: Colors.white),
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
                                'รูปกระดาษคำตอบที่ตรวจ',
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
                                          color: AppColors.primary,
                                          value: progress.expectedTotalBytes != null
                                              ? progress.cumulativeBytesLoaded /
                                                  progress.expectedTotalBytes!
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
                                      'โหลดรูปไม่สำเร็จ',
                                      style: TextStyle(color: AppColors.textSecondary),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'แตะเพื่อดูรูปขนาดใหญ่',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final questionIndex = hasImageUrl ? index - 1 : index;
                    final qNum = (questionIndex + 1).toString();
                    final setIndex = result['set']?.toString();
                    final correctAns = _getCorrectAnswer(exam, qNum, setIndex);

                    String studentAns = '-';
                    bool isCorrect = false;

                    if (answers.isNotEmpty && answers.containsKey(qNum)) {
                      studentAns = answers[qNum].toString();
                      isCorrect = studentAns == correctAns && correctAns != '-';
                    } else if (result.containsKey('itemResults')) {
                      final itemResults = result['itemResults'] as Map<String, dynamic>;
                      isCorrect = itemResults[qNum] == true;
                      if (isCorrect) {
                        studentAns = correctAns;
                      } else if (itemResults[qNum] == false) {
                        studentAns = 'X';
                      } else {
                        studentAns = '-';
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? AppColors.success.withValues(alpha: 0.1)
                            : AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCorrect
                              ? AppColors.success.withValues(alpha: 0.3)
                              : AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isCorrect
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : AppColors.error.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                qNum,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isCorrect
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'ตอบ',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      studentAns.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isCorrect
                                            ? AppColors.success
                                            : AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: AppColors.border,
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      'เฉลย',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      correctAns.toString(),
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            isCorrect
                                ? FontAwesomeIcons.check
                                : FontAwesomeIcons.xmark,
                            color: isCorrect
                                ? AppColors.success
                                : AppColors.error,
                            size: 20,
                          ),
                        ],
                      ),
                    );
                  },
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
            'ยังไม่มีประวัติการตรวจ',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เริ่มสแกนกระดาษคำตอบของคุณเพื่อดูผลลัพธ์',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
