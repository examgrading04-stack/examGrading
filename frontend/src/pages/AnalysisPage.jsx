import { useRef, useState, useMemo, useEffect } from "react";
import { DataTable, Select, StatCard, useChart, Modal } from "../ui.jsx";

function itemLabel(value, type) {
  if (type === "difficulty") {
    if (value >= 0.8) return "ง่ายเกินไป";
    if (value >= 0.4) return "เหมาะสม";
    return "ยากเกินไป";
  }
  if (value >= 0.4) return "ดีมาก";
  if (value >= 0.2) return "พอใช้";
  return "ไม่ดี";
}

function itemTone(value, type) {
  if (type === "difficulty") {
    if (value >= 0.8) return "text-rose-700 bg-rose-50 border-rose-100";
    if (value >= 0.4)
      return "text-emerald-700 bg-emerald-50 border-emerald-100";
    return "text-rose-700 bg-rose-50 border-rose-100";
  }
  if (value >= 0.4) return "text-emerald-700 bg-emerald-50 border-emerald-100";
  if (value >= 0.2) return "text-amber-700 bg-amber-50 border-amber-100";
  return "text-rose-700 bg-rose-50 border-rose-100";
}

function isPendingReview(result, exam) {
  if (!result) return true;

  // 1. Check flagged property
  const flagged = result.flagged;
  if (flagged === true || flagged === "true") return true;
  if (Array.isArray(flagged) && flagged.length > 0) return true;
  if (typeof flagged === "string" && flagged.trim()) {
    const norm = flagged.trim().toLowerCase();
    if (
      ["true", "pending", "flagged", "needs_review", "review"].includes(norm)
    ) {
      return true;
    }
    try {
      const parsed = JSON.parse(flagged);
      if (Array.isArray(parsed) && parsed.length > 0) return true;
      if (parsed === true) return true;
    } catch {}
  }

  // 2. Check status property
  if (
    result.status &&
    [
      "needs_review",
      "pending",
      "flagged",
      "error",
      "waiting",
      "review",
    ].includes(String(result.status).toLowerCase())
  ) {
    return true;
  }

  // 3. Must have answers or itemResults
  if (!result.answers && !result.itemResults) return true;

  // 4. Check questions and answers completeness
  const totalQ = Number(
    exam?.questions || result.totalQuestions || result.total || 0,
  );
  if (result.answers && totalQ > 0) {
    for (let i = 1; i <= totalQ; i++) {
      const answer = result.answers[String(i)];
      if (answer === undefined || answer === null) return true;

      const answerText = String(answer).trim();
      if (
        answerText === "" ||
        answerText === "-" ||
        answerText === "ฝนมากกว่า 1 ตัวเลือก" ||
        answerText.includes(",") ||
        answerText.length > 1
      ) {
        return true;
      }
    }
  }

  return false;
}

function getCorrectAnswer(exam, question) {
  if (!exam || !exam.answerKey) return "-";

  let ak = exam.answerKey;
  if (typeof ak === "string") {
    try {
      ak = JSON.parse(ak);
    } catch (e) {
      return "-";
    }
  }
  if (typeof ak !== "object" || ak === null) return "-";

  if (
    ak[question] &&
    typeof ak[question] === "object" &&
    ak[question].answer !== undefined
  ) {
    return String(ak[question].answer);
  }
  if (typeof ak[question] === "string" || typeof ak[question] === "number") {
    return String(ak[question]);
  }

  for (const setKey of ["0", "1", "A", "B", ""]) {
    if (ak[setKey] && typeof ak[setKey] === "object") {
      if (
        typeof ak[setKey][question] === "string" ||
        typeof ak[setKey][question] === "number"
      )
        return String(ak[setKey][question]);
      if (
        ak[setKey][question] &&
        typeof ak[setKey][question] === "object" &&
        ak[setKey][question].answer !== undefined
      ) {
        return String(ak[setKey][question].answer);
      }
    }
  }

  const firstSet = Object.values(ak).find(
    (v) =>
      typeof v === "object" &&
      v !== null &&
      Object.keys(v).some((k) => !isNaN(Number(k))),
  );
  if (firstSet) {
    if (
      typeof firstSet[question] === "string" ||
      typeof firstSet[question] === "number"
    )
      return String(firstSet[question]);
    if (
      firstSet[question] &&
      typeof firstSet[question] === "object" &&
      firstSet[question].answer !== undefined
    ) {
      return String(firstSet[question].answer);
    }
  }
  return "-";
}

function getQuestionScore(exam, question) {
  if (!exam || !exam.answerKey) return 1.0;

  let ak = exam.answerKey;
  if (typeof ak === "string") {
    try {
      ak = JSON.parse(ak);
    } catch (e) {
      return 1.0;
    }
  }
  if (typeof ak !== "object" || ak === null) return 1.0;

  if (
    ak[question] &&
    typeof ak[question] === "object" &&
    ak[question].score !== undefined
  ) {
    return Number(ak[question].score) || 1.0;
  }

  for (const setKey of ["0", "1", "A", "B", ""]) {
    if (ak[setKey] && typeof ak[setKey] === "object") {
      if (
        ak[setKey][question] &&
        typeof ak[setKey][question] === "object" &&
        ak[setKey][question].score !== undefined
      ) {
        return Number(ak[setKey][question].score) || 1.0;
      }
    }
  }

  const firstSet = Object.values(ak).find(
    (v) =>
      typeof v === "object" &&
      v !== null &&
      Object.keys(v).some((k) => !isNaN(Number(k))),
  );
  if (
    firstSet &&
    firstSet[question] &&
    typeof firstSet[question] === "object" &&
    firstSet[question].score !== undefined
  ) {
    return Number(firstSet[question].score) || 1.0;
  }
  return 1.0;
}

// Fix: handle tied scores at group boundary
function splitGroups(sorted, groupSize) {
  const upper = [];
  const lower = [];
  const upperCutScore = sorted[groupSize - 1]?.score;
  const lowerCutScore = sorted[sorted.length - groupSize]?.score;
  for (const r of sorted) {
    const s = Number(r.score || 0);
    if (s >= upperCutScore && upper.length < groupSize) upper.push(r);
  }
  for (let i = sorted.length - 1; i >= 0; i--) {
    const s = Number(sorted[i].score || 0);
    if (s <= lowerCutScore && lower.length < groupSize) lower.push(sorted[i]);
  }
  return { upper, lower };
}

