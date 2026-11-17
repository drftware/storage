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


def slowing(s, at, stop, fade):
    """`s` slowing as a music box's spring runs down, its pitch held as a real box's comb holds
    it (F-G1e5f): full speed until `at` seconds in, then its speed falling as (1 - s) ** `fade`
    to nothing at `stop`, the curve the toy's own turning runs down on. Its length becomes what
    of the recording that plays, so the tune runs out as the toy stops (`Use.through`)."""
    heard = at + (stop - at) / (fade + 1)
    out = dict(s)
    out["length"] = round(heard * s.get("pitch", 1), 4)
    out["slows"] = {"at": at, "stop": stop, "fade": fade}
    return out


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

# A glow stick cracked (F-G1e5b): Pro Sound Effects' "Plastic Crack 2" (1.6 s, hard plastic
# breaking with a crunch), its first crack (loudest 0.13 s in, peak 140, measured in Studio),
# started just before it so it lands on the snap, higher for a thin tube with glass inside.
GLOW_CRACK = sound("rbxassetid://9117458008", 0.1, 0.3, 0.8, 1.35)
# ... then shaken to mix: "Water Bottle 14"'s slosh (`SLOSH`), short, soft and high, a little
# liquid and the glass rattling in a thin tube.
GLOW_SHAKE = sound("rbxassetid://9120502356", 0.1, 0.6, 0.45, 1.7)

# The chattering teeth's every snap (F-G1e2): the hard plastic clack (`CLACK`), higher and cut
# short, as their plastic jaws slam shut seven times a second.
SNAP = sound("rbxassetid://9119728830", 0.15, 0.2, 0.5, 2.2)
# The robot's every footfall (F-G1e2b): Pro Sound Effects' "Robot Footsteps Single Walks Hollow
# Metal Ringy 2" (31.2 s; its first step lands at 0.15 s and rings to 0.45 s, measured in Studio),
# one hollow metal step, pitched up into a small tin foot's clank.
CLANK = sound("rbxassetid://9125818638", 0.14, 0.22, 0.45, 2.0)
# The wind-up mouse's squeak where it stalls and rocks onto its nose: the duck's squeak
# (`SQUEAK`), higher and cut short, a mouse's eek.
EEK = sound("rbxassetid://9125994570", 0, 0.28, 0.7, 1.9)
# The tin bird's every whistled note: Pro Sound Effects' "Pealess Whistle Referee Fox 40 7"
# (0.63 s: a weak burst, then a strong one from 0.2 s to 0.5 s, measured), the strong burst
# pitched up into a small bellows' reedy note.
WHISTLE = sound("rbxassetid://9117259114", 0.18, 0.3, 0.45, 1.5)
# The tin carousel's tune: APM's "Music Box 6" (31.8 s, a real music box, playing from 0.05 s
# without a gap), as long as it turns; its row slows it with the top (`slowing`, its RIDE).
CAROUSEL_TUNE = sound("rbxassetid://9043210085", 0.05, 15.5, 0.8)

