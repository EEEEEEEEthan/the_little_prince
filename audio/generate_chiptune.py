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

# MIDI
A1 = 33
BB1 = 34
C2, D2, E2, F2, G2 = 36, 38, 40, 41, 43
A2, C3, E3, G3 = 45, 48, 52, 55
A3, B3, C4, D4, E4, F4, G4 = 57, 59, 60, 62, 64, 65, 67
A4, B4, C5, D5, E5, F5, G5 = 69, 71, 72, 74, 76, 77, 79
A5, B5, C6 = 81, 83, 84
BB4 = 70


def midi_to_hertz(midi_note: int) -> float:
	return A4_HERTZ * (2.0 ** ((midi_note - A4_MIDI) / 12.0))


def adsr_envelope(
		sample_count: int,
		sample_rate: int,
		attack_seconds: float,
		decay_seconds: float,
		sustain_level: float,
		release_seconds: float,
) -> np.ndarray:
	attack_samples = max(1, int(attack_seconds * sample_rate))
	decay_samples = max(1, int(decay_seconds * sample_rate))
	release_samples = max(1, int(release_seconds * sample_rate))
	sustain_samples = sample_count - attack_samples - decay_samples - release_samples
	if sustain_samples < 1:
		total = attack_samples + decay_samples + release_samples
		scale = sample_count / float(total)
		attack_samples = max(1, int(attack_samples * scale))
		decay_samples = max(1, int(decay_samples * scale))
		release_samples = max(1, sample_count - attack_samples - decay_samples)
		sustain_samples = 0
	parts = [
		np.linspace(0.0, 1.0, attack_samples, endpoint=False),
		np.linspace(1.0, sustain_level, decay_samples, endpoint=False),
	]
	if sustain_samples > 0:
		parts.append(np.full(sustain_samples, sustain_level))
	parts.append(np.linspace(sustain_level, 0.0, release_samples, endpoint=True))
	envelope = np.concatenate(parts)
	if envelope.size < sample_count:
		envelope = np.pad(envelope, (0, sample_count - envelope.size))
	return envelope[:sample_count]


def bandlimited_pulse(
		midi_note: int,
		sample_count: int,
		sample_rate: int,
		duty: float,
) -> np.ndarray:
	frequency = midi_to_hertz(midi_note)
	time_seconds = np.arange(sample_count, dtype=np.float64) / sample_rate
	wave = np.full(sample_count, 2.0 * duty - 1.0, dtype=np.float64)
	max_harmonic = max(1, int((sample_rate * 0.45) / frequency))
	for harmonic_index in range(1, max_harmonic + 1):
		coefficient = 2.0 * math.sin(harmonic_index * math.pi * duty) / (
				harmonic_index * math.pi
		)
		wave += coefficient * np.cos(
				2.0 * math.pi * harmonic_index * frequency * time_seconds
		)
	return wave


def bandlimited_triangle(
		midi_note: int,
		sample_count: int,
		sample_rate: int,
) -> np.ndarray:
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


def expand_bars(bars: list[list[tuple[int | None, float]]]) -> list[tuple[float, int, float]]:
	events: list[tuple[float, int, float]] = []
	beat_position = 0.0
	for bar in bars:
		for midi_note, duration_beats in bar:
			if midi_note is not None:
				events.append((beat_position, midi_note, duration_beats))
			beat_position += duration_beats
	return events


def mix_pulse(
		buffer: np.ndarray,
		events: list[tuple[float, int, float]],
		sample_rate: int,
		beats_per_minute: float,
		duty: float,
		volume: float,
		attack_seconds: float,
		decay_seconds: float,
		sustain_level: float,
		release_seconds: float,
) -> None:
	samples_per_beat = sample_rate * 60.0 / beats_per_minute
	for start_beat, midi_note, duration_beats in events:
		start_index = int(start_beat * samples_per_beat)
		if start_index >= buffer.size:
			continue
		sample_count = min(int(duration_beats * samples_per_beat), buffer.size - start_index)
		if sample_count <= 4:
			continue
		wave = bandlimited_pulse(midi_note, sample_count, sample_rate, duty)
		envelope = adsr_envelope(
				sample_count,
				sample_rate,
				attack_seconds,
				decay_seconds,
				sustain_level,
				release_seconds,
		)
		buffer[start_index:start_index + sample_count] += wave * envelope * volume


