"""
Trailer 生成器 - 为铁锈魔潮生成宣传视频
使用程序化方式创建帧序列并合成视频
"""

import os
import math
from PIL import Image, ImageDraw, ImageFont

# 输出目录
OUTPUT_DIR = "D:/ai/Claude-Code-Game-Studios/assets/trailer"

# 视频规格
WIDTH = 1920
HEIGHT = 1080
FPS = 30
DURATION = 90  # 秒
TOTAL_FRAMES = FPS * DURATION

# 颜色定义
COLORS = {
    "bg_day": (80, 100, 120),
    "bg_night": (30, 35, 50),
    "bg_bunker": (50, 45, 40),
    "wasteland": (100, 90, 80),
    "vehicle_body": (90, 90, 100),
    "vehicle_accent": (70, 70, 80),
    "magic_glow": (150, 200, 255),
    "zombie_dark": (70, 90, 70),
    "title_main": (220, 180, 140),
    "title_shadow": (30, 25, 20),
    "text_white": (255, 255, 255),
    "text_glow": (100, 150, 220),
}

def lerp(a, b, t):
    """线性插值"""
    return a + (b - a) * t

def lerp_color(c1, c2, t):
    """颜色插值"""
    return (
        int(lerp(c1[0], c2[0], t)),
        int(lerp(c1[1], c2[1], t)),
        int(lerp(c1[2], c2[2], t)),
    )

def create_background(phase, phase_progress):
    """创建背景"""
    img = Image.new('RGB', (WIDTH, HEIGHT))
    draw = ImageDraw.Draw(img)

    if phase == 0:  # Hook - 地堡内部到地表
        bg_color = lerp_color(COLORS["bg_bunker"], COLORS["bg_day"], phase_progress)
    elif phase == 1:  # Exploration - 白天地表
        bg_color = COLORS["bg_day"]
    elif phase == 2:  # Combat - 战斗
        bg_color = COLORS["bg_day"]
    elif phase == 3:  # Building - 地堡内部
        bg_color = COLORS["bg_bunker"]
    elif phase == 4:  # Defense - 夜晚
        bg_color = lerp_color(COLORS["bg_day"], COLORS["bg_night"], phase_progress)
    elif phase == 5:  # Day/Night - 日夜循环
        if phase_progress < 0.33:
            bg_color = COLORS["bg_day"]
        elif phase_progress < 0.66:
            bg_color = lerp_color(COLORS["bg_day"], (120, 80, 50), (phase_progress - 0.33) * 3)
        else:
            bg_color = lerp_color((120, 80, 50), COLORS["bg_night"], (phase_progress - 0.66) * 3)
    else:  # Title
        bg_color = (20, 20, 25)

    draw.rectangle([0, 0, WIDTH, HEIGHT], fill=bg_color)

    # 绘制地面（除了 Title 阶段）
    if phase < 6:
        ground_y = int(HEIGHT * 0.6)
        ground_color = lerp_color(COLORS["wasteland"], bg_color, 0.5)
        draw.rectangle([0, ground_y, WIDTH, HEIGHT], fill=ground_color)

    return img

