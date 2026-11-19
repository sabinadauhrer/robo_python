"""Erzeugt Favicon und App-Icons (Kawaii-Roboter) für die Web-App.

Aufruf:  python3 tool/make_icons.py web
"""
import sys
from PIL import Image, ImageDraw

PINK_BG = (255, 214, 231)
INK = (74, 59, 82)
MINT = (158, 230, 207)
MINT_LIGHT = (242, 255, 250)
PINK = (247, 168, 200)
PINK_DEEP = (224, 96, 154)
GLOW = (191, 255, 234)


def robot(size, padding):
    """Zeichnet den Roboter in 4-facher Auflösung und verkleinert dann (glatte Kanten)."""
    S = size * 4
    img = Image.new('RGBA', (S, S), PINK_BG + (255,))
    d = ImageDraw.Draw(img)
    inner = S * (1 - 2 * padding)
    o = S * padding

    def p(x, y):
        return (o + x * inner, o + y * inner)

    def box(x0, y0, x1, y1):
        return [p(x0, y0), p(x1, y1)]

    w = max(2, int(inner * 0.035))
    d.line([p(0.5, 0.24), p(0.5, 0.12)], fill=INK, width=w)
    r = inner * 0.07
    cx, cy = p(0.5, 0.09)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=PINK_DEEP)
    for x in (0.11, 0.89):
        d.ellipse(box(x - 0.065, 0.495, x + 0.065, 0.625), fill=PINK, outline=INK, width=w)
    # Körper mit leichtem Verlauf
    body = box(0.14, 0.24, 0.86, 0.9)
    grad = Image.new('RGBA', img.size)
    gd = ImageDraw.Draw(grad)
    y0, y1 = int(body[0][1]), int(body[1][1])
    for y in range(y0, y1):
        t = (y - y0) / max(1, y1 - y0)
        c = tuple(int(MINT_LIGHT[i] + (MINT[i] - MINT_LIGHT[i]) * t) for i in range(3))
        gd.line([(0, y), (S, y)], fill=c + (255,))
    mask = Image.new('L', img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(body, radius=inner * 0.24, fill=255)
    img.paste(grad, (0, 0), mask)
    d.rounded_rectangle(body, radius=inner * 0.24, outline=INK, width=w)
    d.rounded_rectangle(box(0.24, 0.35, 0.76, 0.76), radius=inner * 0.15, fill=INK)
    for x in (0.32, 0.68):
        d.ellipse(box(x - 0.05, 0.6225, x + 0.05, 0.6775), fill=PINK)
    for x in (0.38, 0.62):
        d.ellipse(box(x - 0.045, 0.46, x + 0.045, 0.58), fill=GLOW)
        d.ellipse(box(x - 0.003, 0.477, x + 0.033, 0.513), fill=(255, 255, 255))
    d.arc(box(0.45, 0.6, 0.55, 0.7), start=20, end=160, fill=PINK, width=w)
    return img.resize((size, size), Image.LANCZOS)


out = sys.argv[1] if len(sys.argv) > 1 else 'web'
robot(32, 0.04).save(f'{out}/favicon.png')
for s in (192, 512):
    robot(s, 0.08).save(f'{out}/icons/Icon-{s}.png')
    robot(s, 0.2).save(f'{out}/icons/Icon-maskable-{s}.png')  # Sicherheitszone für runde Masken
print('Icons erzeugt in', out)
