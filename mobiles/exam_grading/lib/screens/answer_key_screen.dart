import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:quickalert/quickalert.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../models/exam_model.dart';

class AnswerKeyScreen extends StatefulWidget {
  final ExamModel exam;

  const AnswerKeyScreen({Key? key, required this.exam}) : super(key: key);

  @override
  State<AnswerKeyScreen> createState() => _AnswerKeyScreenState();
}

class _AnswerKeyScreenState extends State<AnswerKeyScreen> {
  final _uid = FirebaseAuth.instance.currentUser?.email ?? '';
  // Map<SetIndex, Map<QuestionNumber, AnswerLetter>>
  // e.g. { '0': { '1': 'A', '2': 'C' } }
  Map<String, Map<String, String>> _answerKeys = {};
  int _currentSetIndex = 0;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchAnswerKey();
  }

  Future<void> _fetchAnswerKey() async {
    if (_uid.isEmpty) return;
    try {
      final examRef = FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('exams')
          .doc(widget.exam.id);

      final examDoc = await examRef.get();
      final examData = examDoc.data();
      Map<String, Map<String, String>> answerKeys =
          Map<String, Map<String, String>>.from(widget.exam.answerKey);

      if (examData != null) {
        final rawAnswerKey = examData['answerKey'] ?? examData['answerKeys'];
        answerKeys = _parseAnswerKey(rawAnswerKey);
      }

      if (answerKeys.isEmpty) {
        final legacyDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('answerKeys')
            .doc(widget.exam.id)
            .get();

        final legacyData = legacyDoc.data();
        if (legacyDoc.exists && legacyData != null) {
          answerKeys = _parseAnswerKey(legacyData['data']);
          if (answerKeys.isNotEmpty) {
            await examRef.update({'answerKey': answerKeys});
          }
        }
      }

      if (answerKeys.isEmpty) {
        for (int i = 0; i < widget.exam.sets; i++) {
          answerKeys[i.toString()] = {};
        }
      }

      setState(() {
        _answerKeys = answerKeys;
      });
    } catch (e) {
      debugPrint('Error fetching answer keys: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAnswerKey() async {
    if (_uid.isEmpty) return;

    // Check if current set has all questions answered
    final currentSetData = _answerKeys[_currentSetIndex.toString()] ?? {};
    if (currentSetData.length < widget.exam.questions) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.warning,
        text:
            'กรุณากำหนดเฉลยให้ครบทุกข้อ (ชุด ${String.fromCharCode(65 + _currentSetIndex)})',
        confirmBtnColor: const Color(0xFFF59E0B),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_uid)
          .collection('exams')
          .doc(widget.exam.id)
          .set({
            'answerKey': _answerKeys,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      QuickAlert.show(
        context: context,
        type: QuickAlertType.success,
        text: 'บันทึกเฉลยสำเร็จ',
        confirmBtnColor: const Color(0xFFF59E0B),
      );
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'เกิดข้อผิดพลาด',
        text: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Map<String, Map<String, String>> _parseAnswerKey(dynamic raw) {
    if (raw is! Map) return {};

    return raw.map((setIndex, answers) {
      final answerMap = answers is Map ? answers : <dynamic, dynamic>{};
      return MapEntry(
        setIndex.toString(),
        answerMap.map(
          (question, answer) =>
              MapEntry(question.toString(), answer.toString()),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: SpinKitCircle(color: Color(0xFFF59E0B), size: 50.0),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFF59E0B),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'เฉลย: ${widget.exam.name}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
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
            actions: [
              if (_isSaving)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save, color: Colors.white),
                  onPressed: _saveAnswerKey,
                  tooltip: 'บันทึกเฉลย',
                ),
            ],
          ),

          if (widget.exam.sets > 1)
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: const Color(0xFFF1F5F9),
                      width: 2,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: List.generate(widget.exam.sets, (index) {
                      final setLetter = String.fromCharCode(65 + index);
                      final isSelected = _currentSetIndex == index;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: ChoiceChip(
                          label: Text('ชุด $setLetter'),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected)
                              setState(() => _currentSetIndex = index);
                          },
                          backgroundColor: const Color(0xFFF8FAFC),
                          selectedColor: const Color(0xFFFEF3C7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFFE2E8F0),
                              width: 1.5,
                            ),
                          ),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? const Color(0xFFD97706)
                                : const Color(0xFF64748B),
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),

          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final qNum = index + 1;
                final selectedAnswer =
                    _answerKeys[_currentSetIndex.toString()]?[qNum.toString()];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$qNum',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: List.generate(widget.exam.options, (
                              optIndex,
                            ) {
                              final letter = String.fromCharCode(65 + optIndex);
                              final isChecked = selectedAnswer == letter;
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (!_answerKeys.containsKey(
                                      _currentSetIndex.toString(),
                                    )) {
                                      _answerKeys[_currentSetIndex.toString()] =
                                          {};
                                    }
                                    _answerKeys[_currentSetIndex
                                            .toString()]![qNum.toString()] =
                                        letter;
                                  });
                                },
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isChecked
                                        ? const LinearGradient(
                                            colors: [
                                              Color(0xFFF59E0B),
                                              Color(0xFFD97706),
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          )
                                        : null,
                                    color: isChecked ? null : Colors.white,
                                    border: Border.all(
                                      color: isChecked
                                          ? Colors.transparent
                                          : const Color(0xFFE2E8F0),
                                      width: 2,
                                    ),
                                    boxShadow: isChecked
                                        ? [
                                            BoxShadow(
                                              color: const Color(
                                                0xFFF59E0B,
                                              ).withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      color: isChecked
                                          ? Colors.white
                                          : const Color(0xFF64748B),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }, childCount: widget.exam.questions),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }
}
