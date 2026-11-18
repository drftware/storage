"""Every number of the Big finds set, in studs (10 inches a stud, the boxes' scale). Change them here.

A find's frame in Blender: X across its front, Y away from you (its front faces -Y), Z up, the
origin the find's pivot (the middle of its bottom, on the floor).

The big finds (art/finds/WAVES.md, F-12) are the one find a floor has from floor 2 up, carried in
both hands, behind the unit that rolls up by itself once the code is in (ROADMAP S4-05).
"""

# --- the jukebox (S4-05a) ----------------------------------------------------------------------
# A 1940s arch-top jukebox of our own design (README: the references and its tells). Real size
# from the 1946 arch-tops' spec sheets: about 59.5 in tall, 32.5 in wide, 25 in deep, so it
# stands a little taller than you do. Its tells from a doorway: the arch of coloured plastic that
# runs down both sides like a horseshoe, the chrome speaker grille low down, and the bay window
# over the record in the middle.
JUKEBOX = dict(
    w=3.25,                 # 32.5 in across
    d=2.5,                  # 25 in deep
    h=5.95,                 # 59.5 in tall
    front=-1.05,            # the wooden face, set back so the arch and the bay stand proud of it
    plinth=dict(h=0.24, inset=0.07),   # the dark kick base it stands on
    # the horseshoe of coloured plastic: up each side and round the arch, 0.36 wide (a fist)
    band=dict(c=1.42, w=0.36, z0=0.42, proud=0.17, chrome=0.026),
    # the bay window over the record: a chrome-framed box, its glass leaning back
    bay=dict(x=1.02, z0=2.6, z1=3.95, out=0.52, lean=0.24, frame=0.035),
    platter=dict(r=0.38, z=2.74, y=-1.33),   # a 7 in single on the turntable, seen from above
    stack=dict(n=9, r=0.33, t=0.02, y=-1.16, z=2.98, gap=0.075),  # the changer's records behind
    # the row of selector buttons under the window, and the coin slot's plate at its right
    keys=dict(x=1.08, z0=2.22, z1=2.48, n=10, slot_x=1.3),
    # the speaker: dark cloth behind chrome bars, low down where the sound comes from
    grille=dict(x=1.02, z0=0.6, z1=2.06, bars=7, bar_r=0.03),
    # the fan of chrome rods over the dark cloth inside the arch
    fan=dict(r0=0.32, r1=1.12, rods=7, rod_r=0.024, cloth_r=1.2),
    glow_rgb=(255, 168, 88),   # the plastics lit from inside: warm amber through orange and red
    dust=0.5, seed=4.6,
)

from game import (  # noqa: E402
    STEEL,
    pitched,
)

GAME = [
    # The jukebox's row is written but not ticked built in WAVES.md: a ticked find joins every
    # unit's deal, and a big find is dealt only by a floor's big-find place (ROADMAP S4-05b).
    dict(
        key="Jukebox",
        catalog="Jukebox",
        name="Jukebox",
        grade="Legendary",
        worth=800,
        from_=2,  # big finds start on floor 2, one a floor (design doc)
        grip=(0, 2.3, 0),  # hugged round its middle, under the bay window
        heft=1.0,  # the heaviest thing you carry: both hands, slower than any monster
        size="Large",
        pickUp=pitched(STEEL, 0.6),
        drop=pitched(STEEL, 0.5),
    ),
]
