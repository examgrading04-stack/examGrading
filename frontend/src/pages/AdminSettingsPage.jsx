import { useState, useEffect } from "react";
import {
  API_BASE_URL,
  Swal,
  Icon,
  PrimaryButton,
  Field,
} from "../ui.jsx";

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

      await Swal().fire("สำเร็จ", "บันทึกปีการศึกษาและภาคเรียนเรียบร้อยแล้ว", "success");
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
    <div className="page-enter max-w-[800px] mx-auto px-4">
      <div className="mb-6">
        <h2 className="text-2xl sm:text-3xl font-extrabold text-slate-900 tracking-tight">
          ตั้งค่าระบบ
        </h2>
        <p className="mt-1 text-sm text-slate-500">
          กำหนดค่าพารามิเตอร์เริ่มต้นสำหรับระบบทั้งหมด
        </p>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-slate-200 p-6">
        <form onSubmit={saveSettings} className="space-y-6">
          <div>
            <h3 className="text-lg font-bold text-slate-800 border-b pb-2 mb-4">
              ตั้งค่าภาคเรียนและปีการศึกษา
            </h3>
            <div className="flex gap-4">
              <div className="w-32">
                <Field label="ภาคเรียน">
                  <div className="flex items-center justify-between border border-gray-200 rounded-xl overflow-hidden h-[42px] px-2 bg-slate-50 focus-within:border-blue-500 focus-within:bg-white transition-colors">
                    <button
                      type="button"
                      onClick={() => {
                        const v = parseInt(term) || 1;
                        if (v > 1) setTerm(String(v - 1));
                      }}
                      className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-200 text-slate-600 transition-colors"
                    >
                      <Icon name="fa-minus" />
                    </button>
                    <span className="font-semibold text-slate-700 text-sm">
                      {term || "1"}
                    </span>
                    <button
                      type="button"
                      onClick={() => {
                        const v = parseInt(term) || 1;
                        if (v < 3) setTerm(String(v + 1));
                      }}
                      className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-200 text-slate-600 transition-colors"
                    >
                      <Icon name="fa-plus" />
                    </button>
                  </div>
                </Field>
              </div>
              <div className="flex-1 max-w-xs">
                <Field label="ปีการศึกษา">
                  <div className="flex items-center">
                    <button
                      type="button"
                      onClick={() =>
                        setAcademicYear((p) => String(parseInt(p || 2567) - 1))
                      }
                      className="w-12 h-[42px] flex items-center justify-center bg-slate-100 border border-slate-300 border-r-0 rounded-l-xl hover:bg-slate-200 transition-colors shrink-0"
                    >
                      <Icon name="fa-minus text-slate-600" />
                    </button>
                    <input
                      type="text"
                      readOnly
                      value={academicYear}
                      className="w-full h-[42px] text-center border border-slate-300 focus:outline-none bg-white font-medium text-slate-700"
                      required
                    />
                    <button
                      type="button"
                      onClick={() =>
                        setAcademicYear((p) => String(parseInt(p || 2567) + 1))
                      }
                      className="w-12 h-[42px] flex items-center justify-center bg-slate-100 border border-slate-300 border-l-0 rounded-r-xl hover:bg-slate-200 transition-colors shrink-0"
                    >
                      <Icon name="fa-plus text-slate-600" />
                    </button>
                  </div>
                </Field>
              </div>
            </div>
            <p className="text-xs text-slate-500 mt-2">
              * ภาคเรียนและปีการศึกษาที่กำหนดที่นี่จะถูกใช้เป็นค่าตั้งต้นและบังคับใช้ในหน้าเพิ่มรายวิชา
            </p>
          </div>

          <div className="pt-4 border-t flex justify-end">
            <PrimaryButton type="submit">
              <Icon name="fa-floppy-disk" /> บันทึกการตั้งค่า
            </PrimaryButton>
          </div>
        </form>
      </div>
    </div>
  );
}

