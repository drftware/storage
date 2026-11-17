"""The crack a fragile find's glass shows once it's been dropped hard (F-G1e5e, `Finds/Chip`).

A hit point low and off to one side, five cracks running out from it with a fork or two each,
and a short ring of cracks round the hit, as a knock on a lamp chimney leaves. Each crack is a
pale core with a thin dark edge, so it reads on clear glass over a dark hall and on lit coloured
glass alike, and thick enough to read at phone size on a part a third of a stud across. Seeded,
so it rebuilds the same. Pure Python (no Blender, no PIL): it only writes a PNG.

    python3 art/finds/kit/crack.py      writes out/Crack.png and out/Crack_look.png

`lune run scripts/upload_art Crack` sends Crack.png up; its image ID goes in `Finds/Chip`.
"""
import math
import os
import random
import struct
import zlib

SIZE = 256
SEED = 7
HIT = (0.36, 0.64)  # where the knock landed, across and down the picture
ARMS = 5  # cracks running out from the hit
REACH = (0.32, 0.62)  # each one's length, of the picture's width
STEP = 9.0  # pixels per kink
KINK = 0.38  # radians a crack may turn at each kink
WIDTH = (5.0, 1.6)  # its pale core's width at the hit and at its end, in pixels
EDGE = 1.4  # the dark edge round the core, in pixels
RING = 0.11  # the ring of cracks round the hit, its radius of the picture's width
CORE = (238, 246, 255)
DARK = (34, 38, 44)
DARK_ALPHA = 0.55

OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "out")


def walk(rng, x, y, angle, length, w0, w1, segs):
    """One crack from (x, y): kinked steps, tapering, forking now and then."""
    n = max(2, int(length / STEP))
    for i in range(n):
        angle += rng.uniform(-KINK, KINK)
        nx, ny = x + math.cos(angle) * STEP, y + math.sin(angle) * STEP
        t0, t1 = i / n, (i + 1) / n
        segs.append((x, y, nx, ny, w0 + (w1 - w0) * t0, w0 + (w1 - w0) * t1))
        x, y = nx, ny
        if 0.3 < t0 < 0.75 and rng.random() < 0.14 and w0 > 2.2:
            side = rng.choice((-1, 1))
            walk(rng, x, y, angle + side * rng.uniform(0.5, 0.9), length * (1 - t0) * 0.55,
                 w0 + (w1 - w0) * t1, w1 * 0.8, segs)


def cracks():
    rng = random.Random(SEED)
    hx, hy = HIT[0] * SIZE, HIT[1] * SIZE
    segs = []
    start = rng.uniform(0, math.tau)
    angles = [start + i * math.tau / ARMS + rng.uniform(-0.35, 0.35) for i in range(ARMS)]
    for a in angles:
        walk(rng, hx, hy, a, rng.uniform(*REACH) * SIZE, WIDTH[0], WIDTH[1], segs)
    # the ring: short arcs between neighbouring arms, a few of them left out
    r = RING * SIZE
    for i, a in enumerate(angles):
        if rng.random() < 0.3:
            continue
        b = angles[(i + 1) % ARMS] + (math.tau if i == ARMS - 1 else 0)
        steps = 4
        pts = []
        for k in range(steps + 1):
            t = a + (b - a) * k / steps
            rr = r * rng.uniform(0.9, 1.1)
            pts.append((hx + math.cos(t) * rr, hy + math.sin(t) * rr))
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            segs.append((x0, y0, x1, y1, 2.2, 2.2))
    return segs


def draw(segs):
    core = [0.0] * (SIZE * SIZE)
    edge = [0.0] * (SIZE * SIZE)
    for x0, y0, x1, y1, w0, w1 in segs:
        pad = max(w0, w1) / 2 + EDGE + 1
        dx, dy = x1 - x0, y1 - y0
        ll = dx * dx + dy * dy or 1e-9
        for py in range(max(0, int(min(y0, y1) - pad)), min(SIZE, int(max(y0, y1) + pad) + 1)):
            for px in range(max(0, int(min(x0, x1) - pad)), min(SIZE, int(max(x0, x1) + pad) + 1)):
                cx, cy = px + 0.5, py + 0.5
                t = max(0.0, min(1.0, ((cx - x0) * dx + (cy - y0) * dy) / ll))
                d = math.hypot(cx - (x0 + dx * t), cy - (y0 + dy * t))
                half = (w0 + (w1 - w0) * t) / 2
                a = max(0.0, min(1.0, half + 0.5 - d))
                e = max(0.0, min(1.0, half + EDGE + 0.5 - d))
                i = py * SIZE + px
                core[i] = max(core[i], a)
                edge[i] = max(edge[i], e)
    return core, edge


def pixels(core, edge, under=None):
    rows = []
    for y in range(SIZE):
        row = bytearray([0])
        for x in range(SIZE):
            i = y * SIZE + x
            c, e = core[i], edge[i] * DARK_ALPHA
            a = c + e * (1 - c)
            if under is None:
                if a <= 0:
                    row += bytes(4)
                    continue
                rgb = [(CORE[k] * c + DARK[k] * e * (1 - c)) / a for k in range(3)]
                row += bytes([round(v) for v in rgb] + [round(a * 255)])
            else:
                rgb = [CORE[k] * c + DARK[k] * e * (1 - c) + under[k] * (1 - a) for k in range(3)]
                row += bytes([round(v) for v in rgb] + [255])
        rows.append(bytes(row))
    return rows


def png(path, rows, width):
    def chunk(kind, data):
        return struct.pack(">I", len(data)) + kind + data + struct.pack(">I", zlib.crc32(kind + data))
    head = struct.pack(">IIBBBBB", width, len(rows), 8, 6, 0, 0, 0)
    with open(path, "wb") as f:
        f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", head)
                + chunk(b"IDAT", zlib.compress(b"".join(rows), 9)) + chunk(b"IEND", b""))


def main():
    os.makedirs(OUT, exist_ok=True)
    core, edge = draw(cracks())
    png(os.path.join(OUT, "Crack.png"), pixels(core, edge), SIZE)
    # the look sheet: over a dark hall's glass, and over a lit amber shade
    dark, lit = pixels(core, edge, (40, 44, 52)), pixels(core, edge, (214, 150, 70))
    png(os.path.join(OUT, "Crack_look.png"), [a[:1] + a[1:] + b[1:] for a, b in zip(dark, lit)],
        SIZE * 2)
    print("CRACK -> art/finds/kit/out/Crack.png")


if __name__ == "__main__":
    main()