def mix_triangle(
		buffer: np.ndarray,
		events: list[tuple[float, int, float]],
		sample_rate: int,
		beats_per_minute: float,
		volume: float,
		attack_seconds: float,
		decay_seconds: float,
		sustain_level: float,
		release_seconds: float,
) -> None:
	samples_per_beat = sample_rate * 60.0 / beats_per_minute
	for start_beat, midi_note, duration_beats in events:
		start_index = int(start_beat * samples_per_beat)
		if start_index >= buffer.size:
			continue
		sample_count = min(int(duration_beats * samples_per_beat), buffer.size - start_index)
		if sample_count <= 4:
			continue
		wave = bandlimited_triangle(midi_note, sample_count, sample_rate)
		envelope = adsr_envelope(
				sample_count,
				sample_rate,
				attack_seconds,
				decay_seconds,
				sustain_level,
				release_seconds,
		)
		buffer[start_index:start_index + sample_count] += wave * envelope * volume


def allocate_buffer(bars: list, beats_per_bar: float, beats_per_minute: float) -> np.ndarray:
	total_beats = len(bars) * beats_per_bar
	sample_count = int(total_beats * SAMPLE_RATE * 60.0 / beats_per_minute)
	return np.zeros(sample_count, dtype=np.float64)


def finalize(buffer: np.ndarray) -> np.ndarray:
	peak = float(np.max(np.abs(buffer)))
	if peak > 0.0:
		buffer = buffer / peak * 0.86
	quantized = np.round(buffer * 127.0) / 127.0
	return quantized.astype(np.float64)


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


def render_home_lullaby() -> np.ndarray:
	beats_per_minute = 66.0
	melody_bars = [
		[(A4, 0.5), (C5, 0.5), (E5, 1.0), (E5, 1.0)],
		[(D5, 0.5), (C5, 0.5), (B4, 2.0)],
		[(C5, 1.0), (B4, 0.5), (A4, 0.5), (G4, 1.0)],
		[(A4, 2.0), (None, 1.0)],
		[(E4, 0.5), (A4, 0.5), (C5, 1.0), (B4, 1.0)],
		[(A4, 0.5), (G4, 0.5), (E4, 2.0)],
		[(F4, 1.0), (A4, 1.0), (C5, 1.0)],
		[(B4, 0.5), (C5, 0.5), (A4, 2.0)],
		[(E5, 0.5), (D5, 0.5), (C5, 1.0), (B4, 1.0)],
		[(A4, 0.5), (B4, 0.5), (C5, 2.0)],
		[(D5, 1.0), (E5, 0.5), (D5, 0.5), (C5, 1.0)],
		[(B4, 2.0), (None, 1.0)],
		[(A4, 0.5), (C5, 0.5), (E5, 1.0), (G5, 1.0)],
		[(F5, 0.5), (E5, 0.5), (D5, 2.0)],
		[(C5, 1.0), (B4, 1.0), (E4, 1.0)],
		[(A4, 2.5), (None, 0.5)],
	]
	harmony_bars = [
		[(C4, 3.0)],
		[(C4, 3.0)],
		[(A3, 3.0)],
		[(A3, 3.0)],
		[(G3, 3.0)],
		[(G3, 3.0)],
		[(B3, 3.0)],
		[(E3, 3.0)],
		[(C4, 3.0)],
		[(A3, 3.0)],
		[(G3, 3.0)],
		[(G3, 3.0)],
		[(A3, 3.0)],
		[(G3, 3.0)],
		[(C4, 3.0)],
		[(A3, 2.5), (None, 0.5)],
	]
	bass_bars = [
		[(A2, 3.0)],
		[(A2, 3.0)],
		[(F2, 3.0)],
		[(F2, 3.0)],
		[(C3, 3.0)],
		[(C3, 3.0)],
		[(E2, 3.0)],
		[(E2, 3.0)],
		[(A2, 3.0)],
		[(D2, 3.0)],
		[(E2, 3.0)],
		[(E2, 3.0)],
		[(F2, 3.0)],
		[(E2, 3.0)],
		[(A2, 3.0)],
		[(A2, 2.5), (None, 0.5)],
	]
	buffer = allocate_buffer(melody_bars, 3.0, beats_per_minute)
	mix_pulse(
			buffer, expand_bars(melody_bars), SAMPLE_RATE, beats_per_minute,
			0.25, 0.22, 0.012, 0.10, 0.55, 0.18,
	)
	mix_pulse(
			buffer, expand_bars(harmony_bars), SAMPLE_RATE, beats_per_minute,
			0.125, 0.10, 0.02, 0.12, 0.45, 0.22,
	)
	mix_triangle(
			buffer, expand_bars(bass_bars), SAMPLE_RATE, beats_per_minute,
			0.16, 0.02, 0.08, 0.82, 0.28,
	)
	return finalize(buffer)


