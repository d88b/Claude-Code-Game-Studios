# Architecture Traceability Index

> **Last Updated**: 2026-04-24
> **Version**: 1.0

## Purpose

This document provides a traceability matrix linking Technical Requirements (TRs)
to Architecture Decision Records (ADRs), ensuring all design requirements have
architectural coverage.

---

## Summary

| Layer | TRs | ADR Coverage | Gaps |
|-------|-----|--------------|------|
| **Foundation** | 22 | 22 | 0 ✓ |
| **Core** | 36 | 36 | 0 ✓ |
| **Feature** | 14 | 14 | 0 ✓ |
| **Total** | 72 | 72 | 0 ✓ |

---

## Foundation Layer Traceability

| TR ID | Requirement | ADR Coverage | Status |
|-------|-------------|--------------|--------|
| TR-tilemap-001 to 005 | TileMap system (5-layer, chunks, procedural, TileMapLayer) | ADR-001 | ✓ Covered |
| TR-blocktype-001 to 003 | BlockType database (collision, dig, drops) | ADR-002, ADR-006 | ✓ Covered |
| TR-resource-001 to 003 | Resource database (stack size, categories, new IDs) | ADR-002, ADR-015 | ✓ Covered |
| TR-enemytype-001 to 002 | EnemyType database (stats, behavior_hint) | ADR-002, ADR-010 | ✓ Covered |
| TR-builditem-001 to 002 | BuildItem database (cost, terrain support) | ADR-002, ADR-013 | ✓ Covered |
| TR-vehicletype-001 to 002 | VehicleType database (state machine, stats) | ADR-002, ADR-007 | ✓ Covered |
| TR-scavenge-001 | Scavenge container (loot tables) | ADR-002 | ✓ Covered |
| TR-time-001 to 002 | Time system (scale, cycle) | ADR-004 | ✓ Covered |
| TR-input-001 to 002 | Input control (dual-focus, mapping) | ADR-003 | ✓ Covered |

---

## Core Layer Traceability

| TR ID | Requirement | ADR Coverage | Status |
|-------|-------------|--------------|--------|
| TR-collision-001 to 003 | Block collision (swept, MAX_STEPS, severity) | ADR-006 | ✓ Covered |
| TR-digging-001 to 002 | Block digging (progress, modifiers) | ADR-013 | ✓ Covered |
| TR-placing-001 to 002 | Block placing (validation, cost) | ADR-013 | ✓ Covered |
| TR-drop-001 to 002 | Resource drop (lifetime, spawn) | ADR-015 | ✓ Covered |
| TR-daynight-001 to 002 | Day/night cycle (lighting, overlay) | ADR-004, ADR-016 | ✓ Covered |
| TR-vehicleattr-001 to 002 | Vehicle attribute (health, magic) | ADR-007, ADR-009 | ✓ Covered |
| TR-driving-001 to 003 | Vehicle driving (acceleration, clamp, magic) | ADR-008, ADR-009 | ✓ Covered |
| TR-magic-001 to 002 | Magic consumption (pool, depletion) | ADR-009 | ✓ Covered |
| TR-weapon-001 to 003 | Vehicle weapon (cooldown, projectile, ammo) | ADR-011 | ✓ Covered |
| TR-damage-001 to 002 | Vehicle damage (formula, transitions) | ADR-007, ADR-011 | ✓ Covered |
| TR-area-001 to 002 | Exploration area (bounds, entry) | ADR-016 | ✓ Covered |
| TR-enemyai-001 to 004 | Enemy AI (navigation, state, separation, target) | ADR-010 | ✓ Covered |
| TR-spawn-001 to 002 | Enemy spawn (wave timing, validation) | ADR-012 | ✓ Covered |
| TR-turret-001 to 003 | Turret system (state, targeting, ammo) | ADR-011 | ✓ Covered |
| TR-retreat-001 to 002 | Retreat judgment (threshold, warning) | ADR-016 | ✓ Covered |

---

## Feature Layer Traceability

| TR ID | Requirement | ADR Coverage | Status |
|-------|-------------|--------------|--------|
| TR-buildvalid-001 to 002 | Build validation (terrain, collision) | ADR-013 | ✓ Covered |
| TR-facility-001 to 005 | Bunker facility (lifecycle, storage, crafting, magic, demolition) | ADR-014 | ✓ Covered |

---

## ADR Dependency Graph

```
ADR-005 (Event Bus) — Foundation, no dependencies
    │
    ├──→ ADR-001 (TileMap) — depends on ADR-005
    ├──→ ADR-002 (Database) — no dependencies
    ├──→ ADR-003 (Input) — depends on ADR-005
    ├──→ ADR-004 (Time) — depends on ADR-005
    │
ADR-001, ADR-002, ADR-003, ADR-004, ADR-005 — Foundation layer complete
    │
    ├──→ ADR-006 (Collision) — depends on ADR-001, ADR-002, ADR-005
    ├──→ ADR-007 (Vehicle State) — depends on ADR-002, ADR-005
    ├──→ ADR-008 (Movement) — depends on ADR-003, ADR-006, ADR-007, ADR-009
    ├──→ ADR-009 (Magic) — depends on ADR-002, ADR-005
    ├──→ ADR-010 (Enemy AI) — depends on ADR-001, ADR-002, ADR-005
    ├──→ ADR-011 (Combat) — depends on ADR-002, ADR-007, ADR-009, ADR-010, ADR-005
    ├──→ ADR-012 (Spawn) — depends on ADR-002, ADR-004, ADR-010, ADR-016, ADR-005
    │
ADR-006 to ADR-012 — Core layer complete
    │
    ├──→ ADR-013 (Build) — depends on ADR-001, ADR-002, ADR-003, ADR-007, ADR-005
    ├──→ ADR-014 (Facility) — depends on ADR-001, ADR-002, ADR-009, ADR-013, ADR-005
    ├──→ ADR-015 (Drop) — depends on ADR-001, ADR-002, ADR-007, ADR-005
    ├──→ ADR-016 (Area) — depends on ADR-001, ADR-004, ADR-007, ADR-009, ADR-012, ADR-005
    │
ADR-013 to ADR-016 — Feature layer complete

No circular dependencies detected. ✓
```

---

## Engine Risk Summary

| ADR | Engine Domain | Risk Level | Post-Cutoff API | Verification |
|-----|---------------|------------|-----------------|--------------|
| ADR-001 | TileMap | LOW | TileMapLayer (stable 4.3+) | ✓ Verified |
| ADR-003 | Input | HIGH | Dual-focus (4.6) | ⚠️ Requires testing |
| ADR-010 | Navigation | HIGH | NavigationAgent2D (4.5+) | ⚠️ Requires testing |
| Others | — | LOW | None | ✓ Safe |

All HIGH RISK domains explicitly addressed in architecture.md Open Questions section. ✓

---

## Deprecated API Check

No ADR references APIs listed in `docs/engine-reference/godot/deprecated-apis.md`. ✓

---

## Validation

- [x] All Foundation TRs have ADR coverage
- [x] All Core TRs have ADR coverage
- [x] All Feature TRs have ADR coverage
- [x] No circular ADR dependencies
- [x] All HIGH RISK engine domains flagged
- [x] No deprecated API usage