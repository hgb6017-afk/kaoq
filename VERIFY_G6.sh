#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

VERSION='0.6.1-audit-fixed'

echo "[G6.1] Verifying project structure..."
for f in Makefile control Tweak.xm SmartDialSIM.plist Runtime/SDSDiagnosticReporter.h Runtime/SDSDiagnosticReporter.m DialerIntegration/SDSAdaptivePhoneIntegration.m; do
  [[ -f "$f" ]] || { echo "FAIL: missing $f" >&2; exit 1; }
done
grep -q 'THEOS_PACKAGE_SCHEME = roothide' Makefile
grep -q 'TARGET = iphone:clang:latest:15.0' Makefile
grep -q 'ARCHS = arm64 arm64e' Makefile
grep -q 'DEBUG ?= 0' Makefile
grep -q 'com.apple.mobilephone' SmartDialSIM.plist
grep -q "Version: ${VERSION}" control
grep -q 'preferenceloader' control
grep -q 'SDSAdaptivePhoneIntegration' Tweak.xm
if grep -q 'REQUIRES_DEVICE_VERIFICATION.invalid' SmartDialSIM.plist; then
  echo 'FAIL: inert filter marker still present' >&2; exit 1
fi

echo "[G6.1] Checking RootHide/privacy safety..."
if grep -R --line-number --include='*.m' --include='*.h' --include='*.xm' --include='Makefile' --include='control' --include='*.plist' '/var/jb' .; then
  echo "FAIL: hard-coded /var/jb found" >&2; exit 1
fi
if grep -R --line-number 'UIPasteboard' DialerIntegration SIMCustomization Services Search Runtime Utilities Tweak.xm 2>/dev/null; then
  echo "FAIL: runtime tweak core must not modify/read the user pasteboard" >&2; exit 1
fi
# Preference UI may use UIPasteboard only for the explicit 'Copy diagnostic report' button.
grep -q 'UIPasteboard.generalPasteboard.string = report' Preferences/SDSPRootListController.m

echo "[G6.1] Parsing XML plist files..."
python3 - <<'PY'
import plistlib
from pathlib import Path
for p in [Path('Preferences/Resources/Root.plist'), Path('Preferences/Resources/Info.plist')]:
    with p.open('rb') as f: plistlib.load(f)
print('plist parse: PASS')
PY

echo "[G6.1] Checking local quoted imports..."
python3 - <<'PY'
from pathlib import Path
import re
missing=[]
for p in list(Path('.').rglob('*.m'))+list(Path('.').rglob('*.h'))+list(Path('.').rglob('*.xm')):
    s=p.read_text(errors='ignore')
    for inc in re.findall(r'#(?:import|include)\s+"([^"]+)"', s):
        if not ((p.parent/inc).exists() or Path(inc).exists()): missing.append((str(p),inc))
if missing:
    raise SystemExit('missing local imports: '+repr(missing))
print('quoted imports: PASS')
PY

echo "[G6.1] Checking Frida JS syntax..."
if command -v node >/dev/null 2>&1; then
  for f in Scripts/*.js; do node --check "$f" >/dev/null; done
  echo "Frida JS syntax: PASS"
else
  echo "node unavailable: skipped JS syntax check"
fi

echo "[G6.1] Checking source invariants..."
grep -q 'fetchRecentCallsSyncWithCoalescing:' Services/SDSCallHistoryService.m
grep -q 'SDSCHSignatureMatches' Services/SDSCallHistoryService.m
grep -q 'UIKeyInput' DialerIntegration/SDSDialerNumberSetter.m
grep -q 'SDSCurrentDialLength' DialerIntegration/SDSDialerNumberSetter.m
grep -q 'sendActionsForControlEvents' DialerIntegration/SDSDialerNumberSetter.m
grep -q 'actions.count == 2' SIMCustomization/SDSSIMSelectorBridge.m
grep -q 'ADAPTIVE_PRESENTATION_ONLY' SIMCustomization/SDSSIMSelectorBridge.m
grep -q 'indexDidChangeHandler' Services/SDSDataIndexCoordinator.m
grep -q 'bestScore < 40' DialerIntegration/SDSAdaptivePhoneIntegration.m
! grep -R --line-number -E 'responder paste|paste last' README.md STATUS.md RUNTIME_MATRIX.md ONE_TEST.md 2>/dev/null

echo "[G6.1] Brace sanity..."
python3 - <<'PY'
from pathlib import Path
files=list(Path('.').rglob('*.m'))+list(Path('.').rglob('*.h'))+list(Path('.').rglob('*.xm'))
for p in files:
    s=p.read_text(errors='ignore')
    if s.count('{') != s.count('}'):
        raise SystemExit(f'brace mismatch: {p}')
print(f'brace sanity: PASS ({len(files)} files)')
PY

echo "[G6.1] PASS (static/project checks). Actual iOS compile is performed by GitHub Actions/Theos."
