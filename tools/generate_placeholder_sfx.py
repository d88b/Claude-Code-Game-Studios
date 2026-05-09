#!/usr/bin/env python3
# generate_placeholder_sfx.py
# 使用 Python wave 模块生成占位音效

import wave
import struct
import math
import random
import os

# 音频参数
SAMPLE_RATE = 44100
BIT_DEPTH = 16
CHANNELS = 1  # Mono for SFX

def generate_sine_wave(freq: float, duration: float, amplitude: float = 0.5) -> bytes:
    """生成正弦波"""
    samples = int(SAMPLE_RATE * duration)
    data = []
    for i in range(samples):
        t = i / SAMPLE_RATE
        value = amplitude * math.sin(2 * math.pi * freq * t)
        # 添加衰减
        decay = 1.0 - (i / samples) * 0.7
        value *= decay
        # 转换为 16-bit 整数
        sample = int(value * 32767)
        data.append(sample)
    return struct.pack('<' + 'h' * len(data), *data)

def generate_square_wave(freq: float, duration: float, amplitude: float = 0.3) -> bytes:
    """生成方波（8-bit 风格）"""
    samples = int(SAMPLE_RATE * duration)
    data = []
    for i in range(samples):
        t = i / SAMPLE_RATE
        phase = (2 * math.pi * freq * t) % (2 * math.pi)
        value = amplitude if phase < math.pi else -amplitude
        # 衰减
        decay = 1.0 - (i / samples) * 0.8
        value *= decay
        sample = int(value * 32767)
        data.append(sample)
    return struct.pack('<' + 'h' * len(data), *data)

def generate_noise(duration: float, amplitude: float = 0.3, decay: bool = True) -> bytes:
    """生成白噪音"""
    samples = int(SAMPLE_RATE * duration)
    data = []
    for i in range(samples):
        value = amplitude * (random.random() * 2 - 1)
        if decay:
            decay_factor = 1.0 - (i / samples) * 0.9
            value *= decay_factor
        sample = int(value * 32767)
        data.append(sample)
    return struct.pack('<' + 'h' * len(data), *data)

def generate_chirp(start_freq: float, end_freq: float, duration: float, amplitude: float = 0.4) -> bytes:
    """生成频率扫描（激光/爆炸效果）"""
    samples = int(SAMPLE_RATE * duration)
    data = []
    for i in range(samples):
        t = i / SAMPLE_RATE
        freq = start_freq + (end_freq - start_freq) * (t / duration)
        value = amplitude * math.sin(2 * math.pi * freq * t)
        # 衰减
        decay = 1.0 - (t / duration) * 0.95
        value *= decay
        sample = int(value * 32767)
        data.append(sample)
    return struct.pack('<' + 'h' * len(data), *data)

def generate_click(duration: float = 0.05) -> bytes:
    """生成 UI 点击音"""
    return generate_square_wave(800, duration, 0.4)

