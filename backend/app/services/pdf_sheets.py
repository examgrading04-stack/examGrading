import os
import tempfile
from datetime import datetime
from functools import lru_cache
from pathlib import Path

# pyrefly: ignore [missing-import]
import numpy as np
# pyrefly: ignore [missing-import]
from PIL import Image, ImageDraw, ImageFont

from .qr import build_qr_payload, generate_qr_with_border


BACKEND_DIR = Path(__file__).resolve().parents[2]
TEMPLATE_MAP = {
    30: BACKEND_DIR / "assets" / "templates" / "template_30q.png",
    50: BACKEND_DIR / "assets" / "templates" / "template_50q.png",
    100: BACKEND_DIR / "assets" / "templates" / "template_100q.png",
}

TEXT_BOXES = {
    "subject_code": (300, 240, 520, 44),
    "subject_name": (300, 306, 520, 44),
    "student_id": (300, 374, 520, 44),
    "student_name": (300, 444, 520, 44),
    "exam_date": (300, 512, 520, 44),
}
DEFAULT_QR_POSITION = (900, 250)
TEXT_BOTTOM_PADDING = -4


def _nearest_supported_question_count(total_questions: int) -> int:
    if total_questions <= 30:
        return 30
    if total_questions <= 50:
        return 50
    return 100


def _default_font_path() -> str:
    candidates = [
        os.getenv("THAI_FONT_PATH", ""),
        "C:/Windows/Fonts/tahoma.ttf",
        "C:/Windows/Fonts/tahomabd.ttf",
        "C:/Windows/Fonts/THSarabunNew.ttf",
        "/usr/share/fonts/truetype/tlwg/Garuda.ttf",
        "/usr/share/fonts/truetype/tlwg/Garuda-Bold.ttf",
        "/usr/share/fonts/truetype/tlwg/Loma.ttf",
        "/usr/share/fonts/truetype/tlwg/TlwgTypist.ttf",
        "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
    ]
    for candidate in candidates:
        if os.path.exists(candidate):
            return candidate
    return ""


def _load_font(size: int, font_path: str | None = None) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    return _load_font_cached(size, font_path or _default_font_path())


@lru_cache(maxsize=64)
def _load_font_cached(size: int, font_path: str) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    try:
        return ImageFont.truetype(font_path, size)
    except OSError:
        return ImageFont.load_default()


@lru_cache(maxsize=8)
def _load_template_rgb(template_path: str) -> Image.Image:
    return Image.open(template_path).convert("RGB")


def _draw_fitted_text(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    text: str,
    font_path: str | None,
    base_size: int,
) -> None:
    x, y, max_width, max_height = box
    font_size = base_size
    font = _load_font(font_size, font_path)

    while font_size > 22:
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        if text_width <= max_width and text_height <= max_height:
            break
        font_size -= 2
        font = _load_font(font_size, font_path)

    bbox = draw.textbbox((0, 0), text, font=font)
    text_height = bbox[3] - bbox[1]
    text_y = y + max_height - text_height - TEXT_BOTTOM_PADDING - bbox[1]
    draw.text((x, text_y), text, font=font, fill=(0, 0, 0))


def build_sheet_payload(exam: dict, student: dict) -> dict:
    """Normalize Firestore exam/student docs into the QR/text payload used by the OMR scanner."""
    subject_code = exam.get("subject") or exam.get("subjectCode") or exam.get("code") or exam.get("subject_id") or ""
    student_doc_id = student.get("id") or student.get("docId") or ""
    student_code = student.get("code") or student.get("studentCode") or student.get("student_id") or student_doc_id
    exam_id = exam.get("id") or exam.get("examId") or ""

    return {
        "subject_code": subject_code,
        "subject_name": exam.get("subjectName") or exam.get("subject_name") or exam.get("subject_title") or "",
        "student_id": student_code,
        "student_name": student.get("name") or student.get("studentName") or student.get("student_name") or "",
        "exam_date": exam.get("date") or datetime.now().strftime("%Y-%m-%d"),
        "total_questions": int(exam.get("questions") or exam.get("total_questions") or 50),
        "sheet_id": f"{exam_id}:{student_doc_id or student_code}",
        "exam_id": exam_id,
        "student_doc_id": student_doc_id,
    }


def create_single_sheet_image(
    sheet_payload: dict,
    template_path: str | Path | None = None,
    qr_position: tuple[int, int] = DEFAULT_QR_POSITION,
    text_positions: dict | None = None,
    font_path: str | None = None,
    font_size: int = 32,
) -> Image.Image:
    """Create one answer-sheet image from normalized sheet payload."""
    total_questions = int(sheet_payload.get("total_questions") or 50)
    template_key = _nearest_supported_question_count(total_questions)
    resolved_template = Path(template_path) if template_path else TEMPLATE_MAP[template_key]

    if not resolved_template.exists():
        raise FileNotFoundError(f"Template not found: {resolved_template}")

    template_img = _load_template_rgb(str(resolved_template)).copy()
    payload_str = build_qr_payload(
        subject_code=sheet_payload.get("subject_code", ""),
        subject_name=sheet_payload.get("subject_name", ""),
        student_id=sheet_payload.get("student_id", ""),
        student_name=sheet_payload.get("student_name", ""),
        exam_date=sheet_payload.get("exam_date", ""),
        total_questions=total_questions,
        sheet_id=sheet_payload.get("sheet_id", ""),
        exam_id=sheet_payload.get("exam_id", ""),
    )

    qr_np_array = generate_qr_with_border(payload_str, target_px=180, border=8)
    qr_img = Image.fromarray(qr_np_array.astype(np.uint8)).convert("RGB")
    qr_img = qr_img.resize((370, 370))
    template_img.paste(qr_img, qr_position)

    draw = ImageDraw.Draw(template_img)

    boxes = text_positions or TEXT_BOXES
    for key, box in boxes.items():
        value = sheet_payload.get(key)
        if value:
            _draw_fitted_text(
                draw,
                box,
                str(value),
                font_path,
                font_size,
            )

    return template_img


def generate_pdf_for_students(
    exam: dict,
    students: list[dict],
    output_path: str | Path | None = None,
) -> str:
    """Generate a multi-page PDF for the selected exam and students. Returns the PDF path."""
    if not students:
        raise ValueError("students is required")

    pages = []
    for student in students:
        payload = build_sheet_payload(exam, student)
        pages.append(create_single_sheet_image(payload))

    if output_path is None:
        safe_exam_id = exam.get("id") or exam.get("examId") or "exam"
        output_path = Path(tempfile.gettempdir()) / f"{safe_exam_id}_answer_sheets.pdf"
    else:
        output_path = Path(output_path)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    pages[0].save(
        output_path,
        "PDF",
        resolution=100.0,
        save_all=True,
        append_images=pages[1:],
    )
    return str(output_path)
