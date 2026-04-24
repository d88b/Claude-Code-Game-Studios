# Block Digging System Review Log

Reviews of design/gdd/block-digging-system.md

---

## Review — 2026-04-23 — Verdict: APPROVED (after revision)

Scope signal: M
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, ux-designer, creative-director
Blocking items: 4 (resolved) | Recommended: 6 (addressed)
Prior verdict resolved: First review

### Initial Findings (NEEDS REVISION)

**Blocking Issues Found:**
1. [godot-specialist] Godot 4.6 API mismatch — TileMap deprecated, must use TileMapLayer
2. [game-designer + creative-director] Design-Fantasy disconnect — "wager" contradicts frame-based mechanics
3. [ux-designer] WCAG 2.3.1 violation — 60fps progress bar pulse violates seizure guidelines
4. [systems-designer] Formula dimensional ambiguity — missing delta_time, no safety clamps

### Revisions Applied

| Blocker | Resolution |
|---------|------------|
| Godot 4.6 API | Replaced TileMap→TileMapLayer throughout; updated set_cell/get_cell signatures |
| Fantasy disconnect | Reframed Player Fantasy from "wager" to "deliberate excavation" |
| WCAG violation | Changed pulse to color gradient shift (no strobing) |
| Formula ambiguity | Added explicit delta_time; added MAX_TOOL_TIER clamp; added damage clamp |

**Additional fixes:** Rewrote untestable ACs (AC-015, AC-026); moved AC-027 to Alpha scope.

### Creative Director Verdict

> "Not MAJOR REVISION because the core loop is sound. Not APPROVED because blockers prevented implementation. Targeted fixes, not rewrite. Fix P0 items and this GDD is ready."

After revisions: APPROVED for implementation.

---

## Key Lessons for Future GDDs

1. **Godot 4.6 TileMap deprecated** — Always use TileMapLayer API in all GDDs touching tile systems
2. **Fantasy must match mechanics** — If design delivers exploration, don't claim wager
3. **WCAG compliance** — Any pulsing/flashing UI must be ≤2Hz or use non-flash alternatives
4. **Formula units** — Include all variables with units; add safety clamps for boundary cases
5. **Testable ACs** — Avoid "feels X", "works correctly" — use measurable criteria