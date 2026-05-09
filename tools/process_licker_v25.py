#!/usr/bin/env python3
"""
舔食者精灵表处理脚本 v25 - 从 strip 提取 + 统一字符尺寸
解决不同动画阶段像素大小不一致的问题
"""

import os
from PIL import Image, ImageEnhance, ImageFilter

INPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                         "assets", "sprites", "enemies", "licker")
OUTPUT_DIR = INPUT_DIR

# strip 文件映射
STRIPS = {
    "licker_idle.png": {"strip": "idle_strip.png", "frames": (0, 5), "type": "idle"},
    "licker_walk.png": {"strip": "walk_strip.png", "frames": None, "type": "walk"},  # None = 全部
    "licker_attack1.png": {"strip": "attack1_strip.png", "frames": None, "type": "attack"},
    "licker_attack2.png": {"strip": "attack2_strip.png", "frames": None, "type": "attack"},
    "licker_hurt.png": {"strip": "hurt_strip.png", "frames": None, "type": "hurt"},
    "licker_die.png": {"strip": "die_strip.png", "frames": None, "type": "die"},
}

# 选取的关键帧数量（每张动画）
KEY_COUNTS = {
    "licker_idle.png": 6,
    "licker_walk.png": 8,
    "licker_attack1.png": 6,
    "licker_attack2.png": 6,
    "licker_hurt.png": 4,
    "licker_die.png": 6,
}


def extract_frames_from_strip(strip_path, count=None):
    """从水平 strip 中提取单帧"""
    strip = Image.open(strip_path)
    w, h = strip.size
    frame_w = w // (count or (w // h))  # 假设帧是正方形比例
    # 更准确：从实际图像推断
    # 通常 strip 帧是等宽的
    if count is None:
        # 尝试推断：找最合理的帧数
        # 假设帧宽高比约为 2:1 到 3:1（横向角色）
        count = w // (h // 2)

    frame_w = w // count
    frames = []
    for i in range(count):
        frame = strip.crop((i * frame_w, 0, (i + 1) * frame_w, h))
        frames.append(frame)
    return frames


def extract_licker(img, animation_type="idle"):
    """提取角色主体"""
    if img.mode != 'RGB':
        img = img.convert('RGB')
    width, height = img.size

    # 裁剪底部 15%
    crop_bottom = int(height * 0.15)
    img = img.crop((0, 0, width, height - crop_bottom))

    if animation_type == "idle":
        crop_left = int(width * 0.28)
    else:
        crop_left = int(width * 0.40)
    crop_right = int(width * 0.15)
    img = img.crop((crop_left, 0, width - crop_right, img.height))

    # Alpha 提取
    pixels = img.load()
    alpha = Image.new('L', img.size, 0)
    ap = alpha.load()
    for y in range(img.height):
        for x in range(img.width):
            r, g, b = pixels[x, y]
            is_red = r > 70 and r > g + 10 and r > b + 10
            brightness = int(0.299 * r + 0.587 * g + 0.114 * b)
            is_bright = brightness > 65
            ap[x, y] = 255 if (is_red or is_bright) else 0

    alpha = alpha.filter(ImageFilter.MaxFilter(5))
    alpha = alpha.filter(ImageFilter.MinFilter(3))
    alpha = alpha.filter(ImageFilter.GaussianBlur(1.0))
    img.putalpha(alpha)
    return img


def enhance_colors(img):
    alpha = img.getchannel('A')
    rgb = img.convert('RGB')
    enhancer = ImageEnhance.Color(rgb)
    rgb = enhancer.enhance(1.3)
    enhancer = ImageEnhance.Contrast(rgb)
    rgb = enhancer.enhance(1.2)
    rgb.putalpha(alpha)
    return rgb


def select_keyframes(frames, count):
    if len(frames) <= count:
        return frames
    step = len(frames) / count
    return [frames[int(i * step)] for i in range(count)]


