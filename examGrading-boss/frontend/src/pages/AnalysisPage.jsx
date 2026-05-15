import { useRef, useState } from "react";
import { Field, Select, StatCard, pct, useChart } from "../ui.jsx";

export function AnalysisPage({ data }) {
  const [examId, setExamId] = useState(data.exams[0]?.id || "");
  const canvasRef = useRef(null);
  const results = data.results.filter((result) => !examId || result.examId === examId);
  const exam = data.exams.find((item) => item.id === examId);
  const scores = results.map((result) => Number(result.score || 0)).sort((a, b) => a - b);
  const mean = scores.length ? scores.reduce((sum, score) => sum + score, 0) / scores.length : 0;
  const median = scores.length ? (scores.length % 2 ? scores[Math.floor(scores.length / 2)] : (scores[scores.length / 2 - 1] + scores[scores.length / 2]) / 2) : 0;
  const sd = scores.length ? Math.sqrt(scores.map((score) => (score - mean) ** 2).reduce((sum, value) => sum + value, 0) / scores.length) : 0;
  const distribution = [0, 0, 0, 0, 0];
  results.forEach((result) => {
    const percentage = pct(result.score, exam?.questions);
    distribution[Math.min(4, Math.floor(percentage / 20))] += 1;
  });

  useChart(
    canvasRef,
    {
      type: "bar",
      data: { labels: ["0-20", "21-40", "41-60", "61-80", "81-100"], datasets: [{ label: "จำนวนผู้เรียน", data: distribution, backgroundColor: ["#ef4444", "#f97316", "#eab308", "#22c55e", "#3b82f6"], borderRadius: 8 }] },
      options: { responsive: true, plugins: { legend: { display: false } }, scales: { y: { beginAtZero: true, ticks: { precision: 0 } } } },
    },
    [examId, data.results, data.exams],
  );

  return (
    <div className="page-enter space-y-6">
      <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm max-w-xl">
        <Field label="เลือกข้อสอบ">
          <Select value={examId} onChange={(e) => setExamId(e.target.value)}>
            <option value="">ทุกข้อสอบ</option>
            {data.exams.map((item) => <option key={item.id} value={item.id}>{item.name} ({item.subject})</option>)}
          </Select>
        </Field>
      </div>
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
        <StatCard title="จำนวนผลสอบ" value={results.length} icon="fa-users" color="blue" />
        <StatCard title="คะแนนเฉลี่ย" value={mean.toFixed(2)} icon="fa-chart-simple" color="green" />
        <StatCard title="มัธยฐาน" value={median.toFixed(2)} icon="fa-scale-balanced" color="violet" />
        <StatCard title="ส่วนเบี่ยงเบน" value={sd.toFixed(2)} icon="fa-wave-square" color="amber" />
      </div>
      <section className="bg-white p-6 rounded-2xl shadow-sm border border-slate-200">
        <h3 className="text-lg font-bold mb-4">การกระจายคะแนน</h3>
        <canvas ref={canvasRef} height="110" />
      </section>
    </div>
  );
}


