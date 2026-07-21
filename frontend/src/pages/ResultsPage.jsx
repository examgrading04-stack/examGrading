import { useState, useMemo, useEffect } from "react";
import {
  DataTable,
  Icon,
  Input,
  Select,
  GhostButton,
  PrimaryButton,
  Swal,
  Modal,
  Pagination,
  StatCard,
} from "../ui.jsx";

function getCorrectAnswer(exam, question) {
  if (!exam || !exam.answerKey || typeof exam.answerKey !== "object")
    return "-";
  if (exam.answerKey["0"] && typeof exam.answerKey["0"][question] === "string")
    return exam.answerKey["0"][question];
  if (exam.answerKey["1"] && typeof exam.answerKey["1"][question] === "string")
    return exam.answerKey["1"][question];
  if (typeof exam.answerKey[question] === "string")
    return exam.answerKey[question];
  const firstSet = Object.values(exam.answerKey).find(
    (v) => typeof v === "object",
  );
  if (firstSet && typeof firstSet[question] === "string")
    return firstSet[question];
  return "-";
}

export function ResultsPage({ data, api, refresh, query }) {
  const [selectedExamId, setSelectedExamId] = useState(query?.examId || "");
  const [selectedResult, setSelectedResult] = useState(null);
  const [searchResult, setSearchResult] = useState("");

  useEffect(() => {
    if (query?.examId) {
      setSelectedExamId(query.examId);
    }
  }, [query?.examId]);

  // Filter results based on selected exam
  const filteredResults = useMemo(() => {
    let list = data.results;
    if (selectedExamId) {
      list = list.filter((r) => r.examId === selectedExamId);
    }
    const finalMapped = list.map((row) => {
      const exam = data.exams.find((e) => e.id === row.examId);
      const student = data.students.find(
        (s) => s.id === row.studentId || s.code === row.studentCode,
      );
      const questionsCount = Number(exam?.questions || row.totalQuestions || 0);

      let dynamicScore = row.score || 0;

      // Recalculate score dynamically based on current answer key
      if (exam && (row.answers || row.itemResults)) {
        let calculatedScore = 0;
        for (let i = 1; i <= questionsCount; i++) {
          const qStr = String(i);
          const correctAns = getCorrectAnswer(exam, qStr);

          if (row.answers) {
            if (row.answers[qStr] === correctAns && correctAns !== "-") {
              calculatedScore++;
            }
          } else if (row.itemResults) {
            if (row.itemResults[qStr] === true) {
              calculatedScore++;
            }
          }
        }
        dynamicScore = calculatedScore;
      }

      const percentage = questionsCount
        ? (dynamicScore / questionsCount) * 100
        : 0;

      return {
        ...row,
        score: dynamicScore,
        totalQuestions: questionsCount,
        percentage,
        wrongCount: Math.max(questionsCount - dynamicScore, 0),
        examName: exam?.name || "",
        subject: exam?.subject || "",
        examSection:
          data.sections?.find((s) => String(s.id) === String(exam?.section))
            ?.sec ||
          exam?.section ||
          "",
        studentSec:
          data.sections?.find((s) => String(s.id) === String(student?.section))
            ?.sec ||
          student?.section ||
          "",
        studentName: student?.name || row.studentName || "",
        studentCode: student?.id || student?.code || row.studentCode || "",
      };
    });

    if (searchResult) {
      const keyword = searchResult.trim().toLowerCase();
      return finalMapped.filter((row) =>
        [row.studentName, row.studentCode]
          .filter(Boolean)
          .some((v) => String(v).toLowerCase().includes(keyword)),
      );
    }
    return finalMapped;
  }, [
    data.results,
    data.exams,
    data.students,
    data.sections,
    selectedExamId,
    searchResult,
  ]);

  // Summary Statistics
  const stats = useMemo(() => {
    if (filteredResults.length === 0) return null;
    const scores = filteredResults.map((r) => r.score);
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    const uniqueStudents = new Set(filteredResults.map(r => r.studentCode)).size;
    return {
      avg: avg.toFixed(1),
      count: filteredResults.length,
      uniqueStudents: uniqueStudents
    };
  }, [filteredResults]);

  const currentExam = data.exams.find((e) => e.id === selectedExamId);

  return (
    <div className="page-enter max-w-[1600px] mx-auto pb-20 px-4 space-y-6">
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between mb-2">
        <div className="flex-1 min-w-0 pr-4">
          <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl truncate">
            {currentExam ? (
              <div className="flex flex-col gap-1">
                <span className="text-xl sm:text-2xl text-slate-500">
                  ผลการตรวจคะแนน:
                </span>
                <div className="flex items-center gap-3 text-2xl sm:text-3xl">
                  <span>{currentExam.name}</span>
                  {currentExam.section && (
                    <span className="rounded-full bg-slate-100 px-3 py-1 text-sm font-black uppercase text-slate-600 border border-slate-200">
                      {currentExam.section === "All Section"
                        ? "All Section"
                        : data.sections?.find(
                            (s) => String(s.id) === String(currentExam.section),
                          )?.sec || currentExam.section}
                    </span>
                  )}
                </div>
              </div>
            ) : (
              "ผลการตรวจคะแนนทั้งหมด"
            )}
          </h2>
          <p className="mt-2 text-sm text-slate-500 truncate">
            {currentExam
              ? `รหัสวิชา ${currentExam.subject} · รายชื่อผู้เข้าสอบและผลคะแนนรายบุคคล`
              : "เลือกข้อสอบเพื่อดูรายละเอียดผลคะแนนแยกตามกลุ่มเรียน"}
          </p>
        </div>
        <div className="w-full sm:w-auto flex flex-col sm:flex-row items-start sm:items-end gap-3 print:hidden">
          <div className="w-full sm:w-56 max-w-full">
            <label className="mb-1.5 block text-xs font-bold text-slate-500 uppercase tracking-wider">
              ค้นหาผู้เรียน
            </label>
            <Input
              value={searchResult}
              onChange={(e) => setSearchResult(e.target.value)}
              placeholder="รหัส หรือ ชื่อ-สกุล..."
              className="bg-white"
            />
          </div>
          <div className="w-full sm:w-80">
            <label className="mb-1.5 block text-xs font-bold text-slate-500 uppercase tracking-wider">
              เลือกข้อสอบ
            </label>
            <Select
              value={selectedExamId}
              onChange={(e) => setSelectedExamId(e.target.value)}
              className="w-full bg-white text-slate-900 border-slate-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            >
              <option value="">ดูผลการตรวจคะแนนทั้งหมด</option>
              {data.exams.map((exam) => {
                const secName =
                  exam.section === "All Section" || !exam.section
                    ? "All Section"
                    : data.sections?.find(
                        (s) => String(s.id) === String(exam.section),
                      )?.sec || exam.section;
                return (
                  <option key={exam.id} value={exam.id}>
                    {exam.subject}{" "}
                    {secName !== "All Section" ? `(${secName})` : ""} -{" "}
                    {exam.name}
                  </option>
                );
              })}
            </Select>
          </div>
        </div>
      </div>

      {/* Stats Dashboard */}
      {stats && (
        <div className="grid grid-cols-2 gap-4">
          <StatCard
            title="จำนวนกระดาษคำตอบ"
            value={stats.count}
            icon="fa-file-lines"
            color="blue"
          />
          <StatCard
            title="จำนวนผู้เข้าสอบ"
            value={stats.uniqueStudents}
            icon="fa-users"
            color="indigo"
          />
        </div>
      )}

      {/* Main Table Section */}
      <section className="space-y-4 print:hidden">
        <DataTable
          columns={[
            {
              key: "studentName",
              label: "ผู้เรียน",
              render: (row) => (
                <div className="flex items-center gap-3 py-1">
                  <div className="flex flex-col">
                    <span className="font-extrabold text-slate-800 text-sm">
                      {row.studentName || "-"}
                    </span>
                    <span className="text-xs font-bold text-slate-500">
                      {row.studentCode || "-"}
                    </span>
                    <span className="text-[11px] font-medium text-slate-400 mt-0.5">
                      {row.examName || "-"}
                    </span>
                    <span className="text-[10px] font-medium text-slate-400">
                      {row.subject || "-"} {row.examSection && row.examSection !== "All Section" ? `(${row.examSection})` : ""}
                    </span>
                  </div>
                </div>
              ),
            },
            {
              key: "correctCount",
              label: "จำนวนข้อที่ถูก",
              render: (row) => (
                <span className="font-bold text-emerald-600">
                  {row.score}
                </span>
              ),
            },
            {
              key: "wrongCount",
              label: "จำนวนข้อที่ผิด",
              render: (row) => (
                <span className="font-bold text-rose-600">
                  {row.wrongCount}
                </span>
              ),
            },
            {
              key: "score",
              label: "คะแนน",
              render: (row) => (
                <div className="flex items-baseline gap-1 py-1">
                  <span className="text-xl font-black text-blue-600">
                    {row.score}
                  </span>
                  <span className="text-xs font-bold text-slate-400">
                    / {row.totalQuestions}
                  </span>
                </div>
              ),
            },
            {
              key: "percent",
              label: "ร้อยละ",
              render: (row) => (
                <div className="w-full max-w-[120px]">
                  <div className="flex justify-between text-[10px] font-black text-slate-400 mb-1">
                    <span>{row.percentage.toFixed(0)}%</span>
                  </div>
                  <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full bg-blue-500"
                      style={{ width: `${row.percentage}%` }}
                    />
                  </div>
                </div>
              ),
            },
            {
              key: "actions",
              label: "",
              render: (row) => (
                <div className="flex justify-end gap-2 pr-2">
                  <GhostButton
                    variant="primary"
                    className="p-2 rounded-md"
                    onClick={() => setSelectedResult(row)}
                    title="ดูรายละเอียดการตรวจ"
                  >
                    <Icon name="fa-magnifying-glass" />
                  </GhostButton>
                  <GhostButton
                    variant="danger"
                    className="p-2 rounded-md"
                    onClick={async () => {
                      Swal()
                        .fire({
                          title: "ลบผลการตรวจนี้?",
                          text: "ข้อมูลจะไม่สามารถกู้คืนได้",
                          icon: "warning",
                          showCancelButton: true,
                          confirmButtonColor: "#e11d48",
                        })
                        .then(async (res) => {
                          if (res.isConfirmed) {
                            await api.remove("results", row.id);
                            await refresh("ลบผลการตรวจแล้ว");
                          }
                        });
                    }}
                  >
                    <Icon name="fa-trash-can" />
                  </GhostButton>
                </div>
              ),
            },
          ]}
          rows={filteredResults}
          emptyText="ยังไม่มีผลการตรวจสำหรับรายการที่เลือก"
        />
      </section>

      {/* Print-only Table (shows all rows) */}
      <div className="hidden print:block mt-8">
        <h3 className="text-xl font-bold mb-4">รายละเอียดผลคะแนน</h3>
        <table className="w-full text-left border-collapse text-sm">
          <thead>
            <tr className="border-b-2 border-black">
              <th className="py-2 pr-4 font-bold">รหัสผู้เรียน</th>
              <th className="py-2 pr-4 font-bold">ชื่อ-นามสกุล</th>
              <th className="py-2 pr-4 font-bold">กลุ่มเรียน</th>
              <th className="py-2 pr-4 font-bold text-center">คะแนน</th>
              <th className="py-2 pr-4 font-bold text-center">ร้อยละ</th>
            </tr>
          </thead>
          <tbody>
            {filteredResults.map((r, i) => (
              <tr key={r.id} className="border-b border-gray-300">
                <td className="py-2 pr-4">{r.studentCode || "-"}</td>
                <td className="py-2 pr-4">{r.studentName || "-"}</td>
                <td className="py-2 pr-4">
                  {r.studentSec || r.examSection || "-"}
                </td>
                <td className="py-2 pr-4 text-center">
                  {r.score}/{r.totalQuestions}
                </td>
                <td className="py-2 pr-4 text-center">
                  {r.percentage.toFixed(0)}%
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <Modal
        isOpen={!!selectedResult}
        onClose={() => setSelectedResult(null)}
        title="รายละเอียดการตรวจ"
        maxWidth="max-w-4xl"
      >
        {selectedResult && (
          <StudentAnswersView
            result={
              filteredResults.find((r) => r.id === selectedResult.id) ||
              selectedResult
            }
            exam={data.exams.find((e) => e.id === selectedResult.examId)}
          />
        )}
      </Modal>
    </div>
  );
}

function StudentAnswersView({ result, exam }) {
  const [page, setPage] = useState(1);
  const pageSize = 10;
  if (!exam) return null;

  const questionsCount = Number(exam.questions || result.totalQuestions || 0);
  const rows = Array.from({ length: questionsCount }, (_, i) => {
    const questionStr = String(i + 1);
    const correctAns = getCorrectAnswer(exam, questionStr);
    let studentAns = "-";
    let isCorrect = false;
    let isSkipped = false;

    if (result.answers) {
      studentAns = result.answers[questionStr] || "-";
      if (studentAns === "-") {
        isSkipped = true;
      } else {
        isCorrect = studentAns === correctAns;
      }
    } else if (result.itemResults) {
      isCorrect = result.itemResults[questionStr] === true;
      studentAns = isCorrect
        ? correctAns
        : result.itemResults[questionStr] === false
          ? "X"
          : "-";
      if (studentAns === "-") isSkipped = true;
    }

    return {
      question: questionStr,
      studentAns,
      correctAns,
      isCorrect,
      isSkipped,
    };
  });

  const totalPages = Math.max(1, Math.ceil(rows.length / pageSize));
  const visibleRows = rows.slice((page - 1) * pageSize, page * pageSize);

  useEffect(() => {
    setPage(1);
  }, [result?.id, exam?.id, questionsCount]);

  useEffect(() => {
    setPage((current) => Math.min(current, totalPages));
  }, [totalPages]);

  return (
    <div className="space-y-8">
      {/* Header Profile & Score */}
      <div className="flex flex-col md:flex-row items-center justify-between bg-gradient-to-br from-blue-50 to-indigo-50/50 p-6 rounded-2xl border border-blue-100/60 shadow-sm gap-6">
        <div className="flex items-center gap-5 w-full md:w-auto">
          <div className="w-16 h-16 rounded-full bg-white shadow-sm flex items-center justify-center text-blue-600 border border-blue-100 shrink-0">
             <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8">
                <path fillRule="evenodd" d="M7.5 6a4.5 4.5 0 119 0 4.5 4.5 0 01-9 0zM3.751 20.105a8.25 8.25 0 0116.498 0 .75.75 0 01-.437.695A18.683 18.683 0 0112 22.5c-2.786 0-5.433-.608-7.812-1.7a.75.75 0 01-.437-.695z" clipRule="evenodd" />
             </svg>
          </div>
          <div>
            <p className="text-[11px] font-bold text-blue-600/70 mb-0.5 uppercase tracking-wider">ผู้เข้าสอบ</p>
            <h4 className="text-xl font-black text-slate-800">{result.studentName}</h4>
            <p className="text-sm font-bold text-slate-500">รหัส: <span className="text-slate-600">{result.studentCode}</span></p>
          </div>
        </div>
        <div className="text-center md:text-right bg-white px-6 py-4 rounded-xl shadow-sm border border-blue-100/50 w-full md:w-auto md:min-w-[160px]">
          <p className="text-[11px] font-bold text-slate-400 uppercase tracking-widest mb-1">คะแนนรวม</p>
          <p className="text-4xl font-black text-blue-600">
            {result.score} <span className="text-lg text-slate-400 font-bold">/ {questionsCount}</span>
          </p>
        </div>
      </div>

      {/* Answer Table */}
      <div>
        <h4 className="text-lg font-bold text-slate-800 mb-4 flex items-center gap-2">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 text-slate-400">
            <path fillRule="evenodd" d="M6 2a2 2 0 00-2 2v12a2 2 0 002 2h8a2 2 0 002-2V7.414A2 2 0 0015.414 6L12 2.586A2 2 0 0010.586 2H6zm5 6a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2h-2V8z" clipRule="evenodd" />
          </svg>
          รายละเอียดคำตอบ
        </h4>
        
        <div className="overflow-x-auto rounded-xl border border-slate-200 shadow-sm">
          <table className="w-full text-sm text-left">
            <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
              <tr>
                <th className="px-4 py-3.5">ข้อ</th>
                <th className="px-4 py-3.5 text-center">คำตอบที่เลือก</th>
                <th className="px-4 py-3.5 text-center">เฉลย</th>
                <th className="px-4 py-3.5 text-center">สถานะ</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100 bg-white">
              {visibleRows.map((row) => (
                <tr key={row.question} className="hover:bg-slate-50/70 transition-colors">
                  <td className="px-4 py-3 font-bold text-slate-700">
                    {row.question}
                  </td>
                  <td className="px-4 py-3 text-center font-bold text-slate-800">
                    {row.isSkipped ? (
                      <span className="text-slate-300">-</span>
                    ) : (
                      row.studentAns
                    )}
                  </td>
                  <td className="px-4 py-3 text-center font-bold text-emerald-600">
                    {row.correctAns}
                  </td>
                  <td className="px-4 py-3 text-center">
                    {row.isSkipped ? (
                      <span
                        className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-slate-100 text-slate-400"
                        title="ไม่ตอบ"
                      >
                        <Icon name="fa-minus" />
                      </span>
                    ) : row.isCorrect ? (
                      <span
                        className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-emerald-100 text-emerald-600"
                        title="ถูกต้อง"
                      >
                        <Icon name="fa-check" />
                      </span>
                    ) : (
                      <span
                        className="inline-flex items-center justify-center w-7 h-7 rounded-full bg-rose-100 text-rose-600"
                        title="ผิด"
                      >
                        <Icon name="fa-xmark" />
                      </span>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        
        {rows.length > 0 && (
          <div className="flex items-center justify-between gap-3 border border-slate-200 rounded-xl px-4 py-3 text-sm mt-3 bg-white shadow-sm">
            <span className="text-slate-500 font-medium">
              แสดง {(page - 1) * pageSize + 1}-
              {Math.min(page * pageSize, rows.length)} จาก {rows.length} รายการ
            </span>
            <Pagination
              count={totalPages}
              page={page}
              onChange={(_, value) => setPage(value)}
              variant="outlined"
              shape="rounded"
            />
          </div>
        )}
      </div>

      {/* Answer Image */}
      {result.imageUrl && (
        <div className="pt-6 border-t border-slate-100">
          <div className="flex items-center justify-between gap-3 mb-4">
            <h4 className="text-lg font-bold text-slate-800 flex items-center gap-2">
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-5 h-5 text-slate-400">
                <path fillRule="evenodd" d="M1 5.25A2.25 2.25 0 013.25 3h13.5A2.25 2.25 0 0119 5.25v9.5A2.25 2.25 0 0116.75 17H3.25A2.25 2.25 0 011 14.75v-9.5zm1.5 5.81v3.69c0 .414.336.75.75.75h13.5a.75.75 0 00.75-.75v-2.69l-2.22-2.219a2.25 2.25 0 00-3.182 0l-1.44 1.439-2.25-1.5a2.25 2.25 0 00-2.506.012L2.5 11.06z" clipRule="evenodd" />
              </svg>
              รูปกระดาษคำตอบที่สแกน
            </h4>
            <a
              href={result.imageUrl}
              target="_blank"
              rel="noreferrer"
              className="text-xs font-bold text-blue-600 hover:text-blue-700 bg-blue-50 hover:bg-blue-100 px-3 py-2 rounded-lg transition-colors flex items-center gap-1.5"
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
                <path d="M10 12.5a2.5 2.5 0 100-5 2.5 2.5 0 000 5z" />
                <path fillRule="evenodd" d="M.664 10.59a1.651 1.651 0 010-1.186A10.004 10.004 0 0110 3c4.257 0 7.874 2.62 9.336 6.41.147.381.146.804 0 1.186A10.004 10.004 0 0110 17c-4.257 0-7.874-2.62-9.336-6.41zM14 10a4 4 0 11-8 0 4 4 0 018 0z" clipRule="evenodd" />
              </svg>
              เปิดขนาดเต็ม
            </a>
          </div>
          <div className="bg-slate-50 p-6 rounded-2xl border border-slate-200 flex justify-center shadow-inner">
            <img
              src={result.imageUrl}
              alt="Scanned answer sheet"
              loading="lazy"
              className="max-h-[600px] object-contain rounded-xl shadow-md border border-slate-200 bg-white"
            />
          </div>
        </div>
      )}
    </div>
  );
}
