"""
BC7 解码器 - 用于解码 War Selection 的 KTX2 纹理
BC7 是一种复杂的块压缩格式，有6种模式
"""
import struct
from PIL import Image
import os

Image.MAX_IMAGE_PIXELS = None

def extract_bits(data, offset, num_bits):
    """从数据中提取指定数量的位"""
    byte_offset = offset // 8
    bit_offset = offset % 8

    result = 0
    bits_extracted = 0

    while bits_extracted < num_bits:
        if byte_offset >= len(data):
            return result

        current_byte = data[byte_offset]
        bits_available = 8 - bit_offset
        bits_needed = num_bits - bits_extracted
        bits_to_take = min(bits_available, bits_needed)

        mask = ((1 << bits_to_take) - 1) << bit_offset
        extracted = (current_byte & mask) >> bit_offset

        result |= extracted << bits_extracted
        bits_extracted += bits_to_take

        byte_offset += 1
        bit_offset = 0

    return result

def interpolate_color(c0, c1, w0, w1, total):
    """插值颜色"""
    return (
        (c0[0] * w0 + c1[0] * w1) // total,
        (c0[1] * w0 + c1[1] * w1) // total,
        (c0[2] * w0 + c1[2] * w1) // total,
    )

def interpolate_alpha(a0, a1, w0, w1, total):
    """插值alpha"""
    return (a0 * w0 + a1 * w1) // total

