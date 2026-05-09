"""
舔食者精灵表处理脚本 v23 - 紧凑版本
消除大量空白区域，让角色占满帧区域
"""

import os
from PIL import Image, ImageEnhance, ImageFilter

INPUT_DIR = r"D:\ai\Claude-Code-Game-Studios\assets\sprites\enemies\licker\cleaned_frames"
OUTPUT_DIR = r"D:\ai\Claude-Code-Game-Studios\assets\sprites\enemies\licker"

# 帧尺寸（紧凑版本，消除大量空白）
FRAME_WIDTH = 200
FRAME_HEIGHT = 320
TARGET_CHAR_HEIGHT = 280

# 动画帧范围（基于视频帧编号，从1开始）
IDLE_RANGE = (1, 12)      # 待机动作
WALK_RANGE = (13, 36)     # 爬行
ATTACK_RANGE = (40, 48)   # 前扑
DIE_RANGE = (70, 72)      # 死亡

# 每段动画选取的关键帧数量
IDLE_KEYS = 6
WALK_KEYS = 8
ATTACK_KEYS = 6
DIE_KEYS = 3

def get_frame_path(frame_num):
    return os.path.join(INPUT_DIR, f"frame_{frame_num:03d}.png")

def select_keyframes(start, end, count):
    """从帧范围内均匀选取关键帧"""
    total = end - start + 1
    if total <= count:
        return list(range(start, end + 1))
    step = total / count
    return [int(start + i * step) for i in range(count)]

def extract_licker(img, animation_type="idle"):
    """提取角色主体（保留更多暗部细节）"""
    if img.mode != 'RGB':
        img = img.convert('RGB')
    width, height = img.size

    # 裁剪掉底部 15%（仅去除地面）
    crop_bottom = int(height * 0.15)
    img = img.crop((0, 0, width, height - crop_bottom))

    # 根据动画类型调整左侧裁剪
    if animation_type == "idle":
        crop_left = int(width * 0.28)
    else:
        crop_left = int(width * 0.40)
    crop_right = int(width * 0.15)
    img = img.crop((crop_left, 0, width - crop_right, img.height))

    # 获取裁剪后的尺寸
    width, height = img.size
    pixels = img.load()

    alpha = Image.new('L', (width, height), 0)
    ap = alpha.load()

    for y in range(height):
        for x in range(width):
            r, g, b = pixels[x, y]
            # 红色检测（提高阈值排除暗色背景）
            is_red = r > 70 and r > g + 10 and r > b + 10
            # 或足够亮（排除深色背景）
            brightness = int(0.299 * r + 0.587 * g + 0.114 * b)
            is_bright = brightness > 65
            ap[x, y] = 255 if (is_red or is_bright) else 0

    # 形态学操作清理噪点（更温和，保留细节）
    alpha = alpha.filter(ImageFilter.MaxFilter(5))
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.0))
    img.putalpha(alpha)
    return img

def enhance_colors(img):
    """增强颜色和对比度"""
    alpha = img.getchannel('A')
    rgb = img.convert('RGB')
    enhancer = ImageEnhance.Color(rgb)
    rgb = enhancer.enhance(1.3)
    enhancer = ImageEnhance.Contrast(rgb)
    rgb = enhancer.enhance(1.2)
    rgb.putalpha(alpha)
    return rgb

def crop_to_char(img):
    """裁剪到角色边界"""
    alpha = img.getchannel('A')
    bbox = alpha.getbbox()
    if not bbox:
        return None, (0, 0, 0, 0)
    return img.crop(bbox), bbox

