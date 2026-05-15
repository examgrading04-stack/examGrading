import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ResultsScreen extends StatelessWidget {
  const ResultsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 60,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF64748B),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'ประวัติการตรวจ',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF64748B), Color(0xFF475569)],
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
          StreamBuilder<QuerySnapshot>(
            stream: uid.isNotEmpty
                ? FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .collection('results')
                      .orderBy('timestamp', descending: true)
                      .snapshots()
                : const Stream.empty(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(
                    child: SpinKitCircle(color: Color(0xFF64748B), size: 50.0),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              final docs = snapshot.data!.docs;

              return SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final examId = data['examId'] ?? 'ไม่ระบุ';
                    final score =
                        data['score']?.toString() ?? 'กำลังประมวลผล...';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final dateString = timestamp != null
                        ? "${timestamp.toDate().day}/${timestamp.toDate().month}/${timestamp.toDate().year} ${timestamp.toDate().hour}:${timestamp.toDate().minute.toString().padLeft(2, '0')}"
                        : 'ไม่ทราบเวลา';

                    final isPending = data['score'] == null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPending
                                  ? [
                                      const Color(0xFFFDE68A),
                                      const Color(0xFFF59E0B),
                                    ]
                                  : [
                                      const Color(0xFF34D399),
                                      const Color(0xFF059669),
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    (isPending
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF059669))
                                        .withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              isPending
                                  ? FontAwesomeIcons.clockRotateLeft
                                  : FontAwesomeIcons.checkDouble,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        title: Text(
                          'ข้อสอบ: $examId',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'เวลา: $dateString',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12,
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isPending
                                ? const Color(0xFFFFFBEB)
                                : const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isPending
                                  ? const Color(0xFFFEF3C7)
                                  : const Color(0xFFDCFCE7),
                            ),
                          ),
                          child: Text(
                            isPending ? 'รอตรวจ' : '$score คะแนน',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isPending
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ),
                    );
                  }, childCount: docs.length),
                ),
              );
            },
          ),
        ],
      ),
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
              FontAwesomeIcons.folderOpen,
              size: 60,
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'ยังไม่มีประวัติการตรวจ',
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'เริ่มสแกนกระดาษคำตอบเพื่อดูผลลัพธ์',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
          ),
        ],
      ),
    );
  }
}
