import os
import hashlib

def generate_import_file(file_path, project_root):
    ext = os.path.splitext(file_path)[1].lower()

    if ext not in ['.png', '.svg', '.wav', '.mp3', '.ogg']:
        return False

    name_hash = hashlib.md5(os.path.basename(file_path).encode()).hexdigest()[:16]

    # 安全处理路径 - 使用正斜杠
    rel_path = os.path.relpath(file_path, project_root)
    rel_path = rel_path.replace(chr(92), '/')  # chr(92) is backslash
    rel_path = 'res://' + rel_path

    import_path = file_path + '.import'

    if ext in ['.png', '.svg']:
        basename = os.path.basename(file_path)
        content = f"""[remap]
importer="texture"
type="CompressedTexture2D"
uid="uid_{name_hash}"
path="res://.godot/imported/{basename}-{name_hash}.ctex"
metadata={{
"vram_texture": false
}}

[deps]
source_file="{rel_path}"
dest_files=["res://.godot/imported/{basename}-{name_hash}.ctex"]

[params]
compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=0
"""
    elif ext in ['.wav']:
        basename = os.path.basename(file_path)
        content = f"""[remap]
importer="wav"
type="AudioStreamWAV"
uid="uid_{name_hash}"
path="res://.godot/imported/{basename}-{name_hash}.wav"

[deps]
source_file="{rel_path}"
dest_files=["res://.godot/imported/{basename}-{name_hash}.wav"]

[params]
force/8_bit=false
force/mono=false
force/max_rate=false
force/max_rate_hz=44100
edit/trim=false
edit/normalize=false
edit/loop_mode=0
edit/loop_begin=0
edit/loop_end=-1
compress/mode=0
"""
    elif ext in ['.mp3', '.ogg']:
        basename = os.path.basename(file_path)
        content = f"""[remap]
importer="{ext[1:]}"
type="AudioStream{ext[1:].upper()}"
uid="uid_{name_hash}"
path="res://.godot/imported/{basename}-{name_hash}.{ext[1:]}"

[deps]
source_file="{rel_path}"
dest_files=["res://.godot/imported/{basename}-{name_hash}.{ext[1:]}"]

[params]
loop=false
loop_offset=0
"""
    else:
        return False

    with open(import_path, 'w', encoding='utf-8') as f:
        f.write(content)
    return True

# 批量生成
project_root = 'D:/ai/Claude-Code-Game-Studios'
assets_dir = os.path.join(project_root, 'assets')
dirs_to_process = ['TAB_Sprites', 'TAB_Atlas', 'TAB_Extracted', 'Zombies', 'Units', 'WS_KTX2_Converted', 'WarSelection', 'WarSelection_Full']

generated = 0
skipped = 0

for dir_name in dirs_to_process:
    dir_path = os.path.join(assets_dir, dir_name)
    if os.path.exists(dir_path):
        for root, dirs, files in os.walk(dir_path):
            for f in files:
                if f.endswith(('.png', '.svg', '.wav', '.mp3', '.ogg')):
                    file_path = os.path.join(root, f)
                    import_path = file_path + '.import'

                    if not os.path.exists(import_path):
                        if generate_import_file(file_path, project_root):
                            generated += 1
                    else:
                        skipped += 1

print(f'Generated: {generated} import files')
print(f'Skipped (existing): {skipped} import files')