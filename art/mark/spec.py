"""Every number of the faint mark. Change them here only.

The faint mark (S1-11, GDD "At most one faint mark on a floor"): a small chalk ring with a dot in
it, scrawled on the steel jamb beside one note's door. Somebody went this way before you and
marked where the note was. It's hasty: the ring runs on past where it started, wobbles, and
the stroke drags thin at its end; the chalk caught only the steel's high points, so it's broken
and grainy. The game shows it only in your torch's beam from a few steps (src/shared/FaintMark).

A plane in Blender's XZ (its drawn face toward -Y, which the FBX makes Roblox's front, -Z), its
middle the origin. It's sized to the jamb's face (0.45 studs wide on every unit, art/unit's
`trim`), so the ring is about 0.37 across: a hand's width, a speck from down the hall and plain
once your beam is on it close up.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))

SET = "FaintMark"  # the MeshPart's name and its texture set
SIDE = 0.44        # the plane, studs square: just inside the jamb's face
TEX = 512          # about 1100 texels a stud: the chalk's grain holds up close in a beam
SEED = 1107

# the ring, in the texture's units (0 to 1 across), from the middle
RING_R = 0.37      # its radius: about 0.33 studs across
RING_SQUASH = 0.86  # narrower than tall by this much: drawn fast, by a hand reaching up
RING_TILT = 16.0   # degrees the oval leans
RING_TURNS = 1.14  # it runs on past where it started
RING_DRIFT = 0.17  # it spirals in this share of its radius from start to end, so the overrun
                    # runs just inside where it began
RING_WOBBLE = 0.035 # how far the hand wanders off round (of the texture)
RING_START = 215.0  # degrees: where the chalk first touched (lower left), going anticlockwise
STROKE = 0.042     # the stroke's half-width at its heaviest (about 0.04 studs across)
STROKE_VARY = 0.3  # how much the width swells and thins along the stroke
STROKE_END = 0.4   # at its end it drags this thin (of STROKE)

DOT = (0.025, -0.015)  # the dot inside, off the middle
DOT_R = 0.05        # its radius

CHALK = (0.90, 0.89, 0.84)  # off-white, a little warm (linear-ish, written as sRGB 0-1)
ROUGHNESS = 0.94   # chalk is dry dust: no shine in the beam
GRAIN = 0.62       # how much of a stroke the chalk actually caught (the rest is the steel)
