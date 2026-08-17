import os
import json
import uuid
from datetime import datetime
from typing import Any, List, Optional
from abc import ABC, abstractmethod
from pathlib import Path

try:
    # pyrefly: ignore [missing-import]
    from dotenv import load_dotenv  
    load_dotenv()
    load_dotenv(Path(__file__).parent.parent / ".env")
except ImportError:
    pass


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
    ForeignKey,
    ForeignKeyConstraint,
)
# pyrefly: ignore [missing-import]
from sqlalchemy.orm import declarative_base, sessionmaker

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
    status = Column("status", String(20), default="active")
    created_at = Column("created_at", DateTime, default=datetime.now)

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
    datetime = Column("action_time", DateTime, default=datetime.now)
    userEmail = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True) # Note: old frontend used userEmail, now maps to user_id

class SqlSubject(Base):
    __tablename__ = "subjects"
    code = Column("subject_id", String(50), primary_key=True)
    name = Column("subject_name", String(200), nullable=False)
    term = Column("semester", Integer, nullable=True)
    year = Column("year", Integer, nullable=True)
    teacher = Column("instructor", String(200), nullable=True)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

class SqlStudent(Base):
    __tablename__ = "students"
    id = Column("student_code", String(50), primary_key=True)
    name = Column("student_name", String(200), nullable=False)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

class SqlSection(Base):
    __tablename__ = "subjects_sec"
    id = Column("section_id", String(50), primary_key=True)
    sec = Column("section_name", String(50), nullable=False)
    created_at = Column("created_at", DateTime, default=datetime.now)
    subject = Column("subject_id", String(50), nullable=False)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['subject_id', 'user_id'],
            ['subjects.subject_id', 'subjects.user_id'],
            ondelete="CASCADE"
        ),
    )

class SqlStudentEnrollment(Base):
    __tablename__ = "student_enrollments"
    enrollment_id = Column("enrollment_id", Integer, primary_key=True, autoincrement=True)
    student_code = Column("student_code", String(50), nullable=False)
    subject_id = Column("subject_id", String(50), nullable=False)
    section_id = Column("section_id", String(50), nullable=False)
    user_id = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['student_code', 'user_id'],
            ['students.student_code', 'students.user_id'],
            ondelete="CASCADE"
        ),
        ForeignKeyConstraint(
            ['subject_id', 'user_id'],
            ['subjects.subject_id', 'subjects.user_id'],
            ondelete="CASCADE"
        ),
        ForeignKeyConstraint(
            ['section_id', 'user_id'],
            ['subjects_sec.section_id', 'subjects_sec.user_id'],
            ondelete="CASCADE"
        ),
    )

class SqlExam(Base):
    __tablename__ = "exams"
    id = Column("exam_id", String(100), primary_key=True)
    name = Column("exam_name", String(200), nullable=False)
    questions = Column("questions", Integer, nullable=False)
    createdAt = Column("created_at", DateTime, default=datetime.now)
    subject_id = Column("subject_id", String(50), nullable=False)
    section_id = Column("section_id", String(50), nullable=True)
    template_id = Column("template_id", String(50), ForeignKey("templates.template_id", ondelete="SET NULL"), nullable=True)
    isCustomScore = Column("is_custom_score", Boolean, default=False)
    defaultScore = Column("default_score", Float, default=1.0)
    exam_date = Column("exam_date", String(50), nullable=True)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['subject_id', 'user_id'],
            ['subjects.subject_id', 'subjects.user_id'],
            ondelete="CASCADE"
        ),
        ForeignKeyConstraint(
            ['section_id', 'user_id'],
            ['subjects_sec.section_id', 'subjects_sec.user_id'],
            ondelete="CASCADE"
        ),
    )

class SqlExamAnswerKey(Base):
    __tablename__ = "exam_answer_keys"
    answer_key_id = Column("answer_key_id", Integer, primary_key=True, autoincrement=True)
    question_no = Column("question_no", Integer, nullable=False)
    correct_answer = Column("correct_answer", String(1), nullable=False)
    score = Column("score", Float, nullable=False, default=1.0)
    exam_id = Column("exam_id", String(100), nullable=False)
    user_id = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['exam_id', 'user_id'],
            ['exams.exam_id', 'exams.user_id'],
            ondelete="CASCADE"
        ),
    )

