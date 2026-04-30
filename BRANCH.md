# feature/non-interactive

## What's in this branch
42 tutorial scripts made non-interactive by the DocBash pipeline (run_group: non-interactive-20260427-1821).
Plus 5 scripts fixed locally before the pipeline run (013-ec2, 019-lambda, 033-ses, 035-workspaces, 047-firewall).

All `read -p` and `read -r` user prompts replaced with auto-answers:
- Cleanup confirmations → y
- Press Enter → removed or sleep
- Runtime/config selection → first option
- Email/name/domain → generated values
- VPC/subnet selection → first option or auto-detect

## Status
- 44/70 tutorials passing (42 pipeline + 2 retry)
- 5 fixed locally (on main, included here)
- 21 remaining failures — all environment quota limits (VpcLimitExceeded, AddressLimitExceeded)

## Before publishing
- [ ] Rerun the 21 failures after VPC cleanup completes
- [ ] Verify no `read` prompts remain in passing scripts (spot check)
- [ ] Update REVISION-HISTORY.md for each modified tutorial

## After publishing
- [ ] Rebase feature/resource-tagging off this branch (tagging needs non-interactive as prereq)
