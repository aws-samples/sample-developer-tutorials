# feature/resource-tagging-v2

## What's in this branch
25 tutorial scripts with resource tagging added by the DocBash pipeline (run_group: tagging-20260427-2241).

Every AWS resource created is tagged with:
- `Key=project,Value=doc-smith`
- `Key=tutorial,Value={tutorial-id}`

Using the correct syntax per service (--tags, --tag-specifications, tag-resource, put-bucket-tagging, etc.)

## Status
- 25/44 tutorials passing (56%)
- 19 failures — mix of environment limits and tagging syntax errors

## Before publishing
- [ ] Rebase off feature/non-interactive (tagging needs non-interactive as prereq)
- [ ] Rerun the 19 failures after non-interactive is merged
- [ ] Spot-check that tags are actually applied (not just syntactically correct)
- [ ] Update REVISION-HISTORY.md for each modified tutorial

## After publishing
- [ ] Run tagging on the remaining 26 tutorials that weren't in this batch
