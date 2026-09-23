#!/usr/bin/env python3
"""audit-consistency.py — does the committed evidence agree with the documents?

The test suite catches broken code. It cannot catch a report that claims 53 checks
while the committed manifest says 49, or a film SHA that four documents spell four
different ways. That class of defect has bitten this project twice, both times from a
careless bulk edit during cleanup rather than from anything wrong with the game:

  * TEST-REPORT sections 3-5 kept describing the coin-and-fork build after the level
    became a key-and-door build
  * an `rm` glob deleted the freshly generated 44-check receipt, and record-build.cjs
    -- which then picked "latest" by mtime -- fell back to a stale 40-check one

Both were found by a reader, not by a check. This script is the check.

    python3 scripts/audit-consistency.py        # exit 0 clean, 1 if anything disagrees

It compares what the documents SAY against what the artifacts ARE. It does not judge
whether the game is good, whether the narration is true, or whether the level is fun.
"""
import json, re, os, subprocess, hashlib, glob, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
REEL = "youtube/claude-liam-walker-jumpman-bao-x-walkthrough"
passed, failed = [], []
def ok(m):  passed.append(m)
def bad(m): failed.append(m)
def rd(p):
    try:    return open(p).read()
    except  Exception: return ""
def sha(p):
    h = hashlib.sha256()
    with open(p, "rb") as f:
        for c in iter(lambda: f.read(1 << 20), b""): h.update(c)
    return h.hexdigest()
def newest(prefix):
    """Newest receipt by the timestamp in its FILENAME. mtime is meaningless after a
    clone, which is exactly how the stale-manifest bug got in."""
    fs = glob.glob(f"evidence/{prefix}-*.json")
    return max(fs, key=lambda x: float(re.search(r"-(\d+\.?\d*)\.json", x).group(1))) if fs else None

man = json.load(open("evidence/build-manifest.json"))
lvl = json.load(open("godot/levels/first_steps.json"))
bs  = json.load(open(f"{REEL}/beat_sheet.json"))
cov = json.load(open(f"{REEL}/coverage.json"))
nar = " ".join(b["narration_text"] for b in bs["beats"])
tr, rm_, sm = rd("TEST-REPORT.md"), rd("README.md"), rd("SUBMISSION.md")
so, hr, fc  = rd("SOURCES.md"), rd(f"{REEL}/_qc/HUMAN-REVIEW.md"), rd(f"{REEL}/FACTCHECK.md")

# 1 — the check count, everywhere it appears
m1, m2 = re.search(r"\| Total \| \*\*(\d+)\*\*", tr), re.search(r"\*\*(\d+) automated checks", rm_)
vals = {"TEST-REPORT": int(m1.group(1)) if m1 else None, "manifest": man["machine_checks_passed"],
        "README": int(m2.group(1)) if m2 else None, "film": 53 if "fifty-three" in nar else None}
(ok if len(set(vals.values())) == 1 and None not in vals.values() else bad)(f"check count agrees: {vals}")

# 2 — film SHA in every document vs the actual bytes
mp4 = f"{REEL}/exports/landscape/claude-liam-walker-jumpman-bao-x-walkthrough.mp4"
if os.path.exists(mp4):
    real = sha(mp4)
    found = {n: (re.search(r"[0-9a-f]{64}", t).group(0) if re.search(r"[0-9a-f]{64}", t) else None)
             for n, t in [("README", rm_), ("SUBMISSION", sm), ("QC", hr)]}
    (ok if all(v == real for v in found.values()) else bad)(
        f"film sha256 agrees everywhere ({real[:12]})" + ("" if all(v == real for v in found.values()) else f" | {found}"))
    dur = float(subprocess.run(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",mp4],
                               capture_output=True, text=True).stdout.strip() or 0)
    # Absence is not disagreement. 219.8 s is 3:39 floored and 3:40 rounded and real
    # players disagree, so accept either; the exact seconds are the strict check.
    fl, rn = f"{int(dur//60)}:{int(dur%60):02d}", f"{int(round(dur)//60)}:{int(round(dur)%60):02d}"
    wrong = {n: [x for x in re.findall(r"\b\d:\d\d\b", t) if x not in (fl, rn)]
             for n, t in [("README", rm_), ("SOURCES", so), ("QC", hr), ("SUBMISSION", sm)]}
    wrong = {k: v for k, v in wrong.items() if v}
    (ok if not wrong else bad)(f"no mm:ss contradicts the real runtime ({fl}/{rn})" + (f" | {wrong}" if wrong else ""))
    (ok if f"{dur:.1f}" in rm_ and f"{dur:.1f}" in hr else bad)(f"exact runtime {dur:.1f}s is published")
else:
    bad("film master is missing")

# 3 — the film depicts the submitted game source
src = re.search(r"Game-source revision shown in the film: ([0-9a-f]{40})", sm)
if src:
    d = subprocess.run(["git","diff",src.group(1),"HEAD","--","godot/"], capture_output=True, text=True).stdout
    (ok if not d.strip() else bad)(f"film source {src.group(1)[:12]} == HEAD for godot/" + ("" if not d.strip() else f" | {len(d.splitlines())} lines differ"))
