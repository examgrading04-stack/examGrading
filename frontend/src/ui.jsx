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
import logoImage from "../images/logo.jpg";

export const Swal = () => window.Swal;

function defaultApiBaseUrl() {
  const hostname = window.location.hostname;
  if (!hostname || hostname === "localhost" || hostname === "127.0.0.1") {
    return "http://127.0.0.1:8000";
  }
  return `http://${hostname}:8000`;
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

export function AppLogo({ compact = false, className = "" }) {
  return (
    <div
      className={`${compact ? "w-10 h-10 rounded-xl" : "w-16 h-16 rounded-2xl"} bg-white flex items-center justify-center shadow-sm overflow-hidden border border-slate-200/60 ${className}`}
    >
      <img
        src={logoImage}
        alt="App Logo"
        className="w-full h-full object-cover"
      />
    </div>
  );
}

export function Icon({ name, className = "" }) {
  return (
    <i className={`fa-solid ${name} ${className}`.trim()} aria-hidden="true" />
  );
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
    searchable = true,
  } = props;
  const [open, setOpen] = useState(false);
  const [search, setSearch] = useState("");
  const wrapRef = useRef(null);
  const inputRef = useRef(null);

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

  const filteredOptions = useMemo(() => {
    if (!search) return options;
    const lowerSearch = search.toLowerCase();
    return options.filter((item) =>
      String(item.label).toLowerCase().includes(lowerSearch),
    );
  }, [options, search]);

  const displayOptions = filteredOptions.slice(0, 200);

  const menuClass =
    options.length > 5
      ? "max-h-60 overflow-y-auto"
      : "max-h-none overflow-visible";

  useEffect(() => {
    function handleClickOutside(event) {
      if (!wrapRef.current?.contains(event.target)) {
        setOpen(false);
        setSearch("");
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  useEffect(() => {
    if (open && inputRef.current) {
      inputRef.current.focus();
    }
  }, [open]);

  function selectValue(nextValue) {
    onChange?.({ target: { value: nextValue } });
    setOpen(false);
    setSearch("");
  }

  return (
    <div ref={wrapRef} className="relative">
      <button
        type="button"
        disabled={disabled}
        onClick={() => {
          setOpen((state) => !state);
          if (open) setSearch("");
        }}
        className={`w-full px-4 py-2 bg-white border border-slate-300 rounded-lg text-left focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-colors disabled:opacity-60 disabled:cursor-not-allowed flex items-center justify-between ${className}`}
      >
        <span
          className={`truncate ${selected ? "text-slate-800" : "text-slate-400"}`}
        >
          {selected?.label || placeholder || "เลือกข้อมูล"}
        </span>
        <svg
          xmlns="http://www.w3.org/2000/svg"
          viewBox="0 0 20 20"
          fill="currentColor"
          className="w-4 h-4 text-slate-400 shrink-0 ml-2"
        >
          <path
            fillRule="evenodd"
            d="M5.23 7.21a.75.75 0 011.06.02L10 11.168l3.71-3.938a.75.75 0 111.08 1.04l-4.25 4.5a.75.75 0 01-1.08 0l-4.25-4.5a.75.75 0 01.02-1.06z"
            clipRule="evenodd"
          />
        </svg>
      </button>
      {open && !disabled && (
        <div
          className={`absolute z-[100] mt-1 w-full min-w-[200px] rounded-lg border border-slate-200 bg-white shadow-lg overflow-hidden flex flex-col`}
        >
          {searchable && options.length > 5 && (
            <div className="p-2 border-b border-slate-100 bg-slate-50/50 sticky top-0 z-10">
              <div className="relative">
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 20 20"
                  fill="currentColor"
                  className="w-4 h-4 text-slate-400 absolute left-2.5 top-1/2 -translate-y-1/2"
                >
                  <path
                    fillRule="evenodd"
                    d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z"
                    clipRule="evenodd"
                  />
                </svg>
                <input
                  ref={inputRef}
                  type="text"
                  className="w-full pl-8 pr-3 py-1.5 text-sm bg-white border border-slate-200 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500"
                  placeholder="ค้นหา..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                />
              </div>
            </div>
          )}
          <div className={`${menuClass} py-1`}>
            {displayOptions.length > 0 ? (
              displayOptions.map((item) => {
                const isSelected = item.value === String(value ?? "");
                return (
                  <button
                    key={item.value}
                    type="button"
                    disabled={item.disabled}
                    onClick={() => selectValue(item.value)}
                    className={`block w-full px-3 py-2 text-left text-sm transition-colors truncate ${
                      isSelected
                        ? "bg-blue-50 text-blue-700 font-medium"
                        : "text-slate-700 hover:bg-slate-50"
                    } disabled:opacity-50 disabled:cursor-not-allowed`}
                    title={
                      typeof item.label === "string" ? item.label : undefined
                    }
                  >
                    {item.label}
                  </button>
                );
              })
            ) : (
              <div className="px-3 py-4 text-center text-sm text-slate-500">
                ไม่พบข้อมูล
              </div>
            )}
            {filteredOptions.length > 200 && (
              <div className="px-3 py-2 text-center text-xs text-slate-400 border-t border-slate-50 mt-1">
                มีอีก {filteredOptions.length - 200} รายการ (พิมพ์เพื่อค้นหา)
              </div>
            )}
          </div>
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
      bg: "bg-blue-100",
      border: "border-l-blue-500",
    },
    indigo: {
      text: "text-indigo-600",
      bg: "bg-indigo-100",
      border: "border-l-indigo-500",
    },
    green: {
      text: "text-emerald-600",
      bg: "bg-emerald-100",
      border: "border-l-emerald-500",
    },
    emerald: {
      text: "text-emerald-600",
      bg: "bg-emerald-100",
      border: "border-l-emerald-500",
    },
    violet: {
      text: "text-violet-600",
      bg: "bg-violet-100",
      border: "border-l-violet-500",
    },
    amber: {
      text: "text-amber-600",
      bg: "bg-amber-100",
      border: "border-l-amber-500",
    },
    rose: {
      text: "text-rose-600",
      bg: "bg-rose-100",
      border: "border-l-rose-500",
    },
  };
  const s = styles[color] || styles.blue;
  return (
    <div
      className={`bg-white p-4 rounded-xl border border-slate-200 border-l-4 ${s.border} shadow-sm flex flex-col justify-between h-full`}
    >
      <div className="flex justify-between items-start mb-2">
        <p className="text-slate-600 text-sm font-bold leading-tight pr-2">
          {title}
        </p>
        <div
          className={`w-10 h-10 shrink-0 rounded-lg flex items-center justify-center ${s.bg} ${s.text}`}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            fill="none"
            viewBox="0 0 24 24"
            strokeWidth={2.5}
            stroke="currentColor"
            className="w-5 h-5"
          >
            {getStatIconPath(icon)}
          </svg>
        </div>
      </div>
      <div>
        <h3 className="text-3xl font-black text-slate-800 mt-1">{value}</h3>
      </div>
    </div>
  );
}

function getStatIconPath(name) {
  switch (name) {
    case "fa-users":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M15 19.128a9.38 9.38 0 002.625.372 9.337 9.337 0 004.121-.952 4.125 4.125 0 00-7.533-2.493M15 19.128v-.003c0-1.113-.285-2.16-.786-3.07M15 19.128v.106A12.318 12.318 0 018.624 21c-2.331 0-4.512-.645-6.374-1.766l-.001-.109a6.375 6.375 0 0111.964-3.07M12 6.375a3.375 3.375 0 11-6.75 0 3.375 3.375 0 016.75 0zm8.25 2.25a2.625 2.625 0 11-5.25 0 2.625 2.625 0 015.25 0z"
        />
      );
    case "fa-chart-simple":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M3 13.125C3 12.504 3.504 12 4.125 12h2.25c.621 0 1.125.504 1.125 1.125v6.75C7.5 20.496 6.996 21 6.375 21h-2.25A1.125 1.125 0 013 19.875v-6.75zM9.75 8.625c0-.621.504-1.125 1.125-1.125h2.25c.621 0 1.125.504 1.125 1.125v11.25c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V8.625zM16.5 4.125c0-.621.504-1.125 1.125-1.125h2.25C20.496 3 21 3.504 21 4.125v15.75c0 .621-.504 1.125-1.125 1.125h-2.25a1.125 1.125 0 01-1.125-1.125V4.125z"
        />
      );
    case "fa-scale-balanced":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M12 3v17.25m0 0c-1.472 0-2.882.265-4.185.75M12 20.25c1.472 0 2.882.265 4.185.75M18.75 4.97A48.416 48.416 0 0012 4.5c-2.291 0-4.545.16-6.75.47m13.5 0c1.01.143 2.01.317 3 .52m-3-.52l2.62 10.726c.122.499-.106 1.028-.589 1.202a5.988 5.988 0 01-2.031.352 5.988 5.988 0 01-2.031-.352c-.483-.174-.711-.703-.59-1.202L18.75 4.971zm-16.5.52c.99-.203 1.99-.377 3-.52m0 0l2.62 10.726c.122.499-.106 1.028-.589 1.202a5.989 5.989 0 01-2.031.352 5.989 5.989 0 01-2.031-.352c-.483-.174-.711-.703-.59-1.202L5.25 4.971z"
        />
      );
    case "fa-chart-pie":
      return (
        <>
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M10.5 6a7.5 7.5 0 107.5 7.5h-7.5V6z"
          />
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            d="M13.5 10.5H21A7.5 7.5 0 0013.5 3v7.5z"
          />
        </>
      );
    case "fa-arrow-up-wide-short":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M3 7.5L7.5 3m0 0L12 7.5M7.5 3v13.5m13.5 0L16.5 21m0 0L12 16.5m4.5 4.5V7.5"
        />
      );
    case "fa-file-lines":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M19.5 14.25v-2.625a3.375 3.375 0 00-3.375-3.375h-1.5A1.125 1.125 0 0113.5 7.125v-1.5a3.375 3.375 0 00-3.375-3.375H8.25m0 12.75h7.5m-7.5 3H12M10.5 2.25H5.625c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125V11.25a9 9 0 00-9-9z"
        />
      );
    case "fa-clipboard-check":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M10.125 2.25h-4.5c-.621 0-1.125.504-1.125 1.125v17.25c0 .621.504 1.125 1.125 1.125h12.75c.621 0 1.125-.504 1.125-1.125v-9M10.125 2.25h.375a9 9 0 019 9v.375M10.125 2.25A3.375 3.375 0 0113.5 5.625v1.875a3.375 3.375 0 003.375 3.375h1.875a3.375 3.375 0 003.375-3.375M10.5 15l1.5 1.5 3-3.75"
        />
      );
    case "fa-book":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M12 6.042A8.967 8.967 0 006 3.75c-1.052 0-2.062.18-3 .512v14.25A8.987 8.987 0 016 18c2.305 0 4.408.867 6 2.292m0-14.25a8.966 8.966 0 016-2.292c1.052 0 2.062.18 3 .512v14.25A8.987 8.987 0 0018 18a8.967 8.967 0 00-6 2.292m0-14.25v14.25"
        />
      );
    case "fa-percent":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M9 14.25l6-6m4.5-3.493V21.75l-3.75-1.5-3.75 1.5-3.75-1.5-3.75 1.5V4.757c0-1.108.806-2.057 1.907-2.185a48.507 48.507 0 0111.186 0c1.1.128 1.907 1.077 1.907 2.185zM9.75 9h.008v.008H9.75V9zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0zm4.125 4.5h.008v.008h-.008V13.5zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"
        />
      );
    case "fa-bullseye":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M15.042 21.672L13.684 16.6m0 0l-2.51 2.225.569-9.47 5.227 7.917-3.286-.672zm-7.518-.267A8.25 8.25 0 1120.25 10.5M8.288 14.212A5.25 5.25 0 1117.25 10.5"
        />
      );
    case "fa-check-circle":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
        />
      );
    case "fa-flag":
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M3 3v1.5M3 21v-6m0 0l2.77-.693a14.45 14.45 0 012.228-.188 14.433 14.433 0 013.295.396c.148.04.303.078.461.115 1.135.267 2.308.411 3.498.411 1.765 0 3.468-.328 5.061-.926.24-.09.516-.16.8-.206v-10.5a20.082 20.082 0 00-6.19-.926 14.433 14.433 0 00-3.295.396c-.148.04-.303.078-.461.115-1.135.267-2.308.411-3.498.411a14.45 14.45 0 00-2.228-.188 20.076 20.076 0 00-2.77.693V21z"
        />
      );
    default:
      return (
        <path
          strokeLinecap="round"
          strokeLinejoin="round"
          d="M11.25 11.25l.041-.02a.75.75 0 011.063.852l-.708 2.836a.75.75 0 001.063.853l.041-.021M21 12a9 9 0 11-18 0 9 9 0 0118 0zm-9-3.75h.008v.008H12V8.25z"
        />
      );
  }
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
    <div className="rounded-md border border-slate-200 bg-white shadow-sm">
      <div className="overflow-x-auto relative">
        <table className="w-full text-sm table-fixed">
          <thead className="bg-slate-100/90 backdrop-blur-sm text-slate-700 border-b border-slate-200 sticky top-0 z-10 shadow-sm">
            <tr>
              {columns.map((column) => (
                <th
                  key={column.key}
                  className={`px-4 py-3.5 font-bold whitespace-nowrap ${column.className || "text-left"}`}
                >
                  {column.label}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-slate-200">
            {rows.length ? (
              visibleRows.map((row) => (
                <tr
                  key={row.id || JSON.stringify(row)}
                  className="hover:bg-slate-50/50 transition-colors"
                >
                  {columns.map((column) => (
                    <td
                      key={column.key}
                      className={`px-4 py-3 align-middle ${column.truncate !== false ? "whitespace-nowrap max-w-[200px] sm:max-w-xs md:max-w-md lg:max-w-lg xl:max-w-xl 2xl:max-w-2xl truncate" : ""} ${column.className || "text-left"}`}
                    >
                      {column.render ? column.render(row) : row[column.key]}
                    </td>
                  ))}
                </tr>
              ))
            ) : (
              <tr>
                <td colSpan={columns.length} className="px-4 py-16 text-center">
                  <div className="flex flex-col items-center justify-center gap-3">
                    <div className="w-16 h-16 bg-slate-50 rounded-full flex items-center justify-center text-slate-300 text-3xl mb-2">
                      <Icon name="fa-folder-open" />
                    </div>
                    <p className="font-bold text-slate-500">{emptyText}</p>
                    <p className="text-xs text-slate-400 max-w-xs mx-auto">
                      ยังไม่มีข้อมูลที่จะแสดงผลในตารางนี้
                      ลองเพิ่มข้อมูลหรือปรับการค้นหาใหม่
                    </p>
                  </div>
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
        className={`relative w-full ${maxWidth} bg-white rounded-md shadow-sm flex flex-col max-h-[90vh]`}
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

// ============================================================================
// Auth Components (Redesign)
// ============================================================================

export function AuthInput(props) {
  return (
    <input
      {...props}
      className={`w-full px-4 py-3 bg-white border border-slate-300 rounded-xl text-[15px] focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 transition-all shadow-sm ${props.className || ""}`}
    />
  );
}

export function PasswordInput({
  value,
  onChange,
  placeholder,
  required = false,
  className = "",
}) {
  const [show, setShow] = useState(false);
  return (
    <div className="relative">
      <input
        type={show ? "text" : "password"}
        value={value}
        onChange={onChange}
        placeholder={placeholder}
        required={required}
        className={`w-full px-4 py-3 bg-white border border-slate-300 rounded-xl text-[15px] focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:border-blue-600 transition-all shadow-sm ${className}`}
      />
      <button
        type="button"
        onClick={() => setShow(!show)}
        className="absolute right-4 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600 transition-colors"
      >
        <Icon name={show ? "fa-eye-slash" : "fa-eye"} />
      </button>
    </div>
  );
}

export function Checkbox({ checked, onChange, label, className = "" }) {
  return (
    <label
      className={`flex items-center gap-2 cursor-pointer group ${className}`}
    >
      <div className="relative flex items-center justify-center">
        <input
          type="checkbox"
          checked={checked}
          onChange={onChange}
          className="peer appearance-none w-5 h-5 border border-slate-300 rounded-[6px] bg-white checked:bg-blue-600 checked:border-blue-600 transition-all cursor-pointer focus:outline-none focus:ring-2 focus:ring-blue-600/20 focus:ring-offset-1"
        />
        <div className="absolute inset-0 flex items-center justify-center opacity-0 peer-checked:opacity-100 pointer-events-none text-white text-[10px]">
          <Icon name="fa-check" />
        </div>
      </div>
      {label && (
        <span className="text-sm font-medium text-slate-600 group-hover:text-slate-800 transition-colors select-none">
          {label}
        </span>
      )}
    </label>
  );
}

export function SplitScreenAuthLayout({
  children,
  title,
  subtitle,
  rightTitle,
  rightSubtitle,
  isRegister,
}) {
  return (
    <div className="h-screen w-full relative bg-blue-600 font-sans overflow-hidden">
      {/* Global Background (covers the gap between panes) */}
      <div className="absolute inset-0 z-0 bg-blue-600 pointer-events-none">
        <div className="absolute -top-[20%] -right-[10%] w-[800px] h-[800px] bg-blue-500 rounded-full mix-blend-screen blur-3xl opacity-50"></div>
        <div className="absolute -bottom-[20%] -left-[10%] w-[600px] h-[600px] bg-sky-400 rounded-full mix-blend-screen blur-[100px] opacity-30"></div>
        <div
          className="absolute inset-0"
          style={{
            backgroundImage:
              "radial-gradient(circle at 2px 2px, rgba(255,255,255,0.1) 1px, transparent 0)",
            backgroundSize: "32px 32px",
          }}
        ></div>
      </div>

      {/* Form Pane */}
      <div
        className={`absolute top-0 h-full w-full lg:w-[45%] flex flex-col justify-center px-6 sm:px-12 lg:px-16 py-6 z-20 bg-white transition-all duration-[800ms] ease-[cubic-bezier(0.16,1,0.3,1)] shadow-[0_0_60px_rgba(0,0,0,0.15)] overflow-y-auto ${
          isRegister
            ? "left-0 lg:rounded-r-[40px]"
            : "left-0 lg:left-[55%] lg:rounded-l-[40px]"
        }`}
      >
        <div className="w-full max-w-[400px] mx-auto flex flex-col min-h-full justify-center">
          <div className="flex items-center gap-3 mb-6">
            <AppLogo compact className="!rounded-lg shadow-md" />
            <span className="text-xl font-black text-slate-800 tracking-tight">
              ExamGrading
            </span>
          </div>

          <h1 className="text-2xl sm:text-3xl font-extrabold text-slate-900 mb-2 tracking-tight">
            {title}
          </h1>
          <p className="text-slate-500 font-medium mb-8 text-sm">{subtitle}</p>

          <div className="w-full">{children}</div>
        </div>
      </div>

      {/* Right Pane (Illustration) */}
      <div
        className={`hidden lg:flex absolute top-0 w-[55%] h-full flex-col justify-center px-12 xl:px-20 transition-all duration-[800ms] ease-[cubic-bezier(0.16,1,0.3,1)] z-10 overflow-hidden ${
          isRegister ? "left-[45%]" : "left-0"
        }`}
      >
        <div className="relative z-20 max-w-xl mb-10">
          <h2 className="text-3xl xl:text-4xl font-black text-white mb-4 leading-tight tracking-tight">
            {rightTitle}
          </h2>
          <p className="text-blue-100 text-base font-medium leading-relaxed opacity-90 max-w-lg">
            {rightSubtitle}
          </p>
        </div>

        {/* Clean Glassmorphic Mockup Graphic */}
        <div className="relative z-20 w-full max-w-2xl bg-white/10 backdrop-blur-md rounded-3xl border border-white/20 shadow-[0_30px_60px_rgba(0,0,0,0.2)] p-6 xl:p-8 aspect-[16/10] flex gap-6 overflow-hidden">
          {!isRegister ? (
            <>
              {/* Left Graphic Elements for Login */}
              <div className="w-1/3 flex flex-col gap-4 relative animate-[float_4s_ease-in-out_infinite]">
                <div className="bg-white rounded-2xl p-5 flex-1 shadow-lg flex flex-col justify-center">
                  <div className="w-10 h-10 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center mb-4 border border-blue-100">
                    <Icon name="fa-chart-pie" className="text-lg" />
                  </div>
                  <div className="text-[11px] font-extrabold text-slate-400 uppercase tracking-widest mb-1">
                    ข้อสอบทั้งหมด
                  </div>
                  <div className="text-3xl font-black text-slate-800">
                    1,248
                  </div>
                </div>
                <div className="bg-white rounded-2xl p-5 flex-1 shadow-lg flex flex-col justify-center">
                  <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center mb-4 border border-emerald-100">
                    <Icon name="fa-check-double" className="text-lg" />
                  </div>
                  <div className="text-[11px] font-extrabold text-slate-400 uppercase tracking-widest mb-1">
                    ตรวจแล้ว
                  </div>
                  <div className="text-3xl font-black text-slate-800">
                    98.5<span className="text-xl">%</span>
                  </div>
                </div>
              </div>

              {/* Right Graphic Elements for Login */}
              <div className="w-2/3 bg-white rounded-2xl p-6 shadow-lg flex flex-col relative animate-[float_5s_ease-in-out_infinite_reverse]">
                <div className="flex justify-between items-center mb-8">
                  <div className="text-sm font-bold text-slate-800">
                    ภาพรวมประสิทธิภาพ
                  </div>
                  <div className="text-[11px] font-bold bg-slate-50 text-slate-500 px-3 py-1.5 rounded-lg border border-slate-100">
                    รายสัปดาห์{" "}
                    <Icon name="fa-chevron-down" className="ml-1 text-[10px]" />
                  </div>
                </div>
                <div className="flex-1 flex items-end gap-3 px-2">
                  {[40, 60, 45, 80, 55, 90, 75].map((h, i) => (
                    <div
                      key={i}
                      className="flex-1 bg-slate-100 rounded-t-md relative group h-full"
                    >
                      <div
                        className="absolute bottom-0 w-full bg-blue-500 rounded-t-md transition-all duration-700 ease-out group-hover:bg-blue-600"
                        style={{ height: `${h}%` }}
                      ></div>
                    </div>
                  ))}
                </div>
              </div>
            </>
          ) : (
            <>
              {/* Graphic Elements for Register */}
              <div className="flex-1 flex flex-col gap-6 justify-center items-center relative">
                <div className="absolute inset-0 bg-blue-500/10 rounded-2xl animate-pulse"></div>
                <div className="w-32 h-32 bg-white rounded-full flex items-center justify-center shadow-xl border-4 border-blue-50 relative z-10 animate-[float_4s_ease-in-out_infinite]">
                  <Icon
                    name="fa-user-plus"
                    className="text-5xl text-blue-500"
                  />
                  <div className="absolute -bottom-2 -right-2 w-10 h-10 bg-emerald-500 rounded-full border-4 border-white flex items-center justify-center">
                    <Icon name="fa-check" className="text-white text-sm" />
                  </div>
                </div>
                <div className="space-y-3 w-full max-w-sm relative z-10 text-center">
                  <div className="h-4 bg-white/40 rounded-full w-3/4 mx-auto"></div>
                  <div className="h-4 bg-white/30 rounded-full w-1/2 mx-auto"></div>
                  <div className="h-4 bg-white/20 rounded-full w-2/3 mx-auto"></div>
                </div>
                <div className="flex gap-4 mt-4 relative z-10 w-full max-w-xs animate-[float_5s_ease-in-out_infinite_reverse]">
                  <div className="h-10 bg-white/80 rounded-xl flex-1 shadow-sm backdrop-blur-md"></div>
                  <div className="h-10 bg-blue-500 rounded-xl flex-1 shadow-sm shadow-blue-500/50"></div>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  );
}
