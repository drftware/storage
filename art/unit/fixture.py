"""Write tests/fixtures/curtain_<Size>.json: the Python solver's answers, for the Luau port.

    python3 art/unit/fixture.py M
"""

import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from spec import Spec  # noqa: E402

RISES = [0.0, 0.3, 1.15, 2.5, 4.0, 5.75, 7.0, 7.65]


def main(size):
    s = Spec(size)
    c = s.curtain
    out = {"params": {"Pitch": c.pitch, "Count": c.count, "BottomClosed": c.bottom_closed,
                      "GuideTop": c.guide_top, "DrumZ": c.cz, "DrumY": c.cy,
                      "DrumRadius": c.r0, "Wrap": s.wrap},
           "cases": []}
    for r in RISES:
        frames, st = c.slats(r)
        out["cases"].append({"rise": r, "phi": st[1], "theta": st[2], "ell": st[3],
                             "drum": c.drum_angle(st),
                             "slats": [list(f) for f in frames]})
    root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    path = os.path.join(root, "tests", "fixtures", f"curtain_{size}.json")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w") as f:
        json.dump(out, f, indent=1)
    print("wrote", path)


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "M")
