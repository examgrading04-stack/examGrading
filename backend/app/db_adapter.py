import os
import json
import uuid
from datetime import datetime, date
from typing import Any, Dict, List, Optional
from abc import ABC, abstractmethod


# SQLAlchemy Imports
# pyrefly: ignore [missing-import]
from sqlalchemy import (
    create_engine,
    Column,
    String,
    Integer,
    Float,
    Boolean,
    Text,
    DateTime,
    Date,
    UniqueConstraint,
    ForeignKey,
)
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import declarative_base, sessionmaker, relationship

# ----------------------------------------------------
# Base DB Adapter Interface
# ----------------------------------------------------
class BaseDBAdapter(ABC):
    @abstractmethod
    def get_exam(self, user_email: str, exam_id: str) -> dict[str, Any]:
        pass

    @abstractmethod
    def update_exam(self, user_email: str, exam_id: str, data: dict[str, Any]) -> None:
        pass

    @abstractmethod
    def get_exams(self, user_email: str) -> List[dict[str, Any]]:
        pass

    @abstractmethod
    def get_students(self, user_email: str, student_ids: Optional[List[str]] = None) -> List[dict[str, Any]]:
        pass

    @abstractmethod
    def get_subject_name(self, user_email: str, subject_code: str) -> str:
        pass

    @abstractmethod
    def save_result(self, user_email: str, payload: dict[str, Any]) -> str:
        pass




# ----------------------------------------------------
# SQL Database (MySQL / XAMPP) Implementation
# ----------------------------------------------------
Base = declarative_base()

class SqlUser(Base):
    __tablename__ = "users"
    user_id = Column("user_id", String(100), primary_key=True)
    username = Column("username", String(100), nullable=False)
    password = Column("password", String(255), nullable=False)
    email = Column("email", String(100), nullable=False)
    displayName = Column("displayName", String(200))
    photoURL = Column("photoURL", String(500))
    role = Column("role", String(20), default="user")
    created_at = Column("created_at", DateTime, default=datetime.utcnow)

class SqlTemplate(Base):
    __tablename__ = "templates"
    template_id = Column("template_id", String(50), primary_key=True)
    template_name = Column("template_name", String(100), nullable=False)
    max_questions = Column("max_questions", Integer, nullable=False)
    image_path = Column("image_path", String(255))
    config_json = Column("config_json", Text)

class SqlSystemLog(Base):
    __tablename__ = "system_logs"
    logid = Column("log_id", String(50), primary_key=True)
    activity = Column("action", String(255), nullable=False)
    displayName = Column("displayName", String(200))
    role = Column("role", String(20))
    datetime = Column("action_time", DateTime, default=datetime.utcnow)
    userEmail = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="SET NULL")) # Note: old frontend used userEmail, now maps to user_id

class SqlSubject(Base):
    __tablename__ = "subjects"
    code = Column("subject_id", String(50), primary_key=True)
    name = Column("subject_name", String(200), nullable=False)
    term = Column("semester", Integer, nullable=True)
    year = Column("year", Integer, nullable=True)
    teacher = Column("instructor", String(200), nullable=True)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

class SqlStudent(Base):
    __tablename__ = "students"
    id = Column("student_code", String(50), primary_key=True)
    name = Column("student_name", String(200), nullable=False)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

class SqlSection(Base):
    __tablename__ = "subjects_sec"
    id = Column("section_id", Integer, primary_key=True, autoincrement=True)
    sec = Column("section_name", String(50), nullable=False)
    created_at = Column("created_at", DateTime, default=datetime.utcnow)
    subject = Column("subject_id", String(50), ForeignKey("subjects.subject_id", ondelete="CASCADE"), nullable=False)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

