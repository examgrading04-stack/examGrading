# 📝 Exam Grading System

ระบบตรวจข้อสอบอัตโนมัติและวิเคราะห์ผลการสอบ (Automatic OMR Exam Grading & Diagnostic System) ประกอบด้วย **FastAPI Backend** สำหรับประมวลผลภาพ OMR และวิเคราะห์สถิติข้อสอบ, **React Web Frontend** สำหรับบริหารจัดการระบบ และ **Flutter Mobile Application** สำหรับการสแกนตรวจกระดาษคำตอบด้วยกล้องมือถือ

---

## 🌟 ฟีเจอร์หลัก (Key Features)

- 📷 **ระบบตรวจจับ OMR & QR Code อัตโนมัติ (OMR & Barcode Scanning)**
  - ประมวลผลภาพถ่ายกระดาษคำตอบด้วย OpenCV และ PyZbar
  - อ่าน QR Code บนกระดาษเพื่อระบุรหัสนักศึกษา ชุดข้อสอบ และรหัสวิชาอัตโนมัติ
  - ตรวจจับจุดฝนคำตอบและคำนวณคะแนนอย่างแม่นยำ

- 📊 **ระบบวิเคราะห์คุณภาพข้อสอบ (Item Diagnostics & Analytics)**
  - คำนวณค่าความยากง่าย ($p$) และค่าอำนาจจำแนก ($r$) ของข้อสอบแต่ละข้อ
  - สรุปสถิติคะแนนเฉลี่ย, ค่าเบี่ยงเบนมาตรฐาน (SD), คะแนนสูงสุด-ต่ำสุด และการกระจายตัวของตัวเลือก

- 📄 **ระบบสร้างกระดาษคำตอบ PDF อัตโนมัติ (Dynamic PDF Answer Sheet Generator)**
  - สร้างไฟล์กระดาษคำตอบ PDF ที่ปรับแต่งตามจำนวนข้อสอบและฝนรหัสนักศึกษา/ชุดข้อสอบล่วงหน้าได้

- 🌐 **ระบบเว็บจัดการกลาง (Web Admin Dashboard)**
  - จัดการรายวิชา, ชุดข้อสอบ, เฉลย (Answer Key), ข้อมูลนักศึกษา และพิมพ์กระดาษคำตอบ
  - ดูรายงานผลการสอบและส่งออกข้อมูล

- 📱 **แอปพลิเคชันมือถือสแกนข้อสอบ (Mobile Scanner App)**
  - ถ่ายภาพกระดาษคำตอบผ่านกล้องมือถือ พร้อมระบบพรีวิวและแสดงผลคะแนนทันที
  - อัปโหลดภาพกระดาษคำตอบไปยัง Cloud Storage (Cloudinary)

---

## 🏗️ โครงสร้างโปรเจกต์ (Project Structure)

```text
ExamGrading/
├── backend/                  # ระบบหลังบ้าน (FastAPI / OpenCV / Python)
│   ├── app/
│   │   ├── main.py           # API Routes และ Exception Handlers หลัก
│   │   ├── db_adapter.py     # ตัวจัดการเชื่อมต่อฐานข้อมูล (Database Adapter)
│   │   ├── models/           # Pydantic Schemas และ Data Models
│   │   └── services/         # OMR Processing, Diagnostics, PDF Generator & QR Services
│   ├── assets/               # เทมเพลตกระดาษคำตอบ และไฟล์ทรัพยากร
│   ├── Dockerfile            # Docker Configuration สำหรับ Deploy Backend
│   └── requirements.txt      # Python Dependencies
│
├── frontend/                 # ระบบหน้าบ้านเว็บ (React 19 / Vite / Styled Components)
│   ├── src/
│   │   ├── config/           # การตั้งค่า API Routes และ Google API
│   │   ├── pages/            # หน้าเว็บต่างๆ (Dashboard, Exams, Students, Reports)
│   │   └── ui.jsx            # Shared UI Components
│   └── package.json          # Frontend Dependencies
│
├── mobiles/                  # แอปพลิเคชันมือถือ (Flutter Application)
│   ├── lib/
│   │   ├── app/              # แอปพลิเคชันตั้งค่าและโครงสร้างหลัก
│   │   ├── config/           # App Configuration & Environment Settings
│   │   ├── data/             # Models และ API Services
│   │   └── presentation/     # หน้าจอ (Screens) และ UI Widgets
│   └── pubspec.yaml          # Flutter Dependencies
│
└── render.yaml               # การตั้งค่า Deploy บน Render Cloud
```

