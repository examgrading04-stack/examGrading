# Exam Grading Backend

FastAPI service for answer-sheet PDF generation, OMR scanning, grading, diagnostics, and Firebase persistence.

## Structure

- `app/main.py` - FastAPI application and endpoints.
- `app/models/` - Pydantic request models.
- `app/services/` - OMR scanning, diagnostics, QR, and PDF generation logic.
- `assets/templates/` - Answer-sheet templates for 30, 50, and 100 questions.
- `main.py`, `omr_scanner.py`, `diagnose_sheet.py` - compatibility wrappers for older commands/imports.

## Setup

1. Put Firebase Admin SDK credentials at `backend/serviceAccountKey.json`, repo root `serviceAccountKey.json`, or set `FIREBASE_SERVICE_ACCOUNT`.
2. Install dependencies:

   ```powershell
   pip install -r backend/requirements.txt
   ```

3. Run from the project root:

   ```powershell
   uvicorn backend.main:app --reload --host 0.0.0.0 --port 8000
   ```

## Firestore Paths

- Exams: `users/{email}/exams/{examId}`
- Students: `users/{email}/students/{studentId}`
- Results: `users/{email}/results/{resultId}`

## Endpoints

- `GET /api/health`
- `POST /api/sheets/pdf`
- `POST /api/sheets/pdf/download`
- `POST /api/sheets/pdf/by-subject/download`
- `POST /api/scan`
- `POST /api/scan-cloudinary`
- `POST /api/diagnose`

For local testing, pass `user_email`. For production, send a Firebase ID token with `Authorization: Bearer <firebase-id-token>`.

## LAN Access

Run FastAPI with `--host 0.0.0.0` so phones and other computers on the same network can reach it.

Find this computer's IPv4 address:

```powershell
ipconfig
```

Then use `http://<IPv4>:8000` as the backend URL in web/mobile config. Windows Firewall must allow inbound TCP port `8000`.

## Render Deploy

This backend includes a Dockerfile for Render. Use `backend` as the Root Directory, Docker as the runtime, and `/api/health` as the health check path.

Set these environment variables in Render:

- `FIREBASE_SERVICE_ACCOUNT_JSON` - the full Firebase Admin SDK JSON content.
- `FIREBASE_STORAGE_BUCKET` - `examgradings.firebasestorage.app`.
