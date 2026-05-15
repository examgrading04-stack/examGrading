import { useRef, useState } from "react";
import { DataTable, Field, GhostButton, Icon, Input, PrimaryButton, Select, Swal, emptyForm } from "../ui.jsx";

export function StudentsPage({ data, api, refresh }) {
  const [form, setForm] = useState(emptyForm(["id", "code", "name", "class"]));
  const fileRef = useRef(null);

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
    const buffer = await file.arrayBuffer();
    const workbook = window.XLSX.read(new Uint8Array(buffer), { type: "array" });
    const sheet = workbook.Sheets[workbook.SheetNames[0]];
    const rows = window.XLSX.utils.sheet_to_json(sheet);
    let count = 0;
    for (const row of rows) {
      const code = row["รหัสนักเรียน"] || row.ID || row.code || row["เลขประจำตัว"];
      const name = row["ชื่อ-นามสกุล"] || row["ชื่อ"] || row.Name || row.name;
      const className = row["รหัสกลุ่มเรียน"] || row["กลุ่มเรียน"] || row.Class || row.class || "";
      if (code && name) {
        const payload = { code: String(code), name: String(name), class: String(className) };
        await api.set(`students/${payload.code}`, payload);
        count += 1;
      }
    }
    event.target.value = "";
    await refresh(`นำเข้าผู้เรียน ${count} คนแล้ว`);
  }

  const [filterSubject, setFilterSubject] = useState("");
  const filteredStudents = filterSubject
    ? data.students.filter((s) => s.class && s.class.startsWith(filterSubject + "_"))
    : data.students;

  return (
    <div className="page-enter grid grid-cols-1 xl:grid-cols-[1fr_360px] gap-6">
      <section className="space-y-6">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div>
            <h3 className="text-xl font-extrabold">จัดการผู้เรียน</h3>
            <p className="text-sm text-slate-500">เพิ่ม แก้ไข นำเข้า และจัดกลุ่มผู้เรียน</p>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <div className="min-w-48">
              <Select value={filterSubject} onChange={(e) => setFilterSubject(e.target.value)}>
                <option value="">ทุกวิชา</option>
                {data.subjects.map((subject) => <option key={subject.id} value={subject.id}>{subject.name}</option>)}
              </Select>
            </div>
            <input ref={fileRef} type="file" accept=".xlsx,.xls,.csv" onChange={importExcel} className="hidden" />
            <GhostButton variant="primary" onClick={() => fileRef.current?.click()}><Icon name="fa-file-import" /> นำเข้า Excel</GhostButton>
          </div>
        </div>
        <DataTable
          columns={[
            { key: "code", label: "รหัสนักเรียน" },
            { key: "name", label: "ชื่อ-นามสกุล" },
            { key: "subject", label: "รายวิชา", render: (row) => {
              const subjectId = row.class?.split('_')[0];
              return data.subjects.find(s => s.id === subjectId)?.name || subjectId || "-";
            }},
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
    </div>
  );
}


