import { useState, useEffect } from "react";
import {
  API_BASE_URL,
  apiFetch,
  DataTable,
  Field,
  GhostButton,
  Icon,
  Input,
  PrimaryButton,
  Select,
  Swal,
  formatThaiDate,
} from "../ui.jsx";

export function ExamsPage({ data, api, refresh, navigate, userEmail }) {
  const [form, setForm] = useState({
    subject: "",
    section: "",
    name: "",
    questions: 50,
  });
  const [sheetModal, setSheetModal] = useState(null);
  const [pdfLoading, setPdfLoading] = useState(false);

  // Lock body scroll when modal is open
  useEffect(() => {
    if (sheetModal) {
      document.body.style.overflow = "hidden";
    } else {
      document.body.style.overflow = "unset";
    }
    return () => {
      document.body.style.overflow = "unset";
    };
  }, [sheetModal]);

  // Template label logic
  function getTemplateInfo(q) {
    const num = Number(q) || 0;
    if (num <= 30)
      return { label: "แบบ 30 ข้อ", color: "emerald", icon: "fa-file-lines" };
    if (num <= 50)
      return { label: "แบบ 50 ข้อ", color: "blue", icon: "fa-file-medical" };
    return { label: "แบบ 100 ข้อ", color: "amber", icon: "fa-file-signature" };
  }

  const badgeStyles = {
    emerald: "bg-emerald-50 text-emerald-600 border-emerald-100",
    blue: "bg-indigo-50 text-indigo-600 border-indigo-100",
    amber: "bg-amber-50 text-amber-600 border-amber-100",
  };

  function getStudentsForExam(exam, subjectFromList = null) {
    const subject =
      subjectFromList ||
      data.subjects.find(
        (s) => s.id === exam.subject || s.code === exam.subject,
      );
    const subjectCode = subject?.code || exam.subject || "";
    const examSection = String(exam.section || "");

    if (Array.isArray(exam.studentsSnapshot) && exam.studentsSnapshot.length) {
      return exam.studentsSnapshot;
    }

    return data.students.filter((s) => {
      const studentClass = String(s.class || "");
      const fullFormat = `${subjectCode}_${examSection}`;

      if (examSection) {
        return studentClass === fullFormat || studentClass === examSection;
      }
      return (
        studentClass.startsWith(`${subjectCode}_`) ||
        studentClass === subjectCode
      );
    });
  }

  function openSheetModal(exam) {
    const subject = data.subjects.find(
      (s) => s.id === exam.subject || s.code === exam.subject,
    );
    const students = getStudentsForExam(exam, subject);

    setSheetModal({ exam, subject, students: students.length ? students : [] });
  }

  async function createExam(event) {
    event.preventDefault();
    const subject = data.subjects.find((item) => item.id === form.subject);
    const questions = Number(form.questions);
    const sheetType = questions <= 30 ? 30 : questions <= 50 ? 50 : 100;

    const payload = {
      name: form.name,
      subject: subject?.code || form.subject,
      subjectName: subject?.name || "",
      section: form.section,
      date: formatThaiDate(),
      questions,
      sheetType,
      answerKey: {},
      studentsSnapshot: getStudentsForExam(
        { subject: subject?.code || form.subject, section: form.section },
        subject,
      ).map((student) => ({
        id: student.id || "",
        code: student.code || "",
        name: student.name || "",
        class: student.class || "",
      })),
      createdAt: window.firebase.firestore.FieldValue.serverTimestamp(),
    };

    // Format ID: SUBJECT_SECTION_NAME
    const id =
      `${payload.subject}${payload.section ? "_" + payload.section : ""}_${payload.name}`.replace(
        /\s+/g,
        "_",
      );
    await api.set(`exams/${id}`, payload);
    const exam = { id, ...payload };

    setForm({ subject: "", section: "", name: "", questions: 50 });
    await refresh("สร้างข้อสอบสำเร็จ");
    openSheetModal(exam);
  }

  async function downloadPdf(exam, students) {
    setPdfLoading(true);
    try {
      const response = await apiFetch("/api/sheets/pdf/download", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          user_email: userEmail,
          exam_id: exam.id,
          student_ids: (students || []).map((s) => s.id).filter(Boolean),
          students_snapshot: students || [],
          upload_to_storage: false,
        }),
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
      link.download = `${exam.name || exam.id}_answer_sheets.pdf`;
      link.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      Swal().fire(
        "เชื่อมต่อ Backend ไม่ได้",
        `กรุณาตรวจค่า VITE_API_BASE_URL ว่าชี้ไปยัง Backend บน Render ถูกต้อง\n\nค่าปัจจุบัน: ${API_BASE_URL || "-"}\n\n${err.message}`,
        "error",
      );
    } finally {
      setPdfLoading(false);
    }
  }

  const currentSections = data.sections.filter(
    (s) => s.subject === form.subject,
  );

  return (
    <>
      <div className="page-enter max-w-[1600px] mx-auto pb-20 px-4">
        <div className="grid grid-cols-1 xl:grid-cols-[1fr_380px] gap-8 items-start">
          <section className="space-y-6">
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h3 className="text-xl font-extrabold text-zinc-900">
                  คลังข้อสอบทั้งหมด
                </h3>
                <p className="text-sm text-zinc-500">
                  จัดการข้อสอบ แยกตามรหัสวิชาและกลุ่มเรียน
                </p>
              </div>
            </div>

            <DataTable
              columns={[
                {
                  key: "name",
                  label: "ชื่อข้อสอบ / รายวิชา",
                  render: (row) => {
                    const subj = data.subjects.find(
                      (s) => s.code === row.subject || s.id === row.subject,
                    );
                    return (
                      <div className="flex flex-col py-1">
                        <div className="flex items-center gap-2">
                          <span className="font-bold text-zinc-900">
                            {row.name}
                          </span>
                          {row.section && (
                            <span className="px-1.5 py-0.5 rounded-md bg-zinc-100 text-zinc-500 text-[10px] font-black">
                              {row.subject}_{row.section}
                            </span>
                          )}
                        </div>
                        <span className="text-xs text-zinc-500">
                          {subj ? `${subj.code} · ${subj.name}` : row.subject}
                        </span>
                      </div>
                    );
                  },
                },
                {
                  key: "questions",
                  label: "รูปแบบ",
                  render: (row) => {
                    const { label, color, icon } = getTemplateInfo(
                      row.questions,
                    );
                    return (
                      <div
                        className={`inline-flex items-center gap-2 px-3 py-1 rounded-full border text-[11px] font-bold ${badgeStyles[color]}`}
                      >
                        <Icon name={icon} /> {label} ({row.questions} ข้อ)
                      </div>
                    );
                  },
                },
                {
                  key: "date",
                  label: "วันที่สร้าง",
                  render: (row) => (
                    <span className="text-slate-600 text-sm">{row.date}</span>
                  ),
                },
                {
                  key: "actions",
                  label: "",
                  render: (row) => (
                    <div className="flex justify-end gap-2 pr-2">
                      <GhostButton
                        variant="primary"
                        className="p-2 rounded-xl"
                        onClick={() => navigate("results", { examId: row.id })}
                        title="ดูผลการสอบ"
                      >
                        <Icon name="fa-chart-column" />
                      </GhostButton>
                      <GhostButton
                        variant="success"
                        className="p-2 rounded-xl"
                        onClick={() => openSheetModal(row)}
                        title="เตรียมกระดาษคำตอบ"
                      >
                        <Icon name="fa-users-viewfinder" />
                      </GhostButton>
                      <GhostButton
                        className="p-2 rounded-xl !text-amber-600 !border-amber-200 hover:!bg-amber-50"
                        onClick={() =>
                          navigate("answer-key", { examId: row.id })
                        }
                        title="แก้ไขเฉลย"
                      >
                        <Icon name="fa-key" />
                      </GhostButton>
                      <GhostButton
                        variant="danger"
                        className="p-2 rounded-xl"
                        onClick={() => {
                          Swal()
                            .fire({
                              title: "ลบข้อสอบ?",
                              text: "ข้อมูลผลการสอบจะถูกลบออกด้วย",
                              icon: "warning",
                              showCancelButton: true,
                              confirmButtonColor: "#e11d48",
                            })
                            .then((res) => {
                              if (res.isConfirmed) {
                                api.remove("exams", row.id);
                                refresh("ลบสำเร็จ");
                              }
                            });
                        }}
                      >
                        <Icon name="fa-trash-can" />
                      </GhostButton>
                    </div>
                  ),
                },
              ]}
              rows={data.exams}
              emptyText="ไม่มีข้อสอบในคลัง"
            />
          </section>

          <form
            onSubmit={createExam}
            className="bg-white/95 rounded-2xl border border-zinc-200 p-6 space-y-4 h-fit sticky top-8"
          >
            <h4 className="font-extrabold text-zinc-900">สร้างข้อสอบใหม่</h4>
            <Field label="รายวิชาที่สอบ">
              <Select
                value={form.subject}
                onChange={(e) =>
                  setForm({ ...form, subject: e.target.value, section: "" })
                }
                required
              >
                <option value="">เลือกรายวิชา</option>
                {data.subjects.map((s) => (
                  <option key={s.id} value={s.id}>
                    {s.code} - {s.name}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="กลุ่มเรียน (Section)">
              <Select
                value={form.section}
                onChange={(e) => setForm({ ...form, section: e.target.value })}
                disabled={!form.subject}
              >
                <option value="">ทุกกลุ่มเรียน</option>
                {currentSections.map((s) => (
                  <option key={s.id} value={s.sec}>
                    {s.sec}
                  </option>
                ))}
              </Select>
            </Field>
            <Field label="ชื่อข้อสอบ">
              <Input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                placeholder="เช่น สอบกลางภาค"
                required
              />
            </Field>
            <Field label="จำนวนข้อ">
              <Input
                type="number"
                min="1"
                max="100"
                value={form.questions}
                onChange={(e) =>
                  setForm({ ...form, questions: e.target.value })
                }
                placeholder="50"
                required
              />
            </Field>
            {form.questions && (
              <div
                className={`p-3 rounded-xl border flex items-center gap-3 ${badgeStyles[getTemplateInfo(form.questions).color]}`}
              >
                <Icon name={getTemplateInfo(form.questions).icon} />
                <span className="text-xs font-bold">
                  {getTemplateInfo(form.questions).label}
                </span>
              </div>
            )}
            <PrimaryButton className="w-full h-12">
              <Icon name="fa-plus" /> บันทึกข้อสอบ
            </PrimaryButton>
          </form>
        </div>
      </div>

      {sheetModal && (
        <div className="fixed inset-0 z-[999] flex items-center justify-center p-4 overflow-hidden">
          <div
            className="absolute inset-0 bg-zinc-950/40 backdrop-blur-xl animate-in fade-in duration-300"
            onClick={() => setSheetModal(null)}
          />
          <div className="relative bg-white backdrop-blur-md rounded-[2rem] w-full max-w-2xl max-h-[85vh] flex flex-col overflow-hidden animate-in zoom-in-95 slide-in-from-bottom-10 duration-500 border border-zinc-200/80">
            <div className="px-8 py-6 border-b border-zinc-100 flex justify-between items-center bg-zinc-50/70">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 rounded-xl bg-indigo-600 flex items-center justify-center text-white text-xl">
                  <Icon name="fa-users-rectangle" />
                </div>
                <div>
                  <h4 className="text-lg font-black text-zinc-900 tracking-tight">
                    เตรียมกระดาษคำตอบ
                  </h4>
                  <div className="flex items-center gap-2 mt-0.5">
                    <span className="px-2 py-0.5 rounded-md bg-indigo-50 text-indigo-600 text-[10px] font-black uppercase tracking-wider">
                      {sheetModal.subject?.code}
                    </span>
                    {sheetModal.exam.section && (
                      <span className="px-2 py-0.5 rounded-md bg-zinc-100 text-zinc-500 text-[10px] font-black">
                        {sheetModal.subject?.code}_{sheetModal.exam.section}
                      </span>
                    )}
                    <p className="text-xs text-zinc-500 font-medium">
                      {sheetModal.exam.name}
                    </p>
                  </div>
                </div>
              </div>
              <button
                onClick={() => setSheetModal(null)}
                className="w-10 h-10 rounded-full hover:bg-rose-500 hover:text-white text-zinc-300 transition-all flex items-center justify-center"
              >
                <Icon name="fa-xmark" className="text-xl" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto px-8 py-6 space-y-8">
              <div className="grid grid-cols-3 gap-4">
                <div className="bg-indigo-600/5 p-4 rounded-3xl border border-indigo-50 flex flex-col items-center justify-center text-center">
                  <p className="text-[10px] font-black text-indigo-400 uppercase tracking-widest mb-1">
                    นักเรียน
                  </p>
                  <p className="text-2xl font-black text-zinc-900">
                    {sheetModal.students.length}{" "}
                    <span className="text-xs font-normal text-slate-400 italic">
                      คน
                    </span>
                  </p>
                </div>
                <div className="bg-amber-600/5 p-4 rounded-3xl border border-amber-50 flex flex-col items-center justify-center text-center">
                  <p className="text-[10px] font-black text-amber-400 uppercase tracking-widest mb-1">
                    รูปแบบ
                  </p>
                  <p className="text-sm font-black text-zinc-900">
                    {getTemplateInfo(sheetModal.exam.questions).label}
                  </p>
                </div>
                <div className="bg-indigo-600/5 p-4 rounded-3xl border border-indigo-50 flex flex-col items-center justify-center text-center">
                  <p className="text-[10px] font-black text-indigo-400 uppercase tracking-widest mb-1">
                    จำนวนข้อ
                  </p>
                  <p className="text-2xl font-black text-zinc-900">
                    {sheetModal.exam.questions}{" "}
                    <span className="text-xs font-normal text-slate-400 italic">
                      ข้อ
                    </span>
                  </p>
                </div>
              </div>
              <div className="space-y-3">
                <h5 className="font-black text-zinc-900 text-[11px] flex items-center gap-2 uppercase tracking-widest opacity-40 px-1">
                  <Icon name="fa-list-ul" /> ตรวจสอบรายชื่อในกลุ่มเรียน
                </h5>
                {sheetModal.students.length === 0 ? (
                  <div className="text-center py-10 bg-zinc-50/70 rounded-2xl border border-dashed border-zinc-100">
                    <p className="text-zinc-400 text-sm font-bold">
                      ไม่พบรายชื่อนักเรียนในกลุ่มเรียนนี้
                    </p>
                  </div>
                ) : (
                  <div className="flex flex-col gap-2">
                    {sheetModal.students.map((st, i) => (
                      <div
                        key={st.id}
                        className="p-4 rounded-2xl bg-white border border-zinc-100 flex items-center gap-4"
                      >
                        <div className="w-8 h-8 rounded-lg bg-zinc-50 flex items-center justify-center text-[11px] font-black text-zinc-300">
                          {i + 1}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-bold text-slate-700 text-sm leading-tight">
                            {st.name}
                          </p>
                          <p className="text-[11px] font-bold text-slate-400 mt-0.5 tracking-tight">
                            ID: {st.code}
                          </p>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
            <div className="px-8 py-6 bg-zinc-50/70 border-t border-zinc-100">
              <PrimaryButton
                disabled={pdfLoading || sheetModal.students.length === 0}
                onClick={() =>
                  downloadPdf(sheetModal.exam, sheetModal.students)
                }
                className="w-full h-14 text-sm"
              >
                {pdfLoading ? (
                  <>
                    <Icon name="fa-spinner fa-spin" /> กำลังเตรียม PDF...
                  </>
                ) : (
                  <>
                    <Icon name="fa-file-pdf" /> ดาวน์โหลดกระดาษคำตอบสำหรับทุกคน
                    ({sheetModal.students.length} ชุด)
                  </>
                )}
              </PrimaryButton>
            </div>
          </div>
        </div>
      )}
    </>
  );
}
