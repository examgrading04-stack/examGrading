import { useState } from "react";
import { Field, Icon, Input, PrimaryButton, Select } from "../ui.jsx";

export function AnswerSheet({ config, hideToolbar = false }) {
  const [sheet, setSheet] = useState(config || { questions: 50, subject: "INT101", examName: "สอบกลางภาค", sheetType: 50 });
  const optionsCount = Number(sheet.options || config?.options || 4);
  const setsCount = Number(sheet.sets || config?.sets || 1);
  const questionNumbers = Array.from({ length: Number(sheet.questions || 50) }, (_, index) => index + 1);
  const options = Array.from({ length: optionsCount }, (_, index) => String.fromCharCode(65 + index));
  const barcodePatterns = {
    20: ["2mm", "6mm", "2mm", "2mm", "4mm", "2mm"],
    50: ["4mm", "2mm", "6mm", "2mm", "2mm", "4mm"],
    100: ["6mm", "2mm", "2mm", "4mm", "2mm", "6mm"],
  };
  const sheetType = Number(sheet.questions) <= 20 ? 20 : Number(sheet.questions) <= 50 ? 50 : 100;

  return (
    <div className="omr-page">
      {!hideToolbar && (
        <div className="no-print bg-white shadow-sm py-3 px-6 flex flex-wrap gap-3 items-end sticky top-0 z-30">
          <Field label="จำนวนข้อ"><Input type="number" min="1" max="100" value={sheet.questions} onChange={(e) => setSheet({ ...sheet, questions: e.target.value })} className="w-24" /></Field>
          <Field label="วิชา"><Input value={sheet.subject} onChange={(e) => setSheet({ ...sheet, subject: e.target.value })} className="w-36" /></Field>
          <Field label="ชื่อข้อสอบ"><Input value={sheet.examName} onChange={(e) => setSheet({ ...sheet, examName: e.target.value })} className="w-48" /></Field>
          <PrimaryButton onClick={() => window.print()}><Icon name="fa-print" /> พิมพ์</PrimaryButton>
        </div>
      )}
      <div className="sheet-preview-wrapper bg-gray-300 min-h-screen p-6 overflow-auto flex justify-center">
        <div className="answer-sheet shadow-2xl">
          <div className="mark-corner mark-tl" />
          <div className="mark-corner mark-tr" />
          <div className="mark-corner mark-bl" />
          <div className="mark-corner mark-br" />
          <div className="barcode-area">{(barcodePatterns[sheet.sheetType || sheetType] || barcodePatterns[100]).map((width, index) => <div key={index} style={{ width, background: "black" }} />)}</div>
          <div className="sheet-content">
            <div className="sheet-header border-b-2 border-black pb-3 mb-3">
              <div className="flex justify-between gap-4">
                <div>
                  <h1 className="text-2xl font-bold">กระดาษคำตอบ</h1>
                  <p className="text-sm">OMR Answer Sheet</p>
                  <p className="mt-2 font-bold">วิชา: {sheet.subject || "-"}</p>
                  <p className="font-bold">ข้อสอบ: {sheet.examName || "-"}</p>
                </div>
                <div className="flex gap-4">
                  <div className="text-center">
                    <p className="text-[10px] font-bold mb-1">Student ID / รหัสนักเรียน</p>
                    <div className="border border-black p-1 bg-gray-50">
                      <div className="flex gap-[2px]">
                        {Array.from({ length: 13 }, (_, col) => (
                          <div key={col} className="flex flex-col items-center">
                            <div className="border border-gray-400 w-3 h-3 mb-0.5 bg-white" />
                            {Array.from({ length: 10 }, (_, num) => <div key={num} className="w-[10px] h-[10px] rounded-full border border-gray-400 text-[5.5px] flex items-center justify-center mb-[1.5px] text-gray-500 bg-white font-bold">{num}</div>)}
                          </div>
                        ))}
                      </div>
                    </div>
                  </div>
                  {setsCount > 1 && (
                    <div className="text-center">
                      <p className="text-[10px] font-bold mb-1">ชุด</p>
                      {Array.from({ length: setsCount }, (_, index) => <div key={index} className="w-[13px] h-[13px] rounded-full border border-gray-400 text-[7px] flex items-center justify-center mb-0.5 text-gray-600 bg-white font-bold">{String.fromCharCode(65 + index)}</div>)}
                    </div>
                  )}
                </div>
              </div>
            </div>
            <div className="sheet-bubbles">
              <div className={`${Number(sheet.questions) <= 50 ? "omr-columns-2" : "omr-columns-4"} h-full`}>
                {questionNumbers.map((question) => (
                  <div key={question} className="flex items-center gap-1 mb-[5px] break-inside-avoid">
                    <span className="w-[18px] text-right font-bold text-gray-800 text-[9px] shrink-0">{question}.</span>
                    <div className="flex gap-[3px]">
                      {options.map((option) => <div key={option} className="w-[15px] h-[15px] rounded-full border border-gray-500 flex items-center justify-center text-[7px] text-gray-500 font-bold bg-white">{option}</div>)}
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}


