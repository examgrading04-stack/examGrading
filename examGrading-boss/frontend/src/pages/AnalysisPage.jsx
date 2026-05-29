import { useRef, useState } from "react";
import { DataTable, Select, StatCard, useChart } from "../ui.jsx";

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
  const canvasRef = useRef(null);
  const canvasRefPie = useRef(null);
  const exam = data.exams.find((item) => item.id === examId);

  const results = data.results
    .filter((result) => !examId || result.examId === examId)
    .map((row) => {
      let dynamicScore = row.score || 0;
      const questionsCount = Number(exam?.questions || row.totalQuestions || 0);
      let calculatedItemResults = row.itemResults || {};

      if (exam && (row.answers || row.itemResults)) {
        let calculatedScore = 0;
        let newItemResults = {};
        for (let i = 1; i <= questionsCount; i++) {
          const qStr = String(i);
          const correctAns = getCorrectAnswer(exam, qStr);

          let isCorrect = false;
          if (row.answers) {
            isCorrect = row.answers[qStr] === correctAns && correctAns !== "-";
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
    : 0;
  const median = scores.length
    ? scores.length % 2
      ? scores[Math.floor(scores.length / 2)]
      : (scores[scores.length / 2 - 1] + scores[scores.length / 2]) / 2
    : 0;
  const itemAnalysis = calculateItemAnalysis(results, exam);
  const answeredItemAnalysis = itemAnalysis.filter((item) =>
    results.some((result) => result.itemResults?.[item.question] !== undefined),
  );
  const avgDifficulty = answeredItemAnalysis.length
    ? answeredItemAnalysis.reduce((sum, item) => sum + item.difficulty, 0) /
      answeredItemAnalysis.length
    : 0;
  const avgDiscrimination = answeredItemAnalysis.length
    ? answeredItemAnalysis.reduce((sum, item) => sum + item.discrimination, 0) /
      answeredItemAnalysis.length
    : 0;
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
          <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl">
            ภาพรวมสถิติและคุณภาพข้อสอบ
            {exam?.section && (
              <span className="ml-3 rounded-full bg-slate-100 px-3 py-1 text-sm font-black uppercase text-slate-600 border border-slate-200">
                Sec {exam.section}
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
          title="จำนวนผลการตรวจ"
          value={results.length}
          icon="fa-users"
          color="blue"
        />
        <StatCard
          title="คะแนนเฉลี่ย"
          value={mean.toFixed(2)}
          icon="fa-chart-simple"
          color="green"
        />
        <StatCard
          title="มัธยฐาน"
          value={median.toFixed(2)}
          icon="fa-scale-balanced"
          color="violet"
        />
        <StatCard
          title="p เฉลี่ย"
          value={avgDifficulty.toFixed(2)}
          icon="fa-percent"
          color="amber"
        />
        <StatCard
          title="D เฉลี่ย"
          value={avgDiscrimination.toFixed(2)}
          icon="fa-bullseye"
          color="green"
        />
      </div>

      <section className="grid gap-6 xl:grid-cols-[1fr_24rem]">
        <div className="relative overflow-hidden rounded-2xl border border-slate-200/80 bg-white p-6 shadow-xl shadow-slate-200/40">
          <div className="absolute left-0 top-0 h-1 w-full bg-gradient-to-r from-blue-500 to-indigo-500"></div>
          <div className="flex flex-wrap items-start justify-between gap-4">
            <div className="flex gap-4">
              <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-blue-50 text-xl text-blue-600 shadow-inner">
                <i className="fa-solid fa-chart-column" />
              </div>
              <div>
                <h3 className="text-lg font-extrabold text-slate-800">
                  ระดับความยากง่ายรายข้อ (p)
                </h3>
                <p className="mt-1 text-sm font-medium text-slate-500">
                  สัดส่วนเปอร์เซ็นต์ผู้เรียนที่ตอบถูกในแต่ละข้อ
                </p>
              </div>
            </div>
            <div className="flex shrink-0 items-center gap-4 rounded-xl border border-emerald-100 bg-emerald-50/50 px-4 py-3">
              <div>
                <p className="text-[10px] font-black uppercase tracking-widest text-emerald-600 text-right">
                  คะแนนเฉลี่ย
                </p>
                <p className="text-xs font-semibold text-emerald-700/80 text-right">
                  ผู้เข้าสอบ {results.length} คน
                </p>
              </div>
              <div className="text-3xl font-black text-emerald-600">
                {results.length ? mean.toFixed(2) : "-"}
              </div>
            </div>
          </div>
          <div className="mt-8 relative h-72 w-full overflow-x-auto overflow-y-hidden rounded-xl border border-slate-100 bg-slate-50/30 p-2">
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

        <div className="relative overflow-hidden rounded-2xl border border-slate-200/80 bg-white p-6 shadow-xl shadow-slate-200/40 flex flex-col">
          <div className="absolute left-0 top-0 h-1 w-full bg-gradient-to-r from-indigo-500 to-violet-500"></div>
          <div className="flex gap-4">
            <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-indigo-50 text-xl text-indigo-600 shadow-inner">
              <i className="fa-solid fa-chart-pie" />
            </div>
            <div>
              <h3 className="text-lg font-extrabold text-slate-800">
                สัดส่วนคุณภาพ (D)
              </h3>
              <p className="mt-1 text-sm font-medium text-slate-500">
                คัดกรองจากค่าอำนาจจำแนก
              </p>
            </div>
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

      <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="flex items-center gap-2 mb-4 font-bold text-slate-800">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-blue-50 text-blue-600">
            <i className="fa-solid fa-circle-info" />
          </div>
          <span>เกณฑ์การแปลความหมายคุณภาพข้อสอบ</span>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {/* p Box */}
          <div className="rounded-xl border border-blue-100 bg-blue-50/30 overflow-hidden">
            <div className="bg-blue-100/50 px-4 py-2 flex items-center gap-2 border-b border-blue-100">
              <span className="flex h-6 w-6 items-center justify-center rounded-md bg-white font-black text-blue-700 shadow-sm border border-blue-200 text-xs">
                p
              </span>
              <span className="font-bold text-sm text-blue-900">
                ค่าความยากง่าย (Difficulty)
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
          <div className="rounded-xl border border-emerald-100 bg-emerald-50/30 overflow-hidden">
            <div className="bg-emerald-100/50 px-4 py-2 flex items-center gap-2 border-b border-emerald-100">
              <span className="flex h-6 w-6 items-center justify-center rounded-md bg-white font-black text-emerald-700 shadow-sm border border-emerald-200 text-xs">
                D
              </span>
              <span className="font-bold text-sm text-emerald-900">
                ค่าอำนาจจำแนก (Discrimination)
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

      <section className="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
        <div className="mb-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-lg font-bold text-slate-900">
              วิเคราะห์คุณภาพข้อสอบรายข้อ
            </h2>
            <p className="text-sm text-slate-500 mt-1">
              ค่าความยากง่ายเฉลี่ย {avgDifficulty.toFixed(2)} ·
              ค่าอำนาจจำแนกเฉลี่ย {avgDiscrimination.toFixed(2)}
            </p>
          </div>
          <div className="flex flex-wrap gap-2 text-sm text-slate-500">
            <span className="rounded-full bg-slate-100 px-3 py-1">
              คะแนนเฉลี่ย {mean.toFixed(2)}
            </span>
          </div>
        </div>

        <DataTable
          columns={[
            { key: "question", label: "ข้อ" },
            {
              key: "answer",
              label: "เฉลย",
              render: (row) => (
                <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-slate-100 text-[11px] font-black text-slate-700 border border-slate-200">
                  {row.answer}
                </span>
              ),
            },
            {
              key: "correctCount",
              label: "ตอบถูก",
              render: (row) => `${row.correctCount}/${results.length}`,
            },
            {
              key: "difficulty",
              label: "ค่าความยากง่าย",
              render: (row) => row.difficulty.toFixed(2),
            },
            {
              key: "difficultyLabel",
              label: "ระดับ",
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
              render: (row) => row.discrimination.toFixed(2),
            },
            {
              key: "discriminationLabel",
              label: "แปลผล",
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
    </div>
  );
}
