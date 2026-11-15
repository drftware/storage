# Wind-ups and noisemakers

The catalog's "Wind-ups and noisemakers" set, built with the finds kit (`art/finds/CRAFT.md`).
`scripts/art.sh set windups [textures|export|renders|quick] [CymbalMonkey]`. The generated Luau
is `src/shared/Finds/Sets/Windups.luau`. Every find here animates, and the animation is the find:
wind one, drop it, walk away, and see what comes to look.

**In the place** (Nov 15): the cymbal monkey is a template in
`ReplicatedStorage.Props.Finds.CymbalMonkey`, made by `Finds/Kit.luau`'s `import` from the
uploaded FBX (CRAFT.md, "Into Studio"); the place keeps it once the owner saves it.

## Cymbal monkey (Rare): "Wind: it bashes its cymbals for 20 seconds, loud"

A clockwork toy of the kind made in Japan from the 1950s to the 1970s: a plush monkey sat with
its legs out, a moulded vinyl face, ears, hands and feet, a felt waistcoat, striped trousers and
a brass cymbal in each fist, wound with a tin key in its back. Ours is no maker's character: a
green felt waistcoat edged in gold braid, navy-and-cream trousers, a maroon fez with a black
tassel, amber eyes and a wide toothy grin.

**Looked at:** the Grand Rapids Public Museum's cymbal monkey, record 2019.35.117
(https://www.grpmcollections.org/Detail/objects/189852: 10.5 in tall, 7.5 wide, 8.5 deep, sat
with its legs forward, a pale vinyl face with red-rimmed staring eyes and a toothy grin, orange
vinyl ears, felt vest, striped trousers, brass cymbals held upright in vinyl fists); two videos
of real clockwork cymbal monkeys on YouTube (watch?v=xV-n0KqppX0, a small plush one in a party
hat; watch?v=_67TKEVQ2Pg, a 5.5-inch furry one), their clashes timed from the sound in the page:
the first 4.6 a second, the second about 6, each slowing by about a fifth over its run before
the spring gave out; Wikipedia's "Cymbal-banging monkey toy" for the history (wind-up and later
battery kinds).

**Size:** 267 mm tall to the fez's top, 1.05 studs (10 inches a stud), as the museum's; its
seat 128 wide, its cymbals 66 across. It sits a little above a person's ankle in the lineup.

**Tells:** the cymbals out in front of it, the round head with a pale face and staring eyes, the
fez. At phone size in a unit it's a small sat figure; the fez and the pale face read first.

**Parts** (pivots in `build.py`): `Body` (root: torso, legs, feet, the key's tin collar),
`Head` (nods about X at the neck; face, ears, fez, the tassel's button), `Eyes` (both eyeballs,
rolling about X through their middles), `Tassel` (swings about X where its cord drapes over
the fez's edge), `ArmL`/`ArmR` (each turns about its own shoulder axis, square to the arm, so
the fist sweeps in and out), `CymbalL`/`CymbalR` (flap on their straps about a near-vertical
axis through the bell), `Key` (turns about Y; positive is clockwise seen from behind).

The arms are drawn at the clash, the cymbals' rims meeting square at x = 0, then swung open 24
degrees: that's how it's found and baked, so the cymbals never shade each other. A turn of -24
on both arms is the clash.

**Motions:**
- `Wind` (2.4 s): the key turned clockwise in four half turns, a regrip between each.
- `Play` (21 s): 70 clashes. The arms accelerate in (Quad In), the rims meet square, bounce off
  2 degrees and swing open again (Sine). On every clash the head nods down 4.5 degrees and back,
  the eyes roll up wide (a Quart In pop), the tassel lags and flings, each cymbal flaps on its
  strap and settles, and the key creeps back. The beat is 4.2 clashes a second wound up, slows to
  3.8 by the middle, then the spring gives out: gaps of 0.36, 0.4, 0.43, 0.49, 0.62 s, a last
  tired clash at 19.5 s, and a swing in that stalls short with the cymbals apart before the arms
  sag open. Every hit lands as `ArmL`'s turn reaches -24: a game ticket plays the clash sound
  there (`CLASHES` in `build.py` lists the times). Numbers in `spec.py` `PLAY`.

**Look:** dark brown plush with paler tips, strands running down (the look's noise, baked into
the normal map); a satin peach vinyl face with rosy cheeks, the skin round the eyes a shade
darker; glossy cream eyeballs, amber irises ringed dark; red lips round a row of white teeth;
felt with a fine fuzz; brass cymbals tarnished in blooms and rubbed bright at the rims; a gold-
lacquered tin key worn to steel at its edges with specks of rust. Dust 0.35 greys what faced up.

**Sheets:** `art/sheets/cymbalmonkey-*.png`; motion previews `out/cymbalmonkey-wind.mp4` and
`out/cymbalmonkey-play.mp4`.
