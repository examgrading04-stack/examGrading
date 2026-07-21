import { useMemo, useRef } from "react";
import { StatCard, pct, useChart } from "../ui.jsx";

export function Dashboard({ data }) {
  const canvasRef = useRef(null);
  const averages = useMemo(() => {
    const grouped = {};
    data.results.forEach((result) => {
      const exam = data.exams.find((item) => item.id === result.examId);
      if (!exam) return;
      const key = exam.subject || "ไม่ระบุวิชา";
      if (!grouped[key]) grouped[key] = [];
      grouped[key].push(pct(result.score, exam.questions));
    });
    return Object.entries(grouped).map(([subject, scores]) => ({
      subject,
      average: scores.reduce((sum, score) => sum + score, 0) / scores.length,
    }));
  }, [data.exams, data.results]);

  useChart(
    canvasRef,
    {
      type: "bar",
      data: {
        labels: averages.length
          ? averages.map((item) => item.subject)
          : ["ยังไม่มีข้อมูล"],
        datasets: [
          {
            label: "คะแนนเฉลี่ย (%)",
            data: averages.length ? averages.map((item) => item.average) : [0],
            backgroundColor: "#3b82f6",
            borderRadius: 8,
          },
        ],
      },
      options: {
        responsive: true,
        scales: { y: { beginAtZero: true, max: 100 } },
        plugins: { legend: { display: false } },
      },
    },
    [averages],
  );

  return (
    <div className="page-enter max-w-[1600px] mx-auto px-4 space-y-8">
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-6">
        <StatCard
          title="รายวิชาทั้งหมด"
          value={data.subjects.length}
          icon="fa-book"
          color="blue"
        />
        <StatCard
          title="ผู้เรียนทั้งหมด"
          value={data.students.length}
          icon="fa-users"
          color="green"
        />
        <StatCard
          title="ข้อสอบในระบบ"
          value={data.exams.length}
          icon="fa-file-lines"
          color="violet"
        />
        <StatCard
          title="การสอบที่ประมวลผล"
          value={data.results.length}
          icon="fa-clipboard-check"
          color="amber"
        />
      </div>
      <section className="bg-white p-6 rounded-md shadow-sm border border-slate-200 border-t-4 border-t-blue-600">
        <h3 className="text-lg font-bold mb-4">กราฟสรุปผลการสอบ</h3>
        <canvas ref={canvasRef} height="100" />
      </section>
    </div>
  );
}
