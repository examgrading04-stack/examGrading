import { useState, useEffect, useMemo, forwardRef, useRef } from "react";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
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



const getTodayStr = () => {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, "0");
  const dd = String(d.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
};

export function ExamsPage({ data, api, refresh, navigate, userEmail }) {
  const [form, setForm] = useState({
    subject: "",
    section: "",
    name: "",
    questions: "",
    sheetType: "30",
    examDate: getTodayStr(),
  });

  const [sheetModal, setSheetModal] = useState(null);
  const [pdfLoading, setPdfLoading] = useState(false);
  const [searchExam, setSearchExam] = useState("");
  const datePickerRef = useRef(null);
  const [filterSubject, setFilterSubject] = useState("");
  const [selectedExams, setSelectedExams] = useState(new Set());
  const [lastSelectedExamIndex, setLastSelectedExamIndex] = useState(null);
  const [lastShiftExamIndex, setLastShiftExamIndex] = useState(null);
  const [isEditing, setIsEditing] = useState(false);

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
  function getTemplateInfo(sheetType, questions) {
    const typeStr = sheetType ? String(sheetType).replace("-A-E", "") : "";
    const num = Number(typeStr) || Number(questions) || 0;
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

  // Auto-select sheet type based on question count, cap at 100
  const handleQuestionsChange = (val) => {
    if (val === "" || val === null || val === undefined) {
      setForm((prev) => ({ ...prev, questions: "" }));
      return;
    }

    let num = parseInt(val, 10);
    if (isNaN(num)) {
      setForm((prev) => ({ ...prev, questions: val }));
      return;
    }

    if (num > 100) {
      num = 100;
    } else if (num < 1) {
      num = 1;
    }

    let autoSheetType = "30";
    if (num <= 30) {
      autoSheetType = "30";
    } else if (num <= 50) {
      autoSheetType = "50";
    } else if (num <= 100) {
      autoSheetType = "100";
    }

    setForm((prev) => ({
      ...prev,
      questions: String(num),
      sheetType: autoSheetType,
    }));
  };

  async function deleteExam(id) {
    const result = await Swal().fire({
      title: "ลบกระดาษคำตอบ?",
      text: "ต้องการลบกระดาษคำตอบนี้หรือไม่ (ข้อมูลการตรวจจะหายไปทั้งหมด)",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบ",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#e11d48",
    });
    if (!result.isConfirmed) return;
    await api.remove("exams", id);
    await refresh("ลบกระดาษคำตอบแล้ว");
  }

  async function createExam(event) {
    event.preventDefault();

    if (!form.subject) {
      Swal().fire("แจ้งเตือน", "กรุณาเลือกวิชาก่อนสร้างกระดาษคำตอบ", "warning");
      return;
    }

    if (!form.name || form.name.trim() === "") {
      Swal().fire("แจ้งเตือน", "กรุณากรอกชื่อกระดาษคำตอบ", "warning");
      return;
    }

    const questions = Number(form.questions);
    if (!questions || questions < 1) {
      Swal().fire("แจ้งเตือน", "กรุณากรอกจำนวนข้อสอบอย่างน้อย 1 ข้อ", "warning");
      return;
    }

    if (questions > 100) {
      Swal().fire("แจ้งเตือน", "จำนวนข้อสอบสูงสุดต้องไม่เกิน 100 ข้อ", "warning");
      return;
    }

    let finalSheetType = 30;
    if (questions <= 30) finalSheetType = 30;
    else if (questions <= 50) finalSheetType = 50;
    else if (questions <= 100) finalSheetType = 100;

    const isEdit = !!form.id;
    Swal().fire({
      title: isEdit ? "กำลังแก้ไขกระดาษคำตอบ..." : "กำลังสร้างกระดาษคำตอบ...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    const subject = data.subjects.find((item) => item.id === form.subject);

    const payload = {
      name: form.name,
      subject_id: subject?.code || form.subject,
      subjectName: subject?.name || "",
      section: form.section || "All Section",
      questions,
      sheetType: finalSheetType,
      examDate: form.examDate || "",
      answerKey: {},
    };

    if (isEdit) {
      await api.update("exams", form.id, payload);
      setForm({
        subject: "",
        section: "",
        name: "",
        questions: "",
        sheetType: "30",
        examDate: getTodayStr(),
        id: null,
      });
      setIsEditing(false);
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

    setForm({
      subject: "",
      section: "",
      name: "",
      questions: "",
      sheetType: "30",
      examDate: getTodayStr(),
      id: null,
    });
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
        <div className="grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_380px] xl:grid-rows-[auto_1fr] gap-x-6 gap-y-3 items-start">
          <div className="order-1 xl:row-start-1 xl:col-start-1 min-w-0">
            <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
              <div>
                <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
                  กระดาษคำตอบทั้งหมด
                </h2>
                <p className="mt-1 text-sm text-slate-500">
                  สร้างกระดาษคำตอบและพิมพ์กระดาษคำตอบ
                </p>
              </div>
            </div>
          </div>

          {/* Create/Edit Exam Form */}
          <div className="order-2 xl:row-start-1 xl:row-span-2 xl:col-start-2">
            <form
              onSubmit={createExam}
              className="bg-white rounded-xl border border-slate-200 shadow-sm p-5 space-y-4"
            >
              <h3 className="font-bold text-slate-800 text-base border-b border-slate-100 pb-3">
                {form.id ? "แก้ไขกระดาษคำตอบ" : "สร้างกระดาษคำตอบ"}
              </h3>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  วิชา
                </label>
                <Select
                  value={form.subject}
                  onChange={(e) =>
                    setForm({ ...form, subject: e.target.value, section: "" })
                  }
                >
                  <option value="">-- เลือกวิชา --</option>
                  {data.subjects.map((s) => (
                    <option key={s.id} value={s.id}>
                      {s.code} · {s.name}
                    </option>
                  ))}
                </Select>
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  กลุ่มเรียน (ไม่บังคับ)
                </label>
                <Select
                  value={form.section}
                  onChange={(e) => setForm({ ...form, section: e.target.value })}
                  disabled={!form.subject}
                >
                  <option value="">All Section</option>
                  {currentSections.map((s) => (
                    <option key={s.id} value={s.id}>
                      Sec {s.sec}
                    </option>
                  ))}
                </Select>
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  ชื่อกระดาษคำตอบ
                </label>
                <Input
                  value={form.name}
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                  placeholder="เช่น Midterm 1/2567"
                />
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  จำนวนข้อสอบ (สูงสุด 100 ข้อ)
                </label>
                <Input
                  type="number"
                  min="1"
                  max="100"
                  value={form.questions}
                  onChange={(e) => handleQuestionsChange(e.target.value)}
                  placeholder="กรอกจำนวนข้อ"
                />
                {form.questions && (
                  <p className="text-xs text-slate-500 mt-1">
                    กระดาษที่เลือกอัตโนมัติ:{" "}
                    <span className="font-semibold text-indigo-600">
                      แบบ {form.sheetType} ข้อ
                    </span>
                  </p>
                )}
              </div>

              <div>
                <label className="block text-sm font-semibold text-slate-700 mb-1">
                  วันที่สอบ
                </label>
                <Input
                  type="date"
                  value={form.examDate}
                  onChange={(e) => setForm({ ...form, examDate: e.target.value })}
                />
              </div>

              <div className="flex gap-2 pt-1">
                <PrimaryButton type="submit" className="flex-1">
                  {form.id ? (
                    <>
                      <Icon name="fa-floppy-disk" /> บันทึก
                    </>
                  ) : (
                    <>
                      <Icon name="fa-plus" /> สร้างกระดาษคำตอบ
                    </>
                  )}
                </PrimaryButton>
                {form.id && (
                  <GhostButton
                    type="button"
                    onClick={() => {
                      setForm({
                        subject: "",
                        section: "",
                        name: "",
                        questions: "",
                        sheetType: "30",
                        examDate: getTodayStr(),
                        id: null,
                      });
                      setIsEditing(false);
                    }}
                    className="px-3 py-2 rounded-lg"
                  >
                    <Icon name="fa-xmark" />
                  </GhostButton>
                )}
              </div>
            </form>
          </div>

          <section className="space-y-3 order-3 xl:row-start-2 xl:col-start-1 min-w-0">
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
                        setLastSelectedExamIndex(null);
                        setLastShiftExamIndex(null);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                  render: (row) => (
                    <input
                      type="checkbox"
                      checked={selectedExams.has(row.id)}
                      onChange={(e) => {
                        const currentIndex = filteredExams.findIndex(
                          (x) => x.id === row.id,
                        );
                        const next = new Set(selectedExams);

                        if (
                          e.nativeEvent.shiftKey &&
                          lastSelectedExamIndex !== null
                        ) {
                          const oldStart =
                            lastShiftExamIndex !== null
                              ? Math.min(
                                  lastShiftExamIndex,
                                  lastSelectedExamIndex,
                                )
                              : lastSelectedExamIndex;
                          const oldEnd =
                            lastShiftExamIndex !== null
                              ? Math.max(
                                  lastShiftExamIndex,
                                  lastSelectedExamIndex,
                                )
                              : lastSelectedExamIndex;

                          const newStart = Math.min(
                            currentIndex,
                            lastSelectedExamIndex,
                          );
                          const newEnd = Math.max(
                            currentIndex,
                            lastSelectedExamIndex,
                          );

                          for (let i = oldStart; i <= oldEnd; i++) {
                            if (i < newStart || i > newEnd) {
                              next.delete(filteredExams[i].id);
                            }
                          }

                          const targetState = selectedExams.has(
                            filteredExams[lastSelectedExamIndex].id,
                          );
                          for (let i = newStart; i <= newEnd; i++) {
                            if (targetState) next.add(filteredExams[i].id);
                            else next.delete(filteredExams[i].id);
                          }
                          setLastShiftExamIndex(currentIndex);
                        } else {
                          if (e.target.checked) next.add(row.id);
                          else next.delete(row.id);
                          setLastSelectedExamIndex(currentIndex);
                          setLastShiftExamIndex(currentIndex);
                        }

                        setSelectedExams(next);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                },
                {
                  key: "name",
                  label: "ชื่อกระดาษคำตอบ",
                  className: "w-[280px] sm:w-[200px] text-left",
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
                  className: "w-25 text-center pl-8",
                  render: (row) => (
                    <span className="font-bold text-zinc-700">
                      {row.questions} ข้อ
                    </span>
                  ),
                },
                {
                  key: "date",
                  label: "วันที่จะสอบ / วันที่สร้าง",
                  className: "pl-6 text-slate-600",
                  render: (row) => {
                    const createdDateStr =
                      row.date ||
                      (row.createdAt
                        ? formatThaiDate(new Date(row.createdAt))
                        : "-");
                    const examDateStr = row.examDate
                      ? formatThaiDate(new Date(row.examDate))
                      : null;
                    return (
                      <div className="flex flex-col text-sm">
                        {examDateStr ? (
                          <>
                            <span className="font-semibold text-slate-800">
                              สอบ: {examDateStr}
                            </span>
                            <span className="text-xs text-slate-400">
                              สร้าง: {createdDateStr}
                            </span>
                          </>
                        ) : (
                          <span className="text-slate-600">
                            {createdDateStr}
                          </span>
                        )}
                      </div>
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
                                    (s) =>
                                      String(s.id) === String(row.section),
                                  )?.sec || row.section,
                            questions: row.questions || 50,
                            examDate: row.examDate || "",
                            sheetType: String(
                              row.sheetType || row.template_id || 30,
                            ).replace("-A-E", ""),
                          });
                          setIsEditing(true);
                          window.scrollTo({ top: 0, behavior: "smooth" });
                        }}
                        title="แก้ไข"
                      >
                        <Icon name="fa-pencil" />
                      </GhostButton>
                      <GhostButton
                        className="p-2 rounded-md text-amber-600 hover:text-amber-700 hover:bg-amber-50"
                        onClick={() =>
                          navigate("answer-key", { examId: row.id })
                        }
                        title="กำหนดเฉลย"
                      >
                        <Icon name="fa-key" />
                      </GhostButton>
                      <GhostButton
                        className="p-2 rounded-md text-indigo-600 hover:text-indigo-700 hover:bg-indigo-50"
                        onClick={() => navigate("results", { examId: row.id })}
                        title="ดูผลการสอบ"
                      >
                        <Icon name="fa-chart-column" />
                      </GhostButton>
                      <GhostButton
                        className="p-2 rounded-md text-red-500 hover:text-red-600"
                        onClick={() => deleteExam(row.id)}
                        title="ลบ"
                      >
                        <Icon name="fa-trash-can" />
                      </GhostButton>
                    </div>
                  ),
                },
              ]}
              rows={data.exams.filter((exam) => {
                if (
                  searchExam &&
                  !exam.name.toLowerCase().includes(searchExam.toLowerCase())
                )
                  return false;
                if (filterSubject && exam.subject_id !== filterSubject) return false;
                return true;
              })}
            />
          </section>
        </div>
      </div>

      {/* Sheet Modal */}
      {sheetModal && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl w-full max-w-lg flex flex-col max-h-[90vh]">
            {/* Modal Header */}
            <div className="p-4 border-b border-slate-200 flex items-center justify-between">
              <div>
                <h3 className="font-bold text-slate-800">
                  {sheetModal.exam.name}
                </h3>
                <p className="text-xs text-slate-500 mt-0.5">
                  {sheetModal.subject?.name || sheetModal.exam.subject_id}
                  {" · "}
                  {sheetModal.exam.section === "All Section" ||
                  !sheetModal.exam.section
                    ? "All Section"
                    : `Sec ${sheetModal.exam.section}`}
                </p>
              </div>
              <button
                onClick={() => setSheetModal(null)}
                className="text-slate-400 hover:text-slate-600 p-1"
              >
                <Icon name="fa-xmark" />
              </button>
            </div>

            {/* Modal Body */}
            <div className="p-5 overflow-y-auto flex-1 space-y-4">
              {/* Summary Cards */}
              <div className="grid grid-cols-2 gap-3">
                {(() => {
                  const info = getTemplateInfo(
                    sheetModal.exam.sheetType,
                    sheetModal.exam.questions,
                  );
                  return (
                    <>
                      <div className="bg-white p-4 rounded-lg border border-slate-200 shadow-sm flex flex-col justify-center">
                        <p className="text-sm font-semibold text-slate-500 mb-1">
                          จำนวนข้อ
                        </p>
                        <p className="text-2xl font-bold text-slate-800">
                          {sheetModal.exam.questions}{" "}
                          <span className="text-sm font-normal text-slate-500">
                            ข้อ
                          </span>
                        </p>
                      </div>
                      <div
                        className={`p-4 rounded-lg border shadow-sm flex flex-col justify-center ${badgeStyles[info.color] || "bg-white border-slate-200 text-slate-800"}`}
                      >
                        <p className="text-sm font-semibold opacity-70 mb-1 text-inherit">
                          รูปแบบกระดาษ
                        </p>
                        <p className="text-base font-bold flex items-center gap-2 mt-1 text-inherit">
                          <Icon name={info.icon} className="opacity-80" />
                          {info.label}
                        </p>
                      </div>
                    </>
                  );
                })()}
              </div>

              {/* Student List */}
              <div className="space-y-3 bg-white p-5 rounded-lg border border-slate-200 shadow-sm">
                <h5 className="font-bold text-slate-800 text-base flex items-center gap-2 border-b border-slate-100 pb-3">
                  <Icon name="fa-list-ul" className="text-slate-400" />{" "}
                  รายชื่อผู้เข้าสอบในกลุ่มเรียนนี้
                </h5>
                {sheetModal.students.length === 0 ? (
                  <div className="text-center py-8">
                    <p className="text-slate-500 text-sm">
                      ไม่พบรายชื่อผู้เรียนในกลุ่มเรียนนี้
                    </p>
                  </div>
                ) : (
                  <div className="flex flex-col">
                    {sheetModal.students.map((st, i) => (
                      <div
                        key={st.id || i}
                        className="py-3 px-2 border-b border-slate-100 last:border-0 flex items-center gap-4 hover:bg-slate-50"
                      >
                        <div className="w-8 text-center text-sm font-semibold text-slate-400">
                          {i + 1}
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="font-bold text-slate-700 text-sm">
                            {st.name}
                          </p>
                        </div>
                        <div className="text-sm text-slate-500 w-32 text-right">
                          {st.id || st.code}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>

            {/* Modal Footer */}
            <div className="px-6 py-4 bg-white border-t border-slate-200">
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
