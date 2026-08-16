import { useState, useMemo, useEffect, useRef } from "react";
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
  if (!exam || !exam.answerKey) return "-";
  
  let ak = exam.answerKey;
  if (typeof ak === "string") {
    try { ak = JSON.parse(ak); } catch (e) { return "-"; }
  }
  if (typeof ak !== "object" || ak === null) return "-";

  if (ak[question] && typeof ak[question] === "object" && ak[question].answer !== undefined) {
    return String(ak[question].answer);
  }
  if (typeof ak[question] === "string" || typeof ak[question] === "number") {
    return String(ak[question]);
  }

  for (const setKey of ["0", "1", "A", "B", ""]) {
    if (ak[setKey] && typeof ak[setKey] === "object") {
      if (typeof ak[setKey][question] === "string" || typeof ak[setKey][question] === "number") return String(ak[setKey][question]);
      if (ak[setKey][question] && typeof ak[setKey][question] === "object" && ak[setKey][question].answer !== undefined) {
        return String(ak[setKey][question].answer);
      }
    }
  }

  const firstSet = Object.values(ak).find((v) => typeof v === "object" && v !== null && Object.keys(v).some(k => !isNaN(Number(k))));
  if (firstSet) {
    if (typeof firstSet[question] === "string" || typeof firstSet[question] === "number") return String(firstSet[question]);
    if (firstSet[question] && typeof firstSet[question] === "object" && firstSet[question].answer !== undefined) {
      return String(firstSet[question].answer);
    }
  }
  return "-";
}

