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

## Jack-in-the-box (Uncommon): "Wind: a tune, then a bang as it pops"

A tin music box of the 1950s: a printed tin cube with rolled corner seams, a shallow lid on a
wire hinge at the back, yellow inside, held shut by a sprung nickel catch at the front, a wire
crank with a turned red knob on the right side, and a clown on a cloth-covered spring inside.
Ours is no maker's character: each side prints a playing card's suit in a cream panel inside a
coloured border of marquee dots (spade red-bordered at the front, heart green on the crank's
side, diamond blue at the back, club mustard on the left: a jack in a box), the lid a red and
yellow sunburst round a star; the jack wears red-and-cream harlequin diamonds, a two-tier ruff
and a leaning green felt cap with a wool pompom, and his painted face has crazed with age:
blue diamonds through black almond eyes, high thin brows, a red nose and a thin red grin whose
corners climb into his cheeks.

**Looked at:** the Bruce County Museum's 1953 tin jack-in-the-box, record 2017.012.001
(https://brucemuseum.pastperfectonline.com/webobject/011C739F-8C16-440E-A41F-556931348370: 14
cm tall shut, 13.5 cm square, clowns printed on every side in coloured borders, a knob crank on
the right side, a yellow lid standing open past upright, a plastic clown head on a checked cloth
body); the V&A's late-1940s painted tin one by Mettoy (https://collections.vam.ac.uk/item/O89876:
a lid "held down by a small catch", yellow inside, a red crank on the right side high and to the
back, a clown with a plastic head and felt cap on a spotted cloth body over a large spring,
plays "Pop Goes the Weasel"); a video of a 1953 tin one cranked and popping
(https://www.youtube.com/watch?v=SYPBQvt-RbY), timed from its sound in the page as the cymbal
monkey was: the tune's notes at 0, 0.18, 0.87, 1.25, 1.94, 2.33, 2.5, 2.67, 3.24, 3.79, 4.25,
4.52, 5.89, 6.53, 6.85, 7.38 and 7.77 s, silence for 0.9 s, the bang at 8.66 s, then rattles
0.2, 0.38, 0.52 and 0.65 s after it. Those note times are for the sound ticket.

**Size:** 134 mm square and 139 mm tall shut, 0.55 studs (10 inches a stud), as the museum's;
popped, the jack's cap stands 295 mm off the floor, 1.16 studs.

**Tells:** shut, a bright printed cube with a crank on its side and a big black or red suit on
each face; popped, the clown's white face and red nose on harlequin diamonds above the yellow
lid.

**Parts** (pivots in `build.py`): `Box` (root: the printed cube, its gold-lacquered inside, the
crank's bushing, the hinge straps and pin, the catch's rivet), `Crank` (turns about its axle on
the right side, clockwise as you face that side), `Latch` (the catch, flips forward about its
rivet at its foot), `Lid` (turns about the hinge pin; drawn open on its stop, 112 degrees, and
found turned shut), `Jack` (the cloth body and both ruffs, on the spring's foot on the floor:
sways side to side about it, and is found pressed into the box by `scale` 0.785 and `stretch`
0.56, 44 per cent of its height), `Head` (rides the jack, tilts side to side about the neck).

**Motions:**
- `Wind` (9.0 s): the crank turns by itself through the tune, 6.5 turns in 7.8 s, a quicker
  push and a slower pull each turn as a hand cranks, slowing on the last half turn as the last
  note sounds; then 0.9 s of nothing in which the lid lifts once against its catch. The game
  plays `Pop` as it ends.
- `Pop` (2.95 s): the catch flicks off, the lid bangs onto its stop at 0.095 s and bounces three
  times (the video's rattles), the jack springs past its height and bobs, sways side to side on
  its spring with its head swinging after it, settles by 1.75 s, and then slowly cocks its head
  12 degrees at you and stays that way.
- `Shut` (0.9 s): pushed back in: the head straightens, the jack is pressed down as the lid comes
  over and claps shut at 0.55 s, its edge pushes the catch out and the catch clicks over it.

**Look:** the print is all the look's own masks in the find's frame (the lid's worked out where
it lies shut), over a varnished cream ground with a faint grain, scratched, chipped to tin on the
edges and rusted along the foot; inside is gold lacquer; the face's crazing is two sizes of
cracks. The jack's cloth has the spring's coils showing through it as ridges.

**Sheets:** `art/sheets/jackinthebox-*.png`; motion previews `out/jackinthebox-wind.mp4`,
`-pop.mp4` and `-shut.mp4`.

## Wind-up chattering teeth (Common): "Wind: they chatter off across the floor"

A walking wind-up denture: a moulded set of red-pink gums with cream teeth, the clockwork
between the jaws at the back (a tin box, two brass gears on top, the top jaw's pin on two
posts), a key on the side, standing on two cartoon feet whose round toes poke out in front.
Ours is no maker's: glossy orange three-toed feet turned a little out, a white wing key on the
right, twelve teeth a jaw (two broad incisors, a pointed canine, three molars each side), the
gum dipping round the middle of each tooth and rising to a point between two.

**Looked at:** listings for walking wind-up teeth (Hobby Lobby's "Wind-Up Chatter Teeth With
Feet": 1 3/4 in long, 1 3/8 wide, 1 3/4 tall; Boing Toys' classic chattering teeth, 2.5 in; a
metric listing at 7.5 x 6.3 x 4.4 cm), an image search's photos of vintage ones (a boxed 1949
talking teeth, a 1970 one opened to its tin clockwork between the jaws at the back, a walking
pair on brown feet with orange toes and a white side key) and today's walking party-favour
kind; a video of a walking pair running (https://www.youtube.com/watch?v=XzsjkzlkxHA), timed
from its sound in the page: clicks in bursts about 0.085 s apart, the jaw's open and its snap,
so 6 to 7 snaps a second. Commons had one photo of plain chattering teeth and no video.

**Size:** 65 mm across with the key, 62 deep with the toes, 54 tall: 0.26 by 0.24 by 0.21
studs (10 inches a stud), the bigger listings' size.

**Tells:** a grin of cream teeth in red gums, the dark gap between the rows, on two orange feet.

**Parts** (pivots in `build.py`): `Base` (root: the lower jaw, its teeth, the mouth's floor,
the clockwork and the pin), `Jaw` (the top jaw, teeth and domed palate; turns about the pin
behind the teeth, + opens; drawn 9 degrees open as found, a grin, so a turn of -9 shuts it),
`FootL` and `FootR` (each on its ankle under the jaw: `y` swings it fore and aft, `move` lifts
it, `pitch` tips its toe), `Key` (turns about its shaft on the right side).

**Motions:**
- `Wind` (2.19 s): the key turned four half turns, a regrip between each.
- `Chatter` (10.4 s): the top jaw levered open and slammed shut 7 times a second, slowing a
  third across the run, each snap a footfall: the feet ride one crank, a step for each every
  two snaps, the lifted one swinging forward toe up while the planted one pushes it on. It
  waddles onto the planted foot, swivels a little each step, jolts forward on each snap and
  veers as it goes, about 1.2 studs in all, the key spinning back. It gives out, the jaw
  stalls half open and sags back to its grin. Keys sit where each curve turns, eased, so the
  ten seconds stay small in the Luau.

**Look:** glossy pink-red plastic with a fine stipple, deeper red in the mouth, rubbed pale on
the high edges; cream teeth yellowing toward the gum with a hairline of grime where each goes
in (the top row's coordinates worked back to where it lies shut); orange feet with a mould
seam round the side and dull scuffed soles; a white key gone ivory; tin and brass inside.

**Sheets:** `art/sheets/chatteringteeth-*.png`; motion previews `out/chatteringteeth-wind.mp4`
and `-chatter.mp4`.

**In the place:** uploaded (`assets.json`), not imported yet: Studio was in Play when it was
built. Import it in Edit with `require(game.ReplicatedStorage.Shared.Finds.Kit).import("Windups",
{"ChatteringTeeth"})` (from a clone of `Shared` if Studio already required it).
