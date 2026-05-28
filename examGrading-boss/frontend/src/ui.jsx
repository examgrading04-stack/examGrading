import { useEffect } from "react";
import iconImage from "../images/icon.png";

export const Swal = () => window.Swal;

function defaultApiBaseUrl() {
  const hostname = window.location.hostname;
  if (!hostname || hostname === "localhost" || hostname === "127.0.0.1") {
    return "http://127.0.0.1:8000";
  }
  return "";
}

export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || defaultApiBaseUrl();

export function apiBaseUrls() {
  const urls = API_BASE_URL ? [API_BASE_URL] : [];
  if (
    ["localhost", "127.0.0.1"].includes(window.location.hostname) &&
    API_BASE_URL !== "http://127.0.0.1:8000"
  ) {
    urls.push("http://127.0.0.1:8000");
  }
  return [...new Set(urls)];
}

export async function apiFetch(path, options) {
  let lastError;
  const baseUrls = apiBaseUrls();
  if (!baseUrls.length) {
    throw new Error("ยังไม่ได้ตั้งค่า VITE_API_BASE_URL สำหรับ Backend");
  }
  for (const baseUrl of baseUrls) {
    try {
      return await fetch(`${baseUrl}${path}`, options);
    } catch (error) {
      lastError = error;
    }
  }
  throw lastError;
}

