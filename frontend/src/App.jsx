import { useEffect, useMemo, useState } from "react";
import { AnswerKeyPage } from "./pages/AnswerKeyPage.jsx";
import { AnswerSheet } from "./pages/AnswerSheet.jsx";
import { AnalysisPage } from "./pages/AnalysisPage.jsx";
import { AdminPage } from "./pages/AdminPage.jsx";
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
} from "./ui.jsx";

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
      sessionStorage.setItem("justLoggedIn", "true");
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

  return (
    <div className="min-h-screen flex items-center justify-center bg-slate-50 p-4">
      <div className="bg-white p-8 sm:p-10 rounded-lg shadow-sm border border-slate-200 w-full max-w-md">
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
          <Field label="ชื่อผู้ใช้ หรือ อีเมล (Username / Email)">
            <Input
              type="text"
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

function ProfileModal({ user, profile, api, onClose, onProfileSaved }) {
  const [displayName, setDisplayName] = useState(
    profile?.displayName || user.displayName || "",
  );
  const [photoURL, setPhotoURL] = useState(
    profile?.photoURL || user.photoURL || "",
  );

  async function save(event) {
    event.preventDefault();
    const nextDisplayName = cleanProfileText(displayName);
    const nextPhotoURL = cleanProfileText(photoURL);
    await user.updateProfile({
      displayName: nextDisplayName,
      photoURL: nextPhotoURL,
    });
    await user.reload();
    await api.set(`profiles/${user.email}`, {
      displayName: nextDisplayName,
      photoURL: nextPhotoURL,
      email: user.email,
      lastUpdated: window.firebase.firestore.FieldValue.serverTimestamp(),
    });
    onProfileSaved?.({
      displayName: nextDisplayName,
      photoURL: nextPhotoURL,
      email: user.email,
    });
    Swal().fire("สำเร็จ", "อัปเดตโปรไฟล์เรียบร้อยแล้ว", "success");
    onClose();
  }

  return (
    <div className="fixed inset-0 z-50 bg-slate-950/50 flex items-center justify-center p-4">
      <form
        onSubmit={save}
        className="bg-white rounded-lg border border-slate-200 p-6 shadow-sm w-full max-w-md space-y-4"
      >
        <div className="flex items-center justify-between">
          <h3 className="font-extrabold text-lg">ตั้งค่าโปรไฟล์</h3>
          <GhostButton type="button" className="py-2 px-3" onClick={onClose}>
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
      await api?.log("User signed out");
      await auth.signOut();
    }
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
        className={`fixed inset-y-0 left-0 w-72 bg-white border-r border-slate-200 shadow-sm flex flex-col z-40 transition-transform duration-300 ${sidebarOpen ? "translate-x-0" : "-translate-x-full"} lg:translate-x-0 lg:static lg:shadow-none lg:z-20`}
      >
        <div className="p-4 px-6 border-b border-slate-100 flex items-center justify-between h-[73px]">
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
            .filter((item) => !item.adminOnly || user?.role === "admin")
            .map((item) => (
              <button
                key={item.id}
                onClick={() => {
                  navigate(item.id);
                  setSidebarOpen(false);
                }}
                className={`sidebar-menu ${routeId === item.id ? "active" : ""} w-full flex items-center gap-3 px-4 py-3 rounded-lg text-left text-slate-600`}
              >
                <Icon name={item.icon} />{" "}
                <span className="font-medium">{item.label}</span>
              </button>
            ))}
        </nav>
        <div className="p-4 border-t border-slate-100">
          {user?.role === "admin" ? (
            <GhostButton
              variant="primary"
              onClick={() => navigate("admin")}
              className="w-full"
            >
              <Icon name="fa-user-shield" /> โหมดผู้ดูแลระบบ
            </GhostButton>
          ) : (
            <GhostButton variant="danger" onClick={signOut} className="w-full">
              <Icon name="fa-right-from-bracket" /> ออกจากระบบ
            </GhostButton>
          )}
        </div>
      </aside>
      <main className="flex-1 flex flex-col h-screen overlay-y relative">
        <header className="bg-white border-b border-slate-200 px-6 sm:px-10 shrink-0 sticky top-0 z-10 h-[73px] flex items-center w-full">
          <div className="flex items-center justify-between w-full">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden w-10 h-10 flex items-center justify-center rounded-lg bg-slate-100 text-slate-600 hover:bg-slate-200 transition-colors mr-2"
              >
                <Icon name="fa-bars" />
              </button>
              {route.icon && (
                <div className="w-10 h-10 rounded-md bg-blue-50 text-blue-600 flex items-center justify-center border border-blue-100/50">
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
          api={api}
          onClose={() => setProfileOpen(false)}
          onProfileSaved={onProfileSaved}
        />
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
    const unsubscribe = services.auth.onAuthStateChanged(async (nextUser) => {
      if (nextUser) {
        try {
          const userDoc = await services.db
            .collection("users")
            .doc(nextUser.email)
            .get();
          if (userDoc.exists && userDoc.data().status === "suspended") {
            await services.auth.signOut();
            Swal().fire(
              "เข้าสู่ระบบไม่สำเร็จ",
              "บัญชีของคุณถูกระงับการใช้งาน กรุณาติดต่อผู้ดูแลระบบ",
              "error",
            );
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
      if (user.role === "admin") {
        navigate("admin");
      } else {
        navigate("dashboard");
      }
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
      <div className="min-h-screen flex items-center justify-center bg-slate-50">
        <p className="loader">
          <span>Scan</span>
        </p>
      </div>
    );
  }

  if (!user) {
    return (
      <AuthCard mode={authMode} setMode={setAuthMode} auth={firebase.auth} />
    );
  }

  async function signOut() {
    await api?.log("User signed out");
    await firebase.auth.signOut();
  }

  if (routeId === "admin") {
    if (user.role === "admin") {
      return (
        <AdminPage
          firebase={firebase}
          user={user}
          signOut={signOut}
          navigate={navigate}
        />
      );
    }
    return (
      <div className="min-h-screen flex flex-col items-center justify-center bg-slate-50 text-slate-800">
        <Icon name="fa-shield-halved" className="text-5xl text-red-500 mb-4" />
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
