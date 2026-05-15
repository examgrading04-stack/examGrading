# -*- coding: utf-8 -*-
"""
diagnose_sheet.py
=================
วิเคราะห์กระดาษคำตอบ — รายงานปัญหาที่พบและแนะนำการแก้ไข
Usage:
    python diagnose_sheet.py 5.png
    python diagnose_sheet.py 5.png 6.png 7.png
"""
import cv2, numpy as np, sys, json, io
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')
from dataclasses import dataclass, field
from typing import Optional

# ── reuse ทุก function จาก omr_scanner ──
from .omr_scanner import (
    load_and_preprocess, find_anchor_points, warp_perspective,
    decode_qr, detect_grid_region, get_bubble_positions,
    measure_bubble_ratios, decide_answers, OMRConfig,
    summarize_marks, analyze_bubble_drift
)

YELLOW  = (0, 200, 255)
RED     = (0, 0, 255)
GREEN   = (0, 220, 0)
BLUE    = (255, 100, 0)
MAGENTA = (255, 0, 200)
WHITE   = (255, 255, 255)
BLACK   = (0, 0, 0)

@dataclass
class DiagReport:
    path: str
    issues: list = field(default_factory=list)
    warnings: list = field(default_factory=list)
    info: list = field(default_factory=list)
    anchor_ok: bool = False
    qr_ok: bool = False
    qr_data: dict = field(default_factory=dict)
    grid_rect: Optional[tuple] = None
    n_bubbles_detected: int = 0
    n_questions: int = 0
    answers: dict = field(default_factory=dict)
    flagged: list = field(default_factory=list)
    raw_scores: dict = field(default_factory=dict)

# ────────────────────────────────────────────
def diag_anchors(thresh, report: DiagReport, debug_img):
    """
    ใช้ logic เดียวกับ omr_scanner (อิงสัดส่วนพื้นที่ภาพ) เพื่อให้ผลเหมือนกัน
    คืน anchor list [TL,TR,BL,BR] หรือ None
    """
    anchors = find_anchor_points(thresh)
    if anchors is None:
        report.anchor_ok = False
        report.issues.append("❌ ไม่พบ anchor 4 มุม (ตามเกณฑ์แบบอิงสัดส่วนภาพ)")
        return None

    report.anchor_ok = True
    report.info.append("✅ Anchor 4 มุม: พบครบ")
    # วาดจุด anchor บนภาพเดิม
    labels = ["TL", "TR", "BL", "BR"]
    for (x, y), lbl in zip(anchors, labels):
        cv2.circle(debug_img, (int(x), int(y)), 10, GREEN, 3)
        cv2.putText(debug_img, lbl, (int(x) + 8, int(y) - 8),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.7, GREEN, 2)
    return anchors


def diag_qr(warped, report: DiagReport, debug_img):
    # ใช้ multi-strategy เดียวกับ omr_scanner
    meta = decode_qr(warped)
    report.qr_data = {
        "sc": meta.subject_code,
        "sn": meta.subject_name,
        "id": meta.student_id,
        "nm": meta.student_name,
        "dt": meta.exam_date,
        "tq": meta.total_questions,
    }
    if meta.subject_code or meta.total_questions:
        report.qr_ok = True
        report.info.append(f"✅ QR decode สำเร็จ: tq={report.qr_data.get('tq','?')} sc={report.qr_data.get('sc','?')}")
    else:
        report.qr_ok = False
        report.issues.append("❌ QR decode ไม่ได้ — ตรวจสอบขนาด QR และ quiet zone รอบ QR")


def diag_grid(warped, warped_gray, n_q, report: DiagReport, debug_img):
    grid_rect = detect_grid_region(warped_gray, n_q)
    gx, gy, gw, gh = grid_rect
    cv2.rectangle(debug_img, (gx, gy), (gx+gw, gy+gh), BLUE, 3)
    cv2.putText(debug_img, f"Grid({gw}x{gh})", (gx, gy-10),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, BLUE, 2)

    H, W = warped.shape[:2]
    grid_ratio = (gw * gh) / (H * W)
    report.info.append(f"✅ Grid region: x={gx} y={gy} w={gw} h={gh}")
    report.info.append(f"   Grid ครอบคลุม {grid_ratio*100:.1f}% ของภาพ")

    if grid_ratio < 0.20:
        report.warnings.append("⚠️ พื้นที่ Grid เล็กกว่าที่คาด — อาจ detect bubble ได้ไม่ครบ")
    if grid_ratio > 0.65:
        report.warnings.append("⚠️ Grid ใหญ่มาก — อาจรวม QR หรือ field text เข้าไปด้วย")

    report.grid_rect = grid_rect
    return grid_rect


