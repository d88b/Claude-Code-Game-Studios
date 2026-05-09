"""
像素艺术生成器 - 为铁锈魔潮生成美术资源
使用程序化方式创建像素精灵
"""

import os
from PIL import Image, ImageDraw

# 输出目录
OUTPUT_DIR = "D:/ai/Claude-Code-Game-Studios/assets/sprites/generated"

# 像素艺术颜色定义（末世废土风格）
COLORS = {
    # 战车颜色
    "vehicle_body": (80, 80, 90),       # 暗灰金属
    "vehicle_turret": (60, 60, 70),     # 深灰炮塔
    "vehicle_wheel": (50, 50, 55),      # 车轮
    "vehicle_highlight": (120, 120, 140), # 高光

    # 敌人颜色（僵尸）
    "zombie_skin": (100, 120, 100),     # 腐烂绿
    "zombie_cloth": (60, 50, 40),       # 破旧衣服
    "zombie_eye": (200, 50, 50),        # 红眼

    # 资源颜色
    "crystal": (150, 200, 255),         # 蓝水晶
    "metal": (180, 180, 190),           # 金属
    "organic": (120, 180, 80),          # 有机物
    "fuel": (255, 150, 50),             # 燃料橙
    "rare": (255, 200, 100),            # 稀有金

    # 设施颜色
    "facility_base": (70, 70, 80),      # 基座
    "facility_accent": (100, 150, 200), # 魔导蓝

    # UI 颜色
    "ui_health": (255, 80, 80),         # 红色血量
    "ui_magic": (100, 150, 255),        # 蓝色魔能
    "ui_time": (255, 200, 50),          # 黄色时间
    "ui_warning": (255, 50, 50),        # 红色警告
    "ui_day": (255, 220, 100),          # 白天黄
    "ui_night": (80, 80, 150),          # 夜晚蓝
}

