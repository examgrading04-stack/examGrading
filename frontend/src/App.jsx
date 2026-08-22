import { useEffect, useMemo, useState, useRef } from "react";
import { AnswerKeyPage } from "./pages/AnswerKeyPage.jsx";
import { AnswerSheet } from "./pages/AnswerSheet.jsx";
import { AnalysisPage } from "./pages/AnalysisPage.jsx";
import { AdminPage } from "./pages/AdminPage.jsx";
import { AdminSettingsPage } from "./pages/AdminSettingsPage.jsx";
import { Dashboard } from "./pages/Dashboard.jsx";
import { ExamsPage } from "./pages/ExamsPage.jsx";
import { ReportsPage } from "./pages/ReportsPage.jsx";
import { ResultsPage } from "./pages/ResultsPage.jsx";
import { StudentsPage } from "./pages/StudentsPage.jsx";
import { SubjectsPage } from "./pages/SubjectsPage.jsx";
import { routeById, routes } from "./config/routes.js";
import { currentQuery, currentRouteId } from "./router/location.js";
import { bootFirebase } from "./services/firebaseClient.js";
import {
  AppLogo,
  Field,
  GhostButton,
  Icon,
  Input,
  PrimaryButton,
  Swal,
  API_BASE_URL,
  apiFetch,
  SplitScreenAuthLayout,
  PasswordInput,
} from "./ui.jsx";
import LoginPage from "./pages/LoginPage.jsx";
import RegisterPage from "./pages/RegisterPage.jsx";
import { Loader } from "./components/Loader.jsx";

function cleanProfileText(value) {
  return typeof value === "string" ? value.trim() : "";
}

function AvatarImage({ src, name, iconFallback = false }) {
  const cleanSrc = cleanProfileText(src);
  const fallbackName = cleanProfileText(name) || "U";
  const [failedSrc, setFailedSrc] = useState("");
  const shouldShowImage = cleanSrc && cleanSrc !== failedSrc;

  if (shouldShowImage) {
    return (
      <img
        key={cleanSrc}
        src={cleanSrc}
        alt=""
        referrerPolicy="no-referrer"
        className="w-full h-full object-cover"
        onError={() => setFailedSrc(cleanSrc)}
      />
    );
  }

  if (iconFallback) {
    return (
      <span className="text-slate-400">
        <Icon name="fa-user" />
      </span>
    );
  }

  return fallbackName.slice(0, 1).toUpperCase();
}

