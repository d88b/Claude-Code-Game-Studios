"""验证裁剪后的PNG是否有内容"""
from PIL import Image
import os

OUT_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight/frames"

# Check a few key frames
for fname in ["idle_0.png", "walk_0.png", "attack_0.png", "death_0.png", "hurt_0.png", "jump_0.png"]:
    path = os.path.join(OUT_DIR, fname)
    if not os.path.exists(path):
        print(f"MISSING: {fname}")
        continue
    img = Image.open(path)
    w, h = img.size
    # Sample a few pixels
    pixels = list(img.getdata())
    non_transparent = sum(1 for p in pixels if p[3] > 0)
    total = len(pixels)
    print(f"{fname}: {w}x{h}, {non_transparent}/{total} non-transparent pixels ({100*non_transparent//total}%)")

# Also check the original JPG grid layout
print("\n--- Original JPG dimensions ---")
for name in ["idle", "walk", "attack", "hurt", "jump", "death"]:
    path = os.path.join("d:/ai/Claude-Code-Game-Studios/assets/knight", f"knight_{name}.jpg")
    if os.path.exists(path):
        img = Image.open(path)
        print(f"knight_{name}.jpg: {img.size[0]}x{img.size[1]}")