function getQuestionScore(exam, question) {
  if (!exam || !exam.answerKey) return 1.0;
  
  let ak = exam.answerKey;
  if (typeof ak === "string") {
    try { ak = JSON.parse(ak); } catch (e) { return 1.0; }
  }
  if (typeof ak !== "object" || ak === null) return 1.0;

  if (ak[question] && typeof ak[question] === "object" && ak[question].score !== undefined) {
    return Number(ak[question].score) || 1.0;
  }

  for (const setKey of ["0", "1", "A", "B", ""]) {
    if (ak[setKey] && typeof ak[setKey] === "object") {
      if (ak[setKey][question] && typeof ak[setKey][question] === "object" && ak[setKey][question].score !== undefined) {
        return Number(ak[setKey][question].score) || 1.0;
      }
    }
  }

  const firstSet = Object.values(ak).find((v) => typeof v === "object" && v !== null && Object.keys(v).some(k => !isNaN(Number(k))));
  if (firstSet && firstSet[question] && typeof firstSet[question] === "object" && firstSet[question].score !== undefined) {
    return Number(firstSet[question].score) || 1.0;
  }
  return 1.0;
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

      // Recalculate score dynamically based on current answer key
      let dynamicScore = row.score || 0;
      let totalMaxScore = questionsCount;

      if (exam && (row.answers || row.itemResults)) {
        let calculatedScore = 0;
        let calculatedMax = 0;
        for (let i = 1; i <= questionsCount; i++) {
          const qStr = String(i);
          const correctAns = getCorrectAnswer(exam, qStr);
          const qScore = getQuestionScore(exam, qStr);
          calculatedMax += qScore;

          if (row.answers) {
            if (row.answers[qStr] === correctAns && correctAns !== "-") {
              calculatedScore += qScore;
            } else if (row.total && i > Number(row.total)) {
              calculatedScore += qScore;
            }
          } else if (row.itemResults) {
            if (row.itemResults[qStr] === true) {
              calculatedScore += qScore;
            } else if (row.total && i > Number(row.total)) {
              calculatedScore += qScore;
            }
          }
        }
        dynamicScore = calculatedScore;
        totalMaxScore = calculatedMax;
      } else if (row.total) {
        totalMaxScore = row.total;
      }

      const percentage = totalMaxScore
        ? (dynamicScore / totalMaxScore) * 100
        : 0;

      return {
        ...row,
        score: dynamicScore,
        totalQuestions: totalMaxScore,
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
    const uniqueStudents = new Set(filteredResults.map((r) => r.studentCode))
      .size;
    const flaggedCount = filteredResults.filter((r) => r.flagged).length;
    return {
      avg: avg.toFixed(1),
      count: filteredResults.length,
      uniqueStudents: uniqueStudents,
      flaggedCount,
    };
  }, [filteredResults]);

  const currentExam = data.exams.find((e) => e.id === selectedExamId);

  return (
    <div className="page-enter max-w-[1600px] mx-auto pb-20 px-4 space-y-6">
      <div className="flex flex-col gap-4 mb-2">
        <div className="flex-1 min-w-0 pr-4">
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight truncate">
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
      </div>

      {/* Stats Dashboard */}
      {stats && (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
          <StatCard
            title="จำนวนกระดาษคำตอบ"
            value={stats.count}
            icon="fa-file-lines"
            color="violet"
          />
          <StatCard
            title="จำนวนผู้เข้าสอบ"
            value={stats.uniqueStudents}
            icon="fa-users"
            color="indigo"
          />
          <StatCard
            title="รอตรวจสอบ (Flagged)"
            value={stats.flaggedCount}
            icon="fa-flag"
            color="amber"
          />
        </div>
      )}

      {/* Search and Filter */}
      <div className="w-full flex flex-col sm:flex-row items-start sm:items-end gap-3 print:hidden">
        <div className="w-full sm:w-56 max-w-full">
          <Input
            value={searchResult}
            onChange={(e) => setSearchResult(e.target.value)}
            placeholder="รหัส หรือ ชื่อ-สกุล..."
            className="bg-white"
          />
        </div>
        <div className="w-full sm:w-80">
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

      {/* Main Table Section */}
      <section className="space-y-4 print:hidden">
        <DataTable
          columns={[
            {
              key: "studentName",
              label: "ผู้สอบ",
              className: "w-[180px] sm:w-[220px] md:w-[280px] text-left",
              render: (row) => (
                <div className="flex items-center gap-3 py-1">
                  <div className="flex flex-col">
                    <span className="font-bold text-slate-800 text-base">
                      {row.studentName || "-"}
                    </span>
                    <span className="text-sm font-medium text-slate-500 mt-0.5">
                      {row.studentCode || "-"}
                    </span>
                    <span className="text-xs font-normal text-slate-400 mt-1">
                      {row.examName || "-"}
                    </span>
                    <span className="text-[11px] font-normal text-slate-400">
                      {row.subject || "-"}{" "}
                      {row.examSection && row.examSection !== "All Section"
                        ? `(${row.examSection})`
                        : ""}
                    </span>
                  </div>
                </div>
              ),
            },
            {
              key: "correctCount",
              label: "ข้อที่ถูก",
              className: "w-[100px] sm:w-[120px] text-center",
              render: (row) => (
                <span className="font-semibold text-emerald-600 text-base">
                  {row.score}
                </span>
              ),
            },
            {
              key: "wrongCount",
              label: "ข้อที่ผิด",
              className: "w-[100px] sm:w-[120px] text-center",
              render: (row) => (
                <span className="font-semibold text-rose-600 text-base">
                  {row.wrongCount}
                </span>
              ),
            },
            {
              key: "score",
              label: "คะแนนเต็ม",
              className: "w-[100px] sm:w-[120px] text-center",
              render: (row) => (
                <div className="flex items-baseline justify-center gap-1.5 py-1">
                  <span className="text-xl font-bold text-blue-600">
                    {row.score}
                  </span>
                  <span className="text-sm font-medium text-slate-400">
                    / {row.totalQuestions}
                  </span>
                </div>
              ),
            },
            {
              key: "percent",
              label: "ร้อยละ",
              className: "text-center",
              render: (row) => (
                <div className="w-full max-w-[120px] mx-auto text-center">
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
              key: "flagged",
              label: "สถานะ",
              className: "w-[110px] sm:w-[140px] text-center",
              render: (row) =>
                row.flagged ? (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-amber-100 text-amber-800 text-xs font-bold rounded-md">
                    <Icon name="fa-triangle-exclamation" /> รอตรวจสอบ
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-1 bg-emerald-100 text-emerald-700 text-xs font-bold rounded-md">
                    <Icon name="fa-check" /> สมบูรณ์
                  </span>
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
        <h3 className="text-xl font-bold text-slate-900 tracking-tight mb-4">
          รายละเอียดผลคะแนน
        </h3>
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
  const [zoom, setZoom] = useState(1);
  const imgContainerRef = useRef(null);
  const [isDragging, setIsDragging] = useState(false);
  const [startX, setStartX] = useState(0);
  const [startY, setStartY] = useState(0);
  const [scrollLeft, setScrollLeft] = useState(0);
  const [scrollTop, setScrollTop] = useState(0);

  const handleMouseDown = (e) => {
    if (!imgContainerRef.current) return;
    setIsDragging(true);
    setStartX(e.pageX - imgContainerRef.current.offsetLeft);
    setStartY(e.pageY - imgContainerRef.current.offsetTop);
    setScrollLeft(imgContainerRef.current.scrollLeft);
    setScrollTop(imgContainerRef.current.scrollTop);
  };

  const handleMouseLeave = () => setIsDragging(false);
  const handleMouseUp = () => setIsDragging(false);

  const handleMouseMove = (e) => {
    if (!isDragging || !imgContainerRef.current) return;
    e.preventDefault();
    const x = e.pageX - imgContainerRef.current.offsetLeft;
    const y = e.pageY - imgContainerRef.current.offsetTop;
    const walkX = (x - startX) * 1.5;
    const walkY = (y - startY) * 1.5;
    imgContainerRef.current.scrollLeft = scrollLeft - walkX;
    imgContainerRef.current.scrollTop = scrollTop - walkY;
  };

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

  const flaggedReasons = [];
  if (result.flagged) {
    const skippedQs = rows.filter((r) => r.isSkipped).map((r) => r.question);
    const multiQs = rows
      .filter(
        (r) => r.studentAns && r.studentAns !== "-" && r.studentAns.length > 1,
      )
      .map((r) => r.question);

    if (skippedQs.length > 0) {
      flaggedReasons.push(`พบข้อที่ไม่ได้ฝนคำตอบ: ข้อ ${skippedQs.join(", ")}`);
    }
    if (multiQs.length > 0) {
      flaggedReasons.push(
        `พบข้อที่ฝนมากกว่า 1 ตัวเลือก: ข้อ ${multiQs.join(", ")}`,
      );
    }
    if (flaggedReasons.length === 0) {
      flaggedReasons.push(
        "ความมั่นใจในการอ่านจุดฝนต่ำ (อาจฝนจางหรือลบไม่สะอาด)",
      );
    }
  }

  useEffect(() => {
    setPage(1);
  }, [result?.id, exam?.id, questionsCount]);

  useEffect(() => {
    setPage((current) => Math.min(current, totalPages));
  }, [totalPages]);

  return (
    <div className="space-y-8">
      {/* Header Profile & Score */}
      <div className="flex flex-col md:flex-row items-center justify-between bg-white p-5 rounded-lg border border-slate-200 gap-6">
        <div className="flex items-center gap-4 w-full md:w-auto">
          <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 shrink-0">
            <Icon name="fa-user" className="text-xl" />
          </div>
          <div>
            <h4 className="text-lg font-bold text-slate-800">
              {result.studentName}
            </h4>
            <p className="text-sm text-slate-500 mt-0.5">
              รหัสผู้เรียน:{" "}
              <span className="font-medium text-slate-700">
                {result.studentCode}
              </span>
            </p>
          </div>
        </div>
        <div className="text-center md:text-right w-full md:w-auto md:border-l border-slate-100 md:pl-6">
          <p className="text-xs font-medium text-slate-500 mb-0.5">
            คะแนนที่ได้
          </p>
          <div className="text-3xl font-bold text-blue-600">
            {result.score}{" "}
            <span className="text-lg text-slate-400 font-normal">
              / {questionsCount}
            </span>
          </div>
        </div>
      </div>

      {result.flagged && (
        <div className="bg-amber-100/50 text-amber-800 rounded-lg p-4 text-base flex flex-col gap-1.5 border border-amber-200/50">
          <div className="flex items-center gap-2 font-bold">
            <Icon name="fa-triangle-exclamation" className="text-lg" />
            <span>รอตรวจสอบความถูกต้อง</span>
          </div>
          <ul className="list-disc list-inside pl-1 text-amber-700/90 text-sm space-y-0.5 font-medium">
            {flaggedReasons.map((reason, idx) => (
              <li key={idx}>{reason}</li>
            ))}
          </ul>
        </div>
      )}

      {/* Answer Table */}
      <div>
        <h4 className="text-base font-bold text-slate-800 mb-3 flex items-center gap-2">
          <Icon name="fa-list-check" className="text-slate-400" />
          รายละเอียดคำตอบ
        </h4>

        <div className="overflow-x-auto rounded-lg border border-slate-200">
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
                <tr
                  key={row.question}
                  className="hover:bg-slate-50/70 transition-colors"
                >
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
          <div className="flex items-center justify-between gap-3 border border-slate-200 rounded-lg px-4 py-3 text-sm mt-3 bg-slate-50">
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
          <div className="flex items-center justify-between gap-3 mb-3">
            <h4 className="text-base font-bold text-slate-800 flex items-center gap-2">
              <Icon name="fa-image" className="text-slate-400" />
              รูปกระดาษคำตอบที่สแกน
            </h4>
            <div className="flex items-center gap-3">
              <div className="flex items-center bg-slate-100 rounded-lg border border-slate-200">
                <button
                  onClick={() => setZoom((z) => Math.max(0.5, z - 0.25))}
                  className="p-1 px-2.5 hover:bg-slate-200 text-slate-600 transition-colors rounded-l-lg"
                  title="ย่อ"
                >
                  <Icon name="fa-minus" className="text-xs" />
                </button>
                <span className="text-xs font-semibold px-2 w-[50px] text-center">
                  {Math.round(zoom * 100)}%
                </span>
                <button
                  onClick={() => setZoom((z) => Math.min(3, z + 0.25))}
                  className="p-1 px-2.5 hover:bg-slate-200 text-slate-600 transition-colors"
                  title="ขยาย"
                >
                  <Icon name="fa-plus" className="text-xs" />
                </button>
                <button
                  onClick={() => setZoom(1)}
                  className="p-1 px-2.5 hover:bg-slate-200 text-slate-600 transition-colors border-l border-slate-300 rounded-r-lg"
                  title="คืนค่าเดิม"
                >
                  <Icon name="fa-rotate-right" className="text-xs" />
                </button>
              </div>
              <a
                href={result.imageUrl}
                target="_blank"
                rel="noreferrer"
                className="text-xs font-semibold text-slate-600 hover:text-slate-800 bg-slate-100 hover:bg-slate-200 px-3 py-1.5 rounded-md transition-colors flex items-center gap-1.5"
              >
                <Icon
                  name="fa-arrow-up-right-from-square"
                  className="text-[10px]"
                />
                เปิดขนาดเต็ม
              </a>
            </div>
          </div>
          <div
            ref={imgContainerRef}
            onMouseDown={handleMouseDown}
            onMouseLeave={handleMouseLeave}
            onMouseUp={handleMouseUp}
            onMouseMove={handleMouseMove}
            className={`bg-slate-50 p-6 rounded-2xl border border-slate-200 shadow-inner overflow-auto max-h-[700px] text-center relative ${isDragging ? "cursor-grabbing" : "cursor-grab"}`}
          >
            <img
              src={result.imageUrl}
              alt="Scanned answer sheet"
              loading="lazy"
              draggable="false"
              style={{
                height: `${zoom * 600}px`,
                transition: isDragging ? "none" : "height 0.2s ease-out",
              }}
              className="object-contain shadow-md border border-slate-200 bg-white inline-block pointer-events-none"
            />
          </div>
        </div>
      )}
    </div>
  );
}
