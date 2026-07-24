import { useState } from "react";
import {
  Swal,
  SplitScreenAuthLayout,
  PasswordInput,
  AuthInput,
  Icon,
} from "../ui.jsx";

export default function RegisterPage({ setMode, auth, navigate, hideLayout }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");

  async function submit(event) {
    event.preventDefault();
    if (password !== confirm) {
      Swal().fire("รหัสผ่านไม่ตรงกัน", "กรุณาตรวจสอบรหัสผ่านอีกครั้ง", "error");
      return;
    }
    if (password.length < 6) {
      Swal().fire(
        "รหัสผ่านสั้นเกินไป",
        "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร",
        "error",
      );
      return;
    }
    Swal().fire({
      title: "กำลังสร้างบัญชี...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    try {
      await auth.createUserWithEmailAndPassword(email, password);
      sessionStorage.setItem("justLoggedIn", "true");
      Swal().close();
    } catch (error) {
      Swal().fire("สมัครสมาชิกไม่สำเร็จ", error.message, "error");
    }
  }

  const content = (
    <>
      <form className="space-y-4" onSubmit={submit}>
        <div className="space-y-1">
          <label className="text-[13px] font-bold text-slate-700 ml-1">
            อีเมล
          </label>
          <AuthInput
            type="email"
            value={email}
            onChange={(event) => setEmail(event.target.value)}
            placeholder="example@company.com"
            required
          />
        </div>
        <div className="space-y-1">
          <label className="text-[13px] font-bold text-slate-700 ml-1">
            รหัสผ่าน
          </label>
          <PasswordInput
            value={password}
            onChange={(event) => setPassword(event.target.value)}
            placeholder="กรอกรหัสผ่าน"
            required
          />
        </div>
        <div className="space-y-1">
          <label className="text-[13px] font-bold text-slate-700 ml-1">
            ยืนยันรหัสผ่าน
          </label>
          <PasswordInput
            value={confirm}
            onChange={(event) => setConfirm(event.target.value)}
            placeholder="ยืนยันรหัสผ่านอีกครั้ง"
            required
          />
        </div>

        <button
          type="submit"
          className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl shadow-md shadow-blue-600/20 hover:shadow-lg hover:shadow-blue-600/30 transition-all active:scale-[0.98] mt-4"
        >
          ลงทะเบียนบัญชี
        </button>
      </form>

      <div className="mt-5 pt-5 border-t border-slate-100 flex flex-col items-center gap-2">
        <p className="text-center text-slate-600 font-medium text-[15px]">
          มีบัญชีอยู่แล้วใช่ไหม?{" "}
          <button
            type="button"
            onClick={() => setMode("login")}
            className="text-blue-600 font-bold hover:underline transition-all"
          >
            เข้าสู่ระบบเลย
          </button>
        </p>
      </div>
    </>
  );

  if (hideLayout) return content;

  return (
    <SplitScreenAuthLayout
      title="สร้างบัญชีผู้ใช้งาน"
      subtitle="กรอกข้อมูลของคุณเพื่อเริ่มต้นใช้งานระบบ"
      rightTitle="เริ่มต้นใช้งานระบบประเมินผล"
      rightSubtitle="สมัครสมาชิกวันนี้เพื่อจัดการห้องเรียนและการสอบอย่างมืออาชีพ"
      isRegister={true}
    >
      {content}
    </SplitScreenAuthLayout>
  );
}
