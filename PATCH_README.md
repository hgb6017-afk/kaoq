# G6.1 GitHub overlay

This patch is intentionally a **complete overlay**, not a minimal diff. The previous G6 patch omitted critical files (`SmartDialSIM.plist` and `Runtime/SDSDiagnosticReporter.h`).

To apply: extract this ZIP, upload/replace all included files at the root of the existing SmartDialSIM GitHub repository, and commit. Existing obsolete G4.1 helper scripts may remain; they are not referenced by the G6.1 Makefile/workflow.

GitHub Actions should run **Build SmartDialSIM G6.1 RootHide DEB** and only upload the artifact after the DEB content verification step passes.
