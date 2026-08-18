import { useState, useEffect } from "react";
import { API_BASE_URL, Swal, Icon, PrimaryButton, Field } from "../ui.jsx";

const BASE_URL = API_BASE_URL || "http://127.0.0.1:8000";

export function AdminSettingsPage({ user }) {
  const [academicYear, setAcademicYear] = useState("");
  const [term, setTerm] = useState("");
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    fetch(`${BASE_URL}/api/settings/academic_year`, { cache: "no-store" })
      .then((res) => res.json())
      .then((data) => {
        setAcademicYear(data.year || String(new Date().getFullYear() + 543));
        setTerm(data.term || "1");
        setLoading(false);
      })
      .catch((err) => {
        console.error("Failed to load settings:", err);
        setLoading(false);
      });
  }, []);

  async function saveSettings(e) {
    e.preventDefault();
    if (!academicYear) {
      return Swal().fire("กรุณาระบุปีการศึกษา", "", "warning");
    }

    try {
      Swal().fire({
        title: "กำลังบันทึก...",
        allowOutsideClick: false,
        didOpen: () => Swal().showLoading(),
      });

      const res = await fetch(`${BASE_URL}/api/settings/academic_year`, {
        method: "PUT",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${user.email}`,
        },
        body: JSON.stringify({ year: academicYear, term: term }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || "บันทึกไม่สำเร็จ");
      }

      await Swal().fire(
        "สำเร็จ",
        "บันทึกปีการศึกษาและภาคเรียนเรียบร้อยแล้ว",
        "success",
      );
    } catch (err) {
      Swal().fire("เกิดข้อผิดพลาด", err.message, "error");
    }
  }

  if (loading) {
    return (
      <div className="flex justify-center py-20 text-slate-500">
        <Icon name="fa-circle-notch fa-spin text-3xl" />
      </div>
    );
  }

  if (user?.role !== "admin") {
    return (
      <div className="max-w-2xl mx-auto py-12 text-center text-red-500 font-bold">
        คุณไม่มีสิทธิ์เข้าถึงหน้านี้ (สำหรับผู้ดูแลระบบเท่านั้น)
      </div>
    );
  }

  return (
    <div className="page-enter max-w-3xl mx-auto px-4 sm:px-6 py-6">
      <div className="mb-6 flex items-center gap-3">
        <div className="w-10 h-10 bg-white rounded-xl shadow-sm border border-slate-200 flex items-center justify-center shrink-0">
          <Icon name="fa-cogs text-lg text-blue-600" />
        </div>
        <div>
          <h2 className="text-xl sm:text-2xl font-extrabold text-slate-900 tracking-tight leading-none">
            ตั้งค่าระบบ
          </h2>
          <p className="mt-1 text-sm text-slate-500">
            กำหนดค่าพารามิเตอร์เริ่มต้นสำหรับระบบทั้งหมด
          </p>
        </div>
      </div>

      <div className="bg-white rounded-2xl shadow-[0_2px_15px_-3px_rgba(0,0,0,0.05)] border border-slate-200 overflow-hidden">
        <div className="px-5 py-4 border-b border-slate-100 bg-slate-50/80 flex items-center gap-3">
          <div className="w-8 h-8 rounded-full bg-blue-100 flex items-center justify-center text-blue-600">
            <Icon name="fa-calendar-days text-sm" />
          </div>
          <h3 className="text-base font-bold text-slate-800">
            ปีการศึกษาและภาคเรียนปัจจุบัน
          </h3>
        </div>

        <form onSubmit={saveSettings} className="p-5 sm:p-6 space-y-6">
          <div className="flex flex-col sm:flex-row gap-5 max-w-2xl">
            <div className="w-full sm:w-56">
              <label className="block text-sm font-bold text-slate-700 mb-1.5">
                ปีการศึกษา
              </label>
              <div className="flex items-center border border-slate-300 rounded-xl overflow-hidden h-11 bg-white shadow-sm focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100 transition-all">
                <button
                  type="button"
                  onClick={() =>
                    setAcademicYear((p) => String(parseInt(p || 2567) - 1))
                  }
                  className="w-10 h-full flex items-center justify-center bg-slate-50 hover:bg-slate-100 hover:text-blue-600 text-slate-500 transition-colors border-r border-slate-200 shrink-0"
                >
                  <Icon name="fa-minus text-xs" />
                </button>
                <input
                  type="text"
                  readOnly
                  value={academicYear}
                  className="w-full h-full text-center focus:outline-none bg-transparent font-bold text-slate-700 text-lg"
                  required
                />
                <button
                  type="button"
                  onClick={() =>
                    setAcademicYear((p) => String(parseInt(p || 2567) + 1))
                  }
                  className="w-10 h-full flex items-center justify-center bg-slate-50 hover:bg-slate-100 hover:text-blue-600 text-slate-500 transition-colors border-l border-slate-200 shrink-0"
                >
                  <Icon name="fa-plus text-xs" />
                </button>
              </div>
            </div>

            <div className="w-full sm:w-36">
              <label className="block text-sm font-bold text-slate-700 mb-1.5">
                ภาคเรียน
              </label>
              <div className="flex items-center justify-between border border-slate-300 rounded-xl overflow-hidden h-11 bg-white shadow-sm focus-within:border-blue-500 focus-within:ring-2 focus-within:ring-blue-100 transition-all">
                <button
                  type="button"
                  onClick={() => {
                    const v = parseInt(term) || 1;
                    if (v > 1) setTerm(String(v - 1));
                  }}
                  className="w-10 h-full flex items-center justify-center bg-slate-50 hover:bg-slate-100 hover:text-blue-600 text-slate-500 transition-colors border-r border-slate-200"
                >
                  <Icon name="fa-minus text-xs" />
                </button>
                <span className="font-bold text-slate-700 text-lg w-full text-center">
                  {term || "1"}
                </span>
                <button
                  type="button"
                  onClick={() => {
                    const v = parseInt(term) || 1;
                    if (v < 3) setTerm(String(v + 1));
                  }}
                  className="w-10 h-full flex items-center justify-center bg-slate-50 hover:bg-slate-100 hover:text-blue-600 text-slate-500 transition-colors border-l border-slate-200"
                >
                  <Icon name="fa-plus text-xs" />
                </button>
              </div>
            </div>
          </div>

          <div className="flex items-start gap-2.5 bg-blue-50/60 px-4 py-3 rounded-xl border border-blue-100/60">
            <Icon name="fa-circle-info text-blue-500 mt-0.5 text-sm shrink-0" />
            <p className="text-sm text-slate-600 leading-snug">
              ภาคเรียนและปีการศึกษาที่กำหนดที่นี่
              จะถูกนำไปใช้เป็นค่าตั้งต้นอัตโนมัติ
              ในขณะที่ผู้ใช้งานกำลังเพิ่มรายวิชาใหม่
            </p>
          </div>

          <div className="pt-5 border-t border-slate-100 flex justify-end">
            <PrimaryButton
              type="submit"
              className="px-6 py-2 text-sm shadow-md shadow-blue-500/20 hover:shadow-lg hover:shadow-blue-500/30 transition-all"
            >
              <Icon name="fa-floppy-disk mr-1.5" /> บันทึกการตั้งค่า
            </PrimaryButton>
          </div>
        </form>
      </div>
    </div>
  );
}
