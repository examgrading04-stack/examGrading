import os

frontend_dir = r"d:\ExamGrading\frontend"

def process_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Update saveSubject
    content = content.replace("await dbService.addDoc('subjects', data);", "await dbService.setDocWithId('subjects', data.code, data);")

    # Update saveClass (fix the old classes reference and use proper nested sub-collection)
    if "async function saveClass(e)" in content:
        import re
        save_class_old = re.search(r"async function saveClass\(e\).*?closeModal\('classModal'\);", content, re.DOTALL)
        if save_class_old:
            save_class_new = """async function saveClass(e) {
            e.preventDefault();
            Swal.fire({ title: 'กำลังบันทึก...', allowOutsideClick: false, didOpen: () => Swal.showLoading() });

            try {
                const id = document.getElementById('classId').value;
                const subjectId = document.getElementById('classSubject').value;
                const data = {
                    subject: subjectId,
                    sec: document.getElementById('classCode').value
                };
                if (id) await dbService.updateDoc(`subjects/${subjectId}/sections`, id, data);
                else await dbService.setDocWithId(`subjects/${subjectId}/sections`, data.sec, data);
                closeModal('classModal');"""
            # Keep indentation
            match = re.search(r"([ \t]*)async function saveClass\(e\)", content)
            indent = match.group(1) if match else "        "
            save_class_new = "\n".join([(indent + line.lstrip() if line.strip() else line) for line in save_class_new.split("\n")])
            save_class_new = save_class_new.replace(indent + "async function", "async function", 1)
            content = content.replace(save_class_old.group(0), save_class_new)

    # Update editClass
    if "function editClass(id)" in content:
        content = content.replace(
            "document.getElementById('classId').value = classData.id;",
            "document.getElementById('classId').value = classData.realId || classData.id;"
        )

    # Update deleteClass
    if "function deleteClass(id)" in content:
        import re
        delete_class_old = re.search(r"function deleteClass\(id\).*?await dbService\.deleteDoc\('classes', id\);", content, re.DOTALL)
        if delete_class_old:
            delete_class_new = """function deleteClass(id) {
            const classData = classesList.find(c => c.id === id);
            if (!classData) return;
            Swal.fire({
                title: 'คุณแน่ใจหรือไม่?',
                text: 'คุณต้องการลบกลุ่มเรียนนี้ใช่หรือไม่?',
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#d33',
                cancelButtonColor: '#3085d6',
                confirmButtonText: 'ใช่, ลบเลย!',
                cancelButtonText: 'ยกเลิก'
            }).then(async (result) => {
                if (result.isConfirmed) {
                    await dbService.deleteDoc(`subjects/${classData.subject}/sections`, classData.realId || classData.id);"""
            match = re.search(r"([ \t]*)function deleteClass\(id\)", content)
            indent = match.group(1) if match else "        "
            delete_class_new = "\n".join([(indent + line.lstrip() if line.strip() else line) for line in delete_class_new.split("\n")])
            delete_class_new = delete_class_new.replace(indent + "function deleteClass", "function deleteClass", 1)
            content = content.replace(delete_class_old.group(0), delete_class_new)

    # Update saveExam
    content = content.replace("await dbService.addDoc('exams', data);", "await dbService.setDocWithId('exams', `${data.subject}_${data.name}`, data);")
    
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(content)

for filename in os.listdir(frontend_dir):
    if filename.endswith(".html"):
        process_file(os.path.join(frontend_dir, filename))
        print(f"Processed {filename}")
