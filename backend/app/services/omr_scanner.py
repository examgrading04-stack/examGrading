"""
OMR Answer Sheet Scanner  v3.0
================================
รองรับกระดาษคำตอบ 30, 50, 100 ข้อ  (5 ตัวเลือก A-E)
"""

# pyrefly: ignore [missing-import]
import cv2, numpy as np, json, os, sys
from dataclasses import dataclass, field

# Windows console บางเครื่องใช้ encoding ที่ไม่รองรับภาษาไทย (เช่น cp1252)
# ทำให้ print แล้ว crash; บังคับเป็น UTF-8 ถ้ารองรับ
try:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if hasattr(sys.stderr, "reconfigure"):
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass
try:
    from sklearn.cluster import KMeans

    SKLEARN_AVAILABLE = True
except ImportError:
    SKLEARN_AVAILABLE = False
try:
    # pyrefly: ignore [missing-import]
    from pyzbar import pyzbar as _pyzbar

    PYZBAR_AVAILABLE = True
except ImportError:
    PYZBAR_AVAILABLE = False


@dataclass
class SheetMetadata:
    subject_code: str = ""
    subject_name: str = ""
    student_id: str = ""
    student_name: str = ""
    exam_date: str = ""
    total_questions: int = 0
    sheet_id: str = ""
    exam_id: str = ""


@dataclass
class OMRResult:
    metadata: SheetMetadata = None
    answers: dict = field(default_factory=dict)
    flagged: list = field(default_factory=list)
    raw_scores: dict = field(default_factory=dict)
    success: bool = False
    error_msg: str = ""


class OMRConfig:
    NORM_FILL_MIN = 0.090
    NORM_GAP_MIN = 0.035
    MULTI_MARK_RATIO = 0.55
    ANCHOR_MIN_AREA = 3000
    ANCHOR_MAX_AREA = 9000
    ANCHOR_ASPECT_TOL = 0.15
    WARP_W = 900
    WARP_H = 1200
    BUBBLE_RADIUS = 12
    HOUGH_MIN_R = 9
    HOUGH_MAX_R = 15
    HOUGH_MIN_DIST = 20
    DEBUG_CIRCLE_RADIUS_OFFSET = -3
    SNAP_TO_DETECTED_CIRCLE = True
    SNAP_SEARCH_PAD = 18  # ลดลงเพื่อไม่ให้ไปจับวงกลมข้างๆ
    SNAP_PARAM2 = 14  # ต่ำลงเพื่อเจอ bubble ที่ฝนแล้ว (มืดกว่า) ได้ง่ายขึ้น
    SNAP_FALLBACK_SCORE = 0.15  # snap ทุกครั้งที่คะแนน < 0.15
    LOCAL_REFINE_ENABLE = True
    LOCAL_REFINE_RADIUS = (
        12  # ลดลงเพื่อไม่ให้ overlap กับวงกลมข้างเคียง (ระยะห่างวงกลม ~45px)
    )
    LOCAL_REFINE_STEP = 2  # กว้าง radius ทดแทนด้วย step ใหญ่ขึ้นเพื่อความเร็ว
    LOCAL_REFINE_EARLY_STOP = 0.70
    CHOICES = ["A", "B", "C", "D", "E"]


def _layout_question_count(total_q: int) -> int:
    """
    จำนวนข้อที่ใช้วาง grid จริงบนกระดาษ
    กระดาษรองรับ layout 30/50/100 เท่านั้น
    """
    if total_q <= 30:
        return 30
    if total_q <= 50:
        return 50
    return 100


def load_and_preprocess(path_or_img):
    if isinstance(path_or_img, str):
        img = cv2.imread(path_or_img)
        if img is None:
            raise FileNotFoundError(f"ไม่พบ: {path_or_img}")
    else:
        img = path_or_img.copy()
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    # เพิ่มความทนต่อแสง/เงา: CLAHE + adaptive threshold แบบ Gaussian
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray_eq = clahe.apply(gray)
    blur = cv2.GaussianBlur(gray_eq, (5, 5), 0)
    thresh = cv2.adaptiveThreshold(
        blur, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C, cv2.THRESH_BINARY_INV, 31, 8
    )
    # ลด noise จุดเล็กๆ เพื่อให้หา anchor เสถียรขึ้น
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, k, iterations=1)
    return img, gray, thresh