class SqlResult(Base):
    __tablename__ = "results"
    id = Column("result_id", String(100), primary_key=True)
    score = Column("score", Float, nullable=False)
    total = Column("total", Integer, nullable=False)
    percent = Column("percent", Float, nullable=False)
    flagged = Column("flagged", Boolean, default=False)
    imageUrl = Column("imageURL", String(500))
    createdAt = Column("created_at", DateTime, default=datetime.now)
    examId = Column("exam_id", String(100), nullable=False)
    studentCode = Column("student_code", String(50), nullable=False)
    sheetId = Column("template_id", String(50), ForeignKey("templates.template_id", ondelete="SET NULL"), nullable=True)
    user_email = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['student_code', 'user_id'],
            ['students.student_code', 'students.user_id'],
            ondelete="CASCADE"
        ),
        ForeignKeyConstraint(
            ['exam_id', 'user_id'],
            ['exams.exam_id', 'exams.user_id'],
            ondelete="CASCADE"
        ),
    )

class SqlExamDetail(Base):
    __tablename__ = "exams_detail"
    exam_detail_id = Column("exam_detail_id", Integer, primary_key=True, autoincrement=True)
    question_no = Column("question_no", Integer, nullable=False)
    student_answer = Column("student_answer", String(1))
    status_answer = Column("status_answer", String(20))
    result_id = Column("result_id", String(100), nullable=False)
    user_id = Column("user_id", String(100), ForeignKey("users.user_id", ondelete="CASCADE"), primary_key=True)

    __table_args__ = (
        ForeignKeyConstraint(
            ['result_id', 'user_id'],
            ['results.result_id', 'results.user_id'],
            ondelete="CASCADE"
        ),
    )

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
        self.engine = create_engine(
            db_url,
            pool_size=10,
            max_overflow=20,
            pool_timeout=30,
            pool_recycle=1800,
            pool_pre_ping=True,
        )
        Base.metadata.create_all(self.engine)
        self._auto_migrate()
        self.SessionLocal = sessionmaker(bind=self.engine)

    def _auto_migrate(self):
        """เพิ่มคอลัมน์ใหม่ใน DB อัตโนมัติกรณีที่ตารางเดิมบนเซิร์ฟเวอร์ยังไม่มีคอลัมน์นั้น"""
        # pyrefly: ignore [missing-import]
        from sqlalchemy import text
        try:
            with self.engine.connect() as conn:
                for sql in [
                    "ALTER TABLE exams ADD COLUMN is_custom_score TINYINT(1) DEFAULT 0",
                    "ALTER TABLE exams ADD COLUMN default_score FLOAT DEFAULT 1.0",
                    "ALTER TABLE exams ADD COLUMN exam_date VARCHAR(50) NULL",
                    "ALTER TABLE exams MODIFY COLUMN template_id VARCHAR(50) NULL",
                    "ALTER TABLE results MODIFY COLUMN template_id VARCHAR(50) NULL",
                    "ALTER TABLE student_enrollments DROP FOREIGN KEY student_enrollments_ibfk_2",
                    "ALTER TABLE subjects_sec MODIFY COLUMN section_id VARCHAR(50)",
                    "ALTER TABLE student_enrollments MODIFY COLUMN section_id VARCHAR(50)",
                    "ALTER TABLE student_enrollments ADD CONSTRAINT student_enrollments_ibfk_2 FOREIGN KEY (section_id, user_id) REFERENCES subjects_sec (section_id, user_id) ON DELETE CASCADE",
                ]:
                    try:
                        conn.execute(text(sql))
                        conn.commit()
                    except Exception:
                        pass
        except Exception as e:
            print(f"Auto-migration note: {e}")

    def _get_session(self):
        return self.SessionLocal()

    def _to_dict(self, model_obj, session=None) -> dict[str, Any]:
        if not model_obj:
            return {}
        d = {c.key: getattr(model_obj, c.key) for c in getattr(model_obj, "__mapper__").column_attrs}
        
        own_session = False
        if session is None:
            session = self._get_session()
            own_session = True

        try:
            # Dynamically fetch relationships that were previously JSON strings
            if isinstance(model_obj, SqlResult):
                details = session.query(SqlExamDetail).filter(SqlExamDetail.result_id == model_obj.id, SqlExamDetail.user_id == model_obj.user_email).order_by(SqlExamDetail.question_no).all()
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
                
                # Fetch student name
                student = session.query(SqlStudent).filter(SqlStudent.id == model_obj.studentCode).first()
                if student:
                    d["studentName"] = student.name

            if isinstance(model_obj, SqlExam):
                keys = session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == model_obj.id, SqlExamAnswerKey.user_id == model_obj.user_email).order_by(SqlExamAnswerKey.question_no).all()
                answer_key_dict = {}
                is_custom = getattr(model_obj, "isCustomScore", False)
                for key in keys:
                    if is_custom:
                        answer_key_dict[str(key.question_no)] = {"answer": key.correct_answer, "score": key.score}
                    else:
                        answer_key_dict[str(key.question_no)] = key.correct_answer
                d["answerKey"] = answer_key_dict
                
                # Map back to frontend keys
                d["section"] = d.pop("section_id", None) or "All Section"
                d["sheetType"] = d.pop("template_id", None)
                d["subject"] = d.get("subject_id")
                d["examDate"] = d.get("exam_date") or ""
        finally:
            if own_session:
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
            d = self._to_dict(row)
            d["subject"] = row.subject_id
            d["subjectCode"] = row.subject_id
            subj = session.query(SqlSubject).filter(SqlSubject.code == row.subject_id).first()
            if subj:
                d["subjectName"] = subj.name
                d["subject_name"] = subj.name
            return d
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
                session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == exam_id, SqlExamAnswerKey.user_id == user_email).delete()
                for q_str, ans in answer_key.items():
                    try:
                        q_no = int(q_str)
                        if isinstance(ans, dict):
                            c_ans = str(ans.get("answer", ""))
                            q_score = float(ans.get("score", 1.0))
                        else:
                            c_ans = str(ans)
                            q_score = 1.0
                        session.add(SqlExamAnswerKey(exam_id=exam_id, user_id=user_email, question_no=q_no, correct_answer=c_ans, score=q_score))
                    except ValueError:
                        pass

            session.commit()
        finally:
            session.close()

    def get_exams(self, user_email: str) -> List[dict]:
        session = self._get_session()
        try:
            try:
                # LEFT OUTER JOIN — exam ที่ไม่มี subject ยังคงแสดงอยู่
                rows = session.query(SqlExam).outerjoin(
                    SqlSubject,
                    (SqlExam.subject_id == SqlSubject.code) & (SqlExam.user_email == SqlSubject.user_email)
                ).filter(SqlExam.user_email == user_email).all()
            except Exception as ex:
                if "1054" in str(ex) or "unknown column" in str(ex).lower():
                    session.close()
                    self._auto_migrate()
                    session = self._get_session()
                    rows = session.query(SqlExam).outerjoin(
                        SqlSubject,
                        (SqlExam.subject_id == SqlSubject.code) & (SqlExam.user_email == SqlSubject.user_email)
                    ).filter(SqlExam.user_email == user_email).all()
                else:
                    raise

            # Batch-load subjects เพื่อลด N+1
            subject_ids = list({r.subject_id for r in rows if r.subject_id})
            subject_map = {}
            if subject_ids:
                subjects = session.query(SqlSubject).filter(
                    SqlSubject.code.in_(subject_ids),
                    SqlSubject.user_email == user_email,
                ).all()
                subject_map = {s.code: s for s in subjects}

            res = []
            for r in rows:
                try:
                    d = self._to_dict(r, session=session)
                    d["subject"] = r.subject_id
                    d["subjectCode"] = r.subject_id
                    subj = subject_map.get(r.subject_id or "")
                    if subj:
                        d["subjectName"] = subj.name
                        d["subject_name"] = subj.name
                    res.append(d)
                except Exception as e:
                    print(f"Warning: skipping exam {getattr(r, 'id', '?')} due to error: {e}")
                    continue
            return res
        finally:
            session.close()

    def get_students(self, user_email: str, student_ids: Optional[List[str]] = None) -> List[dict[str, Any]]:
        session = self._get_session()
        try:
            query = session.query(SqlStudent).filter(SqlStudent.user_email == user_email)
            if student_ids:
                query = query.filter(SqlStudent.id.in_(student_ids))
            students = query.all()
            if not students:
                return []
            
            student_codes = [s.id for s in students]
            
            # Batch fetch all enrollments in 1 query
            enrollments = session.query(SqlStudentEnrollment).filter(
                SqlStudentEnrollment.student_code.in_(student_codes),
                SqlStudentEnrollment.user_id == user_email
            ).all()
            
            enroll_map = {}
            section_ids = set()
            for en in enrollments:
                enroll_map.setdefault(en.student_code, []).append(en)
                if en.section_id:
                    section_ids.add(en.section_id)
            
            # Batch fetch all sections in 1 query
            section_map = {}
            if section_ids:
                sections = session.query(SqlSection).filter(SqlSection.id.in_(section_ids)).all()
                section_map = {sec.id: sec.id for sec in sections}
            
            res = []
            for st in students:
                d = self._to_dict(st, session=session)
                st_enrolls = enroll_map.get(st.id, [])
                if not st_enrolls:
                    res.append(d)
                else:
                    for en in st_enrolls:
                        d_copy = d.copy()
                        d_copy["subjectCode"] = en.subject_id
                        if en.section_id in section_map:
                            d_copy["section"] = section_map[en.section_id]
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

    def get_admin_by_name(self, aname: str) -> Optional[dict]:
        """Query admin user by username or email directly — ไม่ต้องโหลดทั้ง table"""
        session = self._get_session()
        try:
            # pyrefly: ignore [missing-import]
            from sqlalchemy import or_
            row = session.query(SqlUser).filter(
                SqlUser.role == "admin",
                or_(SqlUser.username == aname, SqlUser.email == aname)
            ).first()
            return self._to_dict(row) if row else None
        finally:
            session.close()

    def save_result(self, user_email: str, payload: dict[str, Any]) -> str:
        session = self._get_session()
        try:
            data = dict(payload)
            overwrite = data.pop("overwrite", False)
            data["user_email"] = user_email
            
            exam_id = data.get("examId")
            student_code = data.get("studentCode")
            
            if not student_code:
                student_code = "UNKNOWN"
                data["studentCode"] = student_code
                
            # Ensure student exists in DB to satisfy foreign key constraint
            st = session.query(SqlStudent).filter_by(id=student_code, user_email=user_email).first()
            if not st:
                st_name = "ไม่ทราบชื่อ (Unknown)" if student_code == "UNKNOWN" else f"นักเรียน {student_code}"
                new_st = SqlStudent(id=student_code, name=st_name, user_email=user_email)
                session.add(new_st)
                session.flush()

            if exam_id and student_code:
                existing = session.query(SqlResult).filter_by(examId=exam_id, studentCode=student_code).first()
                if existing:
                    if not overwrite:
                        raise ValueError(f"duplicate_result:{student_code}")
                    else:
                        session.query(SqlExamDetail).filter_by(result_id=existing.id, user_id=user_email).delete()
                        session.delete(existing)
                        session.flush()

            data["id"] = uuid.uuid4().hex

            answers = data.pop("answers", {})
            wrong = data.pop("wrong", [])
            skipped = data.pop("skipped", [])
            
            # Clean placeholder firestore timestamps
            for ts_key in ["createdAt", "timestamp"]:
                if ts_key in data:
                    if not isinstance(data[ts_key], datetime):
                        data[ts_key] = datetime.now()

            # Normalize imageUrl field variations
            img_val = data.get("imageUrl") or data.get("image_url") or data.get("imageURL")
            if img_val:
                data["imageUrl"] = img_val
            
            # Remove any keys that are not in SqlResult columns
            allowed_keys = {c.key for c in SqlResult.__mapper__.column_attrs}
            sql_data = {k: v for k, v in data.items() if k in allowed_keys}
            
            if "flagged" in sql_data:
                sql_data["flagged"] = bool(sql_data["flagged"])

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
                        result_id=row.id,
                        user_id=user_email
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
                row = query.filter(model_cls.user_email == user_email).first()
                if not row:
                    row = query.first()
            else:
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
                email_val = doc_id
                if "email" not in mapped_data:
                    mapped_data["email"] = email_val
                if "username" not in mapped_data:
                    mapped_data["username"] = email_val[:100]
                
                # Only process password if it's explicitly provided
                if "password" in mapped_data:
                    import hashlib
                    raw_pass = mapped_data["password"]
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
                row = query.filter(model_cls.user_email == user_email).first()
                if not row:
                    row = query.first()
            else:
                row = query.first()
            valid_cols = {c.key for c in getattr(model_cls, "__mapper__").column_attrs}
            
            if row:
                if collection == "exams":
                    if "subject" in mapped_data and "subject_id" not in mapped_data:
                        mapped_data["subject_id"] = mapped_data["subject"]
                    if "name" in mapped_data and "exam_name" not in mapped_data:
                        mapped_data["exam_name"] = mapped_data["name"]
                    if "examDate" in mapped_data:
                        mapped_data["exam_date"] = mapped_data["examDate"]
                        
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
                                        mapped_data["section_id"] = str(sec)
                                    except ValueError:
                                        mapped_data["section_id"] = None
                            else:
                                try:
                                    mapped_data["section_id"] = str(sec)
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

                if collection == "results":
                    student_code = mapped_data.get("studentCode") or mapped_data.get("student_code")
                    if student_code == "":
                        student_code = "UNKNOWN"
                        mapped_data["studentCode"] = student_code
                        mapped_data["student_code"] = student_code
                    
                    if student_code:
                        st = session.query(SqlStudent).filter_by(id=student_code, user_email=user_email).first()
                        if not st:
                            st_name = "ไม่ทราบชื่อ (Unknown)" if student_code == "UNKNOWN" else f"นักเรียน {student_code}"
                            new_st = SqlStudent(id=student_code, name=st_name, user_email=user_email)
                            session.add(new_st)
                            session.flush()

                for k, v in mapped_data.items():
                    if k in valid_cols:
                        if isinstance(v, str) and (k.endswith("At") or k == "timestamp" or k == "datetime" or k == "created_at"):
                            try:
                                dt = datetime.fromisoformat(v.replace("Z", "+00:00"))
                                if dt.tzinfo:
                                    dt = dt.astimezone().replace(tzinfo=None)
                                setattr(row, k, dt)
                            except ValueError:
                                setattr(row, k, datetime.now())
                        else:
                            if k in ("user_email", "user_id", "userEmail") and v == "":
                                setattr(row, k, None)
                            else:
                                setattr(row, k, v)
                            
                if collection == "exams" and "answerKey" in mapped_data:
                    session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == doc_id, SqlExamAnswerKey.user_id == user_email).delete()
                    if isinstance(mapped_data["answerKey"], dict):
                        for q_str, ans in mapped_data["answerKey"].items():
                            try:
                                q_no = int(q_str)
                                session.add(SqlExamAnswerKey(exam_id=doc_id, user_id=user_email, question_no=q_no, correct_answer=ans))
                            except ValueError:
                                pass
            else:
                if hasattr(model_cls, "id"):
                    mapped_data["id"] = str(doc_id)
                elif hasattr(model_cls, "code"):
                    mapped_data["code"] = doc_id
                elif hasattr(model_cls, "email"):
                    mapped_data["email"] = doc_id
                elif hasattr(model_cls, "logid"):
                    mapped_data["logid"] = doc_id
                    
                if collection in ("users", "profiles"):
                    mapped_data["user_id"] = doc_id
                    mapped_data["status"] = "active"
                    mapped_data["created_at"] = datetime.now()
                    
                if hasattr(model_cls, "user_email") and user_email:
                    mapped_data["user_email"] = user_email
                    
                if collection == "exams":
                    if "subject" in mapped_data and "subject_id" not in mapped_data:
                        mapped_data["subject_id"] = mapped_data["subject"]
                    if "name" in mapped_data and "exam_name" not in mapped_data:
                        mapped_data["exam_name"] = mapped_data["name"]
                    if "examDate" in mapped_data:
                        mapped_data["exam_date"] = mapped_data["examDate"]
                        
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
                                        mapped_data["section_id"] = str(sec)
                                    except ValueError:
                                        mapped_data["section_id"] = None
                            else:
                                try:
                                    mapped_data["section_id"] = str(sec)
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
                        
                if collection in ("sections", "exams"):
                    subject_id = mapped_data.get("subject") or mapped_data.get("subject_id")
                    if subject_id and user_email:
                        subj = session.query(SqlSubject).filter(
                            SqlSubject.code == subject_id,
                            SqlSubject.user_email == user_email
                        ).first()
                        if not subj:
                            new_subj = SqlSubject(
                                code=subject_id,
                                name=f"วิชา {subject_id}",
                                user_email=user_email
                            )
                            session.add(new_subj)
                            session.flush()

                if collection == "results":
                    student_code = mapped_data.get("studentCode") or mapped_data.get("student_code")
                    if not student_code:
                        student_code = "UNKNOWN"
                        mapped_data["studentCode"] = student_code
                        mapped_data["student_code"] = student_code
                    
                    st = session.query(SqlStudent).filter_by(id=student_code, user_email=user_email).first()
                    if not st:
                        st_name = "ไม่ทราบชื่อ (Unknown)" if student_code == "UNKNOWN" else f"นักเรียน {student_code}"
                        new_st = SqlStudent(id=student_code, name=st_name, user_email=user_email)
                        session.add(new_st)
                        session.flush()

                cleaned_data = {}
                for k, v in mapped_data.items():
                    if k in valid_cols:
                        if isinstance(v, str) and (k.endswith("At") or k == "timestamp" or k == "datetime" or k == "created_at"):
                            try:
                                dt = datetime.fromisoformat(v.replace("Z", "+00:00"))
                                if dt.tzinfo:
                                    dt = dt.astimezone().replace(tzinfo=None)
                                cleaned_data[k] = dt
                            except ValueError:
                                cleaned_data[k] = datetime.now()
                        else:
                            if k == "flagged" and isinstance(v, list):
                                cleaned_data[k] = bool(v)
                            elif k in ("user_email", "user_id", "userEmail") and v == "":
                                cleaned_data[k] = None
                            else:
                                cleaned_data[k] = v
                
                row = model_cls(**cleaned_data)
                session.add(row)
                session.flush()
                
                if collection == "exams" and "answerKey" in mapped_data:
                    raw_ak = mapped_data["answerKey"]
                    if isinstance(raw_ak, dict):
                        if "0" in raw_ak and isinstance(raw_ak["0"], dict):
                            raw_ak = raw_ak["0"]
                        elif 0 in raw_ak and isinstance(raw_ak[0], dict):
                            raw_ak = raw_ak[0]
                        for q_str, ans in raw_ak.items():
                            try:
                                q_no = int(q_str)
                                if isinstance(ans, dict):
                                    c_ans = str(ans.get("answer", ""))
                                    q_score = float(ans.get("score", 1.0))
                                else:
                                    c_ans = str(ans)
                                    q_score = 1.0
                                session.add(SqlExamAnswerKey(exam_id=doc_id, user_id=user_email, question_no=q_no, correct_answer=c_ans, score=q_score))
                            except ValueError:
                                pass
                                


            if collection == "students" and "section" in mapped_data:
                subjectCode = mapped_data.get("subjectCode")
                section_id = mapped_data.get("section")
                if section_id:
                    sec_row = session.query(SqlSection).filter(
                        (SqlSection.id == section_id) | ((SqlSection.sec == str(section_id)) & (SqlSection.subject == subjectCode)),
                        SqlSection.user_email == user_email
                    ).first()
                    if sec_row:
                        subj_id = subjectCode if (subjectCode and str(subjectCode).strip()) else sec_row.subject
                        enroll = session.query(SqlStudentEnrollment).filter(
                            SqlStudentEnrollment.student_code == doc_id,
                            SqlStudentEnrollment.subject_id == subj_id
                        ).first()
                        if not enroll:
                            enroll = SqlStudentEnrollment(
                                student_code=doc_id,
                                subject_id=subj_id,
                                section_id=sec_row.id,
                                user_id=user_email
                            )
                            session.add(enroll)
                        else:
                            enroll.section_id = sec_row.id

            try:
                session.commit()
            except Exception as e:
                session.rollback()
                if "Duplicate entry" in str(e) or "IntegrityError" in str(type(e)):
                    # pyrefly: ignore [missing-import]
                    from fastapi import HTTPException
                    item_name = "รหัสวิชา" if collection == "subjects" else "รหัส"
                    raise HTTPException(status_code=400, detail=f"{item_name}นี้มีอยู่ในระบบแล้ว (อาจถูกสร้างโดยผู้ใช้งานอื่น) กรุณาใช้รหัสอื่น")
                raise
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
                row = query.filter(model_cls.user_email == user_email).first()
                if not row:
                    row = query.first()
            else:
                row = query.first()
            if row:
                mapped_data = dict(data)
                        
                if collection in ("users", "profiles") and "password" in mapped_data:
                    import hashlib
                    raw_pass = mapped_data["password"]
                    if raw_pass and not (isinstance(raw_pass, str) and len(raw_pass) == 64 and all(c in "0123456789abcdef" for c in raw_pass.lower())):
                        mapped_data["password"] = hashlib.sha256(raw_pass.encode()).hexdigest()

                if collection == "exams":
                    if "subject" in mapped_data and "subject_id" not in mapped_data:
                        mapped_data["subject_id"] = mapped_data["subject"]
                    if "name" in mapped_data and "exam_name" not in mapped_data:
                        mapped_data["exam_name"] = mapped_data["name"]
                        
                    sec = mapped_data.get("section")
                    if sec is not None:
                        if str(sec).lower() != "all section" and str(sec).strip() != "":
                            subject_id = mapped_data.get("subject_id") or getattr(row, "subject_id", None)
                            if subject_id:
                                sec_row = session.query(SqlSection).filter(
                                    SqlSection.subject == subject_id,
                                    SqlSection.sec == str(sec)
                                ).first()
                                if sec_row:
                                    mapped_data["section_id"] = sec_row.id
                                else:
                                    try:
                                        mapped_data["section_id"] = str(sec)
                                    except ValueError:
                                        mapped_data["section_id"] = None
                            else:
                                try:
                                    mapped_data["section_id"] = str(sec)
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
                        
                valid_cols = {c.key for c in getattr(model_cls, "__mapper__").column_attrs}
                for k, v in mapped_data.items():
                    if k in valid_cols:
                        if isinstance(v, str) and (k.endswith("At") or k == "timestamp" or k == "datetime" or k == "created_at"):
                            try:
                                dt = datetime.fromisoformat(v.replace("Z", "+00:00"))
                                if dt.tzinfo:
                                    dt = dt.astimezone().replace(tzinfo=None)
                                setattr(row, k, dt)
                            except ValueError:
                                setattr(row, k, datetime.now())
                        else:
                            setattr(row, k, v)
                            
                if collection == "exams" and "answerKey" in mapped_data:
                    raw_ak = mapped_data["answerKey"]
                    # If frontend sends empty answerKey during an exam detail update, do not delete existing answers!
                    if isinstance(raw_ak, dict) and len(raw_ak) > 0:
                        session.query(SqlExamAnswerKey).filter(SqlExamAnswerKey.exam_id == doc_id, SqlExamAnswerKey.user_id == user_email).delete()
                        if "0" in raw_ak and isinstance(raw_ak["0"], dict):
                            raw_ak = raw_ak["0"]
                        elif 0 in raw_ak and isinstance(raw_ak[0], dict):
                            raw_ak = raw_ak[0]
                        for q_str, ans in raw_ak.items():
                            try:
                                q_no = int(q_str)
                                if isinstance(ans, dict):
                                    c_ans = str(ans.get("answer", ""))
                                    q_score = float(ans.get("score", 1.0))
                                else:
                                    c_ans = str(ans)
                                    q_score = 1.0
                                session.add(SqlExamAnswerKey(exam_id=doc_id, user_id=user_email, question_no=q_no, correct_answer=c_ans, score=q_score))
                            except ValueError:
                                pass
                                
                if collection == "students" and "section" in mapped_data:
                    subjectCode = mapped_data.get("subjectCode")
                    section_id = mapped_data.get("section")
                    if section_id:
                        sec_row = session.query(SqlSection).filter(
                            (SqlSection.id == section_id) | ((SqlSection.sec == str(section_id)) & (SqlSection.subject == subjectCode)),
                            SqlSection.user_email == user_email
                        ).first()
                        if sec_row:
                            subj_id = subjectCode if (subjectCode and str(subjectCode).strip()) else sec_row.subject
                            enroll = session.query(SqlStudentEnrollment).filter(
                                SqlStudentEnrollment.student_code == doc_id,
                                SqlStudentEnrollment.subject_id == subj_id
                            ).first()
                            if not enroll:
                                enroll = SqlStudentEnrollment(
                                    student_code=doc_id,
                                    subject_id=subj_id,
                                    section_id=sec_row.id,
                                    user_id=user_email
                                )
                                session.add(enroll)
                            else:
                                enroll.section_id = sec_row.id

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
                row = query.filter(model_cls.user_email == user_email).first()
                if not row:
                    row = query.first()
            else:
                row = query.first()
            if row:
                if collection == "students":
                    # ลบข้อมูลการลงทะเบียนเรียนที่เกี่ยวข้องก่อน เพื่อไม่ให้ติด Foreign Key
                    session.query(SqlStudentEnrollment).filter(
                        SqlStudentEnrollment.student_code == doc_id,
                        SqlStudentEnrollment.user_id == user_email
                    ).delete()
                session.delete(row)
                session.commit()
        except Exception as e:
            session.rollback()
            print(f"Error in delete_doc ({collection}, {doc_id}): {e}")
            raise
        finally:
            session.close()

    def get_results(self, user_email: str) -> List[dict[str, Any]]:
        """โหลด results พร้อม answers แบบ batch — ลด N+1 query อย่างมาก"""
        session = self._get_session()
        try:
            rows = session.query(SqlResult).filter(
                SqlResult.user_email == user_email
            ).all()
            if not rows:
                return []

            result_ids = [r.id for r in rows]
            student_codes = list({r.studentCode for r in rows if r.studentCode})

            # Batch load ExamDetails ทีเดียว
            details_all = session.query(SqlExamDetail).filter(
                SqlExamDetail.result_id.in_(result_ids),
                SqlExamDetail.user_id == user_email,
            ).order_by(SqlExamDetail.question_no).all()

            # Batch load Student names ทีเดียว
            student_map: dict[str, str] = {}
            if student_codes:
                students = session.query(SqlStudent).filter(
                    SqlStudent.id.in_(student_codes)
                ).all()
                student_map = {s.id: s.name for s in students}

            # Group details by result_id
            details_map: dict[str, list] = {}
            for det in details_all:
                details_map.setdefault(det.result_id, []).append(det)

            res = []
            for row in rows:
                try:
                    d = {c.key: getattr(row, c.key) for c in row.__mapper__.column_attrs}

                    # Convert datetime
                    for k, v in list(d.items()):
                        if isinstance(v, datetime):
                            d[k] = v.isoformat()

                    # Answers from batch-loaded details
                    answers_dict: dict[str, str] = {}
                    wrong_list: list[str] = []
                    skipped_list: list[str] = []
                    for det in details_map.get(row.id, []):
                        q = str(det.question_no)
                        answers_dict[q] = det.student_answer or ""
                        if det.status_answer == "Wrong":
                            wrong_list.append(q)
                        elif det.status_answer == "Skipped":
                            skipped_list.append(q)

                    d["answers"] = answers_dict
                    d["wrong"] = wrong_list
                    d["skipped"] = skipped_list
                    d["studentName"] = student_map.get(row.studentCode or "", "")
                    res.append(d)
                except Exception as e:
                    print(f"Warning: skipping result {getattr(row, 'id', '?')} due to error: {e}")
                    continue
            return res
        finally:
            session.close()

    def get_collection(self, collection: str, user_email: Optional[str] = None, parent_doc_id: Optional[str] = None) -> List[dict]:
        if collection == "students":
            return self.get_students(user_email)
        if collection == "exams":
            return self.get_exams(user_email)
        if collection == "results":
            return self.get_results(user_email)

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
            return [self._to_dict(r, session=session) for r in rows]
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
    # Always use MySQL — ensure charset and correct driver prefix
    if db_url.startswith("postgresql") or db_url.startswith("postgres"):
        # Fallback safety: strip supabase/postgres URL and use local MySQL
        db_url = "mysql+pymysql://root:@localhost:3306/exam_grading"
    if "charset=" not in db_url:
        db_url += "?charset=utf8mb4" if "?" not in db_url else "&charset=utf8mb4"

    print(f"DATABASE: Connecting to MySQL -> {db_url}")
    _cached_adapter = MySQLAdapter(db_url)
    return _cached_adapter
