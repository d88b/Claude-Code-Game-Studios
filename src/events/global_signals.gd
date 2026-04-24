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
## 魔能耗尽警告 (触发阈值 10%)
signal magic_depleted()
## 战车状态变化 (state: int — VehicleState enum value)
signal vehicle_state_changed(state: int)
## 战车被摧毁 (vehicle_id: int)
signal vehicle_destroyed(vehicle_id: int)

# === 敌人系统信号 ===
## 敌人被生成 (enemy_id: int, position: Vector2)
signal enemy_spawned(enemy_id: int, position: Vector2)
## 敌人被消灭 (enemy_id: int)
signal enemy_killed(enemy_id: int)
## Elite/Boss 敌人出现 (enemy_id: int, tier: int) — HUD 警告用
signal elite_spawned(enemy_id: int, tier: int)

# === 区域系统信号 ===
## 进入新区域 (area_id: int, area_name: String)
signal area_entered(area_id: int, area_name: String)
## 离开区域 (area_id: int)
signal area_exited(area_id: int)

# === 撤退系统信号 ===
## 撤退阈值触发 (reason: String)
signal retreat_threshold_reached(reason: String)
## 撤退警告解除 (conditions normalized)
signal retreat_warning_cleared()
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
## 设施被摧毁 (facility_id: int, position: Vector2i)
signal facility_destroyed(facility_id: int, position: Vector2i)
## 设施状态变化 (facility_id: int, new_state: int)
signal facility_state_changed(facility_id: int, new_state: int)

# === 建造系统信号 ===
## 建造开始 (item_id: int, position: Vector2i)
signal build_started(item_id: int, position: Vector2i)
## 建造完成 (item_id: int, position: Vector2i)
signal build_completed(item_id: int, position: Vector2i)

# === 战斗系统信号 ===
## 武器开火 (weapon_id: int, position: Vector2)
signal weapon_fired(weapon_id: int, position: Vector2)
## 炮塔开火 (turret_id: int, position: Vector2, direction: Vector2)
signal turret_fired(turret_id: int, position: Vector2, direction: Vector2)
## 炮塔命中目标 (turret_id: int, target_id: int, damage: float)
signal turret_hit(turret_id: int, target_id: int, damage: float)
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

# === Tutorial 信号 ===
## 教程步骤提示显示 (text: String)
signal tutorial_prompt_shown(text: String)
## 教程高亮元素显示 (target: String)
signal tutorial_highlight_shown(target: String)
## 教程完成
signal tutorial_completed()
## 教程跳过
signal tutorial_skipped()

# === Credits 信号 ===
## Credits 完成
signal credits_finished()

# === Achievement 信号 ===
## 成绩解锁通知 (achievement_id: String, achievement_name: String)
signal achievement_notification(achievement_id: String, achievement_name: String)

# === Audio 信号 ===
## BGM 变化 (track_name: String)
signal bgm_track_changed(track_name: String)
## 音效播放 (sfx_name: String)
signal sfx_played(sfx_name: String)

# === Analytics 信号 ===
## 探索完成 (success: bool)
signal explore_completed(success: bool)
## 波次完成 (enemies_remaining: int, hp_lost: int)
signal wave_completed(enemies_remaining: int, hp_lost: int)
## 玩家死亡
signal player_death()
## 撤退成功 (hp: int, time_remaining: int)
signal retreat_success(hp: int, time_remaining: int)

# === 生命周期 ===

func _ready() -> void:
	print("[GlobalSignals] Event bus initialized — 35+ signals defined")