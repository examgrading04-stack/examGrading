import { GOOGLE_CLIENT_ID } from "../config/google.js";
import { API_BASE_URL } from "../ui.jsx";
const BASE_URL = API_BASE_URL || "http://localhost:5173/";

class MockUser {
  constructor(data, authInstance) {
    Object.assign(this, data);
    this._auth = authInstance;
  }
  async updateProfile(data) {
    Object.assign(this, data);
    await fetch(
      `${BASE_URL}/api/db/users/${this.email}/profiles/${this.email}`,
      {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(data),
      },
    );
    this._auth.saveUser(this);
  }
  async reload() {
    const res = await fetch(
      `${BASE_URL}/api/db/users/${this.email}/profiles/${this.email}`,
    );
    if (res.ok) {
      const data = await res.json();
      if (data) {
        Object.assign(this, data);
        this._auth.saveUser(this);
      }
    }
  }
}

class MockAuth {
  constructor() {
    this.listeners = [];
    this.currentUser = null;
    this.persistence = "local";
    let stored = localStorage.getItem("local_user");
    if (!stored) {
      stored = sessionStorage.getItem("local_user");
      if (stored) this.persistence = "session";
    }
    if (stored) {
      try {
        this.currentUser = new MockUser(JSON.parse(stored), this);
      } catch (e) {
        this.currentUser = null;
      }
    }
  }

  setPersistence(type) {
    this.persistence = type;
    return Promise.resolve();
  }

  saveUser(user) {
    const userData = {
      email: user.email,
      displayName: user.displayName,
      photoURL: user.photoURL,
    };
    if (this.persistence === "session") {
      sessionStorage.setItem("local_user", JSON.stringify(userData));
      localStorage.removeItem("local_user");
    } else {
      localStorage.setItem("local_user", JSON.stringify(userData));
      sessionStorage.removeItem("local_user");
    }
    this.currentUser = new MockUser(userData, this);
    this.listeners.forEach((cb) => cb(this.currentUser));
  }

  onAuthStateChanged(callback) {
    this.listeners.push(callback);
    setTimeout(() => callback(this.currentUser), 0);
    return () => {
      this.listeners = this.listeners.filter((cb) => cb !== callback);
    };
  }

