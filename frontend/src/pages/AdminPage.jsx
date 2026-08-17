import { useEffect, useMemo, useRef, useState } from "react";
import {
  API_BASE_URL,
  Field,
  Icon,
  Input,
  Pagination,
  PrimaryButton,
  AppLogo,
  Swal,
  useChart,
} from "../ui.jsx";
import { Loader } from "../components/Loader.jsx";
import AdminLoginPage from "./AdminLoginPage.jsx";
import { AdminSettingsPage } from "./AdminSettingsPage.jsx";

const BASE_URL = API_BASE_URL || "http://127.0.0.1:8000";
const ADMIN_COLLECTIONS = ["Admin", "admins"];
const LOG_COLLECTIONS = ["systemLogs", "logs", "ประวัติการใช้งานระบบ"];
const USER_SUBCOLLECTIONS = ["exams", "students", "results", "subjects"];

function toDate(value) {
  if (!value) return null;
  if (typeof value.toDate === "function") return value.toDate();
  if (value instanceof Date) return value;
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? null : parsed;
}

function formatDateTime(value) {
  const date = toDate(value);
  if (!date) return "-";
  return date.toLocaleString("th-TH", {
    year: "numeric",
    month: "short",
    day: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

function displayUserName(user) {
  return (
    user.displayName ||
    user.name ||
    user.fullName ||
    user.email ||
    user.id ||
    "ไม่ระบุชื่อ"
  );
}

async function getFirstExistingCollection(db, names) {
  for (const name of names) {
    const snapshot = await db.collection(name).limit(1).get();
    if (!snapshot.empty) return name;
  }
  return names[0];
}

async function loadCollection(db, name) {
  const snapshot = await db.collection(name).get();
  return snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }));
}

function ownerIdFromSubcollectionDoc(doc) {
  return doc.ref?.parent?.parent?.id || null;
}

async function loadUsersFromSubcollections(db) {
  const owners = new Map();
  const nested = {
    exams: [],
    results: [],
    students: [],
    subjects: [],
  };

  await Promise.all(
    USER_SUBCOLLECTIONS.map(async (collectionName) => {
      const snapshot = await db.collectionGroup(collectionName).get();
      snapshot.docs.forEach((doc) => {
        const owner = ownerIdFromSubcollectionDoc(doc);
        if (!owner) return;
        if (!owners.has(owner)) {
          owners.set(owner, {
            id: owner,
            email: owner.includes("@") ? owner : "",
            displayName: owner.includes("@") ? owner.split("@")[0] : owner,
            role: "Teacher",
            status: "active",
            source: "subcollections",
          });
        }
        if (nested[collectionName]) {
          nested[collectionName].push({
            id: doc.id,
            owner,
            ...doc.data(),
          });
        }
      });
    }),
  );

  return {
    users: Array.from(owners.values()),
    nested,
  };
}