def scale_and_align(cropped_img):
    """缩放并对齐到固定帧尺寸，让角色占满"""
    if cropped_img is None:
        return Image.new('RGBA', (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))

    char_w, char_h = cropped_img.size
    # 计算缩放比例，让角色占满帧的 85-90%
    padding = 10
    available_h = FRAME_HEIGHT - padding * 2
    available_w = FRAME_WIDTH - padding * 2

    scale_h = available_h / char_h
    scale_w = available_w / char_w
    scale = min(scale_h, scale_w)

    new_w = int(round(char_w * scale))
    new_h = int(round(char_h * scale))

    resized = cropped_img.resize((new_w, new_h), Image.LANCZOS)
    # 二值化 alpha
    res_alpha = resized.getchannel('A')
    rap = res_alpha.load()
    rw, rh = resized.size
    for y in range(rh):
        for x in range(rw):
            rap[x, y] = 255 if rap[x, y] > 128 else 0
    resized.putalpha(res_alpha)

    canvas = Image.new('RGBA', (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    x_off = (FRAME_WIDTH - new_w) // 2
    y_off = (FRAME_HEIGHT - new_h) // 2
    canvas.paste(resized, (x_off, y_off), resized)
    return canvas

def process_single_image(img_path, animation_type="idle"):
    basename = os.path.basename(img_path)
    print(f"  处理: {basename}")
    img = Image.open(img_path)
    print(f"    原始: {img.width}x{img.height}")
    img = extract_licker(img, animation_type)
    img = enhance_colors(img)
    cropped, bbox = crop_to_char(img)
    if bbox and bbox[2] > bbox[0]:
        print(f"    角色: {bbox[2]-bbox[0]}x{bbox[3]-bbox[1]}")
    return scale_and_align(cropped)

def create_sprite_sheet(frame_indices, output_name, animation_type="idle"):
    print(f"\n创建 {output_name} ({len(frame_indices)} 帧)...")
    frames = []
    for idx in frame_indices:
        img_path = get_frame_path(idx)
        if not os.path.exists(img_path):
            print(f"    跳过不存在的帧: {img_path}")
            continue
        frame = process_single_image(img_path, animation_type)
        frames.append(frame)

    if not frames:
        print(f"    警告: 没有有效帧！")
        return False

    sheet_w = FRAME_WIDTH * len(frames)
    sheet = Image.new('RGBA', (sheet_w, FRAME_HEIGHT), (0, 0, 0, 0))
    for i, frame in enumerate(frames):
        sheet.paste(frame, (i * FRAME_WIDTH, 0), frame)

    output_path = os.path.join(OUTPUT_DIR, output_name)
    sheet.save(output_path)
    print(f"    已保存: {output_name} ({os.path.getsize(output_path) // 1024}KB, {sheet_w}x{FRAME_HEIGHT})")
    return True

def main():
    print("=" * 60)
    print("舔食者精灵表生成器 v23 - 紧凑版本")
    print("=" * 60)

    # 选取关键帧
    idle_frames = select_keyframes(*IDLE_RANGE, IDLE_KEYS)
    walk_frames = select_keyframes(*WALK_RANGE, WALK_KEYS)
    attack_frames = select_keyframes(*ATTACK_RANGE, ATTACK_KEYS)
    die_frames = select_keyframes(*DIE_RANGE, DIE_KEYS)

    print(f"\n关键帧选取:")
    print(f"  Idle: {idle_frames}")
    print(f"  Walk: {walk_frames}")
    print(f"  Attack: {attack_frames}")
    print(f"  Die: {die_frames}")
    print(f"\n帧尺寸: {FRAME_WIDTH}x{FRAME_HEIGHT}")

    # 生成精灵表
    results = {}
    results["licker_idle.png"] = create_sprite_sheet(idle_frames, "licker_idle.png", "idle")
    results["licker_walk.png"] = create_sprite_sheet(walk_frames, "licker_walk.png", "walk")
    results["licker_attack.png"] = create_sprite_sheet(attack_frames, "licker_attack.png", "attack")
    results["licker_die.png"] = create_sprite_sheet(die_frames, "licker_die.png", "die")

    print("\n" + "=" * 60)
    print("生成结果:")
    for name, success in results.items():
        status = "成功" if success else "失败"
        print(f"  {name}: {status}")
    print("=" * 60)

if __name__ == "__main__":
    main()
