# SmartDialSIM G6.1 — Audit report

## High-severity issues found and fixed

1. **Incomplete G6 GitHub patch:** the old patch omitted the active `SmartDialSIM.plist` and `Runtime/SDSDiagnosticReporter.h`. Applying it over G4.1 could leave the tweak inert and/or fail compilation. The new overlay is generated from the complete G6.1 tree.
2. **SIM control could be mistaken for keypad digit 1/2:** text such as `SIM 1` contained a digit and passed the old key detector. Key discovery now excludes line/SIM semantics and requires keypad-like geometry.
3. **SIM logical-line order was unsafe:** the old adaptive approach could infer SIM order from observation/order. G6.1 only accepts exactly two native menu actions or explicit native logical markers; otherwise it leaves SIM UI untouched.
4. **Suggestion replacement could send up to 64 blind delete actions:** visible-keypad fallback now determines the current dial-string length first and fails closed when it cannot do so safely.
5. **Clipboard fallback risk:** runtime dialer code no longer reads/writes the user pasteboard. The pasteboard is used only by the explicit Settings button that copies a diagnostic report.
6. **Initial index race:** if the user typed before Contacts/History finished loading, suggestions could remain empty. Index swaps now re-query the current dial string.
7. **Stale suggestions after toggling Smart Dial/tweak:** disabling now clears cached dial state so re-enabling refreshes the same currently typed number.
8. **Async weak-reference race:** search scheduling now strongifies the controller before dispatching to avoid a nil dispatch queue during teardown.
9. **Number-display false positives:** only label/text input views above the keypad with a minimum confidence score are accepted.
10. **CallHistory ABI risk:** private calls are guarded by method-signature checks; call fields use exception-safe KVC instead of treating unknown scalar-return selectors as Objective-C objects. Change refresh also listens only to actually-posted local notification names matching CallHistory/Recent-call patterns, without reading notification payloads.
11. **Diagnostic privacy:** arbitrary visible text/contact names are redacted; phone-like text is masked.
12. **Release/package validation:** GitHub Actions now checks package/version/architecture, extracts the DEB, verifies the Phone filter and Preferences payload, and only then uploads it.

## Static checks performed

- Required project files and local imports.
- RootHide scheme / target / architecture.
- No hard-coded `/var/jb` in tweak/package source.
- Active Phone filter, no inert G4 marker.
- XML preferences plist parsing.
- Frida JS syntax when Node is available.
- Brace/source invariant checks.
- Runtime core contains no UIPasteboard fallback.

## Not statically provable

The actual Apple Phone view hierarchy, UIKeyInput exposure, exact iOS 16.2 CallHistory behavior, and dual-SIM native selector representation require a real device. In particular, separate menu-item carrier titles are not rewritten unless that menu boundary is verified. The code is designed to fail closed when those boundaries are unavailable rather than guessing.
