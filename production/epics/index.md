# Epics Index

Last Updated: 2026-04-24
Engine: Godot 4.6

## Foundation Layer (9 epics) ✅ COMPLETE

| Epic | Layer | GDD | Stories | Status |
|------|-------|-----|---------|--------|
| tilemap-world | Foundation | tilemap-world-system.md | 6 stories | Ready |
| block-type-database | Foundation | block-type-database.md | 5 stories | Ready |
| resource-database | Foundation | resource-database.md | 1 story | Ready |
| enemy-type-database | Foundation | enemy-type-database.md | 1 story | Ready |
| build-item-database | Foundation | build-item-database.md | 1 story | Ready |
| vehicle-type-database | Foundation | vehicle-type-database.md | 1 story | Ready |
| scavenge-container-database | Foundation | scavenge-container-database.md | 1 story | Ready |
| time-system | Foundation | time-system.md | 1 story | Ready |
| input-control-system | Foundation | input-control-system.md | 1 story | Ready |

## Core Layer (15 epics) ✅ COMPLETE

| Epic | Layer | GDD | Stories | Status |
|------|-------|-----|---------|--------|
| block-collision-system | Core | block-collision-system.md | 1 story | Ready |
| block-digging-system | Core | block-digging-system.md | 1 story | Ready |
| block-placing-system | Core | block-placing-system.md | 1 story | Ready |
| resource-drop-system | Core | resource-drop-system.md | 1 story | Ready |
| day-night-cycle-system | Core | day-night-cycle-system.md | 1 story | Ready |
| vehicle-attribute-system | Core | vehicle-attribute-system.md | 1 story | Ready |
| vehicle-driving-system | Core | vehicle-driving-system.md | 1 story (⚠️ HIGH) | Ready |
| magic-energy-consumption | Core | magic-energy-consumption.md | 1 story | Ready |
| vehicle-weapon-system | Core | vehicle-weapon-system.md | 1 story | Ready |
| vehicle-damage-system | Core | vehicle-damage-system.md | 1 story | Ready |
| exploration-area-system | Core | exploration-area-system.md | 1 story | Ready |
| enemy-ai-system | Core | enemy-ai-system.md | 1 story (⚠️ HIGH) | Ready |
| enemy-spawn-system | Core | enemy-spawn-system.md | 1 story | Ready |
| turret-system | Core | turret-system.md | 1 story | Ready |
| retreat-judgment-system | Core | retreat-judgment-system.md | 1 story | Ready |

## Feature Layer (2 epics) ✅ COMPLETE

| Epic | Layer | GDD | Stories | Status |
|------|-------|-----|---------|--------|
| build-validation-system | Feature | build-validation-system.md | 1 story | Ready |
| bunker-facility-system | Feature | bunker-facility-system.md | 1 story | Ready |

---

**Total: 26 epics — all stories created**

**Foundation: 18 stories total (tilemap: 6, block-type: 5, others: 7 single stories)**
**Core: 15 stories total (one per epic)**
**Feature: 2 stories total (one per epic)**
**Grand Total: ~35 stories**

**HIGH RISK Stories:**
- `vehicle-driving-system` Story 001 (ADR-003: Dual-focus Godot 4.6)
- `enemy-ai-system` Story 001 (ADR-010: NavigationAgent2D Godot 4.5+)

---

**Next Steps:**
1. Run `/gate-check pre-production` to validate readiness for sprint planning
2. Run `/sprint-plan` to assign stories to sprint
3. Developers can pick up stories via `/story-readiness [story-path]` → `/dev-story [story-path]`