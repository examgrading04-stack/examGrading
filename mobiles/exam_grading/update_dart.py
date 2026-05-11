import os
import re

flutter_dir = r"d:\ExamGrading\mobiles\exam_grading\lib"

def process_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    original_content = content

    # 1. Replace FirebaseAuth.instance.currentUser?.uid
    content = content.replace("FirebaseAuth.instance.currentUser?.uid", "FirebaseAuth.instance.currentUser?.email")
    content = content.replace("FirebaseAuth.instance.currentUser!.uid", "FirebaseAuth.instance.currentUser!.email")

    # 2. Update subjects_screen.dart add()
    if filepath.endswith("subjects_screen.dart"):
        if "await _subjectsRef.add(data);" in content:
            content = content.replace("await _subjectsRef.add(data);", "await _subjectsRef.doc(code).set(data);")

    # 3. Update sections_screen.dart add()
    if filepath.endswith("sections_screen.dart"):
        if ".collection('sections')\n                                  .add(data);" in content:
            content = content.replace(".collection('sections')\n                                  .add(data);", ".collection('sections')\n                                  .doc(secController.text.trim()).set(data);")
            
    # 4. Update exams_screen.dart add()
    if filepath.endswith("exams_screen.dart"):
        if "await FirebaseFirestore.instance\n                                .collection('users')\n                                .doc(_uid)\n                                .collection('exams')\n                                .add(data);" in content:
            content = content.replace("await FirebaseFirestore.instance\n                                .collection('users')\n                                .doc(_uid)\n                                .collection('exams')\n                                .add(data);", "await FirebaseFirestore.instance\n                                .collection('users')\n                                .doc(_uid)\n                                .collection('exams')\n                                .doc('${selectedSubject!.id}_${nameController.text.trim()}').set(data);")

    if content != original_content:
        with open(filepath, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(flutter_dir):
    for filename in files:
        if filename.endswith(".dart"):
            process_file(os.path.join(root, filename))
