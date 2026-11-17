"""The words a find's game row is written in (F-G1f, art/finds/PIPELINE.md): the sounds it
plays and the shapes of its press. Plain Python, no Blender: each set's spec.py imports it for
its GAME rows, and art/finds/rows.py turns those into src/shared/Finds/Rows.luau.

A sound is a stretch of a recording: its asset id, where in it the sound starts (seconds), how
long it plays, how loud, and its pitch (above 1, a smaller, lighter thing). Until each find has
its own recorded (ROADMAP polish "Finds' own sounds"), finds borrow the tools' and the bedroom
set's stretches, pitched for their size and stuff.
"""


def sound(id, start, length, volume, pitch=None):
    s = {"id": id, "from": start, "length": length, "volume": volume}
    if pitch is not None:
        s["pitch"] = pitch
    return s


def pitched(s, pitch, volume=None):
    """`s` played at `pitch`, and at `volume` if given."""
    return sound(s["id"], s["from"], s["length"], s["volume"] if volume is None else volume, pitch)


# --- Taking it and dropping it -------------------------------------------------------------
# Pro Sound Effects' "Keys In Padlock 1": a clink, metal or glass taken in a hand
CLINK = sound("rbxassetid://9116175991", 0, 0.5, 0.7)
# "Metal Hit Steel Plate Hit Slapped 2": one slap, a hand closing on a tin or steel body
SLAP = sound("rbxassetid://9116657808", 0, 0.3, 0.7)
# "Plastic Ice Chest 25": hollow plastic knocks
HOLLOW = sound("rbxassetid://9117544893", 0, 0.42, 0.8)
# "Switch Portable Plastic Radio Tape Player 9": a hard plastic clack
CLACK = sound("rbxassetid://9119728830", 0.15, 0.35, 0.85)
# "Plastic Bubble Wrap Short Fluttering Movements 12": a plastic sleeve rustling
RUSTLE = sound("rbxassetid://9125745465", 0.2, 0.45, 0.7)
# "Manacles Metal Clangs 4": its first clang, the monkey's cymbals touching as it's lifted
CLANG = sound("rbxassetid://9116460746", 0, 0.42, 0.6)
# "Metal Container 2": from just before its hit, a tin landing and bouncing
TIN = sound("rbxassetid://9116546109", 0.36, 0.9, 0.75)
# "Crowbar Impact Dropping To Concrete 1": steel hitting concrete and bouncing
STEEL = sound("rbxassetid://9114008989", 0, 1.4, 0.65)
# "Chair Drop 3": from its first hard hit, plastic slamming down and rattling
PLASTIC = sound("rbxassetid://9113768847", 0.22, 0.9, 0.8)
# "Shield Impacts 15": a plastic case hitting the floor, crunchy
CRUNCH = sound("rbxassetid://9119075637", 0, 0.7, 0.8)
# "Pillow Blanket 1": the teddy's grab on the cloth, for the squishies and the cowboy doll
SOFT = sound("rbxassetid://9117373366", 0.4, 0.4, 0.75)

# --- Pressing it ---------------------------------------------------------------------------
# The torch's own switch (`Torch.OnSound`, `OffSound`): a lantern, the fairy lights' box and the
# hard hat's lamp click as a torch does.
CLICK_ON = sound("rbxassetid://9114480271", 0.38, 0.14, 1.4)
CLICK_OFF = sound("rbxassetid://9114480269", 0.1, 0.14, 1.4)
# Pro Sound Effects' "Music Box Wind Up 1" (19.6 s): a small music box wound and playing
# "Frere Jacques"; its first 9 seconds under the jack's Wind (the crank turning).
MUSIC_BOX = sound("rbxassetid://9117044359", 0, 9, 1.1)
# "match strike/ignite" (Creator Store, 2.4 s): a match struck and catching, under the wick's
# Light (the tea light's whole strike, the oil lamp's strike and its flame taking).
MATCH_ID = "rbxassetid://71757268954484"
# The jack's bang as its lid flies open: for now "Manacles Metal Clangs 4" (`CLANG`), lower and
# louder; a real spring bang is ROADMAP polish (F-G1b2's follow-up).
POP = sound("rbxassetid://9116460746", 0, 0.42, 1.3, 0.75)
# Pro Sound Effects' "Toy Plastic Feet Wind Up 1" (4.9 s, a key wound then a run): its winding
# under the monkey's Wind (the key in its back turning).
WIND = sound("rbxassetid://9120219923", 0, 2.4, 1)
# "Crash Cymbal" (Creator Store, one hit of a 17-inch crash, almost no silence before it),
# pitched up and cut short into a small brass toy cymbal's clang: one each clash.
CLASH = sound("rbxassetid://867306119", 0, 0.35, 0.9, 1.9)
# "Rolling loop" (Creator Store, small wheels rolling): under the toy car's Push, cut as it
# slows (a fade is ROADMAP polish).
ROLL = sound("rbxassetid://99838569349900", 0, 3.4, 0.6)

