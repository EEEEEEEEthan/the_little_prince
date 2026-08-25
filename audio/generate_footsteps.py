#!/usr/bin/env python3
"""生成短促土地闷响、草地沙沙、老鼠吱声与玻璃罩放下 one-shot（CC0）。运行：python3 audio/generate_footsteps.py"""

from __future__ import annotations

import math
import wave
from pathlib import Path

import numpy as np

SAMPLE_RATE = 22050
SAMPLE_WIDTH_BYTES = 2


def one_pole_lowpass(samples: np.ndarray, cutoff_hertz: float) -> np.ndarray:
	coefficient = math.exp(-2.0 * math.pi * cutoff_hertz / SAMPLE_RATE)
	filtered = np.empty_like(samples)
	previous = 0.0
	for index, sample in enumerate(samples):
		previous = (1.0 - coefficient) * sample + coefficient * previous
		filtered[index] = previous
	return filtered


def one_pole_highpass(samples: np.ndarray, cutoff_hertz: float) -> np.ndarray:
	return samples - one_pole_lowpass(samples, cutoff_hertz)


def fade_edges(samples: np.ndarray, fade_samples: int) -> np.ndarray:
	faded = samples.copy()
	ramp = np.linspace(0.0, 1.0, fade_samples)
	faded[:fade_samples] *= ramp
	faded[-fade_samples:] *= ramp[::-1]
	return faded


def write_wav(samples: np.ndarray, output_path: Path) -> None:
	peak = np.max(np.abs(samples))
	normalized = samples / peak * 0.85 if peak > 0.0 else samples
	pcm = np.clip(normalized * 32767.0, -32768.0, 32767.0).astype(np.int16)
	with wave.open(str(output_path), "w") as wav_file:
		wav_file.setnchannels(1)
		wav_file.setsampwidth(SAMPLE_WIDTH_BYTES)
		wav_file.setframerate(SAMPLE_RATE)
		wav_file.writeframes(pcm.tobytes())


def render_dirt_thud(seed: int, thud_hertz: float) -> np.ndarray:
	rng = np.random.default_rng(seed)
	duration_seconds = 0.11
	sample_count = int(SAMPLE_RATE * duration_seconds)
	time_seconds = np.arange(sample_count, dtype=np.float64) / SAMPLE_RATE
	noise = one_pole_lowpass(rng.normal(0.0, 1.0, sample_count), 420.0)
	body = np.sin(2.0 * math.pi * thud_hertz * time_seconds)
	envelope = np.exp(-time_seconds / 0.028)
	mixed = fade_edges(envelope * (0.72 * body + 0.55 * noise), 8)
	return mixed


def render_thin_rat_squeak() -> np.ndarray:
	rng = np.random.default_rng(9)
	duration_seconds = 0.14
	sample_count = int(SAMPLE_RATE * duration_seconds)
	time_seconds = np.arange(sample_count, dtype=np.float64) / SAMPLE_RATE
	envelope = np.exp(-time_seconds / 0.028) * (1.0 - np.exp(-time_seconds / 0.004))
	chirp_hertz = 2100.0 + 900.0 * np.exp(-time_seconds / 0.05)
	tone = 0.72 * np.sin(2.0 * math.pi * chirp_hertz * time_seconds)
	overtone = 0.22 * np.sin(2.0 * math.pi * chirp_hertz * 2.03 * time_seconds)
	noise = rng.normal(0.0, 0.08, sample_count)
	return fade_edges(envelope * (tone + overtone + noise), 12)


def render_light_glass_rim_clink() -> np.ndarray:
	rng = np.random.default_rng(13)
	duration_seconds = 0.2
	sample_count = int(SAMPLE_RATE * duration_seconds)
	time_seconds = np.arange(sample_count, dtype=np.float64) / SAMPLE_RATE
	thud_envelope = np.exp(-time_seconds / 0.032)
	thud = thud_envelope * np.sin(2.0 * math.pi * 124.0 * time_seconds)
	tick_envelope = np.exp(-time_seconds / 0.02) * (1.0 - np.exp(-time_seconds / 0.0018))
	tick_hertz = 1760.0 + 380.0 * np.exp(-time_seconds / 0.035)
	tick = tick_envelope * (
		0.58 * np.sin(2.0 * math.pi * tick_hertz * time_seconds)
		+ 0.26 * np.sin(2.0 * math.pi * tick_hertz * 2.02 * time_seconds)
	)
	contact_noise = (
		np.exp(-time_seconds / 0.014)
		* one_pole_highpass(one_pole_lowpass(rng.normal(0.0, 1.0, sample_count), 4200.0), 700.0)
		* 0.32
	)
	return fade_edges(0.88 * thud + 0.52 * tick + contact_noise, 10)


def render_grass_rustle(seed: int) -> np.ndarray:
	rng = np.random.default_rng(seed)
	duration_seconds = 0.13
	sample_count = int(SAMPLE_RATE * duration_seconds)
	time_seconds = np.arange(sample_count, dtype=np.float64) / SAMPLE_RATE
	noise = rng.normal(0.0, 1.0, sample_count)
	rustle = one_pole_highpass(one_pole_lowpass(noise, 5200.0), 1400.0)
	flutter = 0.55 + 0.45 * np.sin(2.0 * math.pi * 38.0 * time_seconds + seed)
	envelope = np.exp(-time_seconds / 0.045) * flutter
	return fade_edges(rustle * envelope, 10)


def main() -> None:
	output_directory = Path(__file__).resolve().parent
	write_wav(render_dirt_thud(11, 92.0), output_directory / "muffled_dirt_thud_a.wav")
	write_wav(render_dirt_thud(23, 108.0), output_directory / "muffled_dirt_thud_b.wav")
	write_wav(render_grass_rustle(41), output_directory / "dry_grass_rustle_a.wav")
	write_wav(render_grass_rustle(67), output_directory / "dry_grass_rustle_b.wav")
	write_wav(render_thin_rat_squeak(), output_directory / "thin_rat_squeak.wav")
	write_wav(render_light_glass_rim_clink(), output_directory / "light_glass_rim_clink.wav")


if __name__ == "__main__":
	main()