def diag_bubbles(warped, grid_rect, n_q, report: DiagReport, debug_img):
    try:
        positions = get_bubble_positions(warped, grid_rect, n_q)
    except Exception as e:
        report.issues.append(f"❌ get_bubble_positions error: {e}")
        return None

    gx, gy = grid_rect[0], grid_rect[1]
    total_bubbles = 0
    detected_bubbles = 0

    for gi, group in enumerate(positions):
        if group is None:
            report.issues.append(f"❌ Group {gi}: detect bubble ไม่ได้ — bubble อาจเล็กเกินไปหรือ contrast ต่ำ")
            continue
        xs, ys = group
        rpg = len(ys)
        expected = rpg * 5
        total_bubbles += expected

        # วาด detected positions
        # วาดตำแหน่งที่จะวัด (หลัง snapping ใน measure_bubble_ratios จะขยับได้เล็กน้อย)
        for row, y in enumerate(ys):
            for ch, x in enumerate(xs):
                cx, cy = gx + x, gy + y
                cv2.circle(debug_img, (cx, cy), max(3, OMRConfig.BUBBLE_RADIUS - 2), BLUE, 1)
                detected_bubbles += 1

        report.info.append(f"   Group {gi}: {len(xs)} cols × {rpg} rows = {len(xs)*rpg} bubbles")

        # ตรวจ column count
        if len(xs) != 5:
            report.warnings.append(f"⚠️ Group {gi}: พบ {len(xs)} columns แทน 5 — K-means อาจ cluster ผิด")

    report.n_bubbles_detected = detected_bubbles
    expected_total = n_q * 5

    if detected_bubbles < expected_total * 0.8:
        report.issues.append(
            f"❌ Detect ได้ {detected_bubbles}/{expected_total} bubbles ({detected_bubbles/expected_total*100:.0f}%) "
            f"— bubble เล็กเกิน หรือ contrast ต่ำ")
    elif detected_bubbles < expected_total * 0.95:
        report.warnings.append(
            f"⚠️ Detect ได้ {detected_bubbles}/{expected_total} bubbles "
            f"({detected_bubbles/expected_total*100:.0f}%) — บางข้ออาจหาย")
    else:
        report.info.append(f"✅ Detect bubbles: {detected_bubbles}/{expected_total}")

    return positions


def diag_fill_quality(raw_scores, report: DiagReport, debug_img, warped, grid_rect, positions):
    if not raw_scores:
        return
    # raw_scores ในเวอร์ชันใหม่คือ score~0..1 (ยิ่งมากยิ่งมืด)
    all_scores = [r for ratios in raw_scores.values() for r in ratios]
    report.info.append("✅ Bubble score stats (0..1, ยิ่งมาก=ยิ่งมืด):")
    report.info.append(f"   min={min(all_scores):.3f}  max={max(all_scores):.3f}  mean={np.mean(all_scores):.3f}")

    # สรุปจำนวนข้อที่ "ฝน/ไม่ฝน/น่าสงสัย" แบบเดียวกับ omr_scanner
    try:
        n_q = report.n_questions or len(raw_scores)
        sm = summarize_marks(raw_scores, n_q)
        report.info.append(f"✅ Summary marks: filled≈{sm['filled_count']}/{n_q} blank={sm['blank_count']}/{n_q} thr={sm['fill_threshold']}")
        if sm["suspicious"]:
            report.warnings.append(f"⚠️ suspicious {len(sm['suspicious'])} ข้อ (เช่น {', '.join('Q'+str(x['question']) for x in sm['suspicious'][:10])})")
    except Exception as e:
        report.warnings.append(f"⚠️ summarize_marks error: {e}")

    # วาด fill heatmap บน debug
    gx, gy = grid_rect[0], grid_rect[1]
    if positions:
        for gi, group in enumerate(positions):
            if not group:
                continue
            xs, ys = group
            rpg = len(ys)
            for row, y in enumerate(ys):
                q_no = gi * rpg + row + 1
                if q_no not in raw_scores:
                    continue
                ratios = raw_scores[q_no]
                for ch, (x, ratio) in enumerate(zip(xs, ratios)):
                    cx, cy = gx + x, gy + y
                    # ratio คือ score 0..1
                    intensity = int(min(max(ratio, 0.0), 1.0) * 255)
                    color = (0, intensity, 255 - intensity)
                    cv2.circle(debug_img, (cx, cy), OMRConfig.BUBBLE_RADIUS - 2, color, -1)