class SqlStudentEnrollment(Base):
    __tablename__ = "student_enrollments"
    enrollment_id = Column("enrollment_id", Integer, primary_key=True, autoincrement=True)
    student_code = Column("student_code", String(50), ForeignKey("students.student_code", ondelete="CASCADE"), nullable=False)
    subject_id = Column("subject_id", String(50), ForeignKey("subjects.subject_id", ondelete="CASCADE"), nullable=False)
    section_id = Column("section_id", Integer, ForeignKey("subjects_sec.section_id", ondelete="CASCADE"), nullable=False)
    user_id = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

class SqlExam(Base):
    __tablename__ = "exams"
    id = Column("exam_id", String(100), primary_key=True)
    name = Column("exam_name", String(200), nullable=False)
    questions = Column("questions", Integer, nullable=False)
    createdAt = Column("created_at", DateTime, default=datetime.utcnow)
    subject_id = Column("subject_id", String(50), ForeignKey("subjects.subject_id", ondelete="CASCADE"), nullable=False)
    section_id = Column("section_id", Integer, ForeignKey("subjects_sec.section_id", ondelete="CASCADE"), nullable=False)
    template_id = Column("template_id", String(50), ForeignKey("templates.template_id", ondelete="RESTRICT"), nullable=False)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

class SqlExamAnswerKey(Base):
    __tablename__ = "exam_answer_keys"
    answer_key_id = Column("answer_key_id", Integer, primary_key=True, autoincrement=True)
    question_no = Column("question_no", Integer, nullable=False)
    correct_answer = Column("correct_answer", String(1), nullable=False)
    exam_id = Column("exam_id", String(100), ForeignKey("exams.exam_id", ondelete="CASCADE"), nullable=False)

class SqlResult(Base):
    __tablename__ = "results"
    id = Column("result_id", String(100), primary_key=True)
    score = Column("score", Float, nullable=False)
    total = Column("total", Integer, nullable=False)
    percent = Column("percent", Float, nullable=False)
    flagged = Column("flagged", Boolean, default=False)
    imageUrl = Column("imageURL", String(500))
    createdAt = Column("created_at", DateTime, default=datetime.utcnow)
    examId = Column("exam_id", String(100), ForeignKey("exams.exam_id", ondelete="CASCADE"), nullable=False)
    studentCode = Column("student_code", String(50), ForeignKey("students.student_code", ondelete="CASCADE"), nullable=False)
    sheetId = Column("template_id", String(50), ForeignKey("templates.template_id", ondelete="RESTRICT"), nullable=False)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), nullable=False)

class SqlExamDetail(Base):
    __tablename__ = "exams_detail"
    exam_detail_id = Column("exam_detail_id", Integer, primary_key=True, autoincrement=True)
    question_no = Column("question_no", Integer, nullable=False)
    correct_answer = Column("correct_answer", String(1))
    student_answer = Column("student_answer", String(1))
    status_answer = Column("status_answer", String(20))
    result_id = Column("result_id", String(100), ForeignKey("results.result_id", ondelete="CASCADE"), nullable=False)

def _get_model_class(collection: str):
    mapping = {
        "users":           SqlUser,
        "profiles":        SqlUser,
        "subjects":        SqlSubject,
        "sections":        SqlSection,
        "students":        SqlStudent,
        "exams":           SqlExam,
        "results":         SqlResult,
        "systemLogs":      SqlSystemLog,
        "student_enrollments": SqlStudentEnrollment,
    }
    return mapping.get(collection)


