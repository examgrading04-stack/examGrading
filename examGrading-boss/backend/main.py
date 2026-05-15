import os
import sys
import uuid
from pathlib import Path
from typing import Any

BACKEND_DIR = Path(__file__).resolve().parent
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

import firebase_admin
from fastapi import Depends, FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from firebase_admin import auth, credentials, firestore, storage
import requests
from pydantic import BaseModel

from diagnose_sheet import diagnose
from generate_pdf_sheets import generate_pdf_for_students
from omr_scanner import calculate_score, scan_answer_sheet, summarize_marks


APP_ROOT = BACKEND_DIR.parent
TMP_DIR = APP_ROOT / "tmp"
TMP_DIR.mkdir(exist_ok=True)

FIREBASE_SERVICE_ACCOUNT = os.getenv(
    "FIREBASE_SERVICE_ACCOUNT",
    str(APP_ROOT / "serviceAccountKey.json"),
)
FIREBASE_STORAGE_BUCKET = os.getenv(
    "FIREBASE_STORAGE_BUCKET",
    "examgradings.firebasestorage.app",
)

app = FastAPI(title="Exam Grading OMR API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=os.getenv("CORS_ORIGINS", "*").split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class SheetPdfRequest(BaseModel):
    user_email: str | None = None
    exam_id: str
    student_ids: list[str] | None = None
    upload_to_storage: bool = True


class ScanCloudinaryRequest(BaseModel):
    exam_id: str
    image_url: str
    user_email: str | None = None
    answer_set: str = "0"
    debug: bool = False
    save_result: bool = True


def init_firebase() -> None:
    if firebase_admin._apps:
        return

    if os.path.exists(FIREBASE_SERVICE_ACCOUNT):
        cred = credentials.Certificate(FIREBASE_SERVICE_ACCOUNT)
    else:
        cred = credentials.ApplicationDefault()

    firebase_admin.initialize_app(cred, {"storageBucket": FIREBASE_STORAGE_BUCKET})


def get_db():
    init_firebase()
    return firestore.client()


def get_user_email(
    authorization: str | None = None,
    user_email: str | None = None,
) -> str:
    """Use Firebase ID token when supplied; fallback to user_email for local testing."""
    if authorization and authorization.startswith("Bearer "):
        init_firebase()
        decoded = auth.verify_id_token(authorization.removeprefix("Bearer ").strip())
        email = decoded.get("email")
        if not email:
            raise HTTPException(status_code=401, detail="Firebase token has no email")
        return email

    if user_email:
        return user_email

    raise HTTPException(status_code=401, detail="Missing Firebase token or user_email")


async def save_upload(file: UploadFile) -> str:
    suffix = Path(file.filename or "sheet.jpg").suffix or ".jpg"
    path = TMP_DIR / f"{uuid.uuid4().hex}{suffix}"
    with open(path, "wb") as out:
        out.write(await file.read())
    return str(path)


def user_root(db, user_email: str):
    return db.collection("users").document(user_email)


def get_exam(db, user_email: str, exam_id: str) -> dict[str, Any]:
    doc = user_root(db, user_email).collection("exams").document(exam_id).get()
    if not doc.exists:
        raise HTTPException(status_code=404, detail=f"Exam not found: {exam_id}")
    exam = doc.to_dict() or {}
    exam["id"] = doc.id
    return exam


def get_students(db, user_email: str, student_ids: list[str] | None = None) -> list[dict[str, Any]]:
    query = user_root(db, user_email).collection("students")
    docs = list(query.stream())
    students = []
    allowed = set(student_ids or [])
    for doc in docs:
        if allowed and doc.id not in allowed:
            continue
        student = doc.to_dict() or {}
        student["id"] = doc.id
        students.append(student)
    return students


def normalize_answer_key(exam: dict[str, Any], answer_set: str = "0") -> dict[int, str]:
    raw = exam.get("answerKey") or exam.get("answerKeys") or {}
    if answer_set in raw and isinstance(raw[answer_set], dict):
        raw = raw[answer_set]
    else:
        try:
            numeric_set = int(answer_set)
        except (TypeError, ValueError):
            numeric_set = None
        if numeric_set in raw and isinstance(raw[numeric_set], dict):
            raw = raw[numeric_set]

    normalized = {}
    for question, answer in raw.items():
        try:
            normalized[int(question)] = str(answer).upper()
        except (TypeError, ValueError):
            continue
    return normalized


def metadata_to_dict(result) -> dict[str, Any]:
    metadata = result.metadata
    if not metadata:
        return {}
    return {
        "subjectCode": metadata.subject_code,
        "subjectName": metadata.subject_name,
        "studentCode": metadata.student_id,
        "studentName": metadata.student_name,
        "examDate": metadata.exam_date,
        "totalQuestions": metadata.total_questions,
        "sheetId": metadata.sheet_id,
    }


def serialize_answers(answers: dict) -> dict[str, Any]:
    return {str(key): value for key, value in answers.items()}


@app.get("/api/health")
def health():
    return {"ok": True, "service": "exam-grading-omr"}


@app.post("/api/sheets/pdf")
def create_answer_sheets_pdf(
    payload: SheetPdfRequest,
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization=authorization, user_email=payload.user_email)
    exam = get_exam(db, user_email, payload.exam_id)
    students = get_students(db, user_email, payload.student_ids)
    if not students:
        raise HTTPException(status_code=400, detail="No students found for PDF generation")

    pdf_path = generate_pdf_for_students(exam, students)
    storage_path = None
    public_url = None

    if payload.upload_to_storage:
        bucket = storage.bucket()
        storage_path = f"users/{user_email}/exams/{payload.exam_id}/answer_sheets.pdf"
        blob = bucket.blob(storage_path)
        blob.upload_from_filename(pdf_path, content_type="application/pdf")
        public_url = f"gs://{bucket.name}/{storage_path}"

        user_root(db, user_email).collection("exams").document(payload.exam_id).set(
            {
                "answerSheets": {
                    "storagePath": storage_path,
                    "gsUrl": public_url,
                    "studentCount": len(students),
                    "updatedAt": firestore.SERVER_TIMESTAMP,
                }
            },
            merge=True,
        )

    return {
        "examId": payload.exam_id,
        "studentCount": len(students),
        "localPath": pdf_path,
        "storagePath": storage_path,
        "gsUrl": public_url,
    }


@app.post("/api/sheets/pdf/download")
def download_answer_sheets_pdf(
    payload: SheetPdfRequest,
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization=authorization, user_email=payload.user_email)
    exam = get_exam(db, user_email, payload.exam_id)
    students = get_students(db, user_email, payload.student_ids)
    if not students:
        raise HTTPException(status_code=400, detail="No students found for PDF generation")

    pdf_path = generate_pdf_for_students(exam, students)
    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=f"{payload.exam_id}_answer_sheets.pdf",
    )