  async signInWithEmailAndPassword(email, password) {
    const res = await fetch(`${BASE_URL}/api/auth/login`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "เข้าสู่ระบบไม่สำเร็จ");
    }
    const data = await res.json();
    const user = new MockUser(data, this);
    this.saveUser(user);
    return { user };
  }

  async createUserWithEmailAndPassword(email, password) {
    const res = await fetch(`${BASE_URL}/api/auth/register`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ email, password }),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "สมัครสมาชิกไม่สำเร็จ");
    }
    const data = await res.json();
    const user = new MockUser(data, this);
    this.saveUser(user);
    return { user };
  }

  async signOut() {
    this.currentUser = null;
    localStorage.removeItem("local_user");
    sessionStorage.removeItem("local_user");
    this.listeners.forEach((cb) => cb(null));
  }

  async signInWithPopup(provider) {
    if (!GOOGLE_CLIENT_ID) {
      if (!window.Swal) {
        throw new Error("SweetAlert2 library missing");
      }

      const result = await window.Swal.fire({
        title: "จำลองล็อกอิน Google (โหมดออฟไลน์)",
        text: "เนื่องจากยังไม่ได้ระบุ GOOGLE_CLIENT_ID ระบบจะสร้างบัญชีทดสอบใน MySQL ให้โดยอัตโนมัติ",
        input: "email",
        inputLabel: "ระบุอีเมล Google สำหรับทดสอบ",
        inputPlaceholder: "your-google-account@gmail.com",
        inputValue: "google-test@gmail.com",
        showCancelButton: true,
        confirmButtonText: "เข้าสู่ระบบ",
        cancelButtonText: "ยกเลิก",
      });

      if (!result.isConfirmed || !result.value) {
        throw new Error("ยกเลิกการล็อกอิน");
      }

      const email = result.value.trim();
      const displayName = email.split("@")[0];

      const res = await fetch(`${BASE_URL}/api/auth/google-mock`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, displayName }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.detail || "เข้าสู่ระบบจำลองไม่สำเร็จ");
      }

      const data = await res.json();
      const user = new MockUser(data, this);
      this.currentUser = user;
      localStorage.setItem("local_user", JSON.stringify(data));
      this.listeners.forEach((cb) => cb(user));
      return { user };
    }

    return new Promise((resolve, reject) => {
      try {
        if (typeof google === "undefined" || !google.accounts) {
          throw new Error(
            "Google Identity Services SDK ยังโหลดไม่สำเร็จ กรุณาต่ออินเทอร์เน็ตเพื่อเข้าใช้งาน",
          );
        }

        const client = google.accounts.oauth2.initTokenClient({
          client_id: GOOGLE_CLIENT_ID,
          scope: "openid email profile",
          callback: async (tokenResponse) => {
            if (tokenResponse.error) {
              reject(
                new Error(
                  tokenResponse.error_description ||
                  "Google Popup closed or failed",
                ),
              );
              return;
            }
            if (tokenResponse.access_token) {
              try {
                const res = await fetch(`${BASE_URL}/api/auth/google`, {
                  method: "POST",
                  headers: { "Content-Type": "application/json" },
                  body: JSON.stringify({
                    access_token: tokenResponse.access_token,
                  }),
                });

                if (!res.ok) {
                  const err = await res.json();
                  throw new Error(
                    err.detail || "การยืนยัน Google Token ล้มเหลวจาก API",
                  );
                }

                const data = await res.json();
                const user = new MockUser(data, this);
                this.currentUser = user;
                localStorage.setItem("local_user", JSON.stringify(data));
                this.listeners.forEach((cb) => cb(user));
                resolve({ user });
              } catch (e) {
                reject(e);
              }
            }
          },
          error_callback: (err) => {
            reject(
              new Error(err.message || "Google OAuth initialization error"),
            );
          },
        });

        client.requestAccessToken();
      } catch (e) {
        reject(e);
      }
    });
  }
}

class MockDocumentSnapshot {
  constructor(id, data) {
    this.id = id;
    this._data = data;
    this.exists = data !== null && data !== undefined;
  }
  data() {
    return this._data;
  }
}

class MockQueryDocumentSnapshot {
  constructor(id, ref, data) {
    this.id = id;
    this.ref = ref;
    this._data = data;
  }
  data() {
    return this._data;
  }
}

class MockQuerySnapshot {
  constructor(docs) {
    this.docs = docs;
    this.empty = docs.length === 0;
  }
  forEach(callback) {
    this.docs.forEach(callback);
  }
}