---

## 🛠️ เทคโนโลยีที่ใช้ (Tech Stack)

| ส่วนงาน | เทคโนโลยี / ไลบรารี |
| :--- | :--- |
| **Backend** | Python 3.10+, FastAPI, Uvicorn, OpenCV, PyZbar, NumPy, Scikit-learn, ReportLab, SQLAlchemy |
| **Frontend** | React 19, Vite, Styled Components |
| **Mobile App** | Flutter (Dart SDK 3.8+), Provider, Camera, Google Sign-In, Lottie, QuickAlert |
| **Infrastructure & Cloud** | Docker, Cloudinary (Image Storage), Render (Cloud Hosting) |

---

## 🚀 วิธีการติดตั้งและการรันระบบ (Getting Started)

### 1. ระบบหลังบ้าน (Backend Server)

#### ข้อกำหนดเบื้องต้น:
- Python 3.10 ขึ้นไป
- *หมายเหตุสำหรับ Windows/Linux:* ไลบรารี `pyzbar` จำเป็นต้องใช้ zbar DLL/library หากพบข้อผิดพลาดเกี่ยวกับ zbar ให้ติดตั้ง zbar เพิ่มเติม

#### ขั้นตอนการรัน:
1. เข้าไปยังโฟลเดอร์ `backend`:
   ```bash
   cd backend
   ```

2. สร้างและเปิดใช้งาน Virtual Environment (แนะนำ):
   ```powershell
   # บน Windows
   python -m venv .venv
   .\.venv\Scripts\Activate.ps1

   # บน macOS / Linux
   python3 -m venv .venv
   source .venv/bin/activate
   ```

3. ติดตั้ง Dependencies:
   ```bash
   pip install -r requirements.txt
   ```

4. ตั้งค่าไฟล์ `.env` ในโฟลเดอร์ `backend/.env` (ตัวอย่าง):
   ```env
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_UPLOAD_PRESET=your_preset
   ```

5. รัน Uvicorn Server:
   - **สำหรับ Windows (แนะนำ):**
     ```powershell
     py -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
     ```
   - **สำหรับ macOS / Linux:**
     ```bash
     python3 -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
     ```
   - เข้าดู API Interactive Documentation ได้ที่: [http://localhost:8000/docs](http://localhost:8000/docs)

---

### 2. ระบบหน้าบ้านเว็บ (Web Frontend)

#### ขั้นตอนการรัน:
1. เข้าไปยังโฟลเดอร์ `frontend`:
   ```bash
   cd frontend
   ```

2. ติดตั้ง Node Packages:
   ```bash
   npm install
   ```

3. รัน Development Server:
   ```bash
   npm run dev
   ```
   - เข้าใช้งานเว็บได้ที่: `http://localhost:5173`

---

### 3. แอปพลิเคชันมือถือ (Flutter Mobile App)

#### ขั้นตอนการรัน:
1. เข้าไปยังโฟลเดอร์ `mobiles`:
   ```bash
   cd mobiles
   ```

2. ติดตั้ง Flutter Packages:
   ```bash
   flutter pub get
   ```

3. ตั้งค่า URL ของ Backend Server ในไฟล์ `mobiles/.env`:
   ```env
   FASTAPI_URL=http://<IP-เครื่องคอมพิวเตอร์ของคุณ>:8000
   ```

4. รันแอปพลิเคชัน:
   ```bash
   # รันทั่วไป
   flutter run

   # หรือระบุ FASTAPI_URL ผ่านคำสั่งโดยตรง
   flutter run --dart-define=FASTAPI_URL=http://<IP-เครื่องคอมพิวเตอร์ของคุณ>:8000
   ```

---

## ☁️ การ Deploy (Deployment)

- **Backend (Render)**: มีการตั้งค่าไฟล์ [render.yaml](file:///d:/ExamGrading/render.yaml) และ [Dockerfile](file:///d:/ExamGrading/backend/Dockerfile) ไว้เรียบร้อยแล้ว สามารถนำไปเชื่อมต่อกับ Render Blueprint เพื่อทำการปรับแต่งและสร้าง Web Service ได้อัตโนมัติ
- **Image Storage**: อัปโหลดภาพกระดาษคำตอบขึ้น Cloudinary อัตโนมัติเมื่อกำหนดค่า `CLOUDINARY_CLOUD_NAME` และ `CLOUDINARY_UPLOAD_PRESET` ใน environment variables
