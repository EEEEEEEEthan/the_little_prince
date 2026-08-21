#!/usr/bin/env python3
"""生成可循环的 8bit 配乐（CC0）。运行：python3 audio/generate_chiptune.py"""

from __future__ import annotations

import math
import subprocess
import wave
from pathlib import Path

import numpy as np

SAMPLE_RATE = 22050
A4_MIDI = 69
A4_HERTZ = 440.0

C3, D3, G3, A3 = 48, 50, 55, 57
C4, D4, E4, G4, A4 = 60, 62, 64, 67, 69
C5, D5, E5, G5, A5, C6 = 72, 74, 76, 79, 81, 84


def midi_to_hertz(midi_note: int) -> float:
	return A4_HERTZ * (2.0 ** ((midi_note - A4_MIDI) / 12.0))


def expand_bars(bars: list[list[tuple[int | None, float]]]) -> list[tuple[float, int, float]]:
	events: list[tuple[float, int, float]] = []
	beat_position = 0.0
	for bar in bars:
		for midi_note, duration_beats in bar:
			if midi_note is not None:
				events.append((beat_position, midi_note, duration_beats))
			beat_position += duration_beats
	return events


def allocate_buffer(bar_count: int, beats_per_bar: float, beats_per_minute: float) -> np.ndarray:
	total_beats = bar_count * beats_per_bar
	sample_count = int(total_beats * SAMPLE_RATE * 60.0 / beats_per_minute)
	return np.zeros(sample_count, dtype=np.float64)


def music_box_tine(midi_note: int, sample_count: int, sample_rate: int) -> np.ndarray:
	frequency = midi_to_hertz(midi_note)
	time_seconds = np.arange(sample_count, dtype=np.float64) / sample_rate
	fundamental = np.sin(2.0 * math.pi * frequency * time_seconds)
	octave = np.sin(2.0 * math.pi * frequency * 2.0 * time_seconds)
	return fundamental + 0.16 * octave


