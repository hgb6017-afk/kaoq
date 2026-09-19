# Runtime matrix — G6.1

| Capability | iOS 15.x | iOS 16.2 | Fail-safe behavior |
|---|---|---|---|
| Phone target | `com.apple.mobilephone` | `com.apple.mobilephone` | No injection outside Phone |
| Keypad discovery | UIKit scan + geometry/semantic confidence | Same | Suggestions remain hidden |
| Dial-string observation | Native visible number display scan | Same | Native keypad unaffected |
| Suggestion fill | `UIKeyInput`, else visible keypad controls | Same | Selection fails safely; never calls |
| Contacts | Contacts.framework | Contacts.framework | Call-history source may still work |
| Call history | Runtime-signature-checked `CHManager` | Runtime-signature-checked `CHManager` | Contacts-only Smart Dial |
| SIM presentation | Exactly-two action menu or explicit native SIM1/SIM2 markers | Same | Native SIM UI untouched |
| SIM selection logic | Apple's original target/action | Apple's original target/action | Never reimplemented |
| Diagnostics | On demand, redacted | On demand, redacted | Idle during normal use |
