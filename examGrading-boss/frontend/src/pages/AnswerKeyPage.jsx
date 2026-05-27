import { useEffect, useState } from "react";
import { Field, Icon, PrimaryButton, Select } from "../ui.jsx";

export function AnswerKeyPage({ data, api, refresh, query }) {
  const [examId, setExamId] = useState(query.examId || data.exams[0]?.id || "");
  const [answers, setAnswers] = useState({});
  const exam = data.exams.find((item) => item.id === examId);

  useEffect(() => {
    if (!exam) return;
    setAnswers(exam.answerKey?.[0] || {});
  }, [examId, exam]);

  async function save() {
    if (!exam) return;
    const answerKey = { 0: answers };
    await api.update("exams", exam.id, { answerKey });
    localStorage.setItem("answerKeys", JSON.stringify({ ...JSON.parse(localStorage.getItem("answerKeys") || "{}"), [exam.id]: answerKey }));
    await refresh("บันทึกเฉลยแล้ว");
  }

  const questionNumbers = Array.from({ length: Number(exam?.questions || 0) }, (_, index) => index + 1);
  const options = Array.from({ length: 5 }, (_, index) => String.fromCharCode(65 + index));

  return (
    <div className="page-enter space-y-6">
      <div className="bg-white rounded-2xl border border-slate-200 p-5 shadow-sm flex flex-wrap items-end justify-between gap-4">
        <div className="flex-1 max-w-md">
          <Field label="เลือกข้อสอบ">
            <Select value={examId} onChange={(e) => setExamId(e.target.value)}>
              <option value="">เลือกข้อสอบ</option>
              {data.exams.map((item) => <option key={item.id} value={item.id}>{item.name} ({item.subject})</option>)}
            </Select>
          </Field>
        </div>
        <PrimaryButton onClick={save} disabled={!exam} className="px-10"><Icon name="fa-floppy-disk" /> บันทึกเฉลย</PrimaryButton>
      </div>
      {exam ? (
        <div className="columns-1 sm:columns-2 lg:columns-3 xl:columns-4 2xl:columns-5 gap-4">
          {questionNumbers.map((question) => (
            <div key={question} className="break-inside-avoid bg-white rounded-xl border border-slate-200 p-4 flex items-center justify-between mb-4 hover:border-blue-300 transition-colors shadow-sm">
              <span className="font-extrabold text-slate-700 min-w-[50px]">ข้อ {question}</span>
              <div className="flex gap-1.5">
                {options.map((option) => (
                  <button
                    key={option}
                    type="button"
                    onClick={() => setAnswers({ ...answers, [question]: option })}
                    className={`w-9 h-9 rounded-full border-2 font-bold transition-all ${answers[question] === option ? "bg-blue-600 text-white border-blue-600 shadow-md shadow-blue-200 scale-110" : "bg-white text-slate-500 border-slate-100 hover:border-blue-200"}`}
                  >
                    {option}
                  </button>
                ))}
              </div>
            </div>
          ))}
        </div>
      ) : (
        <div className="bg-white border border-slate-200 rounded-2xl p-10 text-center text-slate-500 shadow-sm">เลือกข้อสอบเพื่อกำหนดเฉลย</div>
      )}
    </div>
  );
}


