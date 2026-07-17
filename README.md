# Exam Grading Boss

ระบบตรวจและวิเคราะห์ข้อสอบที่ประกอบด้วย backend สำหรับ OMR, web frontend, และ Flutter mobile app.

## โครงสร้างโปรเจกต์ (Project Layout)

```text
examGrading-boss/
  backend/
    app/                 แอป FastAPI, models, และ services
    assets/templates/    เทมเพลตกระดาษคำตอบ OMR
  docs/                 บันทึกการติดตั้งและ Deploy
  render.yaml           ไฟล์ตั้งค่า Render สำหรับหลังบ้าน
  frontend/
    src/config/          การตั้งค่าเส้นทางและ Google API
    src/pages/           หน้าเว็บบนระบบ (Web Page)
    src/ui.jsx           ส่วนประกอบ UI ส่วนกลาง
  mobiles/exam_grading/
    lib/app/             โครงสร้างแอป Flutter
    lib/config/          การตั้งค่าต่างๆ ของแอปมือถือ
    lib/data/models/     โมเดลข้อมูล
    lib/presentation/    หน้าจอและวิดเจ็ตต่างๆ
```

## วิธีการรันระบบ (Run)

### 1. ระบบหลังบ้าน (Backend):

ก่อนรัน ให้ตรวจสอบว่าติดตั้งไลบรารีครบถ้วนแล้ว:
```powershell
pip install -r backend/requirements.txt
```

เนื่องจากบน Windows บางเครื่องอาจไม่สามารถเรียกใช้คำสั่ง `uvicorn` ได้โดยตรง (ขึ้นข้อผิดพลาด `'uvicorn' is not recognized`) ให้ใช้คำสั่งผ่าน Python Module แทนดังนี้:

**สำหรับ Windows (แนะนำ):**
```powershell
py -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

**สำหรับ macOS / Linux / Windows ทั่วไป:**
```bash
python -m uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

---

### 2. ระบบหน้าบ้าน (Frontend):

```powershell
cd frontend
npm install
npm run dev
```

---

### 3. แอปพลิเคชันมือถือ (Mobile App):

```powershell
cd mobiles/exam_grading
flutter pub get
flutter run
```

สำหรับการทดสอบกับโทรศัพท์มือถือเครื่องจริง ให้เปลี่ยนค่า `FASTAPI_URL=http://<computer-ip>:8000` ในไฟล์ `mobiles/exam_grading/.env` หรือรันผ่านคำสั่ง Flutter:

```powershell
flutter run --dart-define=FASTAPI_URL=http://<computer-ip>:8000
```

*รายละเอียดการ Deploy สามารถศึกษาเพิ่มเติมได้ในโฟลเดอร์ `docs/` ซึ่งตัว Render จะทำงานร่วมกับไฟล์ `render.yaml` และ `backend/Dockerfile`*
