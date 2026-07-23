import { useState } from "react";
import {
  DataTable,
  GhostButton,
  PrimaryButton,
  Icon,
  Select,
  Swal,
  StatCard,
} from "../ui.jsx";

export function ReportsPage({ data }) {
  const [selectedSubject, setSelectedSubject] = useState("");

  const rows = data.exams.map((exam) => {
    const subject = data.subjects?.find(
      (s) =>
        s.id === exam.subjectCode ||
        s.code === exam.subjectCode ||
        s.id === exam.code ||
        s.code === exam.code ||
        s.id === exam.subject ||
        s.code === exam.subject,
    );
    const subjectName = subject
      ? `${subject.code} ${subject.name}`
      : exam.subject || "ไม่ระบุวิชา";
    const results = data.results.filter((result) => result.examId === exam.id);
    const scores = results
      .map((r) => Number(r.score || 0))
      .sort((a, b) => a - b);

    const average = scores.length
      ? scores.reduce((sum, score) => sum + score, 0) / scores.length
      : 0;

    let median = 0;
    if (scores.length > 0) {
      const mid = Math.floor(scores.length / 2);
      median =
        scores.length % 2 !== 0
          ? scores[mid]
          : (scores[mid - 1] + scores[mid]) / 2;
    }

    let mode = 0;
    if (scores.length > 0) {
      const counts = {};
      let maxCount = 0;
      scores.forEach((s) => {
        counts[s] = (counts[s] || 0) + 1;
        if (counts[s] > maxCount) {
          maxCount = counts[s];
          mode = s;
        }
      });
    }

    const maxScore = scores.length > 0 ? Math.max(...scores) : 0;
    const minScore = scores.length > 0 ? Math.min(...scores) : 0;

    const sectionName =
      exam.section === "All Section" || !exam.section
        ? "All Section"
        : data.sections?.find((s) => String(s.id) === String(exam.section))
            ?.sec || exam.section;

    return {
      ...exam,
      subjectKey: subject?.id || subject?.code || exam.subject || "",
      subjectName,
      sectionName,
      participantCount: results.length,
      average,
      median,
      mode,
      maxScore,
      minScore,
    };
  });

  const reportRows = selectedSubject
    ? rows.filter((row) => row.subjectKey === selectedSubject)
    : rows;

  const totalExams = reportRows.length;
  const totalParticipants = reportRows.reduce(
    (sum, r) => sum + r.participantCount,
    0,
  );

  function exportReport(format) {
    if (!reportRows.length) {
      return Swal().fire(
        "ไม่มีข้อมูล",
        selectedSubject
          ? "ยังไม่มีข้อมูลข้อสอบของรายวิชาที่เลือก"
          : "ยังไม่มีข้อมูลข้อสอบในระบบ",
        "warning",
      );
    }
    const exportRows = reportRows.map((row, index) => ({
      ลำดับ: index + 1,
      ข้อสอบ: row.name,
      รายวิชา: row.subjectName,
      กลุ่มเรียน: row.sectionName,
      จำนวนผู้สอบ: row.participantCount,
      คะแนนเต็ม: row.questions || 0,
      คะแนนเฉลี่ย: row.average.toFixed(2),
      มัธยฐาน: row.median.toFixed(2),
      ฐานนิยม: row.mode,
      "สูงสุด/ต่ำสุด": `${row.maxScore}/${row.minScore}`,
    }));
    const ws = window.XLSX.utils.json_to_sheet(exportRows);
    const wb = window.XLSX.utils.book_new();
    window.XLSX.utils.book_append_sheet(wb, ws, "Report");
    const subjectSuffix = selectedSubject ? `_${selectedSubject}` : "_all";
    window.XLSX.writeFile(
      wb,
      `Exam_Report${subjectSuffix}_${new Date().toISOString().split("T")[0]}.${format === "csv" ? "csv" : "xlsx"}`,
    );
  }

  return (
    <div className="page-enter mx-auto max-w-[1600px] space-y-6 px-4 pb-20">
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between mb-2">
        <div>
          <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl">
            รายงานผลการตรวจทั้งหมด
          </h2>
          <p className="mt-2 text-sm text-slate-500">
            สรุปข้อมูลผู้เข้าสอบและคะแนนเฉลี่ยของทุกรายวิชา พร้อมส่งออกรายงาน
          </p>
        </div>
        <div className="flex flex-wrap gap-2 items-end">
          <div className="min-w-60">
            <label className="mb-1.5 block text-xs font-bold text-slate-500 uppercase tracking-wider">
              รายวิชาที่ต้องการส่งออก
            </label>
            <Select
              value={selectedSubject}
              onChange={(e) => setSelectedSubject(e.target.value)}
              className="w-full bg-white text-slate-900 border-slate-200"
            >
              <option value="">ทุกรายวิชา</option>
              {data.subjects.map((subject) => (
                <option key={subject.id} value={subject.id}>
                  {subject.code} {subject.name}
                </option>
              ))}
            </Select>
          </div>
          <GhostButton
            variant="success"
            onClick={() => exportReport("xlsx")}
            className="print:hidden"
          >
            <Icon name="fa-file-excel" /> ส่งออก Excel
          </GhostButton>
          <GhostButton
            variant="primary"
            onClick={() => exportReport("csv")}
            className="print:hidden"
          >
            <Icon name="fa-file-csv" /> ส่งออก CSV
          </GhostButton>
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <StatCard
          title="จำนวนข้อสอบทั้งหมด"
          value={totalExams}
          icon="fa-file-lines"
          color="violet"
        />
        <StatCard
          title="ยอดผู้เข้าสอบทั้งหมด"
          value={totalParticipants}
          icon="fa-users"
          color="indigo"
        />
      </div>

      <section className="space-y-4 mt-6">
        <div>
          <h2 className="text-xl font-bold text-slate-900">
            ตารางสรุปผลรายข้อสอบ
          </h2>
          <p className="mt-1 text-sm text-slate-500">
            ข้อมูลสรุปผู้เข้าสอบและคะแนนเฉลี่ยในแต่ละชุดข้อสอบ
          </p>
        </div>

        <DataTable
          columns={[
            {
              key: "name",
              label: "ข้อสอบ",
              className: "w-[120px] sm:w-[150px] md:w-[180px] text-left",
              truncate: false,
              render: (row) => (
                <div
                  className="font-bold text-slate-800 truncate w-[120px] sm:w-[150px] md:w-[180px] text-left py-2"
                  title={row.name}
                >
                  {row.name}
                </div>
              ),
            },
            {
              key: "subject",
              label: "ชื่อวิชา",
              className: "w-[100px] sm:w-[130px] md:w-[160px] text-left",
              truncate: false,
              render: (row) => (
                <div
                  className="text-sm font-semibold text-slate-700 w-full truncate text-left"
                  title={row.subjectName}
                >
                  {row.subjectName}
                </div>
              ),
            },
            {
              key: "section",
              label: "กลุ่มเรียน",
              className: "text-center",
              render: (row) => (
                <span className="font-medium text-slate-600">
                  {row.sectionName}
                </span>
              ),
            },
            {
              key: "participantCount",
              label: "จำนวนผู้สอบ",
              className: "text-center",
              render: (row) => (
                <span className="flex items-center justify-center gap-1.5 font-medium text-slate-700">
                  <Icon name="fa-user" className="text-slate-400 text-[10px]" />{" "}
                  {row.participantCount}
                </span>
              ),
            },
            {
              key: "totalScore",
              label: "คะแนนเต็ม",
              className: "text-center",
              render: (row) => (
                <span className="font-bold text-blue-600">
                  {row.questions || "-"}
                </span>
              ),
            },
            {
              key: "average",
              label: "คะแนนเฉลี่ย",
              className: "text-center",
              render: (row) => (
                <span className="font-semibold text-slate-700">
                  {row.average.toFixed(2)}
                </span>
              ),
            },
            {
              key: "median",
              label: "มัธยฐาน",
              className: "text-center",
              render: (row) => (
                <span className="font-semibold text-slate-700">
                  {row.median.toFixed(2)}
                </span>
              ),
            },
            {
              key: "mode",
              label: "ฐานนิยม",
              className: "text-center",
              render: (row) => (
                <span className="font-semibold text-slate-700">{row.mode}</span>
              ),
            },
            {
              key: "maxmin",
              label: "สูงสุด/ต่ำสุด",
              className: "text-center",
              render: (row) => (
                <span className="font-semibold text-slate-600">
                  <span className="text-emerald-600">{row.maxScore}</span> /{" "}
                  <span className="text-rose-600">{row.minScore}</span>
                </span>
              ),
            },
          ]}
          rows={reportRows}
          emptyText={
            selectedSubject
              ? "ยังไม่มีรายงานผลการตรวจของรายวิชาที่เลือก"
              : "ยังไม่มีรายงานผลการตรวจ"
          }
        />
      </section>
    </div>
  );
}
