extends Node

## 资源管理器 — 追踪玩家资源数量（全局单例 Autoload）

var inventory: Dictionary = {}

signal resource_changed(item_id: String, new_amount: int)
signal resource_collected(item_id: String, amount: int)

func _ready():
	pass

func add_item(item: ItemData, amount: int = 1) -> void:
	var current = inventory.get(item.id, 0)
	inventory[item.id] = current + amount
	resource_changed.emit(item.id, inventory[item.id])
	resource_collected.emit(item.id, amount)

func get_amount(item_id: String) -> int:
	return inventory.get(item_id, 0)

func has_item(item_id: String, amount: int = 1) -> bool:
	return inventory.get(item_id, 0) >= amount

func remove_item(item: ItemData, amount: int = 1) -> void:
	var current = inventory.get(item.id, 0)
	if current < amount:
		push_warning("Not enough %s to remove. Have %d, need %d" % [item.id, current, amount])
		return
	inventory[item.id] = current - amount
	resource_changed.emit(item.id, inventory[item.id])

func clear_inventory() -> void:
	inventory.clear()
