"""Build the security camera feed's two pictures (art/feed/README.md).

    blender -b --factory-startup -P art/feed/build.py
    (plain python3 runs it too: it needs nothing but the standard library)

out/FeedGrain.png  128x128, tiles: a security camera's grain, white specks of every strength on
                   clear, with every other row a faint dark scanline. FeedView lays it over the
                   picture and jumps it to a new place each frame the picture updates, by whole
                   pixels across and even rows down, so the grain crawls and the lines hold still.
out/FeedSnow.png   128x128, tiles: a dead channel's snow, solid, with a few torn bright bands: what
                   the feed shows as it cuts in and as it cuts out.

Seeded, so a rebuild makes the same pictures (the sha256 in assets.json holds).
"""

import os
import random
import struct
import zlib

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "out")
SIZE = 128
SEED = 7

# The grain: how strong a speck can be (alpha out of 255) and how many of them are bright.
GRAIN_MOST = 105  # the strongest everyday speck: the picture still reads through it
GRAIN_BRIGHT = 0.035  # share of specks that flare near white
SCANLINE = 46  # a scanline row's darkness (alpha of black): felt, not seen as stripes
# The snow: grey levels, and the torn bands across it.
SNOW_LOW, SNOW_HIGH = 18, 235
BANDS = 5  # bright torn rows across the snow
BAND_LIFT = 70  # how much brighter a band's row is


def write_png(path, w, h, rows):
    """rows: one bytes object per row, RGBA, top row first."""
    raw = b"".join(b"\x00" + r for r in rows)

    def chunk(t, d):
        c = struct.pack(">I", len(d)) + t + d
        return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(png)


def grain(rng):
    rows = []
    for y in range(SIZE):
        row = bytearray()
        for _ in range(SIZE):
            if y % 2 == 1:
                row += bytes((0, 0, 0, SCANLINE))
                continue
            if rng.random() < GRAIN_BRIGHT:
                a = rng.randint(150, 230)
            else:
                a = int(min(GRAIN_MOST, abs(rng.gauss(0, GRAIN_MOST * 0.45))))
            row += bytes((255, 255, 255, a))
        rows.append(bytes(row))
    return rows


def snow(rng):
    bands = set(rng.sample(range(SIZE), BANDS))
    rows = []
    for y in range(SIZE):
        row = bytearray()
        lift = BAND_LIFT if y in bands else 0
        for _ in range(SIZE):
            v = min(255, rng.randint(SNOW_LOW, SNOW_HIGH) + lift)
            if y % 2 == 1:
                v = v * 3 // 4  # the scanlines run through the snow too
            row += bytes((v, v, v, 255))
        rows.append(bytes(row))
    return rows


def main():
    os.makedirs(OUT, exist_ok=True)
    rng = random.Random(SEED)
    write_png(os.path.join(OUT, "FeedGrain.png"), SIZE, SIZE, grain(rng))
    write_png(os.path.join(OUT, "FeedSnow.png"), SIZE, SIZE, snow(rng))
    print("DONE feed: FeedGrain.png, FeedSnow.png")


main()
