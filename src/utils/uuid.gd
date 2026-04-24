# UUID — 唯一标识符生成器
# 用于生成会话 ID、玩家 ID、崩溃报告 ID 等

class_name UUID

# === 生成 UUID v4 ===

static func generate() -> String:
    # UUID v4 格式: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx
    # y 为 8, 9, a, 或 b

    var bytes: Array[int] = []
    for i in 16:
        bytes.append(randi_range(0, 255))

    # 设置版本位 (version 4)
    bytes[6] = (bytes[6] & 0x0F) | 0x40

    # 设置变体位 (RFC 4122)
    bytes[8] = (bytes[8] & 0x3F) | 0x80

    # 格式化为 UUID 字符串
    var uuid: String = ""
    uuid += "%02x%02x%02x%02x" % [bytes[0], bytes[1], bytes[2], bytes[3]]
    uuid += "-"
    uuid += "%02x%02x" % [bytes[4], bytes[5]]
    uuid += "-"
    uuid += "%02x%02x" % [bytes[6], bytes[7]]
    uuid += "-"
    uuid += "%02x%02x" % [bytes[8], bytes[9]]
    uuid += "-"
    uuid += "%02x%02x%02x%02x%02x%02x" % [bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]]

    return uuid

# === 从文件加载或生成新 UUID ===

static func generate_or_load(file_path: String) -> String:
    if FileAccess.file_exists(file_path):
        var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
        if file != null:
            var id: String = file.get_as_text().strip_edges()
            file.close()
            if not id.is_empty():
                return id

    # 生成新 UUID
    var new_id: String = generate()
    var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
    if file != null:
        file.store_string(new_id)
        file.close()

    return new_id

# === 验证 UUID 格式 ===

static func is_valid(uuid: String) -> bool:
    # UUID v4 格式检查
    var pattern: RegEx = RegEx.new()
    pattern.compile("^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")

    var result: RegExMatch = pattern.search(uuid.to_lower())
    return result != null

# === 生成短 UUID (无连字符) ===

static func generate_short() -> String:
    return generate().replace("-", "")