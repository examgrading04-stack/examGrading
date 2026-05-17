import { useRef, useState } from "react";
import { DataTable, Field, GhostButton, Icon, Input, PrimaryButton, Select, Swal, emptyForm } from "../ui.jsx";

export function StudentsPage({ data, api, refresh }) {
  const [form, setForm] = useState(emptyForm(["id", "code", "name", "class"]));
  const [importOpen, setImportOpen] = useState(false);
  const [importSubject, setImportSubject] = useState("");
  const [importClass, setImportClass] = useState("");
  const [searchText, setSearchText] = useState("");
  const fileRef = useRef(null);
  const importSections = importSubject
    ? data.sections.filter((section) => section.subject === importSubject)
    : [];

  async function saveStudent(event) {
    event.preventDefault();
    const payload = { code: form.code, name: form.name, class: form.class };
    if (form.id) await api.update("students", form.id, payload);
    else await api.set(`students/${payload.code}`, payload);
    setForm(emptyForm(["id", "code", "name", "class"]));
    await refresh("บันทึกผู้เรียนแล้ว");
  }

  async function deleteStudent(row) {
    const result = await Swal().fire({ title: "ลบผู้เรียน?", text: row.name, icon: "warning", showCancelButton: true, confirmButtonText: "ลบ", cancelButtonText: "ยกเลิก" });
    if (!result.isConfirmed) return;
    await api.remove("students", row.id);
    await refresh("ลบผู้เรียนแล้ว");
  }

  async function importExcel(event) {
    const file = event.target.files?.[0];
    if (!file || !window.XLSX) return;
    if (!importClass) {
      event.target.value = "";
      Swal().fire("เลือกกลุ่มเรียนก่อน", "กรุณาเลือกรายวิชาและกลุ่มเรียนก่อนนำเข้า Excel", "warning");
      return;
    }
    const buffer = await file.arrayBuffer();
    const workbook = window.XLSX.read(new Uint8Array(buffer), { type: "array" });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = window.XLSX.utils.sheet_to_json(sheet);
    let count = 0;
    for (const row of rows) {
      const code = row["รหัสนักเรียน"] || row.ID || row.code || row["เลขประจำตัว"];
      const name = row["ชื่อ-นามสกุล"] || row["ชื่อ"] || row.Name || row.name;
      if (code && name) {
        const payload = { code: String(code), name: String(name), class: importClass };
        await api.set(`students/${payload.code}`, payload);
        count += 1;
      }
    }
    event.target.value = "";
    setImportOpen(false);
    setImportSubject("");
    setImportClass("");
    await refresh(`นำเข้าผู้เรียน ${count} คนแล้ว`);
  }

  const [filterSubject, setFilterSubject] = useState("");
  const [filterSection, setFilterSection] = useState("");
  const filterSections = filterSubject
    ? data.sections.filter((section) => section.subject === filterSubject)
    : data.sections;
  const normalizedSearch = searchText.trim().toLowerCase();
  const filteredStudents = data.students.filter((student) => {
    const matchesSubject = filterSubject
      ? student.class && student.class.startsWith(filterSubject + "_")
      : true;
    const matchesSection = filterSection ? student.class === filterSection : true;
    const matchesSearch = normalizedSearch
      ? [student.code, student.name].some((value) =>
        String(value || "").toLowerCase().includes(normalizedSearch),
      )
      : true;
    return matchesSubject && matchesSection && matchesSearch;
  });

  return (
    <div className="page-enter grid grid-cols-1 xl:grid-cols-[1fr_360px] gap-6">
      <section className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 className="text-xl font-extrabold">จัดการผู้เรียน</h3>
            <p className="text-sm text-slate-500">เพิ่ม แก้ไข นำเข้า และจัดกลุ่มผู้เรียน</p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <div className="min-w-64">
              <Input
                value={searchText}
                onChange={(event) => setSearchText(event.target.value)}
                placeholder="ค้นหารหัสนักเรียนหรือชื่อ"
              />
            </div>
            <div className="min-w-40">
              <Select
                value={filterSubject}
                onChange={(event) => {
                  setFilterSubject(event.target.value);
                  setFilterSection("");
                }}
              >
                <option value="">ทุกวิชา</option>
                {data.subjects.map((subject) => <option key={subject.id} value={subject.id}>{subject.name}</option>)}
              </Select>
            </div>
            <div className="min-w-40">
              <Select value={filterSection} onChange={(event) => setFilterSection(event.target.value)}>
                <option value="">ทุกกลุ่มเรียน</option>
                {filterSections.map((section) => (
                  <option key={section.id} value={section.id}>
                    {section.sec} ({section.subject})
                  </option>
                ))}
              </Select>
            </div>
            <input ref={fileRef} type="file" accept=".xlsx,.xls,.csv" onChange={importExcel} className="hidden" />
            <GhostButton variant="primary" onClick={() => setImportOpen(true)}><Icon name="fa-file-import" /> นำเข้า Excel</GhostButton>
          </div>
        </div>
        <div className="max-h-[520px] overflow-y-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
          <DataTable
            columns={[
              { key: "code", label: "รหัสนักเรียน" },
              { key: "name", label: "ชื่อ-นามสกุล" },
              {
                key: "subject", label: "รายวิชา", render: (row) => {
                  const subjectId = row.class?.split('_')[0];
                  return data.subjects.find(s => s.id === subjectId)?.name || subjectId || "-";
                }
              },
              { key: "class", label: "กลุ่มเรียน", render: (row) => data.sections.find(s => s.id === row.class)?.sec || row.class || "ไม่ระบุ" },
              {
                key: "actions",
                label: "",
                render: (row) => (
                  <div className="flex justify-end gap-2">
                    <GhostButton className="py-2 px-3" onClick={() => setForm({ ...emptyForm(["id", "code", "name", "class"]), ...row })}><Icon name="fa-pen" /></GhostButton>
                    <GhostButton variant="danger" className="py-2 px-3" onClick={() => deleteStudent(row)}><Icon name="fa-trash" /></GhostButton>
                  </div>
                ),
              },
            ]}
            rows={filteredStudents}
          />
        </div>
      </section>
      <form onSubmit={saveStudent} className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm space-y-4 h-fit">
        <h4 className="font-extrabold">{form.id ? "แก้ไขผู้เรียน" : "เพิ่มผู้เรียน"}</h4>
        <Field label="รหัสนักเรียน"><Input value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value })} placeholder="เช่น 6400123" required /></Field>
        <Field label="ชื่อ-นามสกุล"><Input value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} placeholder="เช่น นายสมชาย รักเรียน" required /></Field>
        <Field label="กลุ่มเรียน">
          <Select value={form.class} onChange={(e) => setForm({ ...form, class: e.target.value })}>
            <option value="">ไม่ระบุ</option>
            {data.sections.map((section) => <option key={section.id} value={section.id}>{section.sec} ({section.subject})</option>)}
          </Select>
        </Field>
        <PrimaryButton className="w-full"><Icon name="fa-floppy-disk" /> บันทึกผู้เรียน</PrimaryButton>
      </form>
      {importOpen && (
        <div className="fixed inset-0 z-50 bg-slate-950/50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xl w-full max-w-lg space-y-5">
            <div className="flex items-center justify-between gap-4">
              <div>
                <h3 className="font-extrabold text-lg">นำเข้า Excel</h3>
                <p className="text-sm text-slate-500 mt-1">
                  ไฟล์ต้องมีเฉพาะคอลัมน์รหัสนักเรียนและชื่อ-นามสกุล
                </p>
              </div>
              <GhostButton type="button" className="py-2 px-3" onClick={() => setImportOpen(false)}>
                <Icon name="fa-xmark" />
              </GhostButton>
            </div>

            <Field label="รายวิชา">
              <Select
                value={importSubject}
                onChange={(event) => {
                  setImportSubject(event.target.value);
                  setImportClass("");
                }}
              >
                <option value="">เลือกรายวิชา</option>
                {data.subjects.map((subject) => (
                  <option key={subject.id} value={subject.id}>
                    {subject.code} - {subject.name}
                  </option>
                ))}
              </Select>
            </Field>

            <Field label="กลุ่มเรียน">
              <Select
                value={importClass}
                onChange={(event) => setImportClass(event.target.value)}
                disabled={!importSubject}
              >
                <option value="">เลือกกลุ่มเรียน</option>
                {importSections.map((section) => (
                  <option key={section.id} value={section.id}>
                    {section.sec}
                  </option>
                ))}
              </Select>
            </Field>

            <div className="rounded-xl border border-slate-200 bg-slate-50 p-4 text-sm text-slate-600">
              <div className="font-bold text-slate-700 mb-2">รูปแบบไฟล์</div>
              <div>รหัสนักเรียน | ชื่อ-นามสกุล</div>
              <div className="mt-1 text-slate-500">หรือใช้ชื่อคอลัมน์อังกฤษ: code | name</div>
            </div>

            <PrimaryButton
              type="button"
              className="w-full"
              disabled={!importClass}
              onClick={() => fileRef.current?.click()}
            >
              <Icon name="fa-file-import" /> เลือกไฟล์ Excel
            </PrimaryButton>
          </div>
        </div>
      )}
    </div>
  );
}