def diag_answers(raw_scores, answers, flagged, n_q, report: DiagReport):
    report.answers = answers
    report.flagged = flagged

    answered  = sum(1 for v in answers.values() if v is not None)
    not_filled = [f for f in flagged if f["reason"] == "not_filled"]
    low_conf   = [f for f in flagged if f["reason"] == "low_confidence"]

    report.info.append(f"✅ ผลตรวจ: {answered}/{n_q} ข้อมีคำตอบ")
    if not_filled:
        report.warnings.append(f"⚠️ ไม่ระบาย {len(not_filled)} ข้อ: {[f['question'] for f in not_filled]}")
    if low_conf:
        report.warnings.append(f"⚠️ low confidence {len(low_conf)} ข้อ: {[f['question'] for f in low_conf]}")
    if len(flagged) == 0:
        report.info.append("✅ ไม่มี flagged — detect คำตอบครบสมบูรณ์")


def add_legend(img):
    H, W = img.shape[:2]
    legends = [
        (GREEN,   "Anchor / QR OK"),
        (BLUE,    "Grid / Bubble position"),
        (YELLOW,  "Anchor candidate"),
        (RED,     "Error"),
        (MAGENTA, "Flagged"),
    ]
    x0, y0 = 10, H - 20 - len(legends)*28
    for i, (color, text) in enumerate(legends):
        y = y0 + i * 28
        cv2.rectangle(img, (x0, y-12), (x0+20, y+8), color, -1)
        cv2.putText(img, text, (x0+28, y+4), cv2.FONT_HERSHEY_SIMPLEX, 0.55, WHITE, 2)
        cv2.putText(img, text, (x0+28, y+4), cv2.FONT_HERSHEY_SIMPLEX, 0.55, BLACK, 1)


def draw_answers_overlay(debug_img, answers, flagged, positions, grid_rect):
    gx, gy = grid_rect[0], grid_rect[1]
    flagged_qs = {f["question"] for f in flagged}
    choices = OMRConfig.CHOICES
    R = OMRConfig.BUBBLE_RADIUS
    dbg_r = max(3, R + int(getattr(OMRConfig, "DEBUG_CIRCLE_RADIUS_OFFSET", -3)))

    for gi, group in enumerate(positions or []):
        if not group:
            continue
        xs, ys = group
        rpg = len(ys)
        for row, y in enumerate(ys):
            q_no = gi * rpg + row + 1
            ans = answers.get(q_no)
            if ans and ans in choices:
                ch = choices.index(ans)
                cx, cy = gx + xs[ch], gy + y
                color = MAGENTA if q_no in flagged_qs else GREEN
                cv2.circle(debug_img, (cx, cy), dbg_r, color, 3)
                cv2.putText(debug_img, ans, (cx - 6, cy + 5),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.5, color, 2)


