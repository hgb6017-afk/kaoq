# G4.1 dual-version changes

- Expanded supported scope from iOS 16.2-only to iOS 15.x + iOS 16.2.
- Lowered shared Theos deployment target to iOS 15.0.
- Package firmware dependency now allows iOS 15.0+.
- Added `SDSRuntimeVersion` with three fail-closed families: iOS 15.x, iOS 16.2, unsupported.
- Kept all private Phone capabilities disabled until per-family runtime evidence exists.
- Split private-header staging directories into `PrivateHeaders/iOS15` and `PrivateHeaders/iOS162`.
- Added `RUNTIME_MATRIX.md` to track verification separately for both OS families.
- Updated runtime probe to print the actual OS version.
- Updated verified-target helper to accept one or two independently verified bundle IDs.
- Updated Preferences/version strings to 0.4.1-stage4.1.
- Added `VERIFY_STAGE4_1.sh`; legacy `VERIFY_STAGE4.sh` now forwards to it.
- No guessed private Phone class, selector, call-history API, SIM identifier, database path, or entitlement was added.

## G6.1 audit-fixed

- Rebuilt the GitHub overlay so active filter + all new headers are included.
- Hardened keypad/dial display detection, suggestion refill lifecycle, and async search teardown.
- Removed runtime clipboard fill and blind delete bursts.
- Hardened private CallHistory ABI checks and privacy diagnostics.
- Reworked SIM mapping to fail closed unless native two-line identity is reliable.
- Added post-build DEB verification in GitHub Actions.
