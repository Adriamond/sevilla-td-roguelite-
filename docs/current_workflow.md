# Current Workflow

Use this workflow for all change requests (CRs).

## Working model

- Work one CR at a time.
- Keep each CR small and scoped.
- Do not start the next CR until the current one is validated, manually tested, and committed.

## Validation protocol

After implementation, Codex must run:

`powershell -ExecutionPolicy Bypass -File .\tools\run_validation.ps1`

Rules:

- If validation fails, fix issues using the exact validation output.
- Re-run validation until it passes.
- Report validation result in the final CR handoff.

## Manual test protocol

- User runs manual Godot test only after validation passes.
- Codex should provide a compact manual test checklist for the CR acceptance path.
- If manual test fails, open a follow-up CR or continue within the same CR if requested.

## Merge/commit protocol

- Commit/push only after:
  - validation passes, and
  - manual test acceptance is confirmed.
- Do not chain multiple unvalidated CRs in one commit.

## Codex handoff requirements

Each CR handoff should include:

- changed files list
- validation command executed
- validation outcome (pass/fail)
- known follow-ups or risks (if any)
