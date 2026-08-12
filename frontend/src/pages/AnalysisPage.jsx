import { useRef, useState } from "react";
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

function calculateItemAnalysis(results, exam) {
  if (!exam || !results.length) return [];
  const sorted = [...results].sort(
    (a, b) => Number(b.score || 0) - Number(a.score || 0),
  );
  const groupSize = Math.max(1, Math.ceil(sorted.length * 0.27));
  const upperGroup = sorted.slice(0, groupSize);
  const lowerGroup = sorted.slice(-groupSize);

  return Array.from({ length: Number(exam.questions || 0) }, (_, index) => {
    const question = String(index + 1);
    const isCorrect = (result) => result.itemResults?.[question] === true;
    const correctCount = results.filter(isCorrect).length;
    const upperCorrect =
      upperGroup.filter(isCorrect).length / upperGroup.length;
    const lowerCorrect =
      lowerGroup.filter(isCorrect).length / lowerGroup.length;
    const difficulty = correctCount / results.length;
    const discrimination = upperCorrect - lowerCorrect;

    const answer = getCorrectAnswer(exam, question);

    return {
      id: question,
      question,
      answer,
      correctCount,
      difficulty,
      discrimination,
      difficultyLabel: itemLabel(difficulty, "difficulty"),
      discriminationLabel: itemLabel(discrimination, "discrimination"),
    };
  });
}

