# Credits Sequence Design

**铁锈魔潮 (Rust Magic Tide)**

---

## Credits 结构

### Section 1: 游戏信息

```
铁锈魔潮
RUST MAGIC TIDE

Version 0.1.0-alpha
© 2026 [Developer Name]
```

---

### Section 2: 开发团队

```
DEVELOPMENT

Game Design
[Name]

Programming
[Name]

Art & Visuals
[Name] (if applicable)

Audio
[Name] (if applicable)

QA & Testing
[Name] (if applicable)
```

---

### Section 3: 工具与技术

```
TOOLS & TECHNOLOGY

Engine
Godot 4.6

Testing Framework
GUT (Godot Unit Testing)

Special Thanks
Godot Community
GUT Contributors
```

---

### Section 4: 法律信息

```
LEGAL

EULA: legal/EULA.md
Privacy Policy: legal/PRIVACY_POLICY.md
Age Ratings: ESRB Teen, PEGI 12

Third-Party Licenses
- Godot Engine (MIT License)
- GUT (MIT License)
```

---

### Section 5: 结尾

```
THANK YOU FOR PLAYING

铁锈魔潮
RUST MAGIC TIDE

www.[developer-domain].com
```

---

## Implementation

### Credits Scene

创建 `src/ui/credits_screen.tscn`:

```
结构:
- CanvasLayer
  - ScrollContainer
    - VBoxContainer
      - 标题 Label
      - 开发团队 Section
      - 工具技术 Section
      - 法律信息 Section
      - 结尾感谢 Section
```

### Credits Controller

```gdscript
# src/ui/credits_screen.gd
extends Control

@onready var _scroll_container: ScrollContainer = $ScrollContainer
@onready var _vbox: VBoxContainer = $ScrollContainer/VBoxContainer

const SCROLL_SPEED: float = 50.0  # pixels per second

func _process(delta: float) -> void:
    # 自动滚动
    _scroll_container.scroll_vertical += int(SCROLL_SPEED * delta)
    
    # 检测底部，循环或结束
    if _scroll_container.scroll_vertical >= _scroll_container.get_scroll_max():
        # 到达底部，可选: 循环或返回菜单
        _on_credits_complete()

func _on_credits_complete() -> void:
    # 返回主菜单或关闭
    hide()
    # 发送信号通知 credits 完成

func _on_skip_button_pressed() -> void:
    # 按键跳过
    _on_credits_complete()
```

---

## Credits 触发时机

| 触发 | 说明 |
|------|------|
| **游戏通关** | 主线完成后显示 |
| **主菜单选项** | 可随时查看 |
| **特殊事件** | 隐藏彩蛋 credits |

---

## 显示方式

### 自动滚动

- Credits 从上到下自动滚动
- 速度: 50 pixels/秒
- 可按 ESC/任意键跳过

### 音乐

- Credits 播放专门的音乐
- 建议: bgm_victory.wav 或 bgm_menu.wav

---

## 文件位置

| 文件 | 路径 |
|------|------|
| Credits Scene | `src/ui/credits_screen.tscn` |
| Credits Script | `src/ui/credits_screen.gd` |
| Credits 文本 | 嵌入在 scene 或单独文件 |

---

## Credits 文本模板

可在 `assets/data/strings/strings-en.json` 添加:

```json
{
  "credits.title": {
    "source": "铁锈魔潮",
    "context": "Credits title, Chinese"
  },
  "credits.title_en": {
    "source": "RUST MAGIC TIDE",
    "context": "Credits title, English"
  },
  "credits.version": {
    "source": "Version 0.1.0-alpha",
    "context": "Version display"
  },
  "credits.development": {
    "source": "DEVELOPMENT",
    "context": "Section header"
  },
  "credits.tools": {
    "source": "TOOLS & TECHNOLOGY",
    "context": "Section header"
  },
  "credits.legal": {
    "source": "LEGAL",
    "context": "Section header"
  },
  "credits.thanks": {
    "source": "THANK YOU FOR PLAYING",
    "context": "Closing message"
  }
}
```

---

*Credits Sequence Design — 铁锈魔潮*