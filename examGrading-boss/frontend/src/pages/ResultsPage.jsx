import { useState, useMemo } from "react";
import { DataTable, Icon, Select, GhostButton, Swal } from "../ui.jsx";

export function ResultsPage({ data, api, refresh, query }) {
  const [selectedExamId, setSelectedExamId] = useState(query?.examId || "");

  // Filter results based on selected exam
  const filteredResults = useMemo(() => {
    let list = data.results;
    if (selectedExamId) {
      list = list.filter(r => r.examId === selectedExamId);
    }
    return list.map(row => {
      const exam = data.exams.find(e => e.id === row.examId);
      const student = data.students.find(s => s.id === row.studentId || s.code === row.studentCode);
      const percentage = exam?.questions ? (row.score / exam.questions) * 100 : 0;
      
      return {
        ...row,
        totalQuestions: exam?.questions || 0,
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
      {/* Header Section like SubjectsPage */}
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h3 className="text-xl font-extrabold text-slate-800 flex items-center gap-3">
            {currentExam ? `ผลการสอบ: ${currentExam.name}` : "ผลการสอบทั้งหมด"}
            {currentExam?.section && (
              <span className="px-3 py-1 rounded-full bg-slate-100 text-slate-500 text-xs font-black uppercase">Sec {currentExam.section}</span>
            )}
          </h3>
          <p className="text-sm text-slate-500">
            {currentExam 
              ? `รหัสวิชา ${currentExam.subject} · รายชื่อผู้เข้าสอบและผลคะแนนรายบุคคล` 
              : "เลือกข้อสอบเพื่อดูรายละเอียดและสถิติคะแนนแยกตามกลุ่มเรียน"}
          </p>
        </div>
        <div className="w-full sm:w-80">
          <Select value={selectedExamId} onChange={(e) => setSelectedExamId(e.target.value)}>
            <option value="">ดูผลการสอบทั้งหมด</option>
            {data.exams.map((exam) => (
              <option key={exam.id} value={exam.id}>
                {exam.subject} {exam.section ? `(Sec ${exam.section})` : ""} - {exam.name}
              </option>
            ))}
          </Select>
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
                <div className="flex flex-col py-0.5">
                  <div className="flex items-center gap-2">
                    <span className="font-bold text-slate-800">{row.studentName || "-"}</span>
                    {(row.studentSec || row.examSection) && (
                      <span className="text-[10px] font-black text-slate-400 bg-slate-50 px-1.5 py-0.5 rounded border border-slate-100">
                        Sec {row.studentSec || row.examSection}
                      </span>
                    )}
                  </div>
                  <span className="text-[11px] text-slate-400 font-bold uppercase tracking-tight">ID: {row.studentCode || "-"}</span>
                </div>
              )
            },
            { 
              key: "score", 
              label: "คะแนน",
              render: (row) => (
                <div className="flex items-baseline gap-1">
                  <span className="text-lg font-black text-slate-800">{row.score}</span>
                  <span className="text-xs text-slate-400 font-bold">/ {row.totalQuestions}</span>
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
                <div className="flex justify-end pr-2">
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
    </div>
  );
}
