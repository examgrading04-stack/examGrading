from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, List, Optional
import cv2
import numpy as np
import io

# นำเข้า core engine ที่เราพัฒนาไว้
from omr_scanner import scan_answer_sheet

app = FastAPI(title="OMR Scanner API")

# อนุญาตให้ Frontend (React/Next.js) สามารถเรียกใช้งาน API ได้ (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # ในการใช้งานจริงควรเปลี่ยนเป็น URL ของ Frontend
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Models สำหรับโครงสร้างข้อมูล ---
class SheetMetadataModel(BaseModel):
    subject_code: str
    subject_name: str
    student_id: str
    student_name: str
    exam_date: str
    total_questions: int

class ScanResponse(BaseModel):
    success: bool
    error_msg: str
    metadata: Optional[SheetMetadataModel] = None
    answers: Dict[int, Optional[str]] = {}
    flagged: List[int] = []

@app.post("/api/scan", response_model=ScanResponse)
async def scan_exam(file: UploadFile = File(...), force_questions: int = 0):
    """
    รับรูปภาพกระดาษคำตอบที่สแกนมาจาก Frontend (มือถือ/เว็บ)
    ประมวลผลด้วย OMR Scanner และคืนค่าคำตอบที่อ่านได้กลับไป
    """
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="ไฟล์ที่อัปโหลดต้องเป็นรูปภาพเท่านั้น")
    
    try:
        # อ่านไฟล์ภาพเป็น bytes
        image_bytes = await file.read()
        
        # แปลง bytes เป็น numpy array เพื่อให้ OpenCV ใช้งานได้ (ในหน่วยความจำโดยไม่ต้องเซฟลงดิสก์)
        nparr = np.frombuffer(image_bytes, np.uint8)
        img = cv2.imdecode(nparr, cv2.IMREAD_COLOR)
        
        if img is None:
            raise HTTPException(status_code=400, detail="ไม่สามารถอ่านไฟล์ภาพได้")
        
        # ส่งให้ OMR Scanner ประมวลผล
        # force_questions ให้ใส่ 30, 50, 100 หากต้องการบังคับโดยไม่ใช้ QR Code
        result = scan_answer_sheet(img, force_questions=force_questions)
        
        # เตรียมข้อมูลสำหรับส่งกลับไปยัง Frontend
        response = ScanResponse(
            success=result.success,
            error_msg=result.error_msg,
            answers=result.answers,
            flagged=result.flagged
        )
        
        if result.metadata:
            response.metadata = SheetMetadataModel(
                subject_code=result.metadata.subject_code,
                subject_name=result.metadata.subject_name,
                student_id=result.metadata.student_id,
                student_name=result.metadata.student_name,
                exam_date=result.metadata.exam_date,
                total_questions=result.metadata.total_questions
            )
            
        return response
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"เกิดข้อผิดพลาดในการประมวลผล: {str(e)}")

@app.get("/")
def read_root():
    return {"message": "OMR Scanner API is running. Send POST request to /api/scan"}
