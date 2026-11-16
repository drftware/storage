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

## Wind-up walking robot (Uncommon): "Wind: it clanks off in a straight line for 15 seconds"

A printed tin walker in the post-war Japanese way: a boxy torso, a square head on a steel collar,
arms on shoulder pins, short legs on hip pins standing in big flat pressed-tin feet, a key in its
back. Ours is no maker's: printed cobalt blue with rows of pressed rivets, a dark gauge panel in a
red frame on its chest (a cream dial with a red zone and needle, a small yellow dial, a bar meter,
three plastic buttons: red, yellow, green), a yellow-and-black hazard belt, amber lens eyes in
steel bezels, a grille mouth, red ear cones, a strip of little lamps on its brow, a coil-spring
aerial with a red ball, red C-claw hands, gunmetal legs with two bare-tin ribs, red feet with a
dark sole line, a hatch on its back with a red diamond maker's mark and a brass butterfly key.

**Looked at:** a Nomura-style 1950s-60s tin "Sparky" robot (antiquetoys.com, "Nomura or Noguchi
Tin Windup Sparky Robot": the boxy torso, the domed square head, ear discs, arms hung on the
shoulders, the key in its side), Maison Empereur's small wind-up robot (empereur.fr, a
reproduction of the post-war walkers: 11.5 cm tall, 6 cm wide; square head, printed chest of
dials, flat arms on pins, big red feet), listings of 1950s-60s walkers (a Yoshiya "Space Man"
8.5 in, a Daiya walker 6.5 in), the Science Museum Group's 1950s Yoshiya "Atom Robot" record (tin
litho before plastic), and a YouTube review of a clockwork metal walker ("Clockwork Metal Robot
- unboxing and review"): it walks with its arms swinging opposite its legs, and its clanks come
about every 0.28 s, timed from the sound as the cymbal monkey's were.
**Size:** 162 mm (6.4 in) to the top of its head, 187 mm (7.4 in) to the aerial's ball: 0.64 and
0.73 studs; 87 mm across its arms, feet 46 mm long.
**Tells:** the boxy blue body on stubby legs in big red feet, the aerial and ball on top, the
round amber eyes. From a doorway it's a small find: a blue and red speck, like the teeth.
**Parts:** `Body` (root, travelling `x`, `y`, `yaw`, leaning `pitch`, waddling `roll`), `LegL`
and `LegR` (turn about X on hip pins 14.5 mm either side), `FootL` and `FootR` (on the legs at
the ankle pin: `pitch` and `roll` keep the sole flat, `move` along the leg keeps it on the floor
or lifts it on its swing), `ArmL` and `ArmR` (turn about X on shoulder pins), `Aerial` (`pitch`
and `roll` about its socket), `Key` (turns about Y). Left is +X.
**Motions:** `Wind` (five half turns of the key), `Walk` (about 15 s of footfalls, 3.6 a second
slowing to under 2, the arms swinging 24 degrees opposite the legs' 15, rocking 3 degrees onto
the planted foot, leaning 3 degrees into it and nodding on each clank; the aerial is a damped
spring flung about by the sway and the clanks; it stalls, the legs straighten, and the arms swing
on their pins a moment). It covers about 3.4 studs. The body moves only as the planted foot
pushes it, so no foot slides (`robot_walk`).

## Wind-up mouse (Uncommon): "Wind: it zips off and squeaks wherever it stops"

A flocked clockwork mouse of the kind sold from the 1920s to now: a grey teardrop body of nylon
flock over a tin shell, sitting on a grey plastic plate with two drive wheels under its middle
and a tin knob under its rump to rest on. Ours is no maker's: pink-lined felt ears cupped
forward, domed printed eyes (cream, a warm brown iris looking ahead, a printed shine), a pink
bead nose, three black nylon whiskers a side, a stiff black plastic tail on the wag cam, a brass
butterfly key out of its left side through a tin eyelet. The flock is rubbed darker along its
back where hands pick it up and worn through to the dark shell at the snout's tip and the
underside's edge.

**Looked at:** the V&A's mechanical mouse B.114-1996 (collections.vam.ac.uk/item/O36956: Hong
Kong, 1975-79, grey nylon flock over metal, cloth ears, printed paper eyes, a black plastic tail,
the key bar out of its left side, a grey plastic underside, two wheels under the centre, a
balancing knob at the back; 1.5 in tall and wide) and its photo; Brent Museum's 1925 clockwork
mouse T944 (bma-collections.brent.gov.uk, 85 mm long, 38 wide, 40 high, fabric over iron). Two
modern listings (kidero.be, goodio.be) were behind bot checks; one mentioned a tail that wags as
it runs. No video was timed: the run's numbers come from a toy's speed (spec `ZIP`).

