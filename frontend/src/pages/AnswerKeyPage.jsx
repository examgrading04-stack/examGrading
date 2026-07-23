import { useEffect, useState } from "react";
import { Icon, PrimaryButton, GhostButton, Swal } from "../ui.jsx";

export function AnswerKeyPage({ data, api, refresh, query }) {
  const [examId, setExamId] = useState(query.examId || data.exams[0]?.id || "");
  const [answers, setAnswers] = useState({});
  const exam = data.exams.find((item) => item.id === examId);

  useEffect(() => {
    if (!exam) return;
    const ak = exam.answerKey || {};
    // Handle nested format { "0": {...} } and flat format { "1": "A", ... }
    const loadedAnswers =
      ak["0"] || ak[0] || (ak["1"] || Object.keys(ak).length ? ak : {});
    setAnswers(loadedAnswers);
  }, [examId, exam]);

  async function save() {
    if (!exam) return;
    Swal().fire({
      title: "กำลังบันทึก...",
      allowOutsideClick: false,
      didOpen: () => {
        Swal().showLoading();
      },
    });
    const answerKey = { 0: answers };
    await api.update("exams", exam.id, { answerKey });
    localStorage.setItem(
      "answerKeys",
      JSON.stringify({
        ...JSON.parse(localStorage.getItem("answerKeys") || "{}"),
        [exam.id]: answerKey,
      }),
    );
    await refresh("บันทึกเฉลยแล้ว");
  }

  function toggleAnswer(question, option) {
    setAnswers((prev) => {
      const next = { ...prev };
      if (next[question] === option) {
        delete next[question];
      } else {
        next[question] = option;
      }
      return next;
    });
  }

  function clearAll() {
    Swal().fire({
      title: "ล้างคำตอบทั้งหมด?",
      text: "คุณต้องการล้างเฉลยทุกข้อใช่หรือไม่",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ล้างทั้งหมด",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#ef4444",
    }).then((result) => {
      if (result.isConfirmed) {
        setAnswers({});
      }
    });
  }

  const questionNumbers = Array.from(
    { length: Number(exam?.questions || 0) },
    (_, index) => index + 1,
  );
  const options = Array.from({ length: 5 }, (_, index) =>
    String.fromCharCode(65 + index),
  );

  const answeredCount = Object.values(answers).filter(Boolean).length;
  const totalQuestions = Number(exam?.questions || 0);

  return (
    <div className="page-enter space-y-6">
      <div className="bg-white rounded-xl border border-slate-200 border-t-4 border-t-blue-600 p-5 shadow-sm flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-4">
          <button
            onClick={() => window.history.back()}
            className="w-10 h-10 flex items-center justify-center rounded-lg bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors shrink-0"
            title="กลับไปหน้าจัดการกระดาษคำตอบ"
          >
            <Icon name="fa-arrow-left" />
          </button>
          <div>
            <h2 className="text-xl font-bold text-slate-800">
              {exam ? `เฉลยข้อสอบ: ${exam.name}` : "เลือกข้อสอบ"}
            </h2>
            <p className="text-sm text-slate-500 mt-0.5">
              {exam ? `รหัสวิชา: ${exam.subject} | กำหนดแล้ว ${answeredCount} / ${totalQuestions} ข้อ` : "เลือกข้อสอบเพื่อกำหนดเฉลย"}
            </p>
          </div>
        </div>

        {exam && (
          <div className="flex items-center gap-3">
            <GhostButton
              variant="danger"
              onClick={clearAll}
              className="py-2 px-3 text-sm"
              title="ล้างคำตอบทั้งหมด"
            >
              <Icon name="fa-rotate-left" /> ล้างเฉลย
            </GhostButton>
            <PrimaryButton onClick={save} disabled={!exam} className="px-6 py-2">
              <Icon name="fa-floppy-disk" /> บันทึกเฉลย
            </PrimaryButton>
          </div>
        )}
      </div>

      {exam ? (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-3.5">
          {questionNumbers.map((question) => {
            const currentSelected = answers[question];
            return (
              <div
                key={question}
                className={`bg-white rounded-xl border p-3.5 flex items-center justify-between gap-2 shadow-sm transition-all ${
                  currentSelected
                    ? "border-blue-200 bg-blue-50/20"
                    : "border-slate-200 hover:border-slate-300"
                }`}
              >
                <div className="flex items-center gap-1.5 shrink-0">
                  <span className="text-xs font-bold text-slate-400 w-5 text-right">
                    {question}.
                  </span>
                  <span className="font-bold text-slate-700 text-sm">
                    ข้อ {question}
                  </span>
                </div>
                <div className="flex items-center gap-1 sm:gap-1.5 shrink-0">
                  {options.map((option) => {
                    const isSelected = currentSelected === option;
                    return (
                      <button
                        key={option}
                        type="button"
                        onClick={() => toggleAnswer(question, option)}
                        className={`w-8 h-8 sm:w-8.5 sm:h-8.5 rounded-full text-xs font-bold transition-all flex items-center justify-center shrink-0 ${
                          isSelected
                            ? "bg-blue-600 text-white shadow-md shadow-blue-500/30 scale-105"
                            : "bg-slate-100 text-slate-600 hover:bg-blue-50 hover:text-blue-600 border border-slate-200/80"
                        }`}
                      >
                        {option}
                      </button>
                    );
                  })}
                </div>
              </div>
            );
          })}
        </div>
      ) : (
        <div className="bg-white border border-slate-200 rounded-xl p-12 text-center text-slate-500 shadow-sm">
          <Icon name="fa-key" className="text-4xl text-slate-300 mb-3" />
          <p className="font-semibold text-lg text-slate-600">ไม่พบข้อมูลข้อสอบ</p>
          <p className="text-sm text-slate-400">กรุณาเลือกข้อสอบจากหน้าจัดการกระดาษคำตอบ</p>
        </div>
      )}
    </div>
  );
}