export function AnalysisPage({ data }) {
  const [examId, setExamId] = useState(data.exams[0]?.id || "");
  const [infoModal, setInfoModal] = useState({ isOpen: false, type: "" });
  const canvasRef = useRef(null);
  const canvasRefPie = useRef(null);
  const exam = data.exams.find((item) => item.id === examId);

  const results = !examId
    ? []
    : data.results
        .filter((result) => result.examId === examId)
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

              if (isCorrect) calculatedScore++;
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
        return maxCount > 1 || scores.length === 1 ? modes.join(", ") : "ไม่มี";
      })()
    : null;

  const maxScore = scores.length ? Math.max(...scores) : null;
  const minScore = scores.length ? Math.min(...scores) : null;

  const expectedStudentsCount = !examId
    ? null
    : (() => {
        if (!exam) return 0;
        if (exam.section === "All Section" || !exam.section)
          return data.students.length;
        return data.students.filter(
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
                  ? "#E11D48" // ง่ายเกินไป (Rose)
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
          "ไม่ดี (ตัดทิ้ง)",
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

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-5">
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
          <div className="mt-4 flex flex-wrap items-center justify-center gap-6 text-sm font-bold text-slate-600">
            <span className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-[#10B981] shadow-sm shadow-emerald-200"></div>{" "}
              เหมาะสม (40-79%)
            </span>
            <span className="flex items-center gap-2">
              <div className="w-3 h-3 rounded-full bg-[#E11D48] shadow-sm shadow-rose-200"></div>{" "}
              ยาก/ง่ายเกินไป (ควรปรับปรุง)
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
                    ไม่ดี {dPoor} ข้อ ({Math.round((dPoor * 100) / totalD)}%)
                  </span>
                </div>
              );
            })()}
        </div>
      </section>

      <section className="rounded-md border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-center gap-2 mb-4 font-bold text-slate-800">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 text-blue-600">
            <i className="fa-solid fa-circle-info" />
          </div>
          <span>เกณฑ์คุณภาพข้อสอบ</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* p Box */}
          <div className="rounded-md border border-blue-100 bg-blue-50/30 overflow-hidden">
            <div className="bg-blue-100/50 px-4 py-2 flex items-center gap-2 border-b border-blue-100">
              <span className="flex h-6 w-6 items-center justify-center rounded-md bg-white font-black text-blue-700 shadow-sm border border-blue-200 text-xs">
                p
              </span>
              <span className="font-bold text-sm text-blue-900 flex items-center gap-1.5">
                ค่าความยากง่าย (Difficulty)
                <i
                  className="fa-solid fa-circle-question text-blue-400 hover:text-blue-500 cursor-pointer transition-colors"
                  onClick={() => setInfoModal({ isOpen: true, type: "p" })}
                />
              </span>
            </div>
            <div className="p-4 space-y-2 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-slate-600">0.80 - 1.00</span>
                <span className="px-2.5 py-0.5 rounded text-xs font-semibold bg-rose-100 text-rose-700">
                  ง่ายเกินไป (ควรปรับปรุง)
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600 font-bold">0.40 - 0.79</span>
                <span className="px-2.5 py-0.5 rounded text-xs font-semibold bg-emerald-100 text-emerald-700">
                  เหมาะสม (คัดเลือกไว้ใช้)
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">0.00 - 0.39</span>
                <span className="px-2.5 py-0.5 rounded text-xs font-semibold bg-rose-100 text-rose-700">
                  ยากเกินไป (ควรปรับปรุง)
                </span>
              </div>
            </div>
          </div>

          {/* D Box */}
          <div className="rounded-md border border-emerald-100 bg-emerald-50/30 overflow-hidden">
            <div className="bg-emerald-100/50 px-4 py-2 flex items-center gap-2 border-b border-emerald-100">
              <span className="flex h-6 w-6 items-center justify-center rounded-md bg-white font-black text-emerald-700 shadow-sm border border-emerald-200 text-xs">
                D
              </span>
              <span className="font-bold text-sm text-emerald-900 flex items-center gap-1.5">
                ค่าอำนาจจำแนก (Discrimination)
                <i
                  className="fa-solid fa-circle-question text-emerald-400 hover:text-emerald-500 cursor-pointer transition-colors"
                  onClick={() => setInfoModal({ isOpen: true, type: "D" })}
                />
              </span>
            </div>
            <div className="p-4 space-y-2 text-sm">
              <div className="flex items-center justify-between">
                <span className="text-slate-600 font-bold">0.40 ขึ้นไป</span>
                <span className="px-2.5 py-0.5 rounded text-xs font-semibold bg-emerald-100 text-emerald-700">
                  ดีมาก (คัดเลือกไว้ใช้)
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">0.20 - 0.39</span>
                <span className="px-2.5 py-0.5 rounded text-xs font-semibold bg-amber-100 text-amber-700">
                  พอใช้ (ควรพิจารณาปรับ)
                </span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-slate-600">ต่ำกว่า 0.20</span>
                <span className="px-2.5 py-0.5 rounded text-xs font-semibold bg-rose-100 text-rose-700">
                  ไม่ดี (ตัดทิ้ง)
                </span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section className="space-y-4 mt-8">
        <div>
          <h2 className="text-xl font-bold text-slate-900 tracking-tight">
            ตารางวิเคราะห์คุณภาพข้อสอบรายข้อ
          </h2>
          <p className="mt-1 text-sm text-slate-500">
            ข้อมูลการวิเคราะห์คุณภาพและการแปลผลรายข้อ
          </p>
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
              label: "ค่าอำนาจจำแนก",
              className: "text-center",
              render: (row) => row.discrimination.toFixed(2),
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
          ]}
          rows={answeredItemAnalysis}
          emptyText="ยังไม่มีข้อมูลรายข้อสำหรับคำนวณค่าความยากง่ายและค่าอำนาจจำแนก"
        />
      </section>

      <Modal
        isOpen={infoModal.isOpen}
        onClose={() => setInfoModal({ ...infoModal, isOpen: false })}
        title={
          infoModal.type === "p"
            ? "ค่าความยากง่าย (Difficulty)"
            : "ค่าอำนาจจำแนก (Discrimination)"
        }
        maxWidth="max-w-lg"
      >
        <div className="text-slate-700 text-sm leading-relaxed">
          {infoModal.type === "p" && (
            <div className="space-y-4">
              <p className="text-base text-slate-600">
                <strong>ค่าความยากง่าย (p)</strong>{" "}
                คือสัดส่วนของผู้ที่ตอบข้อสอบข้อนั้นถูก จากจำนวนผู้สอบทั้งหมด
                ยิ่งค่าเข้าใกล้ 1 แปลว่าง่าย ยิ่งเข้าใกล้ 0 แปลว่ายาก
              </p>
              <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 shadow-sm">
                <h4 className="font-bold text-slate-800 mb-3 text-base">
                  เกณฑ์การพิจารณา:
                </h4>
                <ul className="space-y-3">
                  <li className="flex items-start gap-3">
                    <i className="fa-solid fa-circle-xmark text-rose-500 mt-0.5 text-lg"></i>
                    <div>
                      <span className="font-bold text-slate-800">
                        0.80 - 1.00
                      </span>{" "}
                      : ข้อสอบง่ายเกินไป (ควรปรับปรุง)
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <i className="fa-solid fa-circle-check text-emerald-500 mt-0.5 text-lg"></i>
                    <div>
                      <span className="font-bold text-slate-800">
                        0.40 - 0.79
                      </span>{" "}
                      : ข้อสอบมีความยากง่ายเหมาะสม <strong>(เก็บไว้ใช้)</strong>
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <i className="fa-solid fa-circle-xmark text-rose-500 mt-0.5 text-lg"></i>
                    <div>
                      <span className="font-bold text-slate-800">
                        0.00 - 0.39
                      </span>{" "}
                      : ข้อสอบยากเกินไป (ควรปรับปรุง)
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          )}

          {infoModal.type === "D" && (
            <div className="space-y-4">
              <p className="text-base text-slate-600">
                <strong>ค่าอำนาจจำแนก (D)</strong>{" "}
                คือความสามารถของข้อสอบในการแยกแยะกลุ่มผู้ที่ได้คะแนนสูง
                (เด็กเก่ง) ออกจากกลุ่มผู้ที่ได้คะแนนต่ำ (เด็กอ่อน)
              </p>
              <div className="bg-slate-50 p-4 rounded-lg border border-slate-200 shadow-sm">
                <h4 className="font-bold text-slate-800 mb-3 text-base">
                  เกณฑ์การพิจารณา:
                </h4>
                <ul className="space-y-3">
                  <li className="flex items-start gap-3">
                    <i className="fa-solid fa-circle-check text-emerald-500 mt-0.5 text-lg"></i>
                    <div>
                      <span className="font-bold text-slate-800">
                        0.40 ขึ้นไป
                      </span>{" "}
                      : ดีมาก สามารถจำแนกเด็กเก่ง/อ่อนได้ชัดเจน{" "}
                      <strong>(เก็บไว้ใช้)</strong>
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <i className="fa-solid fa-circle-exclamation text-amber-500 mt-0.5 text-lg"></i>
                    <div>
                      <span className="font-bold text-slate-800">
                        0.20 - 0.39
                      </span>{" "}
                      : พอใช้ (ควรพิจารณาปรับปรุงตัวเลือก)
                    </div>
                  </li>
                  <li className="flex items-start gap-3">
                    <i className="fa-solid fa-circle-xmark text-rose-500 mt-0.5 text-lg"></i>
                    <div>
                      <span className="font-bold text-slate-800">
                        ต่ำกว่า 0.20
                      </span>{" "}
                      : ไม่ดี ไม่สามารถจำแนกเด็กได้ หรือมีโอกาสเฉลยผิด
                      (ควรตัดทิ้ง)
                    </div>
                  </li>
                </ul>
              </div>
            </div>
          )}

          <div className="mt-8 flex justify-end">
            <button
              onClick={() => setInfoModal({ ...infoModal, isOpen: false })}
              className="bg-blue-600 hover:bg-blue-700 text-white px-5 py-2.5 rounded-lg font-bold transition-colors shadow-sm"
            >
              เข้าใจแล้ว
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