**Size:** 84 mm nose to rump, 40 wide, 36 tall (44 to the ears' tops), the tail reaching 52 mm
behind: 0.33 studs long, 0.17 tall. A speck from a unit's doorway, as every find under six inches
is; held, its pink ears, eyes and brass key read at once.

**Tells:** the pink ears, the grey teardrop, the brass key.

**Parts:** `Body` (root: the flock, eyes, nose, whiskers, plate, knob, eyelet; travels with `x`,
`y`, `yaw`, `pitch`), `Ears` (both, on one hinge across the head: they flick when it stops),
`Wheels` (both on one axle), `Tail` (wags about its root with `turn`, bobs with `pitch`), `Key`.
The ears are their own part because the bake smeared them onto the flock where their feet sink in
(dark wedges); the eyes' domes sit deep with their skirts under the flock for the same reason.

**Motions:** `Wind` (four half turns of the key, a regrip between each, 1.95 s). `Zip` (6 s):
worked out from one spring in `mouse_zip`. It bites and launches in 0.06 s at 3 studs a second,
curls 3.2 degrees a stud to its left (one wheel drags), shimmies and its nose buzzes on its knob
as the gears run, slows as the spring gives out, stalls dead near 5 s, about 11 studs off and
36 degrees round, then rocks onto its nose three times (5.4, 1.5, 0.35 degrees: parabolas, so
the knob lands hard), the moment the game squeaks. The tail wags on the cam (a whole number of
wags, so it stops straight) and whips behind as stiff plastic does, ringing when it stops; the
ears flick on each rock; the key unwinds with the distance run.

## Clockwork tin bird (Epic): "Wind: it hops and whistles"

An antique hopping bird of printed tinplate, the kind German and Japanese makers stamped from the
1920s to the 1960s: two pressed halves crimped along a seam down its back and belly, a folded tin
bill, a loose fan tail slotted into the rump, two wire legs on a crank out of its belly, each on a
stamped foot, and a brass key in its left side. Ours is no real bird and no maker's: a scarlet cap
that sweeps from the bill over the crown and down the nape, printed the old way (deeper crimson at
its edge, a paler sheen on the crown, rows of small crimson-keyed feathers), a dove-grey stripe
under it over the eye, a cream face and throat, a gold breast of small printed feathers deepening
to ochre round the flanks, an olive scalloped back, a printed wing (teal coverts, a cream and a
gold bar, long dark flight feathers edged in ochre), and a rust tail barred in brown with cream
tips. The print is rubbed through to bright tin on the crown, the breast and the seam, chipped at
the edges, with freckles of rust low down. Our maker's mark (a cream oval in a red ring, an ink
star) is printed under the belly.

**Looked at:** the V&A's API (`api.vam.ac.uk/v2/objects/search`, see the mouse): O36973, a
tinplate sparrow (2.25 in tall, 1.5 in wide: a red cap down the nape, a cream face, a grey stripe
through the eye, a printed red-brown wing of scalloped feathers, a loose fan tail, stamped brown
legs and feet, the key in its side; photo `framemark.vam.ac.uk/collections/2006AF4148/full/
!800,600/0/default.jpg`), O36970 a robin (image 2006AF4153); a 1960s German hopping bird listed
at 85 x 56 x 40 mm. No video with a hop rate was found: `HOP` is a toy's numbers.

