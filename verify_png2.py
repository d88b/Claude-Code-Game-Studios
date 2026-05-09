"""深度验证PNG透明度"""
from PIL import Image
import os

OUT_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight/frames"

for fname in ["idle_0.png", "walk_0.png", "attack_0.png", "hurt_0.png"]:
    path = os.path.join(OUT_DIR, fname)
    if not os.path.exists(path):
        print(f"MISSING: {fname}")
        continue
    img = Image.open(path)
    w, h = img.size
    pixels = list(img.getdata())

    # Count transparency buckets
    full_trans = sum(1 for p in pixels if p[3] == 0)
    full_alpha = sum(1 for p in pixels if p[3] == 255)
    partial = sum(1 for p in pixels if 0 < p[3] < 255)

    # Sample top-left corner pixels
    print(f"\n{fname}: {w}x{h}")
    print(f"  Full transparent: {full_trans}, Full opaque: {full_alpha}, Partial: {partial}")

    # Check corner pixels
    for sx in [0, w-1]:
        for sy in [0, h-1]:
            p = pixels[sy * w + sx]
            print(f"  Pixel({sx},{sy}): RGBA{p}")

    # Check center pixels
    cx, cy = w//2, h//2
    for dx in range(-2, 3):
        p = pixels[cy * w + (cx + dx)]
        print(f"  Pixel({cx+dx},{cy}): RGBA{p}")
