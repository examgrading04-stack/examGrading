import { useState, useEffect } from "react";
import {
  DataTable,
  Field,
  GhostButton,
  Icon,
  Input,
  PrimaryButton,
  Select,
  Swal,
  emptyForm,
} from "../ui.jsx";

export function SubjectsPage({ data, api, refresh, userEmail, userName }) {
  const defaultTeacher = userName || userEmail || "";

  const [subjectForm, setSubjectForm] = useState({
    ...emptyForm(["id", "code", "name", "term", "year", "teacher"]),
    term: "1",
    year: String(new Date().getFullYear() + 543),
    teacher: defaultTeacher,
  });

  useEffect(() => {
    if (defaultTeacher && !subjectForm.id && !subjectForm.teacher) {
      setSubjectForm((prev) => ({ ...prev, teacher: defaultTeacher }));
    }
  }, [defaultTeacher, subjectForm.id]);
  const [sectionForm, setSectionForm] = useState(
    emptyForm(["id", "subject", "sec", "count"]),
  );
  const [activeSubject, setActiveSubject] = useState(null);
  const [searchSubject, setSearchSubject] = useState("");
  const [searchSection, setSearchSection] = useState("");

  const sections = activeSubject
    ? data.sections.filter((section) => section.subject === activeSubject)
    : data.sections;

  const filteredSubjects = data.subjects.filter(
    (s) =>
      !searchSubject ||
      (s.code + " " + s.name)
        .toLowerCase()
        .includes(searchSubject.toLowerCase()),
  );

  const filteredSections = sections.filter(
    (s) =>
      !searchSection ||
      String(s.sec).toLowerCase().includes(searchSection.toLowerCase()),
  );

  const currentSubject = data.subjects.find((s) => s.id === activeSubject);

  async function saveSubject(event) {
    event.preventDefault();

    const codeTrimmed = String(subjectForm.code || "").trim();
    if (!codeTrimmed) {
      return Swal().fire(
        "กรุณากรอกรหัสวิชา",
        "รหัสวิชาต้องไม่เป็นค่าว่าง",
        "warning",
      );
    }

    const isEdit = !!subjectForm.id;
    const existing = data.subjects.find(
      (s) =>
        String(s.code || s.id)
          .trim()
          .toLowerCase() === codeTrimmed.toLowerCase() &&
        (isEdit ? s.id !== subjectForm.id && s.code !== subjectForm.id : true),
    );

    if (existing) {
      return Swal().fire(
        "รหัสวิชานี้มีอยู่แล้ว",
        `รหัสวิชา "${codeTrimmed}" (${existing.name || ""}) มีอยู่ในระบบเรียบร้อยแล้ว`,
        "warning",
      );
    }

    Swal().fire({
      title: isEdit ? "กำลังแก้ไขรายวิชา..." : "กำลังบันทึกรายวิชา...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });

    const payload = {
      code: codeTrimmed,
      name: subjectForm.name,
      term: subjectForm.term,
      year: subjectForm.year,
      teacher: subjectForm.teacher || defaultTeacher,
    };

    try {
      if (isEdit) {
        await api.update("subjects", subjectForm.id, payload);
      } else {
        await api.set(`subjects/${payload.code}`, payload);

        // Automatically create a default section (group 1) for the new subject
        const secStr = "1";
        const secId = `${payload.code}_${secStr}`;
        await api.set(`subjects/${payload.code}/sections/${secId}`, {
          id: secId,
          subject: payload.code,
          sec: secStr,
          created_at: new Date().toISOString(),
        });
      }
      setSubjectForm({
        ...emptyForm(["id", "code", "name", "term", "year", "teacher"]),
        term: "1",
        year: String(new Date().getFullYear() + 543),
        teacher: defaultTeacher,
      });
      await refresh("บันทึกรายวิชาเรียบร้อยแล้ว");
    } catch (err) {
      Swal().fire(
        "เกิดข้อผิดพลาด",
        err.message || "ไม่สามารถบันทึกรายวิชาได้",
        "error",
      );
    }
  }

  async function saveSection(event) {
    event.preventDefault();
    const subjectId = activeSubject || sectionForm.subject;
    if (!subjectId) {
      return Swal().fire(
        "กรุณาเลือกรายวิชา",
        "ต้องเลือกรายวิชาก่อนเพิ่มกลุ่มเรียน",
        "warning",
      );
    }

    try {
      if (sectionForm.id) {
        // แก้ไขกลุ่มเรียนเดิม
        Swal().fire({
          title: "กำลังบันทึกกลุ่มเรียน...",
          allowOutsideClick: false,
          didOpen: () => Swal().showLoading(),
        });
        await api.set(`subjects/${subjectId}/sections/${sectionForm.id}`, {
          subject: subjectId,
          sec: sectionForm.sec,
          created_at: new Date().toISOString(),
        });
      } else {
        // เพิ่มกลุ่มเรียนตามจำนวนที่ระบุ
        const count = parseInt(sectionForm.count || sectionForm.sec || "1", 10);
        if (isNaN(count) || count < 1) {
          return Swal().fire(
            "จำนวนไม่ถูกต้อง",
            "กรุณาระบุจำนวนกลุ่มเรียนที่ต้องการเพิ่มเป็นตัวเลขอย่างน้อย 1",
            "warning",
          );
        }

        Swal().fire({
          title: `กำลังสร้างกลุ่มเรียนจำนวน ${count} กลุ่ม...`,
          allowOutsideClick: false,
          didOpen: () => Swal().showLoading(),
        });

        // ค้นหากลุ่มเรียนที่มีอยู่เดิมในรายวิชานี้เพื่อรันตัวเลขกลุ่มต่อ
        const existingSections = data.sections.filter(
          (s) => s.subject === subjectId,
        );
        const existingNums = existingSections
          .map((s) => parseInt(s.sec, 10))
          .filter((n) => !isNaN(n));
        const maxNum = existingNums.length > 0 ? Math.max(...existingNums) : 0;

        const promises = [];
        for (let i = 1; i <= count; i++) {
          const secNum = maxNum + i;
          const secStr = String(secNum);
          const secId = `${subjectId}_${secStr}`;
          promises.push(
            api.set(`subjects/${subjectId}/sections/${secId}`, {
              id: secId,
              subject: subjectId,
              sec: secStr,
              created_at: new Date().toISOString(),
            }),
          );
        }
        await Promise.all(promises);
      }

      setSectionForm(emptyForm(["id", "subject", "sec", "count"]));
      await refresh("บันทึกกลุ่มเรียนเรียบร้อยแล้ว");
    } catch (err) {
      Swal().fire(
        "เกิดข้อผิดพลาด",
        err.message || "ไม่สามารถบันทึกกลุ่มเรียนได้",
        "error",
      );
    }
  }

  async function deleteSubject(subject) {
    const result = await Swal().fire({
      title: "ลบรายวิชา?",
      text: `หากลบวิชา ${subject.name} ระบบจะลบกลุ่มเรียนและรายชื่อผู้เรียนในวิชานี้ด้วย`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบ",
      cancelButtonText: "ยกเลิก",
    });
    if (!result.isConfirmed) return;

    Swal().fire({
      title: "กำลังลบข้อมูล...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });

    await api.remove("subjects", subject.id);
    await refresh("ลบรายวิชาเรียบร้อยแล้ว");
  }

  async function deleteSection(section) {
    const result = await Swal().fire({
      title: "ลบกลุ่มเรียน?",
      text: `หากลบ ${section.sec} ระบบจะลบรายชื่อผู้เรียนของกลุ่มเรียนนี้ด้วย`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบ",
      cancelButtonText: "ยกเลิก",
    });
    if (!result.isConfirmed) return;

    Swal().fire({
      title: "กำลังลบข้อมูล...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });

    await api.remove(
      `subjects/${section.subject}/sections`,
      section.realId || section.id,
    );
    await refresh("ลบกลุ่มเรียนเรียบร้อยแล้ว");
  }

  const [selectedSubjects, setSelectedSubjects] = useState(new Set());
  const [lastSelectedSubjectIndex, setLastSelectedSubjectIndex] =
    useState(null);
  const [lastShiftSubjectIndex, setLastShiftSubjectIndex] = useState(null);
  const [selectedSections, setSelectedSections] = useState(new Set());
  const [lastSelectedSectionIndex, setLastSelectedSectionIndex] =
    useState(null);
  const [lastShiftSectionIndex, setLastShiftSectionIndex] = useState(null);

  async function deleteSelectedSubjects() {
    if (selectedSubjects.size === 0) return;
    const result = await Swal().fire({
      title: "ยืนยันการลบ?",
      text: `คุณต้องการลบรายวิชาจำนวน ${selectedSubjects.size} รายการใช่หรือไม่? (ระบบจะลบกลุ่มเรียนและรายชื่อผู้เรียนด้วย)`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบทั้งหมด",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#ef4444",
    });
    if (!result.isConfirmed) return;

    Swal().fire({
      title: "กำลังลบข้อมูล...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });

    for (const id of selectedSubjects) {
      await api.remove("subjects", id);
    }

    setSelectedSubjects(new Set());
    await refresh("ลบรายวิชาที่เลือกเรียบร้อยแล้ว");
  }

  async function deleteSelectedSections() {
    if (selectedSections.size === 0) return;
    const result = await Swal().fire({
      title: "ยืนยันการลบ?",
      text: `คุณต้องการลบกลุ่มเรียนจำนวน ${selectedSections.size} รายการใช่หรือไม่? (ระบบจะลบรายชื่อผู้เรียนด้วย)`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบทั้งหมด",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#ef4444",
    });
    if (!result.isConfirmed) return;

    Swal().fire({
      title: "กำลังลบข้อมูล...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });

    for (const id of selectedSections) {
      const section = data.sections.find((s) => s.id === id);
      if (section) {
        await api.remove(
          `subjects/${section.subject}/sections`,
          section.realId || section.id,
        );
      }
    }

    setSelectedSections(new Set());
    await refresh("ลบกลุ่มเรียนที่เลือกเรียบร้อยแล้ว");
  }
  return (
    <div className="page-enter max-w-[1600px] mx-auto px-4 grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_380px] xl:grid-rows-[auto_1fr] gap-x-6 gap-y-3 items-start">
      <div className="order-1 xl:row-start-1 xl:col-start-1 min-w-0">
        {!activeSubject ? (
          <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
                รายวิชาทั้งหมด
              </h2>
              <p className="mt-1 text-sm text-slate-500">
                จัดการรายวิชาและกลุ่มเรียนที่เปิดสอน
              </p>
            </div>
          </div>
        ) : (
          <div className="flex flex-wrap items-center justify-between gap-3">
            <div className="flex items-center gap-4">
              <GhostButton
                onClick={() => setActiveSubject(null)}
                className="py-2 px-3"
              >
                <Icon name="fa-arrow-left" />
              </GhostButton>
              <div>
                <h3 className="text-xl font-bold text-slate-900 tracking-tight">
                  กลุ่มเรียน: {currentSubject?.name}
                </h3>
                <p className="text-sm text-slate-500">
                  กลุ่มเรียนทั้งหมดในรายวิชานี้
                </p>
              </div>
            </div>
          </div>
        )}
      </div>

      <section className="space-y-3 order-3 xl:row-start-2 xl:col-start-1 min-w-0">
        {!activeSubject ? (
          <>
            <div className="flex flex-col xl:flex-row xl:items-center gap-4">
              <div className="flex flex-wrap items-center gap-3 flex-1 min-w-0">
                <div className="w-full sm:w-56 max-w-full shrink-0">
                  <Input
                    value={searchSubject}
                    onChange={(e) => setSearchSubject(e.target.value)}
                    placeholder="ค้นหารหัสวิชา หรือ ชื่อวิชา..."
                    icon="fa-magnifying-glass"
                  />
                </div>
              </div>
              {selectedSubjects.size > 0 && (
                <button
                  onClick={deleteSelectedSubjects}
                  className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2 shadow-sm whitespace-nowrap shrink-0"
                  title="ลบรายการที่เลือก"
                >
                  <Icon name="fa-trash-can" /> ({selectedSubjects.size})
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
                      checked={selectedSubjects.size > 0}
                      onChange={(e) => {
                        const next = new Set(selectedSubjects);
                        if (e.target.checked) {
                          filteredSubjects.forEach((s) => next.add(s.id));
                        } else {
                          next.clear();
                        }
                        setSelectedSubjects(next);
                        setLastSelectedSubjectIndex(null);
                        setLastShiftSubjectIndex(null);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                  render: (row) => (
                    <input
                      type="checkbox"
                      checked={selectedSubjects.has(row.id)}
                      onChange={(e) => {
                        const currentIndex = filteredSubjects.findIndex(
                          (x) => x.id === row.id,
                        );
                        const next = new Set(selectedSubjects);

                        if (
                          e.nativeEvent.shiftKey &&
                          lastSelectedSubjectIndex !== null
                        ) {
                          const oldStart =
                            lastShiftSubjectIndex !== null
                              ? Math.min(
                                  lastShiftSubjectIndex,
                                  lastSelectedSubjectIndex,
                                )
                              : lastSelectedSubjectIndex;
                          const oldEnd =
                            lastShiftSubjectIndex !== null
                              ? Math.max(
                                  lastShiftSubjectIndex,
                                  lastSelectedSubjectIndex,
                                )
                              : lastSelectedSubjectIndex;

                          const newStart = Math.min(
                            currentIndex,
                            lastSelectedSubjectIndex,
                          );
                          const newEnd = Math.max(
                            currentIndex,
                            lastSelectedSubjectIndex,
                          );

                          for (let i = oldStart; i <= oldEnd; i++) {
                            if (i < newStart || i > newEnd) {
                              next.delete(filteredSubjects[i].id);
                            }
                          }

                          const targetState = selectedSubjects.has(
                            filteredSubjects[lastSelectedSubjectIndex].id,
                          );
                          for (let i = newStart; i <= newEnd; i++) {
                            if (targetState) next.add(filteredSubjects[i].id);
                            else next.delete(filteredSubjects[i].id);
                          }
                          setLastShiftSubjectIndex(currentIndex);
                        } else {
                          if (e.target.checked) next.add(row.id);
                          else next.delete(row.id);
                          setLastSelectedSubjectIndex(currentIndex);
                          setLastShiftSubjectIndex(currentIndex);
                        }

                        setSelectedSubjects(next);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                },
                {
                  key: "code",
                  label: "รหัสวิชา",
                  className: "w-24 text-left",
                },
                { key: "name", label: "ชื่อวิชา" },
                {
                  key: "termYear",
                  label: "ภาค/ปี",
                  className: "w-20 text-center",
                  render: (row) => `${row.term || "-"}/${row.year || "-"}`,
                },
                {
                  key: "teacher",
                  label: "ผู้สอน",
                  className: "truncate text-left",
                },
                {
                  key: "actions",
                  label: "",
                  truncate: false,
                  className: "w-[200px] text-right",
                  render: (row) => (
                    <div className="flex flex-nowrap gap-2 justify-end">
                      <GhostButton
                        variant="primary"
                        className="py-1.5 px-2.5 text-sm"
                        title="จัดการกลุ่มเรียน"
                        onClick={() => setActiveSubject(row.id)}
                      >
                        <Icon name="fa-users" /> กลุ่ม
                      </GhostButton>
                      <GhostButton
                        className="py-2 px-3"
                        onClick={() =>
                          setSubjectForm({
                            ...emptyForm([
                              "id",
                              "code",
                              "name",
                              "term",
                              "year",
                              "teacher",
                            ]),
                            ...row,
                            term: row.term || "1",
                            year:
                              row.year ||
                              String(new Date().getFullYear() + 543),
                          })
                        }
                      >
                        <Icon name="fa-pen" />
                      </GhostButton>
                      <GhostButton
                        variant="danger"
                        className="py-2 px-3"
                        onClick={() => deleteSubject(row)}
                      >
                        <Icon name="fa-trash" />
                      </GhostButton>
                    </div>
                  ),
                },
              ]}
              rows={filteredSubjects}
              emptyText="ยังไม่มีรายวิชาในระบบ"
            />
          </>
        ) : (
          <>
            <div className="flex flex-col xl:flex-row xl:items-center gap-4">
              <div className="flex flex-wrap items-center gap-3 flex-1 min-w-0">
                <div className="w-full sm:w-56 max-w-full shrink-0">
                  <Input
                    value={searchSection}
                    onChange={(e) => setSearchSection(e.target.value)}
                    placeholder="ค้นหากลุ่มเรียน..."
                    icon="fa-magnifying-glass"
                  />
                </div>
              </div>
              {selectedSections.size > 0 && (
                <button
                  onClick={deleteSelectedSections}
                  className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2 shadow-sm whitespace-nowrap shrink-0"
                  title="ลบรายการที่เลือก"
                >
                  <Icon name="fa-trash-can" /> ({selectedSections.size})
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
                      checked={selectedSections.size > 0}
                      onChange={(e) => {
                        const next = new Set(selectedSections);
                        if (e.target.checked) {
                          filteredSections.forEach((s) => next.add(s.id));
                        } else {
                          next.clear();
                        }
                        setSelectedSections(next);
                        setLastSelectedSectionIndex(null);
                        setLastShiftSectionIndex(null);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                  render: (row) => (
                    <input
                      type="checkbox"
                      checked={selectedSections.has(row.id)}
                      onChange={(e) => {
                        const currentIndex = filteredSections.findIndex(
                          (x) => x.id === row.id,
                        );
                        const next = new Set(selectedSections);

                        if (
                          e.nativeEvent.shiftKey &&
                          lastSelectedSectionIndex !== null
                        ) {
                          const oldStart =
                            lastShiftSectionIndex !== null
                              ? Math.min(
                                  lastShiftSectionIndex,
                                  lastSelectedSectionIndex,
                                )
                              : lastSelectedSectionIndex;
                          const oldEnd =
                            lastShiftSectionIndex !== null
                              ? Math.max(
                                  lastShiftSectionIndex,
                                  lastSelectedSectionIndex,
                                )
                              : lastSelectedSectionIndex;

                          const newStart = Math.min(
                            currentIndex,
                            lastSelectedSectionIndex,
                          );
                          const newEnd = Math.max(
                            currentIndex,
                            lastSelectedSectionIndex,
                          );

                          for (let i = oldStart; i <= oldEnd; i++) {
                            if (i < newStart || i > newEnd) {
                              next.delete(filteredSections[i].id);
                            }
                          }

                          const targetState = selectedSections.has(
                            filteredSections[lastSelectedSectionIndex].id,
                          );
                          for (let i = newStart; i <= newEnd; i++) {
                            if (targetState) next.add(filteredSections[i].id);
                            else next.delete(filteredSections[i].id);
                          }
                          setLastShiftSectionIndex(currentIndex);
                        } else {
                          if (e.target.checked) next.add(row.id);
                          else next.delete(row.id);
                          setLastSelectedSectionIndex(currentIndex);
                          setLastShiftSectionIndex(currentIndex);
                        }

                        setSelectedSections(next);
                      }}
                      className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                    />
                  ),
                },
                {
                  key: "subject",
                  label: "รายวิชา",
                  className: "text-left",
                  render: (row) =>
                    data.subjects.find((subject) => subject.id === row.subject)
                      ?.name || row.subject,
                },
                { key: "sec", label: "กลุ่มเรียน", className: "text-center" },
                {
                  key: "actions",
                  label: "",
                  truncate: false,
                  className: "w-[240px] text-right",
                  render: (row) => (
                    <div className="flex flex-nowrap gap-2 justify-end">
                      <GhostButton
                        className="py-2 px-3"
                        onClick={() =>
                          setSectionForm({
                            ...emptyForm(["id", "subject", "sec"]),
                            ...row,
                          })
                        }
                        title="แก้ไขกลุ่มเรียน"
                      >
                        <Icon name="fa-pen" />
                      </GhostButton>
                      <GhostButton
                        variant="danger"
                        className="py-2 px-3"
                        onClick={() => deleteSection(row)}
                      >
                        <Icon name="fa-trash" />
                      </GhostButton>
                    </div>
                  ),
                },
              ]}
              rows={filteredSections}
              emptyText="ยังไม่มีกลุ่มเรียน"
            />
          </>
        )}
      </section>

      <aside className="space-y-6 order-2 xl:row-start-1 xl:col-start-2 xl:row-span-2">
        {!activeSubject ? (
          <form
            onSubmit={saveSubject}
            className="bg-white rounded-lg border border-zinc-200 border-t-4 border-t-blue-600 p-5  space-y-4"
          >
            <h4 className="text-lg font-bold text-slate-800">
              {subjectForm.id ? "แก้ไขรายวิชา" : "เพิ่มรายวิชา"}
            </h4>
            <Field label="รหัสวิชา">
              <Input
                value={subjectForm.code}
                onChange={(e) =>
                  setSubjectForm({ ...subjectForm, code: e.target.value })
                }
                placeholder="เช่น CS101"
                required
                disabled={Boolean(subjectForm.id)}
              />
            </Field>
            <Field label="ชื่อวิชา">
              <Input
                value={subjectForm.name}
                onChange={(e) =>
                  setSubjectForm({ ...subjectForm, name: e.target.value })
                }
                placeholder="เช่น Introduction to Programming"
                required
              />
            </Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="ภาคเรียน">
                <div className="flex items-center justify-between border border-gray-200 rounded-xl overflow-hidden h-[42px] px-2 bg-slate-50 focus-within:border-blue-500 focus-within:bg-white transition-colors">
                  <button
                    type="button"
                    onClick={() => {
                      const v = parseInt(subjectForm.term) || 1;
                      if (v > 1)
                        setSubjectForm({ ...subjectForm, term: String(v - 1) });
                    }}
                    className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-200 text-slate-600 transition-colors"
                  >
                    <Icon name="fa-minus" />
                  </button>
                  <span className="font-semibold text-slate-700 text-sm">
                    {subjectForm.term || "1"}
                  </span>
                  <button
                    type="button"
                    onClick={() => {
                      const v = parseInt(subjectForm.term) || 1;
                      if (v < 3)
                        setSubjectForm({ ...subjectForm, term: String(v + 1) });
                    }}
                    className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-200 text-slate-600 transition-colors"
                  >
                    <Icon name="fa-plus" />
                  </button>
                </div>
              </Field>
              <Field label="ปีการศึกษา">
                <Input
                  value={subjectForm.year}
                  onChange={(e) =>
                    setSubjectForm({ ...subjectForm, year: e.target.value })
                  }
                  placeholder="เช่น 2567"
                />
              </Field>
            </div>
            <Field label="ผู้สอน">
              <Input
                value={subjectForm.teacher}
                placeholder="ชื่อผู้สอน"
                disabled
                className="bg-slate-100 text-slate-500 cursor-not-allowed border-slate-200"
              />
            </Field>
            <PrimaryButton className="w-full">
              <Icon name="fa-floppy-disk" /> บันทึกรายวิชา
            </PrimaryButton>
          </form>
        ) : (
          <form
            onSubmit={saveSection}
            className="bg-white rounded-lg border border-zinc-200 border-t-4 border-t-blue-600 p-5 space-y-4"
          >
            <div className="flex items-center justify-between">
              <h4 className="text-lg font-bold text-slate-800">
                {sectionForm.id ? "แก้ไขกลุ่มเรียน" : "เพิ่มกลุ่มเรียน"}
              </h4>
              {sectionForm.id && (
                <button
                  type="button"
                  onClick={() =>
                    setSectionForm(emptyForm(["id", "subject", "sec", "count"]))
                  }
                  className="text-xs text-slate-500 hover:text-slate-700 underline font-medium"
                >
                  ยกเลิก
                </button>
              )}
            </div>

            <div className="bg-blue-50 p-4 rounded-md border border-blue-100 text-blue-700 text-sm mb-2">
              <div className="font-bold flex items-center gap-2">
                <Icon name="fa-book" /> {currentSubject?.code}
              </div>
              <div className="mt-1 opacity-80">{currentSubject?.name}</div>
            </div>

            {sectionForm.id ? (
              <Field label="กลุ่มเรียน / Section">
                <Input
                  value={sectionForm.sec}
                  onChange={(e) =>
                    setSectionForm({ ...sectionForm, sec: e.target.value })
                  }
                  placeholder="เช่น 1 หรือ 01"
                  required
                />
              </Field>
            ) : (
              <Field label="จำนวนกลุ่มเรียนที่ต้องการเพิ่ม">
                <Input
                  type="number"
                  min="1"
                  max="50"
                  value={sectionForm.count ?? ""}
                  onChange={(e) =>
                    setSectionForm({ ...sectionForm, count: e.target.value })
                  }
                  placeholder="เช่น 1 หรือ 3"
                  required
                />
                <p className="text-xs text-slate-400 mt-1">
                  ระบบจะสร้างหมายเลขกลุ่มเรียนถัดไปให้อัตโนมัติ (เช่น กลุ่ม 1,
                  2, 3...)
                </p>
              </Field>
            )}

            <PrimaryButton className="w-full">
              <Icon name="fa-floppy-disk" />{" "}
              {sectionForm.id ? "บันทึกการแก้ไข" : "สร้างกลุ่มเรียน"}
            </PrimaryButton>
          </form>
        )}
      </aside>
    </div>
  );
}
