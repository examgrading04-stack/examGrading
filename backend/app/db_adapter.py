import os
import json
import uuid
from datetime import datetime, date
from typing import Any, Dict, List, Optional
from abc import ABC, abstractmethod


# SQLAlchemy Imports
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
)
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker

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

class SqlExam(Base):
    __tablename__ = "exams"
    id = Column(String(100), primary_key=True)
    user_email = Column(String(100), primary_key=True)
    name = Column(String(200))
    subject = Column(String(100))
    subjectCode = Column(String(100))
    code = Column(String(100))
    questions = Column(Integer)
    total_questions = Column(Integer)
    answerKey = Column(Text)       # JSON stringified
    answerSheets = Column(Text)    # JSON stringified
    updatedAt = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class SqlStudent(Base):
    __tablename__ = "students"
    id = Column("student_id", String(100), primary_key=True)
    user_email = Column("user_id", String(100), primary_key=True)
    code = Column("student_code", String(100))
    name = Column("student_name", String(200))
    class_name = Column(String(100)) # class is reserved in Python
    section = Column("section_id", String(100))
    subjectCode = Column(String(100))

class SqlSubject(Base):
    __tablename__ = "subjects"
    code = Column("subject_id", String(100), primary_key=True)
    user_email = Column("user_id", String(100), primary_key=True)
    name = Column("subject_name", String(200))

class SqlResult(Base):
    __tablename__ = "results"
    id = Column(String(100), primary_key=True)
    user_email = Column(String(100))
    examId = Column(String(100))
    examName = Column(String(200))
    answerSet = Column(String(50))
    studentCode = Column(String(100))
    studentName = Column(String(200))
    sheetId = Column(String(100))
    score = Column(Float)
    total = Column(Integer)
    percent = Column(Float)
    answers = Column(Text)         # JSON stringified
    flagged = Column(Boolean, default=False)
    wrong = Column(Text)           # JSON stringified
    skipped = Column(Text)         # JSON stringified
    summary = Column(Text)         # JSON stringified
    metadata_json = Column(Text)   # JSON stringified
    imageUrl = Column(String(500))
    createdAt = Column(DateTime, default=datetime.utcnow)
    timestamp = Column(DateTime, default=datetime.utcnow)

class SqlUser(Base):
    __tablename__ = "users"
    user_id = Column(String(10), primary_key=True)
    username = Column(String(50), unique=True)
    password = Column(String(255))
    email = Column(String(100), unique=True)
    status = Column(String(10), default="active")
    created_at = Column(DateTime, default=datetime.utcnow)
    displayName = Column(String(200))
    photoURL = Column(String(500))

class SqlSection(Base):
    __tablename__ = "sections"
    id = Column("section_id", String(100), primary_key=True)
    user_email = Column("user_id", String(100), primary_key=True)
    subject = Column("subject_id", String(100))
    sec = Column("section_number", String(100))
    created_at = Column(String(100))

class SqlSystemLog(Base):
    __tablename__ = "system_logs"
    logid = Column("log_id", String(100), primary_key=True)
    activity = Column("action", Text)
    datetime = Column("action_time", DateTime, default=datetime.utcnow)
    user = Column("user_id", String(100))
    userEmail = Column(String(100))
    displayName = Column(String(200))
    role = Column(String(100))
    metadata_json = Column(Text)

class SqlAdmin(Base):
    __tablename__ = "admins"
    id = Column("admin_id", String(100), primary_key=True)
    aname = Column("admin_username", String(100))
    apassword = Column("admin_password", String(100))

class SqlAnswer(Base):
    __tablename__ = "answer"
    answer_id       = Column(String(10), primary_key=True)
    answer_name     = Column("answer _name", String(100))  # column name has a space
    total_questions = Column(Integer)
    total_score     = Column(Float)