**Size:** 115 mm bill to tail tip, 60 tall, 47 across the key: 0.45 studs long, 0.24 tall. A
speck from a unit's doorway, as every find under six inches is; held, the red cap, the orange
bill on its cream throat, the eye and the striped tail read at once.

**Tells:** the scarlet cap, the orange bill, the cocked striped tail.

**Parts:** `Body` (root: the pressed body, its pivot under the feet so a pitch rocks it on them;
travels with `x`, `y`, `z`, `yaw`, `pitch`), `Bill` (the upper bill, still), `Beak` (the lower
bill on the gape hinge, X: it opens on each whistle note and flicks on landings), `Tail` (the
fan on its root, X: it floats up in the air and slaps down on landing, cocks when it whistles),
`Legs` (both wires and feet on the hip crank, X: they kick back and reach forward to land),
`Key`.

**Motions:** `Wind` (four half turns of the key, a regrip between each, 1.95 s). `Hop` (11.2 s),
worked out in `bird_hop` from one crank: three little hops (13 mm high and 12 forward fully
wound, each flight the time gravity gives that height, a kick that keeps the feet planted, a
swivel either way, a nose-down rock on landing), then it lifts its head, cocks its tail and
whistles two notes over two turns (the bill opening on each, where the game plays them); lower
and slower as the spring runs down, wandering a little left, about 0.8 studs in all. The tail and
lower bill ring off the body's motion as springs.

## Toy siren car (Common): "Push: it rolls off, wailing"

