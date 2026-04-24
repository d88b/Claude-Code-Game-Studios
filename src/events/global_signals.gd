extends Node
# GlobalSignals — 全局事件总线 (Autoload)
## GlobalSignals — 全局事件总线
## 所有 Core/Feature 层模块通过此 Autoload 进行跨场景通信
## Foundation layer system (ADR-005)

# === 时间系统信号 ===
## 小时变化 (hour: int)
signal time_hour_changed(hour: int)
## 日夜阶段变化 (phase: int — TimeSystem.DayPhase enum value)
signal day_phase_changed(phase: int)
## 天数变化 (day: int)
signal day_count_changed(day: int)

# === 方块系统信号 ===
## 方块被挖掘 (grid_pos: Vector2i, block_id: int)
signal block_dug(grid_pos: Vector2i, block_id: int)
## 方块被放置 (grid_pos: Vector2i, block_id: int, layer: int)
signal block_placed(grid_pos: Vector2i, block_id: int, layer: int)

# === 战车系统信号 ===
## 战车受到伤害 (amount: float)
signal vehicle_damaged(amount: float)
## 战车魔能变化 (current: float, max: float)
signal magic_pool_changed(current: float, max_pool: float)
## 战车状态变化 (state: int — VehicleState enum value)
signal vehicle_state_changed(state: int)
## 战车被摧毁 (vehicle_id: int)
signal vehicle_destroyed(vehicle_id: int)

# === 敌人系统信号 ===
## 敌人被生成 (enemy_id: int, position: Vector2)
signal enemy_spawned(enemy_id: int, position: Vector2)
## 敌人被消灭 (enemy_id: int)
signal enemy_killed(enemy_id: int)

# === 区域系统信号 ===
## 进入新区域 (area_id: int, area_name: String)
signal area_entered(area_id: int, area_name: String)
## 离开区域 (area_id: int)
signal area_exited(area_id: int)

# === 撤退系统信号 ===
## 撤退阈值触发 (reason: String)
signal retreat_threshold_reached(reason: String)
## 撤退开始
signal retreat_initiated()

# === 资源系统信号 ===
## 资源掉落生成 (resource_id: int, position: Vector2, quantity: float)
signal resource_dropped(resource_id: int, position: Vector2, quantity: float)
## 资源被拾取 (resource_id: int, quantity: float)
signal resource_collected(resource_id: int, quantity: float)

# === 设施系统信号 ===
## 设施被创建 (facility_id: int, position: Vector2i)
signal facility_created(facility_id: int, position: Vector2i)
## 设施被拆除 (facility_id: int, position: Vector2i)
signal facility_demolished(facility_id: int, position: Vector2i)

# === 建造系统信号 ===
## 建造开始 (item_id: int, position: Vector2i)
signal build_started(item_id: int, position: Vector2i)
## 建造完成 (item_id: int, position: Vector2i)
signal build_completed(item_id: int, position: Vector2i)

# === 战斗系统信号 ===
## 武器开火 (weapon_id: int, position: Vector2)
signal weapon_fired(weapon_id: int, position: Vector2)
## 炮塔激活 (turret_id: int)
signal turret_activated(turret_id: int)
## 炮塔停用 (turret_id: int)
signal turret_deactivated(turret_id: int)

# === 游戏状态信号 ===
## 游戏暂停
signal game_paused()
## 游戏恢复
signal game_resumed()
## 游戏结束 (reason: String)
signal game_ended(reason: String)

# === 生命周期 ===

func _ready() -> void:
	print("[GlobalSignals] Event bus initialized — 20+ signals defined")