#!/usr/bin/env python3
# generate_ambient_sfx.py
# 生成环境音效

import wave
import struct
import math
import os

SAMPLE_RATE = 44100
BIT_DEPTH = 16
CHANNELS = 1

def generate_wind(duration: float, amplitude: float = 0.15) -> bytes:
    """生成风声（低频噪音 + 轻微调制）"""
    samples = int(SAMPLE_RATE * duration)
    data = []
    for i in range(samples):
        t = i / SAMPLE_RATE
        # 低频噪音模拟风声
        noise = (i % 100) / 100.0  # 简化的伪随机
        mod = math.sin(2 * math.pi * 0.5 * t) * 0.3 + 0.7
        value = amplitude * noise * mod
        sample = int(value * 32767)
        data.append(sample)
    return struct.pack('<' + 'h' * len(data), *data)

def write_wav(filepath: str, data: bytes) -> None:
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'wb') as wav:
        wav.setnchannels(CHANNELS)
        wav.setsampwidth(BIT_DEPTH // 8)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(data)
    print(f"Generated: {filepath}")

base_path = "assets/audio/ambient"
write_wav(f"{base_path}/day_breeze.wav", generate_wind(30, 0.12))
write_wav(f"{base_path}/night_wind.wav", generate_wind(30, 0.18))
write_wav(f"{base_path}/dungeon_ambience.wav", generate_wind(20, 0.08))

print("=== 环境音效生成完成 ===")