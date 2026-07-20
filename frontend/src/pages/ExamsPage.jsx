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
    questions: "",
  });
  const [sheetModal, setSheetModal] = useState(null);
  const [pdfLoading, setPdfLoading] = useState(false);
  const [searchExam, setSearchExam] = useState("");
  const [filterSubject, setFilterSubject] = useState("");
  const [selectedExams, setSelectedExams] = useState(new Set());

  const filteredExams = data.exams.filter((exam) => {
    if (
      searchExam &&
      !exam.name.toLowerCase().includes(searchExam.toLowerCase())
    )
      return false;
    if (filterSubject && exam.subject_id !== filterSubject) return false;
    return true;
  });

  async function deleteSelectedExams() {
    if (selectedExams.size === 0) return;
    const result = await Swal().fire({
      title: "ลบกระดาษคำตอบที่เลือก?",
      text: `ต้องการลบกระดาษคำตอบจำนวน ${selectedExams.size} ชุดหรือไม่ (ข้อมูลการตรวจจะหายไปทั้งหมด)`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบ",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#e11d48",
    });
    if (!result.isConfirmed) return;

    Swal().fire({
      title: "กำลังลบข้อมูล...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });

    await Promise.all(
      Array.from(selectedExams).map((id) => api.remove("exams", id)),
    );

    setSelectedExams(new Set());
    await refresh(`ลบกระดาษคำตอบ ${selectedExams.size} ชุดแล้ว`);
  }

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
        (s) => s.id === exam.subject_id || s.code === exam.subject_id,
      );
    const subjectCode = subject?.code || exam.subject_id || "";
    const examSection = String(exam.section || "");

    if (Array.isArray(exam.studentsSnapshot) && exam.studentsSnapshot.length) {
      return exam.studentsSnapshot;
    }

    return data.students.filter((s) => {
      const sSection = String(s.section || "");
      const sSubject = String(s.subjectCode || "");

      if (examSection && examSection !== "All Section") {
        const matchedSection = data.sections?.find(
          (sec) => String(sec.realId) === sSection && sec.subject === sSubject,
        );
        const sSectionName = String(matchedSection?.sec || sSection);

        return (
          sSubject === subjectCode &&
          (sSection === examSection || sSectionName === examSection)
        );
      }
      return sSubject === subjectCode;
    });
  }

  function openSheetModal(exam) {
    const subject = data.subjects.find(
      (s) => s.id === exam.subject_id || s.code === exam.subject_id,
    );
    const students = getStudentsForExam(exam, subject);

    setSheetModal({ exam, subject, students: students.length ? students : [] });
  }

  async function createExam(event) {
    event.preventDefault();
    const isEdit = !!form.id;
    Swal().fire({
      title: isEdit ? "กำลังแก้ไขกระดาษคำตอบ..." : "กำลังสร้างกระดาษคำตอบ...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    const subject = data.subjects.find((item) => item.id === form.subject);
    const questions = Number(form.questions);
    const sheetType = questions <= 30 ? 30 : questions <= 50 ? 50 : 100;

    const payload = {
      name: form.name,
      subject_id: subject?.code || form.subject,
      subjectName: subject?.name || "",
      section: form.section || "All Section",
      questions,
      sheetType,
      answerKey: {},
    };

    if (isEdit) {
      await api.update("exams", form.id, payload);
      setForm({ subject: "", section: "", name: "", questions: "", id: null });
      await refresh("แก้ไขกระดาษคำตอบสำเร็จ");
      return;
    }

    payload.createdAt = window.firebase.firestore.FieldValue.serverTimestamp();

    // Format ID: SUBJECT_SECTION_NAME
    const id =
      `${payload.subject_id}${payload.section ? "_" + payload.section : ""}_${payload.name}`.replace(
        /\s+/g,
        "_",
      );
    await api.set(`exams/${id}`, payload);
    const exam = { id, ...payload };

    setForm({ subject: "", section: "", name: "", questions: "", id: null });
    await refresh("สร้างกระดาษคำตอบสำเร็จ");
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
            <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between mb-2">
              <div>
                <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl">
                  ข้อมูลกระดาษคำตอบทั้งหมด
                </h2>
                <p className="mt-2 text-sm text-slate-500">
                  สร้างกระดาษคำตอบและพิมพ์กระดาษคำตอบ
                </p>
              </div>
            </div>

            <div className="flex flex-col xl:flex-row xl:items-center justify-between gap-4">
              <div className="flex flex-wrap items-center gap-3 flex-1 min-w-0">
                <div className="w-full sm:w-56 max-w-full shrink-0">
                  <Input
                    value={searchExam}
                    onChange={(event) => setSearchExam(event.target.value)}
                    placeholder="ค้นหาชื่อกระดาษคำตอบ"
                  />
                </div>
                <div className="w-full sm:w-48 shrink-0">
                  <Select
                    value={filterSubject}
                    onChange={(event) => setFilterSubject(event.target.value)}
                  >
                    <option value="">ทุกวิชา</option>
                    {data.subjects.map((subject) => (
                      <option
                        key={subject.id}
                        value={subject.id || subject.code}
                      >
                        {subject.name}
                      </option>
                    ))}
                  </Select>
                </div>
              </div>
              {selectedExams.size > 0 && (
                <button
                  onClick={deleteSelectedExams}
                  className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2 shadow-sm whitespace-nowrap shrink-0"
                  title="ลบรายการที่เลือก"
                >
                  <Icon name="fa-trash-can" /> ({selectedExams.size})
                </button>
              )}
            </div>

            <DataTable
              columns={[
                {
                  key: "select",
                  className: "w-12 text-center px-2",
                  label: (
                    <input
                      type="checkbox"
                      checked={selectedExams.size > 0}
                      onChange={(e) => {
                        const next = new Set(selectedExams);
                        if (e.target.checked) {
                          filteredExams.forEach((ex) => next.add(ex.id));
                        } else {
                          next.clear();
                        }
                        setSelectedExams(next);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                  render: (row) => (
                    <input
                      type="checkbox"
                      checked={selectedExams.has(row.id)}
                      onChange={(e) => {
                        const next = new Set(selectedExams);
                        if (e.target.checked) next.add(row.id);
                        else next.delete(row.id);
                        setSelectedExams(next);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                },
                {
                  key: "name",
                  label: "ชื่อกระดาษคำตอบ",
                  render: (row) => {
                    const subj = data.subjects.find(
                      (s) =>
                        s.code === row.subject_id || s.id === row.subject_id,
                    );
                    return (
                      <div
                        className="flex flex-col gap-1 py-1 cursor-pointer hover:bg-slate-50 p-2 -m-2 rounded-md transition-colors"
                        onClick={() => openSheetModal(row)}
                        title="เตรียมกระดาษคำตอบ"
                      >
                        <span className="font-bold text-blue-600 hover:text-blue-700 text-base flex items-center gap-2">
                          {row.name}{" "}
                          <Icon
                            name="fa-up-right-from-square"
                            className="text-[10px] opacity-70"
                          />
                        </span>
                        <span className="text-sm font-semibold text-zinc-600">
                          {row.section === "All Section" || !row.section
                            ? "All Section"
                            : `Sec ${data.sections.find((s) => String(s.id) === String(row.section))?.sec || row.section}`}
                        </span>
                        <span className="text-xs text-zinc-500">
                          {subj
                            ? `${subj.code} · ${subj.name}`
                            : row.subject_id}
                        </span>
                      </div>
                    );
                  },
                },
                {
                  key: "questions",
                  label: "จำนวนข้อ",
                  className: "w-24 text-center",
                  render: (row) => (
                    <span className="font-bold text-zinc-700">
                      {row.questions} ข้อ
                    </span>
                  ),
                },
                {
                  key: "date",
                  label: "วันที่สร้าง",
                  render: (row) => {
                    const displayDate =
                      row.date ||
                      (row.createdAt
                        ? formatThaiDate(new Date(row.createdAt))
                        : "-");
                    return (
                      <span className="text-slate-600 text-sm">
                        {displayDate}
                      </span>
                    );
                  },
                },
                {
                  key: "actions",
                  label: "",
                  truncate: false,
                  className: "w-[240px] text-right",
                  render: (row) => (
                    <div className="flex flex-nowrap justify-end gap-2 pr-2">
                      <GhostButton
                        className="p-2 rounded-md"
                        onClick={() => {
                          const subj = data.subjects.find(
                            (s) =>
                              s.code === row.subject_id ||
                              s.id === row.subject_id,
                          );
                          setForm({
                            id: row.id,
                            name: row.name,
                            subject: subj ? subj.id : row.subject_id,
                            section:
                              row.section === "All Section"
                                ? ""
                                : data.sections.find(
                                    (s) => String(s.id) === String(row.section),
                                  )?.sec || row.section,
                            questions: row.questions || 50,
                          });
                        }}
                        title="แก้ไขข้อมูลกระดาษคำตอบ"
                      >
                        <Icon name="fa-pen" />
                      </GhostButton>
                      <GhostButton
                        className="p-2 rounded-md !text-amber-600 !border-amber-200 hover:!bg-amber-50"
                        onClick={() =>
                          navigate("answer-key", { examId: row.id })
                        }
                        title="แก้ไขเฉลย"
                      >
                        <Icon name="fa-key" />
                      </GhostButton>
                      <GhostButton
                        variant="primary"
                        className="p-2 rounded-md"
                        onClick={() => navigate("results", { examId: row.id })}
                        title="ดูผลการสอบ"
                      >
                        <Icon name="fa-chart-column" />
                      </GhostButton>
                      <GhostButton
                        variant="danger"
                        className="p-2 rounded-md"
                        onClick={() => {
                          Swal()
                            .fire({
                              title: "ลบกระดาษคำตอบ?",
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
              rows={filteredExams}
              emptyText="ไม่มีกระดาษคำตอบในคลัง"
            />
          </section>

          <form
            onSubmit={createExam}
            className="bg-white/95 rounded-lg border border-zinc-200 border-t-4 border-t-blue-600 p-6 space-y-4 h-fit sticky top-8"
          >
            <h4 className="font-extrabold text-zinc-900">
              {form.id ? "แก้ไขข้อมูลกระดาษคำตอบ" : "สร้างกระดาษคำตอบใหม่"}
            </h4>
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
            <Field label="ชื่อกระดาษคำตอบ">
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
                className={`p-3 rounded-md border flex items-center gap-3 ${badgeStyles[getTemplateInfo(form.questions).color]}`}
              >
                <Icon name={getTemplateInfo(form.questions).icon} />
                <span className="text-xs font-bold">
                  {getTemplateInfo(form.questions).label}
                </span>
              </div>
            )}
            <PrimaryButton className="w-full h-12">
              <Icon name={form.id ? "fa-floppy-disk" : "fa-plus"} />{" "}
              {form.id ? "บันทึกการแก้ไข" : "บันทึกกระดาษคำตอบ"}
            </PrimaryButton>
            {form.id && (
              <GhostButton
                type="button"
                className="w-full h-10"
                onClick={() =>
                  setForm({
                    subject: "",
                    section: "",
                    name: "",
                    questions: "",
                    id: null,
                  })
                }
              >
                ยกเลิกการแก้ไข
              </GhostButton>
            )}
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
                <div className="w-12 h-12 rounded-md bg-indigo-600 flex items-center justify-center text-white text-xl">
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
                    <span className="px-2 py-0.5 rounded-md bg-zinc-100 text-zinc-500 text-[10px] font-black">
                      {sheetModal.exam.section === "All Section" ||
                      !sheetModal.exam.section
                        ? "All Section"
                        : `Sec ${data.sections.find((s) => String(s.id) === String(sheetModal.exam.section))?.sec || sheetModal.exam.section}`}
                    </span>
                    <p className="text-xs text-zinc-500 font-medium">
                      {sheetModal.exam.name}
                    </p>
                  </div>
                </div>
              </div>
              <button
                onClick={() => setSheetModal(null)}
                className="w-10 h-10 rounded-full bg-zinc-100 text-zinc-500 hover:bg-rose-500 hover:text-white transition-all flex items-center justify-center"
              >
                <Icon name="fa-xmark" className="text-xl" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto px-8 py-6 space-y-8">
              <div className="grid grid-cols-3 gap-4">
                {(() => {
                  const info = getTemplateInfo(sheetModal.exam.questions);
                  const style = badgeStyles[info.color] || badgeStyles.amber;
                  const labelColor =
                    info.color === "emerald"
                      ? "text-emerald-500"
                      : info.color === "blue"
                        ? "text-indigo-500"
                        : "text-amber-500";

                  return (
                    <>
                      <div
                        className={`${style} p-4 rounded-lg border flex flex-col items-center justify-center text-center`}
                      >
                        <p
                          className={`text-[12px] font-black ${labelColor} uppercase tracking-widest mb-1 opacity-80`}
                        >
                          นักเรียน
                        </p>
                        <p className="text-2xl font-black">
                          {sheetModal.students.length}{" "}
                          <span className="text-xs font-normal opacity-70">
                            คน
                          </span>
                        </p>
                      </div>
                      <div
                        className={`${style} p-4 rounded-lg border flex flex-col items-center justify-center text-center`}
                      >
                        <p
                          className={`text-[12px] font-black ${labelColor} uppercase tracking-widest mb-1 opacity-80`}
                        >
                          รูปแบบ
                        </p>
                        <p className="text-sm font-black mt-2">
                          <Icon name={info.icon} className="mr-1 opacity-80" />{" "}
                          {info.label}
                        </p>
                      </div>
                      <div
                        className={`${style} p-4 rounded-lg border flex flex-col items-center justify-center text-center`}
                      >
                        <p
                          className={`text-[12px] font-black ${labelColor} uppercase tracking-widest mb-1 opacity-80`}
                        >
                          จำนวนข้อ
                        </p>
                        <p className="text-2xl font-black">
                          {sheetModal.exam.questions}{" "}
                          <span className="text-xs font-normal opacity-70">
                            ข้อ
                          </span>
                        </p>
                      </div>
                    </>
                  );
                })()}
              </div>
              <div className="space-y-3">
                <h5 className="font-black text-zinc-600 text-[14px] flex items-center gap-2 uppercase tracking-widest px-1">
                  <Icon name="fa-list-ul" /> ตรวจสอบรายชื่อในกลุ่มเรียน
                </h5>
                {sheetModal.students.length === 0 ? (
                  <div className="text-center py-10 bg-zinc-50/70 rounded-lg border border-dashed border-zinc-100">
                    <p className="text-zinc-400 text-sm font-bold">
                      ไม่พบรายชื่อนักเรียนในกลุ่มเรียนนี้
                    </p>
                  </div>
                ) : (
                  <div className="flex flex-col gap-2">
                    {sheetModal.students.map((st, i) => (
                      <div
                        key={st.id}
                        className="p-4 rounded-lg bg-white border border-zinc-100 flex items-center gap-4"
                      >
                        <div className="w-8 h-8 rounded-lg bg-indigo-50 flex items-center justify-center text-[14px] font-black text-indigo-600">
                          {i + 1}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-bold text-slate-700 text-[15px] leading-tight">
                            {st.name}
                          </p>
                          <p className="text-[14px] font-bold text-slate-400 mt-0.5 tracking-tight">
                            ID: {st.id || st.code}
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
