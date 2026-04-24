from PIL import Image, ImageDraw
import os

base = "assets"

def create_placeholder(path, size, color, label=None):
    img = Image.new('RGBA', size, color)
    draw = ImageDraw.Draw(img)
    if label:
        cx, cy = size[0]//2, size[1]//2
        draw.line([(cx-10, cy), (cx+10, cy)], fill=(255,255,255,200), width=2)
        draw.line([(cx, cy-10), (cx, cy+10)], fill=(255,255,255,200), width=2)
        draw.rectangle([5, 5, size[0]-5, size[1]-5], outline=(255,255,255,150), width=1)
    img.save(path)
    print(f"Created: {path}")

# Vehicle
create_placeholder(base + "/sprites/vehicle/vehicle_body.png", (64, 48), (100, 100, 100, 255), True)
create_placeholder(base + "/sprites/vehicle/vehicle_turret.png", (32, 32), (80, 80, 80, 255), True)
create_placeholder(base + "/sprites/vehicle/vehicle_wheel.png", (16, 16), (60, 60, 60, 255), True)

# Enemies
create_placeholder(base + "/sprites/enemies/zombie_basic.png", (32, 48), (100, 50, 50, 255), True)
create_placeholder(base + "/sprites/enemies/zombie_fast.png", (24, 40), (150, 80, 80, 255), True)
create_placeholder(base + "/sprites/enemies/zombie_tank.png", (48, 56), (80, 40, 40, 255), True)
create_placeholder(base + "/sprites/enemies/zombie_spitter.png", (28, 44), (120, 60, 120, 255), True)
create_placeholder(base + "/sprites/enemies/boss_miniboss.png", (64, 72), (60, 30, 60, 255), True)

# Drops
create_placeholder(base + "/sprites/drops/drop_crystal.png", (16, 16), (100, 200, 255, 255), True)
create_placeholder(base + "/sprites/drops/drop_metal.png", (16, 16), (150, 150, 150, 255), True)
create_placeholder(base + "/sprites/drops/drop_organic.png", (16, 16), (100, 150, 100, 255), True)
create_placeholder(base + "/sprites/drops/drop_fuel.png", (16, 16), (200, 150, 50, 255), True)
create_placeholder(base + "/sprites/drops/drop_rare.png", (16, 16), (255, 200, 100, 255), True)

# Facilities
create_placeholder(base + "/sprites/facilities/facility_turret.png", (32, 32), (100, 100, 150, 255), True)
create_placeholder(base + "/sprites/facilities/facility_workshop.png", (48, 32), (150, 100, 100, 255), True)
create_placeholder(base + "/sprites/facilities/facility_storage.png", (48, 32), (100, 150, 100, 255), True)
create_placeholder(base + "/sprites/facilities/facility_generator.png", (32, 32), (150, 150, 200, 255), True)
create_placeholder(base + "/sprites/facilities/facility_barrier.png", (64, 16), (80, 80, 80, 255), True)

# UI
create_placeholder(base + "/sprites/ui/icon_health.png", (24, 24), (200, 50, 50, 255), True)
create_placeholder(base + "/sprites/ui/icon_magic.png", (24, 24), (50, 200, 200, 255), True)
create_placeholder(base + "/sprites/ui/icon_time.png", (24, 24), (200, 200, 50, 255), True)
create_placeholder(base + "/sprites/ui/icon_warning.png", (24, 24), (255, 100, 50, 255), True)
create_placeholder(base + "/sprites/ui/icon_day.png", (24, 24), (255, 255, 200, 255), True)
create_placeholder(base + "/sprites/ui/icon_night.png", (24, 24), (50, 50, 150, 255), True)
create_placeholder(base + "/sprites/ui/cursor_default.png", (16, 16), (200, 200, 200, 255), True)
create_placeholder(base + "/sprites/ui/cursor_target.png", (16, 16), (255, 50, 50, 255), True)

print("Done: 25 placeholder sprites created")