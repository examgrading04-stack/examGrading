import { useEffect, useMemo, useState } from "react";
import { AnswerKeyPage } from "./pages/AnswerKeyPage.jsx";
import { AnswerSheet } from "./pages/AnswerSheet.jsx";
import { AnalysisPage } from "./pages/AnalysisPage.jsx";
import { Dashboard } from "./pages/Dashboard.jsx";
import { ExamsPage } from "./pages/ExamsPage.jsx";
import { ReportsPage } from "./pages/ReportsPage.jsx";
import { ResultsPage } from "./pages/ResultsPage.jsx";
import { StudentsPage } from "./pages/StudentsPage.jsx";
import { SubjectsPage } from "./pages/SubjectsPage.jsx";
import { firebaseConfig } from "./config/firebase.js";
import { legacyRouteMap, routeById, routes } from "./config/routes.js";
import {
  AppLogo,
  Field,
  GhostButton,
  Icon,
  Input,
  PrimaryButton,
  Swal,
} from "./ui.jsx";

function bootFirebase() {
  if (!window.firebase) {
    throw new Error("Firebase SDK ยังโหลดไม่สำเร็จ");
  }
  if (!window.firebase.apps.length) {
    window.firebase.initializeApp(firebaseConfig);
  }
  return {
    auth: window.firebase.auth(),
    db: window.firebase.firestore(),
  };
}

function currentRouteId() {
  const pathname = window.location.pathname.split("/").pop();
  if (pathname === "login.html" || pathname === "login") return "login";
  if (pathname === "register.html" || pathname === "register")
    return "register";
  if (!pathname || pathname === "index.html") return "dashboard";
  if (legacyRouteMap[pathname]) return legacyRouteMap[pathname];
  const clean = window.location.pathname.replace(/\/$/, "");
  const found = routes.find(
    (route) => route.path === clean || clean.endsWith(route.path),
  );
  return found?.id || "dashboard";
}

function currentQuery() {
  return Object.fromEntries(
    new URLSearchParams(window.location.search).entries(),
  );
}

