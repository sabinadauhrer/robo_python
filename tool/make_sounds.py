"""Erzeugt niedliche Soundeffekte als WAV (22,05 kHz, mono, 16 bit)."""
import math, struct, sys, wave
RATE = 22050
OUT = sys.argv[1]

def tone(f0, f1, dur, vol=0.5, attack=0.005, decay=6.0, vibrato=0.0, harmonics=(1.0,)):
    n = int(RATE * dur); out = []; phase = 0.0
    for i in range(n):
        t = i / RATE; k = i / max(1, n - 1)
        f = f0 + (f1 - f0) * k
        if vibrato: f *= 1 + vibrato * math.sin(2 * math.pi * 18 * t) * (1 - k)
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / attack) * math.exp(-decay * t)
        s = sum(a * math.sin(phase * (h + 1)) for h, a in enumerate(harmonics))
        out.append(vol * env * s / sum(harmonics))
    return out

def silence(dur): return [0.0] * int(RATE * dur)

def mix(*parts):
    n = max(len(p) for p in parts); return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]

def save(name, samples):
    with wave.open(f'{OUT}/{name}.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s)) * 32000)) for s in samples))

bell = (1.0, 0.35, 0.15)
save('move', tone(600, 900, 0.09, vol=0.35, decay=30))
save('coin', tone(1319, 1319, 0.08, vol=0.4, decay=20, harmonics=bell) + tone(1760, 1760, 0.32, vol=0.45, decay=9, harmonics=bell))
save('error', tone(520, 260, 0.35, vol=0.4, decay=5, harmonics=(1.0, 0.3)))
notes = [1047, 1319, 1568, 2093]
save('success', sum((tone(f, f, 0.12 if i < 3 else 0.5, vol=0.4, decay=8 if i < 3 else 4, harmonics=bell) for i, f in enumerate(notes)), []))
save('correct', mix(tone(784, 784, 0.35, vol=0.3, decay=8, harmonics=bell), silence(0.07) + tone(988, 988, 0.35, vol=0.3, decay=8, harmonics=bell)))
save('wrong', tone(330, 330, 0.12, vol=0.35, decay=10) + tone(262, 250, 0.25, vol=0.35, decay=8))
save('tap', tone(1100, 1300, 0.03, vol=0.2, decay=60))