function calculateItemAnalysis(results, exam) {
  const validResults = (results || []).filter((r) => !isPendingReview(r, exam));
  if (!exam || !validResults.length) return [];
  const sorted = [...validResults].sort(
    (a, b) => Number(b.score || 0) - Number(a.score || 0),
  );
  const groupSize = Math.max(1, Math.ceil(sorted.length * 0.27));
  const { upper: upperGroup, lower: lowerGroup } = splitGroups(
    sorted,
    groupSize,
  );

  return Array.from({ length: Number(exam.questions || 0) }, (_, index) => {
    const question = String(index + 1);
    const isCorrect = (result) => result.itemResults?.[question] === true;
    const correctCount = validResults.filter(isCorrect).length;
    const upperCorrectCount = upperGroup.filter(isCorrect).length;
    const lowerCorrectCount = lowerGroup.filter(isCorrect).length;
    const upperCorrect =
      upperGroup.length > 0 ? upperCorrectCount / upperGroup.length : 0;
    const lowerCorrect =
      lowerGroup.length > 0 ? lowerCorrectCount / lowerGroup.length : 0;
    const difficulty =
      validResults.length > 0 ? correctCount / validResults.length : 0;
    const discrimination = upperCorrect - lowerCorrect;

    const answer = getCorrectAnswer(exam, question);

    return {
      id: question,
      question,
      answer,
      correctCount,
      difficulty,
      discrimination,
      upperCorrect,
      lowerCorrect,
      upperCorrectCount,
      upperGroupLength: upperGroup.length,
      lowerCorrectCount,
      lowerGroupLength: lowerGroup.length,
      difficultyLabel: itemLabel(difficulty, "difficulty"),
      discriminationLabel: itemLabel(discrimination, "discrimination"),
    };
  });
}

