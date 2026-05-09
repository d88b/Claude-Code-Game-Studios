"""重新处理 hurt.jpg - 亮白色背景"""
from PIL import Image
import os

BASE_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight"
OUT_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight/frames"
PAD = 4

# hurt.jpg 背景约234，但有些区域低至231
# 阈值设为220确保所有背景都被透明
img = Image.open(os.path.join(BASE_DIR, "knight_hurt.jpg")).convert("RGBA")
w, h = img.size
pixels = img.load()

for y in range(h):
    for x in range(w):
        r, g, b, a = pixels[x, y]
        brightness = (r + g + b) / 3
        if brightness > 210:
            pixels[x, y] = (r, g, b, 0)  # 亮色=背景透明
        else:
            pixels[x, y] = (r, g, b, 255)

for i in range(3):
    fw = w // 3
    fh = h
    x = i * fw
    frame = img.crop((x, 0, x + fw, h))

    bbox = frame.getbbox()
    if bbox:
        bx0, by0, bx1, by1 = bbox
        bx0 = max(0, bx0 - PAD)
        by0 = max(0, by0 - PAD)
        bx1 = min(fw, bx1 + PAD)
        by1 = min(h, by1 + PAD)
        cropped = frame.crop((bx0, by0, bx1, by1))
    else:
        cropped = frame

    out_path = os.path.join(OUT_DIR, f"hurt_{i}.png")
    cropped.save(out_path)
    cw, ch = cropped.size
    # Verify corners
    corners_ok = True
    for cx, cy in [(0,0), (cw-1,0), (0,ch-1), (cw-1,ch-1)]:
        r, g, b, a = cropped.getpixel((cx, cy))
        if a != 0:
            corners_ok = False
    print(f"hurt_{i}.png: {cw}x{ch}, corners_transparent={corners_ok}")

print("DONE hurt")
