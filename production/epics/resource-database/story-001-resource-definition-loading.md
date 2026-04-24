# Story 001: Resource Definition Loading

> **Epic**: ResourceDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/resource-database.md`
**Requirement**: `TR-resource-001`, `TR-resource-002`, `TR-resource-003`

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: ResourceDB 是 RefCounted Autoload，从 entities.yaml 加载资源定义，O(1) Dictionary lookup。

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: All static data from entities.yaml
- Required: Database pattern: RefCounted Autoload
- Required: O(1) lookup via Dictionary

---

## Acceptance Criteria

- [ ] Resource definitions loaded from entities.yaml
- [ ] get_resource(resource_id) returns ResourceDefinition for valid ID
- [ ] get_max_stack_size(resource_id) returns stack limit (100 for most)
- [ ] MVP resources defined: 铁锭(151), 铜锭(152), 基础零件(160)
- [ ] Resource categories: raw_material, processed, component, ammo
- [ ] Invalid ID returns null gracefully

---

## Implementation Notes

```gdscript
class_name ResourceDB extends RefCounted

var _resources: Dictionary = {}  # {resource_id: ResourceDefinition}

class ResourceDefinition:
    var resource_id: int
    var display_name: String  # 中文名称
    var max_stack_size: int   # 堆叠上限
    var category: String      # raw_material/processed/component/ammo

func get_resource(resource_id: int) -> ResourceDefinition:
    return _resources.get(resource_id, null)

func get_max_stack_size(resource_id: int) -> int:
    var res = get_resource(resource_id)
    return res.max_stack_size if res else 0
```

---

## QA Test Cases

- **AC-1**: Valid resource query
  - Given: resource_id = 151 (铁锭)
  - When: get_resource(151) called
  - Then: returns ResourceDefinition with display_name, max_stack_size=100
- **AC-2**: Stack size query
  - Given: resource_id = 151
  - When: get_max_stack_size(151) called
  - Then: returns 100
- **AC-3**: Category validation
  - Given: all resources loaded
  - When: category field checked
  - Then: valid categories only (raw_material/processed/component/ammo)

---

## Test Evidence

**Type**: Integration
**Required**: `tests/unit/resource/resource_loading_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer)
- Unlocks: VehicleAttributeSystem, FacilityController