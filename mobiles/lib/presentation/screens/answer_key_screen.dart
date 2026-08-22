import 'package:flutter/material.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:exam_grading/data/models/exam_model.dart';
import 'package:exam_grading/data/services/auth_service.dart';
import 'package:exam_grading/data/services/api_service.dart';
import 'package:exam_grading/presentation/theme/app_colors.dart';

class AnswerKeyScreen extends StatefulWidget {
  final ExamModel exam;

  const AnswerKeyScreen({super.key, required this.exam});

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  String get _uid => AuthService.instance.currentEmail ?? '';

  Map<String, Map<String, String>> _answerKeys = {};
  Map<String, Map<String, double>> _scores = {};
  final int _currentSetIndex = 0;

  bool _isLoading = true;
  bool _isSaving = false;

  bool _isCustomScore = false;
  final TextEditingController _globalScoreController = TextEditingController(
    text: "0.5",
  );

  int get _sheetTypeCount {
    final st = widget.exam.sheetType ?? '100-A-E';
    if (st.startsWith('30')) return 30;
    if (st.startsWith('50')) return 50;
    return 100;
  }

  @override
  void initState() {
    super.initState();
    _fetchAnswerKey();
  }

  Future<void> _fetchAnswerKey() async {
    if (_uid.isEmpty) return;
    try {
      final examData = await ApiService.instance.getDoc(
        _uid,
        'exams',
        widget.exam.id,
      );

      Map<String, Map<String, dynamic>> rawAnswerKey = widget.exam.answerKey;

      if (examData != null) {
        final r = examData['answerKey'] ?? examData['answerKeys'];
        if (r != null && r is Map) {
          rawAnswerKey = _parseRawAnswerKeyDynamic(r);
        }

        if (examData['isCustomScore'] != null) {
          _isCustomScore = examData['isCustomScore'] == true;
        }

        if (examData['defaultScore'] != null) {
          _globalScoreController.text = examData['defaultScore'].toString();
        }
      }

      final numSets = widget.exam.sets > 0 ? widget.exam.sets : 1;

      Map<String, Map<String, String>> tempAnswerKeys = {};
      Map<String, Map<String, double>> tempScores = {};
      bool hasCustomScore = false;

      for (int i = 0; i < numSets; i++) {
        String sId = i.toString();
        tempAnswerKeys[sId] = {};
        tempScores[sId] = {};

        final setAnswers = rawAnswerKey[sId] ?? {};
        for (var entry in setAnswers.entries) {
          final q = entry.key;
          final v = entry.value;
          if (v is Map) {
            tempAnswerKeys[sId]![q] = v['answer']?.toString() ?? '';
            final scoreVal =
                double.tryParse(v['score']?.toString() ?? '0.5') ?? 0.5;
            tempScores[sId]![q] = scoreVal;
            if (scoreVal != 0.5) hasCustomScore = true;
          } else {
            tempAnswerKeys[sId]![q] = v.toString();
            tempScores[sId]![q] = 0.5;
          }
        }
      }

      setState(() {
        _answerKeys = tempAnswerKeys;
        _scores = tempScores;
        _isCustomScore = _isCustomScore || hasCustomScore;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching answer keys: $e');
      setState(() => _isLoading = false);
    }
  }

  Map<String, Map<String, dynamic>> _parseRawAnswerKeyDynamic(dynamic raw) {
    if (raw is! Map) return {};
    if (raw.isNotEmpty) {
      final firstVal = raw.values.first;
      if (firstVal is! Map || firstVal.containsKey('answer')) {
        return {'0': raw.map((k, v) => MapEntry(k.toString(), v))};
      }
    }
    return raw.map((setIndex, answers) {
      final answerMap = answers is Map ? answers : <dynamic, dynamic>{};
      return MapEntry(
        setIndex.toString(),
        answerMap.map(
          (question, answer) => MapEntry(question.toString(), answer),
        ),
      );
    });
  }

  void _syncGlobalScore() {
    final gScore = double.tryParse(_globalScoreController.text) ?? 0.5;
    setState(() {
      for (var sId in _scores.keys) {
        for (var qNum in _scores[sId]!.keys) {
          _scores[sId]![qNum] = gScore;
        }
      }
    });
  }

  Future<void> _saveAnswerKey() async {
    if (_uid.isEmpty) return;

    final currentSetData = _answerKeys[_currentSetIndex.toString()] ?? {};
    int answeredCount = 0;
    for (int i = 1; i <= widget.exam.questions; i++) {
      if (currentSetData[i.toString()] != null &&
          currentSetData[i.toString()]!.isNotEmpty) {
        answeredCount++;
      }
    }

    if (answeredCount < widget.exam.questions) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text:
            'กรุณากำหนดเฉลยให้ครบทุกข้อ (ขาดอีก ${widget.exam.questions - answeredCount} ข้อ)',
        confirmBtnColor: AppColors.primary,
      );
      return;
    }

    setState(() => _isSaving = true);

    Map<String, Map<String, dynamic>> payload = {};
    for (var sId in _answerKeys.keys) {
      payload[sId] = {};
      for (var qNum in _answerKeys[sId]!.keys) {
        final ans = _answerKeys[sId]![qNum];
        if (ans == null || ans.isEmpty) continue;

        if (_isCustomScore) {
          final s =
              _scores[sId]?[qNum] ??
              (double.tryParse(_globalScoreController.text) ?? 0.5);
          payload[sId]![qNum] = {'answer': ans, 'score': s};
        } else {
          payload[sId]![qNum] = ans;
        }
      }
    }

    try {
      await ApiService.instance.updateDoc(_uid, 'exams', widget.exam.id, {
        'answerKey': payload,
        'isCustomScore': _isCustomScore,
        'defaultScore': double.tryParse(_globalScoreController.text) ?? 0.5,
      });

      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'บันทึกเฉลยสำเร็จ',
        confirmBtnColor: AppColors.primary,
      );
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SpinKitCircle(color: AppColors.primary, size: 50.0),
        ),
      );
    }

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
                'เฉลย: ${widget.exam.name}',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(color: AppColors.surface),
            ),
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
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
                )
              else
                IconButton(
                  icon: const Icon(Icons.save, color: AppColors.primary),
                  onPressed: _saveAnswerKey,
                  tooltip: 'บันทึกเฉลย',
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                  boxShadow: AppColors.softShadow,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'กำหนดคะแนนเองรายข้อ',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Switch(
                          value: _isCustomScore,
                          activeThumbColor: AppColors.primary,
                          onChanged: (val) {
                            setState(() => _isCustomScore = val);
                          },
                        ),
                      ],
                    ),
                    if (_isCustomScore) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            'คะแนนเริ่มต้น:',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _globalScoreController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              textAlign: TextAlign.center,
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onChanged: (_) => _syncGlobalScore(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final qNum = index + 1;
                final bool isDisabled = qNum > widget.exam.questions;
                final selectedAnswer =
                    _answerKeys[_currentSetIndex.toString()]?[qNum.toString()];
                final numOptions = (widget.exam.options > 0)
                    ? widget.exam.options
                    : 5;

                final score =
                    _scores[_currentSetIndex.toString()]?[qNum.toString()] ??
                    (double.tryParse(_globalScoreController.text) ?? 0.5);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Opacity(
                    opacity: isDisabled ? 0.5 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDisabled ? Colors.grey[100] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border, width: 1.5),
                        boxShadow: isDisabled ? [] : AppColors.softShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ข้อที่ $qNum',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDisabled
                                        ? AppColors.textSecondary
                                        : AppColors.textPrimary,
                                  ),
                                ),
                                if (_isCustomScore && !isDisabled)
                                  Row(
                                    children: [
                                      const Text(
                                        'คะแนน: ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 50,
                                        child: TextField(
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          textAlign: TextAlign.center,
                                          controller:
                                              TextEditingController(
                                                  text: score
                                                      .toString()
                                                      .replaceAll(
                                                        RegExp(
                                                          r'([.]*0)(?!.*\d)',
                                                        ),
                                                        '',
                                                      ),
                                                )
                                                ..selection =
                                                    TextSelection.collapsed(
                                                      offset: score
                                                          .toString()
                                                          .replaceAll(
                                                            RegExp(
                                                              r'([.]*0)(?!.*\d)',
                                                            ),
                                                            '',
                                                          )
                                                          .length,
                                                    ),
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  vertical: 4,
                                                  horizontal: 4,
                                                ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          onChanged: (val) {
                                            final parsed =
                                                double.tryParse(val) ?? 0.0;
                                            _scores[_currentSetIndex
                                                    .toString()]![qNum
                                                    .toString()] =
                                                parsed;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: List.generate(numOptions, (optIndex) {
                                final letter = String.fromCharCode(
                                  65 + optIndex,
                                );
                                final isChecked = selectedAnswer == letter;
                                return GestureDetector(
                                  onTap: isDisabled
                                      ? null
                                      : () {
                                          setState(() {
                                            if (!_answerKeys.containsKey(
                                              _currentSetIndex.toString(),
                                            )) {
                                              _answerKeys[_currentSetIndex
                                                      .toString()] =
                                                  {};
                                              _scores[_currentSetIndex
                                                      .toString()] =
                                                  {};
                                            }
                                            _answerKeys[_currentSetIndex
                                                    .toString()]![qNum
                                                    .toString()] =
                                                letter;

                                            if (!_scores[_currentSetIndex
                                                    .toString()]!
                                                .containsKey(qNum.toString())) {
                                              _scores[_currentSetIndex
                                                      .toString()]![qNum
                                                      .toString()] =
                                                  double.tryParse(
                                                    _globalScoreController.text,
                                                  ) ??
                                                  0.5;
                                            }
                                          });
                                        },
                                  child: Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isChecked
                                          ? AppColors.primary
                                          : (isDisabled
                                                ? Colors.grey[300]
                                                : Colors.white),
                                      border: Border.all(
                                        color: isChecked
                                            ? Colors.transparent
                                            : AppColors.border,
                                        width: 1.5,
                                      ),
                                      boxShadow: isChecked
                                          ? AppColors.primaryShadow
                                          : [],
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      letter,
                                      style: TextStyle(
                                        color: isChecked
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }, childCount: _sheetTypeCount),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}
