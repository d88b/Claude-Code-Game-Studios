"""
从 strip 序列帧生成紧凑精灵图集
Licker v1: idle(47), walk(38), attack1(45), attack2(33), hurt(47), die(92)
Licker v2: idle(59), walk(59), attack1(9), attack2(55), fall(25), rise(35)
"""

import os
from PIL import Image

INPUT_DIR = './assets/sprites/enemies/licker'
OUTPUT_DIR = INPUT_DIR
FRAME_W = 1280
FRAME_H = 720

# Licker v1 动画配置：取均匀分布的关键帧
LICKER_V1 = {
    'idle':    {'strip': 'idle_strip.png',    'total': 47, 'keys': 6},
    'walk':    {'strip': 'walk_strip.png',    'total': 38, 'keys': 8},
    'attack1': {'strip': 'attack1_strip.png', 'total': 45, 'keys': 6},
    'attack2': {'strip': 'attack2_strip.png', 'total': 33, 'keys': 6},
    'hurt':    {'strip': 'hurt_strip.png',    'total': 47, 'keys': 4},
    'die':     {'strip': 'die_strip.png',     'total': 92, 'keys': 6},
}

# Licker v2 动画配置
LICKER_V2 = {
    'idle':    {'strip': 'licker2_idle_strip.png',    'total': 59, 'keys': 6},
    'walk':    {'strip': 'licker2_walk_strip.png',    'total': 59, 'keys': 8},
    'attack1': {'strip': 'licker2_attack1_strip.png', 'total': 9,  'keys': 6},
    'attack2': {'strip': 'licker2_attack2_strip.png', 'total': 55, 'keys': 6},
    'fall':    {'strip': 'licker2_fall_strip.png',    'total': 25, 'keys': 4},
    'rise':    {'strip': 'licker2_rise_strip.png',    'total': 35, 'keys': 6},
}


def select_frames(total, count):
    """均匀选取关键帧索引"""
    if total <= count:
        return list(range(total))
    step = total / count
    return [int(i * step) % total for i in range(count)]


def extract_frame(strip_path, frame_idx):
    """从 strip 中提取单帧并裁剪空白"""
    img = Image.open(strip_path)
    x = frame_idx * FRAME_W
    frame = img.crop((x, 0, x + FRAME_W, FRAME_H))
    
    # 转 RGBA 方便处理
    if frame.mode != 'RGBA':
        frame = frame.convert('RGBA')
    
    # 裁剪白色背景
    pixels = frame.load()
    w, h = frame.size
    min_x, min_y = w, h
    max_x, max_y = 0, 0
    has_content = False
    
    for y in range(h):
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if not (r > 240 and g > 240 and b > 240):
                if x < min_x: min_x = x
                if y < min_y: min_y = y
                if x > max_x: max_x = x
                if y > max_y: max_y = y
                has_content = True
    
    if not has_content:
        return Image.new('RGBA', (200, 300), (0, 0, 0, 0)), (0, 0, 0, 0)
    
    char_w = max_x - min_x + 1
    char_h = max_y - min_y + 1
    cropped = frame.crop((min_x, min_y, max_x + 1, max_y + 1))
    return cropped, (min_x, min_y, max_x + 1, max_y + 1)


def scale_to_fit(cropped, target_h=280):
    """缩放到目标高度，保持比例"""
    if cropped is None or cropped.size[0] == 0:
        return Image.new('RGBA', (150, target_h), (0, 0, 0, 0))
    
    cw, ch = cropped.size
    scale = target_h / ch
    nw = int(cw * scale)
    nh = target_h
    resized = cropped.resize((nw, nh), Image.LANCZOS)
    
    # 创建帧画布（紧凑尺寸）
    fw = max(200, nw + 20)  # 左右各留 10px
    fh = nh + 10            # 底部留空间
    canvas = Image.new('RGBA', (fw, fh), (0, 0, 0, 0))
    x_off = (fw - nw) // 2
    y_off = 5
    canvas.paste(resized, (x_off, y_off), resized)
    return canvas


def create_atlas(config, prefix, anim_order):
    """为指定配置创建精灵图集"""
    print(f"\n处理 {prefix}:")
    
    all_frames = {}
    max_w = 0
    max_h = 0
    
    for anim_name in anim_order:
        cfg = config[anim_name]
        strip_path = os.path.join(INPUT_DIR, cfg['strip'])
        if not os.path.exists(strip_path):
            print(f"  跳过不存在的: {cfg['strip']}")
            continue
        
        frame_indices = select_frames(cfg['total'], cfg['keys'])
        frames = []
        
        for idx in frame_indices:
            cropped, bbox = extract_frame(strip_path, idx)
            scaled = scale_to_fit(cropped)
            frames.append(scaled)
            
            if scaled.width > max_w:
                max_w = scaled.width
            if scaled.height > max_h:
                max_h = scaled.height
        
        all_frames[anim_name] = frames
        print(f"  {anim_name}: {len(frames)} 帧, 帧尺寸 {frames[0].size if frames else 'N/A'}")
    
    # 统一帧尺寸
    frame_w = max_w
    frame_h = max_h
    print(f"  统一帧尺寸: {frame_w}x{frame_h}")
    
    # 为每个动画创建图集
    results = {}
    for anim_name, frames in all_frames.items():
        # 统一调整到相同尺寸
        uniform_frames = []
        for f in frames:
            if f.size != (frame_w, frame_h):
                canvas = Image.new('RGBA', (frame_w, frame_h), (0, 0, 0, 0))
                x_off = (frame_w - f.width) // 2
                y_off = (frame_h - f.height) // 2
                canvas.paste(f, (x_off, y_off), f)
                uniform_frames.append(canvas)
            else:
                uniform_frames.append(f)
        
        sheet_w = frame_w * len(uniform_frames)
        sheet = Image.new('RGBA', (sheet_w, frame_h), (0, 0, 0, 0))
        for i, f in enumerate(uniform_frames):
            sheet.paste(f, (i * frame_w, 0), f)
        
        output_name = f"{prefix}_{anim_name}.png"
        output_path = os.path.join(OUTPUT_DIR, output_name)
        sheet.save(output_path)
        results[anim_name] = (output_name, sheet_w, frame_h, len(uniform_frames))
        print(f"    -> {output_name} ({sheet_w}x{frame_h}, {os.path.getsize(output_path) // 1024}KB)")
    
    return results, frame_w, frame_h


def main():
    print("=" * 60)
    print("Strip -> 精灵图集生成器")
    print("=" * 60)
    
    # Licker v1
    v1_results, v1_w, v1_h = create_atlas(
        LICKER_V1, 'licker',
        ['idle', 'walk', 'attack1', 'attack2', 'hurt', 'die']
    )
    
    # Licker v2
    v2_results, v2_w, v2_h = create_atlas(
        LICKER_V2, 'licker2',
        ['idle', 'walk', 'attack1', 'attack2', 'fall', 'rise']
    )
    
    print("\n" + "=" * 60)
    print("生成完成！")
    print(f"Licker v1 帧尺寸: {v1_w}x{v1_h}")
    print(f"Licker v2 帧尺寸: {v2_w}x{v2_h}")
    print("=" * 60)

if __name__ == '__main__':
    main()
