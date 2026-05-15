export const routes = [
  {
    id: "dashboard",
    path: "/dashboard",
    file: "dashboard.html",
    label: "แดชบอร์ด",
    icon: "fa-chart-pie",
  },
  {
    id: "subjects",
    path: "/subjects",
    file: "subjects.html",
    label: "รายวิชาและกลุ่มเรียน",
    icon: "fa-book-open",
  },
  {
    id: "students",
    path: "/students",
    file: "students.html",
    label: "จัดการผู้เรียน",
    icon: "fa-user-graduate",
  },
  {
    id: "exams",
    path: "/exams",
    file: "exams.html",
    label: "จัดการข้อสอบ",
    icon: "fa-file-pen",
  },
  {
    id: "answer-key",
    path: "/answer-key",
    file: "answer-key.html",
    label: "เฉลยข้อสอบ",
    icon: "fa-key",
  },
  {
    id: "results",
    path: "/results",
    file: "results.html",
    label: "ผลการสอบ",
    icon: "fa-square-poll-vertical",
  },
  {
    id: "analysis",
    path: "/analysis",
    file: "analysis.html",
    label: "วิเคราะห์ผล",
    icon: "fa-chart-line",
  },
  {
    id: "reports",
    path: "/reports",
    file: "reports.html",
    label: "รายงานผล",
    icon: "fa-file-invoice",
  },
  {
    id: "answer-sheet",
    path: "/answer-sheet",
    file: "answer_sheet.html",
    label: "กระดาษคำตอบ",
    icon: "fa-file-lines",
    hidden: true,
  },
];

export const legacyRouteMap = Object.fromEntries(
  routes.map((route) => [route.file, route.id]),
);

export const routeById = Object.fromEntries(
  routes.map((route) => [route.id, route]),
);
