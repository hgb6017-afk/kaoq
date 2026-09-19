# SmartDialSIM G6.1 Audit-Fixed Candidate

Target: Apple Phone (`com.apple.mobilephone`) on iOS 15.x and iOS 16.2 with RootHide, arm64/arm64e.

G6.1 is the corrected single-build candidate intended for **one real-device test**. It includes:

- Smart Dial suggestions on the native Phone keypad.
- Contacts source through Contacts.framework without requesting a surprise permission prompt.
- Call-history source through CallHistory.framework only when a compatible `CHManager` runtime boundary is present; otherwise Contacts-only Smart Dial continues.
- Vietnamese `0` / `+84` normalization and optional Vietnamese-name T9.
- Deduplication, ranking, debounce, stale-query cancellation, and automatic refresh after the first asynchronous index load.
- Tap suggestion → fill the native dialer using `UIKeyInput` when safely discoverable, otherwise verified visible keypad controls; no clipboard fallback and never auto-call.
- Compact SIM presentation only when the native control exposes a reliable two-line mapping; Apple's target/action and subscription logic are not replaced.
- Custom SIM 1 / SIM 2 aliases, live preferences, and an on-demand privacy-redacted diagnostic report in the same build.

## Safety model

The project intentionally avoids hard-coding guessed private keypad/SIM selectors. UIKit discovery is confidence-gated: if the keypad display, number-entry boundary, call-history provider, or SIM line mapping cannot be identified safely, that module leaves Phone's native behavior untouched.

CallHistory uses the system framework path only inside Phone and validates Objective-C method signatures before `objc_msgSend`. It never inserts, updates, or deletes call-history data.

## RootHide build

```make
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:15.0
THEOS_PACKAGE_SCHEME = roothide
```

The GitHub Actions workflow runs `VERIFY_G6.sh`, builds a release `.deb`, extracts it, verifies the active Phone filter + preference files + package version, and only then uploads the artifact.

## Validation status

- Static/project audit: performed by `VERIFY_G6.sh`.
- RootHide/Theos compile: must pass GitHub Actions (this container has no iPhoneOS/Theos compiler environment).
- Actual Phone behavior: requires the single device pass in `ONE_TEST.md`.

Do not call this a final release until that device pass succeeds on the intended iOS 15.x / iOS 16.2 device(s).
