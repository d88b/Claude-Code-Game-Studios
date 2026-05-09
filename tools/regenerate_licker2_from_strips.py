#!/usr/bin/env python3
"""
从 strip 重新生成 v2 精灵图
"""

import os
import warnings
from PIL import Image, ImageFilter, ImageEnhance

warnings.filterwarnings("ignore", category=DeprecationWarning)

INPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                         "assets", "sprites", "enemies", "licker")
OUTPUT_DIR = INPUT_DIR

STRIP_FRAME_W = 1280
STRIP_FRAME_H = 720

ANIMATIONS = {
    "licker2_idle.png":    {"strip": "licker2_idle_strip.png",    "keyframes": list(range(0, 59, 10)),  "type": "idle"},
    "licker2_walk.png":    {"strip": "licker2_walk_strip.png",    "keyframes": list(range(0, 59, 8)),   "type": "walk"},
    "licker2_attack1.png": {"strip": "licker2_attack1_strip.png", "keyframes": list(range(0, 9)),       "type": "attack"},
    "licker2_attack2.png": {"strip": "licker2_attack2_strip.png", "keyframes": [0, 10, 20, 30, 40, 50], "type": "attack"},
    "licker2_fall.png":    {"strip": "licker2_fall_strip.png",    "keyframes": [0, 6, 12, 18],          "type": "fall"},
    "licker2_rise.png":    {"strip": "licker2_rise_strip.png",    "keyframes": [0, 6, 12, 18, 24, 30],  "type": "rise"},
}


def extract_licker(img, anim_type="idle"):
    if img.mode != 'RGB':
        img = img.convert('RGB')
    w, h = img.size
    crop_bottom = int(h * 0.15)
    img = img.crop((0, 0, w, h - crop_bottom))
    if anim_type == "idle":
        crop_left = int(w * 0.28)
    else:
        crop_left = int(w * 0.40)
    crop_right = int(w * 0.15)
    img = img.crop((crop_left, 0, w - crop_right, img.height))

    pixels = img.load()
    alpha = Image.new('L', img.size, 0)
    ap = alpha.load()
    pw, ph = img.size
    for y in range(ph):
        for x in range(pw):
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


def main():
    print("=" * 60)
    print("从 strip 重新生成 v2 精灵图")
    print("=" * 60)

    # 第一遍
    all_chars = {}
    max_w = 0
    max_h = 0

    for output_name, cfg in ANIMATIONS.items():
        strip_path = os.path.join(INPUT_DIR, cfg["strip"])
        if not os.path.exists(strip_path):
            print(f"  跳过: {cfg['strip']}")
            continue

        strip = Image.open(strip_path)
        print(f"  {output_name}: {len(cfg['keyframes'])} 关键帧")

        for i, kf in enumerate(cfg["keyframes"]):
            frame = strip.crop((kf * STRIP_FRAME_W, 0, (kf+1) * STRIP_FRAME_W, STRIP_FRAME_H))
            char = extract_licker(frame, cfg["type"])
            char = enhance_colors(char)
            bbox = char.getchannel('A').getbbox()
            if bbox:
                cw, ch = bbox[2] - bbox[0], bbox[3] - bbox[1]
                max_w = max(max_w, cw)
                max_h = max(max_h, ch)
                all_chars[(output_name, i)] = (char, bbox, cw, ch)

    print(f"\n全局最大: {max_w}x{max_h}")

    padding = 10
    frame_w = max_w + padding * 2
    frame_h = max_h + padding * 2
    print(f"帧尺寸: {frame_w}x{frame_h}")

    # 第二遍
    for output_name, cfg in ANIMATIONS.items():
        num_frames = len(cfg["keyframes"])
        out_frames = []

        for i in range(num_frames):
            key = (output_name, i)
            if key not in all_chars:
                out_frames.append(Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0)))
                continue

            char, bbox, cw, ch = all_chars[key]
            cropped = char.crop(bbox)
            scaled = cropped.resize((max_w, max_h), Image.LANCZOS)
            a = scaled.getchannel('A')
            a.putdata([255 if v > 128 else 0 for v in a.getdata()])
            scaled.putalpha(a)

            canvas = Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0))
            x_off = (frame_w - max_w) // 2
            y_off = (frame_h - max_h) // 2
            canvas.paste(scaled, (x_off, y_off), scaled)
            out_frames.append(canvas)

        sheet_w = frame_w * len(out_frames)
        sheet = Image.new('RGBA', (sheet_w, frame_h), (0, 0, 0, 0))
        for i, f in enumerate(out_frames):
            sheet.paste(f, (i * frame_w, 0), f)

        path = os.path.join(OUTPUT_DIR, output_name)
        sheet.save(path)
        print(f"  {output_name}: {sheet_w}x{frame_h}")

    # 验证
    print("\n验证:")
    for output_name in ANIMATIONS:
        path = os.path.join(OUTPUT_DIR, output_name)
        if not os.path.exists(path):
            continue
        sheet = Image.open(path)
        sizes = set()
        for i in range(sheet.width // frame_w):
            f = sheet.crop((i * frame_w, 0, (i+1) * frame_w, frame_h))
            b = f.getchannel('A').getbbox()
            if b:
                sizes.add((b[2]-b[0], b[3]-b[1]))
        if len(sizes) == 1:
            print(f"  {output_name}: OK {sizes.pop()}")
        else:
            print(f"  {output_name}: 不一致 {sizes}")

    print("\n完成！")


if __name__ == "__main__":
    main()
