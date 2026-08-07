import { useState } from "react";
import {
  Swal,
  PasswordInput,
  AuthInput,
  Checkbox,
  Icon,
  AppLogo,
} from "../ui.jsx";
import { Loader } from "../components/Loader.jsx";

const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000";

export default function AdminLoginPage({ setSession, writeAnonymousLog }) {
  const [loginForm, setLoginForm] = useState({
    aname: "",
    apassword: "",
    remember: false,
  });
  const [loading, setLoading] = useState(false);

  async function login(event) {
    event.preventDefault();
    setLoading(true);
    try {
      const res = await fetch(`${API_BASE_URL}/api/auth/admin/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          aname: loginForm.aname,
          apassword: loginForm.apassword,
        }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || "เข้าสู่ระบบไม่สำเร็จ");
      }

      const admin = await res.json();
      const nextSession = {
        aid: admin.user_id || admin.aid || admin.id,
        aname: admin.username || admin.aname || admin.id,
      };

      if (loginForm.remember) {
        localStorage.setItem("examAdminSession", JSON.stringify(nextSession));
      } else {
        sessionStorage.setItem("examAdminSession", JSON.stringify(nextSession));
      }

      setSession(nextSession);
      if (writeAnonymousLog) {
        await writeAnonymousLog(
          `เข้าสู่ระบบ Admin สำเร็จ: ${nextSession.aname}`,
        );
      }
    } catch (error) {
      if (writeAnonymousLog) {
        await writeAnonymousLog(
          `เข้าสู่ระบบ Admin ไม่สำเร็จ: ${loginForm.aname}`,
        );
      }
      Swal().fire("เข้าสู่ระบบไม่สำเร็จ", error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen bg-slate-900 flex flex-col justify-center py-12 px-6 sm:px-6 lg:px-8 font-sans relative overflow-hidden">
      {/* Clean Dark Background */}
      <div className="absolute inset-0 z-0 bg-slate-900">
        <div className="absolute top-0 inset-x-0 h-96 bg-gradient-to-b from-blue-900/20 to-transparent"></div>
      </div>

      <div className="sm:mx-auto sm:w-full sm:max-w-md relative z-10 flex flex-col items-center">
        <div className="flex justify-center mb-6">
          <AppLogo
            compact
            className="!rounded-xl shadow-lg border border-slate-700 relative z-10"
          />
        </div>
        <h2 className="text-center text-3xl font-black text-white tracking-tight drop-shadow-sm">
          เข้าสู่ระบบผู้ดูแล
        </h2>
        <p className="mt-2 text-center text-sm font-medium text-slate-400">
          สำหรับผู้ดูแลระบบ ExamGrading เท่านั้น
        </p>
      </div>

      <div className="mt-8 sm:mx-auto sm:w-full sm:max-w-md relative z-10 w-full max-w-sm mx-auto sm:max-w-md">
        <div className="bg-slate-800/80 backdrop-blur-md py-8 px-6 sm:px-10 shadow-2xl rounded-2xl border border-slate-700/80 relative">
          <form onSubmit={login} className="space-y-6">
            <div className="space-y-2">
              <label className="text-[13px] font-bold text-slate-300 ml-1">
                ชื่อผู้ใช้ (Admin Username)
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-500">
                  <Icon name="fa-user-shield" />
                </div>
                <AuthInput
                  type="text"
                  value={loginForm.aname}
                  onChange={(event) =>
                    setLoginForm({ ...loginForm, aname: event.target.value })
                  }
                  placeholder="กรอกชื่อผู้ใช้สำหรับผู้ดูแลระบบ"
                  required
                  className="!pl-11 !bg-slate-900 !border-slate-700 !text-white !placeholder-slate-500 focus:!border-blue-500 focus:!ring-blue-500/30 rounded-xl"
                />
              </div>
            </div>

            <div className="space-y-2">
              <label className="text-[13px] font-bold text-slate-300 ml-1">
                รหัสผ่าน (Password)
              </label>
              <div className="relative">
                <div className="absolute inset-y-0 left-0 pl-4 flex items-center pointer-events-none text-slate-500 z-10">
                  <Icon name="fa-lock" />
                </div>
                <PasswordInput
                  value={loginForm.apassword}
                  onChange={(event) =>
                    setLoginForm({
                      ...loginForm,
                      apassword: event.target.value,
                    })
                  }
                  placeholder="กรอกรหัสผ่าน"
                  required
                  className="!pl-11 !bg-slate-900 !border-slate-700 !text-white !placeholder-slate-500 focus:!border-blue-500 focus:!ring-blue-500/30 rounded-xl"
                />
              </div>
            </div>

            <button
              type="submit"
              className="w-full bg-blue-600 hover:bg-blue-500 text-white font-bold py-3.5 px-4 rounded-xl shadow-md shadow-blue-900/50 transition-all active:scale-[0.98] mt-6 flex items-center justify-center gap-2 border border-blue-500/50"
              disabled={loading}
            >
              <Icon name="fa-right-to-bracket" className="text-lg" />
              <span>เข้าสู่ระบบ</span>
            </button>
          </form>
        </div>
      </div>

      {loading && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-900/80 backdrop-blur-sm">
          <Loader />
        </div>
      )}
    </div>
  );
}