function AuthCard({ mode, setMode, auth }) {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirm, setConfirm] = useState("");
  const isRegister = mode === "register";

  async function submit(event) {
    event.preventDefault();
    if (isRegister && password !== confirm) {
      Swal().fire("รหัสผ่านไม่ตรงกัน", "กรุณาตรวจสอบรหัสผ่านอีกครั้ง", "error");
      return;
    }
    if (isRegister && password.length < 6) {
      Swal().fire(
        "รหัสผ่านสั้นเกินไป",
        "รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร",
        "error",
      );
      return;
    }
    Swal().fire({
      title: isRegister ? "กำลังสร้างบัญชี..." : "กำลังเข้าสู่ระบบ...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    try {
      if (isRegister)
        await auth.createUserWithEmailAndPassword(email, password);
      else await auth.signInWithEmailAndPassword(email, password);
      Swal().close();
    } catch (error) {
      Swal().fire(
        isRegister ? "สมัครสมาชิกไม่สำเร็จ" : "เข้าสู่ระบบไม่สำเร็จ",
        error.message,
        "error",
      );
    }
  }

  async function googleLogin() {
    const provider = new window.firebase.auth.GoogleAuthProvider();
    try {
      await auth.signInWithPopup(provider);
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

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-sky-50 via-indigo-50 to-white p-4">
      <div className="bg-white/90 backdrop-blur-xl p-8 sm:p-10 rounded-3xl shadow-[0_8px_30px_rgb(0,0,0,0.05)] border border-white/70 w-full max-w-md">
        <div className="text-center mb-8">
          <div className="flex justify-center mb-4">
            <AppLogo />
          </div>
          <h1 className="text-2xl font-extrabold text-slate-800 tracking-tight">
            {isRegister ? "สร้างบัญชีผู้ใช้งาน" : "ระบบตรวจและวิเคราะห์ข้อสอบ"}
          </h1>
          <p className="text-slate-500 mt-2 font-medium">
            {isRegister
              ? "กรอกข้อมูลเพื่อเริ่มต้นใช้งานระบบ"
              : "ลงชื่อเข้าใช้งานระบบ"}
          </p>
        </div>

        <form className="space-y-4" onSubmit={submit}>
          <Field label="อีเมล (Email)">
            <Input
              type="email"
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              placeholder="example@email.com"
              required
            />
          </Field>
          <Field label="รหัสผ่าน (Password)">
            <Input
              type="password"
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              placeholder="กรอกรหัสผ่าน"
              required
            />
          </Field>
          {isRegister && (
            <Field label="ยืนยันรหัสผ่าน">
              <Input
                type="password"
                value={confirm}
                onChange={(event) => setConfirm(event.target.value)}
                placeholder="ยืนยันรหัสผ่านอีกครั้ง"
                required
              />
            </Field>
          )}
          {!isRegister && (
            <button
              type="button"
              onClick={resetPassword}
              className="text-blue-600 text-sm font-semibold hover:underline"
            >
              ลืมรหัสผ่าน?
            </button>
          )}
          <PrimaryButton type="submit" className="w-full">
            {isRegister ? "ลงทะเบียนสมาชิก" : "เข้าสู่ระบบ"}
          </PrimaryButton>
        </form>

        {!isRegister && (
          <GhostButton
            type="button"
            onClick={googleLogin}
            className="w-full mt-4"
          >
            <img
              src="https://img.icons8.com/color/24/000000/google-logo.png"
              className="w-5 h-5"
              alt=""
            />{" "}
            เข้าสู่ระบบด้วย Google
          </GhostButton>
        )}

        <p className="mt-8 text-center text-slate-500 text-sm">
          {isRegister ? "มีบัญชีอยู่แล้ว?" : "ยังไม่มีบัญชี?"}{" "}
          <button
            type="button"
            onClick={() => setMode(isRegister ? "login" : "register")}
            className="text-blue-600 font-bold hover:underline"
          >
            {isRegister ? "เข้าสู่ระบบ" : "สมัครสมาชิกใหม่"}
          </button>
        </p>
      </div>
    </div>
  );
}

function ProfileModal({ user, api, onClose }) {
  const [displayName, setDisplayName] = useState(user.displayName || "");
  const [photoURL, setPhotoURL] = useState(user.photoURL || "");

  async function save(event) {
    event.preventDefault();
    await user.updateProfile({ displayName, photoURL });
    await api.set(`profiles/${user.email}`, {
      displayName,
      photoURL,
      email: user.email,
      lastUpdated: window.firebase.firestore.FieldValue.serverTimestamp(),
    });
    Swal().fire("สำเร็จ", "อัปเดตโปรไฟล์เรียบร้อยแล้ว", "success");
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/50 flex items-center justify-center p-4">
      <form
        onSubmit={save}
        className="bg-white rounded-2xl border border-slate-200 p-6 shadow-xl w-full max-w-md space-y-4"
      >
        <div className="flex items-center justify-between">
          <h3 className="font-extrabold text-lg">ตั้งค่าโปรไฟล์</h3>
          <GhostButton type="button" className="py-2 px-3" onClick={onClose}>
            <Icon name="fa-xmark" />
          </GhostButton>
        </div>

        <div className="flex flex-col items-center gap-3 py-4 bg-slate-50 rounded-2xl border border-dashed border-slate-200">
          <div className="w-24 h-24 rounded-full bg-gradient-to-br from-blue-100 to-emerald-100 flex items-center justify-center text-blue-700 font-bold text-3xl overflow-hidden shadow-md border-4 border-white">
            {photoURL ? (
              <img
                src={photoURL}
                alt="Preview"
                className="w-full h-full object-cover"
                onError={(e) => {
                  e.target.onerror = null;
                  e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName || "U")}&background=random`;
                }}
              />
            ) : (
              <span className="text-slate-400">
                <Icon name="fa-user" />
              </span>
            )}
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
        <Field label="URL รูปโปรไฟล์">
          <Input
            value={photoURL}
            onChange={(e) => setPhotoURL(e.target.value)}
            placeholder="https://example.com/photo.jpg"
          />
        </Field>
        <PrimaryButton className="w-full">
          <Icon name="fa-floppy-disk" /> บันทึกโปรไฟล์
        </PrimaryButton>
      </form>
    </div>
  );
}

function Shell({ user, auth, routeId, query, navigate, data, api, refresh }) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [profileOpen, setProfileOpen] = useState(false);
  const route = routeById[routeId] || routeById.dashboard;
  const displayName = user.displayName || user.email || "อาจารย์ผู้สอน";
  const avatar = user.photoURL ? (
    <img
      src={user.photoURL}
      alt=""
      className="w-full h-full object-cover"
      onError={(e) => {
        e.target.onerror = null;
        e.target.src = `https://ui-avatars.com/api/?name=${encodeURIComponent(displayName || "U")}&background=random`;
      }}
    />
  ) : (
    displayName.slice(0, 1).toUpperCase()
  );

  function renderPage() {
    const props = {
      data,
      api,
      refresh,
      navigate,
      query,
      userEmail: user.email,
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
    return <Dashboard {...props} />;
  }

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50 relative">
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-30 lg:hidden"
        />
      )}
      <aside
        className={`fixed inset-y-0 left-0 w-72 bg-white/95 backdrop-blur-xl border-r border-slate-200/70 shadow-xl flex flex-col z-40 transition-transform duration-300 ${sidebarOpen ? "translate-x-0" : "-translate-x-full"} lg:translate-x-0 lg:static lg:shadow-sm lg:z-20`}
      >
        <div className="p-6 border-b border-slate-100 flex items-center justify-between">
          <div className="flex items-center gap-4">
            <AppLogo compact />
            <span className="text-xl font-extrabold tracking-tight text-slate-800">
              Exam Grading
            </span>
          </div>
          <button
            onClick={() => setSidebarOpen(false)}
            className="lg:hidden text-slate-400 hover:text-slate-600"
          >
            <Icon name="fa-xmark" />
          </button>
        </div>
        <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
          {routes
            .filter((item) => !item.hidden)
            .map((item) => (
              <button
                key={item.id}
                onClick={() => {
                  navigate(item.id);
                  setSidebarOpen(false);
                }}
                className={`sidebar-menu ${routeId === item.id ? "active" : ""} w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left text-slate-600`}
              >
                <Icon name={item.icon} />{" "}
                <span className="font-medium">{item.label}</span>
              </button>
            ))}
        </nav>
        <div className="p-4 border-t border-slate-100">
          <GhostButton
            variant="danger"
            onClick={() => auth.signOut()}
            className="w-full"
          >
            <Icon name="fa-right-from-bracket" /> ออกจากระบบ
          </GhostButton>
        </div>
      </aside>
      <main className="flex-1 flex flex-col h-screen overflow-y-auto relative">
        <header className="bg-white/85 backdrop-blur-md border-b border-slate-200/70 shadow-sm p-4 px-6 lg:px-8 flex justify-between items-center sticky top-0 z-10">
          <div className="flex items-center gap-4">
            <button
              onClick={() => setSidebarOpen(true)}
              className="lg:hidden w-10 h-10 flex items-center justify-center rounded-xl bg-slate-100 text-slate-600 hover:bg-slate-200 transition-colors"
            >
              <Icon name="fa-bars" />
            </button>
            <h2 className="text-xl lg:text-2xl font-extrabold text-slate-800 tracking-tight">
              {route.label}
            </h2>
          </div>
          <button
            onClick={() => setProfileOpen(true)}
            className="flex items-center gap-3 group"
          >
            <span className="hidden sm:flex flex-col items-end">
              <span className="text-sm font-semibold text-slate-800 leading-none group-hover:text-blue-600 transition-colors">
                {displayName}
              </span>
              <span className="text-xs text-slate-500 mt-1">
                ตั้งค่าโปรไฟล์
              </span>
            </span>
            <span className="w-11 h-11 bg-gradient-to-br from-blue-100 to-emerald-100 rounded-full flex items-center justify-center text-blue-700 font-bold overflow-hidden shadow-sm border border-white">
              {avatar}
            </span>
          </button>
        </header>
        <div className="p-4 lg:p-8 max-w-7xl mx-auto w-full">
          {renderPage()}
        </div>
      </main>
      {profileOpen && (
        <ProfileModal
          user={user}
          api={api}
          onClose={() => setProfileOpen(false)}
        />
      )}
    </div>
  );
}