@app.post("/api/scan")
async def scan_sheet(
    file: UploadFile = File(...),
    user_email: str | None = Form(None),
    exam_id: str = Form(...),
    answer_set: str = Form("0"),
    debug: bool = Form(False),
    save_result: bool = Form(True),
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization=authorization, user_email=user_email)
    exam = get_exam(db, user_email, exam_id)
    image_path = await save_upload(file)
    result = scan_answer_sheet(
        image_path,
        force_questions=int(exam.get("questions") or 0),
        debug=debug,
    )

    if not result.success:
        raise HTTPException(status_code=422, detail=result.error_msg or "Scan failed")

    answer_key = normalize_answer_key(exam, answer_set)
    score = calculate_score(result.answers, answer_key)
    metadata = metadata_to_dict(result)
    summary = summarize_marks(result.raw_scores, result.metadata.total_questions) if result.raw_scores else {}

    payload = {
        "examId": exam_id,
        "examName": exam.get("name", ""),
        "answerSet": answer_set,
        "studentCode": metadata.get("studentCode", ""),
        "studentName": metadata.get("studentName", ""),
        "sheetId": metadata.get("sheetId", ""),
        "score": score["score"],
        "total": score["total"],
        "percent": score["percent"],
        "answers": serialize_answers(result.answers),
        "flagged": result.flagged,
        "wrong": score["wrong"],
        "skipped": score["skipped"],
        "summary": summary,
        "metadata": metadata,
        "createdAt": firestore.SERVER_TIMESTAMP,
    }

    result_id = None
    if save_result:
        _, doc_ref = user_root(db, user_email).collection("results").add(payload)
        result_id = doc_ref.id

    response_payload = dict(payload)
    response_payload["createdAt"] = None
    response_payload["resultId"] = result_id
    response_payload["imagePath"] = image_path
    return response_payload