function mergeUsers(primaryUsers, discoveredUsers) {
  const usersById = new Map();
  discoveredUsers.forEach((user) => usersById.set(user.id, user));
  primaryUsers.forEach((user) => {
    usersById.set(user.id, {
      ...usersById.get(user.id),
      ...user,
      email: user.email || usersById.get(user.id)?.email || user.id,
      role: user.role || usersById.get(user.id)?.role || "user",
      status: user.status || usersById.get(user.id)?.status || "active",
    });
  });
  return Array.from(usersById.values()).sort((a, b) =>
    displayUserName(a).localeCompare(displayUserName(b), "th"),
  );
}
export function AdminPage({ firebase, user, signOut, navigate }) {
  const db = firebase.db;
  const chartRef = useRef(null);
  const [session, setSession] = useState(() => {
    try {
      const stored =
        localStorage.getItem("examAdminSession") ||
        sessionStorage.getItem("examAdminSession");
      if (stored) {
        const parsed = JSON.parse(stored);
        if (!parsed.aid) return null; // Force logout for invalid sessions
        return parsed;
      }
      return null;
    } catch {
      return null;
    }
  });

  useEffect(() => {
    if (user?.role === "admin" && !session) {
      const nextSession = {
        aid: user.id,
        aname: user.displayName || user.email,
      };
      sessionStorage.setItem("examAdminSession", JSON.stringify(nextSession));
      setSession(nextSession);
    }
  }, [user, session]);

  const [activePage, setActivePage] = useState("dashboard");
  const [loading, setLoading] = useState(false);
  const [logCollection, setLogCollection] = useState(LOG_COLLECTIONS[0]);
  const [selectedLogs, setSelectedLogs] = useState(new Set());
  const [lastSelectedLogIndex, setLastSelectedLogIndex] = useState(null);
  const [lastShiftLogIndex, setLastShiftLogIndex] = useState(null);
  const [viewingLog, setViewingLog] = useState(null);
  const [userForm, setUserForm] = useState({
    id: "",
    displayName: "",
    email: "",
    role: "user",
  });
  const [editingUser, setEditingUser] = useState(null);
  const [search, setSearch] = useState("");
  const [searchLogs, setSearchLogs] = useState("");
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [isLoggingOut, setIsLoggingOut] = useState(false);
  const [usersPage, setUsersPage] = useState(1);
  const chartInstance = useRef(null);
  const [logsPage, setLogsPage] = useState(1);
  const [data, setData] = useState({
    admins: [],
    users: [],
    logs: [],
    exams: [],
    results: [],
    students: [],
  });

  useEffect(() => {
    if (session) refresh();
  }, [session]);

  async function writeLog(activity) {
    const docRef = db.collection(logCollection).doc();
    await docRef.set({
      logid: docRef.id,
      activity,
      datetime: window.firebase.firestore.FieldValue.serverTimestamp(),
      admin: session?.aname || "Admin",
      userEmail: session?.aid || user?.email || user?.id,
    });
  }

  async function writeAnonymousLog(action) {
    if (!session) return;
    try {
      await fetch(`${BASE_URL}/api/db/systemLogs`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          activity: action,
          displayName: session.aname,
          role: "Teacher",
          userEmail: session.aid,
        }),
      });
    } catch (error) {
      console.error("Failed to write anonymous log:", error);
    }
  }

  async function refresh() {
    setLoading(true);
    try {
      const [adminsName, logsName] = await Promise.all([
        getFirstExistingCollection(db, ADMIN_COLLECTIONS),
        getFirstExistingCollection(db, LOG_COLLECTIONS),
      ]);
      setLogCollection(logsName);

      const [admins, users, logs, discovered] = await Promise.all([
        loadCollection(db, adminsName),
        loadCollection(db, "users"),
        loadCollection(db, logsName),
        loadUsersFromSubcollections(db),
      ]);
      const allUsers = mergeUsers(users, discovered.users);

      const nested = await Promise.all(
        allUsers.map(async (user) => {
          const root = db.collection("users").doc(user.id);
          const [exams, results, students] = await Promise.all([
            root.collection("exams").get(),
            root.collection("results").get(),
            root.collection("students").get(),
          ]);
          return {
            exams: exams.docs.map((doc) => ({
              id: doc.id,
              owner: user.id,
              ...doc.data(),
            })),
            results: results.docs.map((doc) => ({
              id: doc.id,
              owner: user.id,
              ...doc.data(),
            })),
            students: students.docs.map((doc) => ({
              id: doc.id,
              owner: user.id,
              ...doc.data(),
            })),
          };
        }),
      );

      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);

      const freshLogs = [];
      const oldLogIds = [];
      for (const log of logs) {
        const date = toDate(log.datetime);
        if (date && date < sevenDaysAgo) {
          oldLogIds.push(log.id);
        } else {
          freshLogs.push(log);
        }
      }

      if (oldLogIds.length > 0) {
        Promise.all(
          oldLogIds.map((id) => db.collection(logsName).doc(id).delete()),
        ).catch(console.error);
      }

      setData({
        admins,
        users: allUsers,
        logs: freshLogs.sort(
          (a, b) =>
            (toDate(b.datetime)?.getTime() || 0) -
            (toDate(a.datetime)?.getTime() || 0),
        ),
        exams: nested.flatMap((item) => item.exams),
        results: nested.flatMap((item) => item.results),
        students: nested.flatMap((item) => item.students),
      });
    } catch (error) {
      Swal().fire("โหลดข้อมูลไม่สำเร็จ", error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  async function deleteLog(id) {
    const res = await Swal().fire({
      title: "ยืนยันการลบ Log?",
      text: "คุณต้องการลบประวัติการใช้งานนี้ใช่หรือไม่",
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบ",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#ef4444",
    });
    if (res.isConfirmed) {
      setLoading(true);
      try {
        await db.collection(logCollection).doc(id).delete();
        await refresh();
      } catch (error) {
        Swal().fire("ลบไม่สำเร็จ", error.message, "error");
      } finally {
        setLoading(false);
      }
    }
  }

  async function deleteSelectedLogs() {
    if (selectedLogs.size === 0) return;
    const res = await Swal().fire({
      title: "ยืนยันการลบ Log จำนวนหลายรายการ?",
      text: `คุณต้องการลบประวัติการใช้งานจำนวน ${selectedLogs.size} รายการใช่หรือไม่`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบ",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#ef4444",
    });
    if (res.isConfirmed) {
      setLoading(true);
      try {
        await Promise.all(
          Array.from(selectedLogs).map((id) =>
            db.collection(logCollection).doc(id).delete(),
          ),
        );
        setSelectedLogs(new Set());
        await refresh();
      } catch (error) {
        Swal().fire("ลบไม่สำเร็จ", error.message, "error");
      } finally {
        setLoading(false);
      }
    }
  }

  function logout() {
    setIsLoggingOut(true);
    writeAnonymousLog("ออกจากระบบ (Admin)");
    localStorage.removeItem("examAdminSession");
    sessionStorage.removeItem("examAdminSession");
    setSession(null);
    if (signOut) {
      signOut();
    }
    setTimeout(() => {
      setIsLoggingOut(false);
    }, 1000);
  }

  async function saveUser(event) {
    event.preventDefault();
    Swal().fire({
      title: "กำลังบันทึกข้อมูล...",
      allowOutsideClick: false,
      didOpen: () => Swal().showLoading(),
    });
    const id = (editingUser?.id || userForm.id || userForm.email).trim();
    if (!id) return;
    const payload = {
      displayName: userForm.displayName.trim(),
      email: userForm.email.trim() || id,
      role: userForm.role,
      status: editingUser?.status || "active",
      updatedAt: window.firebase.firestore.FieldValue.serverTimestamp(),
    };

    if (!editingUser) {
      payload.password = "123456";
    }

    await db.collection("users").doc(id).set(payload, { merge: true });
    await writeLog(`${editingUser ? "แก้ไข" : "เพิ่ม"}ข้อมูลผู้ใช้งาน: ${id}`);
    setEditingUser(null);
    setUserForm({ id: "", displayName: "", email: "", role: "user" });
    await refresh();
    Swal().fire("สำเร็จ", "บันทึกข้อมูลผู้ใช้งานเรียบร้อย", "success");
  }

  async function toggleUserStatus(user) {
    const nextStatus = user.status === "suspended" ? "active" : "suspended";
    await db.collection("users").doc(user.id).set(
      {
        status: nextStatus,
        updatedAt: window.firebase.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await writeLog(
      `${nextStatus === "suspended" ? "ระงับ" : "ปลดระงับ"}บัญชีผู้ใช้งาน: ${user.id}`,
    );
    await refresh();
  }

  async function removeUser(user) {
    const result = await Swal().fire({
      title: "ลบผู้ใช้งาน?",
      text: `ต้องการลบข้อมูล ${displayUserName(user)} ออกจาก Firestore หรือไม่`,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "ลบข้อมูล",
      cancelButtonText: "ยกเลิก",
      confirmButtonColor: "#dc2626",
    });
    if (!result.isConfirmed) return;
    await db.collection("users").doc(user.id).delete();
    await writeLog(`ลบข้อมูลผู้ใช้งาน: ${user.id}`);
    await refresh();
  }

  function startEdit(user) {
    setEditingUser(user);
    setUserForm({
      id: user.id,
      displayName: displayUserName(user),
      email: user.email || user.id,
      role: user.role || "user",
    });
  }

  const filteredUsers = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return data.users;
    return data.users.filter((user) =>
      [user.id, user.email, displayUserName(user), user.role]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(keyword)),
    );
  }, [data.users, search]);

  const PAGE_SIZE = 10;
  const usersTotalPages = Math.max(
    1,
    Math.ceil(filteredUsers.length / PAGE_SIZE),
  );
  const paginatedUsers = useMemo(() => {
    const start = (usersPage - 1) * PAGE_SIZE;
    return filteredUsers.slice(start, start + PAGE_SIZE);
  }, [filteredUsers, usersPage]);
  const filteredLogs = useMemo(() => {
    const keyword = searchLogs.trim().toLowerCase();
    if (!keyword) return data.logs;
    return data.logs.filter((log) =>
      [log.id, log.userEmail, log.user, log.admin, log.logid, log.activity]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(keyword)),
    );
  }, [data.logs, searchLogs]);

  const logsTotalPages = Math.max(
    1,
    Math.ceil(filteredLogs.length / PAGE_SIZE),
  );
  const paginatedLogs = useMemo(() => {
    const start = (logsPage - 1) * PAGE_SIZE;
    return filteredLogs.slice(start, start + PAGE_SIZE);
  }, [filteredLogs, logsPage]);

  useEffect(() => {
    setUsersPage(1);
  }, [search]);

  useEffect(() => {
    setUsersPage((page) => Math.min(page, usersTotalPages));
  }, [usersTotalPages]);

  useEffect(() => {
    setLogsPage((page) => Math.min(page, logsTotalPages));
  }, [logsTotalPages]);

  const monthlyStats = useMemo(() => {
    const today = new Date();
    const months = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(today.getFullYear(), today.getMonth() - i, 1);
      months.push(d.toLocaleDateString("th-TH", { month: "short" }));
    }
    const counts = Object.fromEntries(months.map((month) => [month, 0]));
    data.results.forEach((result) => {
      const date = toDate(
        result.createdAt || result.datetime || result.date || result.timestamp,
      );
      if (!date) return;
      const label = date.toLocaleDateString("th-TH", { month: "short" });
      if (counts[label] !== undefined) counts[label] += 1;
    });
    return { labels: months, values: months.map((month) => counts[month]) };
  }, [data.results]);

  useChart(
    chartRef,
    {
      type: "line",
      data: {
        labels: monthlyStats.labels,
        datasets: [
          {
            label: "จำนวนรายการตรวจข้อสอบ",
            data: monthlyStats.values,
            backgroundColor: "rgba(16, 185, 129, 0.16)",
            borderColor: "#10b981",
            borderWidth: 2,
            fill: true,
            tension: 0.35,
            pointBackgroundColor: "#10b981",
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: { y: { beginAtZero: true } },
        plugins: { legend: { display: false } },
      },
    },
    [monthlyStats, activePage],
  );

  if (!session) {
    return (
      <AdminLoginPage
        setSession={setSession}
        writeAnonymousLog={writeAnonymousLog}
        navigate={navigate}
      />
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-slate-100 text-slate-800 font-['Inter'] relative">
      {sidebarOpen && (
        <div
          onClick={() => setSidebarOpen(false)}
          className="fixed inset-0 bg-slate-900/40 backdrop-blur-sm z-40 lg:hidden"
        />
      )}
      <aside
        className={`fixed inset-y-0 left-0 w-72 bg-slate-900 border-r border-slate-800 flex flex-col z-50 transition-transform duration-300 ${
          sidebarOpen ? "translate-x-0" : "-translate-x-full"
        } lg:translate-x-0 lg:static lg:shadow-none lg:z-20`}
      >
        <button
          onClick={() => setSidebarOpen(false)}
          className={`lg:hidden absolute top-4 -right-12 w-10 h-10 flex items-center justify-center rounded-full bg-slate-900/50 text-white hover:bg-slate-900/70 backdrop-blur-md transition-all duration-300 shadow-sm ${sidebarOpen ? "opacity-100" : "opacity-0 pointer-events-none"}`}
        >
          <Icon name="fa-xmark" className="text-xl" />
        </button>
        <div className="p-4 px-6 border-b border-slate-800 flex items-center h-[73px]">
          <div className="flex items-center gap-3 w-full">
            <div className="w-8 h-8 rounded-lg bg-indigo-500 text-white flex items-center justify-center shadow-md shrink-0">
              <Icon name="fa-user-shield" />
            </div>
            <span className="text-xl font-bold tracking-tight text-white leading-none truncate">
              Admin<span className="text-indigo-400 font-medium">Panel</span>
            </span>
          </div>
        </div>
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {[
            ["dashboard", "fa-chart-line", "แดชบอร์ด"],
            ["users", "fa-users-gear", "จัดการผู้ใช้งาน"],
            ["settings", "fa-cogs", "ตั้งค่าระบบ"],
            ["logs", "fa-list-check", "ประวัติการใช้งาน"],
          ].map(([id, icon, label]) => (
            <button
              key={id}
              onClick={() => {
                setActivePage(id);
                setSidebarOpen(false);
              }}
              className={`group w-full flex items-center gap-3 px-3 py-2.5 rounded-xl text-left transition-all duration-200 ${
                activePage === id
                  ? "bg-indigo-600 text-white font-bold shadow-md shadow-indigo-900/50"
                  : "text-slate-400 hover:bg-slate-800 hover:text-white font-medium"
              }`}
            >
              <div
                className={`w-8 h-8 rounded-lg flex items-center justify-center transition-colors shrink-0 ${
                  activePage === id
                    ? "bg-white/20 text-white"
                    : "bg-slate-800 text-slate-400 group-hover:text-white"
                }`}
              >
                <Icon name={icon} className="text-[13px]" />
              </div>
              <span className="text-[15px] truncate">{label}</span>
            </button>
          ))}
        </nav>
        <div className="p-4 border-t border-slate-800 bg-slate-900 space-y-2 shrink-0">
          <button
            onClick={logout}
            className="w-full flex items-center justify-center gap-2 py-2.5 px-4 rounded-xl text-sm font-bold text-rose-400 bg-slate-800 border border-slate-700 hover:bg-rose-500 hover:text-white hover:border-rose-500 transition-colors"
          >
            <Icon name="fa-right-from-bracket" /> ออกจากระบบ
          </button>
        </div>
      </aside>

      <main className="flex-1 flex flex-col h-screen overflow-y-auto bg-slate-100 relative selection:bg-indigo-500/30">
        <header className="bg-white border-b border-slate-200 px-6 sm:px-10 shrink-0 sticky top-0 z-30 h-[73px] flex items-center w-full shadow-sm">
          <div className="flex items-center justify-between w-full">
            <div className="flex items-center gap-3">
              <button
                onClick={() => setSidebarOpen(true)}
                className="lg:hidden w-10 h-10 flex items-center justify-center rounded-lg bg-slate-100 text-slate-600 hover:bg-slate-200 transition-colors mr-2 shrink-0"
              >
                <Icon name="fa-bars" />
              </button>
              <div className="hidden sm:flex w-10 h-10 rounded-md bg-indigo-50 text-indigo-600 items-center justify-center border border-indigo-100/50 shrink-0">
                <Icon
                  name={
                    activePage === "dashboard"
                      ? "fa-chart-line"
                      : activePage === "users"
                        ? "fa-users-gear"
                        : "fa-list-check"
                  }
                />
              </div>
              <div>
                <h2 className="text-xl sm:text-2xl font-black text-slate-800 leading-tight">
                  {activePage === "dashboard" && "แดชบอร์ด"}
                  {activePage === "users" && "จัดการผู้ใช้งาน"}
                  {activePage === "settings" && "ตั้งค่าระบบ"}
                  {activePage === "logs" && "ประวัติการใช้งาน"}
                </h2>
              </div>
            </div>

            <div className="flex items-center gap-4">
              <button
                onClick={refresh}
                className="hidden"
                disabled={loading}
              ></button>
              <div className="flex items-center gap-3">
                <span className="hidden sm:flex flex-col items-end">
                  <span className="text-sm font-semibold text-slate-800 leading-none">
                    {session.aname}
                  </span>
                  <span className="text-xs text-indigo-600 mt-1 font-bold">
                    ผู้ดูแลระบบ
                  </span>
                </span>
                <div className="w-10 h-10 bg-indigo-50 rounded-full flex items-center justify-center text-indigo-600 font-bold overflow-hidden border border-indigo-100">
                  <Icon name="fa-user-shield" />
                </div>
              </div>
            </div>
          </div>
        </header>

        <div
          className={`p-4 lg:p-8 max-w-[1600px] mx-auto w-full flex-1 ${activePage === "dashboard" ? "flex flex-col min-h-[calc(100vh-73px)] lg:h-[calc(100vh-73px)] lg:overflow-hidden" : "space-y-6"}`}
        >
          {activePage === "dashboard" && (
            <div className="flex flex-col lg:flex-1 lg:min-h-0 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6 shrink-0">
                <AdminStatCard
                  color="indigo"
                  icon="fa-users"
                  title="จำนวนบัญชีผู้ใช้งานทั้งหมด"
                  value={`${data.users.length} คน`}
                />
                <AdminStatCard
                  color="purple"
                  icon="fa-file-signature"
                  title="จำนวนการสอบทั้งหมดในระบบ"
                  value={`${data.exams.length} ครั้ง`}
                />
                <AdminStatCard
                  color="emerald"
                  icon="fa-check-double"
                  title="จำนวนรายการตรวจที่บันทึกแล้ว"
                  value={`${data.results.length} รายการ`}
                />
              </div>

              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 lg:flex-1 lg:min-h-0">
                <section className="lg:col-span-2 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col lg:min-h-0 relative">
                  <h3 className="text-lg font-bold mb-4 text-slate-800 shrink-0">
                    สถิติการตรวจข้อสอบ (6 เดือนล่าสุด)
                  </h3>
                  <div className="flex-1 w-full min-h-[250px] lg:min-h-0 relative">
                    <canvas ref={chartRef} />
                  </div>
                </section>

                <section className="lg:col-span-1 bg-white p-6 rounded-2xl border border-slate-200 shadow-sm flex flex-col lg:min-h-0">
                  <h3 className="text-lg font-bold mb-4 text-slate-800 shrink-0">
                    กิจกรรมล่าสุดในระบบ
                  </h3>
                  <div className="flex-1 space-y-4 overflow-y-auto pr-2 custom-scrollbar">
                    {data.logs.slice(0, 5).map((log, index) => (
                      <div
                        key={log.id || log.logid || `recent-log-${index}`}
                        className="border-l-4 border-indigo-500 pl-3 py-1"
                      >
                        <p
                          className="text-sm font-bold text-slate-800 line-clamp-2"
                          title={log.activity}
                        >
                          {log.activity}
                        </p>
                        <p className="text-xs text-slate-500 mt-1">
                          {formatDateTime(log.datetime)} •{" "}
                          {log.userEmail || log.admin || "System"}
                        </p>
                      </div>
                    ))}
                    {data.logs.length === 0 && (
                      <div className="flex flex-col items-center justify-center h-full text-slate-400">
                        <Icon
                          name="fa-clock-rotate-left"
                          className="text-3xl mb-2 opacity-50"
                        />
                        <p className="text-sm font-medium">
                          ยังไม่มีกิจกรรมล่าสุด
                        </p>
                      </div>
                    )}
                  </div>
                  <button
                    onClick={() => setActivePage("logs")}
                    className="mt-4 w-full py-2.5 text-sm font-bold text-indigo-600 bg-indigo-50 border border-indigo-100 rounded-xl hover:bg-indigo-100 hover:border-indigo-200 transition-colors shrink-0 flex items-center justify-center gap-2"
                  >
                    <Icon name="fa-list" /> ดูประวัติทั้งหมด
                  </button>
                </section>
              </div>
            </div>
          )}

          {activePage === "users" && (
            <div className="space-y-6">
              <div className="sticky top-[73px] z-20 bg-slate-100 py-2 -mt-2">
                <form
                  onSubmit={saveUser}
                  className="bg-white rounded-2xl border border-slate-200 shadow-md p-6 grid grid-cols-1 lg:grid-cols-4 gap-4 items-end"
                >
                  <div>
                    <label className="block text-sm font-bold text-slate-700 mb-2">
                      อีเมล
                    </label>
                    <input
                      type="text"
                      value={userForm.email}
                      onChange={(event) =>
                        setUserForm({ ...userForm, email: event.target.value })
                      }
                      placeholder="somchai@example.com"
                      className="w-full px-4 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-800 placeholder-slate-400 transition-colors"
                      disabled={editingUser !== null}
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-bold text-slate-700 mb-2">
                      ชื่อในระบบ
                    </label>
                    <input
                      type="text"
                      value={userForm.displayName}
                      onChange={(event) =>
                        setUserForm({
                          ...userForm,
                          displayName: event.target.value,
                        })
                      }
                      placeholder="สมชาย ใจดี"
                      className="w-full px-4 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-800 placeholder-slate-400 transition-colors"
                      required
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-bold text-slate-700 mb-2">
                      บทบาท
                    </label>
                    <select
                      value={userForm.role}
                      onChange={(event) =>
                        setUserForm({ ...userForm, role: event.target.value })
                      }
                      className="w-full px-4 py-2 bg-slate-50 border border-slate-300 rounded-xl focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-800 transition-colors"
                    >
                      <option value="user">ผู้ใช้งานทั่วไป (User)</option>
                      <option value="admin">ผู้ดูแลระบบ (Admin)</option>
                    </select>
                  </div>
                  <div className="flex gap-2 h-[42px]">
                    <button
                      type="submit"
                      className="flex-1 justify-center bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded-xl transition-all shadow-sm hover:shadow-md disabled:opacity-50 disabled:pointer-events-none flex items-center gap-2"
                    >
                      <Icon
                        name={editingUser ? "fa-floppy-disk" : "fa-user-plus"}
                      />{" "}
                      {editingUser ? "บันทึก" : "เพิ่ม"}
                    </button>
                    {editingUser && (
                      <button
                        type="button"
                        onClick={() => {
                          setEditingUser(null);
                          setUserForm({
                            id: "",
                            displayName: "",
                            email: "",
                            role: "user",
                          });
                        }}
                        className="px-4 rounded-xl border border-slate-300 bg-white hover:bg-slate-50 text-slate-600 hover:text-slate-800 transition-colors"
                      >
                        <Icon name="fa-xmark" />
                      </button>
                    )}
                  </div>
                </form>
              </div>

              <div className="flex justify-between items-center gap-4">
                <h3 className="text-lg font-bold text-slate-800">
                  ข้อมูลบัญชีผู้ใช้งาน
                </h3>
                <input
                  type="text"
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder="ค้นหาชื่อหรืออีเมล..."
                  className="w-full sm:w-[384px] px-4 py-2 bg-white border border-slate-300 rounded-xl focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-800 placeholder-slate-400 transition-colors shadow-sm"
                />
              </div>

              <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                <div className="overflow-x-auto relative">
                  <table className="w-full text-left border-collapse text-sm text-slate-600">
                    <thead className="bg-slate-50 text-slate-500 sticky top-0 z-10 border-b border-slate-200">
                      <tr>
                        <th className="p-3 w-16 text-center border-b border-slate-200 font-bold">
                          ลำดับ
                        </th>
                        <th className="p-3 w-[25%] font-bold whitespace-nowrap border-b border-slate-200">
                          รหัสผู้ใช้ / อีเมล
                        </th>
                        <th className="p-3 w-[35%] font-bold whitespace-nowrap border-b border-slate-200 text-left">
                          ชื่อ
                        </th>
                        <th className="p-3 w-28 font-bold text-center whitespace-nowrap border-b border-slate-200">
                          บทบาท
                        </th>
                        <th className="p-3 w-28 font-bold text-center whitespace-nowrap border-b border-slate-200">
                          สถานะ
                        </th>
                        <th className="p-3 w-32 font-bold text-center whitespace-nowrap border-b border-slate-200">
                          จัดการ
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {paginatedUsers.map((user, index) => (
                        <tr
                          key={user.id || `user-${index}`}
                          className="hover:bg-slate-50 transition-colors border-b border-slate-100 last:border-0"
                        >
                          <td className="p-4 text-center">
                            {(usersPage - 1) * PAGE_SIZE + index + 1}
                          </td>
                          <td className="p-4 whitespace-nowrap truncate font-medium text-slate-700">
                            {user.id}
                          </td>
                          <td className="p-4 font-medium text-slate-800 truncate text-left">
                            {user.displayName}
                          </td>
                          <td className="p-4 whitespace-nowrap text-center">
                            <span
                              className={`px-2.5 py-1 rounded-full text-xs font-bold border ${
                                user.role === "admin"
                                  ? "bg-indigo-50 text-indigo-700 border-indigo-200"
                                  : "bg-slate-100 text-slate-600 border-slate-200"
                              }`}
                            >
                              {user.role === "admin" ? "Admin" : "User"}
                            </span>
                          </td>
                          <td className="p-4 whitespace-nowrap text-center">
                            <span
                              className={`px-2.5 py-1 rounded-full text-xs font-bold border ${
                                user.status === "suspended"
                                  ? "bg-rose-50 text-rose-700 border-rose-200"
                                  : "bg-emerald-50 text-emerald-700 border-emerald-200"
                              }`}
                            >
                              {user.status === "suspended" ? "ระงับ" : "ปกติ"}
                            </span>
                          </td>
                          <td className="p-4 text-center whitespace-nowrap">
                            <button
                              onClick={() => startEdit(user)}
                              className="w-8 h-8 rounded-lg text-amber-500 hover:bg-slate-100 hover:text-amber-600 mx-1 transition-colors"
                              title="แก้ไข"
                            >
                              <Icon name="fa-pen-to-square" />
                            </button>
                            <button
                              onClick={() => toggleUserStatus(user)}
                              className={`w-8 h-8 rounded-lg ${user.status === "suspended" ? "text-emerald-500 hover:bg-slate-100 hover:text-emerald-600" : "text-rose-500 hover:bg-slate-100 hover:text-rose-600"} mx-1 transition-colors`}
                              title={
                                user.status === "suspended"
                                  ? "ปลดระงับบัญชี"
                                  : "ระงับบัญชี"
                              }
                            >
                              <Icon
                                name={
                                  user.status === "suspended"
                                    ? "fa-unlock"
                                    : "fa-ban"
                                }
                              />
                            </button>
                            <button
                              onClick={() => removeUser(user)}
                              className="w-8 h-8 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-rose-500 mx-1 transition-colors"
                              title="ลบ"
                            >
                              <Icon name="fa-trash-can" />
                            </button>
                          </td>
                        </tr>
                      ))}
                      {!filteredUsers.length && (
                        <tr>
                          <td
                            colSpan="6"
                            className="p-8 text-center text-slate-500 font-medium border-b border-slate-100"
                          >
                            ยังไม่มีข้อมูลผู้ใช้งาน
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
                {filteredUsers.length > 0 && (
                  <div className="flex flex-col sm:flex-row items-center justify-between gap-3 border-t border-slate-200 px-4 py-3 text-sm bg-slate-50">
                    <span className="text-slate-500 font-medium">
                      แสดง {(usersPage - 1) * PAGE_SIZE + 1}-
                      {Math.min(usersPage * PAGE_SIZE, filteredUsers.length)}{" "}
                      จาก {filteredUsers.length} รายการ
                    </span>
                    <Pagination
                      count={usersTotalPages}
                      page={usersPage}
                      onChange={(_, value) => setUsersPage(value)}
                      variant="outlined"
                      shape="rounded"
                    />
                  </div>
                )}
              </div>
            </div>
          )}

          {activePage === "settings" && (
            <AdminSettingsPage user={{ role: "admin", email: session?.aid }} />
          )}

          {activePage === "logs" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-bold text-slate-800">
                  ประวัติการใช้งานระบบ
                </h3>
                <div className="flex gap-4 items-center min-h-[36px]">
                  <button
                    onClick={deleteSelectedLogs}
                    className={`bg-rose-500 hover:bg-rose-600 text-white px-3 py-1.5 rounded-xl text-sm font-bold transition flex items-center justify-center gap-2 shadow-sm shrink-0 ${
                      selectedLogs.size > 0
                        ? "opacity-100"
                        : "opacity-0 pointer-events-none absolute -z-10"
                    }`}
                    title="ลบประวัติที่เลือก"
                  >
                    <Icon name="fa-trash-can" /> ({selectedLogs.size})
                  </button>
                  <input
                    type="text"
                    value={searchLogs}
                    onChange={(event) => setSearchLogs(event.target.value)}
                    placeholder="ค้นหาประวัติการใช้งาน..."
                    className="w-full sm:w-[384px] px-4 py-2 bg-white border border-slate-300 rounded-xl focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 text-slate-800 placeholder-slate-400 transition-colors shadow-sm"
                  />
                </div>
              </div>
              <div className="bg-white rounded-2xl border border-slate-200 shadow-sm overflow-hidden">
                <div className="overflow-x-auto relative">
                  <table className="w-full text-left border-collapse text-sm text-slate-600 font-mono">
                    <thead className="bg-slate-50 sticky top-0 z-10 border-b border-slate-200">
                      <tr>
                        <th className="p-3 w-12 text-center border-b border-slate-200">
                          <input
                            type="checkbox"
                            checked={selectedLogs.size > 0}
                            onChange={(e) => {
                              const next = new Set(selectedLogs);
                              if (e.target.checked) {
                                filteredLogs.forEach((l) => next.add(l.id));
                              } else {
                                next.clear();
                              }
                              setSelectedLogs(next);
                            }}
                            className="w-4 h-4 rounded bg-white border-slate-300 text-indigo-600 focus:ring-indigo-500/20"
                          />
                        </th>
                        <th className="p-3 w-40 font-bold whitespace-nowrap border-b border-slate-200 text-slate-500">
                          วัน-เวลา
                        </th>
                        <th className="p-3 w-[25%] font-bold whitespace-nowrap border-b border-slate-200 text-slate-500">
                          ผู้ใช้งาน
                        </th>
                        <th className="p-3 w-48 font-bold whitespace-nowrap border-b border-slate-200 text-slate-500">
                          Log ID
                        </th>
                        <th className="p-3 w-[40%] font-bold whitespace-nowrap border-b border-slate-200 text-slate-500">
                          กิจกรรม
                        </th>
                        <th className="p-3 w-24 font-bold text-center whitespace-nowrap border-b border-slate-200 text-slate-500">
                          จัดการ
                        </th>
                      </tr>
                    </thead>
                    <tbody>
                      {paginatedLogs.map((log, index) => (
                        <tr
                          key={log.id || log.logid || `log-${index}`}
                          className="hover:bg-slate-50 transition-colors border-b border-slate-100 last:border-0"
                        >
                          <td className="p-3 text-center border-b border-slate-100">
                            <input
                              type="checkbox"
                              checked={selectedLogs.has(log.id)}
                              onChange={(e) => {
                                const currentIndex = filteredLogs.findIndex(
                                  (x) => x.id === log.id,
                                );
                                const newSet = new Set(selectedLogs);

                                if (
                                  e.nativeEvent.shiftKey &&
                                  lastSelectedLogIndex !== null
                                ) {
                                  const oldStart =
                                    lastShiftLogIndex !== null
                                      ? Math.min(
                                          lastShiftLogIndex,
                                          lastSelectedLogIndex,
                                        )
                                      : lastSelectedLogIndex;
                                  const oldEnd =
                                    lastShiftLogIndex !== null
                                      ? Math.max(
                                          lastShiftLogIndex,
                                          lastSelectedLogIndex,
                                        )
                                      : lastSelectedLogIndex;

                                  const newStart = Math.min(
                                    currentIndex,
                                    lastSelectedLogIndex,
                                  );
                                  const newEnd = Math.max(
                                    currentIndex,
                                    lastSelectedLogIndex,
                                  );

                                  for (let i = oldStart; i <= oldEnd; i++) {
                                    if (i < newStart || i > newEnd) {
                                      newSet.delete(filteredLogs[i].id);
                                    }
                                  }

                                  const targetState = selectedLogs.has(
                                    filteredLogs[lastSelectedLogIndex].id,
                                  );
                                  for (let i = newStart; i <= newEnd; i++) {
                                    if (targetState)
                                      newSet.add(filteredLogs[i].id);
                                    else newSet.delete(filteredLogs[i].id);
                                  }
                                  setLastShiftLogIndex(currentIndex);
                                } else {
                                  if (e.target.checked) newSet.add(log.id);
                                  else newSet.delete(log.id);
                                  setLastSelectedLogIndex(currentIndex);
                                  setLastShiftLogIndex(currentIndex);
                                }

                                setSelectedLogs(newSet);
                              }}
                              className="w-4 h-4 rounded bg-white border-slate-300 text-indigo-600 focus:ring-indigo-500/20"
                            />
                          </td>
                          <td className="p-3 border-b border-slate-100 text-slate-500">
                            {(() => {
                              const d = toDate(log.datetime);
                              if (!d) return "-";
                              return (
                                <div className="flex flex-col">
                                  <span className="font-medium text-slate-700 whitespace-nowrap">
                                    {d.toLocaleDateString("th-TH", {
                                      year: "numeric",
                                      month: "short",
                                      day: "numeric",
                                    })}
                                  </span>
                                  <span className="text-xs text-slate-500 whitespace-nowrap mt-0.5">
                                    เวลา{" "}
                                    {d.toLocaleTimeString("th-TH", {
                                      hour: "2-digit",
                                      minute: "2-digit",
                                    })}{" "}
                                    น.
                                  </span>
                                </div>
                              );
                            })()}
                          </td>
                          <td className="p-3 font-medium text-slate-700 truncate border-b border-slate-100">
                            {log.userEmail || log.user || log.admin || "-"}
                          </td>
                          <td className="p-3 text-slate-400 font-mono text-xs truncate border-b border-slate-100">
                            {log.logid || log.id}
                          </td>
                          <td className="p-3 text-indigo-600 font-medium truncate border-b border-slate-100">
                            {log.activity || "-"}
                          </td>
                          <td className="p-3 text-center border-b border-slate-100">
                            <button
                              onClick={() => {
                                setViewingLog(log);
                              }}
                              className="w-8 h-8 rounded-lg text-indigo-400 hover:bg-indigo-50 hover:text-indigo-600 transition-colors mr-1"
                              title="ดูรายละเอียด"
                            >
                              <Icon name="fa-eye" />
                            </button>
                            <button
                              onClick={() => deleteLog(log.id)}
                              className="w-8 h-8 rounded-lg text-slate-400 hover:bg-slate-100 hover:text-rose-500 transition-colors"
                              title="ลบข้อมูล"
                            >
                              <Icon name="fa-trash-can" />
                            </button>
                          </td>
                        </tr>
                      ))}
                      {!filteredLogs.length && (
                        <tr>
                          <td
                            colSpan="6"
                            className="p-8 text-center text-slate-500 font-medium border-b border-slate-100"
                          >
                            ยังไม่มีประวัติการใช้งาน
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
                {filteredLogs.length > 0 && (
                  <div className="flex flex-col sm:flex-row items-center justify-between gap-3 border-t border-slate-200 px-4 py-3 text-sm bg-slate-50">
                    <span className="text-slate-500 font-medium">
                      แสดง {(logsPage - 1) * PAGE_SIZE + 1}-
                      {Math.min(logsPage * PAGE_SIZE, filteredLogs.length)} จาก{" "}
                      {filteredLogs.length} รายการ
                    </span>
                    <Pagination
                      count={logsTotalPages}
                      page={logsPage}
                      onChange={(_, value) => setLogsPage(value)}
                      variant="outlined"
                      shape="rounded"
                    />
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </main>

      {loading && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-50/80 backdrop-blur-sm">
          <Loader />
        </div>
      )}

      {viewingLog && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-900/50 backdrop-blur-sm p-4 animate-in fade-in duration-200">
          <div className="bg-white rounded-2xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col shadow-2xl">
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-slate-100 bg-slate-50">
              <div className="flex items-center gap-4">
                <div className="w-12 h-12 bg-indigo-100 text-indigo-600 rounded-xl flex items-center justify-center text-xl border border-indigo-200 shrink-0">
                  <Icon name="fa-clock-rotate-left" />
                </div>
                <div>
                  <p className="text-sm font-bold text-indigo-600 mb-1">
                    {formatDateTime(viewingLog.datetime)}
                  </p>
                  <h3 className="text-xl font-bold text-slate-800 leading-tight mt-1">
                    {viewingLog.activity || "ไม่มีกิจกรรม"}
                  </h3>
                </div>
              </div>
              <button
                onClick={() => setViewingLog(null)}
                className="w-10 h-10 rounded-xl text-slate-400 hover:bg-slate-200 hover:text-slate-700 transition-colors flex items-center justify-center shrink-0"
                title="ปิด"
              >
                <Icon name="fa-xmark" className="text-xl" />
              </button>
            </div>

            {/* Body */}
            <div className="p-6 overflow-y-auto custom-scrollbar flex-1 space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div>
                  <p className="text-xs font-bold text-slate-400 mb-1 uppercase tracking-wider">
                    Log ID
                  </p>
                  <p className="font-mono text-sm text-slate-700 bg-slate-50 p-2.5 rounded-xl border border-slate-200 break-all">
                    {viewingLog.logid || viewingLog.id}
                  </p>
                </div>
                <div>
                  <p className="text-xs font-bold text-slate-400 mb-1 uppercase tracking-wider">
                    ผู้ใช้งาน
                  </p>
                  <p className="text-sm font-bold text-slate-800 p-2.5 bg-slate-50 rounded-xl border border-slate-200 break-all">
                    {viewingLog.userEmail ||
                      viewingLog.user ||
                      viewingLog.admin ||
                      "-"}
                  </p>
                </div>
              </div>
              <div>
                <p className="text-xs font-bold text-slate-400 mb-2 uppercase tracking-wider">
                  ข้อมูลดิบ (Raw Data)
                </p>
                <div className="bg-slate-900 rounded-xl overflow-hidden border border-slate-800 shadow-inner">
                  <pre className="text-slate-300 p-4 text-xs font-mono overflow-x-auto whitespace-pre-wrap custom-scrollbar max-h-[300px]">
                    {JSON.stringify(viewingLog, null, 2)}
                  </pre>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
      {isLoggingOut && (
        <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-900/80 backdrop-blur-sm">
          <Loader />
        </div>
      )}
    </div>
  );
}

function AdminStatCard({ title, value, icon, color }) {
  const styles = {
    indigo: {
      text: "text-indigo-600",
      bg: "bg-indigo-100",
      border: "border-l-indigo-500",
    },
    purple: {
      text: "text-purple-600",
      bg: "bg-purple-100",
      border: "border-l-purple-500",
    },
    emerald: {
      text: "text-emerald-600",
      bg: "bg-emerald-100",
      border: "border-l-emerald-500",
    },
  };
  const s = styles[color] || styles.indigo;
  return (
    <div
      className={`bg-white p-5 rounded-xl border border-slate-200 border-l-4 ${s.border} shadow-sm flex flex-col justify-between h-full`}
    >
      <div className="flex justify-between items-start mb-3">
        <p className="text-slate-600 text-sm font-bold leading-tight pr-2">
          {title}
        </p>
        <div
          className={`w-10 h-10 shrink-0 rounded-lg flex items-center justify-center ${s.bg} ${s.text} text-[18px]`}
        >
          <Icon name={icon} />
        </div>
      </div>
      <h3 className="text-3xl font-black text-slate-800 tracking-tight">
        {value}
      </h3>
    </div>
  );
}
