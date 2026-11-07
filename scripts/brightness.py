# Mean brightness (0-255 grey) of a 4x3 grid of regions in each image, plus the whole frame.
# Compares captures of one view at two quality levels: python3 -I scripts/brightness.py a.jpg b.jpg
import subprocess, sys
W, H, GX, GY = 196, 103, 4, 3
def grid(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-vf", f"scale={W}:{H}", "-f", "rawvideo", "-pix_fmt", "gray", "-"], capture_output=True).stdout
    cells = []
    for gy in range(GY):
        row = []
        for gx in range(GX):
            s = n = 0
            for y in range(gy * H // GY, (gy + 1) * H // GY):
                for x in range(gx * W // GX, (gx + 1) * W // GX):
                    s += raw[y * W + x]; n += 1
            row.append(s / n)
        cells.append(row)
    return cells, sum(raw) / len(raw)
for p in sys.argv[1:]:
    cells, mean = grid(p)
    print(p.split("/")[-1][-24:], f"mean {mean:5.1f} |", " | ".join(" ".join(f"{v:4.0f}" for v in r) for r in cells))
