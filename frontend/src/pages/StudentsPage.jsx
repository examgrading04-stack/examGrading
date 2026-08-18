import { useRef, useState } from "react";
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

export function StudentsPage({ data, api, refresh }) {
  const [form, setForm] = useState(
    emptyForm(["id", "name", "section", "subjectCode"]),
  );
  const [isEditing, setIsEditing] = useState(false);
  const [importOpen, setImportOpen] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [importSubject, setImportSubject] = useState("");
  const [importClass, setImportClass] = useState("");
  const [searchText, setSearchText] = useState("");
  const [selectedStudents, setSelectedStudents] = useState(new Set());
  const [lastSelectedStudentIndex, setLastSelectedStudentIndex] =
    useState(null);
  const [lastShiftStudentIndex, setLastShiftStudentIndex] = useState(null);
  const fileRef = useRef(null);

  const importSections = importSubject
    ? data.sections.filter((section) => section.subject === importSubject)
    : data.sections;

  const subjectById = new Map(data.subjects.map((s) => [String(s.id), s]));
  const subjectByCode = new Map(
    data.subjects.map((s) => [String(s.code || "").toLowerCase(), s]),
  );

  async function saveStudent(event) {
    event.preventDefault();

    const studentIdTrimmed = String(form.id || "").trim();
    if (!studentIdTrimmed) {
      return Swal().fire({
        title: "กรุณากรอกรหัสผู้เรียน",
        icon: "warning",
        confirmButtonText: "ตกลง",
      });
    }

    if (!form.name || !form.name.trim()) {
      return Swal().fire({
        title: "กรุณากรอกชื่อ-นามสกุล",
        icon: "warning",
        confirmButtonText: "ตกลง",
      });
    }

    if (
      (form.subjectCode && !form.section) ||
      (!form.subjectCode && form.section)
    ) {
      return Swal().fire({
        title: "ข้อมูลไม่ครบถ้วน",
        text: "หากต้องการเพิ่มนักเรียนเข้าวิชา กรุณาเลือกทั้ง 'วิชา' และ 'กลุ่มเรียน'",
        icon: "warning",
        confirmButtonText: "ตกลง",
      });
    }

    const existingStudent = data.students.find((s) => {
      const matchId =
        String(s.id || s.code || "")
          .trim()
          .toLowerCase() === studentIdTrimmed.toLowerCase();
      const matchSubject =
        String(s.subjectCode || s.subject || "")
          .trim()
          .toLowerCase() ===
        String(form.subjectCode || "")
          .trim()
          .toLowerCase();
      if (!isEditing) {
        return matchId && matchSubject;
      } else {
        const sameRecord =
          (s.id === form.id || s.code === form.id) &&
          (s.subjectCode === form.subjectCode ||
            s.subject === form.subjectCode);
        return matchId && matchSubject && !sameRecord;
      }
    });

    if (existingStudent) {
      return Swal().fire({
        title: "รหัสผู้เรียนนี้มีอยู่แล้ว",
        text: `รหัสผู้เรียน "${studentIdTrimmed}" (${existingStudent.name || ""}) มีอยู่ในรายวิชานี้เรียบร้อยแล้ว`,
        icon: "warning",
        confirmButtonText: "ตกลง",
      });
    }

    const nameTrimmed = String(form.name || "").trim();
    const existingName = data.students.find((s) => {
      const matchName =
        String(s.name || "")
          .trim()
          .toLowerCase() === nameTrimmed.toLowerCase();
      const matchSubject =
        String(s.subjectCode || s.subject || "")
          .trim()
          .toLowerCase() ===
        String(form.subjectCode || "")
          .trim()
          .toLowerCase();
      if (!isEditing) {
        return matchName && matchSubject;
      } else {
        const sameRecord =
          (s.id === form.id || s.code === form.id) &&
          (s.subjectCode === form.subjectCode ||
            s.subject === form.subjectCode);
        return matchName && matchSubject && !sameRecord;
      }
    });

    if (existingName) {
      return Swal().fire({
        title: "ชื่อ-นามสกุลนี้มีอยู่แล้ว",
        text: `ชื่อ-นามสกุล "${nameTrimmed}" (รหัสผู้เรียน: ${existingName.id || existingName.code || ""}) มีอยู่ในรายวิชานี้เรียบร้อยแล้ว`,
        icon: "warning",
        confirmButtonText: "ตกลง",
      });
    }

    Swal().fire({
      title: isEditing
        ? "กำลังแก้ไขข้อมูลผู้เรียน..."
        : "กำลังบันทึกผู้เรียน...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });

    const payload = {
      id: studentIdTrimmed,
      name: form.name.trim(),
      section: form.section,
      subjectCode: form.subjectCode || "",
    };

    try {
      Swal().fire({
        title: "กำลังบันทึก...",
        allowOutsideClick: false,
        didOpen: () => {
          Swal().showLoading();
        },
      });
      await api.set(`students/${payload.id}`, payload);
      setForm(emptyForm(["id", "name", "section", "subjectCode"]));
      setIsEditing(false);
      await refresh("บันทึกข้อมูลผู้เรียนเรียบร้อยแล้ว");
    } catch (err) {
      Swal().fire({
        title: "เกิดข้อผิดพลาด",
        text: err.message || "ไม่สามารถบันทึกข้อมูลได้",
        icon: "error",
      });
    }
  }

  async function deleteStudent(row) {
    const result = await Swal().fire({
      title: "ลบผู้เรียน?",
      text: row.name,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบ",
      cancelButtonText: "ยกเลิก",
    });
    if (!result.isConfirmed) return;
    Swal().fire({
      title: "กำลังลบ...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    try {
      if (row.id != null && row.id !== "") {
        await api.remove("students", row.id);
      }
      await refresh("ลบผู้เรียนแล้ว");
    } catch (err) {
      Swal().fire({
        title: "เกิดข้อผิดพลาด",
        text: err.message || "ไม่สามารถลบข้อมูลได้",
        icon: "error",
      });
    }
  }

  async function deleteSelectedStudents() {
    if (selectedStudents.size === 0) return;
    const count = selectedStudents.size;
    const result = await Swal().fire({
      title: "ลบผู้เรียนที่เลือก?",
      text: `ต้องการลบข้อมูลผู้เรียนจำนวน ${count} คนหรือไม่`,
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

    try {
      const idsToDelete = new Set();
      for (const uniqueId of selectedStudents) {
        const student = data.students.find(
          (s) => `${s.id}_${s.subjectCode}` === uniqueId || s.id === uniqueId,
        );
        if (student) idsToDelete.add(student.id);
        else idsToDelete.add(uniqueId.split("_")[0]);
      }

      const validIds = Array.from(idsToDelete).filter(
        (id) => id != null && id !== "",
      );
      await Promise.all(validIds.map((id) => api.remove("students", id)));

      setSelectedStudents(new Set());
      await refresh(`ลบผู้เรียน ${validIds.length} รายการแล้ว`);
    } catch (err) {
      Swal().fire({
        title: "เกิดข้อผิดพลาด",
        text: err.message || "ไม่สามารถลบข้อมูลได้",
        icon: "error",
      });
    }
  }

  const [batchEnrollOpen, setBatchEnrollOpen] = useState(false);
  const [batchSubject, setBatchSubject] = useState("");
  const [batchClass, setBatchClass] = useState("");
  const [isBatchEnrolling, setIsBatchEnrolling] = useState(false);

  const batchSections = batchSubject
    ? data.sections.filter((section) => section.subject === batchSubject)
    : [];

  async function enrollSelectedStudents() {
    if (selectedStudents.size === 0) return;
    if (!batchSubject || !batchClass) {
      Swal().fire({
        title: "ข้อมูลไม่ครบถ้วน",
        text: "กรุณาเลือกวิชาและกลุ่มเรียน",
        icon: "warning",
      });
      return;
    }

    setIsBatchEnrolling(true);
    try {
      const uniqueIds = new Set();
      for (const uniqueId of selectedStudents) {
        uniqueIds.add(uniqueId.split("_")[0]);
      }

      const studentsToEnroll = Array.from(uniqueIds).map((id) => {
        return (
          data.students.find((s) => s.id === id || s.code === id) || {
            id,
            name: "",
          }
        );
      });

      let count = 0;
      for (const student of studentsToEnroll) {
        if (!student.name) continue;

        const payload = {
          id: student.id,
          name: student.name,
          section: batchClass,
          subjectCode: batchSubject,
        };
        await api.set(`students/${payload.id}`, payload);
        count++;
      }

      setBatchEnrollOpen(false);
      setBatchSubject("");
      setBatchClass("");
      setSelectedStudents(new Set());
      await refresh(`ลงทะเบียนผู้เรียน ${count} คน เรียบร้อยแล้ว`);
    } catch (err) {
      Swal().fire(
        "เกิดข้อผิดพลาด",
        err.message || "ไม่สามารถลงทะเบียนได้",
        "error",
      );
    } finally {
      setIsBatchEnrolling(false);
    }
  }

  function getRowValue(row, keys) {
    for (const key of keys) {
      if (row[key] !== undefined && row[key] !== null && row[key] !== "") {
        return String(row[key]).trim();
      }
    }
    return "";
  }

  function resolveSubjectId(rawSubject) {
    if (!rawSubject) return "";
    const normalized = String(rawSubject).trim();
    if (subjectById.has(normalized)) return normalized;
    const byCode = subjectByCode.get(normalized.toLowerCase());
    return byCode?.id || "";
  }

  function resolveClassFromRow(row) {
    const rawClass = getRowValue(row, [
      "class",
      "Class",
      "sectionId",
      "section_id",
      "กลุ่มเรียน",
    ]);

    if (rawClass) {
      const direct = data.sections.find(
        (section) => section.id === rawClass || section.realId === rawClass,
      );
      if (direct) return direct.id;
    }

    const rawSection = getRowValue(row, ["section", "Section", "sec", "Sec"]);
    const rawSubject = getRowValue(row, [
      "subject",
      "Subject",
      "subjectCode",
      "subject_code",
      "วิชา",
      "รหัสวิชา",
    ]);

    const subjectIdFromRow = resolveSubjectId(rawSubject);
    const subjectIdForLookup = subjectIdFromRow || importSubject || "";

    if (rawSection && subjectIdForLookup) {
      const matched = data.sections.find(
        (section) =>
          section.subject === subjectIdForLookup &&
          String(section.sec || "") === String(rawSection),
      );
      if (matched) return matched.id;
    }

    if (rawSection && !subjectIdForLookup) {
      const bySec = data.sections.filter(
        (section) => String(section.sec || "") === String(rawSection),
      );
      if (bySec.length === 1) return bySec[0].id;
    }

    return importClass || "";
  }

  async function importExcel(event) {
    const file = event.target.files?.[0];
    if (!file || !window.XLSX) return;

    setIsImporting(true);
    try {
      const buffer = await file.arrayBuffer();
      const wb = window.XLSX.read(buffer, { type: "array" });
      const sheet = wb.Sheets[wb.SheetNames[0]];
      const rows = window.XLSX.utils.sheet_to_json(sheet);

      if (importSubject && !importClass) {
        setIsImporting(false);
        Swal().fire({
          icon: "warning",
          title: "ข้อมูลไม่ครบถ้วน",
          text: "กรุณาเลือกกลุ่มเรียนให้ครบถ้วนก่อนนำเข้าไฟล์ Excel",
        });
        return;
      }

      Swal().fire({
        title: "กำลังนำเข้าข้อมูล...",
        allowOutsideClick: false,
        didOpen: () => Swal().showLoading(),
      });

      let count = 0;
      let skippedMissing = 0;
      let skippedDuplicates = [];
      const processedIds = new Set();
      const processedNames = new Set();

      for (const row of rows) {
        const code =
          row["รหัสผู้เรียน"] ||
          row["รหัสนักศึกษา"] ||
          row.ID ||
          row.code ||
          row["เลขประจำตัว"];
        const name = row["ชื่อ-นามสกุล"] || row["ชื่อ"] || row.Name || row.name;

        if (code && name) {
          const subjectCode = importSubject;
          const sectionId = importClass;

          const codeTrimmed = String(code).trim();
          const nameTrimmed = String(name).trim();
          const codeLower = codeTrimmed.toLowerCase();
          const nameLower = nameTrimmed.toLowerCase();

          // Check if already processed in this file
          if (processedIds.has(codeLower)) {
            skippedDuplicates.push(nameTrimmed);
            continue;
          }

          const isMasterListImport = !subjectCode;

          const duplicateId = data.students.find((s) => {
            const matchId =
              String(s.id || s.code || "")
                .trim()
                .toLowerCase() === codeLower;
            if (!matchId) return false;

            if (isMasterListImport) {
              return true; // Any existing record means it's already in the system
            } else {
              return (
                String(s.subjectCode || s.subject || "")
                  .trim()
                  .toLowerCase() === String(subjectCode).trim().toLowerCase()
              );
            }
          });

          if (duplicateId) {
            skippedDuplicates.push(nameTrimmed);
            continue;
          }

          // Mark as processed
          processedIds.add(codeLower);

          // บันทึกผู้เรียน
          const payload = {
            id: codeTrimmed,
            name: nameTrimmed,
            section: sectionId,
            subjectCode: subjectCode,
          };
          await api.set(`students/${payload.id}`, payload);
          count += 1;
        } else {
          skippedMissing += 1;
        }
      }

      event.target.value = "";
      setImportOpen(false);
      setImportSubject("");
      setImportClass("");

      Swal().hideLoading();
      Swal().close();

      if (skippedDuplicates.length > 0) {
        await Swal().fire({
          icon: "warning",
          title: "นำเข้าเสร็จสิ้น (มีข้อมูลซ้ำ)",
          text: `นำเข้าสำเร็จ ${count} คน, ไม่สมบูรณ์ ${skippedMissing} แถว\nพบข้อมูลซ้ำซ้อนและถูกข้าม ${skippedDuplicates.length} รายการ`,
          showConfirmButton: true,
          didOpen: () => Swal().hideLoading(),
        });
        await refresh();
      } else if (skippedMissing > 0) {
        await refresh(
          `นำเข้าสำเร็จ ${count} คน (ข้าม ${skippedMissing} แถวที่ข้อมูลไม่สมบูรณ์หรือไม่ระบุวิชา)`,
        );
      } else {
        await refresh(`นำเข้าผู้เรียน ${count} คนเรียบร้อยแล้ว`);
      }
    } catch (err) {
      console.error(err);
      Swal().fire(
        "เกิดข้อผิดพลาด",
        err.message || "ไม่สามารถนำเข้าไฟล์ Excel ได้",
        "error",
      );
    } finally {
      setIsImporting(false);
    }
  }

  const [filterSubject, setFilterSubject] = useState("");
  const [filterSection, setFilterSection] = useState("");
  const filterSections =
    filterSubject && filterSubject !== "__UNSPECIFIED__"
      ? data.sections.filter((section) => section.subject === filterSubject)
      : data.sections;
  const normalizedSearch = searchText.trim().toLowerCase();
  const filteredStudents = data.students.filter((student) => {
    let matchesSubject = true;
    if (filterSubject === "__UNSPECIFIED__") {
      matchesSubject = !student.subjectCode || student.subjectCode === "";
    } else if (filterSubject) {
      matchesSubject =
        student.subjectCode === filterSubject ||
        (student.section &&
          (String(student.section).startsWith(filterSubject + "_") ||
            String(student.section).includes(filterSubject)));
    }
    const matchesSection = filterSection
      ? String(student.section) === String(filterSection)
      : true;
    const matchesSearch = normalizedSearch
      ? [student.id, student.name].some((value) =>
          String(value || "")
            .toLowerCase()
            .includes(normalizedSearch),
        )
      : true;
    return matchesSubject && matchesSection && matchesSearch;
  });

  return (
    <div className="page-enter max-w-[1600px] mx-auto px-4 grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_360px] xl:grid-rows-[auto_1fr] gap-x-6 gap-y-3 items-start">
      <div className="order-1 xl:row-start-1 xl:col-start-1 min-w-0">
        <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
          <div>
            <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
              รายชื่อผู้เรียนทั้งหมด
            </h2>
            <p className="mt-1 text-sm text-slate-500">
              เพิ่มรายชื่อ หรือนำเข้าผู้เรียนจากไฟล์ Excel เข้าสู่กลุ่มเรียน
            </p>
          </div>
          {selectedStudents.size > 0 && (
            <div className="flex gap-2 shrink-0">
              <button
                onClick={() => setBatchEnrollOpen(true)}
                className="bg-blue-600 hover:bg-blue-700 text-white px-3 py-1.5 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2 shadow-sm whitespace-nowrap"
                title="ลงทะเบียนเข้าวิชา"
              >
                <Icon name="fa-user-plus" /> ลงทะเบียนวิชา (
                {
                  new Set(
                    Array.from(selectedStudents).map((id) => id.split("_")[0]),
                  ).size
                }
                )
              </button>
              <button
                onClick={deleteSelectedStudents}
                className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2 shadow-sm whitespace-nowrap"
                title="ลบรายการที่เลือก"
              >
                <Icon name="fa-trash-can" /> ลบ
              </button>
              <button
                onClick={() => setSelectedStudents(new Set())}
                className="bg-slate-200 hover:bg-slate-300 text-slate-700 px-3 py-1.5 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2 shadow-sm whitespace-nowrap"
                title="ยกเลิกการเลือก"
              >
                <Icon name="fa-xmark" />
              </button>
            </div>
          )}
        </div>
      </div>
      <section className="space-y-3 order-3 xl:row-start-2 xl:col-start-1 min-w-0">
        <div className="flex flex-col xl:flex-row xl:items-center gap-4">
          <div className="flex flex-wrap items-center gap-3 flex-1 min-w-0">
            <div className="w-full sm:w-56 max-w-full shrink-0">
              <Input
                value={searchText}
                onChange={(event) => setSearchText(event.target.value)}
                placeholder="ค้นหารหัสผู้เรียนหรือชื่อ"
              />
            </div>
            <div className="w-full sm:w-48 shrink-0">
              <Select
                value={filterSubject}
                onChange={(event) => {
                  setFilterSubject(event.target.value);
                  setFilterSection("");
                }}
              >
                <option value="">ทุกวิชา</option>
                <option value="__UNSPECIFIED__">ไม่ระบุวิชา</option>
                {data.subjects.map((subject) => (
                  <option key={subject.id} value={subject.id}>
                    {subject.name}
                  </option>
                ))}
              </Select>
            </div>
            {filterSubject && filterSubject !== "__UNSPECIFIED__" && (
              <div className="w-full sm:w-48 shrink-0">
                <Select
                  value={filterSection}
                  onChange={(event) => setFilterSection(event.target.value)}
                >
                  <option value="">ทุกกลุ่มเรียน</option>
                  {filterSections.map((section) => (
                    <option key={section.id} value={section.id}>
                      {section.sec} ({section.subject})
                    </option>
                  ))}
                </Select>
              </div>
            )}
          </div>
        </div>
        <DataTable
          columns={[
            {
              key: "select",
              className: "w-12 text-center px-2",
              label: (
                <input
                  type="checkbox"
                  checked={
                    filteredStudents.length > 0 &&
                    filteredStudents.every((s) =>
                      selectedStudents.has(`${s.id}_${s.subjectCode}`),
                    )
                  }
                  onChange={(e) => {
                    const next = new Set(selectedStudents);
                    if (e.target.checked) {
                      filteredStudents.forEach((s) =>
                        next.add(`${s.id}_${s.subjectCode}`),
                      );
                    } else {
                      filteredStudents.forEach((s) =>
                        next.delete(`${s.id}_${s.subjectCode}`),
                      );
                    }
                    setSelectedStudents(next);
                    setLastSelectedStudentIndex(null);
                    setLastShiftStudentIndex(null);
                  }}
                  className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                />
              ),
              render: (row) => (
                <input
                  type="checkbox"
                  checked={selectedStudents.has(`${row.id}_${row.subjectCode}`)}
                  onChange={(e) => {
                    const currentIndex = filteredStudents.findIndex(
                      (x) =>
                        x.id === row.id && x.subjectCode === row.subjectCode,
                    );
                    const next = new Set(selectedStudents);

                    if (
                      e.nativeEvent.shiftKey &&
                      lastSelectedStudentIndex !== null
                    ) {
                      const oldStart =
                        lastShiftStudentIndex !== null
                          ? Math.min(
                              lastShiftStudentIndex,
                              lastSelectedStudentIndex,
                            )
                          : lastSelectedStudentIndex;
                      const oldEnd =
                        lastShiftStudentIndex !== null
                          ? Math.max(
                              lastShiftStudentIndex,
                              lastSelectedStudentIndex,
                            )
                          : lastSelectedStudentIndex;

                      const newStart = Math.min(
                        currentIndex,
                        lastSelectedStudentIndex,
                      );
                      const newEnd = Math.max(
                        currentIndex,
                        lastSelectedStudentIndex,
                      );

                      for (let i = oldStart; i <= oldEnd; i++) {
                        if (i < newStart || i > newEnd) {
                          next.delete(
                            `${filteredStudents[i].id}_${filteredStudents[i].subjectCode}`,
                          );
                        }
                      }

                      const targetState = selectedStudents.has(
                        `${filteredStudents[lastSelectedStudentIndex].id}_${filteredStudents[lastSelectedStudentIndex].subjectCode}`,
                      );
                      for (let i = newStart; i <= newEnd; i++) {
                        const uniqueId = `${filteredStudents[i].id}_${filteredStudents[i].subjectCode}`;
                        if (targetState) next.add(uniqueId);
                        else next.delete(uniqueId);
                      }
                      setLastShiftStudentIndex(currentIndex);
                    } else {
                      const uniqueId = `${row.id}_${row.subjectCode}`;
                      if (e.target.checked) next.add(uniqueId);
                      else next.delete(uniqueId);
                      setLastSelectedStudentIndex(currentIndex);
                      setLastShiftStudentIndex(currentIndex);
                    }

                    setSelectedStudents(next);
                  }}
                  className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                />
              ),
            },
            {
              key: "id",
              label: "รหัสผู้เรียน",
              className: "w-[150px] text-left",
            },
            { key: "name", label: "ชื่อ-นามสกุล" },
            {
              key: "subject",
              label: "รายวิชา",
              className: "w-[160px] text-center",
              render: (row) => {
                const subjectId = row.subjectCode || row.section?.split("_")[0];
                return (
                  data.subjects.find(
                    (s) => s.id === subjectId || s.code === subjectId,
                  )?.name ||
                  subjectId ||
                  "-"
                );
              },
            },
            {
              key: "section",
              label: "กลุ่มเรียน",
              className: "w-[100px] text-center",
              render: (row) =>
                data.sections.find((s) => String(s.id) === String(row.section))
                  ?.sec ||
                row.section ||
                "ไม่ระบุ",
            },
            {
              key: "actions",
              label: "",
              truncate: false,
              className: "w-[120px] text-right",
              render: (row) => (
                <div className="flex flex-nowrap justify-end gap-2">
                  <GhostButton
                    className="py-2 px-3"
                    onClick={() => {
                      setForm({
                        ...emptyForm(["id", "name", "section", "subjectCode"]),
                        ...row,
                      });
                      setIsEditing(true);
                    }}
                  >
                    <Icon name="fa-pen" />
                  </GhostButton>
                  <GhostButton
                    variant="danger"
                    className="py-2 px-3"
                    onClick={() => deleteStudent(row)}
                  >
                    <Icon name="fa-trash" />
                  </GhostButton>
                </div>
              ),
            },
          ]}
          rows={filteredStudents}
        />
      </section>
      <form
        onSubmit={saveStudent}
        className="bg-white/95 rounded-lg border border-zinc-200 border-t-4 border-t-blue-600 p-5 space-y-4 h-fit order-2 xl:row-start-1 xl:col-start-2 xl:row-span-2"
      >
        <div className="flex items-center justify-between mb-2">
          <h4 className="text-lg font-bold text-slate-800">
            {isEditing ? "แก้ไขผู้เรียน" : "เพิ่มผู้เรียนใหม่"}
          </h4>
          {!isEditing ? (
            <>
              <input
                ref={fileRef}
                type="file"
                accept=".xlsx,.xls,.csv"
                onChange={importExcel}
                className="hidden"
              />
              <GhostButton
                type="button"
                variant="primary"
                onClick={() => setImportOpen(true)}
                className="py-1 px-3 text-sm whitespace-nowrap bg-blue-50 hover:bg-blue-100"
              >
                <Icon name="fa-file-import" /> นำเข้า Excel
              </GhostButton>
            </>
          ) : (
            <GhostButton
              type="button"
              onClick={() => {
                setForm(emptyForm(["id", "name", "section", "subjectCode"]));
                setIsEditing(false);
              }}
              className="py-1 px-3 text-sm whitespace-nowrap text-zinc-500 hover:text-zinc-800 hover:bg-zinc-100"
            >
              <Icon name="fa-xmark" /> ยกเลิก
            </GhostButton>
          )}
        </div>
        <Field label="รหัสผู้เรียน">
          <Input
            value={form.id || ""}
            onChange={(e) => setForm({ ...form, id: e.target.value })}
            placeholder="เช่น 6400123"
            required
            disabled={isEditing}
          />
        </Field>
        <Field label="ชื่อ-นามสกุล">
          <Input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            placeholder="เช่น นายสมชาย รักเรียน"
            required
          />
        </Field>
        <Field label="วิชา (ตัวเลือก)">
          <Select
            value={form.subjectCode || ""}
            onChange={(e) => {
              setForm({ ...form, subjectCode: e.target.value, section: "" });
            }}
          >
            <option value="">ไม่ระบุ</option>
            {data.subjects.map((subject) => (
              <option key={subject.id} value={subject.id}>
                {subject.code} - {subject.name}
              </option>
            ))}
          </Select>
        </Field>
        {form.subjectCode && (
          <Field label="กลุ่มเรียน (ตัวเลือก)">
            <Select
              value={form.section || ""}
              onChange={(e) => setForm({ ...form, section: e.target.value })}
            >
              <option value="">กรุณาเลือกกลุ่มเรียน</option>
              {data.sections
                .filter((s) => s.subject === form.subjectCode)
                .map((section) => (
                  <option key={section.id} value={section.id}>
                    {section.sec}
                  </option>
                ))}
            </Select>
          </Field>
        )}
        <PrimaryButton className="w-full">
          <Icon name="fa-floppy-disk" /> บันทึกผู้เรียน
        </PrimaryButton>
      </form>

      {importOpen && (
        <div className="fixed inset-0 z-50 bg-zinc-950/45 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="relative bg-white rounded-2xl w-full max-w-lg mx-auto shadow-2xl flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center px-6 py-5 border-b border-zinc-100 shrink-0">
              <div>
                <h3 className="text-xl font-bold text-slate-800">
                  นำเข้าผู้เรียนจาก Excel
                </h3>
              </div>
              <GhostButton
                type="button"
                className="py-2 px-3"
                disabled={isImporting}
                onClick={() => setImportOpen(false)}
              >
                <Icon name="fa-xmark" />
              </GhostButton>
            </div>

            <div className="p-6 space-y-5 overflow-visible">
              <Field label="รายวิชา (ตัวเลือก)">
                <Select
                  value={importSubject}
                  disabled={isImporting}
                  onChange={(event) => {
                    setImportSubject(event.target.value);
                    setImportClass("");
                  }}
                >
                  <option value="">ไม่ระบุ</option>
                  {data.subjects.map((subject) => (
                    <option key={subject.id} value={subject.id}>
                      {subject.code} - {subject.name}
                    </option>
                  ))}
                </Select>
              </Field>

              {importSubject && (
                <Field label="กลุ่มเรียน (ตัวเลือก)">
                  <Select
                    value={importClass}
                    disabled={isImporting}
                    onChange={(event) => setImportClass(event.target.value)}
                  >
                    <option value="">กรุณาเลือกกลุ่มเรียน</option>
                    {importSections.map((section) => (
                      <option key={section.id} value={section.id}>
                        {section.sec}
                      </option>
                    ))}
                  </Select>
                </Field>
              )}

              <div className="rounded-md border border-zinc-200 bg-zinc-50 p-4 text-sm text-zinc-600 space-y-2">
                <div className="font-bold text-zinc-700">
                  รูปแบบคอลัมน์ในไฟล์ Excel
                </div>
                <div className="space-y-1">
                  <div>
                    • <b>รหัสผู้เรียน</b> (รหัสนักศึกษา / code / ID)
                  </div>
                  <div>
                    • <b>ชื่อ-นามสกุล</b> (ชื่อ / name)
                  </div>
                </div>
              </div>

              <PrimaryButton
                type="button"
                className="w-full"
                disabled={isImporting || (importSubject && !importClass)}
                onClick={() => fileRef.current?.click()}
              >
                <Icon
                  name={isImporting ? "fa-spinner fa-spin" : "fa-file-import"}
                />{" "}
                {isImporting ? "กำลังนำเข้าข้อมูล..." : "เลือกไฟล์ Excel"}
              </PrimaryButton>
            </div>
            {isImporting && (
              <div className="absolute inset-0 rounded-lg bg-white/80 backdrop-blur-sm flex flex-col items-center justify-center gap-3">
                <div className="loader" aria-live="polite" aria-busy="true">
                  <span>LOADING</span>
                </div>
                <p className="text-sm font-medium text-slate-600">
                  กำลังนำเข้ารายชื่อผู้เรียน...
                </p>
              </div>
            )}
          </div>
        </div>
      )}

      {batchEnrollOpen && (
        <div className="fixed inset-0 z-50 bg-zinc-950/45 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="relative bg-white rounded-2xl w-full max-w-lg mx-auto shadow-2xl flex flex-col max-h-[90vh]">
            <div className="flex justify-between items-center px-6 py-5 border-b border-zinc-100 shrink-0">
              <div>
                <h3 className="text-xl font-bold text-slate-800">
                  ลงทะเบียนวิชา
                </h3>
                <p className="text-sm text-slate-500 mt-1">
                  นำนักเรียนที่เลือกทั้งหมด{" "}
                  {
                    new Set(
                      Array.from(selectedStudents).map(
                        (id) => id.split("_")[0],
                      ),
                    ).size
                  }{" "}
                  คน เข้าสู่กลุ่มเรียนใหม่
                </p>
              </div>
              <GhostButton
                type="button"
                className="py-2 px-3"
                disabled={isBatchEnrolling}
                onClick={() => setBatchEnrollOpen(false)}
              >
                <Icon name="fa-xmark" />
              </GhostButton>
            </div>

            <div className="p-6 space-y-5 overflow-visible">
              <Field label="รายวิชา">
                <Select
                  value={batchSubject}
                  disabled={isBatchEnrolling}
                  onChange={(event) => {
                    setBatchSubject(event.target.value);
                    setBatchClass("");
                  }}
                >
                  <option value="">กรุณาเลือกรายวิชา</option>
                  {data.subjects.map((subject) => (
                    <option key={subject.id} value={subject.id}>
                      {subject.code} - {subject.name}
                    </option>
                  ))}
                </Select>
              </Field>

              <Field label="กลุ่มเรียน">
                <Select
                  value={batchClass}
                  disabled={isBatchEnrolling || !batchSubject}
                  onChange={(event) => setBatchClass(event.target.value)}
                >
                  <option value="">
                    {!batchSubject
                      ? "กรุณาเลือกวิชาก่อน"
                      : "กรุณาเลือกกลุ่มเรียน"}
                  </option>
                  {batchSections.map((section) => (
                    <option key={section.id} value={section.id}>
                      {section.sec}
                    </option>
                  ))}
                </Select>
              </Field>

              <PrimaryButton
                type="button"
                className="w-full"
                disabled={isBatchEnrolling || !batchSubject || !batchClass}
                onClick={enrollSelectedStudents}
              >
                <Icon
                  name={
                    isBatchEnrolling ? "fa-spinner fa-spin" : "fa-user-plus"
                  }
                />{" "}
                {isBatchEnrolling ? "กำลังลงทะเบียน..." : "ยืนยันการลงทะเบียน"}
              </PrimaryButton>
            </div>

            {isBatchEnrolling && (
              <div className="absolute inset-0 rounded-2xl bg-white/80 backdrop-blur-sm flex flex-col items-center justify-center gap-3">
                <div className="loader" aria-live="polite" aria-busy="true">
                  <span>LOADING</span>
                </div>
                <p className="text-sm font-medium text-slate-600">
                  กำลังลงทะเบียนวิชา...
                </p>
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
