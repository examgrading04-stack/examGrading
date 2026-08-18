import os
import tempfile
import pandas as pd
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.platypus import SimpleDocTemplate, Table, TableStyle, Paragraph, Spacer
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfbase import pdfmetrics

# Check if THSarabunNew font exists, if not, we use Helvetica (might not support Thai, but we try)
# We can download a Thai font, or use standard fonts. For robust Thai support,
# we need a font like TH Sarabun New. We will try to load it if available.
FONT_NAME = "Helvetica"
FONT_BOLD = "Helvetica-Bold"


def register_fonts():
    global FONT_NAME, FONT_BOLD
    font_path = os.path.join(
        os.path.dirname(__file__), "..", "..", "fonts", "THSarabunNew.ttf"
    )
    font_bold_path = os.path.join(
        os.path.dirname(__file__), "..", "..", "fonts", "THSarabunNew-Bold.ttf"
    )
    if os.path.exists(font_path):
        pdfmetrics.registerFont(TTFont("THSarabunNew", font_path))
        FONT_NAME = "THSarabunNew"
        if os.path.exists(font_bold_path):
            pdfmetrics.registerFont(TTFont("THSarabunNew-Bold", font_bold_path))
            FONT_BOLD = "THSarabunNew-Bold"
        else:
            FONT_BOLD = "THSarabunNew"


register_fonts()


def prepare_report_data(
    exam: dict, results: list, students: list, subject_name: str, sections: list
) -> list:
    student_map = {
        s.get("id") or s.get("studentCode") or s.get("student_id"): s for s in students
    }
    section_map = {
        str(s.get("id")): (s.get("name") or s.get("sec") or s.get("section_name"))
        for s in (sections or [])
    }
    data = []

    for r in results:
        student_id = r.get("studentCode") or r.get("student_id") or ""
        student = student_map.get(student_id, {})
        student_name = student.get("name") or student.get("studentName") or "-"

        sec_id = (
            student.get("section") or student.get("sec") or exam.get("section") or ""
        )
        student_sec = section_map.get(str(sec_id), sec_id) if sec_id else "-"
        if student_sec == "All Section":
            student_sec = "All Section"

        score = r.get("score", 0)
        total = r.get("total") or r.get("totalQuestions") or exam.get("questions") or 0
        percent = r.get("percent") or r.get("percentage") or 0

        data.append(
            {
                "รหัสผู้เรียน": student_id,
                "ชื่อ-นามสกุล": student_name,
                "วิชา": subject_name,
                "กลุ่มเรียน": student_sec,
                "คะแนนที่ได้": score,
                "คะแนนเต็ม": total,
                "เปอร์เซ็นต์ (%)": f"{percent:.2f}%",
            }
        )

    # Sort by student id
    data.sort(key=lambda x: x["รหัสผู้เรียน"])
    return data


def generate_excel_report(
    exam: dict, results: list, students: list, subject_name: str, sections: list
) -> str:
    data = prepare_report_data(exam, results, students, subject_name, sections)

    df = pd.DataFrame(data)

    fd, temp_path = tempfile.mkstemp(suffix=".xlsx")
    os.close(fd)

    # Write to Excel
    df.to_excel(temp_path, index=False, engine="openpyxl")
    return temp_path


def generate_pdf_report(
    exam: dict, results: list, students: list, subject_name: str, sections: list
) -> str:
    data = prepare_report_data(exam, results, students, subject_name, sections)

    fd, temp_path = tempfile.mkstemp(suffix=".pdf")
    os.close(fd)

    doc = SimpleDocTemplate(
        temp_path,
        pagesize=A4,
        rightMargin=30,
        leftMargin=30,
        topMargin=30,
        bottomMargin=30,
    )
    elements = []

    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "TitleStyle",
        parent=styles["Heading1"],
        fontName=FONT_BOLD,
        fontSize=18,
        alignment=1,  # Center
        spaceAfter=12,
    )

    subtitle_style = ParagraphStyle(
        "SubtitleStyle",
        parent=styles["Normal"],
        fontName=FONT_NAME,
        fontSize=14,
        alignment=1,
        spaceAfter=20,
    )

    exam_name = exam.get("name", "N/A")
    elements.append(Paragraph(f"รายงานผลคะแนนสอบ: {exam_name}", title_style))
    elements.append(Paragraph(f"วิชา: {subject_name}", subtitle_style))

    # Table data
    headers = [
        "รหัสผู้เรียน",
        "ชื่อ-นามสกุล",
        "วิชา",
        "กลุ่มเรียน",
        "คะแนนที่ได้",
        "คะแนนเต็ม",
        "เปอร์เซ็นต์",
    ]
    table_data = [headers]
    for row in data:
        table_data.append(
            [
                row["รหัสผู้เรียน"],
                row["ชื่อ-นามสกุล"],
                row["วิชา"],
                row["กลุ่มเรียน"],
                str(row["คะแนนที่ได้"]),
                str(row["คะแนนเต็ม"]),
                str(row["เปอร์เซ็นต์ (%)"]),
            ]
        )

    table = Table(table_data, colWidths=[85, 130, 70, 55, 60, 60, 60])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#4f46e5")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.whitesmoke),
                ("ALIGN", (0, 0), (-1, -1), "CENTER"),
                ("FONTNAME", (0, 0), (-1, 0), FONT_BOLD),
                ("FONTSIZE", (0, 0), (-1, 0), 11),
                ("BOTTOMPADDING", (0, 0), (-1, 0), 12),
                ("BACKGROUND", (0, 1), (-1, -1), colors.white),
                ("TEXTCOLOR", (0, 1), (-1, -1), colors.black),
                ("FONTNAME", (0, 1), (-1, -1), FONT_NAME),
                ("FONTSIZE", (0, 1), (-1, -1), 10),
                ("ALIGN", (1, 1), (1, -1), "LEFT"),
                ("GRID", (0, 0), (-1, -1), 1, colors.black),
                ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.whitesmoke, colors.white]),
            ]
        )
    )

    elements.append(table)
    doc.build(elements)

    return temp_path
