import { useEffect, useMemo, useRef, useState } from "react";
import { Field, Icon, Input, PrimaryButton, Swal, useChart } from "../ui.jsx";

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
  const [search, setSearch] = useState("");
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
      admin: session?.aname || loginForm.aname || "Admin",
    });
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

      setData({
        admins,
        users: allUsers,
        logs: logs.sort(
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

  const monthlyStats = useMemo(() => {
    const months = ["ต.ค.", "พ.ย.", "ธ.ค.", "ม.ค.", "ก.พ.", "มี.ค."];
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
        scales: { y: { beginAtZero: true } },
        plugins: { legend: { display: false } },
      },
    },
    [monthlyStats],
  );

  if (!session) {
    return (
      <div className="min-h-screen bg-zinc-900 flex items-center justify-center p-4 font-['Sarabun']">
        <form
          onSubmit={login}
          className="bg-white p-8 sm:p-10 rounded-xl  w-full max-w-md border-t-8 border-emerald-500"
        >
          <div className="text-center mb-8">
            <div className="bg-zinc-800 text-emerald-400 w-16 h-16 rounded-full flex items-center justify-center mx-auto mb-4 text-3xl">
              <Icon name="fa-user-shield" />
            </div>
            <h1 className="text-2xl font-bold text-zinc-800">
              Admin Control Panel
            </h1>
            <p className="text-zinc-500 mt-2">เข้าสู่ระบบสำหรับผู้ดูแลระบบ</p>
          </div>
          <div className="space-y-4">
            <Field label="ชื่อผู้ใช้ผู้ดูแลระบบ (Admin Username)">
              <Input
                value={loginForm.aname}
                onChange={(event) =>
                  setLoginForm({ ...loginForm, aname: event.target.value })
                }
                placeholder="admin_user"
                required
              />
            </Field>
            <Field label="รหัสผ่าน (Password)">
              <Input
                type="password"
                value={loginForm.apassword}
                onChange={(event) =>
                  setLoginForm({ ...loginForm, apassword: event.target.value })
                }
                placeholder="••••••••"
                required
              />
            </Field>
            <PrimaryButton
              type="submit"
              variant="success"
              className="w-full"
              disabled={loading}
            >
              <Icon name="fa-right-to-bracket" /> เข้าสู่ระบบผู้ดูแล
            </PrimaryButton>
          </div>
        </form>
      </div>
    );
  }

  return (
    <div className="flex h-screen overflow-hidden bg-zinc-100 text-zinc-800 font-['Sarabun']">
      <aside className="w-64 bg-zinc-900 text-zinc-300 flex flex-col shrink-0">
        <div className="p-6 border-b border-zinc-700 flex items-center gap-3">
          <Icon name="fa-user-shield" />
          <span className="text-lg font-bold text-white">Admin System</span>
        </div>
        <nav className="flex-1 p-4 space-y-2 overflow-y-auto">
          {[
            ["dashboard", "fa-chart-line", "ภาพรวมระบบ (Dashboard)"],
            ["users", "fa-users-gear", "จัดการผู้ใช้งาน"],
            ["logs", "fa-list-check", "ประวัติการใช้งาน"],
          ].map(([id, icon, label]) => (
            <button
              key={id}
              onClick={() => setActivePage(id)}
              className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl text-left transition ${activePage === id ? "bg-emerald-500 text-white" : "hover:bg-emerald-600 hover:text-white"}`}
            >
              <Icon name={icon} /> {label}
            </button>
          ))}
        </nav>
        <div className="p-4 border-t border-zinc-700">
          <button
            onClick={logout}
            className="w-full flex items-center justify-center gap-2 text-red-300 hover:bg-zinc-800 py-2 rounded-xl transition"
          >
            <Icon name="fa-right-from-bracket" /> ออกจากระบบ
          </button>
        </div>
      </aside>

      <main className="flex-1 flex flex-col h-screen overflow-y-auto">
        <header className="bg-white  p-4 flex justify-between items-center">
          <h2 className="text-xl font-bold text-zinc-800">
            {activePage === "dashboard" && "ภาพรวมระบบ (Dashboard)"}
            {activePage === "users" && "จัดการผู้ใช้งาน"}
            {activePage === "logs" && "ประวัติการใช้งาน"}
          </h2>
          <div className="flex items-center gap-4">
            <button
              onClick={refresh}
              className="text-sm font-bold text-emerald-700 hover:text-emerald-800"
              disabled={loading}
            >
              <Icon name="fa-rotate" /> รีเฟรช
            </button>
            <span className="hidden sm:inline text-zinc-600 font-medium">
              สิทธิ์: ผู้ดูแลระบบ
            </span>
            <div className="w-10 h-10 bg-emerald-100 rounded-full flex items-center justify-center text-emerald-800 font-bold border-2 border-emerald-500">
              <Icon name="fa-user-tie" />
            </div>
          </div>
        </header>

        <div className="p-6 space-y-6">
          {activePage === "dashboard" && (
            <div className="space-y-8">
              <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
                <AdminStat
                  color="blue"
                  icon="fa-users"
                  title="จำนวนบัญชีผู้ใช้งานทั้งหมด"
                  value={`${data.users.length} คน`}
                />
                <AdminStat
                  color="orange"
                  icon="fa-file-signature"
                  title="จำนวนการสอบทั้งหมดในระบบ"
                  value={`${data.exams.length} ครั้ง`}
                />
                <AdminStat
                  color="green"
                  icon="fa-check-double"
                  title="จำนวนรายการตรวจที่บันทึกแล้ว"
                  value={`${data.results.length} รายการ`}
                />
              </div>
              <section className="bg-white p-6 rounded-xl ">
                <h3 className="text-lg font-bold mb-4 text-zinc-700">
                  สถิติการตรวจข้อสอบรายเดือน
                </h3>
                <canvas ref={chartRef} height="80" />
              </section>
            </div>
          )}

          {activePage === "users" && (
            <div className="space-y-6">
              <form
                onSubmit={saveUser}
                className="bg-white rounded-xl  p-5 grid grid-cols-1 lg:grid-cols-5 gap-4 items-end"
              >
                <Field label="รหัสผู้ใช้ / อีเมล">
                  <Input
                    value={userForm.id}
                    disabled={Boolean(editingUser)}
                    onChange={(event) =>
                      setUserForm({ ...userForm, id: event.target.value })
                    }
                    placeholder="user@email.com"
                  />
                </Field>
                <Field label="ชื่อ-นามสกุล">
                  <Input
                    value={userForm.displayName}
                    onChange={(event) =>
                      setUserForm({
                        ...userForm,
                        displayName: event.target.value,
                      })
                    }
                    placeholder="ชื่อผู้ใช้งาน"
                  />
                </Field>
                <Field label="อีเมล">
                  <Input
                    value={userForm.email}
                    onChange={(event) =>
                      setUserForm({ ...userForm, email: event.target.value })
                    }
                    placeholder="name@example.com"
                  />
                </Field>
                <Field label="บทบาท">
                  <select
                    value={userForm.role}
                    onChange={(event) =>
                      setUserForm({ ...userForm, role: event.target.value })
                    }
                    className="w-full px-4 py-3 bg-white border border-zinc-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  >
                    <option>Teacher</option>
                    <option>Admin</option>
                    <option>Staff</option>
                  </select>
                </Field>
                <div className="flex gap-2">
                  <PrimaryButton
                    type="submit"
                    variant="success"
                    className="flex-1"
                  >
                    <Icon
                      name={editingUser ? "fa-floppy-disk" : "fa-user-plus"}
                    />{" "}
                    {editingUser ? "บันทึก" : "เพิ่ม"}
                  </PrimaryButton>
                  {editingUser && (
                    <button
                      type="button"
                      onClick={() => {
                        setEditingUser(null);
                        setUserForm({
                          id: "",
                          displayName: "",
                          email: "",
                          role: "Teacher",
                        });
                      }}
                      className="px-4 rounded-xl border border-zinc-200 bg-white"
                    >
                      <Icon name="fa-xmark" />
                    </button>
                  )}
                </div>
              </form>

              <div className="flex justify-between items-center gap-4">
                <h3 className="text-lg font-bold text-zinc-800">
                  ข้อมูลบัญชีผู้ใช้งาน
                </h3>
                <Input
                  value={search}
                  onChange={(event) => setSearch(event.target.value)}
                  placeholder="ค้นหาชื่อหรืออีเมล..."
                  className="max-w-sm bg-white"
                />
              </div>

              <div className="bg-white rounded-xl  overflow-x-auto">
                <table className="w-full text-left border-collapse">
                  <thead>
                    <tr className="bg-zinc-100 text-zinc-700">
                      <th className="p-4 border-b">รหัสผู้ใช้</th>
                      <th className="p-4 border-b">ชื่อ-นามสกุล</th>
                      <th className="p-4 border-b">อีเมล / ชื่อผู้ใช้</th>
                      <th className="p-4 border-b text-center">บทบาท</th>
                      <th className="p-4 border-b text-center">สถานะ</th>
                      <th className="p-4 border-b text-center">จัดการ</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filteredUsers.map((user) => (
                      <tr
                        key={user.id}
                        className={`hover:bg-zinc-50 ${user.status === "suspended" ? "bg-red-50" : ""}`}
                      >
                        <td className="p-4 border-b text-zinc-600">
                          {user.id}
                        </td>
                        <td className="p-4 border-b font-medium">
                          {displayUserName(user)}
                        </td>
                        <td className="p-4 border-b">
                          {user.email || user.id}
                        </td>
                        <td className="p-4 border-b text-center">
                          <span
                            className={`${user.role === "Admin" ? "bg-purple-100 text-purple-700" : "bg-blue-100 text-blue-700"} px-3 py-1 rounded-full text-xs font-bold`}
                          >
                            {user.role || "Teacher"}
                          </span>
                        </td>
                        <td className="p-4 border-b text-center">
                          {user.status === "suspended" ? (
                            <span className="text-red-600 font-bold">
                              ถูกระงับ
                            </span>
                          ) : (
                            <span className="text-emerald-600 font-bold">
                              ปกติ
                            </span>
                          )}
                        </td>
                        <td className="p-4 border-b text-center whitespace-nowrap">
                          <button
                            onClick={() => startEdit(user)}
                            className="text-yellow-500 hover:text-yellow-600 mx-2"
                            title="แก้ไข"
                          >
                            <Icon name="fa-pen-to-square" />
                          </button>
                          <button
                            onClick={() => toggleUserStatus(user)}
                            className={`${user.status === "suspended" ? "text-emerald-600" : "text-red-500"} hover:opacity-80 mx-2`}
                            title="เปลี่ยนสถานะ"
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
                            className="text-zinc-500 hover:text-red-600 mx-2"
                            title="ลบ"
                          >
                            <Icon name="fa-trash" />
                          </button>
                        </td>
                      </tr>
                    ))}
                    {!filteredUsers.length && (
                      <tr>
                        <td
                          colSpan="6"
                          className="p-8 text-center text-zinc-500"
                        >
                          ยังไม่มีข้อมูลผู้ใช้งาน
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}

          {activePage === "logs" && (
            <div className="space-y-6">
              <div className="flex justify-between items-center">
                <h3 className="text-lg font-bold text-zinc-800">
                  ประวัติการใช้งานระบบ
                </h3>
                <span className="text-sm text-zinc-500">
                  Collection: {logCollection}
                </span>
              </div>
              <div className="bg-zinc-900 rounded-xl  overflow-x-auto p-2">
                <table className="w-full text-left border-collapse text-sm text-zinc-300 font-mono">
                  <thead>
                    <tr className="border-b border-zinc-700 text-zinc-400">
                      <th className="p-3">วัน-เวลา</th>
                      <th className="p-3">ผู้ใช้งาน</th>
                      <th className="p-3">Log ID</th>
                      <th className="p-3">กิจกรรม</th>
                    </tr>
                  </thead>
                  <tbody>
                    {data.logs.map((log) => (
                      <tr
                        key={log.id}
                        className="hover:bg-zinc-800 border-b border-zinc-800"
                      >
                        <td className="p-3 whitespace-nowrap">
                          {formatDateTime(log.datetime)}
                        </td>
                        <td className="p-3 text-white">
                          {log.userEmail || log.user || log.admin || "-"}
                        </td>
                        <td className="p-3 text-white">
                          {log.logid || log.id}
                        </td>
                        <td className="p-3 text-emerald-300">
                          {log.activity || "-"}
                        </td>
                      </tr>
                    ))}
                    {!data.logs.length && (
                      <tr>
                        <td
                          colSpan="4"
                          className="p-8 text-center text-zinc-400"
                        >
                          ยังไม่มีประวัติการใช้งาน
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          )}
        </div>
      </main>
    </div>
  );
}

function AdminStat({ title, value, icon, color }) {
  const colors = {
    blue: "border-blue-500 text-blue-500",
    orange: "border-orange-500 text-orange-500",
    green: "border-emerald-500 text-emerald-500",
  };
  return (
    <div
      className={`bg-white p-6 rounded-xl  border-t-4 ${colors[color].split(" ")[0]} flex items-center justify-between`}
    >
      <div>
        <p className="text-zinc-500 text-sm font-bold">{title}</p>
        <h3 className="text-3xl font-bold mt-2 text-zinc-800">{value}</h3>
      </div>
      <div className={`${colors[color].split(" ")[1]} text-4xl opacity-50`}>
        <Icon name={icon} />
      </div>
    </div>
  );
}


