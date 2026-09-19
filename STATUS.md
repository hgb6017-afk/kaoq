# SmartDialSIM G6.1 Status

Version: `0.6.1-audit-fixed`

## Implemented / audit-fixed

- iOS 15.x + exact iOS 16.2 runtime gate.
- RootHide scheme, arm64 + arm64e, active Phone-only filter.
- Contacts index, contact-change refresh, and re-query after asynchronous index swaps.
- Runtime-checked CallHistory `CHManager` provider with signature validation, opportunistic name-only change observation, foreground refresh, and safe Contacts-only fallback.
- Vietnamese normalization, T9, merge/ranking/debounce/stale-query cancellation.
- Adaptive keypad discovery with geometry + semantic filtering so SIM controls containing digits are not mistaken for keypad buttons.
- Number-display confidence threshold before Smart Dial UI attaches.
- Suggestion fill via safe `UIKeyInput` first, visible native keypad controls second; no user-pasteboard fallback and no blind 64-delete burst.
- Compact SIM presentation only with a reliable two-line mapping; no carrier-name / physical-eSIM / observation-order mapping.
- Unicode-safe SIM alias truncation and restoration of native visual/accessibility state.
- Preferences live reload, release logging, and privacy-redacted on-demand diagnostics.
- GitHub workflow verifies the produced DEB contents before upload.

## Remaining device-only uncertainties

These cannot be proved statically:

- Whether a particular iOS 15.x / iOS 16.2 Phone build exposes the UIKit boundaries needed by adaptive keypad discovery and number replacement.
- Whether exact iOS 16.2 exposes a compatible CallHistory provider. If not, history suggestions disable while Contacts remains usable.
- Whether the native dual-SIM control exposes exactly two menu actions or explicit logical-line markers. If not, SIM presentation intentionally remains native rather than guessing. If Apple renders carrier names inside a separate menu overlay, those menu-item titles are not rewritten until that UI boundary is verified on-device.
- Non-Vietnam international `+` numbers require a usable `UIKeyInput` boundary; the visible-keypad fallback cannot synthesize a long-press `+` safely.

One real-device pass is therefore still required before a final-release claim.
