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

function getExamTotalScore(exam) {
  if (!exam || !exam.answerKey) return Number(exam?.questions || 0);

  let ak = exam.answerKey;
  if (typeof ak === "string") {
    try {
      ak = JSON.parse(ak);
    } catch (e) {
      return Number(exam?.questions || 0);
    }
  }
  if (typeof ak !== "object" || ak === null)
    return Number(exam?.questions || 0);

  let totalScore = 0;
  let hasValidScore = false;

  for (let i = 1; i <= Number(exam.questions || 0); i++) {
    const qStr = String(i);
    let qScore = 1.0;

    if (
      ak[qStr] &&
      typeof ak[qStr] === "object" &&
      ak[qStr].score !== undefined
    ) {
      qScore = Number(ak[qStr].score) || 1.0;
      hasValidScore = true;
    } else {
      let foundNested = false;
      for (const setKey of ["0", "1", "A", "B", ""]) {
        if (ak[setKey] && typeof ak[setKey] === "object") {
          if (
            ak[setKey][qStr] &&
            typeof ak[setKey][qStr] === "object" &&
            ak[setKey][qStr].score !== undefined
          ) {
            qScore = Number(ak[setKey][qStr].score) || 1.0;
            hasValidScore = true;
            foundNested = true;
            break;
          }
        }
      }
      if (!foundNested) {
        const firstSet = Object.values(ak).find(
          (v) =>
            typeof v === "object" &&
            v !== null &&
            Object.keys(v).some((k) => !isNaN(Number(k))),
        );
        if (
          firstSet &&
          firstSet[qStr] &&
          typeof firstSet[qStr] === "object" &&
          firstSet[qStr].score !== undefined
        ) {
          qScore = Number(firstSet[qStr].score) || 1.0;
          hasValidScore = true;
        }
      }
    }
    totalScore += qScore;
  }

  if (!hasValidScore && Object.keys(ak).length === 0)
    return Number(exam?.questions || 0);
  return totalScore;
}

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
      .map((row) => {
        let dynamicScore = row.score || 0;
        const questionsCount = Number(
          exam?.questions || row.totalQuestions || 0,
        );

        if (exam && (row.answers || row.itemResults)) {
          let calculatedScore = 0;
          for (let i = 1; i <= questionsCount; i++) {
            const qStr = String(i);
            const correctAns = getCorrectAnswer(exam, qStr);
            const qScore = getQuestionScore(exam, qStr);

            if (row.answers) {
              if (row.answers[qStr] === correctAns && correctAns !== "-") {
                calculatedScore += qScore;
              }
            } else if (row.itemResults) {
              if (row.itemResults[qStr] === true) {
                calculatedScore += qScore;
              }
            }
          }
          dynamicScore = calculatedScore;
        }
        return Number(dynamicScore);
      })
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

    let mode = "-";
    if (scores.length > 0) {
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
      mode =
        maxCount <= 1 || uniqueCounts.every((c) => c === maxCount)
          ? "ไม่มี"
          : modes.join(", ");
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
      totalMaxScore: getExamTotalScore(exam),
    };
  });

  const availableSubjectsMap = new Map();
  data.subjects?.forEach((s) => {
    availableSubjectsMap.set(s.id, `${s.code} ${s.name}`);
  });
  rows.forEach((row) => {
    if (row.subjectKey && !availableSubjectsMap.has(row.subjectKey)) {
      availableSubjectsMap.set(row.subjectKey, row.subjectName);
    }
  });
  const availableSubjectsList = Array.from(availableSubjectsMap.entries()).map(
    ([key, name]) => ({ key, name }),
  );

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
      คะแนนเต็ม: row.totalMaxScore,
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
          <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
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
              {availableSubjectsList.map((subject) => (
                <option key={subject.key} value={subject.key}>
                  {subject.name}
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
          <h2 className="text-xl font-bold text-slate-900 tracking-tight">
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
                  {row.totalMaxScore.toString().replace(/\.0$/, "")}
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
