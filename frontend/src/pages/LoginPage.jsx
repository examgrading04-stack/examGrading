import { useState } from "react";
import {
  Swal,
  SplitScreenAuthLayout,
  PasswordInput,
  AuthInput,
  Checkbox,
  Icon,
} from "../ui.jsx";

export default function LoginPage({ setMode, auth, navigate, hideLayout }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberMe, setRememberMe] = useState(false);

  async function submit(event) {
    event.preventDefault();
    Swal().fire({
      title: "กำลังเข้าสู่ระบบ...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    try {
      // Check if user is blocked before calling auth API
      const cleanEmail = email.trim();
      const userDoc = await window.firebase
        .firestore()
        .collection("users")
        .doc(cleanEmail)
        .get();
      if (userDoc.exists && userDoc.data().status === "suspended") {
        Swal().fire(
          "ถูกระงับการใช้งาน",
          "บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ",
          "error",
        );
        return;
      }

      if (auth.setPersistence && window.firebase?.auth?.Auth?.Persistence) {
        const persistenceType = rememberMe
          ? window.firebase.auth.Auth.Persistence.LOCAL
          : window.firebase.auth.Auth.Persistence.SESSION;
        await auth.setPersistence(persistenceType);
      }

      await auth.signInWithEmailAndPassword(email, password);
      sessionStorage.setItem("justLoggedIn", "true");
      Swal().close();
    } catch (error) {
      Swal().fire("เข้าสู่ระบบไม่สำเร็จ", error.message, "error");
    }
  }

  async function googleLogin() {
    const provider = new window.firebase.auth.GoogleAuthProvider();
    try {
      if (auth.setPersistence && window.firebase?.auth?.Auth?.Persistence) {
        const persistenceType = rememberMe
          ? window.firebase.auth.Auth.Persistence.LOCAL
          : window.firebase.auth.Auth.Persistence.SESSION;
        await auth.setPersistence(persistenceType);
      }

      await auth.signInWithPopup(provider);
      sessionStorage.setItem("justLoggedIn", "true");
    } catch (error) {
      if (
        !["auth/popup-closed-by-user", "auth/cancelled-popup-request"].includes(
          error.code,
        )
      ) {
        Swal().fire("Login Error", error.message, "error");
      }
    }
  }

  async function resetPassword() {
    const result = await Swal().fire({
      title: "รีเซ็ตรหัสผ่าน",
      input: "email",
      inputLabel: "กรอกอีเมลที่ใช้สมัคร",
      inputPlaceholder: "example@email.com",
      showCancelButton: true,
      confirmButtonText: "ส่งลิงก์รีเซ็ต",
    });
    if (!result.isConfirmed || !result.value) return;
    try {
      await auth.sendPasswordResetEmail(result.value);
      Swal().fire("สำเร็จ", "ส่งลิงก์รีเซ็ตรหัสผ่านแล้ว", "success");
    } catch (error) {
      Swal().fire("เกิดข้อผิดพลาด", error.message, "error");
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
            autoComplete="email"
            name="email"
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
            autoComplete="current-password"
            name="password"
            required
          />
        </div>

        <div className="flex items-center justify-between mt-2">
          <Checkbox
            checked={rememberMe}
            onChange={(e) => setRememberMe(e.target.checked)}
            label="จำรหัสผ่าน"
          />
          <button
            type="button"
            onClick={resetPassword}
            className="text-[13px] font-bold text-blue-600 hover:text-blue-700 hover:underline transition-colors"
          >
            ลืมรหัสผ่าน?
          </button>
        </div>

        <button
          type="submit"
          className="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded-xl shadow-md shadow-blue-600/20 hover:shadow-lg hover:shadow-blue-600/30 transition-all active:scale-[0.98] mt-4"
        >
          เข้าสู่ระบบ
        </button>
      </form>

      <div className="flex items-center gap-4 my-5">
        <div className="h-px bg-slate-200 flex-1"></div>
        <span className="text-[13px] font-bold text-slate-400 uppercase tracking-wider">
          หรือเข้าสู่ระบบด้วย
        </span>
        <div className="h-px bg-slate-200 flex-1"></div>
      </div>

      <div className="grid grid-cols-1 gap-3">
        <button
          type="button"
          onClick={googleLogin}
          className="flex items-center justify-center gap-3 w-full py-3 px-4 bg-white border border-slate-300 hover:bg-slate-50 rounded-xl font-bold text-[15px] text-slate-700 transition-colors shadow-sm"
        >
          <img
            src="https://img.icons8.com/color/24/000000/google-logo.png"
            className="w-5 h-5"
            alt=""
          />
          Google
        </button>
      </div>

      <div className="mt-5 pt-5 border-t border-slate-100 flex flex-col items-center gap-2">
        <p className="text-center text-slate-600 font-medium text-[15px]">
          ยังไม่มีบัญชีใช่ไหม?{" "}
          <button
            type="button"
            onClick={() => setMode("register")}
            className="text-blue-600 font-bold hover:underline transition-all"
          >
            สมัครสมาชิกเลย
          </button>
        </p>

        <button
          type="button"
          onClick={() => navigate("admin")}
          className="flex items-center justify-center gap-2 text-slate-400 hover:text-blue-600 transition-colors font-bold text-sm py-2 px-4 rounded-lg hover:bg-blue-50"
        >
          <Icon name="fa-shield-halved" /> สำหรับเจ้าหน้าที่ (Admin)
        </button>
      </div>
    </>
  );

  if (hideLayout) return content;

  return (
    <SplitScreenAuthLayout
      title="ยินดีต้อนรับ"
      subtitle="กรอกอีเมลและรหัสผ่านเพื่อเข้าสู่ระบบ"
      rightTitle="จัดการข้อมูลนักเรียนและข้อสอบได้อย่างง่ายดาย"
      rightSubtitle="เข้าสู่ระบบเพื่อใช้งานกระดานควบคุมและตรวจข้อสอบทันที"
      isRegister={false}
    >
      {content}
    </SplitScreenAuthLayout>
  );
}
