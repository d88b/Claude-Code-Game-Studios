"""
封面图生成器 - 为铁锈魔潮生成 Steam/Epic 封面图
使用程序化方式创建宣传图
"""

import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# 输出目录
OUTPUT_DIR = "D:/ai/Claude-Code-Game-Studios/assets/keyart"

# 颜色定义（末世废土风格）
COLORS = {
    "bg_base": (45, 35, 30),          # 深棕背景
    "bg_gradient_top": (60, 50, 45),  # 渐变顶部
    "bg_gradient_bot": (30, 25, 20),  # 渐变底部
    "wasteland": (80, 70, 60),        # 废土色
    "rust": (120, 80, 60),            # 锈红色
    "magic_blue": (100, 150, 220),    # 魔导蓝
    "magic_glow": (150, 200, 255),    # 魔导光芒
    "zombie_dark": (70, 90, 70),      # 僵尸暗绿
    "vehicle_body": (90, 90, 100),    # 战车金属灰
    "vehicle_accent": (70, 70, 80),   # 战车深灰
    "title_main": (220, 180, 140),    # 标题主色（锈金）
    "title_shadow": (30, 25, 20),     # 标题阴影
}

# 封面尺寸规格
SIZES = {
    "capsule_main": (616, 353),    # Steam 主封面
    "capsule_small": (200, 112),   # Steam 小封面
    "capsule_header": (460, 215),  # Steam 头部封面
    "epic_main": (1920, 1080),    # Epic 主图
    "epic_small": (256, 256),     # Epic 小图
}

def create_gradient_background(width, height):
    """创建渐变背景"""
    img = Image.new('RGB', (width, height))
    for y in range(height):
        # 从顶部到底部渐变
        ratio = y / height
        r = int(COLORS["bg_gradient_top"][0] * (1 - ratio) + COLORS["bg_gradient_bot"][0] * ratio)
        g = int(COLORS["bg_gradient_top"][1] * (1 - ratio) + COLORS["bg_gradient_bot"][1] * ratio)
        b = int(COLORS["bg_gradient_top"][2] * (1 - ratio) + COLORS["bg_gradient_bot"][2] * ratio)
        for x in range(width):
            img.putpixel((x, y), (r, g, b))
    return img

def draw_wasteland_ground(draw, width, height):
    """绘制废土地面"""
    ground_y = int(height * 0.65)
    # 地面渐变
    for y in range(ground_y, height):
        ratio = (y - ground_y) / (height - ground_y)
        color = (
            int(COLORS["wasteland"][0] * (1 - ratio * 0.3)),
            int(COLORS["wasteland"][1] * (1 - ratio * 0.3)),
            int(COLORS["wasteland"][2] * (1 - ratio * 0.3)),
        )
        draw.line([(0, y), (width, y)], fill=color)

    # 添加一些废土纹理（随机点）
    import random
    random.seed(42)
    for _ in range(width * 2):
        x = random.randint(0, width - 1)
        y = random.randint(ground_y, height - 1)
        size = random.randint(1, 3)
        darkness = random.randint(0, 30)
        color = (
            COLORS["wasteland"][0] - darkness,
            COLORS["wasteland"][1] - darkness,
            COLORS["wasteland"][2] - darkness,
        )
        draw.rectangle([x, y, x + size, y + size], fill=color)

