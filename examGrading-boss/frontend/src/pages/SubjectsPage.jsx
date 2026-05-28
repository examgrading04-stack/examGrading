import { useState } from "react";
import { DataTable, Field, GhostButton, Icon, Input, PrimaryButton, Select, Swal, emptyForm } from "../ui.jsx";

export function SubjectsPage({ data, api, refresh }) {
  const [subjectForm, setSubjectForm] = useState(emptyForm(["id", "code", "name", "term", "year", "teacher"]));
  const [sectionForm, setSectionForm] = useState(emptyForm(["id", "subject", "sec"]));
  const [activeSubject, setActiveSubject] = useState(null);
  const sections = activeSubject ? data.sections.filter((section) => section.subject === activeSubject) : data.sections;

  const currentSubject = data.subjects.find((s) => s.id === activeSubject);

  async function saveSubject(event) {
    event.preventDefault();
    const payload = { code: subjectForm.code, name: subjectForm.name, term: subjectForm.term, year: subjectForm.year, teacher: subjectForm.teacher };
    if (subjectForm.id) await api.update("subjects", subjectForm.id, payload);
    else await api.set(`subjects/${payload.code}`, payload);
    setSubjectForm(emptyForm(["id", "code", "name", "term", "year", "teacher"]));
    await refresh("บันทึกรายวิชาแล้ว");
  }

  async function saveSection(event) {
    event.preventDefault();
    const subjectId = activeSubject || sectionForm.subject;
    if (!subjectId) return Swal().fire("กรุณาเลือกรายวิชา", "ต้องเลือกรายวิชาก่อนเพิ่มกลุ่มเรียน", "warning");
    const id = sectionForm.id || sectionForm.sec;
    await api.set(`subjects/${subjectId}/sections/${id}`, { subject: subjectId, sec: sectionForm.sec, created_at: new Date().toISOString() });
    setSectionForm(emptyForm(["id", "subject", "sec"]));
    await refresh("บันทึกกลุ่มเรียนแล้ว");
  }

  async function deleteSubject(subject) {
    const result = await Swal().fire({ title: "ลบรายวิชา?", text: subject.name, icon: "warning", showCancelButton: true, confirmButtonText: "ลบ", cancelButtonText: "ยกเลิก" });
    if (!result.isConfirmed) return;
    await api.remove("subjects", subject.id);
    await refresh("ลบรายวิชาแล้ว");
  }

  async function deleteSection(section) {
    const result = await Swal().fire({ title: "ลบกลุ่มเรียน?", text: section.sec, icon: "warning", showCancelButton: true, confirmButtonText: "ลบ", cancelButtonText: "ยกเลิก" });
    if (!result.isConfirmed) return;
    await api.remove(`subjects/${section.subject}/sections`, section.realId || section.id);
    await refresh("ลบกลุ่มเรียนแล้ว");
  }

  return (
    <div className="page-enter grid grid-cols-1 xl:grid-cols-[1fr_380px] gap-6">
      <section className="space-y-6">
        {!activeSubject ? (
          <>
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div>
                <h3 className="text-xl font-extrabold">รายวิชาทั้งหมด</h3>
                <p className="text-sm text-zinc-500">จัดการรายวิชา เทอม และปีการศึกษา</p>
              </div>
            </div>
            <DataTable
              columns={[
                { key: "code", label: "รหัสวิชา" },
                { key: "name", label: "ชื่อวิชา" },
                { key: "term", label: "เทอม" },
                { key: "year", label: "ปี" },
                { key: "teacher", label: "ผู้สอน" },
                {
                  key: "actions",
                  label: "",
                  render: (row) => (
                    <div className="flex flex-wrap gap-2 justify-end">
                      <GhostButton variant="primary" className="py-2 px-3" onClick={() => setActiveSubject(row.id)}><Icon name="fa-users" /> กลุ่มเรียน</GhostButton>
                      <GhostButton className="py-2 px-3" onClick={() => setSubjectForm({ ...emptyForm(["id", "code", "name", "term", "year", "teacher"]), ...row })}><Icon name="fa-pen" /></GhostButton>
                      <GhostButton variant="danger" className="py-2 px-3" onClick={() => deleteSubject(row)}><Icon name="fa-trash" /></GhostButton>
                    </div>
                  ),
                },
              ]}
              rows={data.subjects}
            />
          </>
        ) : (
          <>
            <div className="flex flex-wrap items-center justify-between gap-3">
              <div className="flex items-center gap-4">
                <GhostButton onClick={() => setActiveSubject(null)} className="py-2 px-3"><Icon name="fa-arrow-left" /></GhostButton>
                <div>
                  <h3 className="text-xl font-extrabold">กลุ่มเรียน: {currentSubject?.name}</h3>
                  <p className="text-sm text-zinc-500">จัดการกลุ่มเรียนของวิชา {currentSubject?.code}</p>
                </div>
              </div>
            </div>
            <DataTable
              columns={[
                { key: "subject", label: "รายวิชา", render: (row) => data.subjects.find((subject) => subject.id === row.subject)?.name || row.subject },
                { key: "sec", label: "กลุ่มเรียน" },
                { key: "actions", label: "", render: (row) => <div className="flex justify-end"><GhostButton variant="danger" className="py-2 px-3" onClick={() => deleteSection(row)}><Icon name="fa-trash" /></GhostButton></div> },
              ]}
              rows={sections}
              emptyText="ยังไม่มีกลุ่มเรียน"
            />
          </>
        )}
      </section>

      <aside className="space-y-6">
        {!activeSubject ? (
          <form onSubmit={saveSubject} className="bg-white rounded-2xl border border-zinc-200 p-5  space-y-4">
            <h4 className="font-extrabold">{subjectForm.id ? "แก้ไขรายวิชา" : "เพิ่มรายวิชา"}</h4>
            <Field label="รหัสวิชา"><Input value={subjectForm.code} onChange={(e) => setSubjectForm({ ...subjectForm, code: e.target.value })} placeholder="เช่น CS101" required disabled={Boolean(subjectForm.id)} /></Field>
            <Field label="ชื่อวิชา"><Input value={subjectForm.name} onChange={(e) => setSubjectForm({ ...subjectForm, name: e.target.value })} placeholder="เช่น Introduction to Programming" required /></Field>
            <div className="grid grid-cols-2 gap-3">
              <Field label="เทอม"><Input value={subjectForm.term} onChange={(e) => setSubjectForm({ ...subjectForm, term: e.target.value })} placeholder="เช่น 1" /></Field>
              <Field label="ปี"><Input value={subjectForm.year} onChange={(e) => setSubjectForm({ ...subjectForm, year: e.target.value })} placeholder="เช่น 2567" /></Field>
            </div>
            <Field label="ผู้สอน"><Input value={subjectForm.teacher} onChange={(e) => setSubjectForm({ ...subjectForm, teacher: e.target.value })} placeholder="เช่น ผศ.ดร.สมชาย" /></Field>
            <PrimaryButton className="w-full"><Icon name="fa-floppy-disk" /> บันทึกรายวิชา</PrimaryButton>
          </form>
        ) : (
          <form onSubmit={saveSection} className="bg-white rounded-2xl border border-zinc-200 p-5  space-y-4">
            <h4 className="font-extrabold">เพิ่มกลุ่มเรียน</h4>
            <div className="bg-blue-50 p-4 rounded-xl border border-blue-100 text-blue-700 text-sm mb-2">
              <div className="font-bold flex items-center gap-2"><Icon name="fa-book" /> {currentSubject?.code}</div>
              <div className="mt-1 opacity-80">{currentSubject?.name}</div>
            </div>
            <Field label="กลุ่มเรียน / Section">
              <Input value={sectionForm.sec} onChange={(e) => setSectionForm({ ...sectionForm, sec: e.target.value })} placeholder="เช่น 01" required />
            </Field>
            <PrimaryButton className="w-full"><Icon name="fa-plus" /> บันทึกกลุ่มเรียน</PrimaryButton>
          </form>
        )}
      </aside>
    </div>
  );
}



