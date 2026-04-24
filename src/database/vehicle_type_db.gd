extends Node
# VehicleTypeDB — 战车类型数据库 (Autoload)
## VehicleTypeDB — 战车类型数据库
## 从 entities.yaml 加载战车定义，提供 O(1) 查询接口
## Foundation layer database — 所有战车属性的数据源

# === 状态枚举 ===
enum VehicleState { GARAGE_IDLE, DEPLOYABLE, DEPLOYED, DISABLED, DESTROYED }

# === 阈值常量 ===
## DISABLED 阈值：生命值 < 20%
const DISABLED_THRESHOLD: float = 0.2
## DESTROYED 阈值：生命值 <= 0
const DESTROYED_THRESHOLD: float = 0.0

# === 数据缓存 ===
## 战车数据缓存：{vehicle_id: VehicleStats}
var _vehicles: Dictionary = {}
## 战车数量
var vehicle_count: int = 0

# === 战车定义类 ===
class VehicleStats:
	## 战车类型 ID
	var vehicle_id: int = 0
	## 显示名称 (中文)
	var display_name: String = ""
	## 最大生命值
	var max_health: float = 100.0
	## 护甲值
	var armor: float = 0.0
	## 魔能池容量
	var magic_pool: float = 100.0
	## 最大速度
	var max_speed: float = 200.0
	## 加速度
	var acceleration_rate: float = 500.0

# === 初始化 ===

func _ready() -> void:
	_build_cache()
	print("[VehicleTypeDB] initialized with vehicle_count=", vehicle_count)

func _build_cache() -> void:
	_create_mvp_vehicles()

func _create_mvp_vehicles() -> void:
	# 默认战车 (1)
	var default_vehicle: VehicleStats = VehicleStats.new()
	default_vehicle.vehicle_id = 1
	default_vehicle.display_name = "基础战车"
	default_vehicle.max_health = 100.0
	default_vehicle.armor = 5.0
	default_vehicle.magic_pool = 100.0
	default_vehicle.max_speed = 200.0
	default_vehicle.acceleration_rate = 500.0
	_vehicles[1] = default_vehicle

	# 重甲战车 (2)
	var heavy: VehicleStats = VehicleStats.new()
	heavy.vehicle_id = 2
	heavy.display_name = "重甲战车"
	heavy.max_health = 200.0
	heavy.armor = 15.0
	heavy.magic_pool = 80.0
	heavy.max_speed = 150.0
	heavy.acceleration_rate = 300.0
	_vehicles[2] = heavy

	# 快速战车 (3)
	var fast: VehicleStats = VehicleStats.new()
	fast.vehicle_id = 3
	fast.display_name = "快速战车"
	fast.max_health = 80.0
	fast.armor = 2.0
	fast.magic_pool = 120.0
	fast.max_speed = 300.0
	fast.acceleration_rate = 800.0
	_vehicles[3] = fast

	vehicle_count = _vehicles.size()

# === 查询 API ===

## 获取战车属性 — 返回 null 表示无效 ID
func get_vehicle_stats(vehicle_id: int) -> VehicleStats:
	return _vehicles.get(vehicle_id, null)

## 获取显示名称
func get_display_name(vehicle_id: int) -> String:
	var stats: VehicleStats = get_vehicle_stats(vehicle_id)
	if stats == null:
		return ""
	return stats.display_name

## 获取所有战车 ID
func get_all_vehicle_ids() -> Array[int]:
	return _vehicles.keys()

# === 状态转换 ===

## 计算给定生命值比例的状态
func calculate_state(health_ratio: float) -> VehicleState:
	if health_ratio <= DESTROYED_THRESHOLD:
		return VehicleState.DESTROYED
	elif health_ratio < DISABLED_THRESHOLD:
		return VehicleState.DISABLED
	else:
		return VehicleState.DEPLOYED

## 检查是否允许从状态 A 转换到状态 B
func can_transition(from: VehicleState, to: VehicleState) -> bool:
	# 状态转换规则：
	# GARAGE_IDLE → DEPLOYABLE (准备部署)
	# DEPLOYABLE → DEPLOYED (部署)
	# DEPLOYED → DISABLED (损伤严重)
	# DISABLED → DESTROYED (彻底损坏)
	# DISABLED → DEPLOYED (修复)
	match from:
		VehicleState.GARAGE_IDLE:
			return to == VehicleState.DEPLOYABLE
		VehicleState.DEPLOYABLE:
			return to == VehicleState.DEPLOYED
		VehicleState.DEPLOYED:
			return to == VehicleState.DISABLED or to == VehicleState.DESTROYED
		VehicleState.DISABLED:
			return to == VehicleState.DESTROYED or to == VehicleState.DEPLOYED
		VehicleState.DESTROYED:
			return false  # 无法转换
	return false