export function formatThaiDate(value = new Date()) {
  return new Date(value).toLocaleDateString("th-TH", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

export function pct(value, max) {
  if (!max) return 0;
  return Math.round((Number(value || 0) / Number(max || 1)) * 100);
}

export function emptyForm(fields) {
  return Object.fromEntries(fields.map((field) => [field, ""]));
}

export function AppLogo({ compact = false }) {
  return (
    <div
      className={`${compact ? "w-10 h-10 rounded-lg" : "w-16 h-16 rounded-xl"} bg-white flex items-center justify-center shadow-sm border border-slate-200 overflow-hidden p-0.5`}
    >
      <img
        src={iconImage}
        alt="App Logo"
        className="w-full h-full object-contain"
      />
    </div>
  );
}

export function Icon({ name }) {
  return <i className={`fa-solid ${name}`} aria-hidden="true" />;
}

export function Field({ label, children }) {
  return (
    <label className="block">
      <span className="block text-sm font-bold text-slate-700 mb-2">
        {label}
      </span>
      {children}
    </label>
  );
}

export function Input(props) {
  return (
    <input
      {...props}
      placeholder={props.placeholder || `กรอก${props.label || ""}`}
      className={`w-full px-4 py-2 bg-white border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors ${props.className || ""}`}
    />
  );
}

export function Select(props) {
  return (
    <select
      {...props}
      className={`w-full px-4 py-2 bg-white border border-slate-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors ${props.className || ""}`}
    />
  );
}

export function PrimaryButton({
  children,
  className = "",
  variant = "primary",
  ...props
}) {
  const variants = {
    primary:
      "bg-blue-600 hover:bg-blue-700 text-white shadow-sm border border-transparent",
    danger:
      "bg-rose-600 hover:bg-rose-700 text-white shadow-sm border border-transparent",
    success:
      "bg-emerald-600 hover:bg-emerald-700 text-white shadow-sm border border-transparent",
    warning:
      "bg-amber-500 hover:bg-amber-600 text-white shadow-sm border border-transparent",
    slate:
      "bg-slate-700 hover:bg-slate-800 text-white shadow-sm border border-transparent",
  };
  return (
    <button
      {...props}
      className={`inline-flex items-center justify-center gap-2 font-semibold py-2 px-4 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed ${variants[variant]} ${className}`}
    >
      {children}
    </button>
  );
}

export function GhostButton({
  children,
  className = "",
  variant = "slate",
  ...props
}) {
  const variants = {
    primary:
      "border-blue-200 bg-blue-50/50 text-blue-700 hover:bg-blue-100 hover:border-blue-300",
    danger:
      "border-rose-200 bg-rose-50/50 text-rose-700 hover:bg-rose-100 hover:border-rose-300",
    success:
      "border-emerald-200 bg-emerald-50/50 text-emerald-700 hover:bg-emerald-100 hover:border-emerald-300",
    slate:
      "border-slate-200 bg-white text-slate-700 hover:bg-slate-50 hover:border-slate-300",
  };
  return (
    <button
      {...props}
      className={`inline-flex items-center justify-center gap-2 border font-semibold py-2 px-4 rounded-lg transition-colors disabled:opacity-60 disabled:cursor-not-allowed ${variants[variant]} ${className}`}
    >
      {children}
    </button>
  );
}

export function useChart(canvasRef, config, deps) {
  useEffect(() => {
    if (!canvasRef.current || !window.Chart) return undefined;
    const chart = new window.Chart(canvasRef.current, config);
    return () => chart.destroy();
  }, deps);
}

export function StatCard({ title, value, icon, color }) {
  const styles = {
    blue: {
      text: "text-blue-600",
      border: "border-blue-200",
      iconBg: "bg-blue-50",
    },
    green: {
      text: "text-emerald-600",
      border: "border-emerald-200",
      iconBg: "bg-emerald-50",
    },
    emerald: {
      text: "text-emerald-600",
      border: "border-emerald-200",
      iconBg: "bg-emerald-50",
    },
    violet: {
      text: "text-violet-600",
      border: "border-violet-200",
      iconBg: "bg-violet-50",
    },
    amber: {
      text: "text-amber-600",
      border: "border-amber-200",
      iconBg: "bg-amber-50",
    },
  };
  const s = styles[color] || styles.blue;
  return (
    <div
      className={`bg-white p-5 rounded-xl shadow-sm border ${s.border} flex justify-between items-center transition-colors group`}
    >
      <div>
        <p className="text-slate-500 text-xs font-bold uppercase tracking-wider">
          {title}
        </p>
        <h3 className="text-2xl font-bold mt-1 text-slate-800">{value}</h3>
      </div>
      <div
        className={`w-12 h-12 rounded-lg flex items-center justify-center ${s.text} ${s.iconBg} border border-white`}
      >
        <Icon name={icon} />
      </div>
    </div>
  );
}

export function DataTable({
  columns,
  rows,
  emptyText = "ไม่มีข้อมูล",
}) {
  return (
    <div className="overflow-x-auto rounded-xl border border-slate-200 bg-white shadow-sm">
      <table className="w-full text-sm">
        <thead className="bg-slate-50 text-slate-600 border-b border-slate-200">
          <tr>
            {columns.map((column) => (
              <th
                key={column.key}
                className="px-4 py-3 text-left font-bold whitespace-nowrap"
              >
                {column.label}
              </th>
            ))}
          </tr>
        </thead>
        <tbody className="divide-y divide-slate-100">
          {rows.length ? (
            rows.map((row) => (
              <tr
                key={row.id || JSON.stringify(row)}
                className="hover:bg-slate-50"
              >
                {columns.map((column) => (
                  <td key={column.key} className="px-4 py-3 align-top">
                    {column.render ? column.render(row) : row[column.key]}
                  </td>
                ))}
              </tr>
            ))
          ) : (
            <tr>
              <td
                colSpan={columns.length}
                className="px-4 py-10 text-center text-slate-500"
              >
                {emptyText}
              </td>
            </tr>
          )}
        </tbody>
      </table>
    </div>
  );
}

import { createPortal } from "react-dom";

export function Modal({
  isOpen,
  onClose,
  title,
  children,
  maxWidth = "max-w-2xl",
}) {
  if (!isOpen) return null;

  return createPortal(
    <div
      className="fixed inset-0 z-[9999] flex items-center justify-center overflow-y-auto overflow-x-hidden bg-slate-900/40 p-4 animate-in fade-in duration-200"
      onClick={onClose}
    >
      <div
        className={`relative w-full ${maxWidth} bg-white rounded-xl shadow-xl flex flex-col max-h-[90vh]`}
        onClick={(e) => e.stopPropagation()}
      >
        <div className="flex items-center justify-between p-5 border-b border-slate-200">
          <h3 className="text-lg font-bold text-slate-800">{title}</h3>
          <button
            onClick={onClose}
            className="w-8 h-8 flex items-center justify-center rounded-lg hover:bg-slate-100 text-slate-500 hover:text-slate-700 transition-colors"
          >
            <Icon name="fa-xmark" />
          </button>
        </div>
        <div className="p-5 overflow-y-auto flex-1">{children}</div>
      </div>
    </div>,
    document.body
  );
}