# ────────────────────────────────────────────
def diagnose(image_path: str, force_q: int = 0):
    report = DiagReport(path=image_path)
    print(f"\n{'='*60}")
    print(f"🔍 วิเคราะห์: {image_path}")
    print('='*60)

    # โหลดภาพ
    try:
        img, gray, thresh = load_and_preprocess(image_path)
    except Exception as e:
        print(f"❌ โหลดภาพไม่ได้: {e}")
        return report

    H_orig, W_orig = img.shape[:2]
    report.info.append(f"📐 ขนาดภาพ: {W_orig}×{H_orig} px")

    if W_orig < 800 or H_orig < 800:
        report.warnings.append(f"⚠️ ภาพเล็กเกิน ({W_orig}×{H_orig}) — ควร ≥ 1000×1300 px")

    # ── Step 1: Anchor ──
    debug_orig = img.copy()
    anchors = diag_anchors(thresh, report, debug_orig)

    if not report.anchor_ok:
        # วาด debug แล้ว return
        add_legend(debug_orig)
        _save_debug(debug_orig, [], report, image_path, "no_anchor")
        _print_report(report)
        return report

    # ── Warp ──
    warped = warp_perspective(img, anchors)
    warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
    debug_img = warped.copy()

    # ── Step 2: QR ──
    diag_qr(warped, report, debug_img)
    n_q = int(report.qr_data.get("tq", force_q or 30))
    report.n_questions = n_q
    report.info.append(f"📋 จำนวนข้อ: {n_q}")

    # ── Step 3: Grid ──
    grid_rect = diag_grid(warped, warped_gray, n_q, report, debug_img)

    # ── Step 4: Bubbles ──
    positions = diag_bubbles(warped, grid_rect, n_q, report, debug_img)

    if positions is None:
        _save_debug(debug_img, [], report, image_path, "no_bubbles")
        _print_report(report)
        return report

    # ── Step 5: Fill quality ──
    raw_scores = measure_bubble_ratios(warped, grid_rect, positions)
    report.raw_scores = raw_scores
    diag_fill_quality(raw_scores, report, debug_img, warped, grid_rect, positions)

    # ── Step 6: Answers ──
    answers, flagged = decide_answers(raw_scores, n_q=n_q)
    diag_answers(raw_scores, answers, flagged, n_q, report)
    draw_answers_overlay(debug_img, answers, flagged, positions, grid_rect)

    add_legend(debug_img)
    _save_debug(debug_img, positions, report, image_path, "full")
    _print_report(report)
    _print_answers_table(answers, flagged)

    return report


def _save_debug(debug_img, positions, report, orig_path, suffix):
    out = os.path.splitext(orig_path)[0] + f"_diag_{suffix}.jpg"
    cv2.imwrite(out, debug_img)
    print(f"\n💾 Debug image: {out}")


def _print_report(report: DiagReport):
    print("\n── ผลการวิเคราะห์ ──")
    for item in report.info:
        print(f"  {item}")
    print()
    for w in report.warnings:
        print(f"  {w}")
    print()
    for e in report.issues:
        print(f"  {e}")


def _print_answers_table(answers, flagged):
    if not answers:
        return
    flagged_qs = {f["question"]: f["reason"] for f in flagged}
    print("\n── คำตอบที่ detect ได้ ──")
    cols = 10
    qs = sorted(answers.keys())
    for i in range(0, len(qs), cols):
        row_qs = qs[i:i+cols]
        header = "  ".join(f"Q{q:3d}" for q in row_qs)
        ans_row = "  ".join(
            f"{'??' if answers[q] is None else answers[q]:>4}"
            + ("⚠" if q in flagged_qs else " ")
            for q in row_qs
        )
        print(f"  {header}")
        print(f"  {ans_row}")
        print()


