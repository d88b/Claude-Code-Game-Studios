"""验证新裁剪的PNG透明度"""
from PIL import Image
import os

OUT_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight/frames"

for fname in ["idle_0.png", "walk_0.png", "attack_0.png", "hurt_0.png", "jump_0.png", "death_0.png"]:
    path = os.path.join(OUT_DIR, fname)
    if not os.path.exists(path):
        print(f"MISSING: {fname}")
        continue
    img = Image.open(path)
    w, h = img.size

    # Count transparency
    total = w * h
    fully_trans = 0
    fully_opaque = 0
    for y in range(h):
        for x in range(w):
            r, g, b, a = img.getpixel((x, y))
            if a == 0:
                fully_trans += 1
            elif a == 255:
                fully_opaque += 1

    # Corner check
    corners = []
    for cx, cy in [(0,0), (w-1,0), (0,h-1), (w-1,h-1)]:
        r, g, b, a = img.getpixel((cx, cy))
        corners.append(f"({cx},{cy})=a{a}")

    print(f"{fname}: {w}x{h}, trans={fully_trans}, opaque={fully_opaque}, corners={corners}")
