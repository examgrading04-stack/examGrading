# Exam Grading Backend

FastAPI service for generating answer-sheet PDFs, scanning OMR sheets, grading answers, and writing results to Firebase.

## Setup

1. Put Firebase Admin SDK credentials at repo root:

   `serviceAccountKey.json`

   Or set:

   `FIREBASE_SERVICE_ACCOUNT=C:\path\to\serviceAccountKey.json`

2. Install dependencies:

   `pip install -r backend/requirements.txt`

3. Run:

   `uvicorn backend.main:app --reload --host 127.0.0.1 --port 8000`

## Firestore Paths

- Exams: `users/{email}/exams/{examId}`
- Students: `users/{email}/students/{studentId}`
- Results: `users/{email}/results/{resultId}`

## Endpoints

- `GET /api/health`
- `POST /api/sheets/pdf`
- `POST /api/sheets/pdf/download`
- `POST /api/scan`
- `POST /api/diagnose`

For local testing, pass `user_email`. For production, send a Firebase ID token:

`Authorization: Bearer <firebase-id-token>`