def main():
    print("=" * 60)
    print("舔食者精灵表 v25 - 从 strip 提取 + 统一尺寸")
    print("=" * 60)

    # =========================================================================
    # 第一遍：提取所有帧，找最大字符尺寸
    # =========================================================================
    print("\n=== 第一遍：分析所有帧 ===")

    all_cropped = {}  # (output_name, frame_idx) -> cropped_img
    max_char_w = 0
    max_char_h = 0

    for output_name, strip_info in STRIPS.items():
        strip_path = os.path.join(INPUT_DIR, strip_info["strip"])
        if not os.path.exists(strip_path):
            print(f"  跳过: 找不到 {strip_info['strip']}")
            continue

        print(f"\n  处理 {strip_info['strip']}...")
        frames = extract_frames_from_strip(strip_path)
        print(f"    提取 {len(frames)} 帧")

        key_count = KEY_COUNTS.get(output_name, len(frames))
        key_frames = select_keyframes(frames, key_count)
        print(f"    选取 {len(key_frames)} 关键帧")

        for i, frame in enumerate(key_frames):
            img = extract_licker(frame, strip_info["type"])
            img = enhance_colors(img)
            bbox = img.getchannel('A').getbbox()
            if bbox:
                cw = bbox[2] - bbox[0]
                ch = bbox[3] - bbox[1]
                max_char_w = max(max_char_w, cw)
                max_char_h = max(max_char_h, ch)
                all_cropped[(output_name, i)] = (img, bbox)
                print(f"    帧{i}: 字符 {cw}x{ch}")
            else:
                all_cropped[(output_name, i)] = (img, None)

    print(f"\n全局最大字符: {max_char_w}x{max_char_h}")

    # 计算统一缩放
    # 目标帧尺寸基于最大字符
    target_frame_w = max_char_w + 20  # 左右各留 10px
    target_frame_h = max_char_h + 20  # 上下各留 10px
    # 统一到整数
    target_frame_w = int(target_frame_w)
    target_frame_h = int(target_frame_h)
    print(f"目标帧尺寸: {target_frame_w}x{target_frame_h}")

    # =========================================================================
    # 第二遍：统一缩放并生成精灵表
    # =========================================================================
    print("\n=== 第二遍：生成精灵表 ===")

    for output_name, strip_info in STRIPS.items():
        if output_name not in [k[0] for k in all_cropped.keys()]:
            continue

        frames_out = []
        i = 0
        while (output_name, i) in all_cropped:
            img, bbox = all_cropped[(output_name, i)]
            if bbox:
                cropped = img.crop(bbox)
                cw, ch = cropped.size
                # 直接放置到帧中心，不缩放
                canvas = Image.new('RGBA', (target_frame_w, target_frame_h), (0, 0, 0, 0))
                x_off = (target_frame_w - cw) // 2
                y_off = (target_frame_h - ch) // 2
                canvas.paste(cropped, (x_off, y_off), cropped)
                frames_out.append(canvas)
            else:
                frames_out.append(Image.new('RGBA', (target_frame_w, target_frame_h), (0, 0, 0, 0)))
            i += 1

        if not frames_out:
            continue

        # 拼接精灵表
        sheet_w = target_frame_w * len(frames_out)
        sheet = Image.new('RGBA', (sheet_w, target_frame_h), (0, 0, 0, 0))
        for i, frame in enumerate(frames_out):
            sheet.paste(frame, (i * target_frame_w, 0), frame)

        output_path = os.path.join(OUTPUT_DIR, output_name)
        sheet.save(output_path)
        print(f"  {output_name}: {sheet_w}x{target_frame_h} ({os.path.getsize(output_path) // 1024}KB)")

    # 验证
    print("\n=== 验证：所有帧字符尺寸 ===")
    for output_name in STRIPS:
        path = os.path.join(OUTPUT_DIR, output_name)
        if not os.path.exists(path):
            continue
        img = Image.open(path)
        fw = target_frame_w
        for i in range(img.width // fw):
            frame = img.crop((i * fw, 0, (i + 1) * fw, img.height))
            bbox = frame.getchannel('A').getbbox()
            if bbox:
                cw = bbox[2] - bbox[0]
                ch = bbox[3] - bbox[1]
                if i == 0:
                    print(f"  {output_name}: 帧0 = {cw}x{ch}")
            else:
                if i == 0:
                    print(f"  {output_name}: 帧0 = 空")

    print("\n完成！")


if __name__ == "__main__":
    main()