def generate_explosion(duration: float = 0.5) -> bytes:
    """生成爆炸音效"""
    noise_part = generate_noise(duration * 0.7, 0.5, True)
    bass_part = generate_chirp(150, 30, duration * 0.3, 0.6)
    # 混合
    noise_samples = struct.unpack('<' + 'h' * (len(noise_part) // 2), noise_part)
    bass_samples = struct.unpack('<' + 'h' * (len(bass_part) // 2), bass_part)
    mixed = []
    for i in range(len(noise_samples)):
        if i < len(bass_samples):
            val = int((noise_samples[i] + bass_samples[i]) / 2)
        else:
            val = noise_samples[i]
        mixed.append(val)
    return struct.pack('<' + 'h' * len(mixed), *mixed)

def generate_zombie_death(duration: float = 0.6) -> bytes:
    """生成僵尸死亡音效"""
    # 低沉的呻吟 + 噪音
    groan = generate_chirp(200, 80, duration, 0.4)
    noise = generate_noise(duration, 0.2, True)
    groan_samples = struct.unpack('<' + 'h' * (len(groan) // 2), groan)
    noise_samples = struct.unpack('<' + 'h' * (len(noise) // 2), noise)
    mixed = []
    for i in range(len(groan_samples)):
        val = int((groan_samples[i] + noise_samples[i]) / 2)
        mixed.append(val)
    return struct.pack('<' + 'h' * len(mixed), *mixed)

def write_wav(filepath: str, data: bytes) -> None:
    """写入 WAV 文件"""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'wb') as wav:
        wav.setnchannels(CHANNELS)
        wav.setsampwidth(BIT_DEPTH // 8)
        wav.setframerate(SAMPLE_RATE)
        wav.writeframes(data)
    print(f"Generated: {filepath}")

def main():
    base_path = "assets/audio"

    # === 战车音效 ===
    write_wav(f"{base_path}/sfx/vehicle/weapon_fire.wav", generate_chirp(1200, 400, 0.15, 0.5))
    write_wav(f"{base_path}/sfx/vehicle/weapon_hit.wav", generate_square_wave(600, 0.08, 0.35))
    write_wav(f"{base_path}/sfx/vehicle/vehicle_deploy.wav", generate_chirp(300, 500, 0.5, 0.4))
    write_wav(f"{base_path}/sfx/vehicle/vehicle_return.wav", generate_chirp(500, 200, 0.6, 0.3))

    # === 敌人音效 ===
    write_wav(f"{base_path}/sfx/enemies/zombie_attack.wav", generate_chirp(150, 300, 0.3, 0.35))
    write_wav(f"{base_path}/sfx/enemies/zombie_death.wav", generate_zombie_death(0.6))

    # === UI 音效 ===
    write_wav(f"{base_path}/sfx/ui/ui_click.wav", generate_click(0.05))
    write_wav(f"{base_path}/sfx/ui/ui_confirm.wav", generate_square_wave(500, 0.12, 0.35))
    write_wav(f"{base_path}/sfx/ui/ui_warning.wav", generate_square_wave(800, 0.25, 0.45))

    # === 挖掘音效 ===
    write_wav(f"{base_path}/sfx/digging/dig_complete.wav", generate_noise(0.25, 0.3, True))

    # === 放置音效 ===
    write_wav(f"{base_path}/sfx/placement/place_success.wav", generate_square_wave(400, 0.2, 0.3))

    # === 日夜转换 ===
    write_wav(f"{base_path}/sfx/game_state/daynight_transition.wav", generate_chirp(400, 600, 0.6, 0.25))

    # === 爆炸 ===
    write_wav(f"{base_path}/sfx/game_state/explosion.wav", generate_explosion(0.5))

    # === 拾取 ===
    write_wav(f"{base_path}/sfx/resources/pickup_generic.wav", generate_chirp(800, 1200, 0.15, 0.35))

    # === 新增音效 ===
    write_wav(f"{base_path}/sfx/vehicle/engine_idle.wav", generate_square_wave(60, 2.0, 0.15))
    write_wav(f"{base_path}/sfx/vehicle/engine_accel.wav", generate_chirp(50, 120, 1.5, 0.2))
    write_wav(f"{base_path}/sfx/digging/dig_start.wav", generate_noise(0.15, 0.25, True))
    write_wav(f"{base_path}/sfx/digging/dig_loop.wav", generate_noise(0.3, 0.2, False))
    write_wav(f"{base_path}/sfx/enemies/zombie_idle.wav", generate_chirp(80, 120, 2.0, 0.15))
    write_wav(f"{base_path}/sfx/enemies/boss_roar.wav", generate_chirp(100, 60, 1.5, 0.5))
    write_wav(f"{base_path}/sfx/facility/turret_fire.wav", generate_chirp(1000, 300, 0.12, 0.4))
    write_wav(f"{base_path}/sfx/facility/generator_loop.wav", generate_square_wave(100, 3.0, 0.1))
    write_wav(f"{base_path}/sfx/ui/ui_hover.wav", generate_click(0.03))
    write_wav(f"{base_path}/sfx/ui/ui_cancel.wav", generate_square_wave(300, 0.12, 0.3))
    write_wav(f"{base_path}/sfx/game_state/day_start.wav", generate_chirp(200, 400, 0.8, 0.3))
    write_wav(f"{base_path}/sfx/game_state/night_start.wav", generate_chirp(400, 150, 0.8, 0.35))
    write_wav(f"{base_path}/sfx/resources/drop_land.wav", generate_noise(0.2, 0.25, True))
    write_wav(f"{base_path}/sfx/facility/place.wav", generate_square_wave(350, 0.18, 0.32))
    write_wav(f"{base_path}/sfx/facility/remove.wav", generate_noise(0.15, 0.3, True))

    # === BGM (简化版) ===
    # 使用低频正弦波作为占位 BGM
    def generate_bgm_loop(duration: float, base_freq: float, amplitude: float = 0.15) -> bytes:
        samples = int(SAMPLE_RATE * duration)
        data = []
        for i in range(samples):
            t = i / SAMPLE_RATE
            # 多层正弦波叠加
            val = amplitude * (
                0.5 * math.sin(2 * math.pi * base_freq * t) +
                0.3 * math.sin(2 * math.pi * base_freq * 1.5 * t) +
                0.2 * math.sin(2 * math.pi * base_freq * 2 * t)
            )
            # 添加轻微调制
            val *= 0.9 + 0.1 * math.sin(2 * math.pi * 0.5 * t)
            sample = int(val * 32767)
            data.append(sample)
        return struct.pack('<' + 'h' * len(data), *data)

    write_wav(f"{base_path}/bgm/bgm_exploration.wav", generate_bgm_loop(30, 120, 0.12))
    write_wav(f"{base_path}/bgm/bgm_bunker.wav", generate_bgm_loop(30, 80, 0.1))
    write_wav(f"{base_path}/bgm/bgm_defense.wav", generate_bgm_loop(30, 150, 0.15))
    write_wav(f"{base_path}/bgm/bgm_victory.wav", generate_bgm_loop(10, 200, 0.18))
    write_wav(f"{base_path}/bgm/bgm_defeat.wav", generate_bgm_loop(10, 60, 0.12))

    print("\n=== 音频生成完成 ===")
    print(f"SFX: 29 个音效")
    print(f"BGM: 6 个背景音乐")
    print(f"位置: {base_path}/")

if __name__ == "__main__":
    main()