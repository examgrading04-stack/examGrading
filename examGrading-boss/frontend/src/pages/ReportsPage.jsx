import { DataTable, GhostButton, Icon, Swal, StatCard } from "../ui.jsx";

export function ReportsPage({ data }) {
  const rows = data.exams.map((exam) => {
    const subject = data.subjects?.find(
      (s) => s.id === exam.subject || s.code === exam.subject,
    );
    const subjectName = subject
      ? `${subject.code} ${subject.name}`
      : exam.subject || "ไม่ระบุวิชา";
    const results = data.results.filter((result) => result.examId === exam.id);
    const average = results.length
      ? results.reduce((sum, result) => sum + Number(result.score || 0), 0) /
        results.length
      : 0;
    return {
      ...exam,
      subjectName,
      participantCount: results.length,
      average,
    };
  });

  const totalExams = rows.length;
  const totalParticipants = rows.reduce(
    (sum, r) => sum + r.participantCount,
    0,
  );

  function exportReport(format) {
    if (!rows.length) {
      return Swal().fire(
        "ไม่มีข้อมูล",
        "ยังไม่มีข้อมูลข้อสอบในระบบ",
        "warning",
      );
    }
    const reportRows = rows.map((row, index) => ({
      ลำดับ: index + 1,
      ข้อสอบ: row.name,
      รายวิชา: row.subjectName,
      จำนวนผู้สอบ: row.participantCount,
      คะแนนเฉลี่ย: row.average.toFixed(2),
    }));
    const ws = window.XLSX.utils.json_to_sheet(reportRows);
    const wb = window.XLSX.utils.book_new();
    window.XLSX.utils.book_append_sheet(wb, ws, "Report");
    window.XLSX.writeFile(
      wb,
      `Exam_Report_${new Date().toISOString().split("T")[0]}.${format === "csv" ? "csv" : "xlsx"}`,
    );
  }

  return (
    <div className="page-enter mx-auto max-w-[1600px] space-y-6 px-4 pb-20">
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between mb-2">
        <div>
          <div className="mb-2 inline-flex items-center gap-2 rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold text-blue-600 border border-blue-100">
            <i className="fa-solid fa-chart-line" />
            <span>รายงานและสถิติ</span>
          </div>
          <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl">
            รายงานผลการตรวจทั้งหมด
          </h2>
          <p className="mt-2 text-sm text-slate-500">
            สรุปข้อมูลผู้เข้าสอบและคะแนนเฉลี่ยของทุกรายวิชา พร้อมส่งออกรายงาน
          </p>
        </div>
        <div className="flex flex-wrap gap-2">
          <GhostButton variant="success" onClick={() => exportReport("xlsx")}>
            <Icon name="fa-file-excel" /> ส่งออก Excel
          </GhostButton>
          <GhostButton variant="primary" onClick={() => exportReport("csv")}>
            <Icon name="fa-file-csv" /> ส่งออก CSV
          </GhostButton>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <StatCard
          title="จำนวนข้อสอบทั้งหมด"
          value={totalExams}
          icon="fa-file-lines"
          color="blue"
        />
        <StatCard
          title="ยอดผู้เข้าสอบทั้งหมด"
          value={totalParticipants}
          icon="fa-users"
          color="violet"
        />
      </div>

      <section className="rounded-2xl border border-slate-200/80 bg-white p-6 shadow-xl shadow-slate-200/40 relative overflow-hidden">
        <div className="absolute left-0 top-0 h-1 w-full bg-gradient-to-r from-blue-500 to-emerald-500"></div>
        <div className="mb-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-slate-50 text-slate-500 border border-slate-100">
              <i className="fa-solid fa-table" />
            </div>
            <div>
              <h2 className="text-lg font-bold text-slate-900">
                ตารางสรุปผลรายข้อสอบ
              </h2>
              <p className="text-sm text-slate-500 mt-0.5">
                ข้อมูลสรุปผู้เข้าสอบและคะแนนเฉลี่ยในแต่ละชุดข้อสอบ
              </p>
            </div>
          </div>
        </div>

        <DataTable
          columns={[
            {
              key: "name",
              label: "ข้อสอบ",
              render: (row) => (
                <span className="font-bold text-slate-800">{row.name}</span>
              ),
            },
            {
              key: "subject",
              label: "รายวิชา",
              render: (row) => (
                <span className="inline-flex rounded-md border border-slate-200 bg-slate-50 px-2 py-1 text-xs font-semibold text-slate-600">
                  {row.subjectName}
                </span>
              ),
            },
            {
              key: "participantCount",
              label: "จำนวนผู้สอบ",
              render: (row) => (
                <span className="flex items-center gap-1.5 font-medium text-slate-700">
                  <Icon name="fa-user" className="text-slate-400 text-xs" />{" "}
                  {row.participantCount} คน
                </span>
              ),
            },
            {
              key: "average",
              label: "คะแนนเฉลี่ย",
              render: (row) => (
                <span className="font-bold text-slate-700">
                  {row.average.toFixed(2)}
                </span>
              ),
            },
          ]}
          rows={rows}
          emptyText="ยังไม่มีรายงานผลการตรวจ"
        />
      </section>
    </div>
  );
}
