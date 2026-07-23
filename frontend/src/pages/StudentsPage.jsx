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
  const [form, setForm] = useState(emptyForm(["id", "name", "section"]));
  const [importOpen, setImportOpen] = useState(false);
  const [isImporting, setIsImporting] = useState(false);
  const [importSubject, setImportSubject] = useState("");
  const [importClass, setImportClass] = useState("");
  const [searchText, setSearchText] = useState("");
  const [selectedStudents, setSelectedStudents] = useState(new Set());
  const [lastSelectedStudentIndex, setLastSelectedStudentIndex] = useState(null);
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
    Swal().fire({
      title: "กำลังบันทึกผู้เรียน...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    const payload = {
      id: form.id,
      name: form.name,
      section: form.section,
      subjectCode: importSubject || "",
    };
    await api.set(`students/${payload.id}`, payload);
    setForm(emptyForm(["id", "name", "section"]));
    await refresh("บันทึกผู้เรียนแล้ว");
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
    await api.remove("students", row.id);
    await refresh("ลบผู้เรียนแล้ว");
  }

  async function deleteSelectedStudents() {
    if (selectedStudents.size === 0) return;
    const result = await Swal().fire({
      title: "ลบรายการที่เลือก?",
      text: `ต้องการลบข้อมูลผู้เรียนจำนวน ${selectedStudents.size} คนหรือไม่`,
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
      Array.from(selectedStudents).map((id) => api.remove("students", id)),
    );

    setSelectedStudents(new Set());
    await refresh(`ลบผู้เรียน ${selectedStudents.size} รายการแล้ว`);
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

      Swal().fire({
        title: "กำลังนำเข้าข้อมูล...",
        allowOutsideClick: false,
        didOpen: () => Swal().showLoading(),
      });

      let count = 0;
      for (const row of rows) {
        const code =
          row["รหัสผู้เรียน"] || row.ID || row.code || row["เลขประจำตัว"];
        const name = row["ชื่อ-นามสกุล"] || row["ชื่อ"] || row.Name || row.name;

        if (code && name) {
          const section_id = resolveClassFromRow(row);

          const rawSubject = getRowValue(row, [
            "subject",
            "Subject",
            "subjectCode",
            "subject_code",
            "วิชา",
            "รหัสวิชา",
          ]);
          const subject_code = resolveSubjectId(rawSubject);

          const payload = {
            id: String(code),
            name: String(name),
            section: section_id,
            subjectCode: subject_code,
          };
          await api.set(`students/${payload.id}`, payload);
          count += 1;
        }
      }

      event.target.value = "";
      setImportOpen(false);
      setImportSubject("");
      setImportClass("");
      await refresh(`นำเข้าผู้เรียน ${count} คนแล้ว`);
    } finally {
      setIsImporting(false);
    }
  }

  const [filterSubject, setFilterSubject] = useState("");
  const [filterSection, setFilterSection] = useState("");
  const filterSections = filterSubject
    ? data.sections.filter((section) => section.subject === filterSubject)
    : data.sections;
  const normalizedSearch = searchText.trim().toLowerCase();
  const filteredStudents = data.students.filter((student) => {
    const matchesSubject = filterSubject
      ? student.subjectCode === filterSubject ||
        (student.section &&
          (String(student.section).startsWith(filterSubject + "_") ||
            String(student.section).includes(filterSubject)))
      : true;
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
    <div className="page-enter max-w-[1600px] mx-auto px-4 grid grid-cols-1 xl:grid-cols-[1fr_360px] gap-6">
      <section className="space-y-6">
        <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between mb-2">
          <div>
            <h2 className="text-2xl font-extrabold text-slate-900 sm:text-3xl">
              ข้อมูลผู้เรียนทั้งหมด
            </h2>
            <p className="mt-2 text-sm text-slate-500">
              เพิ่มรายชื่อ หรือนำเข้าผู้เรียนจากไฟล์ Excel เข้าสู่กลุ่มเรียน
            </p>
          </div>
        </div>
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
                {data.subjects.map((subject) => (
                  <option key={subject.id} value={subject.id}>
                    {subject.name}
                  </option>
                ))}
              </Select>
            </div>
            {filterSubject && (
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
          {selectedStudents.size > 0 && (
            <button
              onClick={deleteSelectedStudents}
              className="bg-red-500 hover:bg-red-600 text-white px-3 py-1.5 rounded-lg text-sm font-semibold transition flex items-center justify-center gap-2 shadow-sm whitespace-nowrap shrink-0"
              title="ลบรายการที่เลือก"
            >
              <Icon name="fa-trash-can" /> ({selectedStudents.size})
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
                  checked={selectedStudents.size > 0}
                  onChange={(e) => {
                    const next = new Set(selectedStudents);
                    if (e.target.checked) {
                      filteredStudents.forEach((s) => next.add(s.id));
                    } else {
                      next.clear();
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
                  checked={selectedStudents.has(row.id)}
                  onChange={(e) => {
                    const currentIndex = filteredStudents.findIndex(x => x.id === row.id);
                    const next = new Set(selectedStudents);
                    
                    if (e.nativeEvent.shiftKey && lastSelectedStudentIndex !== null) {
                      const oldStart = lastShiftStudentIndex !== null ? Math.min(lastShiftStudentIndex, lastSelectedStudentIndex) : lastSelectedStudentIndex;
                      const oldEnd = lastShiftStudentIndex !== null ? Math.max(lastShiftStudentIndex, lastSelectedStudentIndex) : lastSelectedStudentIndex;
                      
                      const newStart = Math.min(currentIndex, lastSelectedStudentIndex);
                      const newEnd = Math.max(currentIndex, lastSelectedStudentIndex);
                      
                      for (let i = oldStart; i <= oldEnd; i++) {
                        if (i < newStart || i > newEnd) {
                          next.delete(filteredStudents[i].id);
                        }
                      }

                      const targetState = selectedStudents.has(filteredStudents[lastSelectedStudentIndex].id);
                      for (let i = newStart; i <= newEnd; i++) {
                        if (targetState) next.add(filteredStudents[i].id);
                        else next.delete(filteredStudents[i].id);
                      }
                      setLastShiftStudentIndex(currentIndex);
                    } else {
                      if (e.target.checked) next.add(row.id);
                      else next.delete(row.id);
                      setLastSelectedStudentIndex(currentIndex);
                      setLastShiftStudentIndex(currentIndex);
                    }
                    
                    setSelectedStudents(next);
                  }}
                  className="w-4 h-4 cursor-pointer rounded border-slate-300 text-blue-600 focus:ring-blue-600"
                />
              ),
            },
            { key: "id", label: "รหัสผู้เรียน", className: "w-[150px] text-left" },
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
                    onClick={() =>
                      setForm({
                        ...emptyForm(["id", "name", "section"]),
                        ...row,
                      })
                    }
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
        className="bg-white/95 rounded-lg border border-zinc-200 border-t-4 border-t-blue-600 p-5 space-y-4 h-fit"
      >
        <div className="flex items-center justify-between mb-2">
          <h4 className="font-extrabold text-lg">
            {form.id ? "แก้ไขผู้เรียน" : "เพิ่มผู้เรียน"}
          </h4>
          {!form.id && (
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
          )}
        </div>
        <Field label="รหัสผู้เรียน">
          <Input
            value={form.id || ""}
            onChange={(e) => setForm({ ...form, id: e.target.value })}
            placeholder="เช่น 6400123"
            required
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
        <Field label="กลุ่มเรียน">
          <Select
            value={form.section}
            onChange={(e) => setForm({ ...form, section: e.target.value })}
          >
            <option value="">ไม่ระบุ</option>
            {data.sections.map((section) => (
              <option key={section.id} value={section.id}>
                {section.sec} ({section.subject})
              </option>
            ))}
          </Select>
        </Field>
        <PrimaryButton className="w-full">
          <Icon name="fa-floppy-disk" /> บันทึกผู้เรียน
        </PrimaryButton>
      </form>

      {importOpen && (
        <div className="fixed inset-0 z-50 bg-zinc-950/45 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="relative bg-white/95 rounded-lg border border-zinc-200 border-t-4 border-t-blue-600 p-6 w-full max-w-lg space-y-5">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h3 className="font-extrabold text-lg">นำเข้า Excel</h3>
                <p className="text-sm text-zinc-500 mt-1">
                  รองรับการนำเข้าหลายวิชา/หลายกลุ่มเรียนในไฟล์เดียว
                </p>
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

            <Field label="รายวิชา (ค่าเริ่มต้น)">
              <Select
                value={importSubject}
                disabled={isImporting}
                onChange={(event) => {
                  setImportSubject(event.target.value);
                  setImportClass("");
                }}
              >
                <option value="">(ไม่กำหนด)</option>
                {data.subjects.map((subject) => (
                  <option key={subject.id} value={subject.id}>
                    {subject.code} - {subject.name}
                  </option>
                ))}
              </Select>
            </Field>

            <Field label="กลุ่มเรียน (ค่าเริ่มต้น)">
              <Select
                value={importClass}
                disabled={isImporting}
                onChange={(event) => setImportClass(event.target.value)}
              >
                <option value="">(ไม่กำหนด)</option>
                {importSections.map((section) => (
                  <option key={section.id} value={section.id}>
                    {section.sec}
                  </option>
                ))}
              </Select>
            </Field>

            <div className="rounded-md border border-zinc-200 bg-zinc-50 p-4 text-sm text-zinc-600">
              <div className="font-bold text-zinc-700 mb-2">รูปแบบไฟล์</div>
              <div>รหัสผู้เรียน | ชื่อ-นามสกุล</div>
              <div className="mt-1 text-zinc-500">
                รองรับคอลัมน์ภาษาอังกฤษ: code | name
              </div>
              <div className="mt-1 text-zinc-500">
                ถ้าต้องการกำหนดหลายวิชา/หลายกลุ่มในไฟล์เดียว เพิ่มคอลัมน์:
                subject (หรือ subjectCode/วิชา/รหัสวิชา) และ section (หรือ sec)
              </div>
            </div>

            <PrimaryButton
              type="button"
              className="w-full"
              disabled={isImporting}
              onClick={() => fileRef.current?.click()}
            >
              <Icon
                name={isImporting ? "fa-spinner fa-spin" : "fa-file-import"}
              />{" "}
              {isImporting ? "กำลังนำเข้าข้อมูล..." : "เลือกไฟล์ Excel"}
            </PrimaryButton>
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
    </div>
  );
}
