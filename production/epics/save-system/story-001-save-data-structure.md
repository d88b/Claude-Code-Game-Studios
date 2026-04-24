# Story 001: Save Data Structure + Auto-Save + Load

> **Epic**: SaveSystem
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-25

## Context

**GDD**: `design/gdd/save-system.md`
**Requirement**: Blocker #5 from Gate Check — SAVE SYSTEM MISSING

**ADR Governing Implementation**: ADR-005: Event Bus (save/load signals)
**ADR Decision Summary**: SaveManager 作为 Autoload，使用 JSON 格式存储存档数据。

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Godot 4.6 FileAccess API 变化 — 使用 `FileAccess.open()` 返回 FileAccess 对象。

---

## Acceptance Criteria

- [x] **AC-01**: 自动存档在返回地堡时触发，存档文件写入 `user://saves/`
- [x] **AC-02**: 存档数据包含 game_state, vehicle, bunker_layout, resources, facilities, areas
- [x] **AC-03**: 加载存档恢复所有系统状态
- [x] **AC-04**: 存档文件损坏时显示错误提示，不崩溃
- [x] **AC-05**: 存档文件大小 ≤ 1MB
- [x] **AC-06**: 3 个存档槽可用（slot_1, slot_2, slot_3）
- [x] **AC-07**: 存档包含版本号，支持版本迁移

---

## Implementation Notes

### SaveManager Autoload

```gdscript
# src/save/save_manager.gd
class_name SaveManager extends Node

const SAVE_DIR: String = "user://saves/"
const MAX_SAVE_SLOTS: int = 3
const SAVE_VERSION: String = "1.0.0"

signal save_completed(slot_id: int, success: bool)
signal load_completed(slot_id: int, success: bool)

var _current_slot: int = 1

func _ready() -> void:
    # 确保 save 目录存在
    var dir: DirAccess = DirAccess.open("user://")
    if not dir.dir_exists("saves"):
        dir.make_dir("saves")
    
    # 连接 GameState 信号
    GlobalSignals.state_changed.connect(_on_game_state_changed)

func auto_save() -> bool:
    var save_data: Dictionary = _collect_save_data()
    return _write_save(_current_slot, save_data)

func _collect_save_data() -> Dictionary:
    return {
        "version": SAVE_VERSION,
        "game_version": ProjectSettings.get_setting("application/config/version", "0.1.0"),
        "saved_at": Time.get_datetime_string_from_system(),
        "game_state": _collect_game_state(),
        "vehicle": _collect_vehicle_data(),
        "bunker_layout": _collect_bunker_layout(),
        "resources": _collect_resources(),
        "facilities": _collect_facilities(),
        "areas": _collect_areas(),
        "stats": _collect_stats()
    }

func _write_save(slot_id: int, data: Dictionary) -> bool:
    var path: String = SAVE_DIR + "save_slot_%d.json" % slot_id
    var json: String = JSON.stringify(data)
    
    var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
    if file == null:
        push_error("[SaveManager] Cannot write to %s" % path)
        return false
    
    file.store_string(json)
    file.close()
    
    save_completed.emit(slot_id, true)
    return true

func load_save(slot_id: int) -> bool:
    var path: String = SAVE_DIR + "save_slot_%d.json" % slot_id
    
    if not FileAccess.file_exists(path):
        push_warning("[SaveManager] Save file not found: %s" % path)
        return false
    
    var file: FileAccess = FileAccess.open(path, FileAccess.READ)
    if file == null:
        push_error("[SaveManager] Cannot read %s" % path)
        return false
    
    var json: String = file.get_as_text()
    file.close()
    
    var json_obj: JSON = JSON.new()
    var parse_err: int = json_obj.parse(json)
    if parse_err != OK:
        push_error("[SaveManager] JSON parse error: %s" % path)
        return false
    
    var data: Dictionary = json_obj.get_data()
    return _apply_save_data(data)

func _apply_save_data(data: Dictionary) -> bool:
    # 验证版本
    var save_version: String = data.get("version", "0.0.0")
    if save_version != SAVE_VERSION:
        # 版本迁移逻辑
        data = _migrate_save(data, save_version)
    
    # 应用数据到各系统
    _apply_game_state(data.get("game_state", {}))
    _apply_vehicle_data(data.get("vehicle", {}))
    # ... 其他系统
    
    load_completed.emit(_current_slot, true)
    return true
```

### Integration Points

| System | Save | Load |
|--------|------|------|
| GameState | `_collect_game_state()` | `_apply_game_state()` |
| VehicleAttribute | `_collect_vehicle_data()` | `_apply_vehicle_data()` |
| TileMapWorld | `_collect_bunker_layout()` | `_apply_bunker_layout()` |
| ResourceDB | `_collect_resources()` | `_apply_resources()` |
| FacilityController | `_collect_facilities()` | `_apply_facilities()` |
| AreaManager | `_collect_areas()` | `_apply_areas()` |

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/save/save_manager_test.gd` ✅ CREATED
**Test Cases**: 35+ test functions covering all AC criteria
- test_auto_save_on_bunker_return() ✅
- test_save_data_contains_*() ✅ (game_state, vehicle, bunker_layout, resources, facilities, areas)
- test_load_save_restores_slot() ✅
- test_corrupted_file_emits_error_signal() ✅
- test_save_file_size_within_limit() ✅
- test_max_save_slots_is_3() ✅
- test_version_migration_adds_missing_fields() ✅

---

## Dependencies

- Depends on: GlobalSignals, GameState, VehicleAttribute, TileMapWorld, ResourceDB, FacilityController, AreaManager
- Unlocks: Main Menu (save slot selection), Pause Menu (manual save)

---

## Implementation Estimate

**Days**: 2 (Foundation layer)

---

## Completion Notes

**Implementation Date**: 2026-04-25
**Files Created**:
- `src/save/save_manager.gd` — SaveManager Autoload (507 lines)
- `tests/unit/save/save_manager_test.gd` — Unit tests (35+ test functions)

**Files Modified**:
- `project.godot` — SaveManager Autoload registration

**Implementation Details**:
- Atomic write pattern (temp file → rename) for save file safety
- JSON format with version field for migration support
- Signal emission for save/load events (save_completed, load_completed, save_error, load_error)
- Integration hooks with GlobalSignals for auto-save triggers
- Data collection from 7 game systems (GameState, VehicleAttribute, TileMapWorld, ResourceDB, FacilityController, AreaManager, stats)

**Blocker Status**: #5 SAVE SYSTEM MISSING → **RESOLVED**