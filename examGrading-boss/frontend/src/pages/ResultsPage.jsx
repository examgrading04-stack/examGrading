import { useState, useMemo } from "react";
import { DataTable, Icon, Select, GhostButton, Swal, Modal } from "../ui.jsx";

function getCorrectAnswer(exam, question) {
  if (!exam || !exam.answerKey || typeof exam.answerKey !== "object") return "-";
  if (exam.answerKey["0"] && typeof exam.answerKey["0"][question] === "string") return exam.answerKey["0"][question];
  if (exam.answerKey["1"] && typeof exam.answerKey["1"][question] === "string") return exam.answerKey["1"][question];
  if (typeof exam.answerKey[question] === "string") return exam.answerKey[question];
  const firstSet = Object.values(exam.answerKey).find(v => typeof v === "object");
  if (firstSet && typeof firstSet[question] === "string") return firstSet[question];
  return "-";
}

export function ResultsPage({ data, api, refresh, query }) {
  const [selectedExamId, setSelectedExamId] = useState(query?.examId || "");
  const [selectedResult, setSelectedResult] = useState(null);

  // Filter results based on selected exam
  const filteredResults = useMemo(() => {
    let list = data.results;
    if (selectedExamId) {
      list = list.filter(r => r.examId === selectedExamId);
    }
    return list.map(row => {
      const exam = data.exams.find(e => e.id === row.examId);
      const student = data.students.find(s => s.id === row.studentId || s.code === row.studentCode);
      const questionsCount = Number(exam?.questions || row.totalQuestions || 0);
      
      let dynamicScore = row.score || 0;
      
      // Recalculate score dynamically based on current answer key
      if (exam && (row.answers || row.itemResults)) {
        let calculatedScore = 0;
        for (let i = 1; i <= questionsCount; i++) {
          const qStr = String(i);
          const correctAns = getCorrectAnswer(exam, qStr);
          
          if (row.answers) {
            if (row.answers[qStr] === correctAns && correctAns !== "-") {
              calculatedScore++;
            }
          } else if (row.itemResults) {
            if (row.itemResults[qStr] === true) {
              calculatedScore++;
            }
          }
        }
        dynamicScore = calculatedScore;
      }

      const percentage = questionsCount ? (dynamicScore / questionsCount) * 100 : 0;
      
      return {
        ...row,
        score: dynamicScore,
        totalQuestions: questionsCount,
        percentage,
        isPassed: percentage >= 50,
        examSection: exam?.section || "",
        studentSec: student?.sec || student?.section || ""
      };
    });
  }, [data.results, data.exams, data.students, selectedExamId]);

  // Summary Statistics
  const stats = useMemo(() => {
    if (filteredResults.length === 0) return null;
    const scores = filteredResults.map(r => r.score);
    const avg = scores.reduce((a, b) => a + b, 0) / scores.length;
    const passedCount = filteredResults.filter(r => r.isPassed).length;
    return {
      avg: avg.toFixed(1),
      max: Math.max(...scores),
      min: Math.min(...scores),
      passRate: ((passedCount / filteredResults.length) * 100).toFixed(1),
      count: filteredResults.length
    };
  }, [filteredResults]);

  const currentExam = data.exams.find(e => e.id === selectedExamId);

  return (
    <div className="page-enter max-w-[1600px] mx-auto pb-20 px-4 space-y-6">
      <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between mb-2">
        <div>
          <div className="mb-2 inline-flex items-center gap-2 rounded-full bg-blue-50 px-2.5 py-1 text-xs font-bold text-blue-600 border border-blue-100">
            <i className="fa-solid fa-square-check" />
            <span>ผลการเรียนและคะแนนสอบ</span>
          </div>
          <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl">
            {currentExam ? `ผลการสอบ: ${currentExam.name}` : "ผลการสอบทั้งหมด"}
            {currentExam?.section && (
              <span className="ml-3 rounded-full bg-slate-100 px-3 py-1 text-sm font-black uppercase text-slate-600 border border-slate-200">
                Sec {currentExam.section}
              </span>
            )}
          </h2>
          <p className="mt-2 text-sm text-slate-500">
            {currentExam
              ? `รหัสวิชา ${currentExam.subject} · รายชื่อผู้เข้าสอบและผลคะแนนรายบุคคล`
              : "เลือกข้อสอบเพื่อดูรายละเอียดและสถิติคะแนนแยกตามกลุ่มเรียน"}
          </p>
        </div>
        <div className="w-full sm:w-80 flex flex-col gap-3">
          <div>
            <label className="mb-1.5 block text-xs font-bold text-slate-500 uppercase tracking-wider">เลือกข้อสอบ</label>
            <Select 
              value={selectedExamId} 
              onChange={(e) => setSelectedExamId(e.target.value)} 
              className="w-full bg-white text-slate-900 border-slate-200 focus:border-blue-500 focus:ring-2 focus:ring-blue-100"
            >
              <option value="">ดูผลการสอบทั้งหมด</option>
              {data.exams.map((exam) => (
                <option key={exam.id} value={exam.id}>
                  {exam.subject} {exam.section ? `(Sec ${exam.section})` : ""} - {exam.name}
                </option>
              ))}
            </Select>
          </div>
        </div>
      </div>

      {/* Stats Dashboard */}
      {stats && (
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col items-center justify-center text-center">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">คะแนนเฉลี่ย</p>
            <p className="text-2xl font-black text-indigo-600">{stats.avg}</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col items-center justify-center text-center">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">อัตราการผ่าน</p>
            <p className="text-2xl font-black text-emerald-500">{stats.passRate}%</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col items-center justify-center text-center">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">คะแนนสูงสุด</p>
            <p className="text-2xl font-black text-amber-500">{stats.max}</p>
          </div>
          <div className="bg-white p-5 rounded-2xl border border-slate-200 shadow-sm flex flex-col items-center justify-center text-center">
            <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mb-1">ผู้เข้าสอบ</p>
            <p className="text-2xl font-black text-slate-800">{stats.count}</p>
          </div>
        </div>
      )}

      {/* Main Table Section */}
      <section className="space-y-4">
        <DataTable
          columns={[
            { 
              key: "studentName", 
              label: "ผู้เรียน", 
              render: (row) => (
                <div className="flex items-center gap-3 py-1">
                  <div className="flex h-10 w-10 shrink-0 items-center justify-center rounded-full bg-gradient-to-br from-slate-100 to-slate-200 text-sm font-bold text-slate-500 shadow-inner border border-white">
                    {row.studentName ? row.studentName.charAt(0) : "?"}
                  </div>
                  <div className="flex flex-col">
                    <div className="flex items-center gap-2">
                      <span className="font-extrabold text-slate-800">{row.studentName || "-"}</span>
                      {(row.studentSec || row.examSection) && (
                        <span className="rounded bg-slate-100 px-1.5 py-0.5 text-[10px] font-black text-slate-500 shadow-sm border border-slate-200/50">
                          Sec {row.studentSec || row.examSection}
                        </span>
                      )}
                    </div>
                    <span className="text-[11px] font-bold tracking-tight text-slate-400">ID: {row.studentCode || "-"}</span>
                  </div>
                </div>
              )
            },
            { 
              key: "score", 
              label: "คะแนน",
              render: (row) => (
                <div className="flex items-baseline gap-1 py-1">
                  <span className={`text-xl font-black ${row.isPassed ? 'text-emerald-600' : 'text-rose-600'}`}>{row.score}</span>
                  <span className="text-xs font-bold text-slate-400">/ {row.totalQuestions}</span>
                </div>
              )
            },
            { 
              key: "percent", 
              label: "ร้อยละ", 
              render: (row) => (
                <div className="w-full max-w-[120px]">
                  <div className="flex justify-between text-[10px] font-black text-slate-400 mb-1">
                    <span>{row.percentage.toFixed(0)}%</span>
                  </div>
                  <div className="h-1.5 w-full bg-slate-100 rounded-full overflow-hidden">
                    <div 
                      className={`h-full rounded-full ${row.isPassed ? 'bg-emerald-500' : 'bg-rose-500'}`} 
                      style={{ width: `${row.percentage}%` }}
                    />
                  </div>
                </div>
              )
            },
            { 
              key: "status", 
              label: "ผลการสอบ", 
              render: (row) => (
                <div className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-[10px] font-black uppercase tracking-wider border ${
                  row.isPassed 
                    ? 'bg-emerald-50 text-emerald-600 border-emerald-100' 
                    : 'bg-rose-50 text-rose-600 border-rose-100'
                }`}>
                  <div className={`w-1.5 h-1.5 rounded-full ${row.isPassed ? 'bg-emerald-500' : 'bg-rose-500'}`} />
                  {row.isPassed ? "ผ่าน" : "ไม่ผ่าน"}
                </div>
              )
            },
            { 
              key: "actions", 
              label: "", 
              render: (row) => (
                <div className="flex justify-end gap-2 pr-2">
                  <GhostButton 
                    variant="primary" 
                    className="p-2 rounded-xl"
                    onClick={() => setSelectedResult(row)}
                    title="ดูรายละเอียดการตอบ"
                  >
                    <Icon name="fa-magnifying-glass" />
                  </GhostButton>
                  <GhostButton 
                    variant="danger" 
                    className="p-2 rounded-xl" 
                    onClick={async () => { 
                      Swal().fire({
                        title: "ลบผลสอบนี้?",
                        text: "ข้อมูลจะไม่สามารถกู้คืนได้",
                        icon: "warning",
                        showCancelButton: true,
                        confirmButtonColor: "#e11d48",
                      }).then(async (res) => {
                        if (res.isConfirmed) {
                          await api.remove("results", row.id); 
                          await refresh("ลบผลสอบแล้ว"); 
                        }
                      });
                    }}
                  >
                    <Icon name="fa-trash-can" />
                  </GhostButton>
                </div>
              ) 
            },
          ]}
          rows={filteredResults}
          emptyText="ยังไม่มีผลสอบสำหรับรายการที่เลือก"
        />
      </section>

      <Modal 
        isOpen={!!selectedResult} 
        onClose={() => setSelectedResult(null)}
        title="รายละเอียดการตอบ"
      >
        {selectedResult && (
          <StudentAnswersView 
            result={filteredResults.find(r => r.id === selectedResult.id) || selectedResult} 
            exam={data.exams.find(e => e.id === selectedResult.examId)} 
          />
        )}
      </Modal>
    </div>
  );
}

function StudentAnswersView({ result, exam }) {
  if (!exam) return null;

  const questionsCount = Number(exam.questions || result.totalQuestions || 0);
  const rows = Array.from({ length: questionsCount }, (_, i) => {
    const questionStr = String(i + 1);
    const correctAns = getCorrectAnswer(exam, questionStr);
    let studentAns = "-";
    let isCorrect = false;
    let isSkipped = false;

    if (result.answers) {
      studentAns = result.answers[questionStr] || "-";
      if (studentAns === "-") {
        isSkipped = true;
      } else {
        isCorrect = studentAns === correctAns;
      }
    } else if (result.itemResults) {
      isCorrect = result.itemResults[questionStr] === true;
      studentAns = isCorrect ? correctAns : (result.itemResults[questionStr] === false ? "X" : "-");
      if (studentAns === "-") isSkipped = true;
    }

    return {
      question: questionStr,
      studentAns,
      correctAns,
      isCorrect,
      isSkipped
    };
  });

  return (
    <div className="space-y-6">
      <div className="flex flex-col md:flex-row justify-between bg-slate-50 p-4 rounded-xl border border-slate-100 gap-4">
        <div>
          <p className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-1">ผู้เรียน</p>
          <p className="text-lg font-black text-slate-800">{result.studentName}</p>
          <p className="text-sm font-bold text-slate-500">ID: {result.studentCode}</p>
        </div>
        <div className="md:text-right">
          <p className="text-xs font-bold text-slate-400 uppercase tracking-widest mb-1">คะแนนรวม</p>
          <p className="text-2xl font-black text-blue-600">{result.score} <span className="text-sm text-slate-500">/ {questionsCount}</span></p>
        </div>
      </div>

      <div className="overflow-x-auto rounded-xl border border-slate-200">
        <table className="w-full text-sm text-left">
          <thead className="bg-slate-50 text-slate-600 font-bold border-b border-slate-200">
            <tr>
              <th className="px-4 py-3">ข้อ</th>
              <th className="px-4 py-3 text-center">คำตอบที่เลือก</th>
              <th className="px-4 py-3 text-center">เฉลย</th>
              <th className="px-4 py-3 text-center">สถานะ</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-100 bg-white">
            {rows.map(row => (
              <tr key={row.question} className="hover:bg-slate-50">
                <td className="px-4 py-3 font-bold text-slate-700">{row.question}</td>
                <td className="px-4 py-3 text-center font-bold text-slate-800">{row.studentAns}</td>
                <td className="px-4 py-3 text-center font-bold text-emerald-600">{row.correctAns}</td>
                <td className="px-4 py-3 text-center">
                  {row.isSkipped ? (
                    <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-slate-100 text-slate-400" title="ไม่ตอบ">
                      <Icon name="fa-minus" />
                    </span>
                  ) : row.isCorrect ? (
                    <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-emerald-100 text-emerald-600" title="ถูกต้อง">
                      <Icon name="fa-check" />
                    </span>
                  ) : (
                    <span className="inline-flex items-center justify-center w-6 h-6 rounded-full bg-rose-100 text-rose-600" title="ผิด">
                      <Icon name="fa-xmark" />
                    </span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
