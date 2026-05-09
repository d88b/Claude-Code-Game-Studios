"""更新舔食者场景文件以适配新的紧凑精灵图集"""
import re

SCENE_PATH = "./scenes/licker.tscn"

# 读取原始文件
with open(SCENE_PATH, 'r', encoding='utf-8') as f:
    content = f.read()

# 定义新的帧尺寸
OLD_W, OLD_H = 768, 512
NEW_W, NEW_H = 200, 320

# 更新所有 AtlasTexture 的 region
# 格式: region = Rect2(x, 0, 768, 512) -> region = Rect2(new_x, 0, 200, 320)
def update_region(match):
    x = int(match.group(1))
    # 计算新的 x 偏移
    frame_index = x // OLD_W
    new_x = frame_index * NEW_W
    return f"region = Rect2({new_x}, 0, {NEW_W}, {NEW_H})"

content = re.sub(r'region = Rect2\((\d+), 0, \d+, \d+\)', update_region, content)

# 调整缩放比例
# 原来: 0.18 * 768 = 138px 显示宽度
# 现在: 0.6 * 200 = 120px 显示宽度 (保持相似的视觉大小)
content = content.replace('scale = Vector2(0.18, 0.18)', 'scale = Vector2(0.6, 0.6)')

# 调整碰撞形状以匹配新尺寸
# 原来: Vector2(200, 80) 对应 768x512 帧
# 现在: Vector2(80, 50) 对应 200x320 帧，保持比例
content = content.replace('size = Vector2(200, 80)', 'size = Vector2(80, 50)')

# 调整碰撞形状位置
content = content.replace('position = Vector2(0, 40)', 'position = Vector2(0, 20)')

# 调整 HitParticles 位置
content = content.replace('position = Vector2(0, 50)', 'position = Vector2(0, 25)')

# 写入更新后的文件
with open(SCENE_PATH, 'w', encoding='utf-8') as f:
    f.write(content)

print("场景文件已更新！")
print(f"帧尺寸: {OLD_W}x{OLD_H} -> {NEW_W}x{NEW_H}")
print(f"缩放比例: 0.18 -> 0.6")
print(f"碰撞形状: Vector2(200, 80) -> Vector2(80, 50)")
