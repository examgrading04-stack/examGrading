"""
OMR Answer Sheet Scanner  v3.0
================================
รองรับกระดาษคำตอบ 30, 50, 100 ข้อ  (5 ตัวเลือก A-E)
"""
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
    from pyzbar import pyzbar as _pyzbar
    PYZBAR_AVAILABLE = True
except ImportError:
    PYZBAR_AVAILABLE = False

@dataclass
class SheetMetadata:
    subject_code: str=""; subject_name: str=""
    student_id: str=""; student_name: str=""
    exam_date: str=""; total_questions: int=0
    sheet_id: str=""; exam_id: str=""

@dataclass
class OMRResult:
    metadata: SheetMetadata=None
    answers: dict=field(default_factory=dict)
    flagged: list=field(default_factory=list)
    raw_scores: dict=field(default_factory=dict)
    success: bool=False; error_msg: str=""

class OMRConfig:
    # เกณฑ์ถูกใช้กับ "normalized score" (score - baseline) ใน decide_answers
    # score ถูกคำนวณจากความมืดในวง bubble เทียบกับวงแหวนรอบๆ (0..1 โดยประมาณ)
    NORM_FILL_MIN=0.06; NORM_GAP_MIN=0.04
    ANCHOR_MIN_AREA=3000; ANCHOR_MAX_AREA=9000; ANCHOR_ASPECT_TOL=0.15
    WARP_W=900; WARP_H=1200
    BUBBLE_RADIUS=16; HOUGH_MIN_R=10; HOUGH_MAX_R=30; HOUGH_MIN_DIST=20
    DEBUG_CIRCLE_RADIUS_OFFSET=-3  # ทำวง debug ให้เล็กลง (R + offset)
    SNAP_TO_DETECTED_CIRCLE=True   # snap จุดวัดไปศูนย์กลาง bubble จริง
    SNAP_SEARCH_PAD=26             # ขนาดหน้าต่างค้นหา (px) รอบจุดคาด
    SNAP_PARAM2=18                 # Hough param2 (ต่ำ=เจอง่ายขึ้น)
    CHOICES=["A","B","C","D","E"]

def load_and_preprocess(path_or_img):
    if isinstance(path_or_img, str):
        img=cv2.imread(path_or_img)
        if img is None: raise FileNotFoundError(f"ไม่พบ: {path_or_img}")
    else:
        img = path_or_img.copy()
    gray=cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)
    # เพิ่มความทนต่อแสง/เงา: CLAHE + adaptive threshold แบบ Gaussian
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    gray_eq = clahe.apply(gray)
    blur=cv2.GaussianBlur(gray_eq,(5,5),0)
    thresh=cv2.adaptiveThreshold(
        blur,255,cv2.ADAPTIVE_THRESH_GAUSSIAN_C,cv2.THRESH_BINARY_INV,31,8
    )
    # ลด noise จุดเล็กๆ เพื่อให้หา anchor เสถียรขึ้น
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(3,3))
    thresh = cv2.morphologyEx(thresh, cv2.MORPH_OPEN, k, iterations=1)
    return img,gray,thresh

