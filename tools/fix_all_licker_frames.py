#!/usr/bin/env python3
"""
修复所有舔食者精灵表帧尺寸不一致
v1: 270x126 帧
v2: 376x126 帧
"""

import os
from PIL import Image

INPUT_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
                         "assets", "sprites", "enemies", "licker")

ANIMATIONS = {
    # v1
    "licker_idle.png":     {"frame_w": 270, "frame_h": 126, "frames": 6},
    "licker_walk.png":     {"frame_w": 270, "frame_h": 126, "frames": 8},
    "licker_attack1.png":  {"frame_w": 270, "frame_h": 126, "frames": 6},
    "licker_attack2.png":  {"frame_w": 270, "frame_h": 126, "frames": 6},
    "licker_hurt.png":     {"frame_w": 270, "frame_h": 126, "frames": 4},
    "licker_die.png":      {"frame_w": 270, "frame_h": 126, "frames": 6},
    # v2
    "licker2_idle.png":    {"frame_w": 376, "frame_h": 126, "frames": 6},
    "licker2_walk.png":    {"frame_w": 376, "frame_h": 126, "frames": 8},
    "licker2_attack1.png": {"frame_w": 376, "frame_h": 126, "frames": 6},
    "licker2_attack2.png": {"frame_w": 376, "frame_h": 126, "frames": 6},
    "licker2_fall.png":    {"frame_w": 376, "frame_h": 126, "frames": 4},
    "licker2_rise.png":    {"frame_w": 376, "frame_h": 126, "frames": 6},
}


def fix_animation(anim_name, frame_w, frame_h, num_frames):
    """修复单个动画"""
    path = os.path.join(INPUT_DIR, anim_name)
    sheet = Image.open(path)

    # 提取所有帧
    chars = []
    max_w = 0
    max_h = 0
    for i in range(num_frames):
        frame = sheet.crop((i * frame_w, 0, (i + 1) * frame_w, frame_h))
        bbox = frame.getchannel('A').getbbox()
        if bbox:
            char = frame.crop(bbox)
            chars.append(char)
            max_w = max(max_w, char.width)
            max_h = max(max_h, char.height)
        else:
            chars.append(None)

    if max_w == 0:
        print(f"  {anim_name}: 无有效帧")
        return

    # 统一缩放到最大尺寸
    tw, th = max_w, max_h

    out_frames = []
    for char in chars:
        if char is None:
            out_frames.append(Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0)))
            continue

        if char.size != (tw, th):
            scaled = char.resize((tw, th), Image.NEAREST)
            # 二值化 alpha
            a = scaled.getchannel('A')
            import warnings
            with warnings.catch_warnings():
                warnings.simplefilter("ignore", DeprecationWarning)
                a.putdata([255 if v > 128 else 0 for v in a.getdata()])
            scaled.putalpha(a)

            # 验证并修正：确保 bbox 恰好等于 tw x th
            v_bbox = scaled.getchannel('A').getbbox()
            if v_bbox:
                vw, vh = v_bbox[2] - v_bbox[0], v_bbox[3] - v_bbox[1]
                if vw < tw or vh < th:
                    # 字符小于目标，需要填充
                    canvas = Image.new('RGBA', (tw, th), (0, 0, 0, 0))
                    x = (tw - vw) // 2
                    y = (th - vh) // 2
                    canvas.paste(scaled.crop(v_bbox), (x, y), scaled.crop(v_bbox))
                    scaled = canvas
        else:
            scaled = char

        # 居中放入帧
        canvas = Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0))
        x_off = (frame_w - tw) // 2
        y_off = (frame_h - th) // 2
        canvas.paste(scaled, (x_off, y_off), scaled)
        out_frames.append(canvas)

    # 保存
    sheet_w = frame_w * len(out_frames)
    out = Image.new('RGBA', (sheet_w, frame_h), (0, 0, 0, 0))
    for i, f in enumerate(out_frames):
        out.paste(f, (i * frame_w, 0), f)

    out.save(path)

    # 验证
    verify = Image.open(path)
    sizes = set()
    for i in range(num_frames):
        f = verify.crop((i * frame_w, 0, (i + 1) * frame_w, frame_h))
        b = f.getchannel('A').getbbox()
        if b:
            sizes.add((b[2] - b[0], b[3] - b[1]))
    if len(sizes) == 1:
        print(f"  {anim_name}: OK {sizes.pop()}")
    else:
        print(f"  {anim_name}: 不一致 {sizes}")


def main():
    print("=" * 60)
    print("修复所有舔食者精灵表帧尺寸")
    print("=" * 60)

    # 按前缀分组，v1 和 v2 分别处理
    groups = {"v1": [], "v2": []}
    for name, cfg in ANIMATIONS.items():
        key = "v2" if "licker2" in name else "v1"
        groups[key].append((name, cfg))

    for group_name, anims in groups.items():
        print(f"\n--- {group_name} ---")
        for name, cfg in anims.items() if isinstance(anims, dict) else anims:
            if isinstance(anims, dict):
                fix_animation(name, cfg["frame_w"], cfg["frame_h"], cfg["frames"])
            else:
                fix_animation(name, cfg["frame_w"], cfg["frame_h"], cfg["frames"])

    print("\n完成！")


if __name__ == "__main__":
    main()
