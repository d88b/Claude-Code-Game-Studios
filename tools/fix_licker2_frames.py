#!/usr/bin/env python3
"""
修复 v2 精灵表帧尺寸 — 强制扩展到目标尺寸
"""

import os
import warnings
from PIL import Image

warnings.filterwarnings("ignore", category=DeprecationWarning)

INPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                         "assets", "sprites", "enemies", "licker")

FRAME_W = 376
FRAME_H = 126

V2_ANIMS = {
    "licker2_idle.png":    6,
    "licker2_walk.png":    8,
    "licker2_attack1.png": 6,
    "licker2_attack2.png": 6,
    "licker2_fall.png":    4,
    "licker2_rise.png":    6,
}


def force_to_size(img, target_w, target_h):
    """强制将图像扩展到目标尺寸，保持内容居中"""
    w, h = img.size
    if w == target_w and h == target_h:
        return img

    out = Image.new('RGBA', (target_w, target_h), (0, 0, 0, 0))
    x = (target_w - w) // 2
    y = (target_h - h) // 2
    out.paste(img, (x, y), img)
    return out


def main():
    print("=" * 60)
    print("修复 v2 精灵表帧尺寸 — 强制扩展")
    print("=" * 60)

    # ========== 提取所有帧 ==========
    all_chars = {}
    max_w = 0
    max_h = 0

    for anim_name, num_frames in V2_ANIMS.items():
        path = os.path.join(INPUT_DIR, anim_name)
        sheet = Image.open(path)
        for i in range(num_frames):
            frame = sheet.crop((i * FRAME_W, 0, (i + 1) * FRAME_W, FRAME_H))
            bbox = frame.getchannel('A').getbbox()
            if bbox:
                char = frame.crop(bbox)
                all_chars[(anim_name, i)] = char
                max_w = max(max_w, char.width)
                max_h = max(max_h, char.height)

    print(f"全局最大: {max_w}x{max_h}")

    # 目标：保持宽高比，缩放到最大高度
    target_h = max_h
    target_w = max_w

    # ========== 统一缩放 ==========
    for anim_name, num_frames in V2_ANIMS.items():
        out_frames = []
        for i in range(num_frames):
            char = all_chars.get((anim_name, i))
            if char is None:
                out_frames.append(Image.new('RGBA', (FRAME_W, FRAME_H), (0, 0, 0, 0)))
                continue

            cw, ch = char.size

            # 统一缩放到 target_w x target_h
            scaled = char.resize((target_w, target_h), Image.NEAREST)

            # 二值化 alpha
            a = scaled.getchannel('A')
            a.putdata([255 if v > 128 else 0 for v in a.getdata()])
            scaled.putalpha(a)

            # 关键：检查实际 bbox 是否等于 target_w x target_h
            v_bbox = scaled.getchannel('A').getbbox()
            if v_bbox:
                vw, vh = v_bbox[2] - v_bbox[0], v_bbox[3] - v_bbox[1]
                # 如果小于目标，强制扩展
                if vw < target_w or vh < target_h:
                    char_cropped = scaled.crop(v_bbox)
                    scaled = force_to_size(char_cropped, target_w, target_h)

            # 居中放入帧
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

    # ========== 验证 ==========
    print("\n验证：")
    for anim_name, num_frames in V2_ANIMS.items():
        sheet = Image.open(os.path.join(INPUT_DIR, anim_name))
        sizes = set()
        for i in range(num_frames):
            f = sheet.crop((i * FRAME_W, 0, (i + 1) * FRAME_W, FRAME_H))
            b = f.getchannel('A').getbbox()
            if b:
                sizes.add((b[2] - b[0], b[3] - b[1]))
        if len(sizes) == 1:
            print(f"  {anim_name}: OK {sizes.pop()}")
        else:
            print(f"  {anim_name}: 不一致 {sizes}")

    print("\n完成！")


if __name__ == "__main__":
    main()
