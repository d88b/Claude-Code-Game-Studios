# LocalizationManager.gd
# 本地化管理器 — 加载翻译文件并提供 tr() 功能
## LocalizationManager — Translation file loader and tr() wrapper

class_name LocalizationManager extends Node

# === 配置 ===
const DEFAULT_LOCALE: String = "zh"  # 默认中文
const FALLBACK_LOCALE: String = "en"
const STRING_TABLE_PATH: String = "res://assets/data/strings/strings-{locale}.json"

# === 状态 ===
var current_locale: String = DEFAULT_LOCALE
var _string_table: Dictionary = {}
var _is_loaded: bool = false

# === 信号 ===
signal locale_changed(new_locale: String)

# === 初始化 ===

func _ready() -> void:
	# 加载默认语言
	load_locale(DEFAULT_LOCALE)
	print("[LocalizationManager] Initialized — locale=%s, strings=%d" % [current_locale, _string_table.size()])

## 加载指定语言的字符串表
func load_locale(locale_code: String) -> bool:
	var path: String = STRING_TABLE_PATH.replace("{locale}", locale_code)

	# 尝试加载 JSON 文件
	if not FileAccess.file_exists(path):
		push_warning("[LocalizationManager] String table not found: %s" % path)
		# 尝试 fallback
		if locale_code != FALLBACK_LOCALE:
			return load_locale(FALLBACK_LOCALE)
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[LocalizationManager] Failed to open: %s" % path)
		return false

	var json_text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: int = json.parse(json_text)
	if parse_result != OK:
		push_error("[LocalizationManager] JSON parse error at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return false

	var data: Dictionary = json.get_data()
	if not data.has("strings"):
		push_error("[LocalizationManager] Invalid string table format — missing 'strings' key")
		return false

	_string_table = data.get("strings", {})
	current_locale = locale_code
	_is_loaded = true

	locale_changed.emit(locale_code)
	print("[LocalizationManager] Loaded locale=%s, entries=%d" % [locale_code, _string_table.size()])
	return true

## 切换语言
func set_locale(locale_code: String) -> bool:
	if locale_code == current_locale:
		return true
	return load_locale(locale_code)

## 获取当前语言
func get_locale() -> String:
	return current_locale

## 获取翻译字符串（核心 tr() 函数）
## @param key: 字符串键名，格式 "category.subcategory.description"
## @return: 翻译后的字符串，如果键不存在则返回键名本身
func tr(key: String) -> String:
	if not _is_loaded:
		push_warning("[LocalizationManager] String table not loaded, returning key: %s" % key)
		return key

	if not _string_table.has(key):
		push_warning("[LocalizationManager] Key not found: %s" % key)
		return key

	var entry: Dictionary = _string_table.get(key, {})
	if not entry.has("source"):
		push_warning("[LocalizationManager] Entry missing 'source': %s" % key)
		return key

	return entry.get("source", key)

## 获取带占位符替换的翻译字符串
## @param key: 字符串键名
## @param placeholders: 占位符字典 {"name": value}
## @return: 格式化后的翻译字符串
func tr_format(key: String, placeholders: Dictionary) -> String:
	var template: String = tr(key)

	for placeholder_name: String in placeholders:
		var placeholder_value: String = str(placeholders.get(placeholder_name, ""))
		# 替换 {placeholder_name} 格式的占位符
		template = template.replace("{" + placeholder_name + "}", placeholder_value)

	return template

## 获取字符串条目的上下文信息（供翻译者参考）
func get_context(key: String) -> String:
	if not _string_table.has(key):
		return ""

	var entry: Dictionary = _string_table.get(key, {})
	return entry.get("context", "")

## 检查键是否存在
func has_key(key: String) -> bool:
	return _string_table.has(key)

## 获取所有键名
func get_all_keys() -> Array:
	return _string_table.keys()

## 获取字符串表大小
func get_string_count() -> int:
	return _string_table.size()