@app.post("/api/diagnose")
async def diagnose_sheet(
    file: UploadFile = File(...),
    force_questions: int = Form(0),
):
    image_path = await save_upload(file)
    report = diagnose(image_path, force_q=force_questions)
    return {
        "path": report.path,
        "anchorOk": report.anchor_ok,
        "qrOk": report.qr_ok,
        "qrData": report.qr_data,
        "gridRect": report.grid_rect,
        "questions": report.n_questions,
        "answers": serialize_answers(report.answers),
        "flagged": report.flagged,
        "issues": report.issues,
        "warnings": report.warnings,
        "info": report.info,
    }


def download_image(url: str) -> str:
    resp = requests.get(url, stream=True, timeout=15)
    if resp.status_code != 200:
        raise HTTPException(status_code=400, detail="Cannot download image from Cloudinary")
    
    suffix = Path(url).suffix.split("?")[0]
    if not suffix:
        suffix = ".jpg"
    path = TMP_DIR / f"{uuid.uuid4().hex}{suffix}"
    
    with open(path, "wb") as f:
        for chunk in resp.iter_content(1024):
            f.write(chunk)
    return str(path)


@app.post("/api/scan-cloudinary")
async def scan_cloudinary(
    payload: ScanCloudinaryRequest,
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization=authorization, user_email=payload.user_email)
    exam = get_exam(db, user_email, payload.exam_id)
    
    # Download image from Cloudinary URL
    local_path = download_image(payload.image_url)
    
    # Process image
    result = scan_answer_sheet(
        local_path,
        force_questions=int(exam.get("questions") or 0),
        debug=payload.debug,
    )

    if not result.success:
        raise HTTPException(status_code=422, detail=result.error_msg or "Scan failed")

    answer_key = normalize_answer_key(exam, payload.answer_set)
    score = calculate_score(result.answers, answer_key)
    metadata = metadata_to_dict(result)
    summary = summarize_marks(result.raw_scores, result.metadata.total_questions) if result.raw_scores else {}

    payload_to_save = {
        "examId": payload.exam_id,
        "examName": exam.get("name", ""),
        "answerSet": payload.answer_set,
        "studentCode": metadata.get("studentCode", ""),
        "studentName": metadata.get("studentName", ""),
        "sheetId": metadata.get("sheetId", ""),
        "score": score["score"],
        "total": score["total"],
        "percent": score["percent"],
        "answers": serialize_answers(result.answers),
        "flagged": result.flagged,
        "wrong": score["wrong"],
        "skipped": score["skipped"],
        "summary": summary,
        "metadata": metadata,
        "imageUrl": payload.image_url,
        "createdAt": firestore.SERVER_TIMESTAMP,
    }

    result_id = None
    if payload.save_result:
        _, doc_ref = user_root(db, user_email).collection("results").add(payload_to_save)
        result_id = doc_ref.id

    response_payload = dict(payload_to_save)
    response_payload["createdAt"] = None
    response_payload["resultId"] = result_id
    response_payload["imagePath"] = local_path
    
    return response_payload