def find_anchor_points(thresh_img):
    H,W=thresh_img.shape[:2]
    contours,_=cv2.findContours(thresh_img,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_SIMPLE)
    cands=[]
    for cnt in contours:
        area=cv2.contourArea(cnt)
        if area <= 0:
            continue

        # ใช้สัดส่วนพื้นที่ภาพแทนค่า area คงที่ (รองรับหลายความละเอียด)
        area_frac = area / float(H * W)
        if not (0.0004 < area_frac < 0.02):
            continue

        x,y,w,h=cv2.boundingRect(cnt)
        if w <= 0 or h <= 0:
            continue

        # anchor เป็นสี่เหลี่ยมเกือบจัตุรัส และค่อนข้างทึบ
        asp=w/h
        if not (0.78 < asp < 1.28):
            continue
        rect_area = float(w * h)
        fill = area / rect_area if rect_area > 0 else 0.0
        if fill < 0.60:
            continue

        peri = cv2.arcLength(cnt, True)
        approx = cv2.approxPolyDP(cnt, 0.03 * peri, True)
        if len(approx) < 4:
            continue

        # score: ให้ความสำคัญกับพื้นที่ + ความทึบ
        score = area * (0.5 + fill)
        cands.append((x + w//2, y + h//2, score))
    zones={"TL":(0,W*.25,0,H*.25),"TR":(W*.75,W,0,H*.25),"BL":(0,W*.25,H*.75,H),"BR":(W*.75,W,H*.75,H)}
    found={}
    for lbl,(x1,x2,y1,y2) in zones.items():
        pts=[(cx,cy,a) for cx,cy,a in cands if x1<cx<x2 and y1<cy<y2]
        if pts: found[lbl]=max(pts,key=lambda p:p[2])[:2]
    if len(found)<4: return None
    return [found["TL"],found["TR"],found["BL"],found["BR"]]

def warp_perspective(img,anchors):
    W,H=OMRConfig.WARP_W,OMRConfig.WARP_H
    src=np.float32(anchors); dst=np.float32([[0,0],[W,0],[0,H],[W,H]])
    return cv2.warpPerspective(img,cv2.getPerspectiveTransform(src,dst),(W,H))

def _parse_qr_data(data, meta):
    """แปลง QR string → SheetMetadata"""
    try:
        d = json.loads(data)
        meta.subject_code  = d.get("sc", d.get("subject_code", ""))
        meta.subject_name  = d.get("sn", d.get("subject_name", ""))
        meta.student_id    = d.get("id", d.get("student_id", ""))
        meta.student_name  = d.get("nm", d.get("student_name", ""))
        meta.exam_date     = d.get("dt", d.get("exam_date", ""))
        meta.total_questions = int(d.get("tq", d.get("total_questions", 0)))
        meta.sheet_id = d.get("sid", d.get("sheet_id", ""))
        meta.exam_id = d.get("eid", d.get("exam_id", ""))
        if not meta.exam_id and ":" in meta.sheet_id:
            meta.exam_id = meta.sheet_id.split(":", 1)[0]
    except:
        meta.subject_code = data.strip()
    return meta

def decode_qr(img):
    """Multi-strategy QR decode: ลอง 6 วิธี + pyzbar fallback"""
    meta = SheetMetadata()
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY) if len(img.shape) == 3 else img.copy()
    H, W = gray.shape
    detector = cv2.QRCodeDetector()
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    # QR อยู่ที่ top-right ประมาณ 45-100% x, 0-35% y
    qr_crop = gray[:int(H*0.38), int(W*0.42):]
    _, otsu = cv2.threshold(gray, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    _, otsu_crop = cv2.threshold(qr_crop, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    candidates = [
        gray, qr_crop,
        clahe.apply(gray), clahe.apply(qr_crop),
        otsu, otsu_crop,
        cv2.resize(gray, (W*2, H*2), interpolation=cv2.INTER_CUBIC),
    ]
    for cand in candidates:
        try:
            data, _, _ = detector.detectAndDecode(cand)
            if data:
                return _parse_qr_data(data, meta)
        except:
            pass
    # pyzbar fallback
    if PYZBAR_AVAILABLE:
        for cand in [gray, clahe.apply(gray), otsu]:
            try:
                for r in _pyzbar.decode(cand):
                    data = r.data.decode('utf-8')
                    if data:
                        return _parse_qr_data(data, meta)
            except:
                pass
    return meta

def auto_detect_questions(warped_gray, grid_rect):
    """ประมาณจำนวนข้อจาก Hough circles เมื่อ QR decode ไม่ได้"""
    gx, gy, gw, gh = grid_rect
    roi = warped_gray[gy:gy+gh, gx:gx+gw]
    blur = cv2.GaussianBlur(roi, (5, 5), 0)
    # ใช้ MIN_DIST เล็กลงเพื่อให้นับได้มากขึ้น ไม่ต้องแม่นยำ
    for p2 in [12, 10, 8, 6]:
        c = cv2.HoughCircles(blur, cv2.HOUGH_GRADIENT, dp=1,
            minDist=10, param1=50, param2=p2,
            minRadius=OMRConfig.HOUGH_MIN_R, maxRadius=OMRConfig.HOUGH_MAX_R)
        if c is not None and len(c[0]) > 50:
            n = len(c[0])
            # 30q=150, 50q=250, 100q=500 bubbles
            if n < 210:   return 30
            elif n < 380: return 50
            else:         return 100
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
        xs1.append(x); ys1.append(y)
        xs2.append(x + w); ys2.append(y + h)

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

def _kmeans_uniform_init(data_1d, k):
    """K-means ด้วย uniform init เพื่อให้ edge cluster ไม่หาย"""
    arr = np.array(data_1d).reshape(-1, 1).astype(np.float32)
    mn, mx = float(arr.min()), float(arr.max())
    init = np.linspace(mn, mx, k).reshape(-1, 1)
    km = KMeans(k, init=init, n_init=1, random_state=0)
    km.fit(arr)
    return sorted([int(c[0]) for c in km.cluster_centers_])

def get_bubble_positions(warped, grid_rect, n_q):
    if not SKLEARN_AVAILABLE:
        return _fallback_positions(grid_rect, n_q)
    gx, gy, gw, gh = grid_rect
    pad = 10
    rx1 = max(0, gx - pad); ry1 = max(0, gy - pad)
    rx2 = min(warped.shape[1], gx + gw + pad)
    ry2 = min(warped.shape[0], gy + gh + pad)
    grid_img  = warped[ry1:ry2, rx1:rx2]
    grid_gray = cv2.cvtColor(grid_img, cv2.COLOR_BGR2GRAY)
    blur = cv2.GaussianBlur(grid_gray, (5, 5), 0)
    n_groups = 4 if n_q > 50 else 2
    rpg = n_q // n_groups
    circles = None
    for p2 in [18, 14, 11, 9, 7, 5]:
        c = cv2.HoughCircles(blur, cv2.HOUGH_GRADIENT, dp=1,
            minDist=OMRConfig.HOUGH_MIN_DIST, param1=50, param2=p2,
            minRadius=OMRConfig.HOUGH_MIN_R, maxRadius=OMRConfig.HOUGH_MAX_R)
        if c is not None:
            c = np.round(c[0]).astype(int)
            if len(c) >= n_q * 5 * 0.45:
                circles = c; break
    if circles is None:
        print("  [WARN] Hough ไม่พบ circles เพียงพอ → fallback")
        return _fallback_positions(grid_rect, n_q)

    # offset: แปลง padded coords → grid-relative
    ox = gx - rx1; oy = gy - ry1
    x_rel = np.array([int(c[0]) - ox for c in circles], dtype=np.float32)
    y_rel = np.array([int(c[1]) - oy for c in circles], dtype=np.float32)

    # แบ่งวงกลมเป็นคอลัมน์ซ้าย/ขวา ตามตำแหน่งพิกัด X
    # ไม่ใช้ K-means รวบยอดเพราะอาจจะไปจับโดนเลขข้อสอบ ทำให้จำนวน center ฝั่งซ้าย/ขวาไม่เท่ากัน
    
    # คำนวณ Y centers จากวงกลมทั้งหมดในภาพ (เพื่อป้องกันปัญหากลุ่มใดกลุ่มหนึ่งตรวจไม่เจอแถวบน/ล่างสุด)
    global_ys = _kmeans_uniform_init(y_rel.tolist(), rpg)

    gx_lists = [[] for _ in range(n_groups)]
    for xi in x_rel.tolist():
        # gw = grid width, gw / n_groups คือความกว้างของแต่ละคอลัมน์
        gi = int(xi // (gw / n_groups))
        if 0 <= gi < n_groups:
            gx_lists[gi].append(xi)

    groups = []
    fb = _fallback_positions(grid_rect, n_q)
    for gi in range(n_groups):
        # รวมกลุ่ม X (Binning) ที่อยู่ใกล้กัน (ห่างไม่เกิน 15px ถือว่าเป็นคอลัมน์เดียวกัน)
        x_bins = []
        for x in sorted(gx_lists[gi]):
            if not x_bins or x - x_bins[-1][-1] > 15:
                x_bins.append([x])
            else:
                x_bins[-1].append(x)
        cluster_xs = [np.mean(b) for b in x_bins]

        # หา 5 คอลัมน์ที่มีระยะห่างใกล้เคียง 32.5 px มากที่สุด
        if len(cluster_xs) >= 5:
            best_xs = cluster_xs[:5]; min_cost = float('inf')
            for i in range(len(cluster_xs) - 4):
                cand = cluster_xs[i:i+5]
                diffs = np.diff(cand)
                # cost = ความแปรปรวน + ความเบี่ยงเบนจากระยะห่างเป้าหมาย (32.5px)
                cost = np.var(diffs) + abs(np.mean(diffs) - 32.5) * 5
                if cost < min_cost:
                    min_cost = cost; best_xs = cand
            xs = [int(x) for x in best_xs]
        else:
            print(f"  [WARN] group {gi}: found only {len(cluster_xs)} columns, fallback")
            xs = fb[gi][0]

        # ใช้ global_ys แทนเพื่อความสม่ำเสมอของแถว
        groups.append((xs, [int(y) for y in global_ys]))
    return groups


def _fallback_positions(grid_rect,n_q):
    gx,gy,gw,gh=grid_rect
    n_groups=4 if n_q>50 else 2; rpg=n_q//n_groups
    group_w=gw//n_groups; row_h=gh/rpg
    # ค่าคงที่จากตำแหน่งจริงของกระดาษบนพิกัด 900x1200
    bw = 32.5
    xoff = 64 if n_groups == 4 else 148
    return [([int((gi*group_w)+xoff+ch*bw) for ch in range(5)],[int((r+.5)*row_h) for r in range(rpg)]) for gi in range(n_groups)]

def measure_bubble_ratios(warped,grid_rect,positions):
    gx,gy,gw,gh=grid_rect
    grid_img=warped[gy:gy+gh,gx:gx+gw]
    grid_gray=cv2.cvtColor(grid_img,cv2.COLOR_BGR2GRAY)
    R=OMRConfig.BUBBLE_RADIUS

    # ใช้ความมืด (gray) แทนจำนวนพิกเซลจาก threshold เพื่อทนแสง/เงา/คุณภาพกล้อง
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
    g = clahe.apply(grid_gray)
    g = cv2.GaussianBlur(g, (3, 3), 0)

    def _mean_in_mask(patch, mask):
        # mask เป็น 0/255
        m = mask > 0
        if not np.any(m):
            return 255.0
        return float(np.mean(patch[m]))

    def _snap_center(y, x):
        """หา center bubble จริงใกล้ (x,y) ด้วย Hough ใน patch เล็กๆ"""
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
        try:
            circles = cv2.HoughCircles(
                patch, cv2.HOUGH_GRADIENT,
                dp=1.2, minDist=int(OMRConfig.BUBBLE_RADIUS),
                param1=80, param2=int(getattr(OMRConfig, "SNAP_PARAM2", 18)),
                minRadius=minR, maxRadius=maxR
            )
        except Exception:
            circles = None
        if circles is None:
            return y, x
        cs = np.round(circles[0]).astype(int)
        cx0, cy0 = (x - x1), (y - y1)
        best = None
        best_d2 = 1e18
        for (cx, cy, rr) in cs:
            d2 = (cx - cx0) ** 2 + (cy - cy0) ** 2
            if d2 < best_d2:
                best_d2 = d2
                best = (cx, cy)
        if best is None:
            return y, x
        return int(y1 + best[1]), int(x1 + best[0])

    def ratio_at(y,x):
        # score ~ 0..1  (ยิ่งมาก = ยิ่งมืด = น่าจะฝน)
        y, x = _snap_center(int(y), int(x))
        pad = R + 10
        y1,y2=max(0,y-pad),min(g.shape[0],y+pad)
        x1,x2=max(0,x-pad),min(g.shape[1],x+pad)
        patch=g[y1:y2,x1:x2]
        if patch.size==0: return 0.0

        cy = y - y1
        cx = x - x1
        h,w = patch.shape[:2]
        if not (0 <= cx < w and 0 <= cy < h):
            return 0.0

        inner = np.zeros((h,w), np.uint8)
        ring  = np.zeros((h,w), np.uint8)
        inner_r = max(4, R - 2)
        ring_r1 = R + 3
        ring_r2 = R + 9
        cv2.circle(inner, (cx,cy), inner_r, 255, -1)
        cv2.circle(ring,  (cx,cy), ring_r2, 255, -1)
        cv2.circle(ring,  (cx,cy), ring_r1, 0,   -1)

        inner_mean = _mean_in_mask(patch, inner)
        ring_mean  = _mean_in_mask(patch, ring)
        # กัน division-by-zero และความผิดพลาดจาก ring ที่ไปทับเส้นดำหนาๆ
        denom = max(10.0, ring_mean)
        score = (ring_mean - inner_mean) / denom
        if score < 0: score = 0.0
        if score > 1: score = 1.0
        return score
    results={}
    for gi,group in enumerate(positions):
        if group is None: continue
        xs,ys=group; rpg=len(ys)
        for row,y in enumerate(ys):
            q_no=gi*rpg+row+1
            results[q_no]=[round(ratio_at(y,x),4) for x in xs]
    return results

def _compute_baselines(raw_scores, n_q):
    """column baseline per group = 20th percentile ratio ของแต่ละ choice"""
    n_groups = 4 if n_q > 50 else 2
    rpg = n_q // n_groups
    baselines = {}
    for gi in range(n_groups):
        qs = {q: raw_scores[q] for q in raw_scores if gi*rpg+1<=q<=(gi+1)*rpg}
        if not qs:
            for q in range(gi*rpg+1,(gi+1)*rpg+1): baselines[q]=[0.0]*5
            continue
        cv = {i:[] for i in range(5)}
        for r in qs.values():
            for i,v in enumerate(r): cv[i].append(v)
        bl = [float(np.percentile(cv[i],20)) if cv[i] else 0 for i in range(5)]
        for q in qs: baselines[q] = bl
    return baselines

def _compute_decision_stats(raw_scores, n_q=None):
    """
    คืนค่าสถิติที่ใช้ตัดสิน:
    - baselines per question
    - norms_by_q: normalized score (ratio - baseline) ต่อ choice
    - dynamic_fill_min: threshold สำหรับถือว่า "ฝน"
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
        p95 = float(np.percentile(mx, 95))
        p10 = float(np.percentile(mx, 10))
        p05 = float(np.percentile(mx, 5))
        p01 = float(np.percentile(mx, 1))
        mn  = float(np.min(mx))
        # ถ้าส่วนใหญ่เป็นค่าเล็ก (เช่น กระดาษเปล่าเกือบทั้งหมด) ให้ยก threshold ขึ้นตาม tail
        if p90 < 0.20:
            dynamic_fill_min = max(dynamic_fill_min, p95 + 0.02)
        else:
            # ถ้าคะแนนต่ำสุดยังสูง (ฝนเกือบทั้งหมด/ฝนครบ) distribution จะเป็นก้อนเดียวด้านบน
            # Otsu จะให้ threshold สูงผิด → ใช้ percentile ต่ำแทนเพื่อไม่ทำให้ตัด not_filled
            if p10 > 0.35:
                # ใช้ percentile ต่ำมากเพื่อครอบเคส "ฝนเบาสุด" 1-2 ข้อ
                # และเผื่อ margin เล็กน้อยกันความแกว่ง
                low_ref = mn
                dynamic_fill_min = max(dynamic_fill_min, max(0.0, low_ref - 0.01))
            else:
                # ใช้ Otsu บน max_norm เพื่อหาเส้นแบ่ง low/high อัตโนมัติ
                mx_u8 = (mx * 255.0).astype(np.uint8).reshape(-1, 1)
                try:
                    thr_u8, _ = cv2.threshold(mx_u8, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
                    dynamic_fill_min = max(dynamic_fill_min, float(thr_u8) / 255.0)
                except Exception:
                    pass

    return bls, norms_by_q, float(dynamic_fill_min)

def decide_answers(raw_scores, n_q=None):
    """ตัดสินด้วย normalized score (ratio - baseline) แก้ปัญหาตัวอักษรใน bubble"""
    choices=OMRConfig.CHOICES; answers={}; flagged=[]
    bls, norms_by_q, dynamic_fill_min = _compute_decision_stats(raw_scores, n_q=n_q)
    for q_no,ratios in sorted(raw_scores.items()):
        if not ratios: answers[q_no]=None; continue
        norm = norms_by_q.get(q_no)
        if norm is None:
            bl=bls.get(q_no,[0]*5)
            norm=[r-bl[i] for i,r in enumerate(ratios)]
        sr=sorted(enumerate(norm),key=lambda x:x[1],reverse=True)
        max_idx,max_n=sr[0]; gap=max_n-sr[1][1] if len(sr)>1 else 1.0
        if max_n<dynamic_fill_min:
            flagged.append({"question":q_no,"reason":"not_filled","ratios":dict(zip(choices,ratios))})
            answers[q_no]=None
        elif gap<OMRConfig.NORM_GAP_MIN:
            flagged.append({"question":q_no,"reason":"low_confidence","ratios":dict(zip(choices,ratios))})
            answers[q_no]=choices[max_idx]
        else:
            answers[q_no]=choices[max_idx]
    return answers,flagged

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
        (i1, s1) = sr[0]
        (i2, s2) = sr[1] if len(sr) > 1 else (None, 0.0)
        gap = float(s1 - s2) if i2 is not None else 1.0

        if s1 < fill_min:
            blank += 1
            continue

        filled += 1

        # suspicious rules
        if gap < OMRConfig.NORM_GAP_MIN:
            suspicious.append({
                "question": q_no,
                "reason": "low_confidence",
                "top": choices[i1],
                "gap": round(gap, 4),
                "score": round(float(s1), 4),
            })
            continue
        if s1 < fill_min + 0.03:
            suspicious.append({
                "question": q_no,
                "reason": "weak_fill",
                "top": choices[i1],
                "score": round(float(s1), 4),
            })
            continue
        if s2 >= fill_min * 0.85:
            suspicious.append({
                "question": q_no,
                "reason": "possible_multi",
                "top": choices[i1],
                "second": choices[i2] if i2 is not None else None,
                "gap": round(gap, 4),
                "score": round(float(s1), 4),
            })
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
    grid_img = warped[gy:gy+gh, gx:gx+gw]
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
            for x in xs:
                y1, y2 = max(0, y - pad), min(g.shape[0], y + pad)
                x1, x2 = max(0, x - pad), min(g.shape[1], x + pad)
                patch = g[y1:y2, x1:x2]
                if patch.size == 0:
                    continue

                # หา circle ใน patch รอบๆ center; ตั้ง param2 ต่ำเพื่อให้ detect ได้ง่าย
                circles = cv2.HoughCircles(
                    patch, cv2.HOUGH_GRADIENT,
                    dp=1.2, minDist=R,
                    param1=80, param2=18,
                    minRadius=minR, maxRadius=maxR
                )
                if circles is None:
                    continue
                cs = np.round(circles[0]).astype(int)
                cx0, cy0 = (x - x1), (y - y1)
                # เลือกวงที่ใกล้จุดคาดที่สุด
                best = None
                best_d2 = 1e18
                for (cx, cy, rr) in cs:
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
                rows_report.append({
                    "group": int(gi),
                    "row": int(row_idx + 1),
                    "mean_dist_px": float(np.mean(dists)),
                    "max_dist_px": float(np.max(dists)),
                    "found": int(found),
                    "expected": int(len(xs)),
                })
            else:
                rows_report.append({
                    "group": int(gi),
                    "row": int(row_idx + 1),
                    "mean_dist_px": None,
                    "max_dist_px": None,
                    "found": 0,
                    "expected": int(len(xs)),
                })
    return rows_report

def scan_answer_sheet(image_input,force_questions=0,debug=False):
    result=OMRResult()
    try:
        img,gray,thresh=load_and_preprocess(image_input)
        print(f"[1] Image: {img.shape[1]}x{img.shape[0]}")
        anchors=find_anchor_points(thresh)
        if anchors is None: result.error_msg="ไม่พบ anchor 4 มุม"; return result
        print("[2] Anchors: OK")
        warped=warp_perspective(img,anchors)
        warped_gray=cv2.cvtColor(warped,cv2.COLOR_BGR2GRAY)
        print(f"[3] Warp: {warped.shape[1]}x{warped.shape[0]}")
        meta=decode_qr(warped)
        total_q=meta.total_questions if meta.total_questions>0 else force_questions
        if total_q==0:
            # QR ไม่ได้ → detect จาก bubble grid
            grid_rect_tmp=detect_grid_region(warped_gray,0)
            total_q=auto_detect_questions(warped_gray,grid_rect_tmp)
            print(f"[4] QR decode ไม่ได้ → auto-detect: {total_q} ข้อ")
        else:
            print(f"[4] QR: subject='{meta.subject_code}' tq={total_q}")
        meta.total_questions=total_q; result.metadata=meta
        grid_rect=detect_grid_region(warped_gray,total_q)
        print(f"[5] Grid: {grid_rect}")
        positions=get_bubble_positions(warped,grid_rect,total_q)
        print(f"[6] Positions: {sum(1 for p in positions if p)} groups OK")
        raw_scores=measure_bubble_ratios(warped,grid_rect,positions)
        result.raw_scores=raw_scores
        print(f"[7] Measured: {len(raw_scores)} questions")
        answers,flagged=decide_answers(raw_scores, n_q=total_q)
        result.answers=answers; result.flagged=flagged
        print(f"[8] Answers: {len(answers)} ข้อ, flagged: {len(flagged)}")
        if debug: _save_debug(warped,grid_rect,positions,answers,flagged,image_input)
        result.success=True
    except Exception as e:
        result.error_msg=str(e); import traceback; traceback.print_exc()
    return result

def calculate_score(answers,answer_key):
    correct,wrong,skipped=[],[],[]
    for q_no,key in answer_key.items():
        a=answers.get(q_no)
        if a is None: skipped.append(q_no)
        elif a==key: correct.append(q_no)
        else: wrong.append({"question":q_no,"student":a,"correct":key})
    total=len(answer_key)
    return {"score":len(correct),"total":total,"percent":round(len(correct)/total*100,1) if total else 0,
            "correct":correct,"wrong":wrong,"skipped":skipped}

def _save_debug(warped,grid_rect,positions,answers,flagged,orig_path):
    debug=warped.copy(); gx,gy,gw,gh=grid_rect
    cv2.rectangle(debug,(gx,gy),(gx+gw,gy+gh),(0,255,0),2)
    flagged_qs={f["question"] for f in flagged}; choices=OMRConfig.CHOICES; R=OMRConfig.BUBBLE_RADIUS
    dbg_r = max(3, R + int(getattr(OMRConfig, "DEBUG_CIRCLE_RADIUS_OFFSET", -3)))
    # เพื่อให้วง debug ตรง bubble จริง: ใช้ same snapping logic กับ measure_bubble_ratios
    gx0, gy0, gw0, gh0 = grid_rect
    grid_img = warped[gy0:gy0+gh0, gx0:gx0+gw0]
    grid_gray = cv2.cvtColor(grid_img, cv2.COLOR_BGR2GRAY)
    g = cv2.GaussianBlur(cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8)).apply(grid_gray), (3, 3), 0)

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
            patch, cv2.HOUGH_GRADIENT,
            dp=1.2, minDist=int(OMRConfig.BUBBLE_RADIUS),
            param1=80, param2=int(getattr(OMRConfig, "SNAP_PARAM2", 18)),
            minRadius=minR, maxRadius=maxR
        )
        if circles is None:
            return y, x
        cs = np.round(circles[0]).astype(int)
        cx0, cy0 = (x - x1), (y - y1)
        best = min(cs, key=lambda c: (c[0]-cx0)**2 + (c[1]-cy0)**2)
        return int(y1 + best[1]), int(x1 + best[0])
    for gi,group in enumerate(positions):
        if not group: continue
        xs,ys=group; rpg=len(ys)
        for row,y in enumerate(ys):
            q_no=gi*rpg+row+1; ans=answers.get(q_no)
            if ans and ans in choices:
                ch=choices.index(ans); cx=gx+xs[ch]; cy=gy+y
                # snap ในพิกัด grid แล้วแปลงกลับเป็น warped
                sy, sx = _snap(int(y), int(xs[ch]))
                cx = gx + int(sx)
                cy = gy + int(sy)
                color=(0,165,255) if q_no in flagged_qs else (0,255,0)
                cv2.circle(debug,(cx,cy),dbg_r,color,2)
                cv2.putText(debug,ans,(cx-5,cy+5),cv2.FONT_HERSHEY_SIMPLEX,.4,color,1)
    if isinstance(orig_path, str):
        out=os.path.splitext(orig_path)[0]+"_debug.jpg"
    else:
        out="api_debug.jpg"
    cv2.imwrite(out,debug); print(f"[DEBUG] {out}")

if __name__=="__main__":
    paths=sys.argv[1:] if len(sys.argv)>1 else []
    if not paths: 
        print(json.dumps({"error": "Usage: python3 omr_scanner.py <image> [--json] [--force-q 50]"}, ensure_ascii=False))
        sys.exit(0)
        
    force_q=0; clean=[]; output_json = False; analyze_drift = False
    i=0
    while i<len(paths):
        if paths[i]=="--force-q" and i+1<len(paths): force_q=int(paths[i+1]); i+=2
        elif paths[i]=="--json": output_json=True; i+=1
        elif paths[i]=="--analyze-drift": analyze_drift=True; i+=1
        else: clean.append(paths[i]); i+=1
        
    # ปิด print ชั่วคราวถ้าต้องการ output เป็น json (ใช้ stdout redirect)
    import sys, io
    original_stdout = sys.stdout
    if output_json:
        sys.stdout = io.StringIO()
        
    results_list = []
        
    for path in clean:
        if not output_json:
            print(f"\n{'='*55}\nสแกน: {path}\n{'='*55}")
            
        r=scan_answer_sheet(path,force_questions=force_q,debug=not output_json)
        
        # จัดรูปแบบข้อมูลเป็น JSON / Dict
        sheet_result = {
            "file_path": path,
            "success": r.success,
            "error_msg": r.error_msg
        }
        
        if r.success:
            m=r.metadata
            sheet_result["student"] = {
                "subject_code": m.subject_code,
                "subject_name": m.subject_name,
                "student_id": m.student_id,
                "student_name": m.student_name,
                "total_questions": m.total_questions,
                "exam_date": m.exam_date
                ,"sheet_id": m.sheet_id
            }
            sheet_result["answers"] = r.answers
            sheet_result["flagged"] = r.flagged
            
            if m.total_questions and r.raw_scores:
                sm = summarize_marks(r.raw_scores, m.total_questions)
                sheet_result["summary"] = sm
                
            if not output_json:
                print(f"\nวิชา: {m.subject_code} {m.subject_name}\nนักเรียน: {m.student_id} {m.student_name}\nจำนวนข้อ: {m.total_questions}")
                print("\nคำตอบ:")
                for q in sorted(r.answers): 
                    ans=r.answers[q] or "?"
                    flag=" ⚠" if any(f["question"]==q for f in r.flagged) else ""
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
