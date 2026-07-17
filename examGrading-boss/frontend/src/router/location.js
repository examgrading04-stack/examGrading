import { legacyRouteMap, routes } from "../config/routes.js";

export function currentRouteId() {
  const pathname =
    window.location.pathname.split("/").filter(Boolean).pop() || "";
  if (pathname === "admin.html" || pathname === "admin") return "admin";
  if (pathname === "login.html" || pathname === "login") return "login";
  if (pathname === "register.html" || pathname === "register") {
    return "register";
  }
  if (!pathname || pathname === "index.html") return "dashboard";
  if (legacyRouteMap[pathname]) return legacyRouteMap[pathname];

  const clean = window.location.pathname.replace(/\/$/, "");
  const found = routes.find(
    (route) => route.path === clean || clean.endsWith(route.path),
  );
  return found?.id || "dashboard";
}

export function currentQuery() {
  return Object.fromEntries(
    new URLSearchParams(window.location.search).entries(),
  );
}
