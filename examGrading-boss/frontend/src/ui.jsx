import { useEffect } from "react";

export const Swal = () => window.Swal;
export const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://127.0.0.1:8000";

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
      className={`${compact ? "w-10 h-10 rounded-xl" : "w-16 h-16 rounded-2xl"} bg-white flex items-center justify-center shadow-md border border-slate-100 overflow-hidden`}
    >
      <svg
        viewBox="0 0 100 100"
        className={compact ? "w-8 h-8" : "w-12 h-12"}
        aria-hidden="true"
      >
        <rect
          x="25"
          y="15"
          width="50"
          height="70"
          rx="6"
          fill="white"
          stroke="#1E293B"
          strokeWidth="2"
        />
        <rect x="38" y="10" width="24" height="8" rx="2" fill="#475569" />
        {[35, 50, 65].map((y) => (
          <g key={y}>
            <circle cx="38" cy={y} r="3" fill="#3B82F6" />
            <rect
              x="46"
              y={y - 1}
              width="20"
              height="2"
              rx="1"
              fill="#E2E8F0"
            />
          </g>
        ))}
        <g transform="translate(68, 15) rotate(45)">
          <rect x="0" y="0" width="5" height="18" fill="#FBBF24" />
          <rect x="0" y="0" width="5" height="3.5" fill="#EF4444" />
          <path d="M0 18 L2.5 24 L5 18 Z" fill="#D1D5DB" />
        </g>
        <circle
          cx="82"
          cy="82"
          r="14"
          fill="#10B981"
          stroke="white"
          strokeWidth="1.5"
        />
        <path
          d="M76 82 L80 86 L88 78"
          fill="none"
          stroke="white"
          strokeWidth="2.5"
          strokeLinecap="round"
          strokeLinejoin="round"
        />
      </svg>
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
      className={`w-full px-4 py-3 bg-slate-50 border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all ${props.className || ""}`}
    />
  );
}

export function Select(props) {
  return (
    <select
      {...props}
      className={`w-full px-4 py-3 bg-white border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-blue-500 transition-all ${props.className || ""}`}
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
    primary: "bg-blue-600 hover:bg-blue-700 text-white shadow-blue-200",
    danger: "bg-rose-600 hover:bg-rose-700 text-white shadow-rose-200",
    success: "bg-emerald-600 hover:bg-emerald-700 text-white shadow-emerald-200",
    warning: "bg-amber-500 hover:bg-amber-600 text-white shadow-amber-200",
    slate: "bg-slate-700 hover:bg-slate-800 text-white shadow-slate-200",
  };

  return (
    <button
      {...props}
      className={`inline-flex items-center justify-center gap-2 font-bold py-3 px-4 rounded-xl transition-all active:scale-[0.98] shadow-lg disabled:opacity-60 disabled:cursor-not-allowed ${variants[variant]} ${className}`}
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
      className={`inline-flex items-center justify-center gap-2 border font-semibold py-3 px-4 rounded-xl transition-all active:scale-[0.98] disabled:opacity-60 ${variants[variant]} ${className}`}
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
  const colors = {
    blue: "border-blue-500 text-blue-600 bg-blue-50",
    green: "border-emerald-500 text-emerald-600 bg-emerald-50",
    violet: "border-violet-500 text-violet-600 bg-violet-50",
    amber: "border-amber-500 text-amber-600 bg-amber-50",
  };
  return (
    <div
      className={`bg-white p-6 rounded-2xl shadow-sm border-l-4 ${colors[color].split(" ")[0]} flex justify-between items-center hover:shadow-md transition-shadow`}
    >
      <div>
        <p className="text-slate-500 text-sm font-medium">{title}</p>
        <h3 className="text-3xl font-extrabold mt-2 text-slate-800">{value}</h3>
      </div>
      <div
        className={`w-12 h-12 rounded-xl flex items-center justify-center ${colors[color].split(" ").slice(1).join(" ")}`}
      >
        <Icon name={icon} />
      </div>
    </div>
  );
}

export function DataTable({ columns, rows, emptyText = "ยังไม่มีข้อมูล" }) {
  return (
    <div className="overflow-x-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
      <table className="w-full text-sm">
        <thead className="bg-slate-50 text-slate-600">
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
