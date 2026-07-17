import { useEffect, useMemo, useRef, useState } from "react";
import {
  Field,
  Icon,
  Input,
  Pagination,
  PrimaryButton,
  Swal,
  useChart,
  Modal,
} from "../ui.jsx";

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
    second: "2-digit",
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

function getInitials(name) {
  const clean = String(name || "").trim();
  if (!clean) return "U";
  const parts = clean.split(" ");
  if (parts.length > 1) {
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }
  return clean.slice(0, 2).toUpperCase();
}

function getAvatarGradient(name) {
  const gradients = [
    "from-blue-500 to-indigo-500",
    "from-emerald-400 to-teal-500",
    "from-violet-500 to-purple-600",
    "from-amber-400 to-orange-500",
    "from-rose-400 to-pink-500",
  ];
  let hash = 0;
  const str = String(name || "");
  for (let i = 0; i < str.length; i++) {
    hash = str.charCodeAt(i) + ((hash << 5) - hash);
  }
  const index = Math.abs(hash) % gradients.length;
  return gradients[index];
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
      role: user.role || usersById.get(user.id)?.role || "Teacher",
      status: user.status || usersById.get(user.id)?.status || "active",
    });
  });
  return Array.from(usersById.values()).sort((a, b) =>
    displayUserName(a).localeCompare(displayUserName(b), "th"),
  );
}