# Squeezing it (F-G1e1): each squishy squashes with a sound of its own, measured in Studio
# (AudioPlayer to AudioAnalyzer, 0.1 s bins; all Pro Sound Effects, Roblox's licensed library).
# "Squeeze Toy Squeaky Rubber With Noisemaker Hits 10" (0.51 s, the squeak in its first 0.1 s):
# the duck's squeak.
SQUEAK = sound("rbxassetid://9125994570", 0, 0.5, 1.2)
# "Squeeze Toy Squeaky Rubber With Noisemaker Hits 1" (0.51 s, one hit at its start): low and
# quiet, the stress ball's rubber skin squeezed, its squeaker muffled by the flour inside.
RUBBER = sound("rbxassetid://9125994310", 0, 0.5, 0.45, 0.55)
# "Pillow Blanket 1" (`SOFT`, loudest 0.5 to 0.6 s), a little longer: foam squashed in a hand.
SQUISH = sound("rbxassetid://9117373366", 0.4, 0.5, 0.9)
# "Food Glop Wet 8" (2.51 s, a glop at its start and a smaller one at 0.3 s): goo squelching.
SQUELCH = sound("rbxassetid://9114519462", 0, 0.6, 0.6)
# "Water Bottle 14" (2.25 s, a soft slosh from 0.1 s): gel beads swirling in their skin.
SLOSH = sound("rbxassetid://9120502356", 0.05, 1.2, 0.9)
# "Paper Packet Handling Unfolding Crumpled Sheets 2" (0.47 s, quiet): a paper squishy crinkling.
CRINKLE = sound("rbxassetid://9125723588", 0, 0.47, 1.6)
# "Plastic Bag Breathing Hard Inhales Exhales 7" (0.8 s, a breath out in its first 0.1 s), a
# little higher and soft: the capybara's tiny, happy sigh.
SIGH = sound("rbxassetid://9117408118", 0, 0.8, 0.7, 1.2)

# The chattering teeth's every snap (F-G1e2): the hard plastic clack (`CLACK`), higher and cut
# short, as their plastic jaws slam shut seven times a second.
SNAP = sound("rbxassetid://9119728830", 0.15, 0.2, 0.5, 2.2)

# How far along the halls monsters hear a noisy find (studs: a press's `heard`, its loudness,
# `Use.loudness`). A press with a noise and no `heard` carries as far as the air horn, 130 (the
# cymbal monkey, the jack).
DOWN_THE_HALL = 60  # a squeak you can hear down the hall you're in, no further (the duck)
# a clatter that carries round a corner or two, under the cymbals (the chattering teeth)
ACROSS_THE_FLOOR = 90


def squeeze(s, noisy=False):
    """A squishy's press: one squash and its sound, again once it has come back. `noisy`: the
    squeak is heard by monsters down the hall (the duck)."""
    p = dict(verb="Squeeze", on=[dict(motion="Squeeze", sound=s)], toy=True)
    if noisy:
        p.update(noise="Squeeze", heard=DOWN_THE_HALL)
    return p


# A step that loops until the light runs out, or for good (`Use.Forever`).
FOREVER = float("inf")

# Seconds a lamp stays lit in all (D-250): about a minute, D-188's default for a found light, so
# the lantern's 90 seconds is still the long one. Its switch keeps what's left.
LAMP_LASTS = 60


def lamp(on):
    """A lamp's press: switched on by `on`, off by its SwitchOff with a click, and when its
    light is spent it fades out by the same motion, silent."""
    return dict(
        verb="Switch",
        on=on,
        lasts=LAMP_LASTS,
        out=[dict(motion="SwitchOff")],
        off=dict(motion="SwitchOff", sound=CLICK_OFF),
    )
