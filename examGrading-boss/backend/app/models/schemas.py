from pydantic import BaseModel


class SheetPdfRequest(BaseModel):
    user_email: str | None = None
    exam_id: str
    student_ids: list[str] | None = None
    upload_to_storage: bool = True


class SheetPdfBySubjectRequest(BaseModel):
    user_email: str | None = None
    exam_id: str
    subject_code: str


class ScanCloudinaryRequest(BaseModel):
    exam_id: str
    image_url: str
    user_email: str | None = None
    answer_set: str = "0"
    debug: bool = False
    save_result: bool = True
