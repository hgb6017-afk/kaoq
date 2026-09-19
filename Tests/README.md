# Stage 4 tests

These test sources are not included in the tweak target by default. Run them in a suitable XCTest/Foundation harness or port the vectors to your host test runner.

Focus areas:
- formatting removal and preservation of +/*/# semantics
- conservative VN 0 ↔ +84 equivalence
- Vietnamese diacritic folding/T9 (including Đ/đ)
- duplicate merge across Contacts and Call History
- ranking order exact > prefix > substring > contact > recency > frequency
- SIM label trimming and max length
