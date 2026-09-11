# VALIDATION — acceptance checks (check each session, no merge if red)

| # | Module | Acceptance | Status |
|---|--------|------------|--------|
| 0 | Foundation | `flutter test` passes (category parser); app boots locked behind PIN/biometric stub; docs present | ✅ 2026-09-04 / `feature/00-foundation` (8/8 tests, Flutter 3.47.2) |
| Flex | Customization | Create/rename/delete buckets + sources/dests; ratios !=100 blocked; categories freeform; no hardcoded dropdown | ✅ 2026-09-04 / `feature/01-custom-core` (data layer + 13 tests; UI later) |
| 1 | Txn+Cat | In/out with datetime saves offline; `food junk gobi-65` parses to levels+item; search `gobi-65` → sum/count/month/year | ✅ 2026-09-07 / `feature/02-transactions` (entry UI + search screens, 26 tests, debug APK built+verified) |
| 2 | Budget+Sim | Monthly total set; ins/outs vs budget correct; N buckets editable; simulator previews ratio on last 3 months | ✅ 2026-09-08 / `feature/03-budgets` (editor + simulator + spend progress, 32 tests) |
| 3 | Neutral+Aging | Lend 5000 May, repaid June: both months' budgets unaffected; partials sum to full; auto-settled+archived; aging days + nudge date shown | ✅ 2026-09-08 / `feature/04-neutral` (debts UI + auto-settle, 38 tests) |
| 4 | Split | Pay 1000/10: budget=-100, receivable=900; settle 100 reconciles to bank; unpaid flagged absorbed | ✅ 2026-09-08 / `feature/05-splits` (splits UI + absorb + optimizer, 43 tests) |
| 5 | Instruments | Bank/card/stock/paper/notes save; P/L% = (cur-inv)/inv*100 correct; interest calc correct | ✅ 2026-09-11 / `pr/06-instruments` (vault + P/L% + SI preview, 51/51 green, analyze clean) |
| 6 | Reconcile | Start bank+cash+card+budget vs end: true spent + missing shown; cash physical count path works | ☐ TODO |
| 6b | PriceMemory | Same item twice at different prices → avg/min/max + overpay flag | ☐ TODO |
| 6c | NetWorth | Month-end (banks+cash+investments−debts) graph renders | ☐ TODO |
| 7 | Reports | Graphs per module, tap drills to txn list | ☐ TODO |
| Intake | Share intake | Share text `Paid Rs.450 to Swiggy` → app in sheet → 450 prefilled, editable, source/category pickable, saves offline | ☐ TODO |
| Intake-img | OCR intake | Share payment screenshot → amount extracted offline → confirm screen | ☐ TODO |
| Cash | Cash | Open 2000, spend 300 → expected 1700; ATM Bank→Cash no budget hit; Cash-vs-Digital filter | ☐ TODO |
| Quick | Quick-add | Home widget → 2-tap cash spend opens confirm sheet | ☐ TODO |
| 8 | Backup | Export → delete → import restores 100%; Drive file works; wrong password fails cleanly | ☐ TODO |
| 9 | Security | No PIN/biometric = no data; decoy PIN opens clean demo; auto-lock; encrypted backup | ☐ TODO |

Mark `✅ date/branch` when green. Merge rule: row green + `flutter test` green.