function QuestionDetailModal({
  isOpen,
  onClose,
  detail,
  results,
  students,
  exam,
}) {
  const [searchTerm, setSearchTerm] = useState("");
  const [currentPage, setCurrentPage] = useState(1);
  const itemsPerPage = 10;

  const validResults = useMemo(() => {
    return (results || []).filter((r) => !isPendingReview(r, exam));
  }, [results, exam]);

  const studentResponses = useMemo(() => {
    if (!detail || !validResults.length) return [];

    const sorted = [...validResults].sort(
      (a, b) => Number(b.score || 0) - Number(a.score || 0),
    );
    const groupSize = Math.max(1, Math.ceil(sorted.length * 0.27));
    const upperThreshold = sorted[groupSize - 1]?.score ?? Infinity;
    const lowerThreshold =
      sorted[sorted.length - groupSize]?.score ?? -Infinity;

    return validResults
      .map((result) => {
        const hasId = result.studentId != null && result.studentId !== "";
        const hasCode = result.studentCode != null && result.studentCode !== "";
        const student =
          students.find(
            (s) =>
              (hasId && String(s.id) === String(result.studentId)) ||
              (hasCode && String(s.code) === String(result.studentCode)),
          ) || {};
        const answer = result.answers ? result.answers[detail.question] : "-";
        const isCorrect = result.itemResults
          ? result.itemResults[detail.question] === true
          : false;

        let group = "กลุ่มกลาง";
        let groupColor = "text-slate-500 bg-slate-50 border-slate-200";
        if (Number(result.score || 0) >= upperThreshold && groupSize > 0) {
          group = "กลุ่มได้คะแนนสูง";
          groupColor = "text-emerald-700 bg-emerald-50 border-emerald-200";
        } else if (
          Number(result.score || 0) <= lowerThreshold &&
          groupSize > 0
        ) {
          group = "กลุ่มได้คะแนนต่ำ";
          groupColor = "text-rose-700 bg-rose-50 border-rose-200";
        }

        return {
          studentId: result.studentId || result.studentCode || "-",
          name:
            `${student.firstName || ""} ${student.lastName || ""}`.trim() ||
            student.name ||
            result.studentName ||
            "ไม่ระบุชื่อ",
          answer: answer || "-",
          isCorrect,
          group,
          groupColor,
          score: result.score,
        };
      })
      .sort((a, b) => b.score - a.score);
  }, [detail, validResults, students]);

  const totalValid = validResults.length;

  const filteredResponses = useMemo(() => {
    if (!searchTerm) return studentResponses;
    return studentResponses.filter(
      (s) =>
        s.studentId.includes(searchTerm) ||
        s.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
        s.group.includes(searchTerm),
    );
  }, [studentResponses, searchTerm]);

  const totalPages = Math.ceil(filteredResponses.length / itemsPerPage);
  const currentResponses = filteredResponses.slice(
    (currentPage - 1) * itemsPerPage,
    (currentPage - 1) * itemsPerPage + itemsPerPage,
  );

  useEffect(() => {
    setCurrentPage(1);
  }, [searchTerm]);

  if (!detail) return null;

  const getRecommendation = (p, D) => {
    if (D < 0)
      return {
        text: "ข้อสอบมีความผิดปกติ (D ติดลบ) กลุ่มที่ได้คะแนนต่ำตอบถูกมากกว่ากลุ่มที่ได้คะแนนสูง อาจเกิดจากการเฉลยผิด หรือโจทย์กำกวมจนทำให้ผู้ที่รู้ลึกสับสน ควรตรวจสอบโจทย์และตัวเลือกใหม่โดยด่วน",
        type: "danger",
      };
    if (D < 0.2) {
      if (p > 0.8)
        return {
          text: "ข้อสอบง่ายเกินไปและไม่สามารถจำแนกผู้เรียนได้ ควรปรับตัวเลือกหลอกให้ท้าทายขึ้น หรือปรับคำถามให้ต้องใช้การวิเคราะห์มากขึ้น",
          type: "warning",
        };
      if (p < 0.4)
        return {
          text: "ข้อสอบยากเกินไปและไม่สามารถจำแนกผู้เรียนได้ อาจเกิดจากเนื้อหาที่ยังไม่ได้สอน หรือคำถามซับซ้อนเกินไป ควรทบทวนและปรับปรุง",
          type: "warning",
        };
      return {
        text: "ข้อสอบมีระดับความยากปานกลาง แต่จำแนกผู้เรียนได้ไม่ดีนัก ควรพิจารณาปรับปรุงตัวเลือกหลอกให้สามารถดึงดูดกลุ่มที่ยังไม่เข้าใจเนื้อหามากขึ้น",
        type: "warning",
      };
    }
    if (p > 0.8)
      return {
        text: "ข้อสอบง่าย แต่ยังพอจำแนกผู้เรียนได้บ้าง สามารถเก็บไว้ใช้เป็นข้อสอบพื้นฐานเพื่อแจกคะแนนความรู้พื้นฐานได้",
        type: "success",
      };
    if (p < 0.4)
      return {
        text: "ข้อสอบยากแต่แยกกลุ่มที่ได้คะแนนสูงและต่ำได้ดีเยี่ยม เหมาะสำหรับใช้เป็นข้อสอบคัดเลือกหรือตัดเกรด",
        type: "success",
      };
    return {
      text: "ข้อสอบยอดเยี่ยม มีความยากง่ายเหมาะสมและจำแนกผู้เรียนได้ดีมาก ควรเก็บไว้ในคลังข้อสอบ",
      type: "success",
    };
  };

  const rec = getRecommendation(detail.difficulty, detail.discrimination);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`รายละเอียดการวิเคราะห์ข้อ ${detail.question} (เฉลย: ${detail.answer})`}
      maxWidth="max-w-4xl"
    >
      <div className="space-y-6">
        <div
          className={`p-4 rounded-xl border flex items-start gap-3 ${
            rec.type === "danger"
              ? "bg-rose-50 border-rose-200 text-rose-800"
              : rec.type === "warning"
                ? "bg-amber-50 border-amber-200 text-amber-800"
                : "bg-emerald-50 border-emerald-200 text-emerald-800"
          }`}
        >
          <div
            className={`mt-0.5 flex shrink-0 items-center justify-center w-6 h-6 rounded-full ${
              rec.type === "danger"
                ? "bg-rose-100 text-rose-600"
                : rec.type === "warning"
                  ? "bg-amber-100 text-amber-600"
                  : "bg-emerald-100 text-emerald-600"
            }`}
          >
            <i
              className={`fa-solid ${
                rec.type === "danger"
                  ? "fa-triangle-exclamation"
                  : rec.type === "warning"
                    ? "fa-circle-exclamation"
                    : "fa-lightbulb"
              }`}
            />
          </div>
          <div>
            <h4 className="font-bold mb-1">คำแนะนำสำหรับอาจารย์:</h4>
            <p className="text-sm leading-relaxed">{rec.text}</p>
          </div>
        </div>

        <div>
          <h4 className="font-bold text-slate-800 mb-3 text-sm uppercase tracking-wider">
            วิธีการคำนวณ
          </h4>
          <div className="grid grid-cols-1 lg:grid-cols-5 gap-4">
            {/* p value */}
            <div className="lg:col-span-2 p-5 rounded-xl border border-slate-200 bg-white flex flex-col justify-center">
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 rounded bg-blue-50 text-blue-600 flex items-center justify-center font-black text-sm border border-blue-100">
                  p
                </div>
                <h4 className="font-bold text-slate-700 text-sm">
                  ค่าความยากง่าย (Difficulty)
                </h4>
              </div>

              <div className="flex items-center justify-start mt-3 gap-3 sm:gap-4">
                <div className="flex flex-col items-center">
                  <span className="text-[10px] sm:text-xs font-bold text-emerald-600 bg-emerald-50 px-3 py-1.5 rounded-md border border-emerald-100 text-center whitespace-nowrap">
                    นักเรียนที่ตอบถูก {detail.correctCount} คน
                  </span>
                  <div className="h-0.5 w-full bg-slate-200 my-1.5 rounded-full"></div>
                  <span className="text-[10px] sm:text-xs font-bold text-slate-600 bg-slate-50 px-3 py-1.5 rounded-md border border-slate-200 text-center whitespace-nowrap">
                    นักเรียนทั้งหมด {totalValid} คน
                  </span>
                </div>

                <div className="flex items-center gap-2">
                  <span className="text-slate-300 font-black text-2xl">=</span>
                  <span className="font-black text-blue-600 text-4xl tracking-tighter">
                    {detail.difficulty.toFixed(2)}
                  </span>
                </div>
              </div>
            </div>

            {/* D value */}
            <div className="lg:col-span-3 p-5 rounded-xl border border-slate-200 bg-white flex flex-col justify-center overflow-x-auto custom-scrollbar">
              <div className="flex items-center gap-2 mb-4">
                <div className="w-8 h-8 rounded bg-emerald-50 text-emerald-600 flex items-center justify-center font-black text-sm border border-emerald-100">
                  d
                </div>
                <h4 className="font-bold text-slate-700 text-sm">
                  ค่าอำนาจจำแนก (Discrimination)
                </h4>
              </div>

              <div className="flex items-center justify-start mt-3 gap-2 sm:gap-3 min-w-max">
                {/* Upper Group */}
                <div className="flex flex-col items-center">
                  <span className="text-[10px] sm:text-[11px] font-bold text-emerald-700 bg-emerald-50 px-2 py-1.5 rounded-md border border-emerald-200 text-center whitespace-nowrap">
                    กลุ่มได้คะแนนสูง<br></br>ที่ตอบถูก{" "}
                    {detail.upperCorrectCount} คน
                  </span>
                  <div className="h-0.5 w-full bg-slate-200 my-1.5 rounded-full"></div>
                  <span className="text-[10px] sm:text-[11px] font-bold text-slate-600 bg-slate-50 px-2 py-1.5 rounded-md border border-slate-200 text-center whitespace-nowrap">
                    กลุ่มได้คะแนนสูง<br></br>ทั้งหมด {detail.upperGroupLength}{" "}
                    คน
                  </span>
                </div>

                <span className="text-slate-300 font-black text-xl sm:text-2xl">
                  -
                </span>

                {/* Lower Group */}
                <div className="flex flex-col items-center">
                  <span className="text-[10px] sm:text-[11px] font-bold text-rose-700 bg-rose-50 px-2 py-1.5 rounded-md border border-rose-200 text-center whitespace-nowrap">
                    กลุ่มได้คะแนนต่ำ
                    <br />
                    {detail.lowerCorrectCount} คน
                  </span>
                  <div className="h-0.5 w-full bg-slate-200 my-1.5 rounded-full"></div>
                  <span className="text-[10px] sm:text-[11px] font-bold text-slate-600 bg-slate-50 px-2 py-1.5 rounded-md border border-slate-200 text-center whitespace-nowrap">
                    กลุ่มได้คะแนนต่ำ
                    <br />
                    {detail.lowerGroupLength} คน
                  </span>
                </div>

                {/* Result */}
                <div className="flex items-center gap-2 ml-1 sm:ml-2">
                  <span className="text-slate-300 font-black text-xl sm:text-2xl">
                    =
                  </span>
                  <span className="font-black text-emerald-600 text-3xl sm:text-4xl tracking-tighter">
                    {detail.discrimination.toFixed(2)}
                  </span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <div>
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-3">
            <h4 className="font-bold text-slate-800 text-sm uppercase tracking-wider">
              ข้อมูลการตอบของนักเรียน ({studentResponses.length} คน)
            </h4>
            <div className="relative">
              <i className="fa-solid fa-search absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-sm"></i>
              <input
                type="text"
                placeholder="ค้นหารหัสนักศึกษา, ชื่อ, กลุ่ม..."
                className="pl-9 pr-4 py-2 bg-white border border-slate-200 rounded-lg text-sm w-full sm:w-64 focus:ring-2 focus:ring-blue-100 focus:border-blue-400 transition-all outline-none"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>

          <div className="border border-slate-200 rounded-xl overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-sm text-left">
                <thead className="bg-slate-50 text-slate-500 font-bold uppercase text-[11px] tracking-wider border-b border-slate-200">
                  <tr>
                    <th className="px-4 py-3">รหัสนักศึกษา</th>
                    <th className="px-4 py-3">ชื่อ-นามสกุล</th>
                    <th className="px-4 py-3 text-center">กลุ่ม</th>
                    <th className="px-4 py-3 text-center">คำตอบที่เลือก</th>
                    <th className="px-4 py-3 text-center">สถานะ</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 bg-white">
                  {currentResponses.length > 0 ? (
                    currentResponses.map((student, i) => (
                      <tr
                        key={i}
                        className="hover:bg-slate-50/50 transition-colors"
                      >
                        <td className="px-4 py-3 font-medium text-slate-700">
                          {student.studentId}
                        </td>
                        <td className="px-4 py-3 text-slate-600">
                          {student.name}
                        </td>
                        <td className="px-4 py-3 text-center">
                          <span
                            className={`inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold border ${student.groupColor}`}
                          >
                            {student.group}
                          </span>
                        </td>
                        <td className="px-4 py-3 text-center font-bold text-slate-700">
                          {student.answer}
                        </td>
                        <td className="px-4 py-3 text-center">
                          {student.isCorrect ? (
                            <div className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-emerald-100 text-emerald-600">
                              <i className="fa-solid fa-check text-xs"></i>
                            </div>
                          ) : (
                            <div className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-rose-100 text-rose-600">
                              <i className="fa-solid fa-xmark text-xs"></i>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td
                        colSpan="5"
                        className="px-4 py-8 text-center text-slate-400"
                      >
                        ไม่พบข้อมูลที่ค้นหา
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>

            {totalPages > 1 && (
              <div className="flex items-center justify-between px-4 py-3 border-t border-slate-200 bg-slate-50">
                <span className="text-xs text-slate-500 font-medium">
                  แสดง {(currentPage - 1) * itemsPerPage + 1} ถึง{" "}
                  {Math.min(
                    currentPage * itemsPerPage,
                    filteredResponses.length,
                  )}{" "}
                  จาก {filteredResponses.length} คน
                </span>
                <div className="flex gap-1">
                  <button
                    onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                    disabled={currentPage === 1}
                    className="p-1.5 rounded text-slate-400 hover:bg-slate-200 hover:text-slate-700 disabled:opacity-50 transition-colors"
                  >
                    <i className="fa-solid fa-chevron-left text-xs"></i>
                  </button>
                  {Array.from({ length: totalPages }, (_, i) => i + 1)
                    .filter(
                      (p) =>
                        p === 1 ||
                        p === totalPages ||
                        Math.abs(p - currentPage) <= 1,
                    )
                    .map((p, i, arr) => {
                      const isGap = i > 0 && arr[i - 1] !== p - 1;
                      return (
                        <div key={p} className="flex">
                          {isGap && (
                            <span className="px-2 py-1 text-slate-400 text-xs">
                              ...
                            </span>
                          )}
                          <button
                            onClick={() => setCurrentPage(p)}
                            className={`min-w-[28px] h-[28px] rounded text-xs font-bold transition-colors ${currentPage === p ? "bg-blue-600 text-white" : "text-slate-600 hover:bg-slate-200"}`}
                          >
                            {p}
                          </button>
                        </div>
                      );
                    })}
                  <button
                    onClick={() =>
                      setCurrentPage((p) => Math.min(totalPages, p + 1))
                    }
                    disabled={currentPage === totalPages}
                    className="p-1.5 rounded text-slate-400 hover:bg-slate-200 hover:text-slate-700 disabled:opacity-50 transition-colors"
                  >
                    <i className="fa-solid fa-chevron-right text-xs"></i>
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </Modal>
  );
}

export function AnalysisPage({ data }) {
  const [examId, setExamId] = useState(data.exams[0]?.id || "");
  const [selectedItemDetail, setSelectedItemDetail] = useState(null);
  const canvasRef = useRef(null);
  const canvasRefPie = useRef(null);
  const exam = data.exams.find((item) => item.id === examId);

  const results = useMemo(() => {
    if (!examId || !exam) return [];

    // Map and calculate dynamic scores first, excluding problematic / pending review records
    const mappedResults = (data.results || [])
      .filter(
        (result) => result.examId === examId && !isPendingReview(result, exam),
      )
      .map((row) => {
        let dynamicScore = row.score || 0;
        const questionsCount = Number(
          exam?.questions || row.totalQuestions || 0,
        );
        let calculatedItemResults = row.itemResults || {};

        if (exam && (row.answers || row.itemResults)) {
          let calculatedScore = 0;
          let newItemResults = {};
          for (let i = 1; i <= questionsCount; i++) {
            const qStr = String(i);
            const correctAns = getCorrectAnswer(exam, qStr);

            let isCorrect = false;
            if (row.answers) {
              isCorrect =
                row.answers[qStr] === correctAns && correctAns !== "-";
            } else if (row.itemResults) {
              isCorrect = row.itemResults[qStr] === true;
            }

            if (isCorrect) {
              calculatedScore += getQuestionScore(exam, qStr);
            }
            newItemResults[qStr] = isCorrect;
          }
          dynamicScore = calculatedScore;
          calculatedItemResults = newItemResults;
        }

        return {
          ...row,
          score: dynamicScore,
          itemResults: calculatedItemResults,
        };
      });

    // Deduplicate by studentCode or studentId, keeping the highest score
    const deduplicatedMap = new Map();
    mappedResults.forEach((row) => {
      const studentIdentifier = row.studentCode || row.studentId;
      if (!studentIdentifier) {
        // If no student ID is found, just keep it (e.g. unknown student)
        deduplicatedMap.set(`unknown_${row.id}`, row);
        return;
      }

      if (!deduplicatedMap.has(studentIdentifier)) {
        deduplicatedMap.set(studentIdentifier, row);
      } else {
        const existingRow = deduplicatedMap.get(studentIdentifier);
        if ((row.score || 0) > (existingRow.score || 0)) {
          deduplicatedMap.set(studentIdentifier, row);
        }
      }
    });

    return Array.from(deduplicatedMap.values());
  }, [examId, exam, data.results]);
  const scores = results
    .map((result) => Number(result.score || 0))
    .sort((a, b) => a - b);
  const mean = scores.length
    ? scores.reduce((sum, score) => sum + score, 0) / scores.length
    : null;
  const median = scores.length
    ? scores.length % 2
      ? scores[Math.floor(scores.length / 2)]
      : (scores[scores.length / 2 - 1] + scores[scores.length / 2]) / 2
    : null;

  const mode = scores.length
    ? (() => {
        const counts = {};
        let maxCount = 0;
        let modes = [];
        scores.forEach((s) => {
          counts[s] = (counts[s] || 0) + 1;
          if (counts[s] > maxCount) {
            maxCount = counts[s];
            modes = [s];
          } else if (counts[s] === maxCount) {
            if (!modes.includes(s)) modes.push(s);
          }
        });
        const uniqueCounts = Object.values(counts);
        return maxCount <= 1 || uniqueCounts.every((c) => c === maxCount)
          ? "ไม่มี"
          : modes.join(", ");
      })()
    : null;

  const maxScore = scores.length ? Math.max(...scores) : null;
  const minScore = scores.length ? Math.min(...scores) : null;

  // Standard Deviation
  const sd =
    scores.length > 1 && mean !== null
      ? Math.sqrt(
          scores.reduce((sum, s) => sum + (s - mean) ** 2, 0) /
            (scores.length - 1),
        )
      : null;

  // Low-N warning: 27% grouping unreliable below 15 students
  const isLowN = results.length > 0 && results.length < 15;

  const expectedStudentsCount = !examId
    ? null
    : (() => {
        if (!exam) return 0;
        const subjectStudents = data.students.filter(
          (s) =>
            s.subjectCode === exam.subject_id ||
            s.subjectCode === exam.subjectCode ||
            s.subjectCode === exam.subject,
        );
        if (exam.section === "All Section" || !exam.section)
          return subjectStudents.length;
        return subjectStudents.filter(
          (s) => String(s.section) === String(exam.section),
        ).length;
      })();

  const itemAnalysis = calculateItemAnalysis(results, exam);
  const answeredItemAnalysis = itemAnalysis.filter((item) =>
    results.some((result) => result.itemResults?.[item.question] !== undefined),
  );
  const avgDifficulty = answeredItemAnalysis.length
    ? answeredItemAnalysis.reduce((sum, item) => sum + item.difficulty, 0) /
      answeredItemAnalysis.length
    : null;
  const avgDiscrimination = answeredItemAnalysis.length
    ? answeredItemAnalysis.reduce((sum, item) => sum + item.discrimination, 0) /
      answeredItemAnalysis.length
    : null;
  const chartLabels = answeredItemAnalysis.map(
    (item) => `ข้อ ${item.question}`,
  );
  const chartData = answeredItemAnalysis.map((item) =>
    Math.round(item.difficulty * 100),
  );

  useChart(
    canvasRef,
    {
      type: "bar",
      data: {
        labels: chartLabels,
        datasets: [
          {
            label: "ผู้ตอบถูก (%)",
            data: chartData,
            backgroundColor: chartData.map(
              (v) =>
                v >= 80
                  ? "#F59E0B" // ง่ายเกินไป (Amber)
                  : v >= 40
                    ? "#10B981" // เหมาะสม (Emerald)
                    : "#E11D48", // ยากเกินไป (Rose)
            ),
            borderRadius: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (context) => ` ผู้ตอบถูก ${context.raw}%`,
            },
          },
        },
        scales: {
          x: {
            grid: { display: false },
            ticks: { maxRotation: 45, minRotation: 0, font: { size: 11 } },
          },
          y: {
            beginAtZero: true,
            max: 100,
            ticks: { stepSize: 20, callback: (val) => `${val}%` },
            title: {
              display: true,
              text: "เปอร์เซ็นต์การตอบถูก",
              color: "#64748B",
              font: { size: 12, weight: "bold" },
            },
          },
        },
      },
    },
    [examId, data.results, data.exams],
  );

  const dGood = answeredItemAnalysis.filter(
    (i) => i.discrimination >= 0.4,
  ).length;
  const dFair = answeredItemAnalysis.filter(
    (i) => i.discrimination >= 0.2 && i.discrimination < 0.4,
  ).length;
  const dPoor = answeredItemAnalysis.filter(
    (i) => i.discrimination < 0.2,
  ).length;

  useChart(
    canvasRefPie,
    {
      type: "doughnut",
      data: {
        labels: [
          "ดีมาก (คัดเลือกไว้ใช้)",
          "พอใช้ (ควรพิจารณาปรับ)",
          "ควรปรับปรุง (D ต่ำ)",
        ],
        datasets: [
          {
            data: [dGood, dFair, dPoor],
            backgroundColor: ["#10B981", "#F59E0B", "#EF4444"],
            borderWidth: 0,
            hoverOffset: 4,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          legend: { display: false },
          tooltip: {
            callbacks: {
              label: (context) => ` ${context.label}: ${context.raw} ข้อ`,
            },
          },
        },
        cutout: "75%",
      },
    },
    [examId, data.results, data.exams],
  );

  return (
    <div className="page-enter mx-auto max-w-[1600px] space-y-6 px-4 pb-20">
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between mb-2">
        <div>
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
            ภาพรวมสถิติและคุณภาพข้อสอบ
            {exam?.section && (
              <span className="ml-3 rounded-full bg-slate-100 px-3 py-1 text-sm font-black uppercase text-slate-600 border border-slate-200">
                {exam.section === "All Section" || !exam.section
                  ? "All Section"
                  : `Sec ${
                      data.sections?.find(
                        (s) => String(s.id) === String(exam.section),
                      )?.sec || exam.section
                    }`}
              </span>
            )}
          </h2>
          <p className="mt-2 text-sm text-slate-500">
            สรุปคะแนน และคุณภาพข้อสอบรายข้อจากผลการตรวจที่สแกนแล้ว
          </p>
        </div>
        <div className="w-full sm:w-80">
          <label className="mb-1.5 block text-xs font-bold text-slate-500 uppercase tracking-wider">
            เลือกข้อสอบ
          </label>
          <Select
            value={examId}
            onChange={(e) => setExamId(e.target.value)}
            className="w-full bg-white text-slate-900 border-slate-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
          >
            <option value="">ทุกข้อสอบ</option>
            {data.exams.map((item) => (
              <option key={item.id} value={item.id}>
                {item.name} ({item.subject})
              </option>
            ))}
          </Select>
        </div>
      </div>

      {/* Low-N reliability warning */}
      {isLowN && (
        <div className="flex items-start gap-3 p-4 rounded-xl border border-amber-200 bg-amber-50 text-amber-800">
          <i className="fa-solid fa-triangle-exclamation mt-0.5 text-amber-500 shrink-0" />
          <div>
            <p className="font-bold text-sm">
              คำเตือน: จำนวนผู้สอบน้อยเกินไป ({results.length} คน)
            </p>
            <p className="text-xs mt-0.5 leading-relaxed">
              การวิเคราะห์คุณภาพข้อสอบแบบ 27% Upper-Lower Group
              ต้องการผู้สอบอย่างน้อย 15–20 คน
              เพื่อให้ผลมีความเชื่อถือได้ทางสถิติ
              ผลวิเคราะห์ปัจจุบันอาจคลาดเคลื่อนสูง
              ควรใช้เป็นเพียงข้อมูลเบื้องต้นเท่านั้น
            </p>
          </div>
        </div>
      )}

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-6">
        <StatCard
          title="จำนวนผู้สอบ"
          value={!examId ? "-" : results.length}
          icon="fa-users"
          color="indigo"
        />
        <StatCard
          title="คะแนนเฉลี่ย"
          value={mean !== null ? mean.toFixed(2) : "-"}
          icon="fa-chart-simple"
          color="emerald"
        />
        <StatCard
          title="ส่วนเบี่ยงเบนมาตรฐาน"
          value={sd !== null ? sd.toFixed(2) : "-"}
          icon="fa-wave-square"
          color="sky"
        />
        <StatCard
          title="มัธยฐาน"
          value={median !== null ? median.toFixed(2) : "-"}
          icon="fa-scale-balanced"
          color="blue"
        />
        <StatCard
          title="ฐานนิยม"
          value={mode !== null ? mode : "-"}
          icon="fa-chart-pie"
          color="violet"
        />
        <StatCard
          title="คะแนนสูงสุด/ต่ำสุด"
          value={
            maxScore !== null && minScore !== null ? (
              <span className="flex items-center gap-2">
                <span className="text-emerald-500">{maxScore}</span>
                <span className="text-slate-400 font-medium text-2xl">/</span>
                <span className="text-rose-500">{minScore}</span>
              </span>
            ) : (
              "-"
            )
          }
          icon="fa-arrow-up-right-dots"
          color="rose"
        />
      </div>

      <section className="grid gap-6 xl:grid-cols-[minmax(0,1fr)_24rem]">
        <div className="rounded-md border border-slate-200 bg-white p-5 shadow-sm min-w-0 flex flex-col">
          <div className="mb-4">
            <h3 className="text-xl font-bold text-slate-900 tracking-tight">
              ระดับความยากง่ายรายข้อ (p)
            </h3>
            <p className="mt-1 text-sm text-slate-500">
              สัดส่วนเปอร์เซ็นต์ผู้เรียนที่ตอบถูกในแต่ละข้อ
            </p>
          </div>
          <div className="mt-4 relative flex-1 min-h-[280px] w-full overflow-x-auto overflow-y-hidden rounded-md border border-slate-100 bg-slate-50/30 p-2">
            <div
              style={{
                minWidth: `max(100%, ${chartLabels.length * 40}px)`,
                height: "100%",
              }}
            >
              <canvas ref={canvasRef} />
            </div>
          </div>
          <div className="mt-4 flex flex-wrap items-center justify-center gap-4 sm:gap-6 text-sm font-bold text-slate-600">
            <span className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-[#10B981] shadow-sm shadow-emerald-200"></div>{" "}
              เหมาะสม (40–79%)
            </span>
            <span className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-[#F59E0B] shadow-sm shadow-amber-200"></div>{" "}
              ง่ายเกินไป (≥80%) ควรปรับปรุง
            </span>
            <span className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-[#E11D48] shadow-sm shadow-rose-200"></div>{" "}
              ยากเกินไป (&lt;40%) ควรปรับปรุง
            </span>
          </div>
        </div>

        <div className="rounded-md border border-slate-200 bg-white p-5 shadow-sm flex flex-col min-w-0">
          <div className="mb-4">
            <h3 className="text-xl font-bold text-slate-900 tracking-tight">
              สัดส่วนคุณภาพ (D)
            </h3>
            <p className="mt-1 text-sm text-slate-500">
              คัดกรองจากค่าอำนาจจำแนก
            </p>
          </div>
          <div className="relative mt-8 flex-1 min-h-[280px] flex items-center justify-center">
            {answeredItemAnalysis.length > 0 ? (
              <>
                <canvas ref={canvasRefPie} />
                <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none pb-8">
                  <span className="text-4xl font-black text-slate-800">
                    {answeredItemAnalysis.length}
                  </span>
                  <span className="text-[10px] font-bold text-slate-400 uppercase tracking-widest mt-1">
                    ข้อทั้งหมด
                  </span>
                </div>
              </>
            ) : (
              <div className="flex flex-col items-center gap-3 text-slate-400">
                <i className="fa-solid fa-ghost text-4xl opacity-20"></i>
                <p className="text-sm font-medium">ยังไม่มีข้อมูลเพียงพอ</p>
              </div>
            )}
          </div>
          {answeredItemAnalysis.length > 0 &&
            (() => {
              const totalD = answeredItemAnalysis.length;
              return (
                <div className="mt-4 flex flex-wrap items-center justify-center gap-2 text-[11px] font-bold">
                  <span className="flex items-center gap-1.5 px-2.5 py-1.5 bg-emerald-50 text-emerald-700 rounded-md border border-emerald-100 whitespace-nowrap">
                    <div className="w-2 h-2 rounded-full bg-emerald-500 shadow-sm shadow-emerald-200"></div>{" "}
                    ดีมาก {dGood} ข้อ ({Math.round((dGood * 100) / totalD)}%)
                  </span>
                  <span className="flex items-center gap-1.5 px-2.5 py-1.5 bg-amber-50 text-amber-700 rounded-md border border-amber-100 whitespace-nowrap">
                    <div className="w-2 h-2 rounded-full bg-amber-500 shadow-sm shadow-amber-200"></div>{" "}
                    พอใช้ {dFair} ข้อ ({Math.round((dFair * 100) / totalD)}%)
                  </span>
                  <span className="flex items-center gap-1.5 px-2.5 py-1.5 bg-rose-50 text-rose-700 rounded-md border border-rose-100 whitespace-nowrap">
                    <div className="w-2 h-2 rounded-full bg-rose-500 shadow-sm shadow-rose-200"></div>{" "}
                    ควรปรับปรุง {dPoor} ข้อ (
                    {Math.round((dPoor * 100) / totalD)}%)
                  </span>
                </div>
              );
            })()}
        </div>
      </section>

      <section className="rounded-md border border-slate-200 bg-white p-6 shadow-sm">
        <div className="flex items-center gap-3 mb-6 border-b border-slate-100 pb-4">
          <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-blue-50 to-blue-100 text-blue-600 shadow-sm border border-blue-200">
            <i className="fa-solid fa-book-open-reader text-lg" />
          </div>
          <div>
            <h3 className="text-lg font-bold text-slate-900 tracking-tight">
              ทำความเข้าใจเกณฑ์คุณภาพข้อสอบ
            </h3>
            <p className="text-sm text-slate-500 mt-0.5">
              คำอธิบายความหมายและเกณฑ์พิจารณา
              เพื่อนำไปปรับปรุงข้อสอบให้ดียิ่งขึ้น
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* p Box */}
          <div className="rounded-xl border border-blue-100 bg-gradient-to-b from-blue-50/50 to-white overflow-hidden shadow-sm flex flex-col">
            <div className="px-5 py-4 border-b border-blue-100 flex items-start gap-3">
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-blue-600 font-black text-white shadow-sm shadow-blue-200">
                p
              </span>
              <div>
                <span className="font-bold text-base text-blue-900 block">
                  ค่าความยากง่าย (Difficulty)
                </span>
                <span className="text-xs text-blue-700/80 mt-1 block leading-relaxed">
                  สัดส่วนเปอร์เซ็นต์ของผู้ที่ตอบถูก ยิ่งค่าเข้าใกล้ 1 แปลว่าง่าย
                  เข้าใกล้ 0 แปลว่ายาก
                </span>
              </div>
            </div>
            <div className="p-5 flex-1 space-y-3 text-sm">
              <div className="flex items-center justify-between p-3 rounded-lg bg-rose-50/50 border border-rose-100/50 hover:bg-rose-50 transition-colors">
                <span className="text-slate-700 font-medium">0.80 - 1.00</span>
                <span className="flex items-center gap-2 text-rose-700 font-bold text-xs">
                  <i className="fa-solid fa-circle-xmark"></i> ง่ายเกินไป
                  (ควรปรับปรุง)
                </span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-emerald-50 border border-emerald-200 shadow-[0_1px_2px_rgba(16,185,129,0.1)]">
                <span className="text-emerald-900 font-bold">0.40 - 0.79</span>
                <span className="flex items-center gap-2 text-emerald-700 font-bold text-xs">
                  <i className="fa-solid fa-circle-check"></i> เหมาะสม
                  (คัดเลือกไว้ใช้)
                </span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-rose-50/50 border border-rose-100/50 hover:bg-rose-50 transition-colors">
                <span className="text-slate-700 font-medium">0.00 - 0.39</span>
                <span className="flex items-center gap-2 text-rose-700 font-bold text-xs">
                  <i className="fa-solid fa-circle-xmark"></i> ยากเกินไป
                  (ควรปรับปรุง)
                </span>
              </div>
            </div>
          </div>

          {/* D Box */}
          <div className="rounded-xl border border-emerald-100 bg-gradient-to-b from-emerald-50/50 to-white overflow-hidden shadow-sm flex flex-col">
            <div className="px-5 py-4 border-b border-emerald-100 flex items-start gap-3">
              <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-emerald-500 font-black text-white shadow-sm shadow-emerald-200">
                d
              </span>
              <div>
                <span className="font-bold text-base text-emerald-950 block">
                  ค่าอำนาจจำแนก (Discrimination)
                </span>
                <span className="text-xs text-emerald-800/80 mt-1 block leading-relaxed">
                  ความสามารถในการแยกกลุ่มผู้เรียนที่ได้คะแนนสูงและต่ำ
                  (สัดส่วนกลุ่มสูงตอบถูก − สัดส่วนกลุ่มต่ำตอบถูก)
                </span>
              </div>
            </div>
            <div className="p-5 flex-1 space-y-3 text-sm">
              <div className="flex items-center justify-between p-3 rounded-lg bg-emerald-50 border border-emerald-200 shadow-[0_1px_2px_rgba(16,185,129,0.1)]">
                <span className="text-emerald-900 font-bold">0.40 ขึ้นไป</span>
                <span className="flex items-center gap-2 text-emerald-700 font-bold text-xs">
                  <i className="fa-solid fa-circle-check"></i> ดีมาก
                  (คัดเลือกไว้ใช้)
                </span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-amber-50/50 border border-amber-100/50 hover:bg-amber-50 transition-colors">
                <span className="text-slate-700 font-medium">0.20 - 0.39</span>
                <span className="flex items-center gap-2 text-amber-700 font-bold text-xs">
                  <i className="fa-solid fa-circle-exclamation"></i> พอใช้
                  (พิจารณาปรับปรุง)
                </span>
              </div>
              <div className="flex items-center justify-between p-3 rounded-lg bg-rose-50/50 border border-rose-100/50 hover:bg-rose-50 transition-colors">
                <span className="text-slate-700 font-medium">ต่ำกว่า 0.20</span>
                <span className="flex items-center gap-2 text-rose-700 font-bold text-xs">
                  <i className="fa-solid fa-circle-xmark"></i> ควรปรับปรุง
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="space-y-4 mt-8">
        <div className="flex flex-col sm:flex-row sm:items-end sm:justify-between gap-3">
          <div>
            <h2 className="text-xl font-bold text-slate-900 tracking-tight">
              ตารางวิเคราะห์คุณภาพข้อสอบรายข้อ
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              ข้อมูลการวิเคราะห์คุณภาพและการแปลผลรายข้อ
            </p>
          </div>
          {answeredItemAnalysis.length > 0 && (
            <div className="flex flex-wrap items-center gap-2">
              {/* CSV: item analysis */}
              <button
                onClick={() => {
                  const header = [
                    "ข้อ",
                    "เฉลย",
                    "ตอบถูก",
                    "ทั้งหมด",
                    "p (ความยาก)",
                    "ระดับความยาก",
                    "กลุ่มสูงตอบถูก",
                    "กลุ่มต่ำตอบถูก",
                    "d (อำนาจจำแนก)",
                    "ผลลัพธ์",
                  ];
                  const rows = answeredItemAnalysis.map((r) => [
                    r.question,
                    r.answer,
                    r.correctCount,
                    results.length,
                    r.difficulty.toFixed(3),
                    r.difficultyLabel,
                    `${r.upperCorrectCount}/${r.upperGroupLength} (${Math.round(r.upperCorrect * 100)}%)`,
                    `${r.lowerCorrectCount}/${r.lowerGroupLength} (${Math.round(r.lowerCorrect * 100)}%)`,
                    r.discrimination.toFixed(3),
                    r.discriminationLabel,
                  ]);
                  const csv = [header, ...rows]
                    .map((row) =>
                      row
                        .map((c) => `"${String(c).replace(/"/g, '""')}"`)
                        .join(","),
                    )
                    .join("\n");
                  const blob = new Blob(["\uFEFF" + csv], {
                    type: "text/csv;charset=utf-8;",
                  });
                  const url = URL.createObjectURL(blob);
                  const a = document.createElement("a");
                  a.href = url;
                  a.download = `item_analysis_${exam?.name || examId}.csv`;
                  a.click();
                  URL.revokeObjectURL(url);
                }}
                className="inline-flex shrink-0 items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold text-slate-600 bg-slate-50 hover:bg-slate-100 transition-colors border border-slate-200 shadow-sm"
              >
                <i className="fa-solid fa-table" /> CSV (รายข้อ)
              </button>

              {/* XLSX: student response matrix */}
              <button
                onClick={async () => {
                  const { utils, writeFile } = await import("xlsx");
                  const numQ = Number(exam.questions || 0);
                  const qs = Array.from({ length: numQ }, (_, i) =>
                    String(i + 1),
                  );
                  const sorted = [...results].sort(
                    (a, b) => Number(b.score || 0) - Number(a.score || 0),
                  );
                  const gs = Math.max(1, Math.ceil(sorted.length * 0.27));
                  const { upper: ug, lower: lg } = splitGroups(sorted, gs);

                  const headerRow = [
                    "คนที่",
                    ...qs.map((q) => `ข้อ ${q}`),
                    "รวม",
                  ];
                  const studentRows = sorted.map((r, idx) => [
                    idx + 1,
                    ...qs.map((q) => (r.itemResults?.[q] === true ? 1 : 0)),
                    Number(r.score || 0),
                  ]);
                  const blank = Array(headerRow.length).fill("");
                  const mkRow = (label, fn) => [label, ...qs.map(fn), ""];

                  const allRows = [
                    headerRow,
                    ...studentRows,
                    blank,
                    mkRow(
                      "คนที่ตอบถูกในกลุ่มสูง",
                      (q) =>
                        ug.filter((r) => r.itemResults?.[q] === true).length,
                    ),
                    mkRow("คนทั้งหมดในกลุ่มสูง", () => ug.length),
                    mkRow("PH", (q) =>
                      ug.length
                        ? ug.filter((r) => r.itemResults?.[q] === true).length /
                          ug.length
                        : 0,
                    ),
                    blank,
                    mkRow(
                      "คนที่ตอบถูกในกลุ่มต่ำ",
                      (q) =>
                        lg.filter((r) => r.itemResults?.[q] === true).length,
                    ),
                    mkRow("คนทั้งหมดในกลุ่มต่ำ", () => lg.length),
                    mkRow("PL", (q) =>
                      lg.length
                        ? lg.filter((r) => r.itemResults?.[q] === true).length /
                          lg.length
                        : 0,
                    ),
                    blank,
                    mkRow(
                      "p (ความยากง่าย)",
                      (q) =>
                        answeredItemAnalysis.find((i) => i.question === q)
                          ?.difficulty ?? "",
                    ),
                    mkRow(
                      "D (อำนาจจำแนก)",
                      (q) =>
                        answeredItemAnalysis.find((i) => i.question === q)
                          ?.discrimination ?? "",
                    ),
                  ];

                  const ws = utils.aoa_to_sheet(allRows);
                  ws["!cols"] = [
                    { wch: 24 },
                    ...qs.map(() => ({ wch: 8 })),
                    { wch: 8 },
                  ];
                  ws["!freeze"] = { xSplit: 0, ySplit: 1 };
                  const wb = utils.book_new();
                  utils.book_append_sheet(wb, ws, "Response Matrix");
                  writeFile(wb, `response_matrix_${exam?.name || examId}.xlsx`);
                }}
                className="inline-flex shrink-0 items-center gap-2 px-4 py-2 rounded-lg text-sm font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 transition-colors border border-emerald-200 shadow-sm"
              >
                <i className="fa-solid fa-file-excel" /> Excel (Matrix)
              </button>
            </div>
          )}
        </div>

        <DataTable
          columns={[
            {
              key: "question",
              label: "ข้อ",
              className: "w-16 text-center",
              render: (row) => (
                <span className="text-base font-bold text-slate-800">
                  {row.question}
                </span>
              ),
            },
            {
              key: "answer",
              label: "เฉลย",
              className: "text-center",
              render: (row) => (
                <span className="inline-flex h-8 w-8 items-center justify-center rounded-full bg-blue-50 text-sm font-black text-blue-700 border border-blue-200 shadow-[0_1px_2px_rgba(0,0,0,0.05)]">
                  {row.answer}
                </span>
              ),
            },
            {
              key: "correctCount",
              label: "ตอบถูก",
              className: "text-center",
              render: (row) => `${row.correctCount}/${results.length}`,
            },
            {
              key: "difficulty",
              label: "ค่าความยากง่าย",
              className: "text-center",
              render: (row) => (
                <div className="flex flex-col items-center justify-center">
                  <span
                    className="text-[10px] text-slate-400 font-medium leading-none mb-1"
                    title="คนตอบถูก / คนทั้งหมด"
                  >
                    {row.correctCount} / {results.length}
                  </span>
                  <span className="font-bold text-slate-800 leading-none">
                    {row.difficulty.toFixed(2)}
                  </span>
                </div>
              ),
            },
            {
              key: "difficultyLabel",
              label: "ระดับความยาก",
              className: "text-center",
              render: (row) => (
                <span
                  className={`inline-flex rounded-full border px-2.5 py-1 text-[11px] font-semibold ${itemTone(row.difficulty, "difficulty")}`}
                >
                  {row.difficultyLabel}
                </span>
              ),
            },
            {
              key: "upperCorrect",
              label: "กลุ่มคะแนนสูงตอบถูก",
              className:
                "text-center text-emerald-600 font-medium bg-emerald-50/30",
              render: (row) => (
                <div className="flex flex-col items-center justify-center">
                  <span className="text-[10px] text-slate-400 font-medium leading-none mb-1">
                    {row.upperCorrectCount} / {row.upperGroupLength}
                  </span>
                  <span className="font-bold leading-none">
                    {Math.round((row.upperCorrect || 0) * 100)}%
                  </span>
                </div>
              ),
            },
            {
              key: "lowerCorrect",
              label: "กลุ่มคะแนนต่ำตอบถูก",
              className: "text-center text-rose-600 font-medium bg-rose-50/30",
              render: (row) => (
                <div className="flex flex-col items-center justify-center">
                  <span className="text-[10px] text-slate-400 font-medium leading-none mb-1">
                    {row.lowerCorrectCount} / {row.lowerGroupLength}
                  </span>
                  <span className="font-bold leading-none">
                    {Math.round((row.lowerCorrect || 0) * 100)}%
                  </span>
                </div>
              ),
            },
            {
              key: "discrimination",
              label: "ค่าอำนาจจำแนก",
              className: "text-center",
              render: (row) => (
                <div className="flex flex-col items-center justify-center">
                  <span
                    className="text-[10px] text-slate-400 font-medium leading-none mb-1"
                    title="กลุ่มได้คะแนนสูงตอบถูก - กลุ่มได้คะแนนต่ำตอบถูก"
                  >
                    {Math.round((row.upperCorrect || 0) * 100)}% -{" "}
                    {Math.round((row.lowerCorrect || 0) * 100)}%
                  </span>
                  <span className="font-bold text-slate-800 leading-none">
                    {row.discrimination.toFixed(2)}
                  </span>
                </div>
              ),
            },
            {
              key: "discriminationLabel",
              label: "ผลลัพธ์",
              render: (row) => (
                <span
                  className={`inline-flex rounded-full border px-2.5 py-1 text-[11px] font-semibold ${itemTone(row.discrimination, "discrimination")}`}
                >
                  {row.discriminationLabel}
                </span>
              ),
            },
            {
              key: "action",
              label: "",
              className: "w-24 text-right pr-4",
              render: (row) => (
                <button
                  onClick={() => setSelectedItemDetail(row)}
                  className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold text-blue-600 bg-blue-50 hover:bg-blue-100 hover:text-blue-700 transition-colors border border-blue-200 shadow-sm"
                >
                  <i className="fa-solid fa-list-ul"></i> รายละเอียด
                </button>
              ),
            },
          ]}
          rows={answeredItemAnalysis}
          emptyText="ยังไม่มีข้อมูลรายข้อสำหรับคำนวณค่าความยากง่ายและค่าอำนาจจำแนก"
        />
      </section>

      <QuestionDetailModal
        isOpen={!!selectedItemDetail}
        onClose={() => setSelectedItemDetail(null)}
        detail={selectedItemDetail}
        results={results}
        students={data.students}
        exam={exam}
      />
    </div>
  );
}
