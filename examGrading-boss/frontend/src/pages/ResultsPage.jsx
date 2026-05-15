import { useRef, useState } from "react";
import { API_BASE_URL, DataTable, Field, GhostButton, Icon, Input, PrimaryButton, Select, Swal, pct } from "../ui.jsx";

export function ResultsPage({ data, api, refresh, userEmail }) {
  const [form, setForm] = useState({ examId: "", studentId: "", score: "", answersText: "" });
  const [scanExamId, setScanExamId] = useState("");
  const scanInputRef = useRef(null);

  async function saveResult(event) {
    event.preventDefault();
    const exam = data.exams.find((item) => item.id === form.examId);
    const student = data.students.find((item) => item.id === form.studentId);
    const answers = {};
    form.answersText.split(/[\n, ]+/).filter(Boolean).forEach((answer, index) => {
      answers[index + 1] = answer.toUpperCase();
    });
    const id = `${form.examId}_${form.studentId}`;
    await api.set(`results/${id}`, {
      examId: form.examId,
      studentId: form.studentId,
      studentCode: student?.code || "",
      studentName: student?.name || "",
      examName: exam?.name || "",
      score: Number(form.score),
      answers,
      createdAt: window.firebase.firestore.FieldValue.serverTimestamp(),
    });
    setForm({ examId: "", studentId: "", score: "", answersText: "" });
    await refresh("บันทึกผลสอบแล้ว");
  }

  const rows = data.results.map((row) => {
    const exam = data.exams.find((item) => item.id === row.examId);
    return { ...row, percent: pct(row.score, exam?.questions) };
  });

  async function scanAnswerSheet(event) {
    const file = event.target.files?.[0];
    event.target.value = "";
    if (!file) return;
    if (!scanExamId) {
      Swal().fire("เลือกข้อสอบก่อน", "กรุณาเลือกข้อสอบสำหรับเทียบเฉลย", "warning");
      return;
    }

    const scanForm = new FormData();
    scanForm.append("file", file);
    scanForm.append("user_email", userEmail);
    scanForm.append("exam_id", scanExamId);
    scanForm.append("answer_set", "0");
    scanForm.append("save_result", "true");

    Swal().fire({ title: "กำลังสแกนกระดาษคำตอบ...", allowOutsideClick: false, didOpen: () => Swal().showLoading() });
    const response = await fetch(`${API_BASE_URL}/api/scan`, { method: "POST", body: scanForm });
    if (!response.ok) {
      const detail = await response.text();
      Swal().fire("สแกนไม่สำเร็จ", detail, "error");
      return;
    }
    const result = await response.json();
    await refresh(`บันทึกผลสอบแล้ว: ${result.score}/${result.total}`);
  }

  return (
    <div className="page-enter grid grid-cols-1 xl:grid-cols-[1fr_360px] gap-6">
      <section className="space-y-4">
        <div className="flex flex-wrap items-end justify-between gap-3">
          <h3 className="text-xl font-extrabold">ผลการสอบ</h3>
          <div className="flex flex-wrap items-end gap-2">
            <div className="min-w-56">
              <Field label="ข้อสอบสำหรับสแกน">
                <Select value={scanExamId} onChange={(e) => setScanExamId(e.target.value)}>
                  <option value="">เลือกข้อสอบ</option>
                  {data.exams.map((exam) => <option key={exam.id} value={exam.id}>{exam.name}</option>)}
                </Select>
              </Field>
            </div>
            <input ref={scanInputRef} type="file" accept="image/*" onChange={scanAnswerSheet} className="hidden" />
            <GhostButton variant="success" onClick={() => scanInputRef.current?.click()}><Icon name="fa-camera" /> สแกนรูป</GhostButton>
          </div>
        </div>
        <DataTable
          columns={[
            { key: "studentName", label: "ผู้เรียน", render: (row) => row.studentName || data.students.find((s) => s.id === row.studentId)?.name || "-" },
            { key: "examName", label: "ข้อสอบ", render: (row) => row.examName || data.exams.find((e) => e.id === row.examId)?.name || "-" },
            { key: "score", label: "คะแนน" },
            { key: "percent", label: "%", render: (row) => `${row.percent}%` },
            { key: "actions", label: "", render: (row) => <div className="flex justify-end"><GhostButton variant="danger" className="py-2 px-3" onClick={async () => { await api.remove("results", row.id); await refresh("ลบผลสอบแล้ว"); }}><Icon name="fa-trash" /></GhostButton></div> },
          ]}
          rows={rows}
          emptyText="ยังไม่มีผลสอบ"
        />
      </section>
      <form onSubmit={saveResult} className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4 h-fit">
        <h4 className="font-extrabold">บันทึกผลสอบ</h4>
        <Field label="ข้อสอบ">
          <Select value={form.examId} onChange={(e) => setForm({ ...form, examId: e.target.value })} required>
            <option value="">เลือกข้อสอบ</option>
            {data.exams.map((exam) => <option key={exam.id} value={exam.id}>{exam.name}</option>)}
          </Select>
        </Field>
        <Field label="ผู้เรียน">
          <Select value={form.studentId} onChange={(e) => setForm({ ...form, studentId: e.target.value })} required>
            <option value="">เลือกผู้เรียน</option>
            {data.students.map((student) => <option key={student.id} value={student.id}>{student.code} - {student.name}</option>)}
          </Select>
        </Field>
        <Field label="คะแนน"><Input type="number" min="0" value={form.score} onChange={(e) => setForm({ ...form, score: e.target.value })} placeholder="0" required /></Field>
        <Field label="คำตอบ (คั่นด้วยช่องว่างหรือบรรทัดใหม่)">
          <textarea value={form.answersText} onChange={(e) => setForm({ ...form, answersText: e.target.value })} placeholder="เช่น A B C D ..." className="w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 min-h-28" />
        </Field>
        <PrimaryButton className="w-full"><Icon name="fa-floppy-disk" /> บันทึกผลสอบ</PrimaryButton>
      </form>
    </div>
  );
}