# One press, one noise (F-G1e3), measured in Studio (AudioAnalyzer: loudness and the spectrum's
# loudest bin every 0.06 s). The kazoo's hum: Pro Sound Effects' "Kazoo Fanfare 3" (4.3 s), its
# last note, held on one pitch from 2.68 s and swelling at 3.3 s before it stops at 3.6 s, played
# a little lower so it lasts the kazoo's whole note (1.22 s).
HUM = sound("rbxassetid://9114898444", 2.68, 0.92, 0.9, 0.75)
# The toy drum's every hit: "INSTRUMENT Snare Drum" (Creator Store, 0.51 s, the hit in its
# first 0.05 s), pitched up into a small tin drum's calfskin head and cut before the next hit.
DRUM_HIT = sound("rbxassetid://127450250691379", 0, 0.4, 0.9, 1.3)
# The farm spinner (F-G1e3b): its lever slamming back up to its stop, the hard plastic clack a
# little higher; then its arrow hopping into each notch, the clack small, high and cut short.
LEVER = pitched(CLACK, 1.25, 0.8)
TICK = sound("rbxassetid://9119728830", 0.15, 0.12, 0.4, 2.8)
# The cat the arrow stops on as built: "Cat Meow Sound" (Creator Store, 0.97 s; measured in Studio,
# AudioAnalyzer PeakLevel in 60 ms bins: the meow from 0.06 s, loudest to 0.4 s, gone by 0.6 s),
# through the toy's little speaker.
MEOW = sound("rbxassetid://83454004588488", 0.04, 0.65, 1.3, 1.0)  # a pitch, as its cue list's other sounds have: Luau types a list by its first entry
# The other seven animals the arrow lands on (F-G1e3d), each one short, clean call through the same
# little speaker. Measured in Studio Play (Nov 17, V3d) by `PlaybackLoudness` every 20 ms, which
# reads the recording, not the Sound's volume: each starts just before its call rises above a
# sixth of its peak and ends as it falls back, and its volume brings its peak to the meow's (205
# at 1.3, about 265). Pro Sound Effects where its farm recordings have the animal, Creator Store
# uploads where they don't. The rooster's recording is quiet, so it plays near the top of
# Roblox's volume.
COW = sound("rbxassetid://96686849712218", 0.6, 1.25, 0.6, 1.0)  # "Cow sound", 2.12 s: peak 456, 0.66 to 1.8 s
PIG = sound("rbxassetid://9117352464", 0.18, 0.55, 0.8, 1.0)  # Pro Sound Effects "Pig Grunts 3": peak 321, 0.23 to 0.6 s
SHEEP = sound("rbxassetid://9119065374", 0.22, 0.95, 1.6, 1.0)  # Pro Sound Effects "Sheep Blats 1": peak 163, 0.27 to 1.1 s
HORSE = sound("rbxassetid://609578817", 0.12, 1.0, 1.5, 1.0)  # "horse_exterior_whinny_05": peak 181, 0.17 to 1.03 s
DUCK = sound("rbxassetid://105918663447014", 0.0, 0.65, 1.5, 1.0)  # "QUACK": peak 180, 0 to 0.6 s
ROOSTER = sound("rbxassetid://83144094730313", 0.15, 1.6, 7.0, 1.0)  # "rooster": peak 38, 0.2 to 1.7 s
DOG = sound("rbxassetid://78467017795178", 0.03, 0.7, 2.6, 1.0)  # "Dog Bark SFX V2": peak 102, 0.07 to 0.67 s
# The cowboy doll's cord creeping home under its governor, the owner's default until its six
# lines are recorded (OWNER.md): Pro Sound Effects' "Robot Servo 3" (3.98 s, a steady dual-tone
# whine from 0.18 s, measured), lower and slower so it runs the cord's whole 2.4 s creep.
WHIRR = sound("rbxassetid://9118399720", 0.2, 1.9, 1.6, 0.8)
# The singing fish's motors under its latex, the default until its song is recorded: "Robot Servo
# 19" (4.64 s, steady from 0.12 s to 4.4 s, measured), lower, so it runs the press's 6 s.
MOTOR = sound("rbxassetid://9118401640", 0.12, 4.2, 1.4, 0.7)
# The siren car's wail (F-G1e4): Pro Sound Effects' "Toy Siren Four Variations 1" (a small
# whooper toy siren, 4.77 s). Measured in Studio Play (Nov 17, V4b) by `PlaybackLoudness` every
# 20 ms: silent to 0.36 s, quiet whoops building to 1.25 s (the flywheel revving), full whoops
# every 0.3 s to 2.8 s (peak 191), dying away to nothing at 3.67 s. Played from 0.34 s, the first
# second of a press was near silent in Play (loudness 0 to 3 under both pushes), so it starts at
# 1.0 s, where the whoops become audible: at 0.7 the first whoop answers the press within half a
# second, the full wail comes as the car leaves the hand, and it whimpers away as the flywheel
# runs down (silent at 3.8 s; the car crawls on under its roll to about 5.6 s). Its volume
# brings its peak to the meow's, about 265.
SIREN = sound("rbxassetid://9120221867", 1.0, 2.67, 1.4, 0.7)

# How far along the halls monsters hear a noisy find (studs: a press's `heard`, its loudness,
# `Use.loudness`). A press with a noise and no `heard` carries as far as the air horn, 130 (the
# cymbal monkey, the jack).
DOWN_THE_HALL = 60  # a squeak you can hear down the hall you're in, no further (the duck)
# a clatter that carries round a corner or two, under the cymbals (the chattering teeth, the
# robot's clanking, the tin bird's whistles)
ACROSS_THE_FLOOR = 90
# a bang as loud as the air horn's blast (`Use.LureReach`): the toy drum
AS_FAR_AS_THE_HORN = 130


def squeeze(s, noisy=False, heard=DOWN_THE_HALL):
    """A squishy's press: one squash and its sound, again once it has come back. `noisy`: the
    squeak is heard by monsters as far as `heard` (the duck's down the hall; the mega goo
    ball's deep squelch across the floor)."""
    p = dict(verb="Squeeze", on=[dict(motion="Squeeze", sound=s)], toy=True)
    if noisy:
        p.update(noise="Squeeze", heard=heard)
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
