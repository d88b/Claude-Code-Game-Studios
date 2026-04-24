# BUG-002: Headless Test Preload Failure

**ID**: BUG-002
**Severity**: P2 (Known Issue — Non-blocking)
**Story**: testenv-001
**Found**: 2026-04-24 (QA Sign-off Sprint 3)
**Status**: Open

---

## Description

spawn_wave_test.gd 和 turret_targeting_test.gd 在 headless CLI 模式下 preload 失败。

**Error Message**:
```
Failed to load resource: res://src/spawn/spawn_manager.gd
```

**Root Cause**:
- Headless CLI 环境无法正确解析 GDScript 的 `preload()` 引用
- 相关类可能依赖 Autoload 单例，在 headless 测试环境中未正确初始化

---

## Reproduction Steps

1. 运行 `godot --headless --script tests/gut_runner.gd`
2. 观察 spawn_wave_test.gd 和 turret_targeting_test.gd 输出
3. 看到 preload 失败错误

**Expected**: Tests execute normally in headless CLI
**Actual**: Preload fails, tests blocked

---

## Workaround

- Tests 在 Godot Editor GUT panel 中正常执行（有完整 scene tree）
- 生产代码无问题，仅测试环境问题

---

## Fix Recommendation

1. **Option A**: 使用 `class_name` 引用而非 `preload()`
2. **Option B**: 在测试中使用 `load()` 而非 `preload()` (延迟加载)
3. **Option C**: 为测试创建 mock Autoload 单例

---

## Acceptance Criteria

- [ ] spawn_wave_test.gd 在 headless CLI 正常执行
- [ ] turret_targeting_test.gd 在 headless CLI 正常执行
- [ ] 测试结果与 Editor 一致

---

## Priority Assessment

P2 — 不阻塞生产代码，但影响自动化测试覆盖率。Editor 验证可临时替代。

---

## Owner

engine-programmer