def render_sunset_vesper() -> np.ndarray:
	beats_per_minute = 56.0
	melody_bars = [
		[(D5, 2.0), (C5, 1.0), (A4, 1.0)],
		[(G4, 2.0), (A4, 2.0)],
		[(C5, 2.0), (D5, 1.0), (F5, 1.0)],
		[(E5, 1.0), (D5, 3.0)],
		[(A5, 2.0), (G5, 1.0), (F5, 1.0)],
		[(E5, 2.0), (C5, 2.0)],
		[(D5, 1.0), (E5, 1.0), (F5, 2.0)],
		[(E5, 3.0), (None, 1.0)],
		[(D5, 2.0), (A4, 2.0)],
		[(C5, 2.0), (G4, 2.0)],
		[(A4, 1.0), (C5, 1.0), (D5, 2.0)],
		[(D5, 3.0), (None, 1.0)],
	]
	harmony_bars = [
		[(A4, 4.0)],
		[(F4, 4.0)],
		[(G4, 4.0)],
		[(A4, 4.0)],
		[(C5, 4.0)],
		[(A4, 4.0)],
		[(BB4, 4.0)],
		[(A4, 3.0), (None, 1.0)],
		[(F4, 4.0)],
		[(E4, 4.0)],
		[(F4, 4.0)],
		[(A4, 3.0), (None, 1.0)],
	]
	bass_bars = [
		[(D2, 4.0)],
		[(F2, 4.0)],
		[(C3, 4.0)],
		[(D2, 4.0)],
		[(BB1, 4.0)],
		[(F2, 4.0)],
		[(G2, 4.0)],
		[(A2, 3.0), (None, 1.0)],
		[(D2, 4.0)],
		[(F2, 4.0)],
		[(A2, 4.0)],
		[(D2, 3.0), (None, 1.0)],
	]
	twinkle_bars = [
		[(None, 2.0), (A5, 0.25), (None, 1.75)],
		[(None, 4.0)],
		[(None, 3.0), (C6, 0.25), (None, 0.75)],
		[(None, 4.0)],
		[(None, 1.5), (A5, 0.25), (None, 2.25)],
		[(None, 4.0)],
		[(None, 2.5), (C6, 0.25), (None, 1.25)],
		[(None, 4.0)],
		[(None, 2.0), (A5, 0.25), (None, 1.75)],
		[(None, 4.0)],
		[(None, 3.0), (D5, 0.25), (None, 0.75)],
		[(None, 4.0)],
	]
	buffer = allocate_buffer(melody_bars, 4.0, beats_per_minute)
	mix_pulse(
			buffer, expand_bars(melody_bars), SAMPLE_RATE, beats_per_minute,
			0.5, 0.20, 0.03, 0.16, 0.62, 0.35,
	)
	mix_pulse(
			buffer, expand_bars(harmony_bars), SAMPLE_RATE, beats_per_minute,
			0.25, 0.08, 0.04, 0.18, 0.40, 0.40,
	)
	mix_triangle(
			buffer, expand_bars(bass_bars), SAMPLE_RATE, beats_per_minute,
			0.15, 0.03, 0.10, 0.88, 0.40,
	)
	mix_pulse(
			buffer, expand_bars(twinkle_bars), SAMPLE_RATE, beats_per_minute,
			0.125, 0.07, 0.005, 0.04, 0.20, 0.12,
	)
	return finalize(buffer)


