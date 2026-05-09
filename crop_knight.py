"""智能裁剪骑士精灵表 - 自动检测每个JPG的背景色"""
from PIL import Image
import os

BASE_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight"
OUT_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight/frames"
PAD = 4

CONFIGS = {
    "idle": {"file": "knight_idle.jpg", "cols": 3, "rows": 2},
    "walk": {"file": "knight_walk.jpg", "cols": 4, "rows": 1},
    "attack": {"file": "knight_attack.jpg", "cols": 4, "rows": 1},
    "hurt": {"file": "knight_hurt.jpg", "cols": 3, "rows": 1},
    "jump": {"file": "knight_jump.jpg", "cols": 4, "rows": 1},
    "death": {"file": "knight_death.jpg", "cols": 3, "rows": 2},
}

os.makedirs(OUT_DIR, exist_ok=True)

def detect_background(img):
    """从四角和边缘采样检测背景亮度"""
    w, h = img.size
    samples = []
    # 采样四角各10x10区域
    for ox in [0, w-10]:
        for oy in [0, h-10]:
            for dx in range(10):
                for dy in range(10):
                    r, g, b, a = img.getpixel((ox+dx, oy+dy))
                    samples.append((r+g+b)//3)
    # 采样中间一行的左右边缘
    mid_y = h // 2
    for x in range(20):
        r, g, b, a = img.getpixel((x, mid_y))
        samples.append((r+g+b)//3)
        r, g, b, a = img.getpixel((w-1-x, mid_y))
        samples.append((r+g+b)//3)

    # 背景 = 最常见的亮度范围（取中位数附近）
    samples.sort()
    median = samples[len(samples)//2]
    return median

for name, cfg in CONFIGS.items():
    img_path = os.path.join(BASE_DIR, cfg["file"])
    if not os.path.exists(img_path):
        print(f"MISSING: {img_path}")
        continue

    img = Image.open(img_path).convert("RGBA").convert("RGBA")
    w, h = img.size
    fw = w // cfg["cols"]
    fh = h // cfg["rows"]

    # 检测背景亮度
    bg_brightness = detect_background(img)
    threshold = bg_brightness + 15  # 留15的余量
    print(f"\n{name}.jpg: background ~{bg_brightness}, threshold={threshold}")

    pixels = img.load()
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            brightness = (r + g + b) / 3
            # 根据背景亮度范围判断是暗背景还是亮背景
            if bg_brightness < 128:
                # 暗背景: 比阈值暗的变透明
                if brightness < threshold:
                    pixels[x, y] = (r, g, b, 0)
                else:
                    pixels[x, y] = (r, g, b, 255)
            else:
                # 亮背景: 比阈值亮的变透明
                if brightness > threshold:
                    pixels[x, y] = (r, g, b, 0)
                else:
                    pixels[x, y] = (r, g, b, 255)

    count = cfg["cols"] * cfg["rows"]

    for i in range(count):
        col = i % cfg["cols"]
        row = i // cfg["cols"]
        x = col * fw
        y = row * fh

        frame = img.crop((x, y, x + fw, y + fh))

        # 找到内容边界
        bbox = frame.getbbox()
        if bbox:
            bx0, by0, bx1, by1 = bbox
            bx0 = max(0, bx0 - PAD)
            by0 = max(0, by0 - PAD)
            bx1 = min(fw, bx1 + PAD)
            by1 = min(fh, by1 + PAD)
            cropped = frame.crop((bx0, by0, bx1, by1))
        else:
            cropped = frame

        out_name = f"{name}_{i}.png"
        out_path = os.path.join(OUT_DIR, out_name)
        cropped.save(out_path)
        cw, ch = cropped.size
        print(f"  Saved: {out_name} ({cw}x{ch})")

print("\nDONE")