class SqlAnswerDetail(Base):
    __tablename__ = "answer_detail"
    answer_detail_id = Column(String(10), primary_key=True)
    question_no      = Column(Integer)
    correct_answer   = Column(String(10))
    weight           = Column(Float)
    answer_id        = Column(String(10))

class SqlExamResult(Base):
    __tablename__ = "exam_result"
    exam_result_id = Column(String(10), primary_key=True)
    score          = Column(Float)
    max_score      = Column(Float)
    exam_date      = Column(Date)
    student_id     = Column(String(10))
    answer_id      = Column(String(10))
    user_id        = Column(String(10))

class SqlExamDetail(Base):
    __tablename__ = "exam_detail"
    exam_detail_id = Column(String(10), primary_key=True)
    answer_status  = Column(Integer)
    student_answer = Column(String(10))
    correct_answer = Column(String(10))
    score_per_item = Column(Float)
    exam_result_id = Column(String(10))

class SqlExamAnalysis(Base):
    __tablename__ = "exam_analysis"
    exam_analysis_id     = Column(String(10), primary_key=True)
    difficult_index      = Column(Float)
    discrimination_index = Column(Float)
    total_student        = Column(Integer)
    total_blank          = Column(Integer)
    total_correct        = Column(Integer)
    total_wrong          = Column(Integer)
    exam_detail_id       = Column(String(10))

