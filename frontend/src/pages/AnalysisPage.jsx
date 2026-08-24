import { useRef, useState, useMemo, useEffect } from "react";
import { DataTable, Select, StatCard, useChart, Modal } from "../ui.jsx";

function itemLabel(value, type) {
  if (type === "difficulty") {
    if (value >= 0.8) return "ง่ายเกินเกณฑ์";
    if (value >= 0.4) return "เหมาะสม";
    return "ยากเกินเกณฑ์";
  }
  if (value >= 0.4) return "ดีมาก";
  if (value >= 0.2) return "พอใช้ได้";
  return "ควรปรับปรุง";
}

function itemTone(value, type) {
  if (type === "difficulty") {
    if (value >= 0.8) return "text-amber-700 bg-amber-50 border-amber-100";
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
  let hasFlag = false;
  const flagged = result.flagged;

  if (flagged === true || flagged === "true") {
    hasFlag = true;
  } else if (Array.isArray(flagged) && flagged.length > 0) {
    hasFlag = true;
  } else if (typeof flagged === "string" && flagged.trim()) {
    const norm = flagged.trim().toLowerCase();
    if (
      ["true", "pending", "flagged", "needs_review", "review"].includes(norm)
    ) {
      hasFlag = true;
    } else {
      try {
        const parsed = JSON.parse(flagged);
        if (Array.isArray(parsed) && parsed.length > 0) hasFlag = true;
        if (parsed === true) hasFlag = true;
      } catch {}
    }
  }

  // If flagged is explicitly false, it means it was verified
  if (
    flagged === false ||
    flagged === "false" ||
    (Array.isArray(flagged) && flagged.length === 0) ||
    flagged === "[]"
  ) {
    // Explicitly resolved
    hasFlag = false;
  } else if (!hasFlag) {
    // 2. Check status property only if not explicitly flagged
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
      hasFlag = true;
    }
  }

  if (hasFlag) return true;

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

      <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 xl:grid-cols-4">
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
          icon="fa-arrow-up-wide-short"
          color="rose"
        />
        <StatCard
          title="ความยากง่ายเฉลี่ย (p)"
          value={avgDifficulty !== null ? avgDifficulty.toFixed(2) : "-"}
          icon="fa-chart-line"
          color="amber"
        />
        <StatCard
          title="อำนาจจำแนกเฉลี่ย (r)"
          value={
            avgDiscrimination !== null ? avgDiscrimination.toFixed(2) : "-"
          }
          icon="fa-bolt"
          color="fuchsia"
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
              label: "N ถูก / รวม",
              className: "text-center",
              render: (row) => `${row.correctCount} / ${results.length}`,
            },
            {
              key: "difficulty",
              label: "p (ความยากง่าย)",
              className: "text-center",
              render: (row) => row.difficulty.toFixed(2),
            },
            {
              key: "difficultyLabel",
              label: "ระดับ",
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
              key: "discrimination",
              label: "d (อำนาจจำแนก)",
              className: "text-center",
              render: (row) => row.discrimination.toFixed(2),
            },
            {
              key: "discriminationLabel",
              label: "แปลผล D",
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

function QuestionDetailModal({
  isOpen,
  onClose,
  detail,
  results,
  students,
  exam,
}) {
  if (!isOpen || !detail) return null;

  const questionNum = detail.question;
  const correctAnswer = detail.answer;

  const validResults = (results || []).filter((r) => !isPendingReview(r, exam));
  const sorted = [...validResults].sort(
    (a, b) => Number(b.score || 0) - Number(a.score || 0),
  );
  const groupSize = Math.max(1, Math.ceil(sorted.length * 0.27));
  const { upper: upperGroup, lower: lowerGroup } = splitGroups(
    sorted,
    groupSize,
  );

  const numOptions = Number(exam?.options || 5);
  const defaultChoices = ["A", "B", "C", "D", "E"].slice(0, numOptions);

  const allChoicesSet = new Set(defaultChoices);
  validResults.forEach((r) => {
    const a = r.answers?.[questionNum];
    if (a && typeof a === "string" && a.trim() && a !== "-" && a.length === 1) {
      allChoicesSet.add(a.trim().toUpperCase());
    }
  });

  const choices = Array.from(allChoicesSet).sort();

  const choiceStats = choices.map((choice) => {
    const isCorrect = choice === correctAnswer;

    const totalCount = validResults.filter(
      (r) => (r.answers?.[questionNum] || "").trim().toUpperCase() === choice,
    ).length;
    const totalPct = validResults.length
      ? Math.round((totalCount / validResults.length) * 100)
      : 0;

    const upperCount = upperGroup.filter(
      (r) => (r.answers?.[questionNum] || "").trim().toUpperCase() === choice,
    ).length;
    const upperPct = upperGroup.length
      ? Math.round((upperCount / upperGroup.length) * 100)
      : 0;

    const lowerCount = lowerGroup.filter(
      (r) => (r.answers?.[questionNum] || "").trim().toUpperCase() === choice,
    ).length;
    const lowerPct = lowerGroup.length
      ? Math.round((lowerCount / lowerGroup.length) * 100)
      : 0;

    let distractorStatus = null;
    if (isCorrect) {
      distractorStatus = {
        label: "คำตอบที่ถูกต้อง",
        tone: "text-emerald-700 bg-emerald-50 border border-emerald-200",
        icon: "fa-solid fa-circle-check",
      };
    } else {
      if (totalCount === 0) {
        distractorStatus = {
          label: "ไม่มีคนเลือก",
          tone: "text-slate-500 bg-slate-100 border border-slate-200",
          icon: "fa-solid fa-circle-minus",
        };
      } else if (lowerCount > upperCount) {
        distractorStatus = {
          label: "ตัวลวงมีประสิทธิภาพ",
          tone: "text-emerald-700 bg-emerald-50 border border-emerald-200",
          icon: "fa-solid fa-circle-check",
        };
      } else if (upperCount > lowerCount) {
        distractorStatus = {
          label: "ตัวลวงมีปัญหา (ลวงเด็กเก่ง)",
          tone: "text-rose-700 bg-rose-50 border border-rose-200",
          icon: "fa-solid fa-triangle-exclamation",
        };
      } else {
        distractorStatus = {
          label: "ตัวลวงพอใช้",
          tone: "text-amber-700 bg-amber-50 border border-amber-200",
          icon: "fa-solid fa-circle-info",
        };
      }
    }

    return {
      choice,
      isCorrect,
      totalCount,
      totalPct,
      upperCount,
      upperPct,
      lowerCount,
      lowerPct,
      distractorStatus,
    };
  });

  const noAnswerCount = validResults.filter((r) => {
    const a = (r.answers?.[questionNum] || "").trim();
    return !a || a === "-" || a === "ฝนมากกว่า 1 ตัวเลือก" || a.length > 1;
  }).length;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`การวิเคราะห์รายข้อ: ข้อที่ ${questionNum}`}
      maxWidth="max-w-4xl"
    >
      <div className="space-y-6 text-slate-800">
        {/* Top Summary Cards */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
          <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 text-center">
            <span className="text-xs font-semibold text-blue-600 block mb-1">
              เฉลย
            </span>
            <span className="text-2xl font-extrabold text-blue-800">
              {correctAnswer}
            </span>
          </div>

          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 text-center">
            <span className="text-xs font-semibold text-slate-500 block mb-1">
              ตอบถูก / ทั้งหมด
            </span>
            <span className="text-xl font-bold text-slate-800">
              {detail.correctCount} / {validResults.length}
            </span>
            <span className="text-xs text-slate-400 block mt-0.5">
              (
              {validResults.length
                ? Math.round((detail.correctCount / validResults.length) * 100)
                : 0}
              %)
            </span>
          </div>

          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 text-center">
            <span className="text-xs font-semibold text-slate-500 block mb-1">
              ความยากง่าย (p)
            </span>
            <span className="text-xl font-bold text-slate-800">
              {detail.difficulty.toFixed(2)}
            </span>
            <span
              className={`inline-block mt-1 px-2 py-0.5 rounded-full text-[10px] font-bold border ${itemTone(detail.difficulty, "difficulty")}`}
            >
              {detail.difficultyLabel}
            </span>
          </div>

          <div className="bg-slate-50 border border-slate-200 rounded-xl p-4 text-center">
            <span className="text-xs font-semibold text-slate-500 block mb-1">
              อำนาจจำแนก (D)
            </span>
            <span className="text-xl font-bold text-slate-800">
              {detail.discrimination.toFixed(2)}
            </span>
            <span
              className={`inline-block mt-1 px-2 py-0.5 rounded-full text-[10px] font-bold border ${itemTone(detail.discrimination, "discrimination")}`}
            >
              {detail.discriminationLabel}
            </span>
          </div>
        </div>

        {/* Group Info Callout */}
        <div className="bg-slate-50 rounded-xl p-3.5 border border-slate-200 flex flex-wrap items-center justify-between gap-3 text-xs text-slate-600">
          <div className="flex items-center gap-2">
            <i className="fa-solid fa-users text-slate-400" />
            <span>
              กลุ่มสูง (27% บน):{" "}
              <strong className="text-slate-800">{upperGroup.length} คน</strong>{" "}
              (ตอบถูก {detail.upperCorrectCount} คน ={" "}
              {Math.round((detail.upperCorrect || 0) * 100)}%)
            </span>
          </div>
          <div className="flex items-center gap-2">
            <i className="fa-solid fa-users text-slate-400" />
            <span>
              กลุ่มต่ำ (27% ล่าง):{" "}
              <strong className="text-slate-800">{lowerGroup.length} คน</strong>{" "}
              (ตอบถูก {detail.lowerCorrectCount} คน ={" "}
              {Math.round((detail.lowerCorrect || 0) * 100)}%)
            </span>
          </div>
        </div>

        {/* Choices Breakdown Table */}
        <div>
          <h4 className="text-sm font-bold text-slate-800 mb-3 flex items-center gap-2">
            <i className="fa-solid fa-chart-column text-blue-600" />
            การกระจายตัวของตัวเลือกและประสิทธิภาพตัวลวง
          </h4>
          <div className="overflow-x-auto rounded-xl border border-slate-200">
            <table className="w-full text-left text-sm">
              <thead className="bg-slate-100 text-xs text-slate-600 font-bold border-b border-slate-200">
                <tr>
                  <th className="py-3 px-4 text-center w-20">ตัวเลือก</th>
                  <th className="py-3 px-4 text-center">
                    กลุ่มสูง (N={upperGroup.length})
                  </th>
                  <th className="py-3 px-4 text-center">
                    กลุ่มต่ำ (N={lowerGroup.length})
                  </th>
                  <th className="py-3 px-4 text-center">
                    รวมทั้งหมด (N={validResults.length})
                  </th>
                  <th className="py-3 px-4">การประเมินตัวเลือก</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200 bg-white">
                {choiceStats.map((row) => (
                  <tr
                    key={row.choice}
                    className={
                      row.isCorrect
                        ? "bg-emerald-50/40 font-medium"
                        : "hover:bg-slate-50/60"
                    }
                  >
                    <td className="py-3 px-4 text-center">
                      <span
                        className={`inline-flex w-8 h-8 items-center justify-center rounded-full text-sm font-black ${
                          row.isCorrect
                            ? "bg-emerald-600 text-white shadow-sm"
                            : "bg-slate-100 text-slate-700 border border-slate-300"
                        }`}
                      >
                        {row.choice}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <div className="font-bold text-slate-800">
                        {row.upperCount} คน
                      </div>
                      <div className="text-xs text-slate-400">
                        ({row.upperPct}%)
                      </div>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <div className="font-bold text-slate-800">
                        {row.lowerCount} คน
                      </div>
                      <div className="text-xs text-slate-400">
                        ({row.lowerPct}%)
                      </div>
                    </td>
                    <td className="py-3 px-4 text-center">
                      <div className="font-bold text-slate-800">
                        {row.totalCount} คน
                      </div>
                      <div className="text-xs text-slate-400">
                        ({row.totalPct}%)
                      </div>
                    </td>
                    <td className="py-3 px-4">
                      {row.distractorStatus && (
                        <span
                          className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-semibold ${row.distractorStatus.tone}`}
                        >
                          <i className={row.distractorStatus.icon} />
                          {row.distractorStatus.label}
                        </span>
                      )}
                    </td>
                  </tr>
                ))}
                {noAnswerCount > 0 && (
                  <tr className="bg-slate-50/70 text-slate-500 text-xs">
                    <td className="py-2.5 px-4 text-center italic font-semibold">
                      ไม่ตอบ / โมฆะ
                    </td>
                    <td className="py-2.5 px-4 text-center" colSpan={2}>
                      -
                    </td>
                    <td className="py-2.5 px-4 text-center font-bold">
                      {noAnswerCount} คน
                    </td>
                    <td className="py-2.5 px-4 italic text-slate-400">
                      ไม่ระบุคำตอบหรือฝนผิดพลาด
                    </td>
                  </tr>
                )}
              </tbody>
            </table>
          </div>
        </div>

        {/* Interpretation Box */}
        <div className="bg-blue-50/70 rounded-xl p-4 border border-blue-200 text-xs text-blue-950 space-y-2">
          <h5 className="font-bold text-blue-900 flex items-center gap-2 text-sm">
            <i className="fa-solid fa-lightbulb text-amber-500" />
            คำแนะนำสำหรับการปรับปรุงข้อสอบ
          </h5>
          <ul className="list-disc list-inside space-y-1 text-slate-700 leading-relaxed">
            {detail.discrimination >= 0.4 &&
            detail.difficulty >= 0.4 &&
            detail.difficulty <= 0.8 ? (
              <li className="text-emerald-800 font-semibold">
                ข้อสอบข้อนี้มีคุณภาพดีมาก
                ทั้งความยากง่ายและอำนาจจำแนกอยู่ในเกณฑ์ที่เหมาะสม
                ควรเก็บไว้ใช้ในคลังข้อสอบ
              </li>
            ) : detail.discrimination < 0.2 ? (
              <li className="text-rose-800 font-semibold">
                ค่าอำนาจจำแนกต่ำกว่า 0.20 ควรพิจารณาปรับปรุงเนื้อหาข้อสอบ
                หรือตรวจสอบตัวลวงที่มีปัญหา
              </li>
            ) : (
              <li className="text-amber-800 font-semibold">
                ข้อสอบอยู่ในเกณฑ์พอใช้ อาจปรับปรุงตัวเลือกที่ไม่มีผู้ตอบ
                หรือตัวลวงที่ลวงกลุ่มคะแนนสูง
              </li>
            )}
            <li>
              <strong>ตัวลวงที่ดี:</strong> กลุ่มคะแนนต่ำ (เด็กอ่อน)
              ควรเลือกมากกว่ากลุ่มคะแนนสูง (เด็กเก่ง)
            </li>
            <li>
              <strong>ตัวลวงที่ไม่มีคนเลือก:</strong>{" "}
              ควรปรับเปลี่ยนเนื้อหาตัวเลือกให้มีความน่าจะเป็นและดึงดูดมากขึ้น
            </li>
          </ul>
        </div>
      </div>
    </Modal>
  );
}