function ProfileModal({ user, profile, auth, api, onClose, onProfileSaved }) {
  const [displayName, setDisplayName] = useState(
    profile?.displayName || user.displayName || "",
  );
  const [photoURL, setPhotoURL] = useState(
    profile?.photoURL || user.photoURL || "",
  );
  const [uploading, setUploading] = useState(false);
  const fileInputRef = useRef(null);

  const [view, setView] = useState("PROFILE");
  const [currentPassword, setCurrentPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [changingPassword, setChangingPassword] = useState(false);
  const isGoogleUser =
    user?.providerData?.some((p) => p.providerId === "google.com") ||
    auth.currentUser?.providerData?.some((p) => p.providerId === "google.com");

  function resetPasswordForms() {
    setCurrentPassword("");
    setNewPassword("");
    setConfirmPassword("");
    setView("PROFILE");
  }

  function handleCloseModal() {
    resetPasswordForms();
    onClose();
  }

  async function handleVerifyPassword(e) {
    e.preventDefault();
    if (!currentPassword) {
      Swal().fire("กรุณากรอกรหัสผ่านปัจจุบัน", "", "warning");
      return;
    }
    setChangingPassword(true);
    try {
      const baseUrl =
        typeof API_BASE_URL !== "undefined" && API_BASE_URL
          ? API_BASE_URL
          : "http://127.0.0.1:8000";
      const res = await fetch(`${baseUrl}/api/auth/login`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email: user.email, password: currentPassword }),
      });
      if (!res.ok) {
        throw new Error("รหัสผ่านไม่ถูกต้อง");
      }
      setView("SET_NEW_PASSWORD");
    } catch (error) {
      console.error(error);
      Swal().fire(
        "รหัสผ่านไม่ถูกต้อง",
        "กรุณาตรวจสอบรหัสผ่านปัจจุบันของคุณอีกครั้ง",
        "error",
      );
    } finally {
      setChangingPassword(false);
    }
  }

  async function handleChangePassword(e) {
    e.preventDefault();
    if (!newPassword || !confirmPassword) {
      Swal().fire(
        "ข้อมูลไม่ครบ",
        "กรุณากรอกรหัสผ่านใหม่และยืนยันรหัสผ่าน",
        "warning",
      );
      return;
    }
    if (currentPassword && newPassword === currentPassword) {
      Swal().fire(
        "รหัสผ่านซ้ำซ้อน",
        "ไม่สามารถตั้งรหัสผ่านซ้ำกับรหัสผ่านเดิมได้ กรุณาตั้งรหัสผ่านใหม่",
        "warning",
      );
      return;
    }
    if (newPassword !== confirmPassword) {
      Swal().fire(
        "รหัสผ่านไม่ตรงกัน",
        "กรุณายืนยันรหัสผ่านใหม่ให้ถูกต้อง",
        "warning",
      );
      return;
    }
    if (newPassword.length < 6) {
      Swal().fire(
        "รหัสผ่านสั้นเกินไป",
        "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร",
        "warning",
      );
      return;
    }
    setChangingPassword(true);
    try {
      await window.firebase
        .firestore()
        .collection("users")
        .doc(user.email)
        .update({
          password: newPassword,
        });
      Swal().fire("สำเร็จ", "ตั้งรหัสผ่านใหม่เรียบร้อยแล้ว", "success");
      setCurrentPassword("");
      setNewPassword("");
      setConfirmPassword("");
      setView("PROFILE");
    } catch (error) {
      console.error(error);
      Swal().fire(
        "เกิดข้อผิดพลาด",
        error.message || "ไม่สามารถเปลี่ยนรหัสผ่านได้",
        "error",
      );
    } finally {
      setChangingPassword(false);
    }
  }

  async function save(e) {
    e.preventDefault();
    const nextDisplayName = cleanProfileText(displayName);
    const nextPhotoURL = cleanProfileText(photoURL);
    await auth.currentUser.updateProfile({
      displayName: nextDisplayName,
      photoURL: nextPhotoURL,
    });
    await auth.currentUser.reload();
    await api.set(`profiles/${user.email}`, {
      displayName: nextDisplayName,
      photoURL: nextPhotoURL,
      email: user.email,
      lastUpdated:
        window.firebase?.firestore?.FieldValue?.serverTimestamp?.() ||
        new Date().toISOString(),
    });
    onProfileSaved?.({
      displayName: nextDisplayName,
      photoURL: nextPhotoURL,
      email: user.email,
    });
    Swal().fire("สำเร็จ", "อัปเดตโปรไฟล์เรียบร้อยแล้ว", "success");
    onClose();
  }

  async function handleFileUpload(e) {
    const file = e.target.files[0];
    if (!file) return;

    setUploading(true);
    const formData = new FormData();
    formData.append("file", file);
    formData.append("user_email", user.email);

    try {
      const res = await apiFetch("/api/upload-profile-picture", {
        method: "POST",
        body: formData,
      });
      const data = await res.json();
      if (data.url) {
        let finalUrl = data.url;
        if (
          finalUrl.startsWith("http://localhost:8000") &&
          API_BASE_URL !== "http://localhost:8000"
        ) {
          finalUrl = finalUrl.replace("http://localhost:8000", API_BASE_URL);
        }
        setPhotoURL(finalUrl);
      }
    } catch (err) {
      console.error(err);
      Swal().fire("ผิดพลาด", "ไม่สามารถอัปโหลดรูปภาพได้", "error");
    } finally {
      setUploading(false);
      if (fileInputRef.current) fileInputRef.current.value = null;
    }
  }

  if (view === "VERIFY_PASSWORD") {
    return (
      <div className="fixed inset-0 z-50 bg-slate-950/50 flex flex-col items-center justify-center p-4 overflow-y-auto">
        <form
          onSubmit={handleVerifyPassword}
          className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm w-full max-w-md space-y-4"
        >
          <div className="flex items-center justify-between">
            <h3 className="font-extrabold text-lg">ยืนยันรหัสผ่านเดิม</h3>
            <GhostButton
              type="button"
              className="py-2 px-3"
              onClick={resetPasswordForms}
            >
              <Icon name="fa-arrow-left" />
            </GhostButton>
          </div>
          <p className="text-sm text-slate-500">
            เพื่อความปลอดภัย
            กรุณากรอกรหัสผ่านปัจจุบันของคุณเพื่อยืนยันตัวตนก่อนเปลี่ยนรหัสผ่าน
          </p>
          <Field label="รหัสผ่านปัจจุบัน">
            <PasswordInput
              value={currentPassword}
              onChange={(e) => setCurrentPassword(e.target.value)}
              placeholder="รหัสผ่านปัจจุบัน"
              autoFocus
            />
          </Field>
          <PrimaryButton className="w-full" disabled={changingPassword}>
            <Icon name={changingPassword ? "fa-spinner fa-spin" : "fa-check"} />{" "}
            ยืนยัน
          </PrimaryButton>
        </form>
      </div>
    );
  }

  if (view === "SET_NEW_PASSWORD") {
    return (
      <div className="fixed inset-0 z-50 bg-slate-950/50 flex flex-col items-center justify-center p-4 overflow-y-auto">
        <form
          onSubmit={handleChangePassword}
          className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm w-full max-w-md space-y-4"
        >
          <div className="flex items-center justify-between">
            <h3 className="font-extrabold text-lg">ตั้งรหัสผ่านใหม่</h3>
            <GhostButton
              type="button"
              className="py-2 px-3"
              onClick={resetPasswordForms}
            >
              <Icon name="fa-arrow-left" />
            </GhostButton>
          </div>
          <Field label="รหัสผ่านใหม่">
            <PasswordInput
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              placeholder="รหัสผ่านใหม่อย่างน้อย 6 ตัวอักษร"
            />
          </Field>
          <Field label="ยืนยันรหัสผ่านใหม่">
            <PasswordInput
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
              placeholder="กรอกรหัสผ่านใหม่อีกครั้ง"
            />
          </Field>
          <PrimaryButton className="w-full" disabled={changingPassword}>
            <Icon name={changingPassword ? "fa-spinner fa-spin" : "fa-key"} />{" "}
            เปลี่ยนรหัสผ่าน
          </PrimaryButton>
        </form>
      </div>
    );
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/50 flex flex-col items-center justify-center p-4 overflow-y-auto">
      <div className="bg-white rounded-lg border border-slate-200 shadow-sm w-full max-w-md my-8">
        <form onSubmit={save} className="p-6 space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="font-extrabold text-lg">ตั้งค่าโปรไฟล์</h3>
            <GhostButton
              type="button"
              className="py-2 px-3"
              onClick={handleCloseModal}
            >
              <Icon name="fa-xmark" />
            </GhostButton>
          </div>

          <div className="flex flex-col items-center gap-3 py-4 bg-slate-50 rounded-lg border border-dashed border-slate-200">
            <div className="w-24 h-24 rounded-full bg-slate-50 from-blue-100 to-emerald-100 flex items-center justify-center text-blue-700 font-bold text-3xl overflow-hidden shadow-sm border-4 border-white">
              <AvatarImage
                src={photoURL}
                name={displayName || user.email}
                iconFallback
              />
            </div>
            <div className="text-center">
              <p className="text-sm font-bold text-slate-700">
                รูปตัวอย่างโปรไฟล์
              </p>
              <p className="text-xs text-slate-500">
                แสดงผลเมื่อใส่ URL ที่ถูกต้อง
              </p>
            </div>
          </div>

          <Field label="ชื่อที่แสดง">
            <Input
              value={displayName}
              onChange={(e) => setDisplayName(e.target.value)}
              placeholder="เช่น อาจารย์สมชาย ใจดี"
            />
          </Field>
          <Field label="รูปโปรไฟล์ (URL หรือ อัปโหลดไฟล์)">
            <div className="flex gap-2">
              <Input
                value={photoURL}
                onChange={(e) => setPhotoURL(e.target.value)}
                placeholder="https://example.com/photo.jpg"
                className="flex-1"
              />
              <input
                type="file"
                accept="image/*"
                className="hidden"
                ref={fileInputRef}
                onChange={handleFileUpload}
              />
              <GhostButton
                type="button"
                onClick={() => fileInputRef.current?.click()}
                disabled={uploading}
                className="shrink-0"
                title="อัปโหลดรูปภาพ"
              >
                {uploading ? (
                  <Icon name="fa-spinner fa-spin" />
                ) : (
                  <Icon name="fa-upload" />
                )}
              </GhostButton>
            </div>
          </Field>
          <PrimaryButton className="w-full">
            <Icon name="fa-floppy-disk" /> บันทึกโปรไฟล์
          </PrimaryButton>
        </form>

        {!isGoogleUser && (
          <div className="border-t border-slate-100 p-6 space-y-4 bg-slate-50 rounded-b-lg">
            <h3 className="font-extrabold text-md text-slate-800">
              ความปลอดภัย
            </h3>
            <GhostButton
              type="button"
              variant="primary"
              className="w-full border border-blue-200 bg-white"
              onClick={() => setView("VERIFY_PASSWORD")}
            >
              <Icon name="fa-key" /> เปลี่ยนรหัสผ่าน
            </GhostButton>
          </div>
        )}
      </div>
    </div>
  );
}