def render_king_processional() -> np.ndarray:
	beats_per_minute = 88.0
	melody_bars = [
		[(C5, 1.0), (E5, 1.0), (G5, 1.0), (G5, 1.0)],
		[(A5, 1.0), (G5, 0.5), (F5, 0.5), (E5, 2.0)],
		[(D5, 1.0), (F5, 1.0), (A5, 1.0), (G5, 1.0)],
		[(E5, 2.0), (C5, 2.0)],
		[(G4, 1.0), (C5, 1.0), (E5, 1.0), (D5, 1.0)],
		[(C5, 1.0), (B4, 1.0), (A4, 2.0)],
		[(G4, 1.0), (E4, 1.0), (F4, 1.0), (G4, 1.0)],
		[(C5, 3.0), (None, 1.0)],
		[(E5, 1.0), (G5, 1.0), (C6, 1.0), (B5, 1.0)],
		[(A5, 1.0), (G5, 0.5), (F5, 0.5), (E5, 2.0)],
		[(F5, 1.0), (E5, 1.0), (D5, 1.0), (C5, 1.0)],
		[(B4, 2.0), (G4, 2.0)],
		[(C5, 1.0), (E5, 1.0), (G5, 1.0), (E5, 1.0)],
		[(A5, 2.0), (G5, 2.0)],
		[(F5, 1.0), (E5, 1.0), (D5, 1.0), (B4, 1.0)],
		[(C5, 3.0), (None, 1.0)],
	]
	harmony_bars = [
		[(G4, 4.0)],
		[(E4, 4.0)],
		[(F4, 4.0)],
		[(E4, 4.0)],
		[(E4, 4.0)],
		[(C4, 4.0)],
		[(D4, 4.0)],
		[(E4, 3.0), (None, 1.0)],
		[(G4, 4.0)],
		[(E4, 4.0)],
		[(C4, 4.0)],
		[(D4, 4.0)],
		[(E4, 4.0)],
		[(F4, 4.0)],
		[(D4, 4.0)],
		[(E4, 3.0), (None, 1.0)],
	]
	bass_bars = [
		[(C2, 4.0)],
		[(G2, 4.0)],
		[(F2, 4.0)],
		[(C2, 4.0)],
		[(C2, 4.0)],
		[(A1, 4.0)],
		[(F2, 4.0)],
		[(G2, 3.0), (None, 1.0)],
		[(C2, 4.0)],
		[(G2, 4.0)],
		[(F2, 4.0)],
		[(E2, 4.0)],
		[(C2, 4.0)],
		[(F2, 4.0)],
		[(G2, 4.0)],
		[(C2, 3.0), (None, 1.0)],
	]
	buffer = allocate_buffer(melody_bars, 4.0, beats_per_minute)
	mix_pulse(
			buffer, expand_bars(melody_bars), SAMPLE_RATE, beats_per_minute,
			0.125, 0.21, 0.008, 0.06, 0.42, 0.10,
	)
	mix_pulse(
			buffer, expand_bars(harmony_bars), SAMPLE_RATE, beats_per_minute,
			0.25, 0.08, 0.02, 0.10, 0.35, 0.18,
	)
	mix_triangle(
			buffer, expand_bars(bass_bars), SAMPLE_RATE, beats_per_minute,
			0.16, 0.015, 0.06, 0.80, 0.20,
	)
	return finalize(buffer)


def main() -> None:
	output_directory = Path(__file__).resolve().parent
	tracks = [
		("sparse_aminor_square_lullaby.ogg", render_home_lullaby),
		("warm_dminor_square_vesper.ogg", render_sunset_vesper),
		("sparse_cmajor_square_processional.ogg", render_king_processional),
	]
	for file_name, render in tracks:
		write_ogg(render(), output_directory / file_name)


if __name__ == "__main__":
	main()