def create_vehicle_sprite():
    """创建战车精灵 (64x48)"""
    img = Image.new('RGBA', (64, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 车身主体
    draw.rectangle([8, 16, 56, 40], fill=COLORS["vehicle_body"])
    draw.rectangle([10, 18, 54, 38], fill=COLORS["vehicle_highlight"])

    # 炮塔
    draw.rectangle([24, 8, 40, 20], fill=COLORS["vehicle_turret"])
    draw.rectangle([40, 12, 56, 16], fill=COLORS["vehicle_turret"])  # 炮管

    # 车轮
    for x in [12, 24, 40, 52]:
        draw.rectangle([x, 36, x+6, 44], fill=COLORS["vehicle_wheel"])

    return img

def create_enemy_sprite(enemy_type=0):
    """创建敌人精灵 (32x48) - 僵尸变体"""
    img = Image.new('RGBA', (32, 48), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 头部
    draw.rectangle([8, 4, 24, 20], fill=COLORS["zombie_skin"])
    # 眼睛
    draw.rectangle([10, 8, 14, 12], fill=COLORS["zombie_eye"])
    draw.rectangle([18, 8, 22, 12], fill=COLORS["zombie_eye"])

    # 身体
    draw.rectangle([6, 20, 26, 36], fill=COLORS["zombie_cloth"])

    # 腿
    draw.rectangle([8, 36, 14, 48], fill=COLORS["zombie_cloth"])
    draw.rectangle([18, 36, 24, 48], fill=COLORS["zombie_cloth"])

    # 变体：添加不同特征
    if enemy_type == 1:  # 大僵尸
        draw.rectangle([4, 0, 28, 24], fill=COLORS["zombie_skin"])  # 大头
    elif enemy_type == 2:  # 快僵尸
        draw.rectangle([10, 10, 12, 14], fill=(255, 100, 100))  # 更亮的眼睛
    elif enemy_type == 3:  # 强僵尸
        draw.rectangle([6, 16, 26, 38], fill=(80, 100, 80))  # 更强壮
    elif enemy_type == 4:  # 毒僵尸
        draw.rectangle([12, 6, 20, 10], fill=(50, 200, 50))  # 绿眼睛

    return img

def create_resource_sprite(resource_type=0):
    """创建资源掉落精灵 (16x16)"""
    img = Image.new('RGBA', (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    colors = [
        COLORS["crystal"],
        COLORS["metal"],
        COLORS["organic"],
        COLORS["fuel"],
        COLORS["rare"]
    ]

    color = colors[resource_type % 5]

    # 中心宝石形状
    draw.rectangle([4, 2, 12, 14], fill=color)
    # 高光
    draw.rectangle([6, 4, 10, 8], fill=(min(color[0]+50, 255), min(color[1]+50, 255), min(color[2]+50, 255)))

    return img

def create_facility_sprite(facility_type=0):
    """创建设施精灵 (32x32)"""
    img = Image.new('RGBA', (32, 32), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    # 基座
    draw.rectangle([4, 16, 28, 28], fill=COLORS["facility_base"])

    # 不同设施类型
    if facility_type == 0:  # 炮塔
        draw.rectangle([12, 4, 20, 16], fill=COLORS["facility_accent"])
        draw.rectangle([20, 8, 28, 12], fill=COLORS["facility_accent"])
    elif facility_type == 1:  # 工坊
        draw.rectangle([8, 8, 24, 16], fill=(100, 80, 60))
    elif facility_type == 2:  # 仓库
        draw.rectangle([6, 4, 26, 16], fill=(80, 80, 100))
    elif facility_type == 3:  # 发电机
        draw.rectangle([10, 6, 22, 16], fill=COLORS["facility_accent"])
        draw.rectangle([14, 2, 18, 6], fill=(200, 200, 100))
    elif facility_type == 4:  # 障碍
        draw.rectangle([6, 6, 26, 26], fill=(100, 100, 100))

    return img

def create_ui_icon(icon_type=0):
    """创建 UI 图标精灵 (24x24)"""
    img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    colors = [
        COLORS["ui_health"],
        COLORS["ui_magic"],
        COLORS["ui_time"],
        COLORS["ui_warning"],
        COLORS["ui_day"],
        COLORS["ui_night"],
        (200, 200, 200),  # 指针
        (150, 150, 150),  # 光标
    ]

    color = colors[icon_type % 8]

    # 简单圆形图标
    draw.ellipse([4, 4, 20, 20], fill=color)

    # 不同图标特征
    if icon_type == 0:  # 血量 - 心形
        draw.rectangle([8, 8, 16, 16], fill=(min(color[0]+30, 255), min(color[1]+30, 255), min(color[2]+30, 255)))
    elif icon_type == 3:  # 警告 - 三角
        draw.polygon([(12, 6), (6, 18), (18, 18)], fill=color)
    elif icon_type == 4:  # 白天 - 太阳
        draw.rectangle([6, 6, 18, 18], fill=color)
    elif icon_type == 5:  # 夜晚 - 月亮
        draw.ellipse([6, 6, 18, 18], fill=color)
        draw.ellipse([10, 6, 18, 18], fill=(0, 0, 0, 0))

    return img

def main():
    # 创建输出目录
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("开始生成像素艺术资源...")

    # 生成战车精灵
    vehicle = create_vehicle_sprite()
    vehicle.save(os.path.join(OUTPUT_DIR, "vehicle_body.png"))
    print("[OK] vehicle_body.png (64x48)")

    # 生成敌人精灵（5个变体）
    for i in range(5):
        enemy = create_enemy_sprite(i)
        enemy.save(os.path.join(OUTPUT_DIR, f"enemy_zombie_{i}.png"))
    print("[OK] enemy_zombie_0-4.png (32x48) x5")

    # 生成资源精灵（5种类型）
    for i in range(5):
        resource = create_resource_sprite(i)
        resource.save(os.path.join(OUTPUT_DIR, f"resource_type_{i}.png"))
    print("[OK] resource_type_0-4.png (16x16) x5")

    # 生成设施精灵（5种类型）
    for i in range(5):
        facility = create_facility_sprite(i)
        facility.save(os.path.join(OUTPUT_DIR, f"facility_type_{i}.png"))
    print("[OK] facility_type_0-4.png (32x32) x5")

    # 生成 UI 图标（8种）
    for i in range(8):
        icon = create_ui_icon(i)
        icon.save(os.path.join(OUTPUT_DIR, f"ui_icon_{i}.png"))
    print("[OK] ui_icon_0-7.png (24x24) x8")

    print(f"\n完成！共生成 26 个精灵文件")
    print(f"保存位置: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()