else:
    bad("SUBMISSION.md does not name the game-source revision")

# 4 — evidence integrity
(ok if cov["game"]["build_id"] == man["build_id"] else bad)("coverage build_id == manifest build_id")
cap = f"{REEL}/{cov['captures']['run-01']['path']}"
(ok if os.path.exists(cap) and sha(cap) == cov["captures"]["run-01"]["sha256"] else bad)("capture sha256 matches coverage")
stale = [f for f, h in man["source_sha256"].items() if not os.path.exists(f) or sha(f) != h]
(ok if not stale else bad)(f"{len(man['source_sha256'])} recorded source hashes still match" + (f" | stale: {stale[:3]}" if stale else ""))
sstale = [s["file"] for s in man["screenshots"] if not os.path.exists(s["file"]) or sha(s["file"]) != s["sha256"]]
(ok if not sstale else bad)(f"{len(man['screenshots'])} recorded screenshot hashes still match" + (f" | stale: {sstale[:3]}" if sstale else ""))

# 5 — the manifest cites the newest receipts, not whatever mtime happened to favour
for pre, key in (("mechanics", 0), ("keyboard", 1)):
    n = newest(pre)
    (ok if n and man["tests"][key]["file"] == n else bad)(f"manifest cites the newest {pre} receipt ({os.path.basename(n or '?')})")

# 6 — every check id the documents cite actually exists
real_ids = set()
for p in (newest("mechanics"), newest("keyboard")):
    if p: real_ids |= {r["id"] for r in json.load(open(p))["results"]}
allow = {"walker-jumpman","godot-waikthrough","run-01","first-steps-pick-a-line","claude-liam",
         "full-bleed","contrast-regions","key-and-door","there-and-back","audit-consistency"}
ghost = sorted(c for c in set(re.findall(r"`([a-z0-9]+(?:-[a-z0-9]+){2,})`", tr + rm_ + fc + hr))
               if c not in real_ids and c not in allow and not c.endswith((".gd",".md",".json",".cjs",".py")))
(ok if not ghost else bad)("every cited check id exists" + (f" | missing: {ghost}" if ghost else ""))

# 7 — every file path the documents cite exists
paths = set(re.findall(r"`((?:godot|evidence|scripts|youtube|film)/[A-Za-z0-9_./-]+)`", tr + rm_ + sm + so + fc + hr))
missing = sorted(p for p in paths if "*" not in p and not os.path.exists(p))
(ok if not missing else bad)(f"{len(paths)} cited paths exist" + (f" | missing: {missing}" if missing else ""))

# 8 — numeric claims in the narration vs the shipped level data
sol, az = lvl["solids"], lvl["rising_hazards"][0]["arm_zone"]
base = json.load(open("evidence/baseline/00-baseline-mechanics.json"))["results"]
claims = [("x nine hundred and sixty", sol[2][0] + sol[2][2] == 960),
          ("forty-eight pixels up",    320 - sol[7][1] == 48),
          ("two forty-four to two eighty-four", (az[1], az[1] + az[3]) == (244, 284)),
          ("twenty-five unaltered",    len(base) == 25)]
broken = [c for c, v in claims if c in nar and not v]
(ok if not broken else bad)("narration numbers match the level data" + (f" | wrong: {broken}" if broken else ""))

# 9 — coverage contract
bids = {b["beat_id"] for b in bs["beats"] if b["narration_text"].strip()}
orphan = sorted({e["beat_id"] for f in cov["features"] for e in f["evidence"]} - bids)
(ok if not orphan else bad)("every cited beat exists and has narration" + (f" | orphan: {orphan}" if orphan else ""))
noev = [f["id"] for f in cov["features"] if f["status"] == "implemented" and not f["evidence"]]
(ok if not noev else bad)("every implemented feature has evidence" + (f" | bare: {noev}" if noev else ""))

# 10 — playtest count, language, working tree
(ok if man["human_playtest_sessions"] == 2 and "two players" in tr.lower() else bad)(
    f"playtest count agrees (manifest {man['human_playtest_sessions']})")
tracked = subprocess.run(["git","ls-files"], capture_output=True, text=True).stdout.split()
cn = [f for f in tracked if os.path.exists(f) and re.search(r"[\u4e00-\u9fff]", rd(f))]
(ok if not cn else bad)("no CJK text in tracked deliverables" + (f" | {cn}" if cn else ""))
st = subprocess.run(["git","status","--short"], capture_output=True, text=True).stdout.strip()
(ok if not st else bad)("working tree clean" + (f" | {len(st.splitlines())} uncommitted" if st else ""))

print(f"\n{'='*70}\naudit-consistency: {len(passed)} / {len(passed)+len(failed)} passed\n{'='*70}")
for m in passed: print("  PASS ", m)
if failed:
    print()
    for m in failed: print("  FAIL ", m)
sys.exit(1 if failed else 0)
