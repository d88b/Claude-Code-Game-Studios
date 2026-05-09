#!/usr/bin/env python3
"""
生成占位音频文件 - 使用简单的音调作为临时音效
运行此脚本后，请在 sfxr.me 或 Bfxr 生成更高质量的音效替换
"""

import struct
import wave
import os
import math

# WAV 文件参数
SAMPLE_RATE = 44100
BIT_DEPTH = 16
CHANNELS = 1  # Mono for SFX

# 输出目录
SFX_DIRS = [
    "D:/ai/Claude-Code-Game-Studios/assets/audio/sfx/vehicle",
    "D:/ai/Claude-Code-Game-Studios/assets/audio/sfx/enemies",
    "D:/ai/Claude-Code-Game-Studios/assets/audio/sfx/ui",
    "D:/ai/Claude-Code-Game-Studios/assets/audio/sfx/digging",
    "D:/ai/Claude-Code-Game-Studios/assets/audio/sfx/placement",
    "D:/ai/Claude-Code-Game-Studios/assets/audio/sfx/resources",
    "D:/ai/Claude-Code-Game-Studios/assets/audio/sfx/game_state",
]
BGM_DIR = "D:/ai/Claude-Code-Game-Studios/assets/audio/bgm"

def generate_tone(frequency: float, duration: float, amplitude: float = 0.5) -> bytes:
    """生成简单的正弦波音调"""
    num_samples = int(SAMPLE_RATE * duration)
    samples = []

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # 简单正弦波 + 衰减
        decay = 1.0 - (i / num_samples) * 0.5  # 衰减效果
        value = amplitude * decay * math.sin(2 * math.pi * frequency * t)
        # 转换为 16-bit signed integer
        sample = int(value * 32767)
        samples.append(sample)

    # 打包为 bytes
    return struct.pack('<' + 'h' * len(samples), *samples)

def generate_noise(duration: float, amplitude: float = 0.3) -> bytes:
    """生成简单的白噪声"""
    import random
    num_samples = int(SAMPLE_RATE * duration)
    samples = []

    for i in range(num_samples):
        decay = 1.0 - (i / num_samples) * 0.8
        value = amplitude * decay * (random.random() * 2 - 1)
        sample = int(value * 32767)
        samples.append(sample)

    return struct.pack('<' + 'h' * len(samples), *samples)

def generate_chord(base_freq: float, duration: float) -> bytes:
    """生成和弦音效"""
    num_samples = int(SAMPLE_RATE * duration)
    samples = []

    # 和弦频率
    freqs = [base_freq, base_freq * 1.5, base_freq * 2]

    for i in range(num_samples):
        t = i / SAMPLE_RATE
        decay = 1.0 - (i / num_samples) * 0.6
        value = 0
        for f in freqs:
            value += 0.2 * decay * math.sin(2 * math.pi * f * t)
        sample = int(value * 32767)
        samples.append(sample)

    return struct.pack('<' + 'h' * len(samples), *samples)

def write_wav(filename: str, data: bytes):
    """写入 WAV 文件"""
    with wave.open(filename, 'wb') as wav:
        wav.setnchannels(CHANNELS)
        wav.setsampwidth(BIT_DEPTH // 8)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(data)
    print(f"Created: {filename}")

def create_sfx_files():
    """创建 SFX 文件"""
    # 确保 SFX 目录存在
    for dir_path in SFX_DIRS:
        os.makedirs(dir_path, exist_ok=True)

    # Vehicle SFX
    sfx_list = [
        # vehicle
        (f"{SFX_DIRS[0]}/weapon_fire.wav", generate_noise(0.15, 0.6), "武器射击"),
        (f"{SFX_DIRS[0]}/vehicle_deploy.wav", generate_chord(200, 0.5), "战车部署"),
        (f"{SFX_DIRS[0]}/vehicle_return.wav", generate_chord(150, 0.6), "战车返回"),
        (f"{SFX_DIRS[0]}/weapon_hit.wav", generate_noise(0.2, 0.4), "命中音效"),
        # enemies
        (f"{SFX_DIRS[1]}/zombie_attack.wav", generate_tone(100, 0.3, 0.5), "僵尸攻击"),
        (f"{SFX_DIRS[1]}/zombie_death.wav", generate_noise(0.5, 0.5), "僵尸死亡"),
        # ui
        (f"{SFX_DIRS[2]}/ui_click.wav", generate_tone(800, 0.05, 0.3), "UI 点击"),
        (f"{SFX_DIRS[2]}/ui_confirm.wav", generate_chord(600, 0.1), "UI 确认"),
        (f"{SFX_DIRS[2]}/ui_warning.wav", generate_tone(400, 0.4, 0.6), "UI 警告"),
        # digging
        (f"{SFX_DIRS[3]}/dig_complete.wav", generate_noise(0.3, 0.4), "挖掘完成"),
        # placement
        (f"{SFX_DIRS[4]}/place_success.wav", generate_chord(300, 0.2), "放置成功"),
        # resources
        (f"{SFX_DIRS[5]}/pickup_generic.wav", generate_tone(1000, 0.1, 0.4), "拾取资源"),
        # game_state
        (f"{SFX_DIRS[6]}/daynight_transition.wav", generate_chord(250, 0.8), "日夜转换"),
        (f"{SFX_DIRS[6]}/explosion.wav", generate_noise(0.8, 0.7), "爆炸"),
    ]

    for filepath, data, desc in sfx_list:
        write_wav(filepath, data)

def create_bgm_files():
    """创建 BGM 文件（简单循环）"""
    os.makedirs(BGM_DIR, exist_ok=True)

    # BGM 使用更长、更柔和的音调组合
    bgm_list = [
        (f"{BGM_DIR}/bgm_day.wav", 0.5, 400, "白天探索"),
        (f"{BGM_DIR}/bgm_night.wav", 0.5, 200, "夜晚防守"),
        (f"{BGM_DIR}/bgm_menu.wav", 0.5, 350, "主菜单"),
    ]

    for filepath, duration, base_freq, desc in bgm_list:
        # 生成简单的背景音乐循环（实际应该用更好的工具）
        data = generate_chord(base_freq, duration)
        write_wav(filepath, data)
        print(f"  Note: {desc} - 请用更好的音乐替换")

def main():
    print("=" * 50)
    print("占位音频生成器")
    print("=" * 50)
    print("这些是临时音效，请用 sfxr.me 生成的音效替换")
    print()

    create_sfx_files()
    print()
    create_bgm_files()

    print()
    print("=" * 50)
    print("完成！下一步:")
    print("1. 访问 https://sfxr.me 生成更好的音效")
    print("2. 下载 WAV 文件替换 assets/audio/ 目录中的占位文件")
    print("3. 确保 AudioManager 正确加载音效")
    print("=" * 50)

if __name__ == "__main__":
    main()