function Shell({
  user,
  profile,
  auth,
  routeId,
  query,
  navigate,
  data,
  api,
  refresh,
  onProfileSaved,
}) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const route = routeById[routeId] || routeById.dashboard;
  const displayName = user.displayName || user.email || "อาจารย์ผู้สอน";
  const effectiveDisplayName = profile?.displayName || displayName;
  const photoURL = profile?.photoURL || user.photoURL || "";
  const avatar = <AvatarImage src={photoURL} name={effectiveDisplayName} />;

  function renderPage() {
    const props = {
      data,
      api,
      refresh,
      navigate,
      query,
      userEmail: user.email,
      userName: effectiveDisplayName,
    };
    if (routeId === "dashboard") return <Dashboard {...props} />;
    if (routeId === "subjects") return <SubjectsPage {...props} />;
    if (routeId === "students") return <StudentsPage {...props} />;
    if (routeId === "exams") return <ExamsPage {...props} />;
    if (routeId === "answer-key") return <AnswerKeyPage {...props} />;
    if (routeId === "results") return <ResultsPage {...props} />;
    if (routeId === "analysis") return <AnalysisPage {...props} />;
    if (routeId === "reports") return <ReportsPage {...props} />;
    if (routeId === "answer-sheet") return <AnswerSheet />;
    if (routeId === "admin-settings") return <AdminSettingsPage user={user} />;
    return <Dashboard {...props} />;
  }

  async function signOut() {
    const res = await Swal().fire({
      title: "ยืนยันออกจากระบบ?",
      text: "คุณต้องการออกจากระบบใช่หรือไม่",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ออกจากระบบ",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#ef4444",
    });

    if (res.isConfirmed) {
      setIsLoggingOut(true);
      await api?.log("User signed out");
      setTimeout(async () => {
        await auth.signOut();
        setIsLoggingOut(false);
      }, 1000);
    }
  }

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50 relative">
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-40 lg:hidden"
        />
      )}
      <aside
        className={`fixed inset-y-0 left-0 w-72 bg-white border-r border-slate-200 shadow-sm flex flex-col z-50 transition-transform duration-300 ${sidebarOpen ? "translate-x-0" : "-translate-x-full"} lg:translate-x-0 lg:static lg:shadow-none lg:z-20`}
      >
        <button
          onClick={() => setSidebarOpen(false)}
          className={`lg:hidden absolute top-4 -right-12 w-10 h-10 flex items-center justify-center rounded-full bg-slate-900/50 text-white hover:bg-slate-900/70 backdrop-blur-md transition-all duration-300 shadow-sm ${sidebarOpen ? "opacity-100" : "opacity-0 pointer-events-none"}`}
        >
          <Icon name="fa-xmark" className="text-xl" />
        </button>
        <div className="p-4 px-6 border-b border-slate-100 flex items-center h-[73px]">
          <div className="flex items-center gap-3 w-full">
            <AppLogo compact />
            <div className="flex flex-col justify-center">
              <span className="text-xl font-black tracking-tighter text-slate-800 leading-none">
                Exam<span className="text-indigo-600">Grading</span>
              </span>
              <span className="text-[10px] font-bold text-slate-400 tracking-[0.15em] uppercase mt-1">
                Management
              </span>
            </div>
          </div>
        </div>
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {routes
            .filter((item) => !item.hidden)
            .filter((item) => !item.adminOnly || user?.role === "admin")
            .map((item) => (
              <button
                key={item.id}
                onClick={() => {
                  navigate(item.id);
                  setSidebarOpen(false);
                }}
                className={`group w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-all duration-200 ${
                  routeId === item.id
                    ? "bg-indigo-50 text-indigo-700 shadow-[0_1px_2px_rgba(0,0,0,0.02)] ring-1 ring-indigo-100/50"
                    : "text-slate-600 hover:bg-slate-50 hover:text-slate-900"
                }`}
              >
                <div
                  className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors ${
                    routeId === item.id
                      ? "bg-indigo-600 text-white shadow-md shadow-indigo-200/50"
                      : "bg-slate-100 text-slate-500 group-hover:bg-slate-200 group-hover:text-slate-700"
                  }`}
                >
                  <Icon name={item.icon} className="text-[13px]" />
                </div>
                <span
                  className={`text-[15px] ${
                    routeId === item.id ? "font-bold" : "font-medium"
                  }`}
                >
                  {item.label}
                </span>
              </button>
            ))}
        </nav>
        <div className="p-4 border-t border-slate-100 bg-slate-50/50">
          {user?.role === "admin" ? (
            <button
              onClick={() => navigate("admin")}
              className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl text-sm font-bold text-indigo-700 bg-white border border-indigo-100 shadow-sm hover:bg-indigo-50 transition-colors"
            >
              <Icon name="fa-user-shield" /> โหมดผู้ดูแลระบบ
            </button>
          ) : (
            <button
              onClick={signOut}
              className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl text-sm font-bold text-rose-600 bg-white border border-rose-100 shadow-sm hover:bg-rose-50 hover:border-rose-200 transition-colors"
            >
              <Icon name="fa-right-from-bracket" /> ออกจากระบบ
            </button>
          )}
        </div>
      </aside>
      <main className="flex-1 flex flex-col h-screen overlay-y relative">
        <header className="bg-white border-b border-slate-200 px-6 sm:px-10 shrink-0 sticky top-0 z-30 h-[73px] flex items-center w-full">
          <div className="flex items-center justify-between w-full">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden w-10 h-10 flex items-center justify-center rounded-lg bg-slate-100 text-slate-600 hover:bg-slate-200 transition-colors mr-2"
              >
                <Icon name="fa-bars" />
              </button>
              {route.icon && (
                <div className="hidden sm:flex w-10 h-10 rounded-md bg-blue-50 text-blue-600 items-center justify-center border border-blue-100/50">
                  <Icon name={route.icon} />
                </div>
              )}
              <div>
                <h2 className="text-xl sm:text-2xl font-black text-slate-800 leading-tight">
                  {route.label}
                </h2>
              </div>
            </div>

            <button
              onClick={() => setProfileOpen(true)}
              className="flex items-center gap-3 group"
            >
              <span className="hidden sm:flex flex-col items-end">
                <span className="text-sm font-semibold text-slate-800 leading-none group-hover:text-blue-600 transition-colors">
                  {effectiveDisplayName}
                </span>
                <span className="text-xs text-slate-500 mt-1">
                  ตั้งค่าโปรไฟล์
                </span>
              </span>
              <span className="w-10 h-10 bg-slate-100 rounded-full flex items-center justify-center text-slate-600 font-bold overflow-hidden border border-slate-200">
                {avatar}
              </span>
            </button>
          </div>
        </header>
        <div className="p-4 lg:p-8 max-w-7xl mx-auto w-full">
          {renderPage()}
        </div>
      </main>
      {profileOpen && (
        <ProfileModal
          user={user}
          profile={profile}
          auth={auth}
          api={api}
          onClose={() => setProfileOpen(false)}
          onProfileSaved={onProfileSaved}
        />
      )}
      {isLoggingOut && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-900/80 backdrop-blur-sm transition-opacity">
          <Loader />
        </div>
      )}
    </div>
  );
}

export default function App() {
  const [firebase, setFirebase] = useState(null);
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [authMode, setAuthMode] = useState(
    currentRouteId() === "register" ? "register" : "login",
  );
  const [routeId, setRouteId] = useState(currentRouteId());
  const [query, setQuery] = useState(currentQuery());
  const [loading, setLoading] = useState(true);
  const [data, setData] = useState({
    subjects: [],
    sections: [],
    students: [],
    exams: [],
    results: [],
  });
  const [initialLoginHandled, setInitialLoginHandled] = useState(false);

  useEffect(() => {
    const services = bootFirebase();
    setFirebase(services);
    let userDocInterval = null;

    const unsubscribe = services.auth.onAuthStateChanged(async (nextUser) => {
      if (userDocInterval) {
        clearInterval(userDocInterval);
        userDocInterval = null;
      }

      if (nextUser) {
        try {
          const userEmail =
            nextUser.email || nextUser.username || nextUser.id || nextUser.uid;

          if (userEmail) {
            userDocInterval = setInterval(async () => {
              try {
                const snapshot = await services.db
                  .collection("users")
                  .doc(userEmail)
                  .get();
                if (snapshot.exists && snapshot.data().status === "suspended") {
                  if (userDocInterval) {
                    clearInterval(userDocInterval);
                    userDocInterval = null;
                  }
                  await services.auth.signOut();
                  setTimeout(() => {
                    Swal().fire(
                      "ถูกระงับการใช้งาน",
                      "บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ",
                      "error",
                    );
                  }, 500);
                  setUser(null);
                  setProfile(null);
                  setLoading(false);
                }
              } catch (e) {
                // Ignore fetch errors during polling
              }
            }, 5000);
          }

          const userDoc = await services.db
            .collection("users")
            .doc(userEmail)
            .get();
          if (userDoc.exists && userDoc.data().status === "suspended") {
            await services.auth.signOut();
            setTimeout(() => {
              Swal().fire(
                "เข้าสู่ระบบไม่สำเร็จ",
                "บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ",
                "error",
              );
            }, 500);
            setUser(null);
            setProfile(null);
            setLoading(false);
            return;
          }
          let role = userDoc.data()?.role || nextUser.role;
          if (!role || role !== "admin") {
            const adminEmail =
              nextUser.email || nextUser.username || nextUser.id;
            const adminDoc = await services.db
              .collection("Admin")
              .doc(adminEmail)
              .get();
            if (adminDoc.exists) {
              role = "admin";
            } else {
              const adminsDoc = await services.db
                .collection("admins")
                .doc(adminEmail)
                .get();
              if (adminsDoc.exists) role = "admin";
            }
          }

          if (role === "admin") {
            await services.auth.signOut();
            Swal().fire(
              "ไม่อนุญาตให้เข้าสู่ระบบที่นี่",
              "บัญชีผู้ดูแลระบบ กรุณาเข้าสู่ระบบผ่านปุ่ม 'สำหรับเจ้าหน้าที่' เท่านั้น",
              "error",
            );
            setUser(null);
            setProfile(null);
            setLoading(false);
            return;
          }

          const userData = { ...nextUser, role };
          setUser(userData);
          setProfile(await loadProfile(services, userData));
          await loadData(services, userData);
        } catch (error) {
          console.error("Error checking user status:", error);
        }
      } else {
        setUser(null);
        setProfile(null);
        setInitialLoginHandled(false);
      }
      setLoading(false);
      if (nextUser) await loadData(services, nextUser);
    });
    return () => {
      if (userDocInterval) clearInterval(userDocInterval);
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    const handler = () => {
      setRouteId(currentRouteId());
      setQuery(currentQuery());
    };
    window.addEventListener("popstate", handler);
    return () => window.removeEventListener("popstate", handler);
  }, []);

  useEffect(() => {
    const publicRoutes = ["login", "register", "answer-sheet", "admin"];
    const authOnlyRedirectRoutes = ["login", "register"];
    if (user && authOnlyRedirectRoutes.includes(routeId)) {
      // เข้าสู่ระบบแล้ว → ไปหน้าหลัก
      if (user.role === "admin") {
        navigate("admin");
      } else {
        navigate("dashboard");
      }
    } else if (!user && !loading && !publicRoutes.includes(routeId)) {
      // ออกจากระบบ → กลับไปหน้า login พร้อมเคลียร์ URL
      window.history.pushState({}, "", "/");
      setRouteId("login");
      setQuery({});
    }
  }, [user, loading, routeId]);

  async function getDocs(services, currentUser, collectionPath) {
    const snapshot = await services.db
      .collection("users")
      .doc(currentUser.email)
      .collection(collectionPath)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  async function loadProfile(services, currentUser) {
    if (!services || !currentUser?.email) return null;
    const doc = await services.db
      .collection("users")
      .doc(currentUser.email)
      .collection("profiles")
      .doc(currentUser.email)
      .get();

    if (doc.exists) {
      return { email: currentUser.email, ...doc.data() };
    }

    return {
      email: currentUser.email,
      displayName: currentUser.displayName || "",
      photoURL: currentUser.photoURL || "",
    };
  }

  async function loadData(services = firebase, currentUser = user) {
    if (!services || !currentUser) return;
    const subjects = await getDocs(services, currentUser, "subjects");
    const sectionsSnapshots = await Promise.all(
      subjects.map((subject) =>
        services.db
          .collection("users")
          .doc(currentUser.email)
          .collection("subjects")
          .doc(subject.id)
          .collection("sections")
          .get()
          .then((snapshot) => ({ subject, snapshot })),
      ),
    );
    const sections = [];
    sectionsSnapshots.forEach(({ subject, snapshot }) => {
      snapshot.forEach((doc) =>
        sections.push({
          id: `${subject.id}_${doc.id}`,
          realId: doc.id,
          subject: subject.id,
          ...doc.data(),
        }),
      );
    });
    const [students, exams, results] = await Promise.all([
      getDocs(services, currentUser, "students"),
      getDocs(services, currentUser, "exams"),
      getDocs(services, currentUser, "results"),
    ]);
    const cachedAnswerKeys = JSON.parse(
      localStorage.getItem("answerKeys") || "{}",
    );
    setData({
      subjects,
      sections,
      students,
      exams: exams.map((exam) => ({
        ...exam,
        answerKey:
          exam.answerKey || exam.answerKeys || cachedAnswerKeys[exam.id] || {},
      })),
      results,
    });
  }

  const api = useMemo(() => {
    if (!firebase || !user) return null;
    const root = firebase.db.collection("users").doc(user.email);
    async function log(activity, metadata = {}) {
      try {
        const docRef = firebase.db.collection("systemLogs").doc();
        await docRef.set({
          logid: docRef.id,
          activity,
          datetime: window.firebase.firestore.FieldValue.serverTimestamp(),
          user: user.email,
          userEmail: user.email,
          displayName: user.displayName || "",
          role: "Teacher",
          ...metadata,
        });
      } catch (error) {
        console.warn("Could not write system log", error);
      }
    }

    return {
      log,
      async deleteQuerySnapshot(snapshot) {
        if (snapshot.empty) return 0;
        const chunks = [];
        let current = [];
        snapshot.docs.forEach((doc) => {
          current.push(doc.ref);
          if (current.length === 450) {
            chunks.push(current);
            current = [];
          }
        });
        if (current.length) chunks.push(current);

        let deleted = 0;
        for (const refs of chunks) {
          const batch = firebase.db.batch();
          refs.forEach((ref) => batch.delete(ref));
          await batch.commit();
          deleted += refs.length;
        }
        return deleted;
      },
      async removeSubjectCascade(subjectId) {
        const subjectDoc = await root
          .collection("subjects")
          .doc(subjectId)
          .get();
        const subjectCode = String(subjectDoc.data()?.code || subjectId);

        const sectionSnapshot = await root
          .collection("subjects")
          .doc(subjectId)
          .collection("sections")
          .get();

        const sectionIds = sectionSnapshot.docs.map(
          (doc) => `${subjectId}_${doc.id}`,
        );
        await this.deleteQuerySnapshot(sectionSnapshot);

        const studentsSnapshot = await root.collection("students").get();
        const studentDocs = studentsSnapshot.docs.filter((doc) => {
          const classId = String(doc.data()?.class || "");
          return (
            classId.startsWith(`${subjectId}_`) ||
            classId.startsWith(`${subjectCode}_`) ||
            classId === subjectId ||
            classId === subjectCode ||
            sectionIds.includes(classId)
          );
        });
        if (studentDocs.length) {
          await this.deleteQuerySnapshot({ docs: studentDocs, empty: false });
        }

        await root.collection("subjects").doc(subjectId).delete();
      },
      async removeSectionCascade(subjectId, sectionId) {
        const subjectDoc = await root
          .collection("subjects")
          .doc(subjectId)
          .get();
        const subjectCode = String(subjectDoc.data()?.code || subjectId);
        const sectionDoc = await root
          .collection("subjects")
          .doc(subjectId)
          .collection("sections")
          .doc(sectionId)
          .get();
        const sectionSec = String(sectionDoc.data()?.sec || sectionId);
        const sectionFullId = `${subjectId}_${sectionId}`;
        const legacySectionFullId = `${subjectCode}_${sectionSec}`;

        const studentsSnapshot = await root.collection("students").get();
        const studentDocs = studentsSnapshot.docs.filter((doc) => {
          const classId = String(doc.data()?.class || "");
          return (
            classId === sectionFullId ||
            classId === legacySectionFullId ||
            classId === sectionSec
          );
        });
        if (studentDocs.length) {
          await this.deleteQuerySnapshot({ docs: studentDocs, empty: false });
        }

        await root
          .collection("subjects")
          .doc(subjectId)
          .collection("sections")
          .doc(sectionId)
          .delete();
      },
      async add(collectionPath, payload) {
        const docRef = await root.collection(collectionPath).add(payload);
        await log(`User added ${collectionPath}`, {
          action: "add",
          collectionPath,
          targetId: docRef.id,
        });
        return docRef.id;
      },
      async set(path, payload) {
        await root
          .collection(path.split("/").slice(0, -1).join("/"))
          .doc(path.split("/").at(-1))
          .set(payload, { merge: true });
        await log(`User saved ${path}`, {
          action: "set",
          collectionPath: path.split("/").slice(0, -1).join("/"),
          targetId: path.split("/").at(-1),
        });
      },
      async update(collectionPath, id, payload) {
        await root.collection(collectionPath).doc(id).update(payload);
        await log(`User updated ${collectionPath}/${id}`, {
          action: "update",
          collectionPath,
          targetId: id,
        });
      },
      async remove(collectionPath, id) {
        if (collectionPath === "subjects") {
          await this.removeSubjectCascade(id);
        } else if (
          collectionPath.startsWith("subjects/") &&
          collectionPath.endsWith("/sections")
        ) {
          const parts = collectionPath.split("/");
          const subjectId = parts[1];
          await this.removeSectionCascade(subjectId, id);
        } else {
          await root.collection(collectionPath).doc(id).delete();
        }
        await log(`User deleted ${collectionPath}/${id}`, {
          action: "remove",
          collectionPath,
          targetId: id,
        });
      },
    };
  }, [firebase, user]);

  useEffect(() => {
    if (user && !initialLoginHandled) {
      setInitialLoginHandled(true);
      if (api && sessionStorage.getItem("justLoggedIn")) {
        sessionStorage.removeItem("justLoggedIn");
        api.log("User signed in");
      }
      if (
        user.role === "admin" &&
        (routeId === "dashboard" ||
          routeId === "login" ||
          routeId === "register" ||
          routeId === "")
      ) {
        navigate("admin");
      }
    }
  }, [user, initialLoginHandled, routeId, api]);

  async function refresh(message) {
    await loadData();
    if (message)
      Swal().fire({
        icon: "success",
        title: message,
        timer: 1300,
        showConfirmButton: false,
      });
  }

  function navigate(nextRouteId, nextQuery = {}) {
    const route = routeById[nextRouteId] || routeById.dashboard;
    const params = new URLSearchParams(nextQuery);
    const url = `${route.path}${params.toString() ? `?${params}` : ""}`;
    window.history.pushState({}, "", url);
    setRouteId(route.id);
    setQuery(nextQuery);
  }

  if (loading || !firebase) {
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50">
        <Loader />
      </div>
    );
  }

  async function signOut() {
    await api?.log("User signed out");
    await firebase.auth.signOut();
  }

  if (routeId === "admin") {
    if (user && user.role !== "admin") {
      return (
        <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50 text-slate-800 p-6 text-center">
          <Icon
            name="fa-shield-halved"
            className="text-5xl text-red-500 mb-4"
          />
          <h2 className="text-2xl font-bold mb-4">
            คุณไม่มีสิทธิ์เข้าถึงหน้านี้
          </h2>
          <p className="mb-6 text-slate-500">
            หน้านี้สงวนไว้สำหรับผู้ดูแลระบบเท่านั้น
          </p>
          <PrimaryButton onClick={() => navigate("/")}>
            กลับสู่หน้าหลัก
          </PrimaryButton>
        </div>
      );
    }
    return (
      <AdminPage
        firebase={firebase}
        user={user}
        signOut={signOut}
        navigate={navigate}
      />
    );
  }

  if (!user) {
    const isRegister = authMode === "register";
    return (
      <SplitScreenAuthLayout
        isRegister={isRegister}
        title={isRegister ? "สร้างบัญชีผู้ใช้งาน" : "ยินดีต้อนรับ"}
        subtitle={
          isRegister
            ? "กรอกข้อมูลของคุณเพื่อเริ่มต้นใช้งานระบบ"
            : "กรุณาเข้าสู่ระบบด้วยบัญชีผู้ใช้งานของคุณ"
        }
        rightTitle={
          isRegister ? "เริ่มต้นใช้งานระบบประเมินผล" : "ระบบตรวจข้อสอบอัตโนมัติ"
        }
        rightSubtitle={
          isRegister
            ? "สมัครสมาชิกวันนี้เพื่อจัดการห้องเรียนและการสอบอย่างมืออาชีพ"
            : "รวดเร็ว แม่นยำ และปลอดภัยสำหรับผู้สอนทุกคน"
        }
      >
        <div
          className={`transition-opacity duration-300 ${!isRegister ? "opacity-100 block" : "opacity-0 hidden"}`}
        >
          {!isRegister && (
            <LoginPage
              setMode={setAuthMode}
              auth={firebase.auth}
              navigate={navigate}
              hideLayout={true}
            />
          )}
        </div>
        <div
          className={`transition-opacity duration-300 ${isRegister ? "opacity-100 block" : "opacity-0 hidden"}`}
        >
          {isRegister && (
            <RegisterPage
              setMode={setAuthMode}
              auth={firebase.auth}
              navigate={navigate}
              hideLayout={true}
            />
          )}
        </div>
      </SplitScreenAuthLayout>
    );
  }

  return (
    <Shell
      user={user}
      profile={profile}
      auth={firebase.auth}
      routeId={routeId}
      query={query}
      navigate={navigate}
      data={data}
      api={api}
      refresh={refresh}
      onProfileSaved={(nextProfile) =>
        setProfile((currentProfile) => ({
          ...(currentProfile || {}),
          ...nextProfile,
        }))
      }
    />
  );
}
