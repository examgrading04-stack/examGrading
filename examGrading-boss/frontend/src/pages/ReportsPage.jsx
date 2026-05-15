import { DataTable, GhostButton, Icon, Swal, pct } from "../ui.jsx";

export function ReportsPage({ data }) {
  const rows = data.exams.map((exam) => {
    const results = data.results.filter((result) => result.examId === exam.id);
    const average = results.length ? results.reduce((sum, result) => sum + Number(result.score || 0), 0) / results.length : 0;
    const passCount = results.filter((result) => pct(result.score, exam.questions) >= 50).length;
    return { ...exam, participantCount: results.length, average, passRate: results.length ? Math.round((passCount / results.length) * 100) : 0 };
  });

  function exportReport(format) {
    if (!rows.length) return Swal().fire("ไม่มีข้อมูล", "ยังไม่มีข้อมูลข้อสอบในระบบ", "warning");
    const reportRows = rows.map((row, index) => ({
      ลำดับ: index + 1,
      ข้อสอบ: row.name,
      รายวิชา: row.subject,
      จำนวนผู้สอบ: row.participantCount,
      คะแนนเฉลี่ย: row.average.toFixed(2),
      อัตราผ่าน: `${row.passRate}%`,
    }));
    const ws = window.XLSX.utils.json_to_sheet(reportRows);
    const wb = window.XLSX.utils.book_new();
    window.XLSX.utils.book_append_sheet(wb, ws, "Report");
    window.XLSX.writeFile(wb, `Exam_Report_${new Date().toISOString().split("T")[0]}.${format === "csv" ? "csv" : "xlsx"}`);
  }

  return (
    <div className="page-enter space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <h3 className="text-xl font-extrabold">รายงานผล</h3>
        <div className="flex gap-2">
          <GhostButton onClick={() => exportReport("xlsx")}><Icon name="fa-file-excel" /> Excel</GhostButton>
          <GhostButton onClick={() => exportReport("csv")}><Icon name="fa-file-csv" /> CSV</GhostButton>
        </div>
      </div>
      <DataTable
        columns={[
          { key: "name", label: "ข้อสอบ" },
          { key: "subject", label: "รายวิชา" },
          { key: "participantCount", label: "จำนวนผู้สอบ" },
          { key: "average", label: "คะแนนเฉลี่ย", render: (row) => row.average.toFixed(2) },
          { key: "passRate", label: "อัตราผ่าน", render: (row) => `${row.passRate}%` },
        ]}
        rows={rows}
        emptyText="ยังไม่มีรายงาน"
      />
    </div>
  );
}



