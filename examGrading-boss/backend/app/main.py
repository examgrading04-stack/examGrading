import json
import os
import uuid
from pathlib import Path
from typing import Any

import firebase_admin
from fastapi import Body, Depends, FastAPI, File, Form, Header, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from firebase_admin import auth, credentials, firestore, storage
import requests

from .models.schemas import (
    SheetPdfBySubjectRequest,
    SheetPdfRequest,
)
from .services.diagnostics import diagnose
from .services.omr_scanner import calculate_score, scan_answer_sheet, summarize_marks
from .services.pdf_sheets import generate_pdf_for_students


BACKEND_DIR = Path(__file__).resolve().parents[1]
APP_ROOT = BACKEND_DIR.parent
TMP_DIR = APP_ROOT / "tmp"
TMP_DIR.mkdir(exist_ok=True)

FIREBASE_SERVICE_ACCOUNT = os.getenv("FIREBASE_SERVICE_ACCOUNT", "")
FIREBASE_SERVICE_ACCOUNT_JSON = os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON", "")
if not FIREBASE_SERVICE_ACCOUNT:
    # 1. Check for explicit serviceAccountKey.json
    # 2. Search for any file matching *firebase-adminsdk*.json (standard naming)
    search_dirs = [BACKEND_DIR, APP_ROOT]
    found = False
    for d in search_dirs:
        # Check standard name
        p = d / "serviceAccountKey.json"
        if p.exists():
            FIREBASE_SERVICE_ACCOUNT = str(p)
            found = True
            break
        # Search for pattern
        try:
            for f in d.glob("*.json"):
                if "firebase-adminsdk" in f.name:
                    FIREBASE_SERVICE_ACCOUNT = str(f)
                    found = True
                    break
        except Exception:
            pass
        if found:
            break
    
    if not found:
        FIREBASE_SERVICE_ACCOUNT = str(APP_ROOT / "serviceAccountKey.json")

FIREBASE_STORAGE_BUCKET = os.getenv(
    "FIREBASE_STORAGE_BUCKET",
    "examgradings.firebasestorage.app",
)

app = FastAPI(title="Exam Grading OMR API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Simplified for debugging
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)


def init_firebase() -> None:
    if firebase_admin._apps:
        return

    if FIREBASE_SERVICE_ACCOUNT_JSON:
        print("DEBUG: Using Firebase service account from environment JSON.")
        cred = credentials.Certificate(json.loads(FIREBASE_SERVICE_ACCOUNT_JSON))
    elif os.path.exists(FIREBASE_SERVICE_ACCOUNT):
        print(f"DEBUG: Service account file found at: {FIREBASE_SERVICE_ACCOUNT}")
        print("DEBUG: Service account file found.")
        cred = credentials.Certificate(FIREBASE_SERVICE_ACCOUNT)
    else:
        print(f"DEBUG: Service account NOT found at {FIREBASE_SERVICE_ACCOUNT}, using ApplicationDefault.")
        cred = credentials.ApplicationDefault()

    firebase_admin.initialize_app(cred, {"storageBucket": FIREBASE_STORAGE_BUCKET})
    print("DEBUG: Firebase initialized.")


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


def find_exam_for_scan(db, user_email: str, metadata: dict[str, Any]) -> dict[str, Any]:
    total_questions = int(metadata.get("totalQuestions") or 0)
    subject_code = str(metadata.get("subjectCode") or "").strip()
    exams = []

    for doc in user_root(db, user_email).collection("exams").stream():
        exam = doc.to_dict() or {}
        exam["id"] = doc.id
        exam_questions = int(exam.get("questions") or exam.get("total_questions") or 0)
        if total_questions and exam_questions and exam_questions != total_questions:
            continue
        if subject_code:
            exam_subject = str(
                exam.get("subject") or exam.get("subjectCode") or exam.get("code") or ""
            ).strip()
            if exam_subject and exam_subject != subject_code:
                continue
        if normalize_answer_key(exam):
            exams.append(exam)

    if len(exams) == 1:
        return exams[0]

    detail = "ไม่พบรหัสข้อสอบจาก QR บนกระดาษคำตอบ"
    if len(exams) > 1:
        detail = "พบข้อสอบที่เข้าข่ายหลายชุด กรุณาถ่ายให้ QR ชัดขึ้น"
    raise HTTPException(status_code=422, detail=detail)