export default function App() {
  const [firebase, setFirebase] = useState(null);
  const [user, setUser] = useState(null);
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

  useEffect(() => {
    const services = bootFirebase();
    setFirebase(services);
    const unsubscribe = services.auth.onAuthStateChanged(async (nextUser) => {
      setUser(nextUser);
      setLoading(false);
      if (nextUser) await loadData(services, nextUser);
    });
    return unsubscribe;
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
    if (user && ["login", "register"].includes(routeId)) {
      navigate("dashboard");
    }
  }, [user, routeId]);

  async function getDocs(services, currentUser, collectionPath) {
    const snapshot = await services.db
      .collection("users")
      .doc(currentUser.email)
      .collection(collectionPath)
      .get();
    return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
  }

  async function loadData(services = firebase, currentUser = user) {
    if (!services || !currentUser) return;
    const subjects = await getDocs(services, currentUser, "subjects");
    const sections = [];
    for (const subject of subjects) {
      const snapshot = await services.db
        .collection("users")
        .doc(currentUser.email)
        .collection("subjects")
        .doc(subject.id)
        .collection("sections")
        .get();
      snapshot.forEach((doc) =>
        sections.push({
          id: `${subject.id}_${doc.id}`,
          realId: doc.id,
          subject: subject.id,
          ...doc.data(),
        }),
      );
    }
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
    return {
      async add(collectionPath, payload) {
        const docRef = await root.collection(collectionPath).add(payload);
        return docRef.id;
      },
      async set(path, payload) {
        await root
          .collection(path.split("/").slice(0, -1).join("/"))
          .doc(path.split("/").at(-1))
          .set(payload, { merge: true });
      },
      async update(collectionPath, id, payload) {
        await root.collection(collectionPath).doc(id).update(payload);
      },
      async remove(collectionPath, id) {
        await root.collection(collectionPath).doc(id).delete();
      },
    };
  }, [firebase, user]);

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
      <div className="min-h-screen flex items-center justify-center text-slate-500 font-semibold">
        กำลังโหลดระบบ...
      </div>
    );
  }

  if (!user) {
    return (
      <AuthCard mode={authMode} setMode={setAuthMode} auth={firebase.auth} />
    );
  }

  return (
    <Shell
      user={user}
      auth={firebase.auth}
      routeId={routeId}
      query={query}
      navigate={navigate}
      data={data}
      api={api}
      refresh={refresh}
    />
  );
}
