#!/usr/bin/env python3
"""生成国王/商人/点灯人/地理学家星球循环配乐（CC0）。故乡/日落曲改用 OpenGameArt。运行：python3 audio/generate_chiptune.py"""

from __future__ import annotations

import math
import subprocess
import wave
from pathlib import Path

import numpy as np

SAMPLE_RATE = 22050
A4_MIDI = 69
A4_HERTZ = 440.0

C3, G3, A3 = 48, 55, 57
C4, D4, E4, G4, A4, Bb4, C5 = 60, 62, 64, 67, 69, 70, 72
D3, F3, Bb3 = 50, 53, 58


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


def herald_partial(midi_note: int, sample_count: int, sample_rate: int) -> np.ndarray:
	frequency = midi_to_hertz(midi_note)
	time_seconds = np.arange(sample_count, dtype=np.float64) / sample_rate
	fundamental = np.sin(2.0 * math.pi * frequency * time_seconds)
	odd_third = np.sin(2.0 * math.pi * frequency * 3.0 * time_seconds)
	return fundamental + 0.28 * odd_third


def mix_tine(
		buffer: np.ndarray,
		events: list[tuple[float, int, float]],
		sample_rate: int,
		beats_per_minute: float,
		volume: float,
		decay_seconds: float,
		tone_function=music_box_tine,
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
		wave = tone_function(midi_note, sample_count, sample_rate)
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


def render_hollow_fifth_processional_stumble() -> np.ndarray:
	beats_per_minute = 48.0
	herald_bars = [
		[(C4, 1.0), (G4, 1.0), (C5, 2.0)],
		[(G4, 3.0), (None, 1.0)],
		[(E4, 1.0), (G4, 1.0), (C5, 1.0), (G4, 1.0)],
		[(None, 4.0)],
		[(C5, 1.0), (G4, 1.0), (E4, 1.0), (C4, 1.0)],
		[(Bb3, 2.0), (None, 2.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(C4, 1.0), (G4, 1.0), (E4, 2.0)],
		[(D4, 1.0), (C4, 1.0), (None, 2.0)],
		[(None, 4.0)],
		[(C4, 1.0), (None, 3.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(C5, 2.0), (None, 2.0)],
		[(None, 4.0)],
	]
	toy_stumble_bars = [
		[(None, 4.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(G4, 0.5), (E4, 0.5), (G4, 0.5), (E4, 0.5), (C4, 1.0), (None, 1.0)],
		[(C4, 2.0), (None, 2.0)],
		[(None, 4.0)],
		[(None, 4.0)],
		[(G3, 2.0), (None, 2.0)],
		[(None, 4.0)],
		[(E4, 1.0), (None, 1.0), (G4, 1.0), (None, 1.0)],
		[(Bb4, 0.5), (G4, 1.5), (None, 2.0)],
		[(None, 4.0)],
		[(None, 4.0)],
	]
	fifth_drone_bars = [
		[(C3, 4.0)],
		[(G3, 4.0)],
		[(C3, 4.0)],
		[(None, 4.0)],
		[(C3, 4.0)],
		[(G3, 2.0), (None, 2.0)],
		[(None, 4.0)],
		[(C3, 4.0)],
		[(C3, 4.0)],
		[(None, 4.0)],
		[(G3, 4.0)],
		[(C3, 2.0), (None, 2.0)],
		[(None, 4.0)],
		[(G3, 2.0), (None, 2.0)],
		[(C3, 4.0)],
		[(None, 4.0)],
	]
	buffer = allocate_buffer(len(herald_bars), 4.0, beats_per_minute)
	mix_tine(
			buffer, expand_bars(herald_bars), SAMPLE_RATE, beats_per_minute,
			0.22, 0.95, herald_partial,
	)
	mix_tine(
			buffer, expand_bars(toy_stumble_bars), SAMPLE_RATE, beats_per_minute,
			0.20, 0.62,
	)
	mix_tine(
			buffer, expand_bars(fifth_drone_bars), SAMPLE_RATE, beats_per_minute,
			0.08, 1.5, herald_partial,
	)
	return finalize(buffer)


def render_sparse_ledger_tally() -> np.ndarray:
	beats_per_minute = 48.0
	tally_bars = [
		[(A3, 0.5), (None, 0.5), (A3, 0.5), (None, 1.5)],
		[(C4, 0.5), (None, 2.5)],
		[(None, 3.0)],
		[(G3, 1.0), (None, 2.0)],
		[(A3, 0.5), (None, 0.5), (C4, 0.5), (None, 1.5)],
		[(None, 3.0)],
		[(D3, 2.0), (None, 1.0)],
		[(None, 3.0)],
		[(A3, 0.5), (None, 2.5)],
		[(F3, 1.0), (None, 2.0)],
		[(None, 3.0)],
		[(G3, 0.5), (None, 0.5), (A3, 0.5), (None, 1.5)],
		[(C4, 1.0), (None, 2.0)],
		[(None, 3.0)],
		[(D3, 3.0)],
		[(None, 3.0)],
	]
	buffer = allocate_buffer(len(tally_bars), 3.0, beats_per_minute)
	mix_tine(
			buffer, expand_bars(tally_bars), SAMPLE_RATE, beats_per_minute,
			0.18, 1.1,
	)
	return finalize(buffer)


def render_rapid_lamp_duty_tick() -> np.ndarray:
	beats_per_minute = 96.0
	tick_bars = [
		[(G3, 0.25), (None, 0.25), (G3, 0.25), (None, 0.25), (C4, 0.25), (None, 1.75)],
		[(G3, 0.25), (None, 2.75)],
		[(None, 3.0)],
		[(D3, 1.0), (None, 2.0)],
		[(G3, 0.25), (None, 0.25), (G3, 0.25), (None, 2.25)],
		[(None, 3.0)],
		[(A3, 0.5), (None, 2.5)],
		[(C3, 2.0), (None, 1.0)],
		[(G3, 0.25), (None, 0.25), (C4, 0.25), (None, 2.25)],
		[(None, 3.0)],
		[(G3, 0.25), (None, 2.75)],
		[(D3, 0.5), (None, 2.5)],
		[(G3, 0.25), (None, 0.25), (G3, 0.25), (None, 0.25), (G3, 0.25), (None, 1.75)],
		[(None, 3.0)],
		[(C3, 3.0)],
		[(None, 3.0)],
	]
	buffer = allocate_buffer(len(tick_bars), 3.0, beats_per_minute)
	mix_tine(
			buffer, expand_bars(tick_bars), SAMPLE_RATE, beats_per_minute,
			0.16, 0.42,
	)
	return finalize(buffer)


def render_dry_folio_rest() -> np.ndarray:
	beats_per_minute = 40.0
	folio_bars = [
		[(D3, 2.0), (None, 1.0)],
		[(None, 3.0)],
		[(A3, 1.0), (None, 2.0)],
		[(None, 3.0)],
		[(F3, 0.5), (None, 2.5)],
		[(None, 3.0)],
		[(C4, 2.0), (None, 1.0)],
		[(None, 3.0)],
		[(A3, 1.0), (None, 0.5), (G3, 1.5)],
		[(None, 3.0)],
		[(D3, 3.0)],
		[(None, 3.0)],
		[(F3, 1.0), (None, 2.0)],
		[(None, 3.0)],
		[(A3, 0.5), (None, 2.5)],
		[(None, 3.0)],
	]
	buffer = allocate_buffer(len(folio_bars), 3.0, beats_per_minute)
	mix_tine(
			buffer, expand_bars(folio_bars), SAMPLE_RATE, beats_per_minute,
			0.14, 1.6,
	)
	return finalize(buffer)


def main() -> None:
	output_directory = Path(__file__).resolve().parent
	write_ogg(
			render_hollow_fifth_processional_stumble(),
			output_directory / "hollow_fifth_processional_stumble.ogg",
	)
	write_ogg(render_sparse_ledger_tally(), output_directory / "sparse_ledger_tally.ogg")
	write_ogg(render_rapid_lamp_duty_tick(), output_directory / "rapid_lamp_duty_tick.ogg")
	write_ogg(render_dry_folio_rest(), output_directory / "dry_folio_rest.ogg")


if __name__ == "__main__":
	main()
