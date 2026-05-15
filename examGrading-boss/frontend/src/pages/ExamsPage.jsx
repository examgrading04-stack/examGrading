import { useState } from "react";
import { API_BASE_URL, DataTable, Field, GhostButton, Icon, Input, PrimaryButton, Select, Swal, formatThaiDate } from "../ui.jsx";
import { AnswerSheet } from "./AnswerSheet.jsx";

export function ExamsPage({ data, api, refresh, navigate, userEmail }) {
  const [form, setForm] = useState({ subject: "", name: "", questions: 50 });
  const [preview, setPreview] = useState(null);

  async function createExam(event) {
    event.preventDefault();
    const subject = data.subjects.find((item) => item.id === form.subject);
    const questions = Number(form.questions);
    const sheetType = questions <= 20 ? 20 : questions <= 50 ? 50 : 100;
    const payload = {
      name: form.name,
      subject: subject?.code || form.subject,
      subjectName: subject?.name || "",
      date: formatThaiDate(),
      questions,
      sheetType,
      answerKey: {},
      createdAt: window.firebase.firestore.FieldValue.serverTimestamp(),
    };
    const id = `${payload.subject}_${payload.name}`.replace(/\s+/g, '_');
    await api.set(`exams/${id}`, payload);
    const exam = { id, ...payload };
    setPreview(exam);
    setForm({ subject: "", name: "", questions: 50 });
    await refresh("สร้างข้อสอบแล้ว");
  }

  async function deleteExam(row) {
    const result = await Swal().fire({ title: "ลบข้อสอบ?", text: row.name, icon: "warning", showCancelButton: true, confirmButtonText: "ลบ", cancelButtonText: "ยกเลิก" });
    if (!result.isConfirmed) return;
    await api.remove("exams", row.id);
    await refresh("ลบข้อสอบแล้ว");
  }

  async function downloadAnswerSheets(row) {
    const response = await fetch(`${API_BASE_URL}/api/sheets/pdf/download`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user_email: userEmail, exam_id: row.id, upload_to_storage: false }),
    });
    if (!response.ok) {
      const detail = await response.text();
      Swal().fire("สร้าง PDF ไม่สำเร็จ", detail, "error");
      return;
    }
    const blob = await response.blob();
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = `${row.name || row.id}_answer_sheets.pdf`;
    link.click();
    URL.revokeObjectURL(url);
  }

  return (
    <div className="page-enter space-y-6">
      <div className="grid grid-cols-1 xl:grid-cols-[1fr_380px] gap-6">
        <section className="space-y-4">
          <h3 className="text-xl font-extrabold">จัดการข้อสอบ</h3>
          <DataTable
            columns={[
              { key: "name", label: "ชื่อข้อสอบ" },
              { key: "subject", label: "รายวิชา" },
              { key: "questions", label: "จำนวนข้อ" },
              { key: "date", label: "วันที่" },
              {
                key: "actions",
                label: "",
                render: (row) => (
                  <div className="flex flex-wrap justify-end gap-2">
                    <GhostButton className="py-2 px-3" onClick={() => setPreview(row)}><Icon name="fa-print" /> พิมพ์</GhostButton>
                    <GhostButton className="py-2 px-3" onClick={() => downloadAnswerSheets(row)}><Icon name="fa-file-pdf" /> PDF</GhostButton>
                    <GhostButton variant="primary" className="py-2 px-3" onClick={() => navigate("answer-key", { examId: row.id })}><Icon name="fa-key" /> เฉลย</GhostButton>
                    <GhostButton variant="danger" className="py-2 px-3" onClick={() => deleteExam(row)}><Icon name="fa-trash" /></GhostButton>
                  </div>
                ),
              },
            ]}
            rows={data.exams}
            emptyText="ยังไม่มีข้อสอบ"
          />
        </section>
        <form onSubmit={createExam} className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4 h-fit">
          <h4 className="font-extrabold">สร้างข้อสอบใหม่</h4>
          <Field label="รายวิชา">
            <Select value={form.subject} onChange={(e) => setForm({ ...form, subject: e.target.value })} required>
              <option value="">เลือกรายวิชา</option>
              {data.subjects.map((subject) => <option key={subject.id} value={subject.id}>{subject.code} - {subject.name}</option>)}
            </Select>
          </Field>
          <Field label="ชื่อข้อสอบ"><Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="เช่น สอบกลางภาค" required /></Field>
          <div className="grid grid-cols-1 gap-3">
            <Field label="จำนวนข้อ"><Input type="number" min="1" max="100" value={form.questions} onChange={(e) => setForm({ ...form, questions: e.target.value })} placeholder="50" required /></Field>
          </div>
          <PrimaryButton className="w-full"><Icon name="fa-plus" /> สร้างข้อสอบ</PrimaryButton>
        </form>
      </div>
      {preview && (
        <div className="fixed inset-0 z-50 bg-slate-950/50 p-4 overflow-auto">
          <div className="max-w-6xl mx-auto bg-white rounded-2xl overflow-hidden shadow-xl">
            <div className="flex items-center justify-between p-4 border-b border-slate-200">
              <h4 className="font-extrabold">ตัวอย่างกระดาษคำตอบ</h4>
              <div className="flex gap-2">
                <GhostButton className="py-2 px-3" onClick={() => window.print()}><Icon name="fa-print" /> พิมพ์</GhostButton>
                <GhostButton className="py-2 px-3" onClick={() => setPreview(null)}><Icon name="fa-xmark" /></GhostButton>
              </div>
            </div>
            <AnswerSheet config={{ subject: preview.subject, examName: preview.name, questions: preview.questions, options: 4, sets: 1, sheetType: preview.sheetType }} hideToolbar />
          </div>
        </div>
      )}
    </div>
  );
}