class MockDocReference {
  constructor(path, firestore) {
    this.path = path;
    this.firestore = firestore;
  }
  get id() {
    return this.path.at(-1);
  }
  collection(name) {
    return new MockCollectionReference([...this.path, name], this.firestore);
  }
  async get() {
    const res = await fetch(`${BASE_URL}/api/db/${this.path.join("/")}`);
    if (!res.ok) {
      return new MockDocumentSnapshot(this.path.at(-1), null);
    }
    const data = await res.json();
    return new MockDocumentSnapshot(this.path.at(-1), data);
  }
  async set(data, options) {
    const res = await fetch(`${BASE_URL}/api/db/${this.path.join("/")}`, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "Set document failed");
    }
  }
  async update(data) {
    const res = await fetch(`${BASE_URL}/api/db/${this.path.join("/")}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "Update document failed");
    }
  }
  async delete() {
    const cleanPath = (this.path || []).filter(
      (p) => p !== undefined && p !== null && String(p).trim() !== "",
    );
    if (cleanPath.length === 0 || cleanPath.length % 2 !== 0) {
      console.warn("Skipping delete for invalid path:", this.path);
      return;
    }
    const res = await fetch(`${BASE_URL}/api/db/${cleanPath.join("/")}`, {
      method: "DELETE",
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      console.warn("Delete document note:", err.detail || "Delete document failed");
    }
  }
}

class MockCollectionReference {
  constructor(path, firestore) {
    this.path = path;
    this.firestore = firestore;
    this.filters = [];
    this.limitVal = null;
  }
  get id() {
    return this.path.at(-1);
  }
  doc(id) {
    if (id === null || id === "") {
      id = undefined;
    }
    const docId =
      id !== undefined
        ? id
        : Math.random().toString(36).substring(2, 15) +
          Math.random().toString(36).substring(2, 15);
    return new MockDocReference([...this.path, docId], this.firestore);
  }
  where(field, op, value) {
    const newCol = new MockCollectionReference(this.path, this.firestore);
    newCol.filters = [...this.filters, { field, op, value }];
    newCol.limitVal = this.limitVal;
    return newCol;
  }
  limit(value) {
    const newCol = new MockCollectionReference(this.path, this.firestore);
    newCol.filters = [...this.filters];
    newCol.limitVal = value;
    return newCol;
  }
  async add(data) {
    const res = await fetch(`${BASE_URL}/api/db/${this.path.join("/")}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const err = await res.json();
      throw new Error(err.detail || "Add document failed");
    }
    const resData = await res.json();
    return new MockDocReference([...this.path, resData.id], this.firestore);
  }
  async get() {
    const params = new URLSearchParams();
    this.filters.forEach((f) => {
      if (f.op === "==") {
        params.append(f.field, f.value);
      }
    });
    if (this.limitVal !== null) {
      params.append("limit", this.limitVal);
    }

    const queryStr = params.toString() ? `?${params.toString()}` : "";
    const res = await fetch(
      `${BASE_URL}/api/db/${this.path.join("/")}${queryStr}`,
    );
    if (!res.ok) {
      return new MockQuerySnapshot([]);
    }
    const dataList = await res.json();
<<<<<<< HEAD
    const docs = (dataList || [])
      .map((item) => {
        const docId =
          item.id ||
          item.realId ||
          item.section_id ||
          item.code ||
          item.email ||
          item.logid ||
          (item.sec !== undefined && item.sec !== null ? String(item.sec) : "");

        if (!docId) return null;

        let refPath = [...this.path, docId];
        if (
          item.user_email &&
          this.path.length === 1 &&
          ["exams", "students", "results", "subjects"].includes(this.path[0])
        ) {
          refPath = ["users", item.user_email, this.path[0], docId];
        }
        const ref = new MockDocReference(refPath, this.firestore);
        return new MockQueryDocumentSnapshot(docId, ref, item);
      })
      .filter(Boolean);
=======
    const docs = (dataList || []).map((item) => {
      const docId = item.id || item.user_id || item.template_id || item.code || item.email || item.logid;
      let refPath = [...this.path, docId];
      if (
        item.user_email &&
        this.path.length === 1 &&
        ["exams", "students", "results", "subjects"].includes(this.path[0])
      ) {
        refPath = ["users", item.user_email, this.path[0], docId];
      }
      const ref = new MockDocReference(refPath, this.firestore);
      return new MockQueryDocumentSnapshot(docId, ref, item);
    });
>>>>>>> origin/main
    return new MockQuerySnapshot(docs);
  }
}

class MockBatch {
  constructor() {
    this.deletes = [];
  }
  delete(docRef) {
    this.deletes.push(docRef);
  }
  async commit() {
    await Promise.all(this.deletes.map((ref) => ref.delete()));
  }
}

class MockFirestore {
  constructor() {
    this.FieldValue = {
      serverTimestamp() {
        return new Date().toISOString();
      },
    };
  }
  collection(name) {
    return new MockCollectionReference([name], this);
  }
  collectionGroup(name) {
    return new MockCollectionReference([name], this);
  }
  batch() {
    return new MockBatch();
  }
}

// Define the global windows object
const authFunc = () => new MockAuth();
authFunc.GoogleAuthProvider = class { };
authFunc.Auth = {
  Persistence: {
    LOCAL: "local",
    SESSION: "session",
  },
};

const firestoreFunc = () => new MockFirestore();
firestoreFunc.FieldValue = {
  serverTimestamp: () => new Date().toISOString(),
};

window.firebase = {
  apps: { length: 1 },
  initializeApp: () => { },
  auth: authFunc,
  firestore: firestoreFunc,
};

export function bootFirebase() {
  return {
    auth: window.firebase.auth(),
    db: window.firebase.firestore(),
  };
}
