import { firebaseConfig } from "../config/firebase.js";

export function bootFirebase() {
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
