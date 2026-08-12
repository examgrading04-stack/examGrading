import { useEffect, useState } from "react";
import { Icon, PrimaryButton, Input, Swal } from "../ui.jsx";

export function AnswerKeyPage({ data, api, refresh, query }) {
  const [examId, setExamId] = useState(query.examId || data.exams[0]?.id || "");
  const [answers, setAnswers] = useState({});
  const [scores, setScores] = useState({});
  const [isCustomScore, setIsCustomScore] = useState(false);
  const [globalScore, setGlobalScore] = useState(1);
  const exam = data.exams.find((item) => item.id === examId);

  function handleGlobalScoreChange(e) {
    const val = e.target.value;
    const newGlobalScore = val ? Number(val) : 0;
    setGlobalScore(newGlobalScore);

    const newScores = { ...scores };
    const maxQ = Number(exam?.questions || 0);
    for (let i = 1; i <= maxQ; i++) {
      newScores[i] = newGlobalScore;
    }
    setScores(newScores);
  }

  useEffect(() => {
    if (!exam) return;
    const ak = exam.answerKey || {};
    // Handle nested format { "0": {...} } and flat format { "1": "A", ... }
    const loadedAnswers =
      ak["0"] || ak[0] || (ak["1"] || Object.keys(ak).length ? ak : {});

    const initialAnswers = {};
    const initialScores = {};
    let hasCustomScore = false;

    for (const [q, val] of Object.entries(loadedAnswers)) {
      if (typeof val === "object" && val !== null) {
        initialAnswers[q] = val.answer;
        initialScores[q] = Number(val.score || 1);
        if (Number(val.score || 1) !== 1) hasCustomScore = true;
      } else {
        initialAnswers[q] = val;
        initialScores[q] = 1;
      }
    }

    setAnswers(initialAnswers);
    setScores(initialScores);

    if (exam.isCustomScore !== undefined) {
      setIsCustomScore(exam.isCustomScore);
    } else if (hasCustomScore) {
      setIsCustomScore(true);
    }

    if (exam.defaultScore !== undefined) {
      setGlobalScore(exam.defaultScore);
    }
  }, [examId, exam]);

  async function save() {
    if (!exam) return;

    const maxQ = Number(exam?.questions || 0);
    const missingAnswers = [];
    for (let i = 1; i <= maxQ; i++) {
      if (!answers[i]) {
        missingAnswers.push(i);
      }
    }

    if (missingAnswers.length > 0) {
      Swal().fire({
        title: "ข้อมูลไม่ครบถ้วน",
        text: `กรุณาเลือกเฉลยให้ครบทุกข้อ (ยังขาดอีก ${missingAnswers.length} ข้อ)`,
        icon: "warning",
      });
      return;
    }

    Swal().fire({
      title: "กำลังบันทึก...",
      allowOutsideClick: false,
      didOpen: () => {
        Swal().showLoading();
      },
    });

    const answerKeyToSave = {};
    for (const q of Object.keys(answers)) {
      if (isCustomScore) {
        answerKeyToSave[q] = {
          answer: answers[q],
          score: scores[q] ?? globalScore,
        };
      } else {
        answerKeyToSave[q] = answers[q];
      }
    }

    const answerKey = { 0: answerKeyToSave };
    await api.update("exams", exam.id, {
      answerKey,
      isCustomScore,
      defaultScore: globalScore,
    });
    localStorage.setItem(
      "answerKeys",
      JSON.stringify({
        ...JSON.parse(localStorage.getItem("answerKeys") || "{}"),
        [exam.id]: answerKey,
      }),
    );
    await refresh("บันทึกเฉลยแล้ว");
  }

  const sheetTypeCount = Number(
    String(exam?.sheetType || exam?.questions || 30).replace("-A-E", ""),
  );
  const questionCount = Number(exam?.questions || 0);

  const questionNumbers = Array.from(
    { length: sheetTypeCount },
    (_, index) => index + 1,
  );

  const options = Array.from({ length: 5 }, (_, index) =>
    String.fromCharCode(65 + index),
  );

  return (
    <div className="page-enter max-w-[1600px] mx-auto pb-20 px-4">
      <div className="bg-white rounded-lg border border-zinc-200 shadow-sm p-5 mb-6 flex flex-col gap-4">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="flex items-center gap-4">
            <button
              onClick={() => window.history.back()}
              className="w-10 h-10 flex items-center justify-center rounded-md bg-slate-100 hover:bg-slate-200 text-slate-600 transition-colors"
              title="กลับไปหน้าจัดการกระดาษคำตอบ"
            >
              <Icon name="fa-arrow-left" />
            </button>
            <div>
              <h2 className="text-xl font-bold text-slate-800">
                {exam ? `เฉลย: ${exam.name}` : "เลือกข้อสอบ"}
              </h2>
              <div className="flex items-center gap-2 mt-1">
                <span className="bg-blue-50 text-blue-700 text-xs font-semibold px-2 py-0.5 rounded border border-blue-100">
                  {exam?.subject}
                </span>
                <span className="text-sm text-slate-500 font-medium">
                  กำหนดเฉลย {questionCount} ข้อ จากแม่แบบ {sheetTypeCount} ข้อ
                </span>
              </div>
            </div>
          </div>
          <PrimaryButton onClick={save} disabled={!exam} className="px-8">
            <Icon name="fa-floppy-disk" /> บันทึกเฉลย
          </PrimaryButton>
        </div>

        {/* Settings Bar */}
        <div className="bg-slate-50 rounded-lg p-3 border border-slate-200 flex flex-wrap items-center gap-4">
          <div className="flex items-center gap-3">
            <span className="text-sm font-semibold text-slate-700">
              น้ำหนักคะแนน:
            </span>
            <div className="flex bg-slate-200 p-1 rounded-md">
              <button
                onClick={() => setIsCustomScore(false)}
                className={`px-3 py-1 text-sm font-medium rounded-sm transition-all ${!isCustomScore ? "bg-white text-slate-800 shadow-sm" : "text-slate-500 hover:text-slate-700"}`}
              >
                เท่ากันทุกข้อ
              </button>
              <button
                onClick={() => setIsCustomScore(true)}
                className={`px-3 py-1 text-sm font-medium rounded-sm transition-all ${isCustomScore ? "bg-white text-blue-700 shadow-sm" : "text-slate-500 hover:text-slate-700"}`}
              >
                กำหนดคะแนนเอง
              </button>
            </div>
          </div>

          {isCustomScore && (
            <div className="flex items-center gap-2 pl-4 border-l border-slate-300">
              <span className="text-sm font-medium text-slate-600">
                คะแนนเริ่มต้น:
              </span>
              <div className="relative">
                <Input
                  type="number"
                  step="0.5"
                  min="0"
                  className="w-20 h-8 pl-2 pr-7 text-sm font-bold text-blue-700 bg-white border-slate-300 rounded"
                  value={globalScore}
                  onChange={handleGlobalScoreChange}
                />
                <span className="absolute right-2 top-1/2 -translate-y-1/2 text-xs text-slate-400 font-medium pointer-events-none">
                  pt
                </span>
              </div>
            </div>
          )}
        </div>
      </div>

      {exam ? (
        <div className="columns-1 sm:columns-2 lg:columns-3 xl:columns-4 2xl:columns-5 gap-4">
          {questionNumbers.map((question) => {
            const isDisabled = question > questionCount;

            if (isDisabled) {
              return (
                <div
                  key={question}
                  className="break-inside-avoid mb-4 bg-slate-50 rounded-md border border-dashed border-slate-200 p-4 flex flex-col gap-3 opacity-60 pointer-events-none"
                >
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-slate-400">
                      ข้อ {question}
                    </span>

                    {isCustomScore && (
                      <div className="flex items-center gap-1.5 invisible">
                        <div className="w-16 h-7" />
                      </div>
                    )}
                  </div>

                  <div className="relative flex gap-1.5 justify-center">
                    {/* Placeholder options to maintain height */}
                    <div className="flex gap-1.5 invisible">
                      {options.map((option) => (
                        <div key={`dummy-${option}`} className="w-8 h-8" />
                      ))}
                    </div>

                    {/* Overlay badge */}
                    <div className="absolute inset-0 flex items-center justify-center">
                      <span className="text-xs font-medium text-slate-500 bg-slate-200 px-2 py-0.5 rounded">
                        ไม่ได้เปิดใช้งาน
                      </span>
                    </div>
                  </div>
                </div>
              );
            }

            return (
              <div
                key={question}
                className="break-inside-avoid mb-4 bg-white rounded-md border border-zinc-200 p-4 flex flex-col gap-3 hover:border-blue-300 transition-colors"
              >
                <div className="flex items-center justify-between">
                  <span className="font-bold text-slate-700">
                    ข้อ {question}
                  </span>

                  {isCustomScore && (
                    <div className="flex items-center gap-1.5">
                      <div className="relative">
                        <Input
                          type="number"
                          step="0.5"
                          min="0"
                          className="w-16 h-7 pl-1.5 pr-5 text-xs text-center font-bold text-amber-700 bg-amber-50 border-amber-200 rounded"
                          placeholder={String(globalScore)}
                          value={
                            scores[question] !== undefined
                              ? scores[question]
                              : ""
                          }
                          onChange={(e) =>
                            setScores({
                              ...scores,
                              [question]: e.target.value
                                ? Number(e.target.value)
                                : undefined,
                            })
                          }
                          title="คะแนนสำหรับข้อนี้"
                        />
                        <span className="absolute right-1.5 top-1/2 -translate-y-1/2 text-[10px] text-amber-500 font-bold pointer-events-none">
                          pt
                        </span>
                      </div>
                    </div>
                  )}
                </div>

                <div className="flex gap-1.5 justify-center">
                  {options.map((option) => {
                    const isSelected = answers[question] === option;
                    return (
                      <button
                        key={option}
                        type="button"
                        onClick={() =>
                          setAnswers({ ...answers, [question]: option })
                        }
                        className={`w-8 h-8 shrink-0 rounded-full text-sm font-bold transition-colors border-2 ${
                          isSelected
                            ? "bg-blue-600 text-white border-blue-600"
                            : "bg-white text-zinc-500 border-slate-100 hover:border-blue-200"
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
        <div className="bg-white border border-zinc-200 rounded-md p-10 text-center text-zinc-500">
          เลือกข้อสอบเพื่อกำหนดเฉลย
        </div>
      )}
    </div>
  );
}