class SqlResultAnalysis(Base):
    __tablename__ = "result_analysis"
    analysis_id = Column(String(10), primary_key=True)
    mean        = Column(Float)
    max_score   = Column(Float)
    min_score   = Column(Float)
    median      = Column(Float)
    std_dev     = Column(Float)
    mode        = Column(Float)
    subject_id  = Column(String(10))
    section_id  = Column(String(10))

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
        "admins":          SqlAdmin,
        "answer":          SqlAnswer,
        "answer_detail":   SqlAnswerDetail,
        "exam_result":     SqlExamResult,
        "exam_detail":     SqlExamDetail,
        "exam_analysis":   SqlExamAnalysis,
        "result_analysis": SqlResultAnalysis,
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
        d = {c.key: getattr(model_obj, c.key) for c in model_obj.__table__.columns}
        
        # Handle field mappings and JSON parsing
        if "class_name" in d:
            d["class"] = d.pop("class_name")
        if "metadata_json" in d:
            d["metadata"] = json.loads(d.pop("metadata_json") or "{}")
        
        # Convert datetime objects to string format
        for k, v in list(d.items()):
            if isinstance(v, datetime):
                d[k] = v.isoformat()
        
        # JSON decodes
        for json_col in ["answerKey", "answerSheets", "answers", "wrong", "skipped", "summary"]:
            if json_col in d and d[json_col]:
                try:
                    d[json_col] = json.loads(d[json_col])
                except Exception:
                    pass
        return d


    def get_exam(self, user_email: str, exam_id: str) -> dict[str, Any]:
        from fastapi import HTTPException
        session = self._get_session()
        try:
            row = session.query(SqlExam).filter(
                SqlExam.user_email == user_email,
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
            row = session.query(SqlExam).filter(
                SqlExam.user_email == user_email,
                SqlExam.id == exam_id
            ).first()
            
            # Serialize JSON columns
            serialized_data = {}
            for k, v in data.items():
                if k in ["answerKey", "answerSheets"] and isinstance(v, (dict, list)):
                    serialized_data[k] = json.dumps(v)
                else:
                    serialized_data[k] = v

            if row:
                for k, v in serialized_data.items():
                    setattr(row, k, v)
            else:
                row = SqlExam(id=exam_id, user_email=user_email, **serialized_data)
                session.add(row)
            session.commit()
        finally:
            session.close()

    def get_exams(self, user_email: str) -> List[dict[str, Any]]:
        session = self._get_session()
        try:
            rows = session.query(SqlExam).filter(SqlExam.user_email == user_email).all()
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
            return [self._to_dict(r) for r in rows]
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
            # Flatten or format some fields (replace firestore placeholders)
            data = dict(payload)
            data["user_email"] = user_email
            data["id"] = uuid.uuid4().hex

            # Serialize dict/list fields to JSON string
            for key in ["answers", "wrong", "skipped", "summary"]:
                if key in data and isinstance(data[key], (dict, list)):
                    data[key] = json.dumps(data[key])
            
            if "metadata" in data:
                data["metadata_json"] = json.dumps(data.pop("metadata"))

            # Clean placeholder firestore timestamps
            for ts_key in ["createdAt", "timestamp"]:
                if ts_key in data:
                    # If it's a firebase placeholder or not a datetime, set to current time
                    if not isinstance(data[ts_key], datetime):
                        data[ts_key] = datetime.utcnow()

            row = SqlResult(**data)
            session.add(row)
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
            mapped_data = {}
            for k, v in data.items():
                if k == "class":
                    mapped_data["class_name"] = v
                elif k == "metadata" and collection == "results":
                    mapped_data["metadata_json"] = json.dumps(v)
                elif k in ["answerKey", "answerSheets", "answers", "wrong", "skipped", "summary"] and isinstance(v, (dict, list)):
                    mapped_data[k] = json.dumps(v)
                else:
                    mapped_data[k] = v
                    
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
                    
            if collection == "admins":
                import hashlib
                raw_pass = mapped_data.get("apassword")
                if raw_pass and not (isinstance(raw_pass, str) and len(raw_pass) == 64 and all(c in "0123456789abcdef" for c in raw_pass.lower())):
                    mapped_data["apassword"] = hashlib.sha256(raw_pass.encode()).hexdigest()
                    
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
                for k, v in mapped_data.items():
                    if hasattr(row, k):
                        setattr(row, k, v)
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
                    mapped_data["user_id"] = str(uuid.uuid4().int)[:10]
                    mapped_data["status"] = "active"
                    mapped_data["created_at"] = datetime.utcnow()
                    
                if hasattr(model_cls, "user_email") and user_email:
                    mapped_data["user_email"] = user_email
                    
                valid_cols = {c.name for c in model_cls.__table__.columns}
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
                mapped_data = {}
                for k, v in data.items():
                    if k == "class":
                        mapped_data["class_name"] = v
                    elif k == "metadata" and collection == "results":
                        mapped_data["metadata_json"] = json.dumps(v)
                    elif k in ["answerKey", "answerSheets", "answers", "wrong", "skipped", "summary"] and isinstance(v, (dict, list)):
                        mapped_data[k] = json.dumps(v)
                    else:
                        mapped_data[k] = v
                        
                if collection in ("users", "profiles") and "password" in mapped_data:
                    import hashlib
                    raw_pass = mapped_data["password"]
                    if raw_pass and not (isinstance(raw_pass, str) and len(raw_pass) == 64 and all(c in "0123456789abcdef" for c in raw_pass.lower())):
                        mapped_data["password"] = hashlib.sha256(raw_pass.encode()).hexdigest()
                        
                if collection == "admins" and "apassword" in mapped_data:
                    import hashlib
                    raw_pass = mapped_data["apassword"]
                    if raw_pass and not (isinstance(raw_pass, str) and len(raw_pass) == 64 and all(c in "0123456789abcdef" for c in raw_pass.lower())):
                        mapped_data["apassword"] = hashlib.sha256(raw_pass.encode()).hexdigest()
                        
                for k, v in mapped_data.items():
                    if hasattr(row, k):
                        if isinstance(v, str) and (k.endswith("At") or k == "timestamp" or k == "datetime" or k == "created_at"):
                            try:
                                setattr(row, k, datetime.fromisoformat(v.replace("Z", "+00:00")))
                            except ValueError:
                                setattr(row, k, datetime.utcnow())
                        else:
                            setattr(row, k, v)
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