def decode_bc7_block(block_data):
    """解码单个BC7块"""
    # 确定模式 - 前7位，但只有6种模式(0-5)
    # 模式由第一个字节的前几位决定

    first_byte = block_data[0]

    # 检测模式：找到第一个为1的位
    mode = -1
    for i in range(8):
        if (first_byte >> i) & 1:
            mode = i
            break

    if mode > 5:
        mode = 5  # 限制到有效模式

    # 16像素的颜色
    colors = []

    # 根据模式解码
    if mode == 0:
        # Mode 0: 4-bit indices, 2 endpoints
        # Bit layout: mode(1) + endpoints(10*4=40) + indices(16*4=64) + padding
        # 实际: mode bit + partition(5) + endpoints + indices

        # 简化处理：假设均匀分布
        r0 = block_data[1] if len(block_data) > 1 else 0
        g0 = block_data[2] if len(block_data) > 2 else 0
        b0 = block_data[3] if len(block_data) > 3 else 0
        a0 = 255

        r1 = block_data[4] if len(block_data) > 4 else r0
        g1 = block_data[5] if len(block_data) > 5 else g0
        b1 = block_data[6] if len(block_data) > 6 else b0
        a1 = 255

        c0 = (r0, g0, b0)
        c1 = (r1, g1, b1)

        palette = [
            c0,
            c1,
            interpolate_color(c0, c1, 2, 1, 3),
            interpolate_color(c0, c1, 1, 2, 3),
        ]

        # 读取索引
        for py in range(4):
            for px in range(4):
                idx_pos = 48 + (py * 4 + px) * 2
                idx = extract_bits(block_data, idx_pos, 2)
                colors.append((*palette[idx], a0))

    elif mode == 1:
        # Mode 1: 3-bit indices
        r0 = (block_data[1] >> 4) * 17 if len(block_data) > 1 else 0
        g0 = (block_data[1] & 0xF) * 17
        b0 = (block_data[2] >> 4) * 17 if len(block_data) > 2 else 0

        r1 = (block_data[2] & 0xF) * 17
        g1 = (block_data[3] >> 4) * 17 if len(block_data) > 3 else 0
        b1 = (block_data[3] & 0xF) * 17

        c0 = (r0, g0, b0)
        c1 = (r1, g1, b1)

        palette = [
            c0, c1,
            interpolate_color(c0, c1, 4, 1, 5),
            interpolate_color(c0, c1, 3, 2, 5),
            interpolate_color(c0, c1, 2, 3, 5),
            interpolate_color(c0, c1, 1, 4, 5),
            (0, 0, 0),
            (255, 255, 255),
        ]

        for py in range(4):
            for px in range(4):
                idx_pos = 65 + (py * 4 + px) * 3
                idx = extract_bits(block_data, idx_pos, 3)
                alpha = 255 if idx < 6 else (0 if idx == 6 else 255)
                colors.append((*palette[idx], alpha))

    elif mode == 4:
        # Mode 4: 单独的alpha + 2-bit indices
        # 更简单的模式
        a0 = block_data[1] if len(block_data) > 1 else 255
        a1 = block_data[2] if len(block_data) > 2 else 255

        r0 = block_data[3] if len(block_data) > 3 else 0
        g0 = block_data[4] if len(block_data) > 4 else 0
        b0 = block_data[5] if len(block_data) > 5 else 0

        r1 = block_data[6] if len(block_data) > 6 else 0
        g1 = block_data[7] if len(block_data) > 7 else 0
        b1 = block_data[8] if len(block_data) > 8 else 0

        c0 = (r0, g0, b0)
        c1 = (r1, g1, b1)

        palette = [
            (c0, a0),
            (c1, a1),
            (interpolate_color(c0, c1, 2, 1, 3), interpolate_alpha(a0, a1, 2, 1, 3)),
            (interpolate_color(c0, c1, 1, 2, 3), interpolate_alpha(a0, a1, 1, 2, 3)),
        ]

        for py in range(4):
            for px in range(4):
                idx_pos = 72 + (py * 4 + px) * 2
                idx = extract_bits(block_data, idx_pos, 2)
                colors.append((*palette[idx][0], palette[idx][1]))

    elif mode == 5:
        # Mode 5: 类似Mode 4但alpha范围不同
        a0 = block_data[1] if len(block_data) > 1 else 255
        a1 = block_data[2] if len(block_data) > 2 else 255

        r0 = block_data[3] if len(block_data) > 3 else 128
        g0 = block_data[4] if len(block_data) > 4 else 128
        b0 = block_data[5] if len(block_data) > 5 else 128

        r1 = block_data[6] if len(block_data) > 6 else 128
        g1 = block_data[7] if len(block_data) > 7 else 128
        b1 = block_data[8] if len(block_data) > 8 else 128

        c0 = (r0, g0, b0)
        c1 = (r1, g1, b1)

        palette = [
            (c0, a0),
            (c1, a1),
            (interpolate_color(c0, c1, 1, 1, 2), interpolate_alpha(a0, a1, 1, 1, 2)),
            (c0, a0),  # 重复
        ]

        for py in range(4):
            for px in range(4):
                idx_pos = 72 + (py * 4 + px) * 2
                idx = extract_bits(block_data, idx_pos, 2)
                colors.append((*palette[idx][0], palette[idx][1]))

    else:
        # Mode 2, 3 或未知 - 使用简化解码
        # 直接使用原始字节作为颜色
        for py in range(4):
            for px in range(4):
                byte_idx = (py * 4 + px) % 16
                if byte_idx < len(block_data):
                    colors.append((
                        block_data[byte_idx % 16] if byte_idx % 16 < len(block_data) else 128,
                        block_data[(byte_idx + 4) % 16] if (byte_idx + 4) % 16 < len(block_data) else 128,
                        block_data[(byte_idx + 8) % 16] if (byte_idx + 8) % 16 < len(block_data) else 128,
                        block_data[(byte_idx + 12) % 16] if (byte_idx + 12) % 16 < len(block_data) else 255,
                    ))

    return colors

def decode_bc7(data, width, height):
    """解码BC7纹理"""
    img = Image.new('RGBA', (width, height))
    pixels = img.load()

    block_size = 16
    offset = 0

    blocks_x = width // 4
    blocks_y = height // 4

    for by in range(blocks_y):
        for bx in range(blocks_x):
            block_data = data[offset:offset + block_size]

            colors = decode_bc7_block(block_data)

            for py in range(4):
                for px in range(4):
                    y = by * 4 + py
                    x = bx * 4 + px
                    pixel_idx = py * 4 + px

                    if pixel_idx < len(colors) and y < height and x < width:
                        pixels[x, y] = colors[pixel_idx]

            offset += block_size

    return img

