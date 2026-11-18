"""The next-floor cards' faces (S4-03b1, art/cards/README.md): every number in one place.

Each version of a floor the team can pick on the ride (NextFloor.Versions) has a face: a picture of
that floor, rendered from the game's own models in Blender, read at a glance on a phone from a card
about 130 points wide. No words on it: the picture says what the floor is.
"""

import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", ".."))
OUT = os.path.join(HERE, "out")
SHEETS = os.path.join(ROOT, "art", "sheets")

# The face's size in pixels: a portrait card, 4 wide to 5 tall. A card is about 130 points wide on
# a Galaxy A16 (about 340 pixels), so 512 stays sharp on the sharpest phone.
PX = (512, 640)
SAMPLES = 160

# The models each face is made from: the game's own, as they're exported.
PADLOCK = os.path.join(ROOT, "art", "padlock", "out", "Padlock.fbx")
MANNEQUIN = os.path.join(ROOT, "art", "mannequin", "out", "Mannequin.fbx")
POSES = os.path.join(ROOT, "art", "mannequin", "out", "poses.json")
BULB = os.path.join(ROOT, "art", "corridor", "out", "Corridor_Bulb.fbx")
HALL = os.path.join(ROOT, "art", "corridor", "out", "Corridor_Straight.fbx")
ELEVATOR = os.path.join(ROOT, "art", "elevator", "out", "Elevator.fbx")

# Each face's own colour of light, so the three cards on a panel tell apart at a glance before
# you've read a picture: cold moonlight for the dark, warm bulb for the padlocks, a sick
# fluorescent for the monsters, the emergency red for the way back down.
COLD = (0.42, 0.58, 1.0)
WARM = (1.0, 0.62, 0.32)
SICK = (0.70, 1.0, 0.78)
RED = (1.0, 0.16, 0.10)

# PowerOut: the hall's caged bulb, dead, hanging in the dark; a torch catches its cage.
# The camera from the glass's middle, and what it looks at from there (studs), and its lens (mm).
BULB_CAM = ((0.32, -1.55, -0.30), (0.0, 0.0, 0.10), 50)
BULB_RIM = 45.0      # the cold light behind it, watts: the cage's outline
BULB_TORCH = 18.0    # the torch from below the camera, watts: a glint on the wires
BULB_POOL = 320.0    # the cold pool on the wall behind, so the dead bulb stands out black on it
BULB_EXPOSURE = 0.35

# TwicePadlocks: two padlocks side by side, the right one swung a little, on a steel door.
LOCK_GAP = 0.37      # each padlock's middle from the card's middle, studs
LOCK_SWING = 11.0    # the right one's swing, degrees, as if just hung
LOCK_DROP = 0.08     # the right one hangs this much lower
LOCK_CAM = ((0.0, -2.75, 0.22), (0.0, 0.0, 0.0), 50)
LOCK_KEY = 95.0      # the warm bulb above left
LOCK_RIM = 30.0
LOCK_EXPOSURE = 0.0

# TwiceMonsters: two Mannequins standing as they're found, at the end of a dark hall, lit from
# behind by a buzzing tube; the near one a step ahead.
FIGURES = (((-1.15, 7.0, 0.0), 8.0), ((1.25, 9.6, 0.0), -14.0))  # where, turned (degrees)
FIG_CAM = ((0.2, -2.0, 4.4), (0.0, 8.0, 3.6), 32)
FIG_BACK = 900.0     # the tube behind them
FIG_TORCH = 160.0    # the torch from the camera, a pool at their feet
FIG_EXPOSURE = 0.3

# CaughtToLobby: looking down the shaft at the car far below, its cables running down to it,
# lit red from the bottom of the shaft: the way back down to the lobby.
SHAFT = (15.0, 14.0, 70.0)   # the shaft's width, depth and height above the car's floor
BEAMS = 5.0          # a steel beam round the shaft every this many studs: they draw the depth
DOWN_CAM = ((0.7, -1.0, 36.0), (0.0, 0.4, 0.0), 38)
DOWN_GLOW = 9000.0   # the red from the pit, lighting the car's edges and the shaft walls
DOWN_CAR = 220.0     # the car's own lamp
DOWN_EXPOSURE = 0.8

# The look sheet: the four faces side by side at the size a Galaxy A16 shows a card.
SHEET_CARD_PX = 170
