# Block Placing System Review Log

Reviews of design/gdd/block-placing-system.md

---

## Review — 2026-04-23 — Verdict: APPROVED (after revision)

Scope signal: M
Specialists: game-designer, systems-designer, godot-specialist, ux-designer, qa-lead
Blocking items: 3 (resolved) | Recommended: 6 (addressed)
Prior verdict resolved: First review

### Initial Findings (NEEDS REVISION)

**Blocking Issues Found:**
1. [ux-designer] WCAG 2.3.1 seizure violation — Ghost invalid shake "±2px, 8hz" exceeds 3Hz safety limit
2. [game-designer] Fantasy-mechanics disconnect — Player Fantasy claims "紧迫中的决策压力" but MVP instant placement eliminates time pressure
3. [godot-specialist] queue_tile_modification interface mismatch — Placement calls undefined SET operation; collision system only defined DELETE

**Recommended Items Found:**
1. [game-designer] 100% refund undermines Pillar 3 stakes
2. [systems-designer] State machine missing SELECTING→IDLE transition
3. [systems-designer] Validation priority V3 before V6 frustrates UX
4. [godot-specialist] Signal timing "after physics frame" ambiguous
5. [qa-lead] Missing ACs for ghost preview, error messages, keyboard navigation
6. [qa-lead] AC-EC7 scope unclear (Post-MVP but edge case discusses multi-cell)

### Revisions Applied

| Blocker | Resolution |
|---------|------------|
| WCAG violation | Ghost invalid state: 8hz shake → static X icon overlay (no strobing) |
| Fantasy disconnect | Enabled build_time (3-30 sec); added BUILDING state; updated Player Fantasy delivery |
| Interface mismatch | Extended collision system: queue_tile_modification(cell, layer, operation, tile_data) with SET/DELETE |

**Additional fixes:** Updated Rule 4/5/7 for build_time logic; updated state machine with BUILDING and CANCELLED states; corrected all interface references to use SET operation; resolved Q-005 in Open Questions.

### Final Verdict

> "Core placement logic sound — validation chain, material consumption, physics-safe queue pattern all well-designed. Three blocking issues required revision but were straightforward fixes. Fantasy-mechanics disconnect resolved by enabling build_time to match stated Player Fantasy tension. WCAG compliance and interface consistency now correct."

After revisions: APPROVED for implementation.

---

## Key Lessons for Future GDDs

1. **WCAG strobing limit** — Any animation/pulse > 3Hz violates seizure safety. Use static alternatives or ≤2Hz pulses.
2. **Fantasy must match mechanics** — If Player Fantasy describes time pressure, mechanics must deliver it. Instant placement + countdown fantasy = contradiction.
3. **Interface consistency** — When multiple systems call shared API, define unified interface (like SET/DELETE operations) before writing dependent GDDs.
4. **State machine completeness** — Include cancel/escape transitions explicitly; don't assume implicit returns.
5. **Validation order UX** — Prefer cheaper checks (materials) before expensive checks (physics) for player-friendly feedback.