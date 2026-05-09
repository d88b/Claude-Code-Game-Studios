#!/usr/bin/env python3
"""
修复精灵表帧尺寸不一致 — 统一缩放方案
使用 NEAREST 插值保持像素清晰
"""

import os
from PIL import Image

INPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                         "assets", "sprites", "enemies", "licker")

FRAME_W = 270
FRAME_H = 126

ANIMATIONS = {
    "licker_idle.png":     {"frames": 6},
    "licker_walk.png":     {"frames": 8},
    "licker_attack1.png":  {"frames": 6},
    "licker_attack2.png":  {"frames": 6},
    "licker_hurt.png":     {"frames": 4},
    "licker_die.png":      {"frames": 6},
}


def main():
    print("=" * 60)
    print("修复精灵表帧尺寸不一致 — 统一缩放")
    print("=" * 60)

    # ========== 提取所有帧 ==========
    all_chars = {}
    max_w = 0
    max_h = 0
    min_w = 99999
    min_h = 99999

    for anim_name, cfg in ANIMATIONS.items():
        path = os.path.join(INPUT_DIR, anim_name)
        sheet = Image.open(path)
        for i in range(cfg["frames"]):
            frame = sheet.crop((i * FRAME_W, 0, (i + 1) * FRAME_W, FRAME_H))
            bbox = frame.getchannel('A').getbbox()
            if bbox:
                char = frame.crop(bbox)
                cw, ch = char.size
                all_chars[(anim_name, i)] = char
                max_w = max(max_w, cw)
                max_h = max(max_h, ch)
                min_w = min(min_w, cw)
                min_h = min(min_h, ch)

    print(f"字符尺寸范围: {min_w}x{min_h} ~ {max_w}x{max_h}")
    print(f"缩放比: {min_w/max_w*100:.0f}% ~ 100%")

    # 统一缩放到最大尺寸
    # 使用 NEAREST 保持像素清晰
    target_w = max_w
    target_h = max_h
    print(f"目标: {target_w}x{target_h}")

    for anim_name, cfg in ANIMATIONS.items():
        out_frames = []
        for i in range(cfg["frames"]):
            char = all_chars.get((anim_name, i))
            if char is None:
                out_frames.append(Image.new('RGBA', (FRAME_W, FRAME_H), (0, 0, 0, 0)))
                continue

            # 统一缩放
            if char.size != (target_w, target_h):
                scaled = char.resize((target_w, target_h), Image.NEAREST)
            else:
                scaled = char

            # 二值化 alpha 确保边缘清晰
            a = scaled.getchannel('A')
            a.putdata([255 if v > 128 else 0 for v in a.getdata()])
            scaled.putalpha(a)

            # 居中
            canvas = Image.new('RGBA', (FRAME_W, FRAME_H), (0, 0, 0, 0))
            x_off = (FRAME_W - target_w) // 2
            y_off = (FRAME_H - target_h) // 2
            canvas.paste(scaled, (x_off, y_off), scaled)
            out_frames.append(canvas)

        # 保存
        sheet_w = FRAME_W * len(out_frames)
        out = Image.new('RGBA', (sheet_w, FRAME_H), (0, 0, 0, 0))
        for i, f in enumerate(out_frames):
            out.paste(f, (i * FRAME_W, 0), f)

        path = os.path.join(INPUT_DIR, anim_name)
        out.save(path)
        print(f"  {anim_name}: saved")

    # ========== 验证 ==========
    print("\n验证：每帧字符尺寸")
    for anim_name, cfg in ANIMATIONS.items():
        sheet = Image.open(os.path.join(INPUT_DIR, anim_name))
        sizes = set()
        for i in range(cfg["frames"]):
            frame = sheet.crop((i * FRAME_W, 0, (i + 1) * FRAME_W, FRAME_H))
            bbox = frame.getchannel('A').getbbox()
            if bbox:
                sizes.add((bbox[2] - bbox[0], bbox[3] - bbox[1]))
        if len(sizes) == 1:
            print(f"  {anim_name}: OK {sizes.pop()}")
        else:
            print(f"  {anim_name}: 不一致 {sizes}")

    print("\n完成！")


if __name__ == "__main__":
    main()