def bandlimited_triangle(midi_note: int, sample_count: int, sample_rate: int) -> np.ndarray:
	frequency = midi_to_hertz(midi_note)
	time_seconds = np.arange(sample_count, dtype=np.float64) / sample_rate
	wave = np.zeros(sample_count, dtype=np.float64)
	max_harmonic = max(1, int((sample_rate * 0.45) / frequency))
	for harmonic_index in range(1, max_harmonic + 1, 2):
		sign = 1.0 if ((harmonic_index - 1) // 2) % 2 == 0 else -1.0
		wave += sign * np.sin(
				2.0 * math.pi * harmonic_index * frequency * time_seconds
		) / (harmonic_index * harmonic_index)
	return wave * (8.0 / (math.pi ** 2))


def mix_tine(
		buffer: np.ndarray,
		events: list[tuple[float, int, float]],
		sample_rate: int,
		beats_per_minute: float,
		volume: float,
		decay_seconds: float,
) -> None:
	samples_per_beat = sample_rate * 60.0 / beats_per_minute
	strike_seconds = 0.008
	for start_beat, midi_note, _duration_beats in events:
		start_index = int(start_beat * samples_per_beat)
		if start_index >= buffer.size:
			continue
		sample_count = min(int(decay_seconds * 4.0 * sample_rate), buffer.size - start_index)
		if sample_count <= 8:
			continue
		time_seconds = np.arange(sample_count, dtype=np.float64) / sample_rate
		strike_samples = max(2, int(strike_seconds * sample_rate))
		attack = np.ones(sample_count)
		attack[:strike_samples] = np.linspace(0.0, 1.0, strike_samples)
		envelope = attack * np.exp(-time_seconds / decay_seconds)
		wave = music_box_tine(midi_note, sample_count, sample_rate)
		buffer[start_index:start_index + sample_count] += wave * envelope * volume


def mix_triangle_drone(
		buffer: np.ndarray,
		events: list[tuple[float, int, float]],
		sample_rate: int,
		beats_per_minute: float,
		volume: float,
) -> None:
	samples_per_beat = sample_rate * 60.0 / beats_per_minute
	attack_seconds = 0.35
	release_seconds = 0.9
	for start_beat, midi_note, duration_beats in events:
		start_index = int(start_beat * samples_per_beat)
		if start_index >= buffer.size:
			continue
		sample_count = min(int(duration_beats * samples_per_beat), buffer.size - start_index)
		if sample_count <= 16:
			continue
		wave = bandlimited_triangle(midi_note, sample_count, sample_rate)
		attack_samples = min(int(attack_seconds * sample_rate), sample_count // 3)
		release_samples = min(int(release_seconds * sample_rate), sample_count // 3)
		sustain_samples = sample_count - attack_samples - release_samples
		envelope = np.concatenate(
				[
					np.linspace(0.0, 1.0, attack_samples, endpoint=False),
					np.full(max(sustain_samples, 0), 1.0),
					np.linspace(1.0, 0.0, release_samples, endpoint=True),
				]
		)[:sample_count]
		if envelope.size < sample_count:
			envelope = np.pad(envelope, (0, sample_count - envelope.size))
		buffer[start_index:start_index + sample_count] += wave * envelope * volume


def one_pole_lowpass(
		samples: np.ndarray,
		cutoff_hertz: float,
		sample_rate: int,
) -> np.ndarray:
	alpha = 1.0 - math.exp(-2.0 * math.pi * cutoff_hertz / sample_rate)
	filtered = np.empty_like(samples)
	accumulator = 0.0
	for sample_index, sample in enumerate(samples):
		accumulator += alpha * (sample - accumulator)
		filtered[sample_index] = accumulator
	return filtered


def finalize(buffer: np.ndarray) -> np.ndarray:
	softened = one_pole_lowpass(buffer, 6400.0, SAMPLE_RATE)
	peak = float(np.max(np.abs(softened)))
	if peak > 0.0:
		softened = softened / peak * 0.72
	return np.round(softened * 127.0) / 127.0


def write_ogg(samples: np.ndarray, ogg_path: Path) -> None:
	wav_path = ogg_path.with_suffix(".wav")
	pcm = np.int16(np.clip(samples, -1.0, 1.0) * 32767.0)
	with wave.open(str(wav_path), "w") as wav_file:
		wav_file.setnchannels(1)
		wav_file.setsampwidth(2)
		wav_file.setframerate(SAMPLE_RATE)
		wav_file.writeframes(pcm.tobytes())
	subprocess.run(
			[
				"ffmpeg",
				"-y",
				"-i",
				str(wav_path),
				"-c:a",
				"libvorbis",
				"-q:a",
				"5",
				str(ogg_path),
			],
			check=True,
			capture_output=True,
	)
	wav_path.unlink()
	peak = float(np.max(np.abs(samples)))
	rms = float(np.sqrt(np.mean(samples * samples)))
	duration_seconds = samples.size / SAMPLE_RATE
	print(
			f"{ogg_path.name}: {duration_seconds:.1f}s  peak={peak:.3f}  rms={rms:.3f}"
	)


def render_home_musicbox() -> np.ndarray:
	beats_per_minute = 50.0
	melody_bars = [
		[(A4, 3.0)],
		[(C5, 3.0)],
		[(E5, 2.0), (None, 1.0)],
		[(None, 3.0)],
		[(D5, 3.0)],
		[(C5, 2.0), (A4, 1.0)],
		[(G4, 3.0)],
		[(A4, 2.0), (None, 1.0)],
		[(E5, 2.0), (G5, 1.0)],
		[(D5, 3.0)],
		[(C5, 2.0), (G4, 1.0)],
		[(A4, 2.0), (None, 1.0)],
		[(None, 3.0)],
	]
	echo_bars = [
		[(A3, 3.0)],
		[(None, 3.0)],
		[(E4, 2.0), (None, 1.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(E4, 2.0), (G4, 1.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(A3, 2.0), (None, 1.0)],
		[(None, 3.0)],
	]
	drone_bars = [
		[(A3, 12.0)],
		[(A3, 12.0)],
		[(A3, 9.0), (None, 6.0)],
	]
	buffer = allocate_buffer(len(melody_bars), 3.0, beats_per_minute)
	mix_tine(
			buffer, expand_bars(melody_bars), SAMPLE_RATE, beats_per_minute,
			0.30, 1.45,
	)
	mix_tine(
			buffer, expand_bars(echo_bars), SAMPLE_RATE, beats_per_minute,
			0.11, 1.6,
	)
	mix_triangle_drone(
			buffer, expand_bars(drone_bars), SAMPLE_RATE, beats_per_minute,
			0.055,
	)
	return finalize(buffer)


def render_sunset_vesper() -> np.ndarray:
	beats_per_minute = 42.0
	melody_bars = [
		[(E5, 4.0)],
		[(D5, 2.0), (C5, 2.0)],
		[(A4, 3.0), (None, 1.0)],
		[(G4, 2.0), (None, 2.0)],
		[(A4, 2.0), (C5, 2.0)],
		[(E5, 3.0), (D5, 1.0)],
		[(C5, 2.0), (A4, 2.0)],
		[(E4, 3.0), (None, 1.0)],
		[(None, 4.0)],
	]
	star_bars = [
		[(None, 3.0), (A5, 1.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(None, 2.5), (C6, 1.5)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(None, 1.0), (A5, 1.0), (None, 2.0)],
		[(None, 4.0)],
	]
	drone_bars = [
		[(D3, 16.0)],
		[(D3, 12.0), (None, 8.0)],
	]
	buffer = allocate_buffer(len(melody_bars), 4.0, beats_per_minute)
	mix_tine(
			buffer, expand_bars(melody_bars), SAMPLE_RATE, beats_per_minute,
			0.26, 1.85,
	)
	mix_tine(
			buffer, expand_bars(star_bars), SAMPLE_RATE, beats_per_minute,
			0.07, 1.1,
	)
	mix_triangle_drone(
			buffer, expand_bars(drone_bars), SAMPLE_RATE, beats_per_minute,
			0.045,
	)
	return finalize(buffer)


def render_king_toy_waltz() -> np.ndarray:
	beats_per_minute = 56.0
	melody_bars = [
		[(E4, 1.0), (G4, 1.0), (E4, 1.0)],
		[(D4, 2.0), (C4, 1.0)],
		[(C4, 2.0), (None, 1.0)],
		[(None, 3.0)],
		[(E4, 1.0), (G4, 1.0), (E4, 1.0)],
		[(A4, 2.0), (G4, 1.0)],
		[(E4, 1.0), (D4, 1.0), (C4, 1.0)],
		[(C4, 2.0), (None, 1.0)],
		[(G4, 1.0), (E4, 1.0), (D4, 1.0)],
		[(C4, 2.0), (G3, 1.0)],
		[(G3, 2.0), (None, 1.0)],
		[(C4, 2.0), (None, 1.0)],
		[(E4, 1.0), (G4, 1.0), (E4, 1.0)],
		[(D4, 2.0), (C4, 1.0)],
		[(C4, 1.0), (E4, 1.0), (C4, 1.0)],
		[(C4, 2.0), (None, 1.0)],
		[(None, 3.0)],
	]
	throne_bars = [
		[(C3, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(C3, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(C3, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
		[(None, 3.0)],
	]
	buffer = allocate_buffer(len(melody_bars), 3.0, beats_per_minute)
	mix_tine(
			buffer, expand_bars(melody_bars), SAMPLE_RATE, beats_per_minute,
			0.24, 0.72,
	)
	mix_tine(
			buffer, expand_bars(throne_bars), SAMPLE_RATE, beats_per_minute,
			0.09, 1.2,
	)
	return finalize(buffer)


def main() -> None:
	output_directory = Path(__file__).resolve().parent
	tracks = [
		("sparse_apenta_musicbox.ogg", render_home_musicbox),
		("sparse_dpenta_vesper.ogg", render_sunset_vesper),
		("narrow_cpenta_toy_waltz.ogg", render_king_toy_waltz),
	]
	for file_name, render in tracks:
		write_ogg(render(), output_directory / file_name)


if __name__ == "__main__":
	main()
