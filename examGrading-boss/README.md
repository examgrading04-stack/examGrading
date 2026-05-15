# Exam Grading Boss

ระบบตรวจและวิเคราะห์ข้อสอบที่ประกอบด้วย backend สำหรับ OMR/Firebase, web frontend, และ Flutter mobile app.

## Project Layout

```text
examGrading-boss/
  backend/
    app/                 FastAPI app, models, and services
    assets/templates/    OMR answer-sheet templates
  frontend/
    src/config/          Firebase and route configuration
    src/pages/           Web app pages
    src/ui.jsx           Shared UI helpers/components
  mobiles/exam_grading/
    lib/app/             Flutter app shell/theme
    lib/config/          Firebase options
    lib/data/models/     Data models
    lib/presentation/    Screens and reusable widgets
```

## Run

Backend:

```powershell
pip install -r backend/requirements.txt
uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
```

Frontend:

```powershell
cd frontend
npm install
npm run dev
```

Mobile:

```powershell
cd mobiles/exam_grading
flutter pub get
flutter run
```

For physical phones, set `FASTAPI_URL=http://<computer-ip>:8000` in `mobiles/exam_grading/.env` or run Flutter with:

```powershell
flutter run --dart-define=FASTAPI_URL=http://<computer-ip>:8000
```

FreeHost.run deployment notes are in `docs/freehost-run.md`.
