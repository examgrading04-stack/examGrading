import json
import numpy as np
import os
from PIL import Image, ImageDraw, ImageFont
from generate_qr import generate_qr_with_border

def create_single_sheet_image(
    student_data: dict,
    template_path: str,
    qr_position: tuple,
    text_positions: dict,
    font_path: str = "C:/Windows/Fonts/tahoma.ttf",
    font_size: int = 30
) -> Image.Image:
    """
    สร้างรูปภาพกระดาษคำตอบ 1 ใบในหน่วยความจำ
    """
    # 1. โหลดกระดาษเปล่าตาม Template ที่เลือก
    try:
        if not os.path.exists(template_path):
            # Fallback หากหาไฟล์ใน templates/ ไม่เจอ ให้ลองหาที่โฟลเดอร์หลัก (เผื่อกรณีไฟล์ 1.png เดิม)
            template_img = Image.open("1.png").convert("RGB")
            print(f"Warning: หา {template_path} ไม่เจอ ใช้ 1.png แทน")
        else:
            template_img = Image.open(template_path).convert("RGB")
    except Exception as e:
        print(f"Error: ไม่สามารถโหลด Template ได้: {e}")
        return None

    # 2. แปลงข้อมูลนักเรียนเป็น JSON String เพื่อทำ QR Code
    json_data_str = json.dumps(student_data, ensure_ascii=False)
    
    # 3. สร้างรูป QR Code และแปะลงกระดาษ
    qr_np_array = generate_qr_with_border(json_data_str, target_px=180, border=8)
    qr_img = Image.fromarray(qr_np_array.astype(np.uint8)).convert("RGB")
    qr_img = qr_img.resize((370, 370)) 
    template_img.paste(qr_img, qr_position)

    # 4. วาดข้อความ
    draw = ImageDraw.Draw(template_img)
    try:
        font = ImageFont.truetype(font_path, font_size)
    except IOError:
        font = ImageFont.load_default()

    for key, (x, y) in text_positions.items():
        if key in student_data:
            text_to_draw = f"{student_data[key]}"
            draw.text((x, y), text_to_draw, font=font, fill=(0, 0, 0))

    return template_img


def generate_pdf_for_all_students():
    # 1. รายชื่อนักเรียนและข้อมูลการสอบ
    students = [
        {
            "subject_code": "CS101", "subject_name": "วิทยาการคอมพิวเตอร์",
            "student_id": "66010001", "student_name": "สมชาย ใจดี",
            "total_questions": 30, "exam_date": "2026-05-15 09:30"
        },
        {
            "subject_code": "MATH201", "subject_name": "แคลคูลัส",
            "student_id": "66010002", "student_name": "สมหญิง รักเรียน",
            "total_questions": 50, "exam_date": "2026-05-16 13:00"
        },
        {
            "subject_code": "PHYS301", "subject_name": "ฟิสิกส์ทั่วไป",
            "student_id": "66010003", "student_name": "วิชัย เก่งมาก",
            "total_questions": 100, "exam_date": "2026-05-17 09:00"
        }
    ]

    # การตั้งค่า Template ตามจำนวนข้อ
    # Key: จำนวนข้อ, Value: พาธไฟล์ Template
    template_map = {
        30: "templates/template_30q.png",
        50: "templates/template_50q.png",
        100: "templates/template_100q.png"
    }

    # พิกัดวางข้อความและ QR Code (อ้างอิงจากตำแหน่งบนหัวกระดาษซึ่งมักจะเหมือนกันทุก Template)
    my_text_positions = {
        "subject_code": (300, 260),
        "subject_name": (300, 320),
        "student_id": (300, 400),
        "student_name": (300, 470),
        "exam_date": (300, 530),
    }
    my_qr_position = (900, 250)

    all_pages = []

    print(f"กำลังเริ่มสร้างกระดาษคำตอบสำหรับนักเรียน {len(students)} คน...")

    # 2. วนลูปสร้างรูปกระดาษคำตอบทีละใบ
    for student in students:
        n_q = student.get("total_questions", 50)
        template_file = template_map.get(n_q, "templates/template_50q.png")
        
        print(f"- กำลังประมวลผล: {student['student_id']} ({n_q} ข้อ) -> {template_file}")
        
        sheet_img = create_single_sheet_image(
            student_data=student,
            template_path=template_file,
            qr_position=my_qr_position,
            text_positions=my_text_positions
        )
        if sheet_img:
            all_pages.append(sheet_img)

    # 3. รวมเป็น PDF
    if len(all_pages) > 0:
        pdf_output_path = "all_students_exam_sheets.pdf"
        all_pages[0].save(
            pdf_output_path, 
            "PDF", 
            resolution=100.0, 
            save_all=True, 
            append_images=all_pages[1:]
        )
        print(f"\n✅ สำเร็จ! รวมไฟล์ PDF เรียบร้อย: {pdf_output_path}")
    else:
        print("\n❌ ล้มเหลว: ไม่พบหน้ากระดาษที่จะสร้าง PDF")


if __name__ == "__main__":
    generate_pdf_for_all_students()
