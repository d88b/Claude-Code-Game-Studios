"""检查原始JPG的实际背景色范围"""
from PIL import Image
import os

BASE = "d:/ai/Claude-Code-Game-Studios/assets/knight"

for name in ["idle", "walk", "attack", "hurt", "jump", "death"]:
    path = os.path.join(BASE, f"knight_{name}.jpg")
    if not os.path.exists(path):
        continue
    img = Image.open(path)
    w, h = img.size
    pixels = img.load()

    # Sample corners and edges
    samples = [
        (0, 0), (w//4, 0), (w//2, 0), (3*w//4, 0), (w-1, 0),
        (0, h//2), (w//2, h//2), (w-1, h//2),
        (0, h-1), (w//4, h-1), (w//2, h-1), (3*w//4, h-1), (w-1, h-1),
    ]

    min_bright = 999
    max_bright = 0
    print(f"\n{name}.jpg ({w}x{h}):")
    for x, y in samples:
        r, g, b = pixels[x, y]
        bright = (r + g + b) // 3
        print(f"  ({x},{y}): RGB({r},{g},{b}) brightness={bright}")
        if bright < min_bright: min_bright = bright
        if bright > max_bright: max_bright = bright

    # Find the actual background - scan first 100 pixels for darkest
    bg_samples = []
    for y in [0, 1, 2, h//2-1, h//2, h//2+1, h-2, h-1]:
        for x in range(min(50, w)):
            r, g, b = pixels[x, y]
            bg_samples.append((r+g+b)//3)

    print(f"  Background brightness range: {min(bg_samples)}-{max(bg_samples)}")