def draw_vehicle(draw, center_x, center_y, scale=1.0):
    """绘制战车"""
    # 战车尺寸（基础尺寸 * 缩放）
    body_w = int(120 * scale)
    body_h = int(50 * scale)
    turret_w = int(60 * scale)
    turret_h = int(30 * scale)
    gun_len = int(80 * scale)
    wheel_r = int(12 * scale)

    # 战车主体
    body_x = center_x - body_w // 2
    body_y = center_y - body_h // 2
    draw.rectangle([body_x, body_y, body_x + body_w, body_y + body_h],
                   fill=COLORS["vehicle_body"])
    draw.rectangle([body_x + 5*scale, body_y + 5*scale, body_x + body_w - 5*scale, body_y + body_h - 5*scale],
                   fill=(110, 110, 120))  # 高光

    # 炮塔
    turret_x = center_x - turret_w // 2
    turret_y = body_y - turret_h
    draw.rectangle([turret_x, turret_y, turret_x + turret_w, turret_y + turret_h],
                   fill=COLORS["vehicle_accent"])

    # 炮管
    draw.rectangle([center_x, turret_y + turret_h//3, center_x + gun_len, turret_y + turret_h*2//3],
                   fill=COLORS["vehicle_accent"])

    # 魔导光芒效果（炮管末端）
    glow_x = center_x + gun_len
    glow_y = turret_y + turret_h // 2
    for r in range(int(15 * scale), 0, -2):
        alpha = int(255 * (r / (15 * scale)))
        glow_color = (
            COLORS["magic_glow"][0],
            COLORS["magic_glow"][1],
            COLORS["magic_glow"][2],
        )
        draw.ellipse([glow_x - r, glow_y - r, glow_x + r, glow_y + r],
                     fill=glow_color)

    # 车轮
    wheel_positions = [body_x + 20*scale, body_x + 50*scale, body_x + 80*scale, body_x + 100*scale]
    for wx in wheel_positions:
        draw.ellipse([wx - wheel_r, center_y + body_h//2 - wheel_r//2,
                      wx + wheel_r, center_y + body_h//2 + wheel_r//2],
                     fill=(50, 50, 55))

def draw_zombie_silhouettes(draw, width, height, count=5):
    """绘制僵尸剪影"""
    import random
    random.seed(123)

    for i in range(count):
        # 僵尸位置（分散在背景）
        x = random.randint(width // 4, width - width // 4)
        y = random.randint(int(height * 0.5), int(height * 0.85))

        # 僵尸大小（远小近大）
        depth = (y - height * 0.5) / (height * 0.35)
        size = int(20 + 40 * depth)

        # 僵尸剪影
        darkness = int(70 - 30 * depth)
        color = (darkness, darkness + 20, darkness)

        # 头
        draw.ellipse([x - size//4, y - size, x + size//4, y - size//2], fill=color)
        # 身体
        draw.rectangle([x - size//3, y - size//2, x + size//3, y + size//2], fill=color)
        # 腿
        draw.rectangle([x - size//4, y + size//2, x - size//8, y + size], fill=color)
        draw.rectangle([x + size//8, y + size//2, x + size//4, y + size], fill=color)

def draw_title(draw, width, height, title_en, title_zh, scale=1.0):
    """绘制游戏标题"""
    # 尝试加载字体，如果没有则使用默认
    try:
        # 使用系统字体
        font_size_main = int(48 * scale)
        font_size_sub = int(24 * scale)
        font_main = ImageFont.truetype("arial.ttf", font_size_main)
        font_sub = ImageFont.truetype("arial.ttf", font_size_sub)
    except:
        font_main = ImageFont.load_default()
        font_sub = ImageFont.load_default()

    # 标题位置（顶部居中）
    title_y = int(height * 0.08)

    # 英文标题
    bbox_en = draw.textbbox((0, 0), title_en, font=font_main)
    text_w_en = bbox_en[2] - bbox_en[0]
    text_x = (width - text_w_en) // 2

    # 标题阴影
    draw.text((text_x + 2, title_y + 2), title_en, font=font_main, fill=COLORS["title_shadow"])
    draw.text((text_x, title_y), title_en, font=font_main, fill=COLORS["title_main"])

    # 中文标题（下方）
    bbox_zh = draw.textbbox((0, 0), title_zh, font=font_sub)
    text_w_zh = bbox_zh[2] - bbox_zh[0]
    text_x_zh = (width - text_w_zh) // 2
    draw.text((text_x_zh + 1, title_y + font_size_main + 4), title_zh, font=font_sub,
              fill=COLORS["title_shadow"])
    draw.text((text_x_zh, title_y + font_size_main + 3), title_zh, font=font_sub,
              fill=COLORS["title_main"])

def create_keyart(width, height, name):
    """创建封面图"""
    # 创建渐变背景
    img = create_gradient_background(width, height)
    draw = ImageDraw.Draw(img)

    # 绘制废土地面
    draw_wasteland_ground(draw, width, height)

    # 计算缩放比例
    scale = min(width / 616, height / 353)

    # 绘制僵尸剪影（背景）
    zombie_count = max(3, int(8 * scale))
    draw_zombie_silhouettes(draw, width, height, zombie_count)

    # 绘制战车（前景中央）
    vehicle_x = width // 2
    vehicle_y = int(height * 0.6)
    draw_vehicle(draw, vehicle_x, vehicle_y, scale * 1.2)

    # 绘制标题
    draw_title(draw, width, height, "RUST MAGIC TIDE", "铁锈魔潮", scale)

    # 添加魔导光芒氛围（角落）
    glow_positions = [
        (int(width * 0.15), int(height * 0.3)),
        (int(width * 0.85), int(height * 0.25)),
    ]
    for gx, gy in glow_positions:
        glow_size = int(40 * scale)
        for r in range(glow_size, 0, -4):
            alpha_ratio = r / glow_size
            color = (
                int(COLORS["magic_glow"][0] * alpha_ratio * 0.3),
                int(COLORS["magic_glow"][1] * alpha_ratio * 0.3),
                int(COLORS["magic_glow"][2] * alpha_ratio * 0.3),
            )
            draw.ellipse([gx - r, gy - r, gx + r, gy + r], fill=color)

    return img

def main():
    # 创建输出目录
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    print("开始生成封面图...")

    # 生成所有尺寸的封面图
    for name, size in SIZES.items():
        img = create_keyart(size[0], size[1], name)
        filepath = os.path.join(OUTPUT_DIR, f"{name}.png")
        img.save(filepath, "PNG")
        file_size = os.path.getsize(filepath)
        print(f"[OK] {name}.png ({size[0]}x{size[1]}) - {file_size // 1024}KB")

    print(f"\n完成！共生成 5 张封面图")
    print(f"保存位置: {OUTPUT_DIR}")

if __name__ == "__main__":
    main()