def draw_vehicle(draw, x, y, scale=1.0, facing_right=True):
    """绘制战车"""
    body_w = int(150 * scale)
    body_h = int(60 * scale)
    turret_w = int(70 * scale)
    turret_h = int(35 * scale)
    gun_len = int(100 * scale)

    # 车身
    body_x = x - body_w // 2
    body_y = y - body_h // 2
    draw.rectangle([body_x, body_y, body_x + body_w, body_y + body_h],
                   fill=COLORS["vehicle_body"])
    draw.rectangle([body_x + int(8*scale), body_y + int(8*scale),
                    body_x + body_w - int(8*scale), body_y + body_h - int(8*scale)],
                   fill=(110, 110, 120))

    # 炮塔
    turret_x = x - turret_w // 2
    turret_y = body_y - turret_h
    draw.rectangle([turret_x, turret_y, turret_x + turret_w, turret_y + turret_h],
                   fill=COLORS["vehicle_accent"])

    # 炮管
    gun_dir = 1 if facing_right else -1
    gun_start = x
    gun_end = x + gun_len * gun_dir
    if gun_end < gun_start:
        gun_start, gun_end = gun_end, gun_start
    draw.rectangle([gun_start, turret_y + turret_h//3,
                    gun_end, turret_y + turret_h*2//3],
                   fill=COLORS["vehicle_accent"])

    # 魔导光芒
    glow_x = x + gun_len * gun_dir
    glow_y = turret_y + turret_h // 2
    for r in range(int(20*scale), 0, -3):
        draw.ellipse([glow_x - r, glow_y - r, glow_x + r, glow_y + r],
                     fill=COLORS["magic_glow"])

def draw_zombie(draw, x, y, scale=1.0):
    """绘制僵尸"""
    size = int(30 * scale)
    color = COLORS["zombie_dark"]

    # 头
    draw.ellipse([x - size//3, y - size, x + size//3, y - size//2], fill=color)
    # 身体
    draw.rectangle([x - size//2, y - size//2, x + size//2, y + size//2], fill=color)
    # 腿
    draw.rectangle([x - size//3, y + size//2, x - size//6, y + size], fill=color)
    draw.rectangle([x + size//6, y + size//2, x + size//3, y + size], fill=color)

def draw_turret_facility(draw, x, y, scale=1.0, shooting=False):
    """绘制炮塔设施"""
    size = int(40 * scale)
    base_color = (70, 70, 80)
    accent_color = COLORS["magic_glow"] if shooting else (100, 150, 200)

    # 基座
    draw.rectangle([x - size, y, x + size, y + size//2], fill=base_color)
    # 炮塔
    draw.rectangle([x - size//2, y - size//2, x + size//2, y], fill=accent_color)
    if shooting:
        # 射击效果
        draw.ellipse([x - size//4, y - size, x + size//4, y - size//2],
                     fill=(255, 200, 100))

def draw_text_overlay(draw, text, y_pos, frame_in_phase, phase_duration):
    """绘制文字叠加"""
    # 文字淡入淡出效果
    fade_frames = phase_duration // 4
    if frame_in_phase < fade_frames:
        alpha = frame_in_phase / fade_frames
    elif frame_in_phase > phase_duration - fade_frames:
        alpha = (phase_duration - frame_in_phase) / fade_frames
    else:
        alpha = 1.0

    # 尝试加载字体
    try:
        font_size = 60
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        font = ImageFont.load_default()

    # 文字位置（居中）
    bbox = draw.textbbox((0, 0), text, font=font)
    text_w = bbox[2] - bbox[0]
    text_x = (WIDTH - text_w) // 2

    # 绘制文字（带发光效果）
    glow_intensity = int(255 * alpha)
    glow_color = (COLORS["text_glow"][0], COLORS["text_glow"][1], COLORS["text_glow"][2])
    text_color = (int(COLORS["text_white"][0] * alpha),
                  int(COLORS["text_white"][1] * alpha),
                  int(COLORS["text_white"][2] * alpha))

    # 发光背景
    if alpha > 0.3:
        for offset in range(10, 0, -2):
            glow_alpha = int(alpha * offset * 5)
            draw.text((text_x + offset, y_pos + offset), text, font=font,
                      fill=(glow_color[0], glow_color[1], glow_color[2]))

    draw.text((text_x, y_pos), text, font=font, fill=text_color)

def draw_title_screen(draw, progress):
    """绘制标题画面"""
    # 标题动画
    try:
        font_main = ImageFont.truetype("arial.ttf", 80)
        font_sub = ImageFont.truetype("arial.ttf", 40)
        font_info = ImageFont.truetype("arial.ttf", 30)
    except:
        font_main = ImageFont.load_default()
        font_sub = ImageFont.load_default()
        font_info = ImageFont.load_default()

    # 标题淡入
    alpha = min(1.0, progress * 2) if progress < 0.5 else 1.0

    # 英文标题
    title_en = "RUST MAGIC TIDE"
    bbox = draw.textbbox((0, 0), title_en, font=font_main)
    text_w = bbox[2] - bbox[0]
    text_x = (WIDTH - text_w) // 2
    text_y = int(HEIGHT * 0.35)

    title_color = (int(COLORS["title_main"][0] * alpha),
                   int(COLORS["title_main"][1] * alpha),
                   int(COLORS["title_main"][2] * alpha))

    # 阴影
    draw.text((text_x + 4, text_y + 4), title_en, font=font_main, fill=COLORS["title_shadow"])
    draw.text((text_x, text_y), title_en, font=font_main, fill=title_color)

    # 中文标题
    title_zh = "铁锈魔潮"
    bbox_zh = draw.textbbox((0, 0), title_zh, font=font_sub)
    text_w_zh = bbox_zh[2] - bbox_zh[0]
    text_x_zh = (WIDTH - text_w_zh) // 2
    draw.text((text_x_zh + 2, text_y + 90), title_zh, font=font_sub, fill=COLORS["title_shadow"])
    draw.text((text_x_zh, text_y + 88), title_zh, font=font_sub, fill=title_color)

    # 发售信息（后半段出现）
    if progress > 0.5:
        info_alpha = (progress - 0.5) * 2
        info_text = "COMING TO STEAM & EPIC"
        bbox_info = draw.textbbox((0, 0), info_text, font=font_info)
        text_w_info = bbox_info[2] - bbox_info[0]
        text_x_info = (WIDTH - text_w_info) // 2
        info_color = (int(255 * info_alpha), int(255 * info_alpha), int(255 * info_alpha))
        draw.text((text_x_info, text_y + 150), info_text, font=font_info, fill=info_color)

def create_frame(frame_num):
    """创建单帧"""
    # 计算当前阶段
    phase_durations = [10, 15, 15, 10, 15, 10, 15]  # 各阶段时长（秒）
    phase_frames = [d * FPS for d in phase_durations]

    current_frame = frame_num
    phase = 0
    frame_in_phase = 0

    for i, pf in enumerate(phase_frames):
        if current_frame < pf:
            phase = i
            frame_in_phase = current_frame
            break
        current_frame -= pf

    phase_duration = phase_frames[phase]
    phase_progress = frame_in_phase / phase_duration if phase_duration > 0 else 0

    # 创建背景
    img = create_background(phase, phase_progress)
    draw = ImageDraw.Draw(img)

    # 根据阶段绘制内容
    if phase == 0:  # Hook - 战车冲出地堡
        vehicle_x = int(lerp(WIDTH * 0.3, WIDTH * 0.5, phase_progress))
        vehicle_y = int(HEIGHT * 0.55)
        draw_vehicle(draw, vehicle_x, vehicle_y, 1.5)

    elif phase == 1:  # Exploration - 战车探索
        vehicle_x = int(WIDTH * 0.5 + math.sin(frame_in_phase / 30) * 100)
        vehicle_y = int(HEIGHT * 0.55)
        draw_vehicle(draw, vehicle_x, vehicle_y, 1.5)
        # 资源掉落
        for i in range(3):
            rx = int(WIDTH * 0.2 + i * WIDTH * 0.25)
            ry = int(HEIGHT * 0.5)
            draw.ellipse([rx - 15, ry - 15, rx + 15, ry + 15], fill=COLORS["magic_glow"])
        draw_text_overlay(draw, "EXPLORE THE WASTELAND", int(HEIGHT * 0.85),
                          frame_in_phase, phase_duration)

    elif phase == 2:  # Combat - 战斗
        vehicle_x = int(WIDTH * 0.4)
        vehicle_y = int(HEIGHT * 0.55)
        shooting = frame_in_phase % 30 < 10
        draw_vehicle(draw, vehicle_x, vehicle_y, 1.5, not shooting)
        # 僵尸
        for i in range(5):
            zx = int(WIDTH * 0.6 + i * 80)
            zy = int(HEIGHT * 0.55 + math.sin(frame_in_phase / 15 + i) * 20)
            draw_zombie(draw, zx, zy, 1.0)
        draw_text_overlay(draw, "MAGITECH BATTLE WAGON", int(HEIGHT * 0.85),
                          frame_in_phase, phase_duration)

    elif phase == 3:  # Building - 建造
        # 炮塔设施
        for i in range(3):
            tx = int(WIDTH * 0.2 + i * WIDTH * 0.3)
            ty = int(HEIGHT * 0.55)
            shooting = (frame_in_phase + i * 20) % 60 < 20
            draw_turret_facility(draw, tx, ty, 1.5, shooting)
        draw_text_overlay(draw, "BUILD YOUR FORTRESS", int(HEIGHT * 0.85),
                          frame_in_phase, phase_duration)

    elif phase == 4:  # Defense - 防守
        vehicle_x = int(WIDTH * 0.5)
        vehicle_y = int(HEIGHT * 0.5)
        draw_vehicle(draw, vehicle_x, vehicle_y, 1.2)
        # 僵尸群
        for i in range(10):
            zx = int(WIDTH * 0.1 + i * WIDTH * 0.08)
            zy = int(HEIGHT * 0.6 + (frame_in_phase + i * 10) % 100)
            draw_zombie(draw, zx, zy, 0.8)
        # 炮塔射击
        for i in range(2):
            tx = int(WIDTH * 0.3 + i * WIDTH * 0.4)
            ty = int(HEIGHT * 0.45)
            draw_turret_facility(draw, tx, ty, 1.2, True)
        draw_text_overlay(draw, "DEFEND AGAINST TIDES", int(HEIGHT * 0.85),
                          frame_in_phase, phase_duration)

    elif phase == 5:  # Day/Night
        vehicle_x = int(WIDTH * 0.5)
        vehicle_y = int(HEIGHT * 0.55)
        draw_vehicle(draw, vehicle_x, vehicle_y, 1.3)
        draw_text_overlay(draw, "DAY/NIGHT CYCLE", int(HEIGHT * 0.85),
                          frame_in_phase, phase_duration)

    else:  # Title
        draw_title_screen(draw, phase_progress)

    return img

def main():
    import subprocess

    # 创建输出目录
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # 创建临时帧目录
    frames_dir = os.path.join(OUTPUT_DIR, "frames")
    os.makedirs(frames_dir, exist_ok=True)

    print(f"开始生成 Trailer 帧...")
    print(f"总帧数: {TOTAL_FRAMES} ({DURATION}秒 @ {FPS}fps)")

    # 生成帧（只生成关键帧用于演示，实际可生成全部）
    # 这里生成每隔几帧的一帧，以节省时间
    step = 3  # 每隔3帧生成一帧（实际10fps）
    actual_frames = TOTAL_FRAMES // step

    for i in range(0, TOTAL_FRAMES, step):
        frame = create_frame(i)
        frame_path = os.path.join(frames_dir, f"frame_{i//step:04d}.png")
        frame.save(frame_path)
        if (i // step) % 100 == 0:
            print(f"  生成进度: {i//step}/{actual_frames} 帧")

    print(f"帧生成完成: {actual_frames} 帧")

    # 使用 ffmpeg 合成视频
    output_video = os.path.join(OUTPUT_DIR, "trailer_launch.mp4")

    # 检查 ffmpeg 是否可用
    ffmpeg_check = subprocess.run(["ffmpeg", "-version"], capture_output=True)
    if ffmpeg_check.returncode != 0:
        print("警告: ffmpeg 未安装，无法合成视频")
        print(f"帧文件保存在: {frames_dir}")
        print("请手动使用 ffmpeg 合成:")
        print(f"  ffmpeg -framerate {FPS//step} -i frames/frame_%04d.png -c:v libx264 -pix_fmt yuv420p {output_video}")
        return

    # 合成视频
    print("使用 ffmpeg 合成视频...")
    cmd = [
        "ffmpeg",
        "-y",  # 覆盖现有文件
        "-framerate", str(FPS // step),
        "-i", os.path.join(frames_dir, "frame_%04d.png"),
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-r", str(FPS),  # 输出帧率
        output_video
    ]

    subprocess.run(cmd, capture_output=True)

    # 清理临时帧（可选）
    # print("清理临时帧...")
    # for f in os.listdir(frames_dir):
    #     os.remove(os.path.join(frames_dir, f))
    # os.rmdir(frames_dir)

    file_size = os.path.getsize(output_video) if os.path.exists(output_video) else 0
    print(f"\n完成！")
    print(f"视频文件: {output_video}")
    print(f"文件大小: {file_size // (1024*1024)} MB")

if __name__ == "__main__":
    main()