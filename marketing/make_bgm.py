# -*- coding: utf-8 -*-
"""Generate a gentle, seamlessly-looping background music track for the app.
Offline-compliant (no network fetch). Writes assets/audio/bgm.wav.

Soft sine-based arpeggio over a I-V-vi-IV progression (C-G-Am-F), low volume,
per-note ADSR so note tails decay to near-zero at the loop boundary.
"""
import os
import math
import wave
import struct

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "audio", "bgm.wav")

SR = 22050            # sample rate (mono) — small file, fine for BGM
BPM = 96
BEAT = 60.0 / BPM     # seconds per beat
NOTE = BEAT / 2       # eighth-note arpeggio step

# note name -> frequency (Hz)
F = {
    "C4": 261.63, "D4": 293.66, "E4": 329.63, "F4": 349.23, "G4": 392.00,
    "A4": 440.00, "B4": 493.88, "C5": 523.25, "E5": 659.25, "G3": 196.00,
    "A3": 220.00, "F3": 174.61, "C3": 130.81,
}

# 4 bars, each an arpeggio pattern (up-down) of one chord. 8 eighth notes/bar.
BARS = [
    ["C4", "E4", "G4", "C5", "G4", "E4", "G4", "E4"],   # C
    ["G3", "B4", "D4", "G4", "D4", "B4", "D4", "B4"],   # G  (B4/D4 blend)
    ["A3", "C5", "E4", "A4", "E4", "C5", "E4", "C5"],   # Am
    ["F3", "A4", "C5", "F4", "C5", "A4", "C5", "A4"],   # F
]
# a slow bass note per bar (root, low octave)
BASS = ["C3", "G3", "A3", "F3"]

total_samples = int(round(len(BARS) * 8 * NOTE * SR))
buf = [0.0] * total_samples


def add_tone(start_s, dur_s, freq, amp, attack=0.02, release=0.35):
    n0 = int(start_s * SR)
    n = int(dur_s * SR)
    rel = int(release * SR)
    total = n + rel
    for i in range(total):
        idx = n0 + i
        if idx >= total_samples:
            idx -= total_samples  # wrap tail into loop start for seamlessness
        t = i / SR
        # ADSR-ish envelope
        if t < attack:
            env = t / attack
        elif i < n:
            env = 1.0 - 0.35 * ((i - attack * SR) / max(1, n - attack * SR))
        else:
            env = 0.65 * (1.0 - (i - n) / max(1, rel))
        if env <= 0:
            continue
        buf[idx] += amp * env * math.sin(2 * math.pi * freq * t)


# arpeggio voice
step = 0
for bar_i, bar in enumerate(BARS):
    for note in bar:
        start = step * NOTE
        add_tone(start, NOTE, F[note], amp=0.16, attack=0.015, release=0.30)
        step += 1

# soft bass pad, one per bar (whole bar long, gentle)
for bar_i, root in enumerate(BASS):
    start = bar_i * 8 * NOTE
    add_tone(start, 8 * NOTE, F[root], amp=0.10, attack=0.08, release=0.5)

# gentle high shimmer every half-bar
step = 0
for bar_i, bar in enumerate(BARS):
    start = bar_i * 8 * NOTE
    add_tone(start, NOTE * 2, F["E5"], amp=0.04, attack=0.1, release=0.6)

# normalize to avoid clipping, keep headroom (peak ~0.8)
peak = max(1e-6, max(abs(v) for v in buf))
scale = 0.8 / peak
frames = bytearray()
for v in buf:
    s = int(max(-1.0, min(1.0, v * scale)) * 32767)
    frames += struct.pack("<h", s)

with wave.open(OUT, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(SR)
    w.writeframes(bytes(frames))

print("saved:", OUT)
print("duration: %.2fs" % (total_samples / SR), "size:", os.path.getsize(OUT), "bytes")
