import { useMemo, useRef } from "react";
import { StatCard, pct, useChart, formatThaiDate } from "../ui.jsx";

export function Dashboard({ data, navigate }) {
  const canvasRef = useRef(null);

  const hasData = data.results.length > 0;

  const { averages, passCount, flaggedCount, recentResults } = useMemo(() => {
    const grouped = {};
    let passed = 0;
    let flagged = 0;

    data.results.forEach((result) => {
      const exam = data.exams.find((item) => item.id === result.examId);
      if (!exam) return;

      const percent = pct(result.score, exam.questions);
      if (percent >= 50) passed++;
      if (result.flagged) flagged++;

      const key = exam.name || "ไม่ระบุการสอบ";
      if (!grouped[key]) grouped[key] = [];
      grouped[key].push(percent);
    });

    const avg = Object.entries(grouped).map(([name, scores]) => ({
      name,
      average: scores.reduce((sum, score) => sum + score, 0) / scores.length,
    }));

    // Sort recent by createdAt, fallback to just reverse if not available
    const sorted = [...data.results].sort((a, b) => {
      const ta = new Date(a.createdAt || a.created_at || 0).getTime();
      const tb = new Date(b.createdAt || b.created_at || 0).getTime();
      return tb - ta;
    });

    return {
      averages: avg,
      passCount: passed,
      flaggedCount: flagged,
      recentResults: sorted.slice(0, 8),
    };
  }, [data.exams, data.results]);

  useChart(
    canvasRef,
    {
      type: "bar",
      data: {
        labels: averages.length
          ? averages.map((item) => item.name)
          : ["ยังไม่มีข้อมูล"],
        datasets: [
          {
            label: "คะแนนเฉลี่ย (%)",
            data: averages.length ? averages.map((item) => item.average) : [0],
            backgroundColor: "rgba(59, 130, 246, 0.85)",
            hoverBackgroundColor: "rgba(37, 99, 235, 1)",
            borderRadius: 8,
            borderSkipped: false,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            max: 100,
            grid: { color: "#f1f5f9" },
          },
          x: {
            grid: { display: false },
          },
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "rgba(15, 23, 42, 0.9)",
            padding: 12,
            titleFont: { size: 14, family: "'Prompt', sans-serif" },
            bodyFont: { size: 14, family: "'Prompt', sans-serif" },
            cornerRadius: 8,
          },
        },
      },
    },
    [averages],
  );

  if (!hasData && data.subjects.length === 0) {
    return (
      <div className="page-enter max-w-[1600px] mx-auto px-4 py-12 flex flex-col items-center justify-center min-h-[60vh] text-center">
        <div className="w-24 h-24 bg-blue-50 text-blue-500 rounded-full flex items-center justify-center mb-6 shadow-sm border border-blue-100">
          <i className="fa-solid fa-box-open text-4xl"></i>
        </div>
        <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight mb-2">
          ยินดีต้อนรับสู่ระบบตรวจข้อสอบ
        </h2>
        <p className="text-slate-500 mb-8 max-w-md">
          ดูเหมือนว่าคุณยังไม่มีข้อมูลรายวิชาในระบบ
          ลองเพิ่มรายวิชาและเริ่มต้นสร้างการสอบของคุณได้เลย
        </p>
        <button
          onClick={() => navigate("subjects")}
          className="px-6 py-3 bg-blue-600 text-white rounded-xl font-semibold shadow-sm hover:bg-blue-700 transition-colors"
        >
          <i className="fa-solid fa-plus mr-2"></i> สร้างรายวิชาแรก
        </button>
      </div>
    );
  }

  return (
    <div className="page-enter max-w-[1600px] mx-auto space-y-4 flex flex-col min-h-[calc(100vh-105px)] lg:h-[calc(100vh-137px)] overflow-y-auto lg:overflow-hidden pb-6 lg:pb-0">
      {/* Stat Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-3 sm:gap-4 shrink-0">
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
          color="indigo"
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
          color="emerald"
        />

        <StatCard
          title="รอตรวจสอบ (Flagged)"
          value={flaggedCount}
          icon="fa-flag"
          color="amber"
        />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-4 flex-1 lg:min-h-0">
        {/* Chart Section */}
        <div className="lg:col-span-2 bg-white p-4 sm:p-5 rounded-2xl shadow-sm border border-slate-200 flex flex-col min-h-[220px] sm:min-h-[300px] lg:min-h-0">
          <div className="flex justify-between items-center mb-2">
            <h3 className="text-lg font-bold text-slate-800">
              คะแนนเฉลี่ยผลสอบ (%)
            </h3>
          </div>
          <div className="relative flex-1 min-h-0">
            {hasData ? (
              <canvas ref={canvasRef} />
            ) : (
              <div className="absolute inset-0 flex flex-col items-center justify-center text-slate-400 bg-slate-50/50 rounded-xl border border-dashed border-slate-200">
                <i className="fa-solid fa-chart-bar text-3xl mb-2"></i>
                <p>ยังไม่มีข้อมูลคะแนน</p>
              </div>
            )}
          </div>
        </div>

        {/* Recent Activity */}
        <div className="lg:col-span-1 bg-white p-5 rounded-2xl shadow-sm border border-slate-200 flex flex-col min-h-0">
          <div className="flex justify-between items-center mb-2">
            <h3 className="text-lg font-bold text-slate-800">สแกนล่าสุด</h3>
            <button
              onClick={() => navigate("results")}
              className="text-sm text-blue-600 hover:text-blue-700 font-semibold"
            >
              ดูทั้งหมด
            </button>
          </div>

          <div className="flex-1 overflow-y-auto pr-1">
            {recentResults.length > 0 ? (
              <div className="space-y-2">
                {recentResults.map((res, i) => {
                  const exam = data.exams.find((e) => e.id === res.examId);
                  const isFlagged = res.flagged;

                  let statusColor = "bg-emerald-100 text-emerald-600";
                  let statusIcon = "fa-check";
                  let statusText = "ตรวจแล้ว";

                  if (isFlagged) {
                    statusColor = "bg-amber-100 text-amber-700";
                    statusIcon = "fa-flag";
                    statusText = "มีปัญหา";
                  }

                  return (
                    <div
                      key={res.id || i}
                      className="flex items-center p-3 rounded-xl hover:bg-slate-50 transition-colors border border-transparent hover:border-slate-100"
                    >
                      <div
                        className={`w-10 h-10 rounded-full flex items-center justify-center shrink-0 mr-3 ${statusColor}`}
                      >
                        <i className={`fa-solid ${statusIcon}`}></i>
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="font-bold text-slate-800 truncate text-sm">
                          {res.studentName ||
                            res.studentCode ||
                            "ไม่ระบุผู้สอบ"}
                        </p>
                        <div className="flex items-center gap-1.5 mt-0.5 text-[11px] text-slate-500 truncate">
                          <span
                            className={`font-semibold ${isFlagged ? "text-amber-600" : "text-emerald-600"}`}
                          >
                            {statusText}
                          </span>
                          <span>•</span>
                          <span>{exam?.subject || "ไม่ระบุวิชา"}</span>
                        </div>
                      </div>
                      <div className="text-right ml-3 flex flex-col items-end">
                        <p className="font-black text-slate-800 text-sm">
                          {res.score}
                          <span className="text-slate-400 font-semibold text-xs">
                            /{res.total}
                          </span>
                        </p>
                        <p className="text-[10px] text-slate-400 font-medium">
                          {formatThaiDate(res.createdAt || res.created_at)}
                        </p>
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center h-full text-slate-400 py-12 bg-slate-50/50 rounded-xl border border-dashed border-slate-200">
                <i className="fa-solid fa-clock-rotate-left text-3xl mb-2"></i>
                <p>ยังไม่มีประวัติการสแกน</p>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
