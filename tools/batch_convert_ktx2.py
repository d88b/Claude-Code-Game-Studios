"""
批量转换 War Selection 的 KTX2 纹理为 PNG
"""
import os
import sys
sys.path.insert(0, 'D:/ai/Claude-Code-Game-Studios/tools')

from ktx2_decoder import convert_ktx2_to_png, read_ktx2_texture

def batch_convert_ktx2():
    """批量转换所有KTX2文件"""
    src_dir = 'D:/Program Files (x86)/Steam/steamapps/common/War Selection/Cache/Content'
    dst_dir = 'D:/ai/Claude-Code-Game-Studios/assets/WS_KTX2_Converted'

    converted = 0
    failed = 0

    # 要转换的目录
    dirs_to_convert = ['unit', 'building', 'horde/unit', 'environment', 'particle']

    for category in dirs_to_convert:
        cat_src = os.path.join(src_dir, category)
        if os.path.exists(cat_src):
            cat_dst = os.path.join(dst_dir, category.replace('/', '_'))
            os.makedirs(cat_dst, exist_ok=True)

            ktx2_files = []
            for f in os.listdir(cat_src):
                if f.endswith('.ktx2') and 'albedo' in f:
                    ktx2_files.append(f)

            print(f'{category}: {len(ktx2_files)} albedo textures')

            for ktx2_file in ktx2_files:
                ktx2_path = os.path.join(cat_src, ktx2_file)
                png_name = ktx2_file.replace('.ktx2', '.png')
                png_path = os.path.join(cat_dst, png_name)

                try:
                    if convert_ktx2_to_png(ktx2_path, png_path):
                        converted += 1
                        print(f'  [OK] {ktx2_file}')
                    else:
                        failed += 1
                        print(f'  [FAIL] {ktx2_file}')
                except Exception as e:
                    failed += 1
                    print(f'  [ERR] {ktx2_file}: {str(e)[:30]}')

    print(f'\n=== Converted: {converted}, Failed: {failed} ===')
    return converted, failed

if __name__ == '__main__':
    batch_convert_ktx2()