export function AdminPage({ firebase }) {
  const db = firebase.db;
  const chartRef = useRef(null);
  const [session, setSession] = useState(() => {
    const raw = sessionStorage.getItem("examAdminSession");
    return raw ? JSON.parse(raw) : null;
  });
  const [activePage, setActivePage] = useState("dashboard");
  const [loading, setLoading] = useState(false);
  const [logCollection, setLogCollection] = useState(LOG_COLLECTIONS[0]);
  const [loginForm, setLoginForm] = useState({ aname: "", apassword: "" });

  const [userForm, setUserForm] = useState({
    id: "",
    displayName: "",
    email: "",
    role: "Teacher",
  });
  const [editingUser, setEditingUser] = useState(null);
  const [isFormOpen, setIsFormOpen] = useState(false);

  const [search, setSearch] = useState("");
  const [logSearch, setLogSearch] = useState("");
  const [usersPage, setUsersPage] = useState(1);
  const [logsPage, setLogsPage] = useState(1);

  const [data, setData] = useState({
    admins: [],
    rawUsers: [],
    logs: [],
    exams: [],
    results: [],
    students: [],
  });

  useEffect(() => {
    if (!session) return;

    let unsubscribes = [];
    setLoading(true);

    async function initRealtime() {
      try {
        const [adminsName, logsName] = await Promise.all([
          getFirstExistingCollection(db, ADMIN_COLLECTIONS),
          getFirstExistingCollection(db, LOG_COLLECTIONS),
        ]);
        setLogCollection(logsName);

        // 1. Admins
        unsubscribes.push(
          db.collection(adminsName).onSnapshot(
            (snap) => {
              const admins = snap.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
              }));
              setData((prev) => ({ ...prev, admins }));
            },
            (err) => console.warn(err),
          ),
        );

        // 2. Logs
        unsubscribes.push(
          db.collection(logsName).onSnapshot(
            (snap) => {
              const now = Date.now();
              const SEVEN_DAYS = 7 * 24 * 60 * 60 * 1000;
              const logsToKeep = [];
              const logsToDelete = [];
              snap.docs.forEach((doc) => {
                const log = { id: doc.id, ...doc.data() };
                const t = toDate(log.datetime)?.getTime();
                if (t && now - t > SEVEN_DAYS) logsToDelete.push(log.id);
                else logsToKeep.push(log);
              });

              if (logsToDelete.length > 0) {
                Promise.resolve()
                  .then(async () => {
                    for (let i = 0; i < logsToDelete.length; i += 450) {
                      const batch = db.batch();
                      logsToDelete
                        .slice(i, i + 450)
                        .forEach((id) =>
                          batch.delete(db.collection(logsName).doc(id)),
                        );
                      await batch.commit();
                    }
                  })
                  .catch(console.warn);
              }

              logsToKeep.sort(
                (a, b) =>
                  (toDate(b.datetime)?.getTime() || 0) -
                  (toDate(a.datetime)?.getTime() || 0),
              );
              setData((prev) => ({ ...prev, logs: logsToKeep }));
            },
            (err) => console.warn(err),
          ),
        );

        // 3. Raw Users
        unsubscribes.push(
          db.collection("users").onSnapshot(
            (snap) => {
              const rawUsers = snap.docs.map((doc) => ({
                id: doc.id,
                ...doc.data(),
              }));
              setData((prev) => ({ ...prev, rawUsers }));
            },
            (err) => console.warn(err),
          ),
        );

        // 4. Subcollections via collectionGroup
        const subcollections = ["exams", "results", "students"];
        subcollections.forEach((col) => {
          unsubscribes.push(
            db.collectionGroup(col).onSnapshot(
              (snap) => {
                const items = snap.docs
                  .map((doc) => ({
                    id: doc.id,
                    owner: doc.ref?.parent?.parent?.id || null,
                    ...doc.data(),
                  }))
                  .filter((doc) => doc.owner);

                setData((prev) => ({ ...prev, [col]: items }));
              },
              (err) => console.warn(err),
            ),
          );
        });
      } catch (err) {
        console.error(err);
        Swal().fire("Error starting real-time listeners", err.message, "error");
      } finally {
        setLoading(false);
      }
    }

    initRealtime();

    return () => {
      unsubscribes.forEach((unsub) => unsub());
    };
  }, [session, db]);

  async function refresh() {
    // Left empty since data is now real-time. This prevents UI breaks on existing refresh calls.
  }

  async function login(event) {
    event.preventDefault();
    setLoading(true);
    try {
      const collectionName = await getFirstExistingCollection(
        db,
        ADMIN_COLLECTIONS,
      );
      const snapshot = await db
        .collection(collectionName)
        .where("aname", "==", loginForm.aname.trim())
        .where("apassword", "==", loginForm.apassword)
        .limit(1)
        .get();

      let admin = snapshot.docs[0]
        ? { id: snapshot.docs[0].id, ...snapshot.docs[0].data() }
        : null;

      if (!admin) {
        const byId = await db
          .collection(collectionName)
          .doc(loginForm.aname.trim())
          .get();
        if (byId.exists && byId.data().apassword === loginForm.apassword) {
          admin = { id: byId.id, ...byId.data() };
        }
      }

      if (!admin) {
        await writeAnonymousLog(
          `เข้าสู่ระบบ Admin ไม่สำเร็จ: ${loginForm.aname}`,
        );
        Swal().fire(
          "เข้าสู่ระบบไม่สำเร็จ",
          "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง",
          "error",
        );
        return;
      }

      const nextSession = {
        aid: admin.aid || admin.id,
        aname: admin.aname || admin.id,
      };
      sessionStorage.setItem("examAdminSession", JSON.stringify(nextSession));
      setSession(nextSession);
      await writeAnonymousLog(`เข้าสู่ระบบ Admin สำเร็จ: ${nextSession.aname}`);
    } catch (error) {
      Swal().fire("เข้าสู่ระบบไม่สำเร็จ", error.message, "error");
    } finally {
      setLoading(false);
    }
  }

  async function writeAnonymousLog(activity) {
    const collectionName = await getFirstExistingCollection(
      db,
      LOG_COLLECTIONS,
    );
    setLogCollection(collectionName);
    const docRef = db.collection(collectionName).doc();
    await docRef.set({
      logid: docRef.id,
      activity,
      datetime: window.firebase.firestore.FieldValue.serverTimestamp(),
    });
  }

  function logout() {
    sessionStorage.removeItem("examAdminSession");
    setSession(null);
    setActivePage("dashboard");
  }

  async function saveUser(event) {
    event.preventDefault();
    const id = (editingUser?.id || userForm.id || userForm.email).trim();
    if (!id) return;
    await db
      .collection("users")
      .doc(id)
      .set(
        {
          displayName: userForm.displayName.trim(),
          email: userForm.email.trim() || id,
          role: userForm.role,
          status: editingUser?.status || "active",
          updatedAt: window.firebase.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    await writeLog(`${editingUser ? "แก้ไข" : "เพิ่ม"}ข้อมูลผู้ใช้งาน: ${id}`);
    setEditingUser(null);
    setUserForm({ id: "", displayName: "", email: "", role: "Teacher" });
    setIsFormOpen(false);
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
      role: user.role || "Teacher",
    });
    setIsFormOpen(true);
  }

  function openAddUserModal() {
    setEditingUser(null);
    setUserForm({ id: "", displayName: "", email: "", role: "Teacher" });
    setIsFormOpen(true);
  }

  const allUsers = useMemo(() => {
    const owners = new Map();
    [...data.exams, ...data.results, ...data.students].forEach((doc) => {
      const owner = doc.owner;
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
    });
    return mergeUsers(data.rawUsers, Array.from(owners.values()));
  }, [data.rawUsers, data.exams, data.results, data.students]);

  const filteredUsers = useMemo(() => {
    const keyword = search.trim().toLowerCase();
    if (!keyword) return allUsers;
    return allUsers.filter((user) =>
      [user.id, user.email, displayUserName(user), user.role]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(keyword)),
    );
  }, [allUsers, search]);

  const filteredLogs = useMemo(() => {
    const keyword = logSearch.trim().toLowerCase();
    if (!keyword) return data.logs;
    return data.logs.filter((log) =>
      [log.activity, log.userEmail, log.user, log.admin, log.logid, log.id]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(keyword)),
    );
  }, [data.logs, logSearch]);

  const PAGE_SIZE = 10;
  const usersTotalPages = Math.max(
    1,
    Math.ceil(filteredUsers.length / PAGE_SIZE),
  );
  const paginatedUsers = useMemo(() => {
    const start = (usersPage - 1) * PAGE_SIZE;
    return filteredUsers.slice(start, start + PAGE_SIZE);
  }, [filteredUsers, usersPage]);

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
    setLogsPage(1);
  }, [logSearch]);

  useEffect(() => {
    setUsersPage((page) => Math.min(page, usersTotalPages));
  }, [usersTotalPages]);

  useEffect(() => {
    setLogsPage((page) => Math.min(page, logsTotalPages));
  }, [logsTotalPages]);

  const monthlyStats = useMemo(() => {
    const labels = [];
    const counts = {};
    const now = new Date();
    for (let i = 11; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const label = d.toLocaleDateString("th-TH", {
        month: "short",
        year: "2-digit",
      });
      labels.push(label);
      counts[label] = 0;
    }
    data.results.forEach((result) => {
      const date = toDate(
        result.createdAt || result.datetime || result.date || result.timestamp,
      );
      if (!date) return;
      const label = date.toLocaleDateString("th-TH", {
        month: "short",
        year: "2-digit",
      });
      if (counts[label] !== undefined) counts[label] += 1;
    });
    return { labels, values: labels.map((label) => counts[label]) };
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
            backgroundColor: "rgba(16, 185, 129, 0.08)",
            borderColor: "#10b981",
            borderWidth: 3,
            fill: true,
            tension: 0.35,
            pointBackgroundColor: "#ffffff",
            pointBorderColor: "#10b981",
            pointBorderWidth: 2.5,
            pointRadius: 4,
            pointHoverRadius: 6,
            pointHoverBackgroundColor: "#10b981",
            pointHoverBorderColor: "#ffffff",
            pointHoverBorderWidth: 2,
          },
        ],
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: {
            beginAtZero: true,
            grid: {
              color: "rgba(226, 232, 240, 0.6)",
              drawBorder: false,
            },
            ticks: {
              font: {
                family: "'Sarabun', 'Inter'",
                size: 11,
              },
              color: "#64748b",
            },
          },
          x: {
            grid: {
              display: false,
            },
            ticks: {
              font: {
                family: "'Sarabun', 'Inter'",
                size: 11,
              },
              color: "#64748b",
            },
          },
        },
        plugins: {
          legend: { display: false },
          tooltip: {
            backgroundColor: "#1e293b",
            titleFont: { family: "'Sarabun', 'Inter'", size: 12 },
            bodyFont: { family: "'Sarabun', 'Inter'", size: 12 },
            padding: 10,
            cornerRadius: 8,
            displayColors: false,
          },
        },
      },
    },
    [monthlyStats, activePage],
  );

  function exportLogsToCSV() {
    if (!data.logs.length) {
      Swal().fire(
        "ไม่พบข้อมูล",
        "ไม่มีรายการประวัติการใช้งานที่จะนำออก",
        "warning",
      );
      return;
    }
    const headers = ["วัน-เวลา", "ผู้ใช้ / ผู้ดูแล", "Log ID", "กิจกรรม"];
    const rows = data.logs.map((log) => [
      formatDateTime(log.datetime),
      log.userEmail || log.user || log.admin || "-",
      log.logid || log.id,
      log.activity || "-",
    ]);
    const csvContent =
      "\uFEFF" + // UTF-8 BOM
      [
        headers.join(","),
        ...rows.map((e) =>
          e.map((val) => `"${String(val).replace(/"/g, '""')}"`).join(","),
        ),
      ].join("\n");

    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.setAttribute("href", url);
    link.setAttribute(
      "download",
      `system_logs_${new Date().toISOString().split("T")[0]}.csv`,
    );
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  }

  function getLogActivityColor(activity = "") {
    if (
      activity.includes("สำเร็จ") ||
      activity.includes("ปลดระงับ") ||
      activity.includes("เข้าสู่ระบบ Admin")
    ) {
      return "text-emerald-400";
    }
    if (
      activity.includes("ไม่สำเร็จ") ||
      activity.includes("ลบข้อมูล") ||
      activity.includes("ระงับบัญชี")
    ) {
      return "text-rose-400";
    }
    if (activity.includes("แก้ไขข้อมูล") || activity.includes("เพิ่มข้อมูล")) {
      return "text-amber-300";
    }
    return "text-slate-300";
  }

  if (!session) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center p-4 font-['Sarabun'] relative overflow-hidden">
        {/* Glow Effects */}
        <div className="absolute top-[-20%] left-[-10%] w-[50%] h-[50%] bg-emerald-500/10 rounded-full blur-[120px] pointer-events-none" />
        <div className="absolute bottom-[-20%] right-[-10%] w-[50%] h-[50%] bg-blue-500/10 rounded-full blur-[120px] pointer-events-none" />

        <form
          onSubmit={login}
          className="relative backdrop-blur-md bg-slate-900/60 p-8 sm:p-10 rounded-2xl w-full max-w-md border border-slate-800 shadow-2xl transition-all duration-300 hover:border-slate-700/80"
        >
          {/* Top Line Gradient */}
          <div className="absolute top-0 left-0 right-0 h-[2px] bg-gradient-to-r from-emerald-500 via-teal-500 to-blue-500 rounded-t-2xl" />

          <div className="text-center mb-8">
            <div className="relative inline-flex items-center justify-center bg-slate-800/80 text-emerald-400 w-16 h-16 rounded-2xl mb-4 text-3xl border border-slate-700 shadow-inner group overflow-hidden">
              <div className="absolute inset-0 bg-gradient-to-tr from-emerald-500/15 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-300" />
              <Icon name="fa-user-shield" />
            </div>
            <h1 className="text-2xl font-extrabold text-white tracking-tight">
              Admin Control Panel
            </h1>
            <p className="text-slate-400 mt-2 text-sm">
              เข้าสู่ระบบสำหรับผู้ดูแลระบบ
            </p>
          </div>

          <div className="space-y-5">
            <div>
              <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">
                ชื่อผู้ใช้ผู้ดูแลระบบ (Username)
              </label>
              <div className="relative">
                <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500 text-sm">
                  <Icon name="fa-user" />
                </span>
                <input
                  type="text"
                  value={loginForm.aname}
                  onChange={(event) =>
                    setLoginForm({ ...loginForm, aname: event.target.value })
                  }
                  placeholder="admin_username"
                  required
                  className="w-full pl-10 pr-4 py-3 bg-slate-950/80 border border-slate-800 rounded-xl text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 transition-all duration-300 text-sm"
                />
              </div>
            </div>

            <div>
              <label className="block text-xs font-bold text-slate-300 uppercase tracking-wider mb-2">
                รหัสผ่าน (Password)
              </label>
              <div className="relative">
                <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500 text-sm">
                  <Icon name="fa-lock" />
                </span>
                <input
                  type="password"
                  value={loginForm.apassword}
                  onChange={(event) =>
                    setLoginForm({
                      ...loginForm,
                      apassword: event.target.value,
                    })
                  }
                  placeholder="••••••••"
                  required
                  className="w-full pl-10 pr-4 py-3 bg-slate-950/80 border border-slate-800 rounded-xl text-white placeholder-slate-600 focus:outline-none focus:ring-2 focus:ring-emerald-500/50 focus:border-emerald-500 transition-all duration-300 text-sm"
                />
              </div>
            </div>

            <button
              type="submit"
              disabled={loading}
              className="w-full mt-2 relative overflow-hidden group flex items-center justify-center gap-2 font-bold py-3 px-4 rounded-xl text-white bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-500 hover:to-teal-500 transition-all duration-300 shadow-[0_4px_20px_0_rgba(16,185,129,0.25)] hover:shadow-[0_4px_25px_0_rgba(16,185,129,0.4)] disabled:opacity-60 disabled:cursor-not-allowed"
            >
              <Icon
                name={loading ? "fa-spinner fa-spin" : "fa-right-to-bracket"}
              />
              <span>{loading ? "กำลังโหลด..." : "เข้าสู่ระบบผู้ดูแล"}</span>
            </button>
          </div>
        </form>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-slate-50 text-slate-800 font-['Sarabun']">
      {/* Sidebar */}
      <aside className="w-72 bg-white border-r border-slate-200 flex flex-col shrink-0 z-20">
        <div className="h-[73px] px-6 border-b border-slate-100 flex items-center justify-between">
          <div className="flex items-center gap-4 font-sans">
            <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-emerald-500 to-teal-500 flex items-center justify-center text-white shadow-md">
              <Icon name="fa-user-shield" />
            </div>
            <span className="text-xl font-extrabold tracking-tight text-slate-800">
              Exam Grading
            </span>
          </div>
        </div>

        {/* Sidebar Nav */}
        <nav className="flex-1 p-4 space-y-1.5 overflow-y-auto">
          {[
            ["dashboard", "fa-chart-line", "ภาพรวมระบบ (Dashboard)"],
            ["users", "fa-users-gear", "จัดการผู้ใช้งาน"],
            ["logs", "fa-list-check", "ประวัติการใช้งาน"],
          ].map(([id, icon, label]) => {
            const isActive = activePage === id;
            return (
              <button
                key={id}
                onClick={() => setActivePage(id)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg text-left transition-all duration-200 ${
                  isActive
                    ? "bg-emerald-50 text-emerald-600 border-l-4 border-emerald-500 font-bold"
                    : "border-l-4 border-transparent text-slate-600 hover:bg-emerald-50/50 hover:text-emerald-600"
                }`}
              >
                <Icon name={icon} />
                <span className="text-sm font-medium">{label}</span>
              </button>
            );
          })}
        </nav>

        {/* Admin Profile Details & Logout */}
        <div className="p-4 border-t border-slate-100 space-y-3">
          <div className="flex items-center gap-3 p-2 bg-slate-50 rounded-xl border border-slate-100">
            <div className="w-10 h-10 rounded-lg bg-emerald-100 border border-emerald-200 flex items-center justify-center text-emerald-600 font-bold text-lg">
              <Icon name="fa-user-tie" />
            </div>
            <div className="min-w-0 flex-1">
              <p className="text-xs font-bold text-slate-800 truncate">
                {session?.aname || "Admin"}
              </p>
              <div className="flex items-center gap-1.5 mt-0.5">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                <p className="text-[10px] text-slate-500 font-medium">
                  Online • Administrator
                </p>
              </div>
            </div>
          </div>
          <button
            onClick={logout}
            className="w-full flex items-center justify-center gap-2 text-rose-500 hover:text-rose-600 bg-white hover:bg-rose-50 border border-rose-200 py-2.5 rounded-xl transition-all duration-200 text-sm font-semibold"
          >
            <Icon name="fa-right-from-bracket" />
            <span>ออกจากระบบ</span>
          </button>
        </div>
      </aside>

      {/* Main Content Area */}
      <main className="flex-1 flex flex-col h-screen overflow-hidden bg-slate-50">
        {/* Header */}
        <header className="bg-white border-b border-slate-200 h-[73px] px-6 sticky top-0 z-40 flex justify-between items-center shrink-0">
          <div className="flex items-center gap-3">
            <h2 className="text-lg font-bold text-slate-850">
              {activePage === "dashboard" && "ภาพรวมระบบ (Dashboard)"}
              {activePage === "users" && "จัดการผู้ใช้งาน"}
              {activePage === "logs" && "ประวัติการใช้งาน"}
            </h2>
          </div>
          <div className="flex items-center gap-4">
            <button
              onClick={refresh}
              className={`inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-bold rounded-lg border border-emerald-200 bg-emerald-50/50 text-emerald-700 hover:bg-emerald-100 transition-colors ${loading ? "opacity-70 cursor-not-allowed" : ""}`}
              disabled={loading}
            >
              <Icon name={`fa-rotate ${loading ? "fa-spin" : ""}`} />
              <span>{loading ? "กำลังโหลด..." : "รีเฟรชข้อมูล"}</span>
            </button>
            <span className="hidden sm:inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-slate-100 text-slate-600 border border-slate-200">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              สิทธิ์: ผู้ดูแลระบบ
            </span>
          </div>
        </header>

        {/* Inner Scroll Container */}
        <div className="flex-1 overflow-y-auto p-6 space-y-6">
          {/* Dashboard Tab */}
          {activePage === "dashboard" && (
            <div className="space-y-6 animate-in fade-in duration-300">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <AdminStat
                  gradient="from-blue-500 to-indigo-600"
                  iconColor="text-white"
                  icon="fa-users"
                  title="จำนวนบัญชีผู้ใช้งานทั้งหมด"
                  value={`${allUsers.length} คน`}
                />
                <AdminStat
                  gradient="from-amber-500 to-orange-600"
                  iconColor="text-white"
                  icon="fa-file-signature"
                  title="จำนวนการสอบทั้งหมดในระบบ"
                  value={`${data.exams.length} ครั้ง`}
                />
                <AdminStat
                  gradient="from-emerald-500 to-teal-600"
                  iconColor="text-white"
                  icon="fa-check-double"
                  title="จำนวนรายการตรวจที่บันทึกแล้ว"
                  value={`${data.results.length} รายการ`}
                />
              </div>

              <section className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm">
                <div className="flex items-center justify-between mb-6">
                  <div>
                    <h3 className="text-base font-bold text-slate-800">
                      สถิติการตรวจข้อสอบรายเดือน
                    </h3>
                    <p className="text-xs text-slate-400 mt-0.5">
                      ยอดการตรวจข้อสอบสะสมแยกตามช่วงเวลา 12 เดือนล่าสุด
                    </p>
                  </div>
                  <div className="flex items-center gap-1.5 text-xs text-emerald-600 font-bold bg-emerald-50 px-2.5 py-1 rounded-full border border-emerald-100">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                    <span>อัปเดตแบบเรียลไทม์</span>
                  </div>
                </div>
                <div className="h-72 relative">
                  <canvas ref={chartRef} />
                </div>
              </section>
            </div>
          )}

          {/* Manage Users Tab */}
          {activePage === "users" && (
            <div className="space-y-6 animate-in fade-in duration-300">
              {/* User management sub-bar */}
              <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-800">
                    ข้อมูลบัญชีผู้ใช้งานระบบ
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    ค้นหา เพิ่ม แก้ไข และเปิด/ปิดการใช้งานผู้ใช้งาน
                  </p>
                </div>
                <div className="flex w-full sm:w-auto items-center gap-2">
                  <div className="relative flex-1 sm:w-64">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-xs">
                      <Icon name="fa-magnifying-glass" />
                    </span>
                    <Input
                      value={search}
                      onChange={(event) => setSearch(event.target.value)}
                      placeholder="ค้นหาชื่อ, อีเมล, รหัส หรือบทบาท..."
                      className="pl-9 bg-white text-sm"
                    />
                  </div>
                  <PrimaryButton
                    onClick={openAddUserModal}
                    variant="success"
                    className="shrink-0 text-sm py-2 px-3.5 rounded-lg"
                  >
                    <Icon name="fa-user-plus" />
                    <span className="hidden sm:inline">เพิ่มผู้ใช้ใหม่</span>
                  </PrimaryButton>
                </div>
              </div>

              {/* Users Table */}
              <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse text-sm">
                    <thead>
                      <tr className="bg-slate-50 text-slate-500 border-b border-slate-100 font-bold">
                        <th className="p-4">ผู้ใช้งาน</th>
                        <th className="p-4">รหัส / อีเมลหลัก</th>
                        <th className="p-4 text-center">บทบาท</th>
                        <th className="p-4 text-center">สถานะบัญชี</th>
                        <th className="p-4 text-center">จัดการ</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-100">
                      {paginatedUsers.map((user) => {
                        const name = displayUserName(user);
                        const isSuspended = user.status === "suspended";
                        const initials = getInitials(name);
                        const gradient = getAvatarGradient(name);
                        return (
                          <tr
                            key={user.id}
                            className={`hover:bg-slate-50/50 transition-colors ${
                              isSuspended ? "bg-rose-50/20" : ""
                            }`}
                          >
                            <td className="p-4">
                              <div className="flex items-center gap-3">
                                <div
                                  className={`w-9 h-9 rounded-full bg-gradient-to-tr ${gradient} text-white font-bold flex items-center justify-center text-xs shadow-sm`}
                                >
                                  {initials}
                                </div>
                                <div className="min-w-0">
                                  <span
                                    className={`font-semibold text-slate-700 block text-sm ${isSuspended ? "line-through text-slate-400" : ""}`}
                                  >
                                    {name}
                                  </span>
                                  <span className="text-xs text-slate-400 block truncate max-w-xs">
                                    {user.email || user.id}
                                  </span>
                                </div>
                              </div>
                            </td>
                            <td className="p-4 text-slate-500 text-xs font-mono">
                              {user.id}
                            </td>
                            <td className="p-4 text-center">
                              <span
                                className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-bold border ${
                                  user.role === "Admin"
                                    ? "bg-violet-50 text-violet-700 border-violet-200"
                                    : user.role === "Staff"
                                      ? "bg-teal-50 text-teal-700 border-teal-200"
                                      : "bg-blue-50 text-blue-700 border-blue-200"
                                }`}
                              >
                                {user.role || "Teacher"}
                              </span>
                            </td>
                            <td className="p-4 text-center">
                              {isSuspended ? (
                                <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-rose-50 text-rose-600 border border-rose-200">
                                  <span className="w-1.5 h-1.5 rounded-full bg-rose-500" />
                                  ถูกระงับ
                                </span>
                              ) : (
                                <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold bg-emerald-50 text-emerald-600 border border-emerald-200">
                                  <span className="relative flex h-1.5 w-1.5">
                                    <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                                    <span className="relative inline-flex rounded-full h-1.5 w-1.5 bg-emerald-500"></span>
                                  </span>
                                  ใช้งานปกติ
                                </span>
                              )}
                            </td>
                            <td className="p-4 text-center whitespace-nowrap">
                              <div className="flex items-center justify-center gap-1.5">
                                <button
                                  onClick={() => startEdit(user)}
                                  className="p-1.5 bg-amber-50 hover:bg-amber-100 text-amber-600 hover:text-amber-700 border border-amber-200/50 hover:border-amber-300 rounded-lg transition-colors text-xs"
                                  title="แก้ไขข้อมูล"
                                >
                                  <Icon name="fa-pen-to-square" />
                                </button>
                                <button
                                  onClick={() => toggleUserStatus(user)}
                                  className={`p-1.5 border rounded-lg transition-colors text-xs ${
                                    isSuspended
                                      ? "bg-emerald-50 hover:bg-emerald-100 text-emerald-600 hover:text-emerald-700 border-emerald-200/50 hover:border-emerald-300"
                                      : "bg-rose-50 hover:bg-rose-100 text-rose-500 hover:text-rose-600 border-rose-200/50 hover:border-rose-300"
                                  }`}
                                  title={
                                    isSuspended
                                      ? "ปลดระงับใช้งาน"
                                      : "ระงับการใช้งาน"
                                  }
                                >
                                  <Icon
                                    name={isSuspended ? "fa-unlock" : "fa-ban"}
                                  />
                                </button>
                                <button
                                  onClick={() => removeUser(user)}
                                  className="p-1.5 bg-slate-100 hover:bg-rose-50 text-slate-500 hover:text-rose-600 border border-slate-200/50 hover:border-rose-200 rounded-lg transition-colors text-xs"
                                  title="ลบผู้ใช้งาน"
                                >
                                  <Icon name="fa-trash" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        );
                      })}
                      {!filteredUsers.length && (
                        <tr>
                          <td
                            colSpan="5"
                            className="p-8 text-center text-slate-400 font-medium"
                          >
                            <div className="flex flex-col items-center justify-center gap-2">
                              <Icon
                                name="fa-users-slash"
                                className="text-3xl text-slate-300"
                              />
                              <span>ไม่พบข้อมูลผู้ใช้งานที่ตรงตามคำค้นหา</span>
                            </div>
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {filteredUsers.length > 0 && (
                  <div className="flex items-center justify-between gap-3 border-t border-slate-100 px-4 py-3 text-xs sm:text-sm bg-slate-50/50">
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

              {/* Add/Edit User Modal */}
              <Modal
                isOpen={isFormOpen}
                onClose={() => setIsFormOpen(false)}
                title={
                  editingUser
                    ? "แก้ไขข้อมูลผู้ใช้งาน"
                    : "เพิ่มผู้ใช้งานระบบคนใหม่"
                }
                maxWidth="max-w-lg"
              >
                <form
                  onSubmit={saveUser}
                  className="space-y-4 font-['Sarabun']"
                >
                  <div className="grid grid-cols-1 gap-4">
                    <Field label="ชื่อผู้ใช้ / รหัสประจำตัว (Username / ID)">
                      <Input
                        value={userForm.id}
                        disabled={Boolean(editingUser)}
                        onChange={(event) =>
                          setUserForm({ ...userForm, id: event.target.value })
                        }
                        placeholder="กรอกชื่อผู้ใช้ เช่น teacher_01 หรือ teacher@school.ac.th"
                        required
                      />
                    </Field>
                    <Field label="ชื่อ-นามสกุลจริง (Display Name)">
                      <Input
                        value={userForm.displayName}
                        onChange={(event) =>
                          setUserForm({
                            ...userForm,
                            displayName: event.target.value,
                          })
                        }
                        placeholder="ภาษาไทย หรือภาษาอังกฤษ"
                        required
                      />
                    </Field>
                    <Field label="อีเมลสำหรับติดต่อ (Email Address)">
                      <Input
                        value={userForm.email}
                        onChange={(event) =>
                          setUserForm({
                            ...userForm,
                            email: event.target.value,
                          })
                        }
                        placeholder="teacher@school.ac.th"
                        type="email"
                        required
                      />
                    </Field>
                    <Field label="บทบาทหน้าที่ในระบบ (System Role)">
                      <select
                        value={userForm.role}
                        onChange={(event) =>
                          setUserForm({ ...userForm, role: event.target.value })
                        }
                        className="w-full px-4 py-2 bg-white border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 transition-colors text-sm"
                      >
                        <option value="Teacher">Teacher (ผู้ตรวจข้อสอบ)</option>
                        <option value="Admin">Admin (ผู้ดูแลระบบหลัก)</option>
                        <option value="Staff">
                          Staff (เจ้าหน้าที่ปฏิบัติงาน)
                        </option>
                      </select>
                    </Field>
                  </div>

                  <div className="flex justify-end gap-2.5 pt-4 border-t border-slate-100">
                    <button
                      type="button"
                      onClick={() => setIsFormOpen(false)}
                      className="px-4 py-2 text-sm font-semibold border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 rounded-lg transition-colors"
                    >
                      ยกเลิก
                    </button>
                    <PrimaryButton
                      type="submit"
                      variant="success"
                      className="text-sm px-5"
                    >
                      <Icon name="fa-floppy-disk" />
                      <span>บันทึกข้อมูล</span>
                    </PrimaryButton>
                  </div>
                </form>
              </Modal>
            </div>
          )}

          {/* System Logs Tab */}
          {activePage === "logs" && (
            <div className="space-y-6 animate-in fade-in duration-300">
              {/* Log actions bar */}
              <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
                <div>
                  <h3 className="text-base font-bold text-slate-800">
                    ประวัติการดำเนินกิจกรรมของระบบ
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    บันทึกเหตุการณ์การตรวจข้อสอบ การล็อกอิน
                    และการจัดการผู้ใช้อัตโนมัติ
                  </p>
                </div>

                <div className="flex items-center gap-2 w-full sm:w-auto">
                  <div className="relative flex-1 sm:w-64">
                    <span className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 text-xs">
                      <Icon name="fa-magnifying-glass" />
                    </span>
                    <Input
                      value={logSearch}
                      onChange={(event) => setLogSearch(event.target.value)}
                      placeholder="ค้นหากิจกรรม, ผู้ใช้, Log ID..."
                      className="pl-9 bg-white text-sm"
                    />
                  </div>
                  <button
                    onClick={exportLogsToCSV}
                    className="inline-flex items-center gap-1.5 px-3 py-2 text-sm font-semibold text-slate-700 bg-white border border-slate-200 hover:bg-slate-50 active:bg-slate-100 rounded-lg shadow-sm transition-colors"
                    title="ดาวน์โหลดเป็นไฟล์ Excel/CSV"
                  >
                    <Icon name="fa-file-csv" />
                    <span>ส่งออกข้อมูล</span>
                  </button>
                </div>
              </div>

              {/* Developer Terminal Console Layout */}
              <div className="bg-slate-950 rounded-xl border border-slate-900 shadow-lg overflow-hidden flex flex-col font-mono text-xs">
                {/* Console Bar Header */}
                <div className="bg-slate-900 px-4 py-3 border-b border-slate-950 flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="flex gap-1.5">
                      <span className="w-3 h-3 rounded-full bg-rose-500/80 inline-block" />
                      <span className="w-3 h-3 rounded-full bg-amber-400/80 inline-block" />
                      <span className="w-3 h-3 rounded-full bg-emerald-500/80 inline-block" />
                    </div>
                    <span className="text-[11px] font-bold text-slate-400 ml-2">
                      system_console_stream.sh
                    </span>
                  </div>
                  <div className="flex items-center gap-2 text-slate-500 font-semibold text-[10px]">
                    <span className="text-emerald-500 font-bold bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-900/30">
                      Firestore Connected
                    </span>
                    <span>Collection: {logCollection}</span>
                  </div>
                </div>

                {/* Console Log Panel */}
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="border-b border-slate-900 text-slate-400 bg-slate-900/40 font-bold uppercase tracking-wider text-[10px]">
                        <th className="p-3 w-48">Timestamp (วัน-เวลา)</th>
                        <th className="p-3 w-44">User/Operator</th>
                        <th className="p-3 w-48 font-mono">Event Log ID</th>
                        <th className="p-3">Activity description</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-900/50">
                      {paginatedLogs.map((log) => {
                        const operator =
                          log.userEmail || log.user || log.admin || "-";
                        return (
                          <tr
                            key={log.id}
                            className="hover:bg-slate-900/60 transition-colors"
                          >
                            <td className="p-3 text-slate-400 whitespace-nowrap font-sans">
                              {formatDateTime(log.datetime)}
                            </td>
                            <td className="p-3 text-white font-medium truncate max-w-[170px]">
                              {operator}
                            </td>
                            <td className="p-3 text-slate-500 font-mono">
                              {log.logid || log.id}
                            </td>
                            <td
                              className={`p-3 font-semibold ${getLogActivityColor(log.activity)}`}
                            >
                              {log.activity || "-"}
                            </td>
                          </tr>
                        );
                      })}
                      {!filteredLogs.length && (
                        <tr>
                          <td
                            colSpan="4"
                            className="p-8 text-center text-slate-500"
                          >
                            <div className="flex flex-col items-center justify-center gap-1.5 py-4">
                              <span className="text-slate-650 font-bold">
                                &gt;_ NO_ACTIVITY_LOGS_FOUND
                              </span>
                              <span className="text-[10px] text-slate-600">
                                ตรวจสอบคำค้นหาหรือตัวกรองใหม่อีกครั้ง
                              </span>
                            </div>
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>

                {/* Console Footer Pagination */}
                {filteredLogs.length > 0 && (
                  <div className="flex flex-col sm:flex-row items-center justify-between gap-3 border-t border-slate-900 px-4 py-3 bg-slate-900/25">
                    <span className="text-slate-400 text-[11px] font-medium font-sans">
                      LOG_STREAM: Showing {(logsPage - 1) * PAGE_SIZE + 1}-
                      {Math.min(logsPage * PAGE_SIZE, filteredLogs.length)} of{" "}
                      {filteredLogs.length} events
                    </span>
                    <div className="dark-pagination">
                      <Pagination
                        count={logsTotalPages}
                        page={logsPage}
                        onChange={(_, value) => setLogsPage(value)}
                        variant="outlined"
                        shape="rounded"
                      />
                    </div>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

function AdminStat({ title, value, icon, gradient, iconColor }) {
  return (
    <div className="bg-white p-6 rounded-2xl border border-slate-100 shadow-sm flex items-center justify-between relative overflow-hidden">
      {/* Accent Gradient Glow */}
      <div
        className={`absolute top-0 right-0 w-24 h-24 bg-gradient-to-bl ${gradient} opacity-[0.03] rounded-bl-full pointer-events-none`}
      />

      <div>
        <p className="text-slate-400 text-xs font-bold uppercase tracking-wider mb-1.5">
          {title}
        </p>
        <h3 className="text-3xl font-extrabold text-slate-800 tracking-tight">
          {value}
        </h3>
      </div>
      <div
        className={`w-14 h-14 rounded-2xl flex items-center justify-center bg-gradient-to-tr ${gradient} ${iconColor} shadow-sm text-xl`}
      >
        <Icon name={icon} />
      </div>
    </div>
  );
}