class MySQLAdapter(BaseDBAdapter):
    def __init__(self, db_url: str):
        self.engine = create_engine(db_url, pool_recycle=3600, pool_pre_ping=True)
        Base.metadata.create_all(self.engine)
        self.SessionLocal = sessionmaker(bind=self.engine)

    def _get_session(self):
        return self.SessionLocal()

    def _to_dict(self, model_obj) -> dict[str, Any]:
        if not model_obj:
            return {}
        d = {c.key: getattr(model_obj, c.key) for c in getattr(model_obj, "__mapper__").column_attrs}
        
        # Dynamically fetch relationships that were previously JSON strings
        if isinstance(model_obj, SqlResult):
            session = self._get_session()
            try:
                details = session.query(SqlExamDetail).filter(SqlExamDetail.result_id == model_obj.id).order_by(SqlExamDetail.question_no).all()
                answers_dict = {}
                wrong_list = []
                skipped_list = []
                for det in details:
                    answers_dict[str(det.question_no)] = det.student_answer if det.student_answer else ""
                    if det.status_answer == "Wrong":
                        wrong_list.append(str(det.question_no))
                    elif det.status_answer == "Skipped":
                        skipped_list.append(str(det.question_no))
                
                d["answers"] = answers_dict
                d["wrong"] = wrong_list
                d["skipped"] = skipped_list
            finally:
                session.close()

        if isinstance(model_obj, SqlExam):
            session = self._get_session()
            try:
                keys = session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == model_obj.id).order_by(SqlExamAnswerKey.question_no).all()
                answer_key_dict = {}
                for key in keys:
                    answer_key_dict[str(key.question_no)] = key.correct_answer
                d["answerKey"] = answer_key_dict
                
                # Map back to frontend keys
                d["section"] = d.pop("section_id", None) or "All Section"
                d["sheetType"] = d.pop("template_id", None)
            finally:
                session.close()

        # Handle field mappings and JSON parsing
        if "metadata_json" in d:
            d["metadata"] = json.loads(d.pop("metadata_json") or "{}")
        
        # Convert datetime objects to string format
        for k, v in list(d.items()):
            if isinstance(v, datetime):
                d[k] = v.isoformat()
        
        for json_col in ["answerKey", "answers", "wrong", "skipped", "summary"]:
            if json_col in d and isinstance(d[json_col], str) and d[json_col]:
                try:
                    d[json_col] = json.loads(d[json_col])
                except Exception:
                    pass
        return d


    def get_exam(self, user_email: str, exam_id: str) -> dict[str, Any]:
        # pyrefly: ignore [missing-import]
        from fastapi import HTTPException
        session = self._get_session()
        try:
            row = session.query(SqlExam).join(SqlSubject, SqlExam.subject_id == SqlSubject.code).filter(
                SqlSubject.user_email == user_email,
                SqlExam.id == exam_id
            ).first()
            if not row:
                raise HTTPException(status_code=404, detail=f"Exam not found: {exam_id}")
            return self._to_dict(row)
        finally:
            session.close()

    def update_exam(self, user_email: str, exam_id: str, data: dict[str, Any]) -> None:
        session = self._get_session()
        try:
            row = session.query(SqlExam).join(SqlSubject, SqlExam.subject_id == SqlSubject.code).filter(
                SqlSubject.user_email == user_email,
                SqlExam.id == exam_id
            ).first()
            
            mapped_data = dict(data)
            answer_key = mapped_data.pop("answerKey", None)
            
            valid_cols = {c.key for c in getattr(SqlExam, "__mapper__").column_attrs}
            cleaned_data = {k: v for k, v in mapped_data.items() if k in valid_cols}

            if row:
                for k, v in cleaned_data.items():
                    setattr(row, k, v)
            else:
                row = SqlExam(id=exam_id, user_email=user_email, **cleaned_data)
                session.add(row)
            session.flush()
            
            if answer_key and isinstance(answer_key, dict):
                session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == exam_id).delete()
                for q_str, ans in answer_key.items():
                    try:
                        q_no = int(q_str)
                        session.add(SqlExamAnswerKey(exam_id=exam_id, question_no=q_no, correct_answer=ans))
                    except ValueError:
                        pass

            session.commit()
        finally:
            session.close()

    def get_exams(self, user_email: str) -> List[dict[str, Any]]:
        session = self._get_session()
        try:
            rows = session.query(SqlExam).join(SqlSubject, SqlExam.subject_id == SqlSubject.code).filter(SqlSubject.user_email == user_email).all()
            return [self._to_dict(r) for r in rows]
        finally:
            session.close()

    def get_students(self, user_email: str, student_ids: Optional[List[str]] = None) -> List[dict[str, Any]]:
        session = self._get_session()
        try:
            query = session.query(SqlStudent).filter(SqlStudent.user_email == user_email)
            if student_ids:
                query = query.filter(SqlStudent.id.in_(student_ids))
            rows = query.all()
            
            res = []
            for st in rows:
                d = self._to_dict(st)
                enrolls = session.query(SqlStudentEnrollment).filter(SqlStudentEnrollment.student_code == st.id).all()
                if not enrolls:
                    res.append(d)
                for en in enrolls:
                    d_copy = d.copy()
                    d_copy["subjectCode"] = en.subject_id
                    sec = session.query(SqlSection).filter(SqlSection.id == en.section_id).first()
                    if sec:
                        d_copy["section"] = sec.id
                    res.append(d_copy)
            return res
        finally:
            session.close()

    def get_subject_name(self, user_email: str, subject_code: str) -> str:
        session = self._get_session()
        try:
            row = session.query(SqlSubject).filter(
                SqlSubject.user_email == user_email,
                SqlSubject.code == subject_code
            ).first()
            return row.name if row else ""
        finally:
            session.close()

    def save_result(self, user_email: str, payload: dict[str, Any]) -> str:
        session = self._get_session()
        try:
            data = dict(payload)
            data["user_email"] = user_email
            data["id"] = uuid.uuid4().hex

            answers = data.pop("answers", {})
            wrong = data.pop("wrong", [])
            skipped = data.pop("skipped", [])
            
            # Clean placeholder firestore timestamps
            for ts_key in ["createdAt", "timestamp"]:
                if ts_key in data:
                    if not isinstance(data[ts_key], datetime):
                        data[ts_key] = datetime.utcnow()
            
            # Remove any keys that are not in SqlResult columns
            allowed_keys = {c.key for c in SqlResult.__mapper__.column_attrs}
            sql_data = {k: v for k, v in data.items() if k in allowed_keys}

            row = SqlResult(**sql_data)
            session.add(row)
            session.flush() # get id

            # insert details
            if isinstance(answers, dict):
                for q_str, ans in answers.items():
                    try:
                        q_no = int(q_str)
                    except ValueError:
                        continue
                    status = "Correct"
                    if q_str in wrong:
                        status = "Wrong"
                    elif q_str in skipped:
                        status = "Skipped"
                    
                    det = SqlExamDetail(
                        question_no=q_no,
                        student_answer=ans,
                        status_answer=status,
                        result_id=row.id
                    )
                    session.add(det)

            session.commit()
            return row.id
        finally:
            session.close()

    def get_doc(self, collection: str, doc_id: str, user_email: Optional[str] = None) -> Optional[dict]:
        model_cls = _get_model_class(collection)
        if not model_cls:
            return None
        session = self._get_session()
        try:
            query = session.query(model_cls)
            if hasattr(model_cls, "id"):
                query = query.filter(model_cls.id == doc_id)
            elif hasattr(model_cls, "code"):
                query = query.filter(model_cls.code == doc_id)
            elif hasattr(model_cls, "email"):
                if hasattr(model_cls, "username"):
                    # pyrefly: ignore [missing-import]
                    from sqlalchemy import or_
                    query = query.filter(or_(model_cls.email == doc_id, model_cls.username == doc_id))
                else:
                    query = query.filter(model_cls.email == doc_id)
            elif hasattr(model_cls, "logid"):
                query = query.filter(model_cls.logid == doc_id)
                
            if hasattr(model_cls, "user_email") and user_email:
                query = query.filter(model_cls.user_email == user_email)
                
            row = query.first()
            return self._to_dict(row) if row else None
        finally:
            session.close()

    def set_doc(self, collection: str, doc_id: str, user_email: Optional[str], data: dict) -> None:
        model_cls = _get_model_class(collection)
        if not model_cls:
            return
        session = self._get_session()
        try:
            mapped_data = dict(data)
            
            if collection in ("users", "profiles"):
                import hashlib
                email_val = doc_id
                mapped_data["email"] = email_val
                mapped_data["username"] = email_val[:100]
                
                raw_pass = mapped_data.get("password") or email_val
                if not (isinstance(raw_pass, str) and len(raw_pass) == 64 and all(c in "0123456789abcdef" for c in raw_pass.lower())):
                    mapped_data["password"] = hashlib.sha256(raw_pass.encode()).hexdigest()
                else:
                    mapped_data["password"] = raw_pass
                    
            query = session.query(model_cls)
            if hasattr(model_cls, "id"):
                query = query.filter(model_cls.id == doc_id)
            elif hasattr(model_cls, "code"):
                query = query.filter(model_cls.code == doc_id)
            elif hasattr(model_cls, "email"):
                query = query.filter(model_cls.email == doc_id)
            elif hasattr(model_cls, "logid"):
                query = query.filter(model_cls.logid == doc_id)
                
            if hasattr(model_cls, "user_email") and user_email:
                query = query.filter(model_cls.user_email == user_email)
                
            row = query.first()
            valid_cols = {c.key for c in getattr(model_cls, "__mapper__").column_attrs}
            
            if row:
                if collection == "exams":
                    sec = mapped_data.get("section")
                    if sec is not None:
                        if str(sec).lower() != "all section" and str(sec).strip() != "":
                            subject_id = mapped_data.get("subject_id")
                            if subject_id:
                                sec_row = session.query(SqlSection).filter(
                                    SqlSection.subject == subject_id,
                                    SqlSection.sec == str(sec)
                                ).first()
                                if sec_row:
                                    mapped_data["section_id"] = sec_row.id
                                else:
                                    # Fallback if it's already an ID
                                    try:
                                        mapped_data["section_id"] = int(sec)
                                    except ValueError:
                                        mapped_data["section_id"] = None
                            else:
                                try:
                                    mapped_data["section_id"] = int(sec)
                                except ValueError:
                                    mapped_data["section_id"] = None
                        else:
                            mapped_data["section_id"] = None
                    if "sheetType" in mapped_data:
                        st = str(mapped_data["sheetType"]).replace("-A-E", "")
                        if st == "30":
                            mapped_data["template_id"] = "30-A-E"
                        elif st == "50":
                            mapped_data["template_id"] = "50-A-E"
                        elif st == "100":
                            mapped_data["template_id"] = "100-A-E"
                        else:
                            mapped_data["template_id"] = str(mapped_data["sheetType"])

                for k, v in mapped_data.items():
                    if k in valid_cols:
                        if isinstance(v, str) and (k.endswith("At") or k == "timestamp" or k == "datetime" or k == "created_at"):
                            try:
                                setattr(row, k, datetime.fromisoformat(v.replace("Z", "+00:00")))
                            except ValueError:
                                setattr(row, k, datetime.utcnow())
                        else:
                            setattr(row, k, v)
                            
                if collection == "exams" and "answerKey" in mapped_data:
                    session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == doc_id).delete()
                    if isinstance(mapped_data["answerKey"], dict):
                        for q_str, ans in mapped_data["answerKey"].items():
                            try:
                                q_no = int(q_str)
                                session.add(SqlExamAnswerKey(exam_id=doc_id, question_no=q_no, correct_answer=ans))
                            except ValueError:
                                pass
            else:
                if hasattr(model_cls, "id"):
                    mapped_data["id"] = doc_id
                elif hasattr(model_cls, "code"):
                    mapped_data["code"] = doc_id
                elif hasattr(model_cls, "email"):
                    mapped_data["email"] = doc_id
                elif hasattr(model_cls, "logid"):
                    mapped_data["logid"] = doc_id
                    
                if collection in ("users", "profiles"):
                    mapped_data["user_id"] = doc_id
                    mapped_data["status"] = "active"
                    mapped_data["created_at"] = datetime.utcnow()
                    
                if hasattr(model_cls, "user_email") and user_email:
                    mapped_data["user_email"] = user_email
                    
                if collection == "exams":
                    sec = mapped_data.get("section")
                    if sec is not None:
                        if str(sec).lower() != "all section" and str(sec).strip() != "":
                            subject_id = mapped_data.get("subject_id")
                            if subject_id:
                                sec_row = session.query(SqlSection).filter(
                                    SqlSection.subject == subject_id,
                                    SqlSection.sec == str(sec)
                                ).first()
                                if sec_row:
                                    mapped_data["section_id"] = sec_row.id
                                else:
                                    # Fallback if it's already an ID
                                    try:
                                        mapped_data["section_id"] = int(sec)
                                    except ValueError:
                                        mapped_data["section_id"] = None
                            else:
                                try:
                                    mapped_data["section_id"] = int(sec)
                                except ValueError:
                                    mapped_data["section_id"] = None
                        else:
                            mapped_data["section_id"] = None
                    if "sheetType" in mapped_data:
                        # Frontend sends sheetType as 30, 50, or 100
                        st = str(mapped_data["sheetType"]).replace("-A-E", "")
                        if st == "30":
                            mapped_data["template_id"] = "30-A-E"
                        elif st == "50":
                            mapped_data["template_id"] = "50-A-E"
                        elif st == "100":
                            mapped_data["template_id"] = "100-A-E"
                        else:
                            mapped_data["template_id"] = str(mapped_data["sheetType"])
                        
                cleaned_data = {}
                for k, v in mapped_data.items():
                    if k in valid_cols:
                        if isinstance(v, str) and (k.endswith("At") or k == "timestamp" or k == "datetime" or k == "created_at"):
                            try:
                                cleaned_data[k] = datetime.fromisoformat(v.replace("Z", "+00:00"))
                            except ValueError:
                                cleaned_data[k] = datetime.utcnow()
                        else:
                            cleaned_data[k] = v
                
                row = model_cls(**cleaned_data)
                session.add(row)
                session.flush()
                
                if collection == "exams" and "answerKey" in mapped_data:
                    if isinstance(mapped_data["answerKey"], dict):
                        for q_str, ans in mapped_data["answerKey"].items():
                            try:
                                q_no = int(q_str)
                                session.add(SqlExamAnswerKey(exam_id=doc_id, question_no=q_no, correct_answer=ans))
                            except ValueError:
                                pass
                                
                if collection == "students" and "subjectCode" in mapped_data and "section" in mapped_data:
                    subjectCode = mapped_data["subjectCode"]
                    section_id = mapped_data["section"]
                    sec_row = session.query(SqlSection).filter(SqlSection.id == section_id, SqlSection.user_email == user_email).first()
                    if sec_row:
                        enroll = session.query(SqlStudentEnrollment).filter(SqlStudentEnrollment.student_code == doc_id, SqlStudentEnrollment.subject_id == subjectCode).first()
                        if not enroll:
                            enroll = SqlStudentEnrollment(student_code=doc_id, subject_id=subjectCode, section_id=sec_row.id, user_id=user_email)
                            session.add(enroll)
                        else:
                            enroll.section_id = sec_row.id

            session.commit()
        finally:
            session.close()

    def add_doc(self, collection: str, user_email: Optional[str], data: dict) -> str:
        doc_id = uuid.uuid4().hex
        self.set_doc(collection, doc_id, user_email, data)
        return doc_id

    def update_doc(self, collection: str, doc_id: str, user_email: Optional[str], data: dict) -> None:
        model_cls = _get_model_class(collection)
        if not model_cls:
            return
        session = self._get_session()
        try:
            query = session.query(model_cls)
            if hasattr(model_cls, "id"):
                query = query.filter(model_cls.id == doc_id)
            elif hasattr(model_cls, "code"):
                query = query.filter(model_cls.code == doc_id)
            elif hasattr(model_cls, "email"):
                query = query.filter(model_cls.email == doc_id)
            elif hasattr(model_cls, "logid"):
                query = query.filter(model_cls.logid == doc_id)
                
            if hasattr(model_cls, "user_email") and user_email:
                query = query.filter(model_cls.user_email == user_email)
                
            row = query.first()
            if row:
                mapped_data = dict(data)
                        
                if collection in ("users", "profiles") and "password" in mapped_data:
                    import hashlib
                    raw_pass = mapped_data["password"]
                    if raw_pass and not (isinstance(raw_pass, str) and len(raw_pass) == 64 and all(c in "0123456789abcdef" for c in raw_pass.lower())):
                        mapped_data["password"] = hashlib.sha256(raw_pass.encode()).hexdigest()
                        
                valid_cols = {c.key for c in getattr(model_cls, "__mapper__").column_attrs}
                for k, v in mapped_data.items():
                    if k in valid_cols:
                        if isinstance(v, str) and (k.endswith("At") or k == "timestamp" or k == "datetime" or k == "created_at"):
                            try:
                                setattr(row, k, datetime.fromisoformat(v.replace("Z", "+00:00")))
                            except ValueError:
                                setattr(row, k, datetime.utcnow())
                        else:
                            setattr(row, k, v)
                            
                if collection == "exams" and "answerKey" in mapped_data:
                    session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == doc_id).delete()
                    if isinstance(mapped_data["answerKey"], dict):
                        for q_str, ans in mapped_data["answerKey"].items():
                            try:
                                q_no = int(q_str)
                                session.add(SqlExamAnswerKey(exam_id=doc_id, question_no=q_no, correct_answer=ans))
                            except ValueError:
                                pass
                                
                session.commit()
        finally:
            session.close()

    def delete_doc(self, collection: str, doc_id: str, user_email: Optional[str]) -> None:
        model_cls = _get_model_class(collection)
        if not model_cls:
            return
        session = self._get_session()
        try:
            query = session.query(model_cls)
            if hasattr(model_cls, "id"):
                query = query.filter(model_cls.id == doc_id)
            elif hasattr(model_cls, "code"):
                query = query.filter(model_cls.code == doc_id)
            elif hasattr(model_cls, "email"):
                query = query.filter(model_cls.email == doc_id)
            elif hasattr(model_cls, "logid"):
                query = query.filter(model_cls.logid == doc_id)
                
            if hasattr(model_cls, "user_email") and user_email:
                query = query.filter(model_cls.user_email == user_email)
                
            row = query.first()
            if row:
                session.delete(row)
                session.commit()
        finally:
            session.close()

    def get_collection(self, collection: str, user_email: Optional[str] = None, parent_doc_id: Optional[str] = None) -> List[dict]:
        if collection == "students":
            return self.get_students(user_email)
        if collection == "exams":
            return self.get_exams(user_email)
            
        model_cls = _get_model_class(collection)
        if not model_cls:
            return []
        session = self._get_session()
        try:
            query = session.query(model_cls)
            
            if collection == "sections" and parent_doc_id:
                query = query.filter(model_cls.subject == parent_doc_id)
                
            if hasattr(model_cls, "user_email") and user_email:
                query = query.filter(model_cls.user_email == user_email)
                
            rows = query.all()
            return [self._to_dict(r) for r in rows]
        finally:
            session.close()



# ----------------------------------------------------
# Dependency injection helper
# ----------------------------------------------------
_cached_adapter = None

def get_db_adapter() -> BaseDBAdapter:
    global _cached_adapter
    if _cached_adapter is not None:
        return _cached_adapter

    db_url = os.getenv("DATABASE_URL", "mysql+pymysql://root:@localhost:3306/exam_grading")
    print(f"DATABASE: Using MySQL database adapter connecting to {db_url}")
    _cached_adapter = MySQLAdapter(db_url)
    return _cached_adapter
