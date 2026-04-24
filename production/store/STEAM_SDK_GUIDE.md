# Steam SDK Integration Guide

**Story**: steam-001
**Date**: 2026-04-25

---

## Steamworks 功能清单

| 功能 | 必需性 | 实现难度 | 本 Sprint |
|------|--------|----------|-----------|
| **Steam App ID** | Required | Easy | ✅ Must |
| **Steam Init** | Required | Medium | ✅ Must |
| **Cloud Save** | Optional | Medium | ❌ Deferred |
| **Achievements** | Optional | Medium | ❌ Deferred |
| **Stats/Leaderboards** | Optional | Hard | ❌ Deferred |
| **Workshop** | Optional | Hard | ❌ Deferred |

---

## 准备工作

### 1. Steamworks 账号

- 注册 Steamworks 开发者账号: https://partner.steamgames.com/
- 支付 $100 注册费
- 创建新 App，获取 **App ID**

### 2. 获取 App ID

假设 App ID: `YOUR_APP_ID` (需替换为实际 ID)

---

## Godot Steam 集成方案

### 方案 A: GodotSteam GDExtension (推荐)

**优点**: 官方支持，功能完整
**缺点**: 需要下载 GDExtension 文件

#### 安装步骤

1. **下载 GodotSteam**

```
URL: https://github.com/GodotSteam/GodotSteam/releases
选择: Godot 4.x 版本
文件: godotsteam-gdextension.zip
```

2. **解压到项目**

```
解压到: D:\ai\Claude-Code-Game-Studios\addons\godotsteam\
```

3. **启用插件**

在 `project.godot` 添加:

```ini
[gd_extensions]

godotsteam="res://addons/godotsteam/godotsteam.gdextension"
```

---

### 方案 B: Steam DLL 手动加载

**优点**: 无需额外文件
**缺点**: 功能较少

#### 步骤

1. 安装 Steam SDK: https://partner.steamgames.com/downloads/sdk
2. 复制 `steam_api.dll` 到项目根目录
3. 创建 GDScript 加载:

```gdscript
# steam_integration.gd
extends Node

var _steam_api: Object = null

func _ready() -> void:
    if OS.has_feature("steam"):
        _init_steam()

func _init_steam() -> void:
    # Steam API 初始化
    var app_id: int = YOUR_APP_ID
    print("[Steam] Initializing with App ID: %d" % app_id)
    # ... Steam API calls
```

---

## Steam Manager 实现

创建 `src/platform/steam_manager.gd`:

```gdscript
# steam_manager.gd
# Steam Manager — Steamworks integration

class_name SteamManager extends Node

# === 配置 ===
const STEAM_APP_ID: int = YOUR_APP_ID  # 替换为实际 App ID

# === 信号 ===
signal steam_initialized(success: bool)
signal steam_error(error_message: String)

# === 状态 ===
var _is_initialized: bool = false
var _steam_id: int = 0

func _ready() -> void:
    # 检查是否在 Steam 环境运行
    if not OS.has_feature("steam"):
        push_warning("[SteamManager] Not running in Steam environment")
        return
    
    # 初始化 Steam
    _init_steam()

func _init_steam() -> void:
    # GodotSteam 初始化调用
    # 具体 API 取决于使用的 GDExtension
    
    _is_initialized = true
    _steam_id = _get_steam_id()
    
    steam_initialized.emit(true)
    print("[SteamManager] Initialized — Steam ID: %d" % _steam_id)

func _get_steam_id() -> int:
    # 获取用户 Steam ID
    # GodotSteam API call
    return 0  # Placeholder

# === 公共 API ===

func is_initialized() -> bool:
    return _is_initialized

func get_steam_id() -> int:
    return _steam_id

func get_user_name() -> String:
    if not _is_initialized:
        return ""
    # GodotSteam API call
    return "Player"

func cloud_save(key: String, data: Dictionary) -> bool:
    if not _is_initialized:
        return false
    # Cloud save implementation
    return true

func cloud_load(key: String) -> Dictionary:
    if not _is_initialized:
        return {}
    # Cloud load implementation
    return {}
```

---

## project.godot 配置

添加 Steam 管理器 Autoload:

```ini
[autoload]

SteamManager="*res://src/platform/steam_manager.gd"
```

---

## Steam App ID 文件

创建 `steam_appid.txt` (放在项目根目录，发布时打包):

```
YOUR_APP_ID
```

---

## 测试 Steam 集成

### 1. 本地测试模式

不连接 Steam 服务器，使用本地模拟:

```gdscript
# 在 steam_manager.gd 中添加
func _ready() -> void:
    if OS.is_debug_build():
        # Debug mode: use local test
        _test_mode = true
        _is_initialized = true
        print("[SteamManager] Test mode initialized")
        return
    
    # Normal Steam init
    _init_steam()
```

### 2. Steam 客户端测试

1. 启动 Steam 客户端
2. 登录账号
3. 运行游戏
4. 检查 Steam API 调用

---

## Steamworks Dashboard 配置

### 必需配置项

| 配置 | 位置 | 说明 |
|------|------|------|
| App ID | App Admin | 创建后获得 |
| App Name | App Admin | 铁锈魔潮 |
| Store Page | Store Page Editor | 商店页面 |
| Depots | Depots | 上传构建 |
| Achievements | Stats & Achievements | 可选 |
| Cloud Save | Cloud | 可选 |

---

## 构建上传

### 1. 创建 Depot

- 在 Steamworks 创建 Depot
- 配置 Depot ID

### 2. 使用 SteamCMD 上传

```bash
# 下载 SteamCMD
steamcmd

# 登录
login YOUR_STEAM_ACCOUNT

# 上传构建
run_app_build YOUR_APP_ID -desc "Release Build"
```

### 3. 或使用 Godot Export

- 配置 Steam Export Template
- 直接上传

---

## 检查清单

| 项目 | 状态 |
|------|------|
| Steamworks 账号注册 | ⏳ Pending |
| App ID 获取 | ⏳ Pending |
| GodotSteam 下载安装 | ⏳ Pending |
| SteamManager 实现 | ⏳ Pending |
| steam_appid.txt 创建 | ⏳ Pending |
| 本地测试验证 | ⏳ Pending |
| Steam 客户端测试 | ⏳ Pending |
| 构建上传 Steamworks | ⏳ Pending |

---

## 费用

| 项目 | 费用 |
|------|------|
| Steamworks 注册 | $100 (一次性) |
| 后续发布 | 免费 |

---

## 参考资料

- GodotSteam: https://github.com/GodotSteam/GodotSteam
- Steamworks SDK: https://partner.steamgames.com/downloads/sdk
- Steamworks 文档: https://partner.steamgames.com/doc/

---

*Steam SDK Integration Guide — steam-001*