# ────────────────────────────────────────────
def print_design_recommendations():
    lines = [
        "" ,
        "=" * 62,
        "  [DESIGN RECOMMENDATIONS] ข้อแนะนำปรับปรุงกระดาษคำตอบ",
        "=" * 62,
        "",
        "[1] BUBBLE — เอาตัวอักษร A B C D E ออกจากใน bubble",
        "    - ตัวอักษรทำให้ unfilled bubble มี fill-ratio สูงผิดปกติ",
        "    - วางตัวอักษรไว้ด้านบน header แถวแทน เช่น:",
        "        A  B  C  D  E",
        "        O  O  O  O  O",
        "",
        "[2] BUBBLE SIZE — เพิ่มขนาด bubble",
        "    - แนะนำ radius >= 18-20px (warp 900x1200) เพื่อทน blur/angle",
        "    - 100 ข้อ: ระวังแน่นเกิน — เพิ่ม row/col gap",
        "",
        "[3] ANCHOR SQUARES — ตรวจสอบขนาด",
        "    - แนะนำ 15x15mm บนกระดาษ A4 จริง",
        "    - ต้องเป็นสี่เหลี่ยมจัตุรัสสมบูรณ์ ไม่มีตัวอักษรข้างใน",
        "",
        "[4] QR CODE — เพิ่มขนาด QR",
        "    - แนะนำ >= 35x35mm บนกระดาษจริง",
        "    - quiet zone (ขอบขาว) รอบ QR >= 4 module",
        "    - Error correction level M แทน L (ทนรอยเปื้อนกว่า)",
        "",
        "[5] GRID BORDER — ปรับเส้นขอบกล่อง bubble",
        "    - เส้นหนาอาจถูก detect ว่าเป็น anchor",
        "    - ใช้เส้นบาง (1px) หรือเพิ่ม margin ห่างจาก anchor",
        "",
        "[6] COLUMN SEPARATOR — เพิ่มเส้นกั้นระหว่างกลุ่มข้อ",
        "    - ช่วย K-means cluster column ได้แม่นยำขึ้น",
        "",
        "[7] 100 ข้อ — กระดาษแน่นมาก",
        "    - ถ่ายมือถือมีโอกาส bubble overlap สูง",
        "    - แนะนำพิมพ์ A3 หรือเพิ่ม inter-row gap 2-3px",
        "",
        "=" * 62,
    ]
    for line in lines:
        print(line)


def main() -> None:
    paths = sys.argv[1:] if len(sys.argv) > 1 else []
    force_q = 0
    clean = []
    analyze_drift = False
    i = 0
    while i < len(paths):
        if paths[i] == "--force-q" and i + 1 < len(paths):
            force_q = int(paths[i+1]); i += 2
        elif paths[i] == "--analyze-drift":
            analyze_drift = True; i += 1
        else:
            clean.append(paths[i]); i += 1

    if not clean:
        print("Usage: python diagnose_sheet.py <image> [image2 ...] [--force-q 50] [--analyze-drift]")
        print("       python diagnose_sheet.py 5.png 6.png 7.png")
        sys.exit(0)

    print_design_recommendations()

    reports = []
    for path in clean:
        r = diagnose(path, force_q=force_q)
        if analyze_drift and r.anchor_ok and r.n_questions:
            try:
                img, gray, thresh = load_and_preprocess(path)
                anchors = find_anchor_points(thresh)
                if anchors is not None:
                    warped = warp_perspective(img, anchors)
                    warped_gray = cv2.cvtColor(warped, cv2.COLOR_BGR2GRAY)
                    grid_rect = detect_grid_region(warped_gray, r.n_questions)
                    positions = get_bubble_positions(warped, grid_rect, r.n_questions)
                    rep = analyze_bubble_drift(warped, grid_rect, positions)
                    ok = [x for x in rep if x["mean_dist_px"] is not None]
                    print("\n[DRIFT] วิเคราะห์ drift (px)")
                    if ok:
                        all_mean = float(np.mean([x["mean_dist_px"] for x in ok]))
                        all_max = float(np.max([x["max_dist_px"] for x in ok]))
                        print(f"  mean={all_mean:.2f}px  max={all_max:.2f}px")
                    ranked = sorted([x for x in rep if x["max_dist_px"] is not None],
                                    key=lambda x: x["max_dist_px"], reverse=True)
                    for it in ranked[:10]:
                        print(f"  group={it['group']} row={it['row']:>3}: mean={it['mean_dist_px']:.2f}px max={it['max_dist_px']:.2f}px found={it['found']}/{it['expected']}")
            except Exception as e:
                print(f"[DRIFT] error: {e}")
        reports.append(r)

    # Summary
    print(f"\n{'='*60}")
    print("📊 SUMMARY")
    print('='*60)
    for r in reports:
        status = "✅" if (r.anchor_ok and r.qr_ok and not r.issues) else "⚠️" if r.warnings else "❌"
        print(f"  {status} {r.path}: anchor={'OK' if r.anchor_ok else 'FAIL'} "
              f"qr={'OK' if r.qr_ok else 'FAIL'} "
              f"issues={len(r.issues)} warnings={len(r.warnings)}")


# ────────────────────────────────────────────
if __name__ == "__main__":
    main()