def get_students(db, user_email: str, student_ids: list[str] | None = None) -> list[dict[str, Any]]:
    students_ref = user_root(db, user_email).collection("students")
    if student_ids:
        students = []
        for student_id in student_ids:
            doc = students_ref.document(student_id).get()
            if doc.exists:
                student = doc.to_dict() or {}
                student["id"] = doc.id
                students.append(student)
        return students

    docs = list(students_ref.stream())
    students = []
    for doc in docs:
        student = doc.to_dict() or {}
        student["id"] = doc.id
        students.append(student)
    return students


def normalize_students_snapshot(students_snapshot: list[dict[str, Any]] | None) -> list[dict[str, Any]]:
    if not students_snapshot:
        return []
    students = []
    for raw in students_snapshot:
        student = {
            "id": str(raw.get("id") or raw.get("studentId") or "").strip(),
            "code": str(raw.get("code") or raw.get("studentCode") or "").strip(),
            "name": str(raw.get("name") or raw.get("studentName") or "").strip(),
            "class": str(raw.get("class") or raw.get("className") or "").strip(),
        }
        if student["id"] or student["code"] or student["name"]:
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
        "examId": getattr(metadata, "exam_id", ""),
    }


def resolve_exam_id(payload_exam_id: str | None, metadata: dict[str, Any]) -> str:
    exam_id = (payload_exam_id or "").strip()
    if exam_id:
        return exam_id

    metadata_exam_id = str(metadata.get("examId") or "").strip()
    if metadata_exam_id:
        return metadata_exam_id

    sheet_id = str(metadata.get("sheetId") or "").strip()
    if ":" in sheet_id:
        return sheet_id.split(":", 1)[0].strip()

    raise HTTPException(
        status_code=422,
        detail="ไม่พบรหัสข้อสอบจาก QR บนกระดาษคำตอบ",
    )


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
    students = normalize_students_snapshot(payload.students_snapshot)
    if not students:
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


def get_students_by_subject(
    db, user_email: str, subject_code: str, section: str | None = None
) -> list[dict[str, Any]]:
    """Fetch students for a subject, optionally restricted to one section."""
    students_ref = user_root(db, user_email).collection("students")
    docs = list(students_ref.stream())
    students = []
    target = str(subject_code).strip()
    target_section = str(section or "").strip()
    target_class = f"{target}_{target_section}" if target and target_section else ""

    for doc in docs:
        student = doc.to_dict() or {}
        student["id"] = doc.id

        s_code = student.get("subject") or student.get("subjectCode")
        s_class = str(student.get("class") or "").strip()

        if target_section:
            if s_class in {target_class, target_section}:
                students.append(student)
                continue
            if s_code == target and (
                str(student.get("section") or "").strip() == target_section
                or str(student.get("sectionId") or "").strip() == target_class
            ):
                students.append(student)
                continue
            continue

        if s_code == target or s_class == target or s_class.startswith(target + "_"):
            students.append(student)

    return students


@app.post("/api/sheets/pdf/by-subject/download")
def download_answer_sheets_by_subject(
    payload: SheetPdfBySubjectRequest,
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    """Generate a PDF with answer sheets for all students in a given subject."""
    user_email = get_user_email(authorization=authorization, user_email=payload.user_email)
    exam = get_exam(db, user_email, payload.exam_id)

    # Try to fetch students enrolled in the specific subject/section
    students = get_students_by_subject(
        db,
        user_email,
        payload.subject_code,
        payload.section,
    )
    if not students:
        raise HTTPException(status_code=400, detail="ไม่พบรายชื่อผู้เรียนในวิชานี้")

    # Attach subject name to exam dict for sheet rendering
    subject_doc = (
        user_root(db, user_email)
        .collection("subjects")
        .document(payload.subject_code)
        .get()
    )
    if subject_doc.exists:
        subject_data = subject_doc.to_dict() or {}
        exam.setdefault("subjectName", subject_data.get("name", ""))

    pdf_path = generate_pdf_for_students(exam, students)
    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=f"{payload.exam_id}_answer_sheets.pdf",
    )


@app.post("/api/sheets/pdf/download")
def download_answer_sheets_pdf(
    payload: SheetPdfRequest,
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization=authorization, user_email=payload.user_email)
    exam = get_exam(db, user_email, payload.exam_id)
    students = normalize_students_snapshot(payload.students_snapshot)
    if not students:
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
        "timestamp": firestore.SERVER_TIMESTAMP,
    }

    result_id = None
    if save_result:
        _, doc_ref = user_root(db, user_email).collection("results").add(payload)
        result_id = doc_ref.id

    response_payload = dict(payload)
    response_payload["createdAt"] = None
    response_payload["timestamp"] = None
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
    payload: dict[str, Any] = Body(...),
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    image_url = str(payload.get("image_url") or "").strip()
    if not image_url:
        raise HTTPException(status_code=422, detail="Missing image_url")

    payload_user_email = payload.get("user_email")
    user_email = get_user_email(
        authorization=authorization,
        user_email=str(payload_user_email).strip() if payload_user_email else None,
    )
    answer_set = str(payload.get("answer_set") or "0")
    debug = bool(payload.get("debug", False))
    save_result = bool(payload.get("save_result", True))

    # Download image from Cloudinary URL
    local_path = download_image(image_url)

    payload_exam_id = str(payload.get("exam_id") or "").strip()
    exam = get_exam(db, user_email, payload_exam_id) if payload_exam_id else {}
    force_questions = int(exam.get("questions") or 0) if exam else 0

    # Process image. If exam_id was not sent, QR metadata supplies the exam id
    # and total question count.
    result = scan_answer_sheet(
        local_path,
        force_questions=force_questions,
        debug=debug,
    )

    if not result.success:
        raise HTTPException(status_code=422, detail=result.error_msg or "Scan failed")

    metadata = metadata_to_dict(result)
    if exam:
        exam_id = exam["id"]
    else:
        try:
            exam_id = resolve_exam_id(payload_exam_id, metadata)
            exam = get_exam(db, user_email, exam_id)
        except HTTPException:
            exam = find_exam_for_scan(db, user_email, metadata)
            exam_id = exam["id"]

    answer_key = normalize_answer_key(exam, answer_set)
    score = calculate_score(result.answers, answer_key)
    summary = summarize_marks(result.raw_scores, result.metadata.total_questions) if result.raw_scores else {}

    payload_to_save = {
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
        "imageUrl": image_url,
        "createdAt": firestore.SERVER_TIMESTAMP,
        "timestamp": firestore.SERVER_TIMESTAMP,
    }

    result_id = None
    if save_result:
        _, doc_ref = user_root(db, user_email).collection("results").add(payload_to_save)
        result_id = doc_ref.id

    response_payload = dict(payload_to_save)
    response_payload["createdAt"] = None
    response_payload["timestamp"] = None
    response_payload["resultId"] = result_id
    response_payload["imagePath"] = local_path
    
    return response_payload


@app.get("/api/admin/storage")
def admin_get_storage_usage(
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    bucket = storage.bucket()
    blobs = bucket.list_blobs()
    total_bytes = 0
    file_count = 0
    files = []
    
    for blob in blobs:
        size = blob.size or 0
        total_bytes += size
        file_count += 1
        files.append({
            "name": blob.name,
            "size": size,
            "updated": blob.updated.isoformat() if blob.updated else None,
            "contentType": blob.content_type,
        })
        
    files.sort(key=lambda x: x["size"], reverse=True)
    files = files[:100]
    
    return {
        "totalBytes": total_bytes,
        "fileCount": file_count,
        "files": files,
    }


@app.post("/api/admin/storage/clean")
def admin_clean_storage(
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    bucket = storage.bucket()
    blobs = bucket.list_blobs(prefix="users/")
    
    deleted_count = 0
    freed_bytes = 0
    
    for blob in blobs:
        if blob.name.endswith("answer_sheets.pdf"):
            parts = blob.name.split("/")
            if len(parts) >= 4 and parts[2] == "exams":
                user_email = parts[1]
                exam_id = parts[3]
                
                exam_ref = user_root(db, user_email).collection("exams").document(exam_id)
                exam_doc = exam_ref.get()
                
                if not exam_doc.exists:
                    freed_bytes += blob.size or 0
                    blob.delete()
                    deleted_count += 1

    return {
        "deletedCount": deleted_count,
        "freedBytes": freed_bytes,
    }
