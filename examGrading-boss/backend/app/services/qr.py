"""
QR Code Generator สำหรับระบบตรวจข้อสอบ
========================================
สร้าง QR Code ที่เก็บข้อมูลครบทั้งหมด:
  - รหัสวิชา, ชื่อวิชา
  - รหัสนักเรียน, ชื่อ-นามสกุล
  - วันที่สอบ
  - จำนวนข้อ (30 / 50 / 100)  ← แก้ปัญหา barcode จำลอง

วิธีใช้:
  python3 generate_qr.py          → demo สร้าง QR ตัวอย่าง
  import generate_qr as gq        → ใช้ใน code อื่น
"""

import cv2
import numpy as np
import json
import os
from datetime import datetime


# ─────────────────────────────────────────
#  QR Payload Schema
# ─────────────────────────────────────────

def build_qr_payload(
    subject_code:    str,
    subject_name:    str,
    student_id:      str,
    student_name:    str,
    exam_date:       str,
    total_questions: int,   # 30 / 50 / 100
    sheet_id:        str = "",  # optional: unique ID ของกระดาษใบนี้
    exam_id:         str = "",
) -> str:
    """
    สร้าง JSON string สำหรับเข้ารหัสใน QR
    ใช้ key สั้นเพื่อลด QR complexity → อ่านง่ายขึ้น
    """
    payload = {
        "sc": subject_code,       # subject code
        "sn": subject_name,       # subject name
        "id": student_id,         # student ID
        "nm": student_name,       # student name
        "dt": exam_date,          # exam date
        "tq": total_questions,    # total questions
        "sid": sheet_id,          # sheet ID (optional)
        "eid": exam_id,           # exam ID
    }
    return json.dumps(payload, ensure_ascii=False, separators=(",", ":"))


def parse_qr_payload(qr_string: str) -> dict:
    """
    แปลง QR string กลับเป็น dict
    รองรับทั้ง format สั้น (key sc/sn/...) และ format ยาว
    """
    try:
        data = json.loads(qr_string)
        # normalize key ยาว → สั้น
        key_map = {
            "subject_code":    "sc",
            "subject_name":    "sn",
            "student_id":      "id",
            "student_name":    "nm",
            "exam_date":       "dt",
            "total_questions": "tq",
            "sheet_id":        "sid",
            "exam_id":         "eid",
        }
        for long, short in key_map.items():
            if long in data and short not in data:
                data[short] = data.pop(long)
        return data
    except json.JSONDecodeError:
        # fallback: QR เก็บแค่ตัวเลขจำนวนข้อ
        if qr_string.strip().isdigit():
            return {"tq": int(qr_string.strip())}
        return {"sc": qr_string.strip()}


# ─────────────────────────────────────────
#  สร้าง QR Image ด้วย cv2.QRCodeEncoder
# ─────────────────────────────────────────

def generate_qr_image(payload_str: str, target_px: int = 180) -> np.ndarray:
    """
    สร้าง QR Code image จาก string
    ใช้ integer scale เสมอ → แต่ละ QR module ได้ pixel เต็มจำนวน
    ไม่มี anti-aliasing blur ที่ทำให้ decode ผิดพลาด
    คืน numpy array (grayscale)
    """
    params = cv2.QRCodeEncoder_Params()
    params.correction_level = cv2.QRCodeEncoder_CORRECT_LEVEL_L
    encoder = cv2.QRCodeEncoder.create(params)
    qr_raw  = encoder.encode(payload_str)
    modules = qr_raw.shape[0]

    # integer scale ≥ 4px/module เพื่อให้ decode ได้จากมือถือ
    scale  = max(4, target_px // modules)
    size   = modules * scale
    qr_big = cv2.resize(qr_raw, (size, size), interpolation=cv2.INTER_NEAREST)
    return qr_big


def generate_qr_with_border(payload_str: str, target_px: int = 180, border: int = 12) -> np.ndarray:
    """
    QR พร้อม quiet zone (border สีขาว) ตามมาตรฐาน QR Code
    """
    qr    = generate_qr_image(payload_str, target_px)
    size  = qr.shape[0]
    total = size + border * 2
    canvas = np.ones((total, total), dtype=np.uint8) * 255
    canvas[border:border+size, border:border+size] = qr
    return canvas


# ─────────────────────────────────────────
#  ทดสอบ decode QR ที่สร้างขึ้น
# ─────────────────────────────────────────

def verify_qr(qr_image: np.ndarray) -> tuple[bool, str]:
    """
    ทดสอบ decode QR ที่สร้างขึ้นด้วย OpenCV
    คืน (success, decoded_string)
    """
    detector = cv2.QRCodeDetector()
    data, pts, _ = detector.detectAndDecode(qr_image)
    if data:
        return True, data
    # ลอง threshold ก่อน decode
    if len(qr_image.shape) == 3:
        gray = cv2.cvtColor(qr_image, cv2.COLOR_BGR2GRAY)
    else:
        gray = qr_image
    _, binary = cv2.threshold(gray, 127, 255, cv2.THRESH_BINARY)
    data, pts, _ = detector.detectAndDecode(binary)
    return (bool(data), data)


# ─────────────────────────────────────────
#  สร้าง QR สำหรับกระดาษ template
#  (ใช้ตอนพิมพ์กระดาษจริง)
# ─────────────────────────────────────────

def generate_sheet_qr(
    total_questions: int,
    subject_code: str = "",
    subject_name: str = "",
    student_id: str = "",
    student_name: str = "",
    exam_date: str = "",
    sheet_id: str = "",
    output_path: str = None
) -> np.ndarray:
    """
    สร้าง QR สำหรับกระดาษคำตอบหนึ่งใบ
    ถ้าไม่ระบุข้อมูลนักเรียน → เป็น QR template (มีแค่จำนวนข้อ)
    """
    payload = build_qr_payload(
        subject_code=subject_code,
        subject_name=subject_name,
        student_id=student_id,
        student_name=student_name,
        exam_date=exam_date,
        total_questions=total_questions,
        sheet_id=sheet_id,
    )

    qr_img = generate_qr_with_border(payload, target_px=180, border=12)

    if output_path:
        cv2.imwrite(output_path, qr_img)
        print(f"บันทึก QR: {output_path}")
        print(f"  payload: {payload}")
        # ทดสอบ decode
        ok, decoded = verify_qr(qr_img)
        print(f"  verify:  {'✓ OK' if ok else '✗ FAIL'} → {decoded[:60]}...")

    return qr_img


# ─────────────────────────────────────────
#  อัปเดต omr_scanner ให้ใช้ parse_qr_payload
# ─────────────────────────────────────────

def extract_metadata_from_qr(qr_string: str):
    """
    แปลง QR string → SheetMetadata
    (ใช้แทน decode_qr_and_barcode ใน omr_scanner.py)
    """
    # import ที่นี่เพื่อ avoid circular import
    import sys, os
    sys.path.insert(0, os.path.dirname(__file__))
    from .omr_scanner import SheetMetadata

    meta = SheetMetadata()
    if not qr_string:
        return meta

    data = parse_qr_payload(qr_string)
    meta.subject_code    = data.get("sc", "")
    meta.subject_name    = data.get("sn", "")
    meta.student_id      = data.get("id", "")
    meta.student_name    = data.get("nm", "")
    meta.exam_date       = data.get("dt", "")
    meta.total_questions = int(data.get("tq", 0))
    meta.sheet_id        = data.get("sid", "")
    meta.exam_id         = data.get("eid", "")
    return meta
