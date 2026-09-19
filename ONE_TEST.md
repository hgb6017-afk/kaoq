# One real-device test — G6.1

Do this only after GitHub Actions builds the `0.6.1-audit-fixed` DEB successfully.

1. Install the DEB with Sileo and enable Phone in RootHide App List.
2. Open Settings → SmartDialSIM. Keep Smart Dial, Contacts, Call History and Compact SIM enabled. Enable T9 if desired.
3. Tap **Ghi snapshot kiểm tra ngay** once before the test. It arms only a short diagnostic burst.
4. Open Phone → Keypad. Type digits, delete, long-delete, `*`, `#`, paste a test number, then try both `0...` and `+84...` forms.
5. Confirm matching suggestions appear and no-match hides the list.
6. Tap a suggestion. It must replace the dialed number and **must not call**. Then manually edit/delete the result.
7. If dual SIM exists, switch the native line. The real selected line must remain correct; aliasing is allowed only if the tweak can map the two native lines confidently.
8. Switch away from Keypad and back; background/foreground Phone once. Confirm no duplicate suggestion view, layout warnings, lag, or crash.
9. If all requested behavior works, the single test is complete.
10. If anything fails, Settings → SmartDialSIM → **Sao chép báo cáo** and send that report plus a short description of the failed step. No separate diagnostic build is needed.
