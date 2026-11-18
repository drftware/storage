# Big finds

The one find a floor has from floor 2 up: carried in both hands, slower than any monster, behind
the unit that rolls up by itself once the code is in (ROADMAP S4-05, `WAVES.md` F-12). Built with
the finds kit (`../CRAFT.md`): `scripts/art.sh set big [textures|export|renders|quick] [Find]`.
Every number is in `spec.py`; the sheets land in `art/sheets/<find>-*.png`.

## Jukebox (S4-05a, D-414)

- **What it is.** A 1940s arch-top jukebox of our own design in that tradition: no maker's name,
  no copied cabinet. The design doc names the jukebox as a big find, so it's the first.
- **Real size.** The 1946 arch-top cabinets' spec sheets give about 59.5 in tall, 32.5 in wide
  and 25 to 27 in deep: 5.95 by 3.25 studs, 2.75 deep with its bay. It stands a little taller
  than you (the lineup's person is 5.4 studs). References were taken from what those cabinets
  are known to look like, not from photos opened this session: a photo pass (three or more
  arch-tops from museum and auction listings) is owed before it's ticked built.
- **Its tells.** The horseshoe of coloured plastic up both sides and round the arch (amber,
  orange, deep red, grooves between); the chrome speaker grille low down; the bay window over
  the record, a pale gold panel behind it so it reads as a record player, not a screen; the fan
  of chrome rods inside the arch.
- **Parts.** `Cabinet` (the root: walnut body, kick base, chrome, the bay, the turntable's mat,
  tone arm and the rack of records, the ivory keys, the speaker), `Glow` (the plastics, the
  emissive part), `Window` (the bay's glass, clear), `Record` (the single, turning about Z on the
  spindle).
- **Its motion.** `Play`: the plastics warm up with a stutter as old valves do, then the record
  comes up to speed, heavy at first, 45 turns a minute. Found dark and still. At home it plays
  every record you own (the home chain's press); on the climb it is only carried.
- **Its light.** One warm point light (0.6, range 10, no brighter than a unit's bulb), off as
  found; glow strength 1.6 in Roblox.
- **Bake.** 2048 (a big find), 129 texels a stud, 4,640 triangles.
- **Its game row** (`spec.py`, `GAME`): Legendary, 800, floor 2 up, heft 1. Written but not
  ticked built in `WAVES.md`: a ticked find joins every unit's deal, and a big find is dealt only
  by a floor's big-find place (S4-05b ticks it). Its `size` is "Large" until S4-05b adds "Big".