def find_anchor_points(thresh_img):
    H, W = thresh_img.shape[:2]
    contours, _ = cv2.findContours(
        thresh_img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE
    )
    cands = []
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area <= 0:
            continue

        # ใช้สัดส่วนพื้นที่ภาพแทนค่า area คงที่ (รองรับหลายความละเอียด)
        area_frac = area / float(H * W)
        if not (0.00002 < area_frac < 0.03):
            continue

        x, y, w, h = cv2.boundingRect(cnt)
        if w <= 0 or h <= 0:
            continue
        if w < max(8, W * 0.004) or h < max(8, H * 0.004):
            continue

        # anchor เป็นสี่เหลี่ยมเกือบจัตุรัส และค่อนข้างทึบ
        asp = w / h
        if not (0.62 < asp < 1.55):
            continue
        rect_area = float(w * h)
        fill = area / rect_area if rect_area > 0 else 0.0
        if fill < 0.45:
            continue

        peri = cv2.arcLength(cnt, True)
        approx = cv2.approxPolyDP(cnt, 0.03 * peri, True)
        if len(approx) < 4:
            continue

        # score: ให้ความสำคัญกับพื้นที่ + ความทึบ
        score = area * (0.5 + fill)
        cands.append((x + w // 2, y + h // 2, score, w, h))
    zones = {
        "TL": (0, W * 0.45, 0, H * 0.45),
        "TR": (W * 0.55, W, 0, H * 0.45),
        "BL": (0, W * 0.45, H * 0.55, H),
        "BR": (W * 0.55, W, H * 0.55, H),
    }
    found = {}
    for lbl, (x1, x2, y1, y2) in zones.items():
        pts = [p for p in cands if x1 < p[0] < x2 and y1 < p[1] < y2]
        if pts:
            found[lbl] = max(pts, key=lambda p: p[2])[:2]
    if len(found) == 4:
        return [found["TL"], found["TR"], found["BL"], found["BR"]]
    return _select_anchor_points_from_candidates(cands, W, H)


def _select_anchor_points_from_candidates(cands, W, H):
    if len(cands) < 4:
        return None

    def distinct(points):
        keys = {(int(x), int(y)) for x, y in points}
        return len(keys) == 4

    def geometry_ok(points):
        tl, tr, bl, br = points
        top_w = abs(tr[0] - tl[0])
        bottom_w = abs(br[0] - bl[0])
        left_h = abs(bl[1] - tl[1])
        right_h = abs(br[1] - tr[1])
        if min(top_w, bottom_w) < W * 0.25 or min(left_h, right_h) < H * 0.25:
            return False
        if max(top_w, bottom_w) / max(1, min(top_w, bottom_w)) > 2.8:
            return False
        if max(left_h, right_h) / max(1, min(left_h, right_h)) > 2.8:
            return False
        return True

    candidates = sorted(cands, key=lambda p: p[2], reverse=True)[:80]
    tl = min(candidates, key=lambda p: p[0] / W + p[1] / H)
    tr = max(candidates, key=lambda p: p[0] / W - p[1] / H)
    bl = max(candidates, key=lambda p: p[1] / H - p[0] / W)
    br = max(candidates, key=lambda p: p[0] / W + p[1] / H)
    points = [tl[:2], tr[:2], bl[:2], br[:2]]
    if distinct(points) and geometry_ok(points):
        return points

    best = None
    best_score = -1
    for tl in candidates:
        for tr in candidates:
            if tr[0] <= tl[0] or abs(tr[1] - tl[1]) > H * 0.30:
                continue
            for bl in candidates:
                if bl[1] <= tl[1] or abs(bl[0] - tl[0]) > W * 0.30:
                    continue
                for br in candidates:
                    points = [tl[:2], tr[:2], bl[:2], br[:2]]
                    if br[0] <= bl[0] or br[1] <= tr[1]:
                        continue
                    if not distinct(points) or not geometry_ok(points):
                        continue
                    area = cv2.contourArea(np.float32(points))
                    if area <= W * H * 0.15:
                        continue
                    score = area + sum(p[2] for p in [tl, tr, bl, br])
                    if score > best_score:
                        best_score = score
                        best = points
    return best


def warp_perspective(img, anchors):
    W, H = OMRConfig.WARP_W, OMRConfig.WARP_H
    src = np.float32(anchors)
    dst = np.float32([[0, 0], [W, 0], [0, H], [W, H]])
    return cv2.warpPerspective(img, cv2.getPerspectiveTransform(src, dst), (W, H))


def _parse_qr_data(data, meta):
    """แปลง QR string → SheetMetadata"""
    try:
        d = json.loads(data)
        meta.subject_code = d.get("subject_code", d.get("subject_code", ""))
        meta.subject_name = d.get("subject_name", d.get("subject_name", ""))
        meta.student_id = d.get("student_id", d.get("student_id", ""))
        meta.student_name = d.get("student_name", d.get("student_name", ""))
        meta.exam_date = d.get("exam_date", d.get("exam_date", ""))
        meta.total_questions = int(
            d.get("total_questions", d.get("total_questions", 0))
        )
        meta.sheet_id = d.get("sheet_id", d.get("sheet_id", ""))
        meta.exam_id = d.get("exam_id", d.get("exam_id", ""))
        if not meta.exam_id and ":" in meta.sheet_id:
            meta.exam_id = meta.sheet_id.split(":", 1)[0]
    except:
        meta.subject_code = data.strip()
    return meta


def _merge_metadata(primary, fallback):
    for attr in [
        "subject_code",
        "subject_name",
        "student_id",
        "student_name",
        "exam_date",
        "sheet_id",
        "exam_id",
    ]:
        if not getattr(primary, attr, "") and getattr(fallback, attr, ""):
            setattr(primary, attr, getattr(fallback, attr))
    if not primary.total_questions and fallback.total_questions:
        primary.total_questions = fallback.total_questions
    return primary


def decode_qr(img):
    """Multi-strategy QR decode: ลอง 6 วิธี + pyzbar fallback"""
    meta = SheetMetadata()
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img.copy()
    H, W = gray.shape
    detector = cv2.QRCodeDetector()
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    # QR อยู่ที่ top-right ประมาณ 45-100% x, 0-35% y
    crops = [
        gray,
        gray[: int(H * 0.45), int(W * 0.35) :],
        gray[: int(H * 0.50), int(W * 0.25) :],
        gray[: int(H * 0.55), int(W * 0.15) :],
        gray[: int(H * 0.45), :],
        gray[: int(H * 0.65), :],
    ]
    candidates = []
    for crop in crops:
        if crop.size == 0:
            continue
        variants = [crop, clahe.apply(crop)]
        _, otsu = cv2.threshold(crop, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
        variants.extend([otsu, 255 - otsu])
        adaptive = cv2.adaptiveThreshold(
            clahe.apply(crop),
            255,
            cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
            cv2.THRESH_BINARY,
            31,
            5,
        )
        variants.extend([adaptive, 255 - adaptive])
        for variant in variants:
            candidates.append(variant)
            h, w = variant.shape[:2]
            if min(h, w) < 900:
                candidates.append(
                    cv2.resize(variant, (w * 2, h * 2), interpolation=cv2.INTER_CUBIC)
                )
    for cand in candidates:
        try:
            data, _, _ = detector.detectAndDecode(cand)
            if data:
                return _parse_qr_data(data, meta)
        except:
            pass
    # pyzbar fallback
    if PYZBAR_AVAILABLE:
        for cand in candidates:
            try:
                for r in _pyzbar.decode(cand):
                    data = r.data.decode("utf-8")
                    if data:
                        return _parse_qr_data(data, meta)
            except:
                pass
    return meta


def auto_detect_questions(warped_gray, grid_rect):
    """ประมาณจำนวนข้อจาก Hough circles เมื่อ QR decode ไม่ได้"""
    gx, gy, gw, gh = grid_rect
    roi = warped_gray[gy : gy + gh, gx : gx + gw]
    blur = cv2.GaussianBlur(roi, (5, 5), 0)
    # ใช้ MIN_DIST เล็กลงเพื่อให้นับได้มากขึ้น ไม่ต้องแม่นยำ
    for p2 in [12, 10, 8, 6]:
        c = cv2.HoughCircles(
            blur,
            cv2.HOUGH_GRADIENT,
            dp=1,
            minDist=10,
            param1=50,
            param2=p2,
            minRadius=OMRConfig.HOUGH_MIN_R,
            maxRadius=OMRConfig.HOUGH_MAX_R,
        )
        if c is not None and len(c[0]) > 50:
            n = len(c[0])
            # 30q=150, 50q=250, 100q=500 bubbles
            if n < 210:
                return 30
            elif n < 380:
                return 50
            else:
                return 100
    return 30  # default


def detect_grid_region(warped_gray, total_questions):
    """
    หาพื้นที่กล่อง bubble โดยรวม bounding rect ของ contour ทั้งหมด
    ในโซน bubble (ครึ่งล่างของภาพ) แทนการหา contour เดี่ยวที่ใหญ่สุด
    แก้ปัญหา: เส้นแบ่งกลางกระดาษทำให้ได้ครึ่ง grid
    """
    H, W = warped_gray.shape[:2]
    # โซน bubble อยู่ครึ่งล่างของภาพ (ต่ำกว่า QR+header)
    y_start = int(H * 0.28)
    roi = warped_gray[y_start:, :]

    blur = cv2.GaussianBlur(roi, (5, 5), 0)
    edges = cv2.Canny(blur, 30, 100)
    contours, _ = cv2.findContours(edges, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)

    img_area = H * W
    min_area = img_area * 0.005  # กรอง noise เล็กๆ

    xs1, ys1, xs2, ys2 = [], [], [], []
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area < min_area:
            continue
        x, y, w, h = cv2.boundingRect(cnt)
        # กรองออก contour ที่กว้างหรือสูงผิดปกติ (เส้น header, etc.)
        if w > W * 0.98 or h > H * 0.85:
            continue
        xs1.append(x)
        ys1.append(y)
        xs2.append(x + w)
        ys2.append(y + h)

    if xs1:
        gx = max(0, min(xs1) - 5)
        gy = max(0, min(ys1) - 5) + y_start
        gx2 = min(W, max(xs2) + 5)
        gy2 = min(H, max(ys2) + 5 + y_start)
        gw, gh = gx2 - gx, gy2 - gy
        # sanity check: grid ต้องครอบ >= 30% ของภาพ
        if gw * gh > img_area * 0.20:
            return (gx, gy, gw, gh)

    # fallback
    iw, ih = W, H
    return (int(iw * 0.02), int(ih * 0.30), int(iw * 0.96), int(ih * 0.62))


def robust_grid_1d(data_1d, k, expected_spacing=30):
    # pyrefly: ignore [missing-import]
    import numpy as np

    if not data_1d:
        return []
    pts = np.sort(data_1d)
    if len(pts) == 1:
        return [int(pts[0] + i * expected_spacing) for i in range(k)]
    diffs = np.diff(pts)
    diffs = diffs[diffs > 10]
    if len(diffs) == 0:
        return [int(pts[0] + i * expected_spacing) for i in range(k)]
    min_d = np.min(diffs)
    valid = diffs[diffs < 1.5 * min_d]
    step = np.median(valid) if len(valid) > 0 else min_d
    return [int(pts[0] + i * step) for i in range(k)]


def _kmeans_uniform_init(data_1d, k):
    """K-means ด้วย uniform init เพื่อให้ edge cluster ไม่หาย"""
    arr = np.array(data_1d).reshape(-1, 1).astype(np.float32)
    mn, mx = float(arr.min()), float(arr.max())
    init = np.linspace(mn, mx, k).reshape(-1, 1)
    km = KMeans(k, init=init, n_init=1, random_state=0)
    km.fit(arr)
    return sorted([int(c[0]) for c in km.cluster_centers_])


def _adaptive_bubble_positions(warped, grid_rect, n_q):
    """
    ตรวจหาตำแหน่ง bubble จาก HoughCircles จริงในภาพ
    ใช้ Canny edge detection เพื่อให้จับได้ทั้ง bubble ที่ว่างเปล่า (2 ขอบ) และที่ฝนแล้ว (1 ขอบ)
    """
    gx, gy, gw, gh = grid_rect
    grid_img = warped[gy : gy + gh, gx : gx + gw]
    gray_grid = cv2.cvtColor(grid_img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.5, tileGridSize=(8, 8))
    enhanced = clahe.apply(gray_grid)
    blurred = cv2.GaussianBlur(enhanced, (3, 3), 0)
    edges = cv2.Canny(blurred, 50, 150)

    n_groups = 4 if n_q > 50 else 2
    rpg = n_q // n_groups

    circles = cv2.HoughCircles(
        edges,
        cv2.HOUGH_GRADIENT,
        dp=1,
        minDist=18,
        param1=50,
        param2=12,
        minRadius=9,
        maxRadius=16,
    )
    if circles is None:
        return None

    pts = np.round(circles[0, :, :2]).astype(int)

    # ยอมให้เจอแค่ครึ่งนึงของที่ควรจะเป็นก็พอ เพราะเราใช้ KMeans หาจุดศูนย์กลาง
    if len(pts) < n_q * 1.5:
        return None

    x_split = gw / n_groups
    positions = []
    for gi in range(n_groups):
        x0 = int(gi * x_split)
        x1 = int((gi + 1) * x_split)
        grp = pts[(pts[:, 0] >= x0) & (pts[:, 0] < x1)]
        if len(grp) < max(5, rpg):
            return None

        x_arr = [int(v) for v in np.sort(grp[:, 0])]
        y_arr = [int(v) for v in np.sort(grp[:, 1])]

        def cluster_1d(arr, max_gap):
            if not arr: return []
            clusters = []
            curr = [arr[0]]
            for v in arr[1:]:
                if v - curr[-1] <= max_gap:
                    curr.append(v)
                else:
                    clusters.append(int(np.median(curr)))
                    curr = [v]
            clusters.append(int(np.median(curr)))
            return clusters

        def select_best_5_cols(xc):
            if not xc: return []
            if len(xc) == 5:
                return xc
            if len(xc) < 5:
                step = int(np.median(np.diff(xc))) if len(xc) >= 2 else 32
                while len(xc) < 5:
                    xc.append(int(xc[-1] + step))
                return xc
            # If > 5 columns found (e.g. detected question number digits on the left),
            # find the best window of 5 consecutive columns whose spacing is most consistent (~32px)
            best_window = xc[:5]
            best_score = float("inf")
            for i in range(len(xc) - 4):
                window = xc[i : i + 5]
                diffs = np.diff(window)
                score = float(np.std(diffs) + abs(np.median(diffs) - 32))
                if score < best_score:
                    best_score = score
                    best_window = window
            return list(best_window)

        def fit_rpg_rows(yc, expected_rpg):
            if not yc: return []
            if len(yc) == expected_rpg:
                return yc
            if len(yc) < expected_rpg:
                step = int(np.median(np.diff(yc))) if len(yc) >= 2 else (28 if expected_rpg > 15 else 48)
                while len(yc) < expected_rpg:
                    yc.append(int(yc[-1] + step))
                return yc
            # If > expected_rpg rows found, pick the best window
            best_window = yc[:expected_rpg]
            best_score = float("inf")
            target_step = 28 if expected_rpg > 15 else 48
            for i in range(len(yc) - expected_rpg + 1):
                window = yc[i : i + expected_rpg]
                diffs = np.diff(window)
                score = float(np.std(diffs) + abs(np.median(diffs) - target_step))
                if score < best_score:
                    best_score = score
                    best_window = window
            return list(best_window)

        x_raw = cluster_1d(x_arr, 18)
        x_centers = select_best_5_cols(x_raw)

        y_gap = 14 if rpg > 15 else 20
        y_raw = cluster_1d(y_arr, y_gap)
        y_centers = fit_rpg_rows(y_raw, rpg)

        if len(x_centers) == 5 and len(y_centers) == rpg:
            positions.append((x_centers, y_centers))
        else:
            return None

    if len(positions) != n_groups:
        return None
    return positions


def get_bubble_positions(warped, grid_rect, n_q):
    """
    พยายามใช้ตำแหน่ง bubble จากภาพจริง (Adaptive) ก่อน
    หากหาไม่เจอจริงๆ หรือได้จำนวนแถว/คอลัมน์ไม่ตรง ให้ใช้ fallback
    """
    adapt = _adaptive_bubble_positions(warped, grid_rect, n_q)
    
    if adapt:
        # Validate that adaptive found exactly 5 cols and rpg rows for all groups
        n_groups = 4 if n_q > 50 else 2
        rpg = n_q // n_groups
        valid = True
        for xs, ys in adapt:
            if len(xs) != 5 or len(ys) != rpg:
                valid = False
                break
                
        if valid:
            print("[DEBUG] Using adaptive bubble positions")
            return adapt
        else:
            print("[DEBUG] Adaptive found incorrect rows/cols. Using fallback positions")

    print("[DEBUG] Adaptive failed, using fallback positions")
    return _fallback_positions(grid_rect, n_q)


def _fallback_positions(grid_rect, n_q):
    """
    Fallback positions with perspective slant compensation.
    """
    gx, gy, gw, gh = grid_rect
    n_groups = 4 if n_q > 50 else 2

    # Top and bottom X anchors for interpolation
    top_x0 = [98, 144, 189, 235, 281]
    bot_x0 = [5, 65, 130, 188, 248]

    top_x1 = [532, 576, 620, 664, 708]
    bot_x1 = [570, 630, 700, 740, 820]

    def interpolate_xs(y_val, top_x, bot_x, y_min=401, y_max=1128):
        ratio = (y_val - y_min) / max(1, (y_max - y_min))
        return [int(tx + ratio * (bx - tx)) for tx, bx in zip(top_x, bot_x)]

    if n_q <= 30:
        ys_abs = [int(410 + i * 48) for i in range(15)]
        xs0_list = [interpolate_xs(y, top_x0, bot_x0) for y in ys_abs]
        xs1_list = [interpolate_xs(y, top_x1, bot_x1) for y in ys_abs]
        positions_abs = [(xs0_list, ys_abs), (xs1_list, ys_abs)]

    elif n_q <= 50:
        ys_abs = [int(410 + i * 28) for i in range(25)]
        xs0_list = [interpolate_xs(y, top_x0, bot_x0) for y in ys_abs]
        xs1_list = [interpolate_xs(y, top_x1, bot_x1) for y in ys_abs]
        positions_abs = [(xs0_list, ys_abs), (xs1_list, ys_abs)]

    else:
        ys_abs = [int(1.42 * (i**2) + 34.95 * i + 401.36) for i in range(25)]
        xs0_100 = [[84 + int(i * 45) for i in range(5)]] * 25
        xs1_100 = [[289 + int(i * 45) for i in range(5)]] * 25
        xs2_100 = [[501 + int(i * 45) for i in range(5)]] * 25
        xs3_100 = [[711 + int(i * 45) for i in range(5)]] * 25
        positions_abs = [
            (xs0_100, ys_abs),
            (xs1_100, ys_abs),
            (xs2_100, ys_abs),
            (xs3_100, ys_abs),
        ]

    return [
        ([[x - gx for x in row_xs] for row_xs in xs], [y - gy for y in ys])
        for xs, ys in positions_abs
    ]


def measure_bubble_ratios(warped, grid_rect, positions):
    gx, gy, gw, gh = grid_rect
    grid_img = warped[gy : gy + gh, gx : gx + gw]
    grid_gray = cv2.cvtColor(grid_img, cv2.COLOR_BGR2GRAY)
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    g = cv2.GaussianBlur(clahe.apply(grid_gray), (3, 3), 0)
    R = OMRConfig.BUBBLE_RADIUS
    r_inner = max(4, int(R) - 1)

    results = {}
    for gi, group in enumerate(positions):
        if group is None:
            continue
        xs, ys = group
        rpg = len(ys)
        for row, y in enumerate(ys):
            q_no = gi * rpg + row + 1
            current_xs = xs[row] if (xs and isinstance(xs[0], (list, tuple))) else xs
            cy = int(y)

            # Local row paper background from safe margins outside column A and column E
            row_bg_left = g[
                max(0, cy - 4) : min(g.shape[0], cy + 5),
                max(0, int(current_xs[0]) - 32) : max(0, int(current_xs[0]) - 14),
            ]
            row_bg_right = g[
                max(0, cy - 4) : min(g.shape[0], cy + 5),
                min(g.shape[1], int(current_xs[-1]) + 14) : min(
                    g.shape[1], int(current_xs[-1]) + 32
                ),
            ]
            bg_vals = []
            if row_bg_left.size > 0:
                bg_vals.extend(row_bg_left.flatten())
            if row_bg_right.size > 0:
                bg_vals.extend(row_bg_right.flatten())
            row_paper_bg = float(np.percentile(bg_vals, 80)) if bg_vals else 220.0

            q_scores = []
            for ch, x in enumerate(current_xs):
                cx = int(x)
                x1 = max(0, cx - r_inner)
                x2 = min(grid_img.shape[1], cx + r_inner)
                y1 = max(0, cy - r_inner)
                y2 = min(grid_img.shape[0], cy + r_inner)
                
                # Prevent negative dimensions if circle is completely outside grid
                if x2 <= x1 or y2 <= y1:
                    q_scores.append(0.0)
                    continue

                inner_mask = np.zeros((y2 - y1, x2 - x1), dtype=np.uint8)
                cv2.circle(inner_mask, (cx - x1, cy - y1), r_inner, 255, -1)
                patch_inner = g[y1:y2, x1:x2]
                inner_vals = patch_inner[inner_mask > 0]
                inner_mean = (
                    float(np.mean(inner_vals)) if len(inner_vals) > 0 else 255.0
                )

                contrast = max(
                    0.0, (row_paper_bg - inner_mean) / max(10.0, row_paper_bg)
                )
                dark_thresh = max(0, row_paper_bg - 25)
                dark_ratio = (
                    float(np.mean(inner_vals < dark_thresh))
                    if len(inner_vals) > 0
                    else 0.0
                )
                score = 0.50 * contrast + 0.50 * dark_ratio
                if score < 0:
                    score = 0.0
                if score > 1:
                    score = 1.0
                q_scores.append(round(score, 4))
            results[q_no] = q_scores
    return results


def _compute_baselines(raw_scores, n_q):
    """column baseline per group = 20th percentile ratio ของแต่ละ choice"""
    if raw_scores:
        n_q = max(n_q, max(raw_scores.keys()))
        
    
    n_groups = 4 if n_q > 50 else 2
    rpg = n_q // n_groups
    baselines = {}
    for gi in range(n_groups):
        qs = {
            q: raw_scores[q] for q in raw_scores if gi * rpg + 1 <= q <= (gi + 1) * rpg
        }
        if not qs:
            for q in range(gi * rpg + 1, (gi + 1) * rpg + 1):
                baselines[q] = [0.0] * 5
            continue
        cv = {i: [] for i in range(5)}
        for r in qs.values():
            for i, v in enumerate(r):
                cv[i].append(v)
        bl = [float(np.percentile(cv[i], 20)) if cv[i] else 0 for i in range(5)]
        for q in qs:
            baselines[q] = bl
    return baselines


def _compute_decision_stats(raw_scores, n_q=None):
    """
    คืนค่าสถิติที่ใช้ตัดสิน:
    - baselines: per-column background level
    - norms_by_q: normalized score (ratio - baseline)
    - dynamic_fill_min: threshold ฝน (จำกัดไม่เกิน 0.12 เพื่อไม่ตัดดินสอสีอ่อน)
    """
    if n_q and n_q > 0:
        bls = _compute_baselines(raw_scores, n_q)
    else:
        cv = {i: [] for i in range(5)}
        for r in raw_scores.values():
            for i, v in enumerate(r):
                cv[i].append(v)
        bl = [float(np.percentile(cv[i], 20)) if cv[i] else 0 for i in range(5)]
        bls = {q: bl for q in raw_scores}

    norms_by_q = {}
    max_norms = []
    for q_no, ratios in raw_scores.items():
        if not ratios:
            continue
        bl = bls.get(q_no, [0] * 5)
        norm = [float(r - bl[i]) for i, r in enumerate(ratios)]
        norms_by_q[q_no] = norm
        max_norms.append(max(norm))

    dynamic_fill_min = OMRConfig.NORM_FILL_MIN
    if max_norms:
        mx = np.clip(np.array(max_norms, dtype=np.float32), 0.0, 1.0)
        p90 = float(np.percentile(mx, 90))
        if p90 >= 0.20:
            mx_u8 = (mx * 255.0).astype(np.uint8).reshape(-1, 1)
            try:
                thr_u8, _ = cv2.threshold(
                    mx_u8, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU
                )
                otsu_thr = float(thr_u8) / 255.0
                dynamic_fill_min = max(dynamic_fill_min, otsu_thr)
            except Exception:
                pass

    dynamic_fill_min = min(max(dynamic_fill_min, 0.070), 0.120)
    return bls, norms_by_q, float(dynamic_fill_min)


def decide_answers(raw_scores, n_q=None):
    """ตัดสินด้วย normalized score (ratio - baseline) แก้ปัญหาตัวอักษรใน bubble"""
    choices = OMRConfig.CHOICES
    answers = {}
    flagged = []
    bls, norms_by_q, dynamic_fill_min = _compute_decision_stats(raw_scores, n_q=n_q)
    for q_no, ratios in sorted(raw_scores.items()):
        if not ratios:
            answers[q_no] = None
            continue
        norm = norms_by_q.get(q_no)
        if norm is None:
            bl = bls.get(q_no, [0] * 5)
            norm = [r - bl[i] for i, r in enumerate(ratios)]
        sr = sorted(enumerate(norm), key=lambda x: x[1], reverse=True)
        max_idx, max_n = sr[0]
        second_idx, second_n = sr[1] if len(sr) > 1 else (0, 0.0)
        gap = max_n - second_n if len(sr) > 1 else 1.0

        if max_n < dynamic_fill_min:
            flagged.append(
                {
                    "question": q_no,
                    "reason": "not_filled",
                    "ratios": dict(zip(choices, ratios)),
                }
            )
            answers[q_no] = None
        else:
            # Check for multiple marks (2 or more choices above threshold or close to max)
            multi_choices = [
                choices[i]
                for i, n in enumerate(norm)
                if n >= dynamic_fill_min * 0.75
                and (
                    (n / max(1e-5, max_n))
                    >= float(getattr(OMRConfig, "MULTI_MARK_RATIO", 0.55))
                    or (max_n - n) <= 0.06
                )
            ]
            if len(multi_choices) >= 2:
                detected_str = ",".join(multi_choices)
                flagged.append(
                    {
                        "question": q_no,
                        "reason": "multiple_mark",
                        "detected": detected_str,
                        "ratios": dict(zip(choices, ratios)),
                    }
                )
                answers[q_no] = detected_str
            elif second_n >= dynamic_fill_min * 0.95 or second_n >= 0.075:
                # มีรอยฝนเกินช่องหรือเปื้อนในช่องอื่นอย่างเห็นได้ชัด -> แจ้งเตือนให้ครูตรวจสอบ
                flagged.append(
                    {
                        "question": q_no,
                        "reason": "overflow_smudge",
                        "detected": choices[max_idx],
                        "smudge_choice": choices[second_idx],
                        "ratios": dict(zip(choices, ratios)),
                    }
                )
                answers[q_no] = choices[max_idx]
            elif gap < OMRConfig.NORM_GAP_MIN:
                flagged.append(
                    {
                        "question": q_no,
                        "reason": "low_confidence",
                        "ratios": dict(zip(choices, ratios)),
                    }
                )
                answers[q_no] = choices[max_idx]
            else:
                answers[q_no] = choices[max_idx]
    return answers, flagged


def summarize_marks(raw_scores, n_q):
    """
    สรุปจากคะแนนที่วัดได้ (ไม่ต้องมีเฉลย):
    - filled_count: จำนวนข้อที่น่าจะมีการฝน
    - blank_count: จำนวนข้อที่น่าจะไม่ได้ฝน
    - suspicious: list ของข้อที่ควรตรวจด้วยตา
    """
    choices = OMRConfig.CHOICES
    _, norms_by_q, fill_min = _compute_decision_stats(raw_scores, n_q=n_q)

    filled = 0
    blank = 0
    suspicious = []

    for q_no in sorted(raw_scores):
        norm = norms_by_q.get(q_no)
        if not norm:
            blank += 1
            suspicious.append({"question": q_no, "reason": "no_score"})
            continue

        sr = sorted(enumerate(norm), key=lambda x: x[1], reverse=True)
        i1, s1 = sr[0]
        i2, s2 = sr[1] if len(sr) > 1 else (None, 0.0)
        gap = float(s1 - s2) if i2 is not None else 1.0

        if s1 < fill_min:
            blank += 1
            continue

        filled += 1

        # suspicious rules
        if gap < OMRConfig.NORM_GAP_MIN:
            suspicious.append(
                {
                    "question": q_no,
                    "reason": "low_confidence",
                    "top": choices[i1],
                    "gap": round(gap, 4),
                    "score": round(float(s1), 4),
                }
            )
            continue
        if s1 < fill_min + 0.03:
            suspicious.append(
                {
                    "question": q_no,
                    "reason": "weak_fill",
                    "top": choices[i1],
                    "score": round(float(s1), 4),
                }
            )
            continue
        if s2 >= fill_min * 0.85:
            suspicious.append(
                {
                    "question": q_no,
                    "reason": "possible_multi",
                    "top": choices[i1],
                    "second": choices[i2] if i2 is not None else None,
                    "gap": round(gap, 4),
                    "score": round(float(s1), 4),
                }
            )
            continue

    return {
        "fill_threshold": round(float(fill_min), 4),
        "filled_count": int(filled),
        "blank_count": int(blank),
        "suspicious": suspicious,
    }


def analyze_bubble_drift(warped, grid_rect, positions):
    """
    วิเคราะห์ drift ของตำแหน่ง bubble ที่ใช้วัด เทียบกับ "ศูนย์กลาง bubble จริง" ที่ตรวจเจอ
    วิธี: สำหรับแต่ละตำแหน่ง (x,y) ใน grid จะตัด patch เล็กๆ แล้วใช้ HoughCircles หา bubble ใกล้จุดกึ่งกลาง
    คืนค่าเป็น list ต่อแถว (ในแต่ละ group): mean_dist_px / max_dist_px / found_count
    """
    gx, gy, gw, gh = grid_rect
    grid_img = warped[gy : gy + gh, gx : gx + gw]
    grid_gray = cv2.cvtColor(grid_img, cv2.COLOR_BGR2GRAY)
    g = cv2.GaussianBlur(grid_gray, (5, 5), 0)

    R = int(OMRConfig.BUBBLE_RADIUS)
    # patch ควรครอบวง bubble + ขอบ
    pad = max(18, R + 10)
    minR = max(6, R - 6)
    maxR = R + 6

    rows_report = []
    for gi, group in enumerate(positions):
        if not group:
            continue
        xs, ys = group
        for row_idx, y in enumerate(ys):
            dists = []
            found = 0
            current_xs = (
                xs[row_idx] if (xs and isinstance(xs[0], (list, tuple))) else xs
            )
            for x in current_xs:
                y1, y2 = max(0, y - pad), min(g.shape[0], y + pad)
                x1, x2 = max(0, x - pad), min(g.shape[1], x + pad)
                patch = g[y1:y2, x1:x2]
                if patch.size == 0:
                    continue

                # หา circle ใน patch รอบๆ center; ตั้ง param2 ต่ำเพื่อให้ detect ได้ง่าย
                circles = cv2.HoughCircles(
                    patch,
                    cv2.HOUGH_GRADIENT,
                    dp=1.2,
                    minDist=R,
                    param1=80,
                    param2=18,
                    minRadius=minR,
                    maxRadius=maxR,
                )
                if circles is None:
                    continue
                cs = np.round(circles[0]).astype(int)
                cx0, cy0 = (x - x1), (y - y1)
                # เลือกวงที่ใกล้จุดคาดที่สุด
                best = None
                best_d2 = 1e18
                for cx, cy, rr in cs:
                    d2 = (cx - cx0) ** 2 + (cy - cy0) ** 2
                    if d2 < best_d2:
                        best_d2 = d2
                        best = (cx, cy, rr)
                if best is None:
                    continue
                dx = float(best[0] - cx0)
                dy = float(best[1] - cy0)
                d = float(np.hypot(dx, dy))
                dists.append(d)
                found += 1

            if dists:
                rows_report.append(
                    {
                        "group": int(gi),
                        "row": int(row_idx + 1),
                        "mean_dist_px": float(np.mean(dists)),
                        "max_dist_px": float(np.max(dists)),
                        "found": int(found),
                        "expected": int(len(xs)),
                    }
                )
            else:
                rows_report.append(
                    {
                        "group": int(gi),
                        "row": int(row_idx + 1),
                        "mean_dist_px": None,
                        "max_dist_px": None,
                        "found": 0,
                        "expected": int(len(xs)),
                    }
                )
    return rows_report


def scan_answer_sheet(image_input, force_questions=0, debug=False):
    result = OMRResult()
    try:
        img, gray, thresh = load_and_preprocess(image_input)
        print(f"[1] Image: {img.shape[1]}x{img.shape[0]}")
        anchors = find_anchor_points(thresh)
        if anchors is None:
            result.error_msg = "ไม่พบ anchor 4 มุม"
            return result
        print("[2] Anchors: OK")
        warped = warp_perspective(img, anchors)
        warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
        print(f"[3] Warp: {warped.shape[1]}x{warped.shape[0]}")
        meta = decode_qr(warped)
        if not meta.exam_id and not meta.sheet_id:
            meta = _merge_metadata(meta, decode_qr(img))
            
        grid_rect_tmp = detect_grid_region(warped_gray, 0)
        detected_layout_q = auto_detect_questions(warped_gray, grid_rect_tmp)
        
        total_q = meta.total_questions if meta.total_questions > 0 else (force_questions or detected_layout_q)
        if meta.total_questions > 0:
            print(f"[4] QR: subject='{meta.subject_code}' tq={total_q}")
        else:
            print(f"[4] QR decode ไม่ได้ → auto-detect: {total_q} ข้อ")
            
        meta.total_questions = total_q
        result.metadata = meta
        
        layout_q = detected_layout_q
        if layout_q != total_q:
            print(f"[4.1] Layout normalize: exam={total_q} -> sheet_layout={layout_q}")
            
        grid_rect = detect_grid_region(warped_gray, layout_q)
        print(f"[5] Grid: {grid_rect}")
        positions = get_bubble_positions(warped, grid_rect, layout_q)
        print(f"[6] Positions: {sum(1 for p in positions if p)} groups OK")
        raw_scores = measure_bubble_ratios(warped, grid_rect, positions)
        
        answers, flagged = decide_answers(raw_scores, n_q=layout_q)
        if total_q and total_q < layout_q:
            answers = {int(q): a for q, a in answers.items() if int(q) <= total_q}
            flagged = [f for f in flagged if int(f.get("question", 0)) <= total_q]
            raw_scores = {int(q): v for q, v in raw_scores.items() if int(q) <= total_q}
        else:
            answers = {int(q): a for q, a in answers.items()}
            raw_scores = {int(q): v for q, v in raw_scores.items()}
            
        result.raw_scores = raw_scores
        result.answers = answers
        result.flagged = flagged
        print(f"[7] Measured: {len(raw_scores)} questions (layout={layout_q})")
        print(f"[8] Answers: {len(answers)} ข้อ, flagged: {len(flagged)}")
        if debug:
            _save_debug(warped, grid_rect, positions, answers, flagged, image_input)
        result.success = True
    except Exception as e:
        result.error_msg = str(e)
        import traceback

        traceback.print_exc()
    return result


def calculate_score(answers, answer_key):
    correct, wrong, skipped = [], [], []
    total_score = 0.0
    earned_score = 0.0

    for q_no, key_data in answer_key.items():
        q_score = 1.0
        if isinstance(key_data, dict):
            key = key_data.get("answer", "")
            q_score = float(key_data.get("score", 1.0))
        else:
            key = key_data

        total_score += q_score

        # รองรับทั้ง key แบบ int และ str จากหลายแหล่งข้อมูล
        a = answers.get(q_no)
        if a is None:
            try:
                a = answers.get(int(q_no))
            except Exception:
                pass
        if a is None:
            try:
                a = answers.get(str(q_no))
            except Exception:
                pass
        if isinstance(a, str):
            a = a.strip().upper()
        if isinstance(key, str):
            key = key.strip().upper()

        if a is None or a == "" or a == "NONE":
            skipped.append(q_no)
        elif "," in a or len(a) > 1:
            # ฝนหลายข้อ หรือเครื่องหมายไม่ถูกต้อง -> ให้ 0 คะแนนและบันทึกใน wrong
            wrong.append({"question": q_no, "student": a, "correct": key, "reason": "multiple_marks"})
        elif a == key:
            correct.append(q_no)
            earned_score += q_score
        else:
            wrong.append({"question": q_no, "student": a, "correct": key})

    return {
        "score": earned_score,
        "total": total_score,
        "percent": round(earned_score / total_score * 100, 1) if total_score else 0,
        "correct": correct,
        "wrong": wrong,
        "skipped": skipped,
    }


def _save_debug(warped, grid_rect, positions, answers, flagged, orig_path):
    debug = warped.copy()
    gx, gy, gw, gh = grid_rect
    cv2.rectangle(debug, (gx, gy), (gx + gw, gy + gh), (0, 255, 0), 2)
    flagged_qs = {f["question"] for f in flagged}
    choices = OMRConfig.CHOICES
    R = OMRConfig.BUBBLE_RADIUS
    dbg_r = max(3, R + int(getattr(OMRConfig, "DEBUG_CIRCLE_RADIUS_OFFSET", -3)))
    # เพื่อให้วง debug ตรง bubble จริง: ใช้ same snapping logic กับ measure_bubble_ratios
    gx0, gy0, gw0, gh0 = grid_rect
    grid_img = warped[gy0 : gy0 + gh0, gx0 : gx0 + gw0]
    grid_gray = cv2.cvtColor(grid_img, cv2.COLOR_BGR2GRAY)
    g = cv2.GaussianBlur(
        cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)).apply(grid_gray), (3, 3), 0
    )

    def _snap(y, x):
        if not getattr(OMRConfig, "SNAP_TO_DETECTED_CIRCLE", True):
            return y, x
        pad = int(getattr(OMRConfig, "SNAP_SEARCH_PAD", 26))
        y1, y2 = max(0, y - pad), min(g.shape[0], y + pad)
        x1, x2 = max(0, x - pad), min(g.shape[1], x + pad)
        patch = g[y1:y2, x1:x2]
        if patch.size == 0:
            return y, x
        minR = max(6, int(OMRConfig.BUBBLE_RADIUS) - 6)
        maxR = int(OMRConfig.BUBBLE_RADIUS) + 6
        circles = cv2.HoughCircles(
            patch,
            cv2.HOUGH_GRADIENT,
            dp=1.2,
            minDist=int(OMRConfig.BUBBLE_RADIUS),
            param1=80,
            param2=int(getattr(OMRConfig, "SNAP_PARAM2", 18)),
            minRadius=minR,
            maxRadius=maxR,
        )
        if circles is None:
            return y, x
        cs = np.round(circles[0]).astype(int)
        cx0, cy0 = (x - x1), (y - y1)
        best = min(cs, key=lambda c: (c[0] - cx0) ** 2 + (c[1] - cy0) ** 2)
        return int(y1 + best[1]), int(x1 + best[0])

    for gi, group in enumerate(positions):
        if not group:
            continue
        xs, ys = group
        rpg = len(ys)
        for row, y in enumerate(ys):
            q_no = gi * rpg + row + 1
            ans = answers.get(q_no)
            current_xs = xs[row] if (xs and isinstance(xs[0], (list, tuple))) else xs
            if not ans or str(ans) == "None":
                continue
            ans_list = [a.strip() for a in str(ans).split(",") if a.strip() in choices]
            for a_item in ans_list:
                ch = choices.index(a_item)
                cx = gx + int(current_xs[ch])
                cy = gy + int(y)
                color = (0, 165, 255) if (q_no in flagged_qs or len(ans_list) > 1) else (0, 255, 0)
                cv2.circle(debug, (cx, cy), dbg_r, color, 2)
                cv2.putText(
                    debug,
                    a_item,
                    (cx - 5, cy + 5),
                    cv2.FONT_HERSHEY_SIMPLEX,
                    0.4,
                    color,
                    1,
                )
            # If flagged for overflow/smudge, also highlight smudge choice
            smudge_items = [f.get("smudge_choice") for f in flagged if f.get("question") == q_no and f.get("smudge_choice")]
            for s_item in smudge_items:
                if s_item in choices and s_item not in ans_list:
                    ch = choices.index(s_item)
                    cx = gx + int(current_xs[ch])
                    cy = gy + int(y)
                    cv2.circle(debug, (cx, cy), dbg_r, (0, 140, 255), 2)
                    cv2.putText(
                        debug,
                        f"{s_item}?",
                        (cx - 8, cy + 5),
                        cv2.FONT_HERSHEY_SIMPLEX,
                        0.35,
                        (0, 140, 255),
                        1,
                    )
    if isinstance(orig_path, str):
        out = os.path.splitext(orig_path)[0] + "_debug.jpg"
    else:
        out = "api_debug.jpg"
    cv2.imwrite(out, debug)
    print(f"[DEBUG] {out}")


if __name__ == "__main__":
    paths = sys.argv[1:] if len(sys.argv) > 1 else []
    if not paths:
        print(
            json.dumps(
                {
                    "error": "Usage: python3 omr_scanner.py <image> [--json] [--force-q 50]"
                },
                ensure_ascii=False,
            )
        )
        sys.exit(0)

    force_q = 0
    clean = []
    output_json = False
    analyze_drift = False
    i = 0
    while i < len(paths):
        if paths[i] == "--force-q" and i + 1 < len(paths):
            force_q = int(paths[i + 1])
            i += 2
        elif paths[i] == "--json":
            output_json = True
            i += 1
        elif paths[i] == "--analyze-drift":
            analyze_drift = True
            i += 1
        else:
            clean.append(paths[i])
            i += 1

    # ปิด print ชั่วคราวถ้าต้องการ output เป็น json (ใช้ stdout redirect)
    import sys, io

    original_stdout = sys.stdout
    if output_json:
        sys.stdout = io.StringIO()

    results_list = []

    for path in clean:
        if not output_json:
            print(f"\n{'='*55}\nสแกน: {path}\n{'='*55}")

        r = scan_answer_sheet(path, force_questions=force_q, debug=not output_json)

        # จัดรูปแบบข้อมูลเป็น JSON / Dict
        sheet_result = {
            "file_path": path,
            "success": r.success,
            "error_msg": r.error_msg,
        }

        if r.success:
            m = r.metadata
            sheet_result["student"] = {
                "subject_code": m.subject_code,
                "subject_name": m.subject_name,
                "student_id": m.student_id,
                "student_name": m.student_name,
                "total_questions": m.total_questions,
                "exam_date": m.exam_date,
                "sheet_id": m.sheet_id,
            }
            sheet_result["answers"] = r.answers
            sheet_result["flagged"] = r.flagged

            if m.total_questions and r.raw_scores:
                sm = summarize_marks(r.raw_scores, m.total_questions)
                sheet_result["summary"] = sm

            if not output_json:
                print(
                    f"\nวิชา: {m.subject_code} {m.subject_name}\nนักเรียน: {m.student_id} {m.student_name}\nจำนวนข้อ: {m.total_questions}"
                )
                print("\nคำตอบ:")
                for q in sorted(r.answers):
                    ans = r.answers[q] or "?"
                    flag = " ⚠" if any(f["question"] == q for f in r.flagged) else ""
                    print(f"  Q{q:3d}: {ans}{flag}")
        else:
            if not output_json:
                print(f"ERROR: {r.error_msg}")

        results_list.append(sheet_result)

    # คืนค่า stdout กลับมาและ Print JSON
    if output_json:
        sys.stdout = original_stdout
        # ส่งออกผลลัพธ์เป็น JSON ทั้งหมด
        print(json.dumps(results_list, ensure_ascii=False, indent=2))
