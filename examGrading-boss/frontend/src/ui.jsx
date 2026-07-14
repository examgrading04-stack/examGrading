import {
  Children,
  createElement,
  isValidElement,
  useEffect,
  useMemo,
  useRef,
  useState,
} from "react";
import { createPortal } from "react-dom";
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
  const {
    value,
    onChange,
    children,
    className = "",
    disabled = false,
    placeholder,
  } = props;
  const [open, setOpen] = useState(false);
  const wrapRef = useRef(null);

  const options = useMemo(
    () =>
      Children.toArray(children)
        .filter(isValidElement)
        .map((item) => ({
          value: String(item.props.value ?? ""),
          label: item.props.children,
          disabled: Boolean(item.props.disabled),
        })),
    [children],
  );

  const selected = options.find((item) => item.value === String(value ?? ""));
  const menuClass =
    options.length > 5
      ? "max-h-56 overflow-y-auto"
      : "max-h-none overflow-visible";

  useEffect(() => {
    function handleClickOutside(event) {
      if (!wrapRef.current?.contains(event.target)) setOpen(false);
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  function selectValue(nextValue) {
    onChange?.({ target: { value: nextValue } });
    setOpen(false);
  }

  return (
    <div ref={wrapRef} className="relative">
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen((state) => !state)}
        className={`w-full px-4 py-2 bg-white border border-slate-300 rounded-lg text-left focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors disabled:opacity-60 disabled:cursor-not-allowed ${className}`}
      >
        <span className={selected ? "text-slate-800" : "text-slate-400"}>
          {selected?.label || placeholder || "เลือกข้อมูล"}
        </span>
        <i className="fa-solid fa-chevron-down absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 text-xs" />
      </button>
      {open && !disabled && (
        <div
          className={`absolute z-50 mt-1 w-full rounded-lg border border-slate-200 bg-white shadow-lg ${menuClass}`}
        >
          {options.map((item) => {
            const isSelected = item.value === String(value ?? "");
            return (
              <button
                key={item.value}
                type="button"
                disabled={item.disabled}
                onClick={() => selectValue(item.value)}
                className={`block w-full px-3 py-2 text-left text-sm transition-colors ${
                  isSelected
                    ? "bg-blue-50 text-blue-700"
                    : "text-slate-700 hover:bg-slate-50"
                } disabled:opacity-50 disabled:cursor-not-allowed`}
              >
                {item.label}
              </button>
            );
          })}
        </div>
      )}
    </div>
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
  pageSize = 10,
}) {
  const [page, setPage] = useState(1);
  const safePageSize = Math.max(Number(pageSize) || 10, 1);
  const totalPages = Math.max(1, Math.ceil(rows.length / safePageSize));

  useEffect(() => {
    setPage((current) => Math.min(current, totalPages));
  }, [totalPages]);

  const visibleRows = useMemo(() => {
    const start = (page - 1) * safePageSize;
    return rows.slice(start, start + safePageSize);
  }, [rows, page, safePageSize]);

  const startItem = rows.length ? (page - 1) * safePageSize + 1 : 0;
  const endItem = Math.min(page * safePageSize, rows.length);

  return (
    <div className="rounded-xl border border-slate-200 bg-white shadow-sm">
      <div className="overflow-x-auto">
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
              visibleRows.map((row) => (
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
      {rows.length > 0 && (
        <div className="flex items-center justify-between gap-3 border-t border-slate-200 px-4 py-3 text-xs sm:text-sm">
          <span className="text-slate-500">
            แสดง {startItem}-{endItem} จาก {rows.length} รายการ
          </span>
          <Pagination
            count={totalPages}
            page={page}
            onChange={(_, value) => setPage(value)}
            variant="outlined"
            shape="rounded"
          />
        </div>
      )}
    </div>
  );
}

export function Pagination({
  count,
  page = 1,
  onChange,
  variant = "text",
  shape = "rounded",
}) {
  const safeCount = Math.max(Number(count) || 1, 1);
  const safePage = Math.min(Math.max(Number(page) || 1, 1), safeCount);
  const baseClass =
    shape === "rounded" ? "min-w-9 h-9 rounded-lg" : "min-w-9 h-9 rounded-full";
  const normalClass =
    variant === "outlined"
      ? "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
      : "border border-transparent bg-transparent text-slate-700 hover:bg-slate-100";
  const activeClass =
    variant === "outlined"
      ? "border border-blue-600 bg-blue-600 text-white"
      : "border border-transparent bg-blue-100 text-blue-700";
  const navClass =
    variant === "outlined"
      ? "border border-slate-300 bg-white text-slate-700 hover:bg-slate-50"
      : "border border-transparent bg-transparent text-slate-700 hover:bg-slate-100";

  function buildPages(total, current) {
    if (total <= 7) return Array.from({ length: total }, (_, i) => i + 1);

    if (current <= 4) return [1, 2, 3, 4, 5, "...", total];
    if (current >= total - 3)
      return [1, "...", total - 4, total - 3, total - 2, total - 1, total];
    return [1, "...", current - 1, current, current + 1, "...", total];
  }

  const items = buildPages(safeCount, safePage);

  return (
    <div className="flex items-center gap-1">
      <button
        type="button"
        onClick={() => onChange?.(null, Math.max(safePage - 1, 1))}
        disabled={safePage === 1}
        className={`${baseClass} px-2 text-sm font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50 ${navClass}`}
      >
        ก่อนหน้า
      </button>
      {items.map((value, index) =>
        value === "..." ? (
          <span
            key={`ellipsis-${index}`}
            className="inline-flex min-w-8 items-center justify-center text-slate-400"
          >
            ...
          </span>
        ) : (
          <button
            key={value}
            type="button"
            onClick={() => onChange?.(null, value)}
            className={`${baseClass} px-2 text-sm font-semibold transition-colors ${value === safePage ? activeClass : normalClass}`}
            aria-current={value === safePage ? "page" : undefined}
          >
            {value}
          </button>
        ),
      )}
      <button
        type="button"
        onClick={() => onChange?.(null, Math.min(safePage + 1, safeCount))}
        disabled={safePage >= safeCount}
        className={`${baseClass} px-2 text-sm font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50 ${navClass}`}
      >
        ถัดไป
      </button>
    </div>
  );
}

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
    document.body,
  );
}