A chunky tin friction car of the kind Japanese and English makers pressed from the 1950s to the
70s, a chief's car of our own: a red body with a cream roof and pillars, a cream flash down each
side between two silver lines, a gold-ringed white roundel on each door with our "7" in it (no
real force's words or badges), printed chrome round the windows, door handles and shut lines,
and blue printed glass with a driver in a navy peaked cap (a gold badge on it) in the front
window and a passenger behind, both in profile looking ahead, as both museum cars have them. Up
front a slotted tin grille with two headlamps standing proud in its ends; tin bumpers wrapped
round the nose and tail, each with a pair of over-riders; amber and red tail lamps and a made-up
plate at the back. Black rubber tyres with printed whitewalls on bright pressed tin hubcaps. On
the roof a red fluted plastic dome on a pressed tin base. Underneath, a bare tin pan and the
friction motor's steel case on the rear axle. Played with: the print chipped to bright tin on
its edges, a few rust spots in the deepest chips, fine scuffs along the sides. No dust: on the
glossy lacquer any film read as blotches.

**Looked at:** the V&A's tin friction fire chief's car O1172564 (England, maybe 1950s, 11 cm
long, 4 wide, 3 tall; photo `framemark.vam.ac.uk/collections/2010ED1399/full/!800,600/0/default.jpg`)
and highway patrol car O1172567 (11.2 cm; `2010ED1586`): printed crew in pale glass, printed
chrome, silver bumpers, the friction motor underneath; Duckwells' 1960s Ichiko friction patrol
car (9.25 in), whose roof lights turn as it rolls. No video was timed: the run's numbers are a
fast friction car's (spec `SIREN_RUN`).

**Size:** 140 mm nose to tail (154 with the bumpers), 60 wide at the belt, 52 tall to the roof,
71 to the dome's top: 0.61 studs long, 0.28 tall. A speck from a unit's doorway off, as every
find under six inches is; lit, its red pool on the floor reads from the doorway. Held, the red
and cream, the roof light, the roundel and the crew read at once.

**Tells:** the red dome on the roof, the red and cream body, the whitewalls.

**Parts:** `Body` (root: the pressed shell built the die-cast car's way, D-200, plus pan, motor
case, bumpers, grille, headlamps and the dome's tin base; travels with `x`, `y`, `yaw`, `pitch`,
`roll`), `FrontWheels` and `RearWheels` (two tyres, hubcaps and their axle each, turning about
X), `Beacon` (the red dome turning about Z on its post, the glow part, carrying a red Spot light
tilted 8 degrees down that sweeps the walls and floor, and a weak Point light for low graphics).

**Motions:** `Push` (7.1 s), worked out in `sc_push`: two pushes along the floor rev the flywheel
(the lamp catches with a flicker on the first, the dome starts turning), then it leaves the hand
at 5.4 studs a second, the nose lifting as the flywheel bites, wandering a little and rattling
on its axles, slows as the flywheel runs down and coasts to a stop about 10 studs off. The dome
turns geared to the flywheel, slower and slower, and the lamp dies 0.9 s after it stops. The
game wails the siren over it (D-236).

**Sheets:** `art/sheets/sirencar-*.png`; motion preview `out/sirencar-push.mp4`.

**In the place:** uploaded (`assets.json`) and imported in Edit on Nov 16 as
`ReplicatedStorage.Props.Finds.SirenCar` (the beacon's glow mask set, both lights disabled).

## Squeaky rubber duck (Common): "Squeeze: a squeak you can hear down the hall"

The classic yellow vinyl bath duck, our own: one soft hollow moulding in a bright egg-yolk
yellow with a satin sheen and the mould's faint orange peel, warmer low down where the vinyl is
thickest. A big round head sat forward on a broad body, a small round tuft on the crown along
the mould seam, an upturned tail, and on each side a moulded teardrop wing raised off the body,
its edge and three feather grooves toward the tip pressed in. A glossy orange bill, the upper
and lower halves meeting in a smile, the mouth line dark between them. Printed eyes: a white
almond, a big black pupil looking ahead, a shine, a fine dark rim, rubbed thin in specks.
Underneath, the squeak hole with a little rolled lip. The seam runs faint down the middle, over
the crown, the back and under. Played with: the breast and tail tip scuffed matt, the bill worn
back to yellow in specks along its rim, a little dust on top.

**Looked at:** the V&A's 1950s English moulded bath duck O1122250 (12.7 cm, a raised feathered
wing, an upturned tail, an open bill); Wikimedia Commons' "Yellow rubber duck.jpg", "1 Yellow
rubber duck.jpg" (the round tuft, the wide bill, the lemon-yolk yellow), "Rubber Duck
(7250751978).jpg" (the satin vinyl's soft broad highlights) and "NIND dustyrubberduck
ISO200.png" (dust specks on top).

**Size:** 96 mm bill to tail, 87 tall, 72 wide, as the common 3.5 to 4 inch squeakers are: 0.38
studs long, 0.34 tall. A yellow speck from a unit's doorway; held, the round head, the orange
bill and the eyes read at once.

**Tells:** the yellow, the orange bill, the round head on a broad body.

**How it's made:** the duck is one soft surface, rounded volumes melted together (`dk_sdf`:
body, breast, upturned tail, round head, a teardrop wing each side, the tuft, a flat foot),
sampled along rays from one point low in the breast (`DUCK.centre`, from where every bit of it
is in sight) and then evened out over the surface, pulled toward where it bends (`dk_settle`),
so the game mesh's flat faces stay within 0.8 mm of the detailed surface (D-237). The bill is
two moulded lofts.

**Parts:** `Body` alone (root, its pivot on the floor under its middle): the whole duck, bill
and all.

**Motions:** `Squeeze` (1.17 s), worked out in `duck_squeeze`: the fingers close and it rises a
touch (stretch 1.035), squashes to 0.72 keeping its volume (the squeak, which the game plays
here, loud enough to carry down the hall), is held a beat at 0.70 as the last air wheezes out,
then let go it springs back past its size (1.11) and wobbles still (0.955, 1.025, 0.992). Its
nose dips 4 degrees as it's pressed and lifts on the bounce.

**Sheets:** `art/sheets/rubberduck-*.png`; motion preview `out/rubberduck-squeeze.mp4`.

**In the place:** uploaded (`assets.json`) and imported in Edit on Nov 16 as
`ReplicatedStorage.Props.Finds.RubberDuck`.