def decode_bc4(data, width, height):
    """解码BC4纹理（单通道灰度）"""
    img = Image.new('L', (width, height))
    pixels = img.load()

    block_size = 16
    offset = 0

    for by in range(height // 4):
        for bx in range(width // 4):
            block_data = data[offset:offset + 16]

            a0 = block_data[0]
            a1 = block_data[1]

            if a0 > a1:
                alphas = [a0, a1,
                          (6*a0 + a1) // 7, (5*a0 + 2*a1) // 7,
                          (4*a0 + 3*a1) // 7, (3*a0 + 4*a1) // 7,
                          (2*a0 + 5*a1) // 7, (a0 + 6*a1) // 7]
            else:
                alphas = [a0, a1,
                          (4*a0 + a1) // 5, (3*a0 + 2*a1) // 7,
                          (2*a0 + 3*a1) // 7, (a0 + 4*a1) // 7, 0, 255]

            # 解码3位索引
            for py in range(4):
                for px in range(4):
                    y = by * 4 + py
                    x = bx * 4 + px

                    bit_pos = (py * 4 + px) * 3
                    idx = extract_bits(block_data[2:8], bit_pos, 3)

                    pixels[x, y] = alphas[idx]

            offset += 16

    return img

def read_ktx2_texture(ktx2_path):
    """读取KTX2纹理"""
    file_size = os.path.getsize(ktx2_path)

    with open(ktx2_path, 'rb') as f:
        # KTX2 Header (80 bytes)
        identifier = f.read(12)
        if identifier[:7] != b'\xabKTX 20':
            return None

        vk_format = struct.unpack('<I', f.read(4))[0]
        type_size = struct.unpack('<I', f.read(4))[0]
        width = struct.unpack('<I', f.read(4))[0]
        height = struct.unpack('<I', f.read(4))[0]
        pixel_depth = struct.unpack('<I', f.read(4))[0]
        layer_count = struct.unpack('<I', f.read(4))[0]
        face_count = struct.unpack('<I', f.read(4))[0]
        level_count = struct.unpack('<I', f.read(4))[0]
        supercompression = struct.unpack('<I', f.read(4))[0]

        dfd_offset = struct.unpack('<I', f.read(4))[0]
        dfd_length = struct.unpack('<I', f.read(4))[0]
        kvp_offset = struct.unpack('<I', f.read(4))[0]
        kvp_length = struct.unpack('<I', f.read(4))[0]
        sgd_offset = struct.unpack('<I', f.read(4))[0]
        sgd_length = struct.unpack('<I', f.read(4))[0]

        # Level index starts at byte 80, each level is 24 bytes
        # 使用第一层（最高分辨率）
        level_idx = 0
        f.seek(80 + level_idx * 24)
        byte_offset = struct.unpack('<Q', f.read(8))[0]
        byte_length = struct.unpack('<Q', f.read(8))[0]
        uncompressed_length = struct.unpack('<Q', f.read(8))[0]

        # Read texture data
        f.seek(byte_offset)
        data = f.read(byte_length)

        # 确定格式：根据数据大小判断
        # BC1: 8 bytes/block = 8192 for 128x128
        # BC4: 16 bytes/block = 16384 for 128x128
        # BC7: 16 bytes/block = 16384 for 128x128
        # Uncompressed RGBA: width*height*4

        expected_bc1 = (width // 4) * (height // 4) * 8
        expected_bc4_bc7 = (width // 4) * (height // 4) * 16
        expected_rgba = width * height * 4

        basename = os.path.basename(ktx2_path)

        # 根据文件名判断格式
        if 'mask' in basename.lower() or 'roughness' in basename.lower() or 'metalness' in basename.lower():
            # 这些通常是单通道BC4
            return decode_bc4(data, width, height)
        elif byte_length == expected_rgba:
            # 未压缩RGBA
            img = Image.new('RGBA', (width, height))
            pixels = img.load()
            for y in range(height):
                for x in range(width):
                    offset = (y * width + x) * 4
                    pixels[x, y] = (data[offset], data[offset+1], data[offset+2], data[offset+3])
            return img
        else:
            # 默认使用BC7解码
            return decode_bc7(data, width, height)

def convert_ktx2_to_png(ktx2_path, png_path):
    """转换KTX2到PNG"""
    try:
        img = read_ktx2_texture(ktx2_path)
        if img:
            img.save(png_path)
            return True
    except Exception as e:
        print(f'Error: {e}')
    return False