import hashlib
import os
import uuid
from pathlib import Path
from typing import Any

# pyrefly: ignore [missing-import]
from dotenv import load_dotenv

load_dotenv()
load_dotenv(Path(__file__).parent.parent / ".env")

# pyrefly: ignore [missing-import]
from fastapi import (
    Body,
    Depends,
    FastAPI,
    File,
    Form,
    Header,
    HTTPException,
    UploadFile,
    Request,
    BackgroundTasks,
)

# pyrefly: ignore [missing-import]
from fastapi.middleware.cors import CORSMiddleware

# pyrefly: ignore [missing-import]
from fastapi.middleware.gzip import GZipMiddleware

# pyrefly: ignore [missing-import]
from fastapi.responses import FileResponse

# pyrefly: ignore [missing-import]
from fastapi.staticfiles import StaticFiles
import requests

from datetime import datetime
from .models.schemas import (
    SheetPdfBySubjectRequest,
    SheetPdfRequest,
)
from .services.diagnostics import diagnose
from .services.report_generator import (
    generate_excel_report,
    generate_pdf_report,
    generate_generic_table_pdf,
)
from .services.omr_scanner import calculate_score, scan_answer_sheet, summarize_marks
from .services.pdf_sheets import generate_pdf_for_students
from .db_adapter import get_db_adapter


def upload_to_cloudinary(file_path: str) -> str:
    cloud_name = os.getenv("CLOUDINARY_CLOUD_NAME")
    upload_preset = os.getenv("CLOUDINARY_UPLOAD_PRESET")
    if not cloud_name or not upload_preset:
        return ""
    url = f"https://api.cloudinary.com/v1_1/{cloud_name}/image/upload"
    try:
        with open(file_path, "rb") as f:
            res = requests.post(
                url,
                files={"file": f},
                data={"upload_preset": upload_preset},
                timeout=15,
            )
            if res.status_code == 200:
                return res.json().get("secure_url", "")
    except Exception as e:
        print(f"Cloudinary upload error: {e}")
    return ""


BACKEND_DIR = Path(__file__).resolve().parents[1]
APP_ROOT = BACKEND_DIR.parent
TMP_DIR = APP_ROOT / "tmp"
TMP_DIR.mkdir(exist_ok=True)

STATIC_DIR = Path(__file__).parent / "static"
STATIC_DIR.mkdir(exist_ok=True)
UPLOADS_DIR = STATIC_DIR / "uploads"
UPLOADS_DIR.mkdir(exist_ok=True)


# pyrefly: ignore [missing-import]
from fastapi.responses import JSONResponse
import traceback

app = FastAPI(title="Exam Grading OMR API")


@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    print("500 ERROR:", exc)
    traceback.print_exc()
    return JSONResponse(
        status_code=500,
        content={"detail": str(exc), "traceback": traceback.format_exc()},
        headers={"Access-Control-Allow-Origin": "*"},
    )


app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")
app.add_middleware(GZipMiddleware, minimum_size=1000)
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "https://exam-grading-mu.vercel.app",
    ],
    allow_origin_regex=r"https://.*\.vercel\.app|http://localhost:\d+|http://127\.0\.0\.1:\d+",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# URL สาธารณะของ Backend (ใช้ใน production)
BACKEND_PUBLIC_URL = os.getenv("BACKEND_PUBLIC_URL", "http://localhost:8000")


def get_db():
    return get_db_adapter()


def get_user_email(
    authorization: str | None = None,
    user_email: str | None = None,
) -> str:
    """Authentication helper without Firebase. Uses user_email or authorization header value as email."""
    if user_email:
        return user_email
    if authorization and authorization.startswith("Bearer "):
        token = authorization.removeprefix("Bearer ").strip()
        if token:
            return token
    raise HTTPException(
        status_code=401, detail="Missing user_email or authorization header"
    )


async def save_upload(file: UploadFile) -> str:
    suffix = Path(file.filename or "sheet.jpg").suffix or ".jpg"
    path = TMP_DIR / f"{uuid.uuid4().hex}{suffix}"
    with open(path, "wb") as out:
        out.write(await file.read())
    return str(path)


def get_exam(db, user_email: str, exam_id: str) -> dict[str, Any]:
    return db.get_exam(user_email, exam_id)


def find_exam_for_scan(db, user_email: str, metadata: dict[str, Any]) -> dict[str, Any]:
    total_questions = int(metadata.get("totalQuestions") or 0)
    subject_code = str(metadata.get("subjectCode") or "").strip()
    exams = []

    for exam in db.get_exams(user_email):
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


def get_students(
    db, user_email: str, student_ids: list[str] | None = None
) -> list[dict[str, Any]]:
    return db.get_students(user_email, student_ids)


def normalize_students_snapshot(
    students_snapshot: list[dict[str, Any]] | None,
) -> list[dict[str, Any]]:
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
            q_no = int(question)
            if isinstance(answer, dict):
                normalized[q_no] = {
                    "answer": str(answer.get("answer", "")).upper(),
                    "score": float(answer.get("score", 1.0)),
                }
            else:
                normalized[q_no] = str(answer).upper()
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
    user_email = get_user_email(
        authorization=authorization, user_email=payload.user_email
    )
    exam = get_exam(db, user_email, payload.exam_id)
    students = normalize_students_snapshot(payload.students_snapshot)
    if not students:
        students = get_students(db, user_email, payload.student_ids)
    if not students:
        raise HTTPException(
            status_code=400, detail="No students found for PDF generation"
        )

    pdf_path = generate_pdf_for_students(exam, students)
    storage_path = None
    public_url = None

    if payload.upload_to_storage:
        # Firebase storage functionality is disabled
        storage_path = f"users/{user_email}/exams/{payload.exam_id}/answer_sheets.pdf"
        public_url = f"local://{storage_path}"

        db.update_exam(
            user_email,
            payload.exam_id,
            {
                "answerSheets": {
                    "storagePath": storage_path,
                    "gsUrl": public_url,
                    "studentCount": len(students),
                    "updatedAt": datetime.now().isoformat(),
                }
            },
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
    students = db.get_students(user_email)
    filtered_students = []
    target = str(subject_code).strip()
    target_section = str(section or "").strip()
    target_class = f"{target}_{target_section}" if target and target_section else ""

    for student in students:
        s_code = student.get("subject") or student.get("subjectCode")
        s_class = str(student.get("class") or "").strip()

        if target_section:
            if s_class in {target_class, target_section}:
                filtered_students.append(student)
                continue
            if s_code == target and (
                str(student.get("section") or "").strip() == target_section
                or str(student.get("sectionId") or "").strip() == target_class
            ):
                filtered_students.append(student)
                continue
            continue

        if s_code == target or s_class == target or s_class.startswith(target + "_"):
            filtered_students.append(student)

    return filtered_students


@app.post("/api/sheets/pdf/by-subject/download")
def download_answer_sheets_by_subject(
    payload: SheetPdfBySubjectRequest,
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    """Generate a PDF with answer sheets for all students in a given subject."""
    user_email = get_user_email(
        authorization=authorization, user_email=payload.user_email
    )
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
    subject_name = db.get_subject_name(user_email, payload.subject_code)
    if subject_name:
        exam.setdefault("subjectName", subject_name)

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
    user_email = get_user_email(
        authorization=authorization, user_email=payload.user_email
    )
    exam = get_exam(db, user_email, payload.exam_id)
    students = normalize_students_snapshot(payload.students_snapshot)
    if not students:
        students = get_students(db, user_email, payload.student_ids)
    if not students:
        raise HTTPException(
            status_code=400, detail="No students found for PDF generation"
        )

    pdf_path = generate_pdf_for_students(exam, students)
    return FileResponse(
        pdf_path,
        media_type="application/pdf",
        filename=f"{payload.exam_id}_answer_sheets.pdf",
    )


@app.post("/api/reports/summary/pdf/download")
def download_summary_pdf_report(
    payload: dict = Body(...),
    authorization: str | None = Header(None),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    get_user_email(authorization)
    title = payload.get("title", "รายงาน")
    columns = payload.get("columns", [])
    rows = payload.get("rows", [])

    if not columns or not rows:
        raise HTTPException(status_code=400, detail="Missing columns or rows")

    filepath = generate_generic_table_pdf(title, columns, rows)
    background_tasks.add_task(os.unlink, filepath)

    return FileResponse(
        filepath,
        media_type="application/pdf",
        filename="Summary_Report.pdf",
        background=background_tasks,
    )


@app.post("/api/results/{result_id}/update_answer")
def update_result_answer_endpoint(
    result_id: str,
    payload: dict = Body(...),
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization)
    question_no = payload.get("question_no")
    new_answer = payload.get("new_answer", "")

    if question_no is None:
        raise HTTPException(status_code=400, detail="Missing question_no")

    try:
        res = db.update_result_answer(
            user_email, result_id, int(question_no), new_answer
        )
        return {"ok": True, "score": res["score"], "percent": res["percent"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/api/results/report/excel/download")
def download_excel_report(
    payload: dict = Body(...),
    authorization: str | None = Header(None),
    db=Depends(get_db),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    email = get_user_email(authorization)
    exam_id = payload.get("examId")
    if not exam_id:
        raise HTTPException(status_code=400, detail="Missing examId")

    exam = db.get_doc("exams", exam_id, email)
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")

    subject = db.get_doc("subjects", exam.get("subject_id"), email)
    subject_name = subject.get("name") if subject else "Unknown Subject"

    result_ids = payload.get("resultIds")
    results = [
        r
        for r in db.get_collection("results", email)
        if r.get("examId") == exam_id or r.get("exam_id") == exam_id
    ]
    if result_ids:
        results = [r for r in results if r.get("id") in result_ids]

    students = db.get_collection("students", email)
    sections = db.get_collection("sections", email)

    filepath = generate_excel_report(exam, results, students, subject_name, sections)
    background_tasks.add_task(os.unlink, filepath)

    return FileResponse(
        filepath,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        filename=f"Report_{exam_id}.xlsx",
        background=background_tasks,
    )


@app.post("/api/results/report/pdf/download")
def download_pdf_report(
    payload: dict = Body(...),
    authorization: str | None = Header(None),
    db=Depends(get_db),
    background_tasks: BackgroundTasks = BackgroundTasks(),
):
    email = get_user_email(authorization)
    exam_id = payload.get("examId")
    if not exam_id:
        raise HTTPException(status_code=400, detail="Missing examId")

    exam = db.get_doc("exams", exam_id, email)
    if not exam:
        raise HTTPException(status_code=404, detail="Exam not found")

    subject = db.get_doc("subjects", exam.get("subject_id"), email)
    subject_name = subject.get("name") if subject else "Unknown Subject"

    result_ids = payload.get("resultIds")
    results = [
        r
        for r in db.get_collection("results", email)
        if r.get("examId") == exam_id or r.get("exam_id") == exam_id
    ]
    if result_ids:
        results = [r for r in results if r.get("id") in result_ids]

    students = db.get_collection("students", email)
    sections = db.get_collection("sections", email)

    filepath = generate_pdf_report(exam, results, students, subject_name, sections)
    background_tasks.add_task(os.unlink, filepath)

    return FileResponse(
        filepath,
        media_type="application/pdf",
        filename=f"Report_{exam_id}.pdf",
        background=background_tasks,
    )


@app.post("/api/scan")
async def scan_sheet(
    file: UploadFile = File(...),
    user_email: str | None = Form(None),
    exam_id: str | None = Form(None),
    answer_set: str = Form("0"),
    debug: bool = Form(False),
    save_result: bool = Form(True),
    overwrite: bool = Form(False),
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization=authorization, user_email=user_email)
    image_path = await save_upload(file)

    payload_exam_id = str(exam_id or "").strip()
    exam = get_exam(db, user_email, payload_exam_id) if payload_exam_id else {}
    force_questions = int(exam.get("questions") or 0) if exam else 0

    result = scan_answer_sheet(
        image_path,
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
    score = calculate_score(result.answers, answer_key, exam.get("questions", 0))
    summary = (
        summarize_marks(result.raw_scores, result.metadata.total_questions)
        if result.raw_scores
        else {}
    )

    image_url = upload_to_cloudinary(image_path)
    now = datetime.now()

    payload = {
        "examId": exam_id,
        "examName": exam.get("name", ""),
        "answerSet": answer_set,
        "studentCode": metadata.get("studentCode", ""),
        "studentName": metadata.get("studentName", ""),
        "sheetId": exam.get("sheetType") or metadata.get("sheetId", ""),
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
        "overwrite": overwrite,
        "createdAt": now,
        "timestamp": now,
    }

    result_id = None
    if save_result:
        try:
            result_id = db.save_result(user_email, payload)
        except ValueError as e:
            if str(e).startswith("duplicate_result:"):
                raise HTTPException(
                    status_code=409, detail="กระดาษคำตอบของนักเรียนคนนี้ถูกสแกนไปแล้ว"
                )
            raise

    response_payload = dict(payload)
    response_payload.pop("overwrite", None)
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
        raise HTTPException(
            status_code=400, detail="Cannot download image from Cloudinary"
        )

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
    summary = (
        summarize_marks(result.raw_scores, result.metadata.total_questions)
        if result.raw_scores
        else {}
    )

    now = datetime.now()
    payload_to_save = {
        "examId": exam_id,
        "examName": exam.get("name", ""),
        "answerSet": answer_set,
        "studentCode": metadata.get("studentCode", ""),
        "studentName": metadata.get("studentName", ""),
        "sheetId": exam.get("sheetType") or metadata.get("sheetId", ""),
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
        "createdAt": now,
        "timestamp": now,
    }

    result_id = None
    if save_result:
        result_id = db.save_result(user_email, payload_to_save)

    response_payload = dict(payload_to_save)
    response_payload["createdAt"] = None
    response_payload["timestamp"] = None
    response_payload["resultId"] = result_id
    response_payload["imagePath"] = local_path

    return response_payload


# ----------------------------------------------------
# Firebase Auth & Firestore Local Emulation Endpoints
# ----------------------------------------------------
def parse_db_path(path: str):
    parts = [p for p in path.strip("/").split("/") if p]
    result = {
        "user_email": None,
        "collection": None,
        "doc_id": None,
        "parent_doc_id": None,
    }
    if not parts:
        return result
    if parts[0] == "users":
        if len(parts) > 1:
            result["user_email"] = parts[1]
            if len(parts) > 2:
                result["collection"] = parts[2]
                if len(parts) > 3:
                    result["doc_id"] = parts[3]
                    if len(parts) > 4:
                        result["parent_doc_id"] = parts[3]
                        result["collection"] = parts[4]
                        if len(parts) > 5:
                            result["doc_id"] = parts[5]
                        else:
                            result["doc_id"] = None
            else:
                result["collection"] = "users"
                result["doc_id"] = parts[1]
        else:
            result["collection"] = "users"
    else:
        result["collection"] = parts[0]
        if len(parts) > 1:
            result["doc_id"] = parts[1]
            if len(parts) > 2:
                result["parent_doc_id"] = parts[1]
                result["collection"] = parts[2]
                if len(parts) > 3:
                    result["doc_id"] = parts[3]
                else:
                    result["doc_id"] = None
    return result


@app.post("/api/upload-profile-picture")
async def upload_profile_picture(
    file: UploadFile = File(...), user_email: str = Form(...)
):
    suffix = Path(file.filename or "profile.jpg").suffix or ".jpg"
    file_name = f"{user_email}_{uuid.uuid4().hex[:8]}{suffix}"
    path = UPLOADS_DIR / file_name
    with open(path, "wb") as out:
        out.write(await file.read())
    return {"url": f"{BACKEND_PUBLIC_URL}/static/uploads/{file_name}"}


@app.post("/api/auth/register")
def auth_register(payload: dict = Body(...), db=Depends(get_db)):
    email = payload.get("email")
    password = payload.get("password")
    displayName = payload.get("displayName", "")
    photoURL = payload.get("photoURL", "")
    if not email or not password:
        raise HTTPException(status_code=400, detail="Missing email or password")

    existing = db.get_doc("users", email)
    if existing:
        raise HTTPException(status_code=400, detail="อีเมลนี้ถูกใช้งานแล้ว")

    db.set_doc(
        "users",
        email,
        None,
        {
            "email": email,
            "password": password,
            "displayName": displayName,
            "photoURL": photoURL,
            "role": "user",
        },
    )
    return {
        "success": True,
        "email": email,
        "displayName": displayName,
        "photoURL": photoURL,
    }


@app.post("/api/auth/login")
def auth_login(payload: dict = Body(...), db=Depends(get_db)):
    email = payload.get("email")
    password = payload.get("password")
    if not email or not password:
        raise HTTPException(status_code=400, detail="Missing email or password")

    user_doc = db.get_doc("users", email)
    if user_doc and user_doc.get("status") == "suspended":
        raise HTTPException(
            status_code=403,
            detail="บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ",
        )

    hashed_input = hashlib.sha256(password.encode()).hexdigest()
    if not user_doc or (
        user_doc.get("password") != password
        and user_doc.get("password") != hashed_input
    ):
        raise HTTPException(status_code=401, detail="อีเมลหรือรหัสผ่านไม่ถูกต้อง")

    return {
        "email": user_doc.get("email"),
        "displayName": user_doc.get("displayName") or "",
        "photoURL": user_doc.get("photoURL") or "",
        "role": user_doc.get("role") or "user",
        "providerData": [{"providerId": "password"}],
    }


@app.post("/api/auth/change-password")
def auth_change_password(payload: dict = Body(...), db=Depends(get_db)):
    email = payload.get("email")
    old_password = payload.get("old_password")
    new_password = payload.get("new_password")
    
    if not email or not old_password or not new_password:
        raise HTTPException(status_code=400, detail="Missing required fields")

    user_doc = db.get_doc("users", email)
    if not user_doc:
        raise HTTPException(status_code=404, detail="User not found")

    hashed_input = hashlib.sha256(old_password.encode()).hexdigest()
    if user_doc.get("password") != old_password and user_doc.get("password") != hashed_input:
        raise HTTPException(status_code=401, detail="รหัสผ่านเดิมไม่ถูกต้อง")

    hashed_new_password = hashlib.sha256(new_password.encode()).hexdigest()
    
    user_doc["password"] = hashed_new_password
    db.set_doc("users", email, None, user_doc)
    
    return {"success": True, "message": "Password changed successfully"}


@app.post("/api/auth/google")
def auth_google(payload: dict = Body(...), db=Depends(get_db)):
    access_token = payload.get("access_token")
    email = None
    displayName = ""
    photoURL = ""

    if access_token:
        # Call Google API to verify access token and get profile info
        google_url = (
            f"https://www.googleapis.com/oauth2/v3/userinfo?access_token={access_token}"
        )
        try:
            resp = requests.get(google_url, timeout=10)
            if resp.status_code == 200:
                google_profile = resp.json()
                email = google_profile.get("email")
                displayName = google_profile.get("name", "")
                photoURL = google_profile.get("picture", "")
        except Exception:
            pass

    # Fallback to direct email in payload if access_token missing or Google verification failed
    if not email:
        email = payload.get("email")
        displayName = (
            payload.get("displayName")
            or payload.get("name")
            or (email.split("@")[0] if email else "")
        )
        photoURL = (
            payload.get("photoURL")
            or "https://img.icons8.com/color/96/000000/google-logo.png"
        )

    if not email:
        raise HTTPException(
            status_code=400, detail="Missing Google access token or email"
        )

    # Get or create user in local SQL
    user_doc = db.get_doc("users", email)
    if user_doc and user_doc.get("status") == "suspended":
        raise HTTPException(
            status_code=403,
            detail="บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ",
        )

    if not user_doc:
        db.set_doc(
            "users",
            email,
            None,
            {
                "email": email,
                "password": "",
                "displayName": displayName,
                "photoURL": photoURL,
                "role": "user",
            },
        )
        user_doc = {
            "email": email,
            "displayName": displayName,
            "photoURL": photoURL,
            "role": "user",
        }
    else:
        # Update details if they have changed or are empty
        updated = {}
        if not user_doc.get("displayName") and displayName:
            updated["displayName"] = displayName
        if not user_doc.get("photoURL") and photoURL:
            updated["photoURL"] = photoURL
        if updated:
            db.update_doc("users", email, None, updated)

    return {
        "email": user_doc.get("email"),
        "displayName": user_doc.get("displayName") or "",
        "photoURL": user_doc.get("photoURL") or "",
        "role": user_doc.get("role") or "user",
        "providerData": [{"providerId": "google.com"}],
    }


@app.post("/api/auth/google-mock")
def auth_google_mock(payload: dict = Body(...), db=Depends(get_db)):
    email = payload.get("email")
    displayName = payload.get("displayName", "Google Mock User")
    photoURL = payload.get(
        "photoURL", "https://img.icons8.com/color/96/000000/google-logo.png"
    )
    if not email:
        raise HTTPException(status_code=400, detail="Missing email for mock login")

    user_doc = db.get_doc("users", email)
    if user_doc and user_doc.get("status") == "suspended":
        raise HTTPException(
            status_code=403,
            detail="บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ",
        )

    if not user_doc:
        db.set_doc(
            "users",
            email,
            None,
            {
                "email": email,
                "password": "",
                "displayName": displayName,
                "photoURL": photoURL,
                "role": "user",
            },
        )
        user_doc = {
            "email": email,
            "displayName": displayName,
            "photoURL": photoURL,
            "role": "user",
        }

    return {
        "email": user_doc.get("email"),
        "displayName": user_doc.get("displayName") or "",
        "photoURL": user_doc.get("photoURL") or "",
        "role": user_doc.get("role") or "user",
        "providerData": [{"providerId": "google.com"}],
    }


@app.get("/api/db/{path:path}")
def db_get(path: str, request: Request, db=Depends(get_db)):
    parsed = parse_db_path(path)
    collection = parsed["collection"]
    doc_id = parsed["doc_id"]
    user_email = parsed["user_email"]
    parent_doc_id = parsed["parent_doc_id"]

    if not collection:
        raise HTTPException(status_code=400, detail="Invalid path")

    if doc_id:
        doc = db.get_doc(collection, doc_id, user_email)
        if doc is None:
            return None
        return doc
    else:
        items = db.get_collection(collection, user_email, parent_doc_id)
        for k, v in request.query_params.items():
            if k == "limit":
                continue
            items = [item for item in items if str(item.get(k)) == str(v)]

        if "limit" in request.query_params:
            try:
                limit_val = int(request.query_params["limit"])
                items = items[:limit_val]
            except ValueError:
                pass
        return items


@app.post("/api/db/{path:path}")
def db_post(path: str, payload: dict = Body(...), db=Depends(get_db)):
    parsed = parse_db_path(path)
    collection = parsed["collection"]
    user_email = parsed["user_email"]
    if not collection:
        raise HTTPException(status_code=400, detail="Invalid path")

    doc_id = db.add_doc(collection, user_email, payload)
    return {"id": doc_id}


@app.put("/api/db/{path:path}")
def db_put(path: str, payload: dict = Body(...), db=Depends(get_db)):
    parsed = parse_db_path(path)
    collection = parsed["collection"]
    doc_id = parsed["doc_id"]
    user_email = parsed["user_email"]
    if not collection or not doc_id:
        raise HTTPException(status_code=400, detail="Invalid path")

    db.set_doc(collection, doc_id, user_email, payload)
    return {"ok": True}


@app.patch("/api/db/{path:path}")
def db_patch(path: str, payload: dict = Body(...), db=Depends(get_db)):
    parsed = parse_db_path(path)
    collection = parsed["collection"]
    doc_id = parsed["doc_id"]
    user_email = parsed["user_email"]
    if not collection or not doc_id:
        raise HTTPException(status_code=400, detail="Invalid path")

    db.update_doc(collection, doc_id, user_email, payload)
    return {"ok": True}


@app.get("/api/settings/academic_year")
def get_academic_year(db=Depends(get_db)):
    doc_year = db.get_doc("settings", "academic_year")
    doc_term = db.get_doc("settings", "academic_term")
    return {
        "year": doc_year.get("value") if doc_year and doc_year.get("value") else "2567",
        "term": doc_term.get("value") if doc_term and doc_term.get("value") else "1",
    }


@app.put("/api/settings/academic_year")
def set_academic_year(
    payload: dict = Body(...),
    authorization: str | None = Header(None),
    db=Depends(get_db),
):
    user_email = get_user_email(authorization)
    admin_user = db.get_doc("users", user_email)
    print(
        f"DEBUG: authorization={authorization}, user_email={user_email}, admin_user={admin_user}"
    )
    if not admin_user or admin_user.get("role") != "admin":
        raise HTTPException(status_code=403, detail="Admin only")

    db.set_doc(
        "settings",
        "academic_year",
        None,
        {
            "value": str(payload.get("year", "2567")),
        },
    )
    db.set_doc(
        "settings", "academic_term", None, {"value": str(payload.get("term", "1"))}
    )
    return {"ok": True}


@app.delete("/api/db/{path:path}")
def db_delete(path: str, db=Depends(get_db)):
    parsed = parse_db_path(path)
    collection = parsed["collection"]
    doc_id = parsed["doc_id"]
    user_email = parsed["user_email"]
    if not collection or not doc_id:
        raise HTTPException(status_code=400, detail="Invalid path")

    db.delete_doc(collection, doc_id, user_email)
    return {"ok": True}


@app.get("/api/migrate_db")
def migrate_db(db=Depends(get_db)):
    # pyrefly: ignore [missing-import]
    from sqlalchemy import text

    session = db._get_session()
    logs = []
    try:
        # Drop FKs referencing subjects_sec.section_id
        for table in ["student_enrollments", "exams"]:
            res = session.execute(
                text(
                    f"SELECT CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE WHERE TABLE_NAME = '{table}' AND COLUMN_NAME = 'section_id' AND REFERENCED_TABLE_NAME = 'subjects_sec'"
                )
            ).fetchall()
            for r in res:
                fk_name = r[0]
                logs.append(f"Dropping FK: {fk_name} from {table}")
                session.execute(text(f"ALTER TABLE {table} DROP FOREIGN KEY {fk_name}"))

        logs.append("Modifying subjects_sec.section_id to VARCHAR(50)")
        session.execute(
            text("ALTER TABLE subjects_sec MODIFY COLUMN section_id VARCHAR(50)")
        )

        logs.append("Modifying student_enrollments.section_id to VARCHAR(50)")
        session.execute(
            text("ALTER TABLE student_enrollments MODIFY COLUMN section_id VARCHAR(50)")
        )

        logs.append("Modifying exams.section_id to VARCHAR(50)")
        session.execute(text("ALTER TABLE exams MODIFY COLUMN section_id VARCHAR(50)"))

        logs.append("Adding FKs back")
        session.execute(
            text(
                "ALTER TABLE student_enrollments ADD CONSTRAINT student_enrollments_fk_sec FOREIGN KEY (section_id, user_id) REFERENCES subjects_sec (section_id, user_id) ON DELETE CASCADE"
            )
        )
        session.execute(
            text(
                "ALTER TABLE exams ADD CONSTRAINT exams_fk_sec FOREIGN KEY (section_id, user_id) REFERENCES subjects_sec (section_id, user_id) ON DELETE CASCADE"
            )
        )

        session.commit()
        logs.append("Migration successful")
    except Exception as e:
        session.rollback()
        logs.append(f"Error: {str(e)}")
        return {"status": "error", "logs": logs}
    finally:
        session.close()

    return {"status": "success", "logs": logs}


# ─────────────────────────────────────────────────────────────────────────────
# Helper: แปลง user_email → user_id ในตาราง users
# ─────────────────────────────────────────────────────────────────────────────
def _get_user_id_by_email(email: str, db) -> str:
    user = db.get_doc("users", email)
    if not user:
        raise HTTPException(status_code=404, detail=f"ไม่พบผู้ใช้งาน email: {email}")
    return user.get("user_id", "")


def _short_id() -> str:
    """สร้าง ID สั้น 10 ตัวอักษร"""
    return str(uuid.uuid4().int)[:10]


# ─────────────────────────────────────────────────────────────────────────────
# Answer (เฉลยข้อสอบ)
# ─────────────────────────────────────────────────────────────────────────────
# Admin Login Authentication (ขอบเขต 1.3.1.1)
# ─────────────────────────────────────────────────────────────────────────────
@app.post("/api/auth/admin/login")
def admin_login(payload: dict = Body(...), db=Depends(get_db)):
    aname = payload.get("aname")
    apassword = payload.get("apassword")
    if not aname or not apassword:
        raise HTTPException(status_code=400, detail="กรุณากรอกชื่อผู้ใช้และรหัสผ่าน")

    hashed_input = hashlib.sha256(apassword.encode()).hexdigest()

    # ตรวจสอบว่ามี default admin หรือยัง (query ตรงๆ แทนการโหลดทั้ง table)
    admin_user = db.get_admin_by_name(aname)

    if admin_user is None:
        # สร้าง default admin ถ้ายังไม่มีในระบบ
        default_hash = hashlib.sha256("admin1234".encode()).hexdigest()
        db.set_doc(
            "users",
            "admin@localhost",
            None,
            {
                "email": "admin@localhost",
                "username": "admin",
                "password": default_hash,
                "role": "admin",
                "displayName": "System Admin",
            },
        )
        admin_user = db.get_admin_by_name(aname)

    if (
        admin_user
        and admin_user.get("role") == "admin"
        and admin_user.get("password") == hashed_input
    ):
        return admin_user

    raise HTTPException(
        status_code=401,
        detail="ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง หรือไม่มีสิทธิ์ผู้ดูแลระบบ",
    )
