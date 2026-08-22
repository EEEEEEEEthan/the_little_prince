#!/usr/bin/env python3
"""生成短促软土颗粒与草地沙沙 one-shot（CC0）。运行：python3 audio/generate_footsteps.py"""

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


def render_soft_soil_grit(seed: int, grit_gain: float) -> np.ndarray:
	rng = np.random.default_rng(seed)
	duration_seconds = 0.085
	sample_count = int(SAMPLE_RATE * duration_seconds)
	time_seconds = np.arange(sample_count, dtype=np.float64) / SAMPLE_RATE
	white = rng.normal(0.0, 1.0, sample_count)
	soft_body = one_pole_lowpass(white, 640.0)
	grit = one_pole_highpass(one_pole_lowpass(white, 7600.0), 2100.0)
	grain_ticks = np.zeros(sample_count)
	grain_count = 6
	for _grain_index in range(grain_count):
		center = int(rng.integers(6, max(7, sample_count // 2)))
		half_width = int(rng.integers(2, 6))
		start = max(0, center - half_width)
		end = min(sample_count, center + half_width)
		grain = rng.normal(0.0, 1.0, end - start)
		grain_ticks[start:end] += one_pole_highpass(grain, 1700.0)
	body_envelope = np.exp(-time_seconds / 0.016)
	grit_envelope = np.exp(-time_seconds / 0.011)
	mixed = (
		0.48 * soft_body * body_envelope
		+ grit_gain * grit * grit_envelope
		+ 0.32 * grain_ticks * grit_envelope
	)
	return fade_edges(mixed, 5)


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
	write_wav(render_soft_soil_grit(11, 0.62), output_directory / "soft_soil_grit_a.wav")
	write_wav(render_soft_soil_grit(23, 0.74), output_directory / "soft_soil_grit_b.wav")
	write_wav(render_grass_rustle(41), output_directory / "dry_grass_rustle_a.wav")
	write_wav(render_grass_rustle(67), output_directory / "dry_grass_rustle_b.wav")


if __name__ == "__main__":
	main()
