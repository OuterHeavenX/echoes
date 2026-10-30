#!/usr/bin/env python3
"""Deterministic original art + audio for Echoes of the Last Dawn.

Sprites are drawn with Pillow rectangles (no third-party art, no FF6 assets).
Run: python3 tools/gen_assets.py  -- then Godot --import picks up the PNG/WAV files.
Sprites are 48x64, drawn at 3x of a 16x21 pixel grid so filtering stays crisp.
"""
import math, struct, wave, os
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPR = os.path.join(ROOT, "assets", "sprites")
POR = os.path.join(ROOT, "assets", "portraits")
AUD = os.path.join(ROOT, "assets", "audio")
os.makedirs(SPR, exist_ok=True); os.makedirs(POR, exist_ok=True); os.makedirs(AUD, exist_ok=True)

S = 3  # pixel scale

def draw_char(path, skin, hair, cloak, pants, accent, hat=None, hood=False):
    W, H = 16, 21
    img = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    px = img.load()
    def rect(x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                for dy in range(S):
                    for dx in range(S):
                        px[xx * S + dx, yy * S + dy] = c
    def C(hexv):
        hexv = hexv.lstrip("#")
        return tuple(int(hexv[i:i+2], 16) for i in (0, 2, 4)) + (255,)
    # legs, boots
    rect(5, 16, 2, 3, C(pants)); rect(9, 16, 2, 3, C(pants))
    rect(5, 19, 2, 2, C("#2b2118")); rect(9, 19, 2, 2, C("#2b2118"))
    # cloak / torso
    rect(4, 9, 8, 8, C(cloak))
    rect(5, 9, 6, 3, C(accent))
    # arms
    rect(3, 10, 2, 5, C(cloak)); rect(11, 10, 2, 5, C(cloak))
    rect(3, 15, 2, 1, C(skin)); rect(11, 15, 2, 1, C(skin))
    # head
    rect(5, 3, 6, 6, C(skin))
    rect(6, 5, 1, 1, C("#1a1a1a")); rect(9, 5, 1, 1, C("#1a1a1a"))
    if hood:
        rect(4, 2, 8, 3, C(cloak)); rect(4, 2, 8, 1, C(accent))
    else:
        rect(5, 2, 6, 2, C(hair))
        if hat:
            rect(4, 1, 8, 2, C(hat))
    img.save(path)

CHARS = {
    "rowan": ("#e8c39a", "#5a3a22", "#3fb8a6", "#2b2b33", "#ffd166", None, True),
    "mira": ("#f0c8a0", "#2b2b2b", "#e8873d", "#3a2b1e", "#ffd166", "#c9a86a", False),
    "garran": ("#d8b08a", "#6a6a6a", "#7fa8c9", "#2b3440", "#e8e0c8", "#5a6a7a", False),
    "sera": ("#f2d0b0", "#3a2a1a", "#e8e0c8", "#4a3a5a", "#7fc46a", None, False),
    "ilyan": ("#e8cfa8", "#1a1a2a", "#8a7bd8", "#2b2b33", "#c9a86a", None, True),
    "nessa": ("#e0b890", "#2a1a0a", "#7fc46a", "#2b331e", "#ffd166", None, False),
    "orin": ("#d8c0a0", "#8a8a8a", "#c9a86a", "#3a332a", "#e8e0c8", None, True),
    "tavi": ("#f0c8a0", "#5a1a3a", "#d86a9a", "#3a1a2a", "#ffd166", None, False),
    "npc_tomas": ("#d8b08a", "#c8c8c8", "#6a5a4a", "#2b2b33", "#c9a86a", None, False),
    "npc_shop": ("#e8c39a", "#4a2a1a", "#8a6a3a", "#2b2b33", "#e8e0c8", None, False),
    "npc_inn": ("#f0c8a0", "#2a2a2a", "#a86a8a", "#2b2b33", "#ffd166", None, False),
    "npc_official": ("#e8c39a", "#1a1a1a", "#3a4a6a", "#1a1a2a", "#c9a86a", "#2a3a5a", False),
}
for name, args in CHARS.items():
    draw_char(os.path.join(SPR, name + ".png"), *args)
    # Portrait: same drawing, cropped to head + shoulders, enlarged.
    im = Image.open(os.path.join(SPR, name + ".png"))
    crop = im.crop((3 * S, 0, 13 * S, 11 * S)).resize((96, 106), Image.NEAREST)
    crop.save(os.path.join(POR, name + ".png"))

def draw_enemy(path, body, eye, extra=None):
    W, H = 16, 16
    img = Image.new("RGBA", (W * S, H * S), (0, 0, 0, 0))
    px = img.load()
    def C(h):
        h = h.lstrip("#"); return tuple(int(h[i:i+2], 16) for i in (0, 2, 4)) + (255,)
    def rect(x, y, w, h, c):
        for yy in range(y, y + h):
            for xx in range(x, x + w):
                for dy in range(S):
                    for dx in range(S):
                        px[xx * S + dx, yy * S + dy] = c
    rect(3, 3, 10, 10, C(body))
    rect(5, 6, 2, 2, C(eye)); rect(9, 6, 2, 2, C(eye))
    if extra == "wings":
        rect(1, 5, 2, 4, C("#c9d8e8")); rect(13, 5, 2, 4, C("#c9d8e8"))
    if extra == "antenna":
        rect(7, 1, 2, 2, C(eye))
    if extra == "crown":
        rect(5, 1, 6, 2, C("#ffd166"))
    img.save(path)

draw_enemy(os.path.join(SPR, "rat.png"), "#6a5a4a", "#ff5a3c")
draw_enemy(os.path.join(SPR, "wisp.png"), "#8ac8e8", "#e8f8ff", "wings")
draw_enemy(os.path.join(SPR, "mender.png"), "#7fc46a", "#ffd166", "antenna")
draw_enemy(os.path.join(SPR, "sentry.png"), "#7fa8c9", "#ff3c3c")
draw_enemy(os.path.join(SPR, "warden.png"), "#3a4a6a", "#ffd166", "crown")

# ---- Audio: short original sine/triangle loops (not arrangements of existing music) ----
SR = 22050
def note(freq, dur, vol=0.22):
    n = int(SR * dur); out = bytearray()
    for i in range(n):
        t = i / SR
        v = math.sin(2 * math.pi * freq * t) * vol * (1 - t / (dur * 2))
        out += struct.pack("<h", int(max(-1, min(1, v)) * 12000))
    return bytes(out)

def loop_file(name, melody, bpm=96, repeats=4):
    beat = 60 / bpm
    data = b""
    for _ in range(repeats):
        for freq, beats in melody:
            data += note(freq, beat * beats) if freq else b"\x00\x00" * int(SR * beat * beats)
    with wave.open(os.path.join(AUD, name), "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(data)

A4, B4, C5, D5, E5, F5, G5, A5 = 440, 493.88, 523.25, 587.33, 659.25, 698.46, 783.99, 880
E4, G4 = 329.63, 392.0
loop_file("town.wav", [(C5,1),(E5,1),(G5,1),(E5,1),(A4,1),(C5,1),(E5,1),(G4,1)], bpm=84)
loop_file("battle.wav", [(A4,0.5),(A4,0.5),(C5,0.5),(E5,0.5),(D5,0.5),(F5,0.5),(E5,1),(C5,1)], bpm=132)
loop_file("boss.wav", [(E4,1),(G4,1),(A4,1),(B4,1),(C5,1),(B4,1),(A4,1),(G4,1)], bpm=110)
loop_file("dungeon.wav", [(A4,2),(E4,2),(D5,1),(C5,1),(B4,2)], bpm=72)
loop_file("confirm.wav", [(E5,0.12),(G5,0.18)], bpm=120, repeats=1)
loop_file("hit.wav", [(220,0.12),(160,0.12)], bpm=120, repeats=1)
loop_file("heal.wav", [(C5,0.15),(E5,0.15),(G5,0.25)], bpm=120, repeats=1)
print("assets generated:", sorted(os.listdir(SPR)), sorted(os.listdir(AUD)))
