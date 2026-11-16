# The finds to build: wave 1, plus the RC car

Which finds get made next, and which are done. The bar and the method are in `CRAFT.md`; read it
first. The rows come from the catalog doc, "Unit finds: the item catalog"
(https://claude.ai/artifact/29wkaNXM3Yw86xTMb3sjQQ, read with the docs tools, never WebFetch;
don't read it whole, it is 250,000 characters): its wave 1 is 133 finds, built here in the
order below. Each session works from the Next line and moves it on.

**Next:** F-04g, the farm-animal spinner (step 5), alone; the newest note has its hints. The
oil lamp's sheets still want `ACTIONS= scripts/art.sh set lights renders OilLamp` when next
touched.

## The second run's plan (owner's yes, Nov 15)

The rest of the Wind-ups (12) and all 14 Squishies, about 15 sessions, to CRAFT.md's bar. A
session takes the next batch from the Next line; if a batch doesn't fit, it stops at a find
boundary and the next session carries on. The finds are batched where they share pieces, which
changes the table's order a little.

1. **F-04c** Chattering teeth (built Nov 15) and, as **F-04c2**, the walking robot (built Nov 16; a
   printed tin robot 6 to 9 inches tall; legs swing from the hip, arms the other way, it clanks
   off straight for 15 s). The newest note has both plans.
2. **F-04d** (both built Nov 16) Wind-up mouse (zips off, slows, stops with a squeak, its tail wagging behind) and
   the clockwork tin bird (Epic: an antique printed-tin bird hopping forward in little jumps, its
   beak opening with each whistle, its tail bobbing; the finest printing in the set). Both are
   small tin walkers on a key: share the key and the walk.
3. **F-04e** (both built Nov 16) Toy siren car (a chunky toy emergency car of our own, no real police markings; the
   die-cast car's way of making a body; its roof light spins and glows red with its own light,
   so it sweeps the hall's walls as it rolls) and the squeaky rubber duck (squeeze: the whole
   duck squashes and springs back).
4. **F-04f** Kazoo (built Nov 16; blow: the paper skin under its cap shivers) and, as
   **F-04f2**, the toy drum (built Nov 16; a kid's tin
   drum with zigzag rope sides, the tell from a doorway, and two sticks; a stick comes down, the
   head shivers, the stick bounces off).
5. **F-04g** Farm-animal spinner alone (pull: the lever comes down and snaps back, the arrow
   spins, slows and ticks to a stop on an animal). The work is the face: eight little animal
   pictures drawn in code that read in the hand. Our own toy, not the famous one.
6. **F-04h** Pull-string cowboy doll alone (cloth body, vinyl head, hat, a ring on a string in
   its back; the string runs out and zips back in while its arms jiggle). The first cloth find.
   Must not read as a famous film's cowboy: other clothes, colours and face. Its six spoken
   lines need recorded audio we own: put that question in `OWNER.md`.
7. **F-04i** Singing fish plaque alone (a rubber fish on a wooden plaque with a plate and a
   button; the tail flaps, the head swings out to face you, the mouth opens in time, then it all
   swings back). Our own fish and plaque, not the famous one's. Its song is the same `OWNER.md`
   question as the doll's lines.
8. **F-04j** Wind-up tin carousel alone (Epic, the most parts: a printed canopy turning on a
   centre pole, three or four horses rising and falling out of step, the tune slowing as it runs
   down, timed from a music-box video).
9. **F-04k** A Studio look at all 14 Wind-ups together in a unit at phone size; fix what reads
   badly. Also the jack-in-the-box's playing-card corners and the oil lamp's sheets. Ticks F-04.
10. **F-05a** Bones in the kit, proven on the squishy butter stick (squeeze: a dent that slowly
    fills back in). CRAFT.md: a find that bends in places needs bones. Check in Studio first that
    a skinned MeshPart from our FBX imports and that moving its Bones bends it on a phone-size
    view; write what you learn in `docs/STUDIO.md`. If bones won't work in Roblox, record why and
    build the dent another way (a pressed piece that sinks and rises). Plush needs the same.
11. **F-05b** Stress ball with a face (its eyes are their own parts, pushed out as it squashes),
    mochi bun, squishy toast slice (springs back like bread). Whole-body squash, the tea light's
    flame's `stretch`.
12. **F-05c** Jumbo slow-rise strawberry (the same squash, ten seconds to rise), squishy capybara
    (a tiny happy sigh), paper squishy with a drawn face (crinkled paper, looks homemade).
13. **F-05d** Gel bead ball, glitter goo ball, galaxy goo ball (Legendary): a see-through skin,
    the firefly jar's glass way, with an inside that swirls and settles.
14. **F-05e** Goo ball (oozes between your fingers), colour-change goo ball (changes colour only
    where pressed: may need a new trick, say so), mega goo ball (Epic, both hands).
15. **F-05f** Squishy cake slice (frosting pushes out the side), then a Studio look at all 14
    Squishies at phone size. Ticks F-05.

## Order

| Ticket | What | Why here |
|---|---|---|
| F-01 | The finds kit (CRAFT.md, "The kit"), proven on the first Lights | Every set after it reuses the kit |
| F-02 | The rest of the Lights, in as many sessions as it takes | The owner's example: a lamp that turns on |
| F-03 | The remote-control car and the die-cast car | The owner named the RC car (Nov 14) |
| F-S1 | Into Studio: upload and insert the Lights and the cars, judge them at phone size in the unit's light, fix what reads badly | Glow and size are only true in Roblox |
| F-04 | Wind-ups and noisemakers | Every one animates |
| F-05 | Squishies | The craze of 2026; squash and stretch |
| F-06 | Plush | Soft forms and fabric; the Huge variant shows here |
| F-07 | Night Shift Minis and their blind box | Our own monsters as collectibles |
| F-08 | Boxes and tins | Lids, flaps and reveals |
| F-09 | Bags and cases | Zips, flaps, straps |
| F-10 | Locked and sealed | Locks that open |
| F-11 | Treasures | The rare end: gold, gems, the Secret key |
| F-12 | The eight big finds | Each is big; about two a session |

A set can take several sessions; split its ticket in ROADMAP (F-02a, F-02b) as you go. Mark a
find built with the date and session (`Nov 15, F-02a`) only when it meets CRAFT.md's bar.

## Notes from the sessions

Newest first. What the next session needs to know: kit changes, traps, what's half done.

- **Nov 16, F-04f2 (the toy drum built, judged and in the place; step 4 done).** `ToyDrum` in
  `windups/build.py`, README section (with the Bang's hit times for the game: 0.22, 0.49, 0.76,
  1.03 and the double at 1.61 s), D-239. Uploaded and imported in Edit
  (`ReplicatedStorage.Props.Finds.ToyDrum`: 4 parts, 3 joints, its pivots and sizes checked).
  **What up close needed** (the half-built note's six, all done, judged on quick sheets twice and
  full sheets once): the head is calfskin now (two-tone mottle, broad darker clouds, fine veins,
  a faint spine streak across it, a grey-brown worn patch pocked with dents); the front rim's
  nicks are a few irregular clusters rusting at their cores, and the hoops' enamel chips in
  patches instead of a dotted line along every roll; two pressed grooves round each hoop band,
  broken round the grommets; the sticks warmer with real grain lines, the beads plainly greyed;
  the maker's mark as big as a star with a gold rim; the shell rubbed low and at the front,
  dragged scratches bright to the tin at their cores, the cream ink faintly yellowed. **Found:**
  the worn patch centred under the beads was hidden by them from every view; its halo now sits
  10 mm toward the middle (D-239). The veins at full strength read as crackle; keep a hide's
  veins faint. A 0.5 mm groove is one texel at 511 texels a stud and vanishes: paint grooves at
  least 1 mm wide. The baked occlusion leaves a faint shadow of each stick on the head when it
  lifts in Bang (the kit's way, as for every moved part). **F-04g's hints (step 5, not
  researched):** the plan's step 5. Look at vintage talking farm-animal spinner toys on museum,
  auction or collector pages (at least four photos, and one video of a pull for the timing): the
  face's size (about 10 to 12 in across), the body's depth, where the lever sits and how far it
  travels, the arrow's hub and the clicking stop. Ours must not look like the famous one: give it
  its own body (say, a squat barn-red housing with a round face set in it, a white trim, a made-up
  maker's mark) and its own picture style. The face: eight animals in a ring (cow, pig, sheep,
  horse, hen, duck, dog, cat), each a flat bold print drawn in code as masks in the look (the
  drum's stars and the kazoo's mark show the way: polar shapes, ellipses, `within`/`bell`), each
  in its own coloured wedge or roundel so it reads in the hand at phone size; judge each animal
  up close and redraw any that reads as a blob. Parts: `Body` (root), `Lever` (turning on its
  pivot at the side), `Arrow` (turning about the face's middle, axis out of the face). Motion
  `Pull`: the lever is pulled down (about 0.25 s), let go and snaps back with an overshoot; the
  arrow spins two or three turns, slows (Quart Out) and ticks over the last few pictures, a small
  back-wobble at each, to stop exactly on one: land its final angle on a multiple of 45 degrees so
  the game can add a multiple of 45 to choose the animal.

- **Nov 16, F-04f2 (the toy drum half built: stopped at the context cap; not ticked, not
  exported, not uploaded).** `ToyDrum` in `windups/build.py` (`drum_*`, `hoop_rz`, `cord_runs`,
  `stick_place`, `drum_look`, `drum_bang`; spec `DRUM`, `BANG`; in `FINDS`). Parts `Body` (root
  on the floor at its middle: the tin shell and bottom, both red rolled-tin hoops, the cord, and
  in the detailed mesh a tin grommet at every hole), `Head` (the calfskin, pivot at its middle,
  axis up, `move`s), `StickL`, `StickR` (each turning about the hand's grip 40 mm from its butt;
  a positive turn lifts the tip, checked on the filmstrip). As found the sticks lie across the
  top, beads on the head just behind its middle, butts out over the front rim toward you.
  **References:** Laurel Leaf Farm's Ohio Art drum (6.25 x 3.75 in: litho shell with picture
  medallions, rolled white hoops, plain sticks with round ends), Theriault's c.1895 child's drum
  (7 in: red hoops, the rope laced in V's through holes in the hoops, paper heads, sticks), the
  V&A's Chad Valley drum B.624:1-1999 (6 x 3 in, pressed steel, litho medallions, cord through
  holes in the top), Red Balloon's tin drum listing (about 7 x 5 in, two wooden sticks). Ours:
  165 mm (6.5 in) across the shell, 175 over the hoops, 115 tall: 0.69 studs. **Kit change:**
  `Shape.lathe(strips=True)` unrolls flat spans as strips too; the hoops' flat rims each took a
  texture square as wide as the hoop (24% packed, 314 texels a stud; now 63%, 511, 1024 square,
  5,376 triangles). **Judged once** (quick sheets, all rendered and committed): it reads as a toy
  drum at once from the front, held and on the filmstrip; from the doorway it's small (cream
  head, crossed sticks, red rims; the zigzag barely shows, as for any find this size). The
  Bang filmstrip shows single lifts and the double lift right. **Left to do, in order:** (1) the
  head is plain: stronger two-tone mottle, a faint spine line, a plainly grey-brown scuffed patch
  with little dents where the beads land (`strike` in `drum_look`); (2) the front rim's nicks
  read as an even dotted line: sparser, irregular, a little rust; (3) the hoop bands are plain: two
  fine pressed grooves round each band, clear of the holes; (4) sticks: stronger grain, warmer,
  the beads plainly greyed; (5) the maker's mark at the back is too small beside the stars (try
  `mark` r 14 x 10, star 5.5, a gold rim); (6) a little more honest wear on the shell (rubbed
  low and at the front, scratches, the cream gone faintly yellow). Then rebake
  (`blender -b --factory-startup -P art/finds/windups/build.py -- --stage textures --find
  ToyDrum`, about 45 s), `quick`, look again (check a hit frame by frame: the kit renders frame
  i at i/24 s into `out/frames/ToyDrum/`, deleted after; hits land at 0.22, 0.49, 0.76, 1.03
  and the double at 1.61 s), full `renders`, export (restore the set's other FBX after; add
  `ToyDrum = { "Bang" }` to `src/shared/Finds/Order.luau`), README section (hit times for the
  game's bangs), upload and import if Studio is in Edit, tick. **F-04g's hints (step 5, not
  researched):** WAVES.md's plan step 5; look at vintage farm-animal spinner toys for size (about
  10 in across), the pull lever's pivot and the arrow's hub; parts `Body`, `Lever` (turning on its
  pivot), `Arrow` (turning about the face's middle); motion `Pull`: the lever comes down and snaps
  back, the arrow spins, slows and ticks to a stop on an animal.

- **Nov 16, F-04f (the kazoo built, judged and in the place; the drum not started).** `Kazoo`
  in `windups/build.py`, README, D-238; uploaded and imported in Edit
  (`ReplicatedStorage.Props.Finds.Kazoo`, its pivots and sizes checked). **What up close
  needed:** it read as a plain grey tube. Now pressed up out of the top: three bold rings down
  the taper (half the top's width, as the museum board's), our maker's mark (an oval rim, a
  fine line, a polished star on a dark stippled field); a knurled grip band round the cap
  above its thread and a bead round the cap's top; tarnish in every crease, polish on every
  crest and down the ridge; the red rubbed through on the crimp's crest and bottom corners.
  **Found:** the red half showed as a hairline from above at any seam height, because the shell
  is widest at the seam and the half below tucks under; it now folds 1.5 mm up over the bead
  (`KAZOO.fold`), as a crimped kazoo's does, and reads as a stripe. The Blow camera stands in
  close on the cap (`distance` 0.38): the lift, the tip toward the lips and the skin's shimmer
  through the hole read; the dark filmstrip stage turns bare tin near black, as for every metal
  find. **Traps (STUDIO.md):** paint heights are in `bump_dist` units, not studs; Blender died
  once loading Metal shaders (no `BAKED` line, old textures kept): grep the log, run again.
  The kit writes a set's keys compactly; `scripts/check.sh`'s formatter expands them, so the
  Windups Luau shows thousands of lines changed until it's run. **The drum's hints (F-04f2):**
  a child's tin drum about 6 to 8 in across and 4 to 5 tall (look for vintage lithographed tin
  toy drums on museum or auction pages: printed tin shell, two painted hoops, a white cord
  laced in a zigzag between them through little hooks, the tell from a doorway; a skin or
  printed-paper head, a strap or cord loop; two turned wooden sticks with round heads). Parts:
  `Body` (root: the shell and hoops and cord), `Head` (the top skin, its own part so it can
  `stretch` a hair), `StickL`, `StickR` (each turning about the hand's pivot near its butt end,
  lying across the top when found). Motion `Drum`: a stick lifts (wind-up), snaps down, the
  head dips and shivers, the stick bounces up off it and settles; then the other, about
  four beats a second like a kid banging it. The zigzag cord: `tube` along a polyline
  between the hoops, low rounds; keep it under 1,500 triangles. Paint heights in `bump_dist`
  units (the kazoo's `kz_h`).

- **Nov 16, F-04f (the kazoo half built: stopped at the context cap; not ticked; drum not
  started).** `Kazoo` in `windups/build.py` (`kz_*`, `kazoo_look`, `kazoo_blow`; spec `KAZOO`,
  `BLOW`; in `FINDS`), parts `Body` (root: the shell, both ends' insides, the collar, the cap)
  and `Skin` (the wax-paper disc under the cap, its pivot at its base on the collar's rim, its
  axis square to the top). **References:** Wikimedia Commons' "Kazoo manufacturing steps.JPG"
  (the Kazoo Museum's board of the 18 pressings: tin top with a name and three pressed rings,
  red-printed bottom half crimped over its edges, ends turned under, threaded collar, dished
  cap with a punched hole over a card ring and skin; open the original, 3470 px, and scroll),
  "2023 Kazoo (1).jpg" (submarine taper, ridge down the top, brushed metal), the Grover Center's
  1970s toy kazoo (hub.catalogit.app, 1985.006.140: painted, two halves crimped, three
  indentations). Listings: 4.75 in (121 mm). Measured off the board: nearly full width (23 mm)
  from the mouth to the cap, then a straight taper to a 10 mm tail; cap about 26 mm across, its
  middle 39 mm back from the mouth. **Judged once** (quick sheets): it reads as a kazoo at
  once. Fixed and rebaked (3,740 triangles, 1024 at 1,953 texels a stud), **not yet looked
  at:** the collar stood out of the body's rounded sides under the cap (now r 9.4, the cap's
  foot turned in under to it), the red half showed only as a thin line (seam 0.40 to 0.46),
  tarnish blotches softened, and **the pressed rings and star mark were missing from the normal
  map.** **Trap (kit, worth STUDIO.md):** `Coat.paint(height=)` is in units of the surface's
  `bump_dist` (Blender's Bump node multiplies Height by Distance), not studs: `mm(0.3)` with
  `bump_dist` 0.0006 is nothing. The kazoo now uses `kz_h(mm) = mm / 0.15` with `bump_dist`
  `mm(0.15)`, bump 1.0. The duck's seam and wing grooves (`mm(...)` heights) are flat for the
  same reason: F-04k should fix them. **Left to do:** look at `kazoo-front/back/held/unit`
  (the committed sheets are this second bake's quick ones) beside the references; check the
  rings and star read and the skin through the hole isn't too dark; fix and render again;
  `scripts/art.sh set windups renders Kazoo` (the Blow filmstrip has never been rendered:
  check the skin's shimmer reads and the mouth end tips up toward the lips, pitch negative);
  export (restore the set's other FBX after; add `Kazoo = { "Blow" }` to
  `src/shared/Finds/Order.luau`), README section, upload and import if Studio is in Edit,
  tick. Then the drum (F-04e2 note's plan).

- **Nov 16, F-04e2 (the squeaky rubber duck built, judged and in the place; step 3 done).**
  `RubberDuck` in `windups/build.py`, README, D-237. Uploaded and imported in Edit
  (`ReplicatedStorage.Props.Finds.RubberDuck`). **The holes fixed:** the game mesh's flat faces
  cut 5 mm inside the tail's tip (not the wings), past the bake's 2 mm cage; `dk_settle` now
  pulls each point harder toward a neighbour whose edge sinks inside the surface, so points
  gather where it bends: under 0.7 mm everywhere, no folds. The game mesh is 44 rings of 72
  (6,762 triangles with the bill). **Judged beside the references and fixed, rendered three
  times:** the mould seam's raised line read as a fold down the tail (now a third as tall); the
  wing read as a round disc stuck on from behind (now a teardrop narrowing toward its tip,
  eased in so its outline has no corner, its painted edge following); the tuft was a sharp
  spike (now round-topped); the yellow was mustard (now a brighter egg yolk, less darkening low
  down, less grime); the bill was a flat pillow with a dark smudge under its tip, the bake
  catching the lower bill's dark top across a 0.5 mm mouth gap (now rounder, the gap 1 mm).
  **Left for F-04k's Studio look:** close up from behind, a faint crease at the very tip of the
  tail along the back seam (the loft's halves part there); held and from the front it doesn't
  show. **Trap:** `scripts/art.sh set windups <stage> RubberDuck` printed only its header and
  did nothing three times; running the Blender line directly worked every time (STUDIO.md).
  **F-04f's plan (step 4), not researched.** *The kazoo* (Common, "Blow: a buzzy note"): a tin
  or plastic tube about 4 to 5 in (100 to 125 mm) long, the mouth end narrowing, a round turret
  on top with a cap pressed over the paper (or wax-paper) skin; tin ones are printed with bands.
  One root `Body`, the `Cap` its own part maybe, the `Skin` a thin disc under the cap; motion
  `Blow`: the skin shivers fast (a `scale` or `move` track, a few frames a cycle) for about a
  second, the whole kazoo tipping up a touch as it's put to the lips. Look at two or three
  museum or listing photos for size and the cap's holes. *The toy drum* (a kid's tin drum with
  zigzag rope sides, the tell from a doorway, two wooden sticks with round heads): about 6 to 8
  in across, printed tin shell, rope laced in a zigzag between two hoops, a skin top; parts
  `Body` (root), `StickL`, `StickR` (each turning about its hand's pivot). Motion `Drum`: a
  stick comes down (a wind-up lift first), the head shivers (a small `stretch` or `scale` on a
  `Head` part), the stick bounces off; then the other. The rope zigzag wants a `helix`-like
  path or `tube` between the hoops; check its triangle count.

- **Nov 16, F-04e2 (the squeaky rubber duck half built: stopped at the context cap; not ticked).**
  `RubberDuck` in `windups/build.py` (spec `DUCK`, `SQUEEZE`; `Finds/Order` has it), one part
  `Body`. **How it's made (new):** the duck is one soft surface, rounded volumes melted together
  (`dk_sdf`: body, breast, upturned tail, round head, a wing each side, a crest on the crown,
  a flat foot), sampled along rays from one point low in the breast (`DK["centre"]`, the only
  spot found from which every bit is in sight: higher up, the back hides the tail's top and the
  chin hides itself, which folds the surface), then evened out over the surface (`dk_settle`).
  The loft's two halves part along the mould seam front and back. The bill is two moulded
  lofts (upper and lower, a smile). Eyes, the wing's moulded edge and feathers, the seam ridge
  and the squeak hole are in the look. Motion `Squeeze`: `stretch` 1.035 (grip), 0.72 (the
  squeak), held 0.70, springs back 1.11, wobbles 0.955, 1.025, settles; the nose dips 4 degrees
  as it's pressed. **References:** the V&A's O1122250 (a 1950s English moulded bath duck,
  12.7 cm, raised feathered wing, upturned tail, open bill) and Wikimedia Commons'
  "Yellow rubber duck.jpg", "1 Yellow rubber duck.jpg", "Rubber Duck (7250751978).jpg" and
  "NIND dustyrubberduck ISO200.png" (dust specks on top, satin vinyl). Size: about 98 mm bill
  to tail, 87 tall, 73 wide (common 3.5 to 4 in squeakers). README not written yet.
  **Judged once** (quick sheets, looked at): it reads at once as a classic rubber duck; the
  squeeze filmstrip reads (squash, tall overshoot, wobble). Flagged: the crest was a sharp spike,
  the bill a thin flat tongue, pale speckle on the breast and bill tip like a rash, orange specks
  in the pupils, and **the back sheet shows black holes and a crater on both wings**: the game
  mesh (40 x 64 rays) cuts the wing's back-top and the tail's top up to 4.2 mm inside the
  detailed surface, past the bake's reach (`CAGE` 2 mm out, `REACH` 5 mm), so the bake misses.
  **Fixed in code but not rebaked or rendered:** a soft crest (blend 4.5), a wing that swells
  from the side (blend 6), a thicker bill with more smile and the lower bill showing, a brighter
  yellow, wear on the bill only at its rim, softer breast scuffs, fewer eye specks. **Still to
  fix:** the 4.2 mm gap (the ducktest in this note's recipe: sample face middles of the low grid
  with `dk_sdf`, keep every one under about 1 mm). Try weighting `dk_settle`'s pull by the gap
  (more points where the surface bends), or more rays only at the back (rings sampled densely
  near the horizon), before raising the whole grid (48 x 80 is 7.7k triangles, too many for a
  small find). Then `scripts/art.sh set windups textures RubberDuck`, `... export RubberDuck`
  (restore the set's other FBX after), `quick`, look at front, back, held and unit beside the
  references, fix, full `renders RubberDuck`, README, upload and import if Studio is in Edit.
  The FBX, textures and sheets committed now are the first bake's, holes and all.

- **Nov 16, F-04e (the toy siren car built, judged and in the place; the duck not started).**
  `SirenCar` in `windups/build.py`, README, D-236. Uploaded and imported in Edit
  (`ReplicatedStorage.Props.Finds.SirenCar`). **Judged beside the V&A's two tin cars and fixed,
  rendered twice:** the bonnet and boot wore a pale speckled film under the top light (a fine
  roughness noise breaking the lacquer's sheen; now a broad gentle wander, 0.19 to 0.24); the
  windscreen's thin glints read as cracks (now one broad soft sheen and a faint narrow one); the
  hubcaps mirrored the dark room and read black (now 0.75 metal, 0.38 rough, paler); and both
  museum cars print a crew in their windows, so ours has a driver in a navy peaked cap with a
  gold badge and a passenger behind, in profile, on lighter blue glass. The push filmstrip's red
  pools sweep the floor; lit, the dome burns red without washing pink. **Trap:** exporting one
  find (`... export SirenCar`) still writes the whole set's Luau, unformatted: its diff looks
  like 8,593 lines lost until `stylua` (or `check.sh`) reflows it, then it matches HEAD. The
  quick render that "rendered nothing" last session was not seen again: `renders SirenCar`
  worked both times. **F-04e2's plan (the duck):** the second F-04d2 note below has it (about
  90 to 100 mm long, 85 tall, one part or a body plus the bill, `Squeeze` with `stretch` about
  0.72, held a beat, then a Back Out spring past 1). Look first at two or three photos of a
  classic yellow bath duck with a known size (a museum record or a listing), its squeak hole
  under the tail, the satin vinyl's sheen and the moulding seam; its eyes are printed, not
  parts. Then step 4: the kazoo (a tin or plastic tube about 4 to 5 in, a turret cap over the
  paper skin) and the toy drum (zigzag rope sides, the tell from a doorway, and two sticks).

- **Nov 16, F-04e (the toy siren car half built: stopped at the context cap; not ticked).**
  `SirenCar` in `windups/build.py` (spec `SIREN` and `SIREN_RUN`; `Finds/Order` has it), four
  parts: `Body` (root: the die-cast car's sections, D-200, at 140 mm; tin pan, the friction
  motor's case, swept tin bumpers with over-riders, grille, headlamps, the roof light's tin base),
  `FrontWheels` and `RearWheels` (two tyres with printed whitewalls on tin hubcaps and their axle
  each, turning about X), `Beacon` (the red fluted dome turning about Z, the glow part, carrying a
  red Spot that sweeps round and a weak Point). Motion `Push`: two pushes rev the flywheel (the
  lamp catches with a flicker, the dome starts turning), it shoots off at 5.4 studs/s, drifts,
  rattles, coasts about 10 studs as the flywheel runs down and stops; the dome slows with it, the
  lamp dies after. Baked 1024 at 766 texels a stud, 8,212 triangles (the wheels' lathes are most
  of it: trim `segs` if Studio says so). Luau exported. Not uploaded or imported. **References:**
  the V&A's O1172564 (a tin friction fire chief's car, 11 cm) and O1172567 (a highway patrol
  car, 11.2 cm), Duckwells' 1960s Ichiko friction patrol car (9.25 in; its roof lights turn as it
  rolls). README not written yet. **Judged once** (first quick sheets, looked at): it reads as a
  red-and-cream 1960s tin chief's car with a roof light, roundel "7" and whitewalls. Fixed in code
  but **not rendered again**: dust 0 (a pale film blotched the glossy bonnet and boot), tail lamps
  as bright lenses (they read as silver brackets), the plate's barcode stripes made glyph cells,
  fewer and broader window glints, rougher bright tin (hubcaps read black), a bigger dome
  (r 8.8, h 15), the dome's lit side hotter than the rest, the beam tilted 8 degrees down with a
  stronger preview so its sweep shows on the filmstrip's floor. **Next session:** rebake, render
  (`scripts/art.sh set windups textures SirenCar`, then `... renders SirenCar`: a second `quick`
  printed only its header and rendered nothing, cause not found), look beside the references,
  fix, render again, then README, D-number, upload and import, tick. **Watch:** the beam's sweep
  in the filmstrip (it barely showed before the tilt); whether the lit dome still washes pink.

- **Nov 16, F-04d2 (the clockwork tin bird built, judged and in the place; step 2 done).**
  `TinBird` in `windups/build.py`, README, D-235. **Judged and fixed:** the head read as a glossy
  red blob held (a flat red skullcap with a hard ink rim, black lines across the face, a grey disc
  for an ear, white speckle everywhere). Now, after the V&A sparrow: the cap sweeps from the bill
  over the crown and down the nape, deeper crimson at its edge with a paler printed sheen and rows
  of small crimson-keyed feathers (`scales`); a dove-grey stripe under it over the eye; a cream
  throat so the orange bill stands out held; small printed feathers down the gold breast; chips
  only on edges and high points; a deeper neck so the head is its own round shape; wire legs
  1.5 mm. **Bug fixed:** `bird_hop` wrote its travel in mm where the kit reads studs (13-stud
  hops in the exported Luau); now converted as the tracks are written. **Kit:** the filmstrip's
  stage light rides with a `follow` find and stands on the camera's side when a motion sets its
  own `view` (the hop's camera was on the dark side); the mouse's `Zip` was rendered again and
  stays lit. **Trap:** a motion worked out in mm must convert `x`, `y`, `z` to studs; a find
  leaving its filmstrip floor (40 studs) shows as dark frames with no floor.
  **F-04e's plan (step 3), not researched.** *The toy siren car* (Common, "Push: it rolls off,
  wailing"): a chunky toy emergency car of our own, no real police markings or words, about 5 to
  6 in (130 to 150 mm) long, tin or hard plastic, push-and-go. Build its body the die-cast car's
  way (`dc_half` in `figures/build.py`: sections computed along the car, arches cut round the
  axles; D-200, F-03b's note). Parts: `Body` (root, travels), front and rear `Wheels` on their
  axles, `Beacon` (the roof light: a red dome turning about Z with its own glow and a red Spot
  light, `glow_part`, sweeping the walls), maybe a flywheel whir. Motion `Push`: the die-cast
  car's roll (`DC_PUSH`, `follow`), the beacon spinning and glowing the whole run, slowing as it
  coasts. Look first at V&A or museum toy police cars and fire chiefs' cars from the 1950s to 70s
  (the API search), and one push-and-go listing for its size. *The squeaky rubber duck*
  (Common, "Squeeze: a squeak you can hear down the hall"): the classic yellow bath duck, about
  3.5 to 4 in (90 to 100 mm) long and 85 tall, an orange bill, painted eyes, a squeak hole
  underneath, soft vinyl with a satin sheen. One part (or a body plus the bill) on a pivot at its
  base; motion `Squeeze`: the whole duck squashed with `stretch` (about 0.72), held a beat, then
  springing back past 1 and settling (the tea light's flame proves the channel; a Back Out key
  gives the spring). Its squeak hole is a little dimple under the tail.

- **Nov 16, F-04d2 (the tin bird half built: stopped at the context cap; not ticked).**
  `TinBird` in `windups/build.py` (spec `BIRD` and `HOP`), six parts: `Body` (root, the pressed
  tin body, pivot under its feet so a pitch rocks it on them), `Bill` (upper, still), `Beak`
  (lower bill on the gape hinge, X), `Tail` (fan plate on its root, X), `Legs` (both wire legs
  and stamped feet on the hip crank, X), `Key`. Baked 1024 at 2,063 texels a stud, 3,590
  triangles; Luau exported (motions `Wind`, `Hop`; `Finds/Order` has them); quick sheets
  `art/sheets/tinbird-*.png` rendered and **not looked at**. Not uploaded or imported.
  **References:** the V&A's API (see the mouse's note): O36973, a tinplate sparrow (2.25 in tall,
  1.5 in wide, a red cap, cream face, printed wing, a loose fan tail, stamped brown feet, key in
  its side; photo `framemark.vam.ac.uk/collections/2006AF4148/full/!800,600/0/default.jpg`),
  O36970 a robin (2006AF4153); a 1960s German hopping bird listed at 85 x 56 x 40 mm. No video
  found with a hop rate (the ECU museum's has no playable source): `HOP` is a toy's numbers,
  3.3 hops a second at first, each hop's flight time the one gravity gives its height.
  **The kit now has up-down travel:** `z` in `kit.TRAVEL` (Roblox `y`), in `Finds/Art.luau`'s
  type, `Finds/Pose.luau`'s `solve` and `Finds.travelling`, with a `findpose` spec. **New
  helpers:** `plate` (a tin plate from a grid of its top, its top, underside and rim each one
  island: the tail and the stamped toes), `bill_rings` (a D-section folded bill, upper and lower),
  the look's `scales` (rows of overlapping printed feathers) and `less`; never give `nb.ss` or a
  `less` edge a socket (Python compares the edges: subtract first). `bird_hop` writes the root
  exactly (a kick that keeps the feet planted, a parabola, a swivel, a landing rock) and rings the
  tail and lower bill as springs off it. **To do, in order:** look at every quick sheet beside the
  sparrow photo (the printing reads at phone size? the wing's edge where it wraps the back, the
  cap's line, the tail coming out of the rump's top, the bill's join, feet flat on the floor);
  fix; `scripts/art.sh set windups textures TinBird`, export, `git checkout` the set's other FBX,
  full renders; upload and import if Studio is in Edit; README section (references above), a
  decision line, tick it.

- **Nov 16, F-04d (the wind-up mouse built; the tin bird not started: the context cap).**
  `WindupMouse` in `windups/build.py`, spec `MOUSE` and `ZIP`, README, D-232. A grey flocked
  clockwork mouse, 84 mm, from the V&A's B.114-1996 and Brent Museum's T944. **Museum photos
  without bot checks:** the V&A's API (`api.vam.ac.uk/v2/objects/search?q=...&images_exist=1`,
  read with `javascript_tool`) gives ids, and `framemark.vam.ac.uk/collections/<image id>/full/
  !800,600/0/default.jpg` shows the big photo; shop listings (kidero, goodio) sat behind
  Cloudflare. **Bake trap:** small pieces sunk into a part (ears, eye domes, within the bake's
  2 mm reach) smear onto it as dark wedges and crescents: make them their own part (the ears,
  which then flick on the stop) or sink them deep with the skirt under the surface (`EYE_PROF`).
  **Helpers worth reusing:** `frame(face, up)` (a turn taking +Z to any facing), `mo_normal`
  (which way a body's side faces, for seating eyes), `mo_key` (the robot's key along any axis by
  a matrix), `mouse_zip`'s pitch keys (a peak reached Out, a landing In: exact for |sin| hops and
  for parabolas) and its spring-flex for a stiff tail. **Not done:** no video timing (the run's
  numbers are a toy's speed, spec `ZIP`); the plate has no maker's mark moulded in; the `Zip`
  filmstrip follows it out of the preview's light, so its last frames are dark (the run itself
  reads: it travels, curls left, settles, the tail in a new pose each frame). Uploaded and
  imported (`ReplicatedStorage.Props.Finds.WindupMouse`, five parts, joints checked).
  **F-04d2's plan, the clockwork tin bird, not researched** (Epic, "Wind: it hops and
  whistles"): an antique printed tin bird about 4 to 5 in long (100 to 125 mm) on two wire legs,
  the finest printing in the set (feathers in two or three colours, an eye ring, a printed wing
  over a pressed one). Look first with the V&A's API ("tin bird", "clockwork bird") and one
  video for the hop rate. Parts: `Body` (root, hopping), `Beak` (the lower bill opens with each
  whistle), `Tail` (bobs on each landing, the mouse's spring-flex), `Key` (`mo_key`), maybe the
  legs folding on each hop. **First** add a `z` travel channel to `kit.TRAVEL` and
  `TO_ROBLOX_CH` (Blender Z is Roblox Y), to `Finds/Art.luau`'s pose and `Finds/Pose.luau`'s
  `solve`, with a Lune spec: the hops need it. Key each hop as a parabola (Quad Out up, Quad In
  down), the mouse's way.

- **Nov 16, F-04c2 (the walking robot built, uploaded and in the place).** `WalkingRobot` in `windups/build.py`,
  spec `ROBOT` and `WALK`, README, D-230. Step 1 of the plan is done. **A walk worked out, not
  keyed:** `robot_walk` drives every part off one crank phase, pins the planted foot's sole to the
  floor and moves the body only by that foot's push (exact, yaw and lean included), so nothing
  slides; feet are their own parts that counter-turn flat and `move` along the leg to keep the
  sole down (a pendulum's foot rises at the ends of its swing: 1.5 mm here). The aerial is a
  damped spring simulated from the body's accelerations; keys sit at each curve's turning points
  (`extremes`) and at half or quarter steps of the crank (`turning`): 1,900 keys for 16 s. **The
  kit has no up-down travel** for a whole find (`x`, `y`, `yaw`, `pitch`, `roll` only): the tin
  bird's hops need one. Add a `z` channel to `kit.TRAVEL` (Blender Z is Roblox Y) and to
  `Finds/Art.luau`'s pose, with a Lune spec, before keying hops. **Helpers worth reusing:**
  `rrect` and `boxloft` (rounded boxes from (z, half width, half depth, radius) rows: tin bodies,
  heads, feet), `stud` with `FACING` (a lathed button, rivet, bezel or cone facing any of the six
  ways), the look's `rivets` (printed pressed rivets with an ink ring and a highlight) and `band`.
  Arms first drawn 9 mm thick read as sticks in the held view; 11 mm with bigger claws read.
  **Not done:** the `Walk` filmstrip's camera stands far back (distance 1.15) in the dark: 0.8
  would show the stride better; the module grew 60 KB (1,900 keys), trim the feet's quarter steps
  if the set gets heavy.
  **F-04d's plan, not researched.** *Wind-up mouse* (Uncommon, "Wind: it zips off and squeaks
  wherever it stops"): look at listings of tin or felt-covered clockwork mice (about 3 to 4 in
  long, 75 to 100 mm; a grey felt or printed tin body, round ears, bead eyes, whiskers, a long
  tail of cord or coiled wire, the key in its side, two drive wheels and a guide wheel hidden
  under it) and one video for how fast it runs down. Parts: `Body` (root: `x`, `y`, `yaw`; it
  zips off, veers a little, slows, stops dead with a nose-down rock), `Tail` (wags behind, a
  turn about Z from its root, with follow-through), `Key`, maybe `WheelL`/`WheelR` if they show.
  *Clockwork tin bird* (Epic, "Wind: it hops and whistles"): an antique printed tin bird about 4
  to 5 in long on two wire legs, the finest printing in the set (feathers in two or three
  colours, an eye ring); parts `Body` (root, hopping: needs the `z` channel above), `Beak` (the
  lower bill opens with each whistle), `Tail` (bobs on each landing), `Key`. Share the key (the
  robot's `rb_key` wings) and the hop's rhythm between them only where they truly match.

- **Nov 15, F-04c (the chattering teeth built, uploaded, not imported: Studio was in Play; the
  robot not started).** `ChatteringTeeth` in
  `windups/build.py`, spec `TEETH` and `CHATTER`, README, D-227. Step 1 of the plan is half
  done: research ate the context (two videos' sound, one muddied by music; a frame-difference
  try on video was swamped by the hand-held camera: use sound, in a quiet stretch, and count
  click pairs), so the cap stopped it after one find. **Light motion data:** a long walk
  sampled and thinned with `rdp` at a fine tolerance wrote 160 KB of keys; `teeth_chatter`'s
  `turning` puts a key only where each curve turns (a sine's extremes, its zeros) eased Sine
  InOut, which is exact for a sine and a third the size. Use it for any walker. **A walk that
  doesn't slide:** the body moves forward only by the planted foot's backward swing (speed =
  stride x crank rate x |sin|), and the planted foot's `move` lifts it by what the body's roll
  would sink it. **Drawn open:** the top jaw is drawn 9 degrees open and found that way, so the
  template in the place needs no rest pose. 10.7k triangles (gums swept every 1.6 mm, teeth 10
  round): heavy for a Common, fine for one held find; trim the gum's rings if a floor deals many.
  **F-04c2's plan, the walking robot, not researched** (Uncommon, "Wind: it clanks off in a
  straight line for 15 seconds"). Look first: the Science Museum Group's "Atom Robot" (Yoshiya,
  1950s, collection.sciencemuseumgroup.org.uk/objects/co8538872) for build and size,
  theoldrobots.com (a 5.5 in walking astronaut; an 8.5 in Space Man) and a modern tin
  reproduction's video for the clank rate, timed from its sound. A printed tin litho robot of our
  own, 6 to 7 in (150 to 180 mm) tall: a boxy torso with a printed chest panel (dials, a gauge,
  rivets), a square head with a visor and an aerial, arms on shoulder pins, legs on hip pins and
  flat feet, a key in its side or back. Parts: `Body` (root: travel `x`, `y`, `yaw`, a waddle
  `roll`), `LegL`/`LegR` (swing about the hip, opposite), `ArmL`/`ArmR` (swing opposite the
  legs), `Aerial` (follows through on each step), `Key`. Motions: `Wind`, `Walk` (15 s of
  clanking steps in a straight line, slowing at the end). Reuse the jack's `rsq`, `strip`,
  `rivet` for tin, its look for printing, and the teeth's `turning` keys.

- **Nov 15, F-04b (the jack-in-the-box built and in the place).** `JackInTheBox` in
  `windups/build.py`, spec `JACK` and `TUNE`, README, D-202. Timed from a video's sound as the
  monkey was (a 1953 tin one: 7.8 s of tune, 0.9 s of nothing, the bang, three lid bounces).
  **Drawn popped, found shut:** the lid is drawn open on its stop and the jack popped up, so the
  bake lights them; their rest values (the first key of the first motion that moves them) shut
  the lid and press the jack in with `scale` and `stretch` together (scale 0.785 times stretch
  0.56 is 44 per cent of the height at about the same width; `stretch` alone would make it 34
  per cent wider and poke through the box). A child rides its parent's `stretch`, so the head
  squashes a little as the jack bobs: keep the visible bob between 0.93 and 1.11. A look on a
  part drawn turned (the lid) works out where a face lies at rest by turning `L.x/y/z` back
  through the hinge in nodes (`jack_look`, "the lid"). **Kit helpers in `build.py`** worth
  reusing: `rsq` (a rounded square ring, for tins and boxes), `strip` (a bent tin strip along a
  path: catches, hinge straps), `rounded` (fillets a polyline's corners: wires, cranks), `rivet`.
  **The template in the place stands as drawn** (lid open, jack up): neither `Finds/Kit.luau`'s
  import nor `Art.luau` applies rest values, so the game ticket that deals it must pose every
  part at the first key of the first motion that moves it before it's seen (the tea light's
  flame needs the same). At 1024 the find gets 379 texels a stud (asked 500): the box's inside eats texels. **Not done:**
  playing-card corner indices (a small J and pip in each panel's corners) would make the card
  joke land up close; the sack's diamonds could be finer.
  **F-04c's plan, not researched.** The chattering teeth (Common, "Wind: they chatter off across
  the floor"): white plastic teeth in pink gums on two orange feet, a side key; parts `Base`
  (the lower jaw on its feet, root, travelling with `x`, `y`, `yaw` as the die-cast car does),
  `Jaw` (the upper jaw, hinged at the back, snapping about 6 to 8 times a second), `Key`, the
  feet stepping as a walk from a spring. The walking robot (Uncommon, "it clanks off in a
  straight line for 15 seconds"): a tin litho robot about 6 to 9 inches, legs swinging from
  the hip, arms swinging opposite, a side key; time both from video sound as above.

- **Nov 15, F-04a (the Wind-ups set started; the cymbal monkey built and in the place).**
  `art/finds/windups/` (`scripts/art.sh set windups`), spec `MONKEY` and `PLAY`, README, D-201.
  **Timing from video's sound:** YouTube plays in the built-in browser; in the page, an
  `AudioContext` with `createMediaElementSource(video)` into an `AnalyserNode`, sampled every
  6 ms while it plays at 1x, gives the loudness over time, and peaks with a minimum gap are the
  hits (clashes here; the jack's tune and its pop next). Wait out the ad (`.ad-showing`) first;
  autoplay moves on to another video when it ends. Commons had no video of either toy.
  **Arms built at the hit:** draw the arms where the cymbals meet square, then swing them open
  by the found angle (`arm_open`), so the bake never darkens faces pressed together and a turn of
  minus that angle is the hit, exactly square. **Traps:** a lathe's or loft's shape scaled by `M`
  would unwrap at the wrong size, so ellipsoids are lofts of real points (`blob`); a part that
  pokes into another shows through it (the ears first sat inside the head's fur: a dark disc in
  each cup); fur needs strand noise near 240 a stud stretched to 0.07 along Z, finer reads as
  speckle. A 21 s motion at 24 frames a second writes a 57 KB set module and its filmstrip
  renders 510 frames (several minutes).
  **F-04b's plan, the jack-in-the-box, not researched** (Uncommon: wind, a tune, then a bang a
  few seconds after you let go). Look first: Wikimedia Commons "Jack-in-the-box" photos, a museum
  record for size (tin-litho cube about 5 to 6 in, a side crank on a square shaft, a lid on a
  rear hinge held by a spring catch at the front, a cloth-bodied clown-ish jack on a coil spring
  with a vinyl or composition head; ours, no famous company's), and a video timed by its sound
  as above (the tune's notes a second as the crank turns, how many turns before the pop, the
  pop's bang). Parts: `Box` (root), `Crank` (turns on its side axle), `Latch` (the front catch,
  flips as it releases), `Lid` (rear hinge, flies open past upright and bounces back on its stop),
  `Jack` (`move` up its spring and `stretch`, overshoot and a wobbling settle), `Head` (wobbles
  on its neck after the jack). Motions: `Wind` (the crank turns with the tune, a beat of nothing
  at the end), `Pop` (the latch flips, the lid bangs open, the jack springs out). `texels=` for
  its tin litho print (500 or more).

- **Nov 15, F-03b (the die-cast car built and in the place; F-03 done).** `dc_*` in
  `figures/build.py`, spec `DC` and `DC_PUSH`, README, D-200. **How the body's made:** one loft
  of sections computed along the car (`dc_half`), not stations blended: each section's foot rises
  round the axles to cut the arches (two rings 0.02 apart make the arch's straight sides), the
  greenhouse is a trapezoid whose height follows `dc_cabin(y)`, so the windscreen and back window
  come out of the same rings, and nose and tail turn under in rings drawn in about the section's
  middle, closing on a point. Windows, shut lines and lamps are look masks in the find's frame
  and normal (`L.nx`, `L.ny`). **Traps:** `enamel_wear` and `finish` are sized for finds a stud
  big (edge 0.008, noise 14 to 110 a stud): on a 0.3-stud find write the chips yourself at
  `L.edge(mm(0.8))` and noise 240 to 420; any dust on glossy metallic paint reads as blotches
  (dust 0 here). The studio's reflections still mottle glossy metal a little in the sheets; the
  maps are clean. A find's root can carry the travel channels (`Body` x, y, yaw): the game moves
  the model. Export rewrote the RC car's FBX; it was restored before upload.
  **F-04's plan, not researched** (this session wrapped at 230k context). A new set
  `art/finds/windups/` (`scripts/art.sh set windups`; add it to art.sh's usage comment).
  *Cymbal monkey* (Rare: wind its key, it bashes its cymbals, loud, for 20 s): look first at
  Wikimedia Commons ("Category:Cymbal-banging monkeys"), museum records (V&A, Strong Museum)
  and auction listings for size (about 10 to 12 in tall, a 1950s-60s Japanese clockwork toy: a
  plush monkey on a tin-and-plastic body, striped trousers, a fez or cap, brass cymbals) and a
  video for the beat (count clashes a second, and how it slows). Our own monkey, no famous
  company's character. Parts: `Body` (root), `Head` (nods on a neck pivot), `ArmL`/`ArmR`
  (turning on shoulder pivots so the cymbals meet square in front), `CymbalL`/`CymbalR` on the
  hands if they wobble, `Key` (turns backwards as it unwinds), eyes or jaw if the reference
  shows them moving. Motions: `Wind` (the key turned forward in clicks), `Play` (20 s of clashes
  whose rhythm slows as the spring runs down; head bob in time; the key turning back).
  *Jack-in-the-box* (Uncommon: a tune, then a bang a few seconds after you let go): a tin litho
  cube about 5 to 6 in with a side crank, a latched lid and a clown-like jack on a coil spring
  (ours, not a famous one). Parts: `Box` (root), `Crank` (side axle), `Lid` (hinge at the back),
  `Jack` (`move` up and `stretch` on its spring), `Head` if it wobbles separately. Motions:
  `Wind` (the crank turns with the tune), `Pop` (a pause, the lid bangs open, the jack springs
  out with overshoot and a wobbling settle). Both get `texels=` for their size.

- **Nov 15, F-02n (the Secret lamp built; the Lights done).** `ul_*` in `lights/build.py`,
  spec `UNPLUGGED`, README, D-199: an ordinary 1940s brass table lamp found lit, its cord to a
  plug lying loose on the floor (`UnpluggedLamp`). **Kit change:** a motion may say where the
  filmstrip camera stands, `view` (a direction) and `drop` (how far under the focus it aims):
  the default always looks down from above, which can't see under a lampshade. **Found lit by
  data:** its `Switch` glow track holds 1 from its first key, so its rest is lit (the kit's
  rule), every sheet shows it on and the game's rest pose is lit; no kit flag needed. **Traps:**
  a lathe's `kinds` needs one per span (points minus one) across joined profiles; a shell's
  laced rim (`ul_lacing`) keeps the cord within 0.0054 of the game mesh by riding the wall and
  the rolled bead, not floating off it. Pale cord and an ivory plug read on the dark floor where
  brown vanished; from the doorway the plug is a speck (the lit lamp is the tell there).
  **In Studio** (uploaded, `import("Lights", {"UnpluggedLamp"})`): seen lit in a dark room from
  its doorway, the only light, glowing amber with its pool and ceiling ring (README). Its new
  glow mask drew black for a minute after upload, then glowed (STUDIO.md).
  **The die-cast car, not started** (this session wrapped at 255k context, after the lamp's
  research and sheets). Plan: a small metal toy car about 3 in long (0.3 studs), our own
  late-1960s style: a die-cast zinc body in bright metallic paint, a tinted window insert, a
  black plastic or chrome base riveted on, thin axles with four wheels (no real maker's badge or
  real car's design). Look at three real die-cast toys first (Wikimedia Commons "Die-cast toys"
  and collector listings for size). Parts `Body` (root on the floor between the axles),
  `WheelFL`, `WheelFR`, `WheelRL`, `WheelRR` (each turning on its axle). Its `Push` motion
  from `drive()` in `figures/build.py` (the RC car's simulation reduced to keys): a shove, a
  roll that slows over two or three studs, a little wobble. Big enough at 0.3 studs only up
  close: give it `texels=` for its small size.

- **Nov 15, F-02m (the stained-glass lamp built and in Studio).** `sg_*` in `lights/build.py`,
  spec `STAINED_GLASS`, README, D-198. A leaded cone shade on a cast bronze base with two
  brass pull-chain sockets, 22 in tall with a 14 in shade (from a 15.5 in, 24 in Chairish
  listing and its close-up of the vented cap). Our own pattern: gold diamonds on cobalt round
  the apron, twelve ruby four-petal blossoms with gold hearts, leaves and amber cabochons on
  green, four rows of honey bricks. **How the pattern is made:** the game mesh is a plain
  shell; the detailed mesh is every glass piece (`sg_pieces`, polygons in angle and height),
  both faces, with a half-round lead bead over every join (`sg_leads` dedupes shared sides),
  so the bake draws the pattern and the leading's relief exactly. Kinds pick each piece's
  colour (`SG_GLASS_COL`). Anything that stands proud of the game mesh more than the bake's
  reach (0.008 out) bakes wrong: the cabochons rise 0.006. A lathe whose profile runs top to
  bottom faces inward and bakes dark: run profiles bottom to top. Fragile: one cobalt piece in
  the apron, front left, has a hairline crack (a pale line that burns bright lit); a drop's chip
  would show on the apron's bottom rim. Parts `Base` (root), `Shade` (glow), `ChainA` (pulled:
  `stretch` and `turn`), `ChainB` (sways); motions `SwitchOn`, `SwitchOff`. Lights: a warm
  Spot down out of the shade (0.6, range 10, 110 degrees), a weak Point, and three coloured
  Spots out through the band (ruby front, green and cobalt behind; 0.5, range 9, 70 degrees).
  2048 at 501 texels a stud, 10,148 triangles. **Seen in Studio** (a lit M unit from the
  doorway, off and on): the pattern reads off; on, the shade glows in its colours and the
  coloured Spots **do draw in Edit** at these wide angles: red on the back wall, green on the
  left, blue on the right (the narrow ones earlier didn't). The warm down Spot lights the whole
  unit a little brighter than its bulb: fine at home, where it lives; trim it if a floor ever
  holds it lit. **The Secret lamp, not started** (this session wrapped at about 235k).
  Default look (the catalog says nothing): an ordinary 1940s table lamp, a turned brass column
  on a round stepped base with a pleated or plain yellowed parchment bell shade, harp and
  finial, a brass turn-key socket; plainly lit with no power, its cord running off the base
  to a two-prong plug lying loose on the floor, so a player sees at once it shouldn't be on;
  its light a touch too steady and warm. Sizes: 1940s brass lamps run about 25 in to the
  shade's top with a 6.5 in base (Chairish listings, the search "vintage brass table lamp
  1940s"): look at two or three photos first. Parts: `Base` (root, with cord and plug),
  `Shade` (glow), `Key` (turns). One motion: `Switch`, the key clicks round a quarter turn and
  nothing happens: the light stays on (no flicker anywhere). Add one line to `OWNER.md` asking
  the owner to judge this look (the rarest light in the game).

- **Nov 15, F-02l (the theatre spotlight built; the hat, the jar and the spotlight in Studio).**
  The hard hat and the jar were uploaded and imported (`import("Lights", {"HardHat",
  "FireflyJar"})`); the spotlight too (`{"Spotlight"}`): templates in
  `ReplicatedStorage.Props.Finds` (the owner saves). **Seen in Studio, a lit M unit from the
  doorway, off and on:** the hat reads at a glance (yellow shell, lamp, battery) and its lamp
  throws a pool on the floor; the jar reads up close (glass, grass, fireflies glowing). Its three
  firefly lights all at full together paint the near wall brighter than the bulb, but in play
  each flashes 0.76 s in 5 at its own time, so one at a time: left at 0.4, range 7; the game
  ticket should glance at it in Play. The spotlight reads off (red can, barn doors, stand) and
  on (the lens a bright disc behind its guard); its Spot beam drew nothing in Edit, as the disco
  ball's didn't, so the beam is unjudged in Roblox. **Edit doesn't apply a Motor6D's
  `Transform`** (it only moves parts while the game runs): pose a template in Edit by its C0.
  **The spotlight** (`sp_*` in `lights/build.py`, spec `SPOTLIGHT`, README, D-197) is a 1960s
  studio Fresnel with barn doors on a rolling stand, from the references (Colortran photo on
  Commons, a studio 1K rental listing); parts `Stand`, `Yoke` (pan), `Knob` (the tilt lock),
  `Can` (tilt), `Lens` (glow), `Switch`, four hinged `Door*` leaves; motions `SwitchOn`,
  `SwitchOff`, `Aim`. 2048 at 256 texels a stud. **Kit change:** the lineup camera backs off for
  a find taller than 4.2 studs (`kit.py`; shorter finds frame as before). **Not done:** the
  stained-glass lamp is not researched (this session wrapped at about 270k). Look first at
  photos of real leaded-glass table lamps (a domed shade of small glass pieces in lead came,
  a bronze base), get sizes from a listing, and use no real maker's names or designs. Plan:
  the shade as clear-ish coloured glass pieces (the kit's `clear=True` and alpha) with dark
  lead lines, the bulb inside as the glow part, a few coloured Point or Spot lights round it
  for the "coloured patterns on your walls" (check in Studio which reads; Edit draws no Spot
  beams). Fragile.

- **Nov 15, F-02j and F-02k (the miner's hard hat and the jar of fireflies built).** Both in
  `lights/build.py` (`hh_*`, spec `HARD_HAT`, `HAT_*`, `CAP_LAMP`; `fj_*`/`ff_*`, spec
  `FIREFLY_JAR`, `FIREFLY`) with README entries; D-196. **Not in Studio yet:** the session hit the
  context cap before uploading; the FBX and Luau are exported, the other finds' FBX restored. **The hard hat:** the hat's dome is
  an analytic surface (`hh_F`, `hh_on`, `hh_top`), so the leather bracket, the clip and the cord
  over the crown are laid on it exactly; the cord and battery are `_Pack`, hideable when worn.
  **The jar:** twelve fireflies, each its own part with its own glow track, flying paths in the
  jar's frame: `Idle` (loop, in the jar), `Open`, `Drift` (loop), `Gone`. Their x and y in
  `Drift` are pure sines keyed at quarter points with Sine Out/In (exact, few keys); everything
  else is sampled and thinned with `bl_rdp`. Checked by script: every seam matches to the key,
  no flier passes through the glass, they stay within 3 studs at 1.1 to 3.6 high. **Kit
  change:** a light may name `glow_part` to follow that part's glow in the previews (each
  firefly's light); the game's motion player must do the same (README, D-196). **Travel
  channels lean about the pivot after the move**: a part moved along its axis then pitched
  swings about its rest pivot; the lid's landing solves for it (`fj_lid_tracks`). **Context:**
  this session ran past 300k (two finds with long motion work): budget a find with motion at
  about 120k. **The theatre spotlight, researched, not built:** sizes from Strand's Fresnelite
  6 in (12.1 x 10.2 x 12.3 in with its yoke, 10.5 lb, a steel yoke; theatrecrafts.com's
  archive PDF fresnelite_6_8_2002.pdf), a 1970s Mole-Richardson Combo Junior 1K with a 6 in lens
  on a 1940s rolling baby stand, 4 to 8 ft, its barn doors fixed and rotating
  (oldhollywoodlightcompany.com), a 1960s Berkeley theatre light with barn doors, 18 x 30 x 18 in
  (thehoarde.com); Wikipedia's "Fresnel lantern" (3, 6 and 8 in lenses; barn doors ride in the
  gel frame's slot). **Look at photos first** (Wikimedia Commons "Fresnel lantern", the Mole
  listing). Plan: a 6 in Fresnel can with louvres on top, the stepped lens in its ring, a gel
  frame slot holding four-leaf barn doors, a focus knob under the can; a flat steel yoke with
  big tilt knobs; a telescoping stand on three legs, about 6 studs to the lens. Parts: `Stand`
  (root), `Yoke` (pans about Z), `Can` (tilts about X through the knobs), the lens or lamp as
  the glow part, each barn door leaf hinged, the focus knob. `big=True`. A Spot (3,200 K,
  narrow) and a weak Point. Motions: `SwitchOn` (the lamp strikes and warms through orange),
  `Aim` (heavy, damped pan and tilt, a little overshoot against the yoke's friction), `Doors`.

- **Nov 15, F-02h and F-02i (the disco ball and the neon OPEN sign built, both in Studio).**
  Both in `lights/build.py` (`DB_*` and `NE_*`; spec `DISCO_*` and `NEON`) with README entries;
  uploaded and imported (`import("Lights", {"DiscoBall", "NeonSign"})`), templates in
  `ReplicatedStorage.Props.Finds` (the owner saves). **The disco ball** is a mirror ball on a
  tabletop battery motor (the references showed one; it stands on a floor where a hanging one
  couldn't). Its 1,100 tiles are flat faces only in the detailed mesh, each a degree off true,
  baked into the normal map: that's the sparkle. Lit, one tile in twenty glows (they turn with
  the ball, a stand-in for glints) and six narrow Spot lights on the ball throw the dots; no
  pinspot is modelled (a real ball needs one; this one makes its own light). **Seen in Studio,
  a plain room lit like a unit (bulb 0.6, range 11), from the doorway, off and on:** the sign
  reads OPEN even off and glows pink and aqua on, its pink spill on the walls no brighter than
  the bulb; the ball reads as a silver ball on a stand and glints on. **Not seen: the ball's
  dots on the walls.** Spot lights drew nothing in Edit captures, even at 30 degrees and
  brightness 8, so they're unjudged in Roblox; and at low graphics Roblox draws lights in
  coarse blocks, where 4-degree spots may never show. The game ticket for Spin must check in
  Play on a phone and may need its dots another way (a few dot decals swept round the walls).
  **Kit lesson:** a tube packs as one strip, so a long one (the sign's 6-stud border) shrank the
  whole texture to 195 texels a stud: cut long flat tubes into runs (`ne_chunks`, a stud each;
  326). **The miner's hard hat, planned (references not looked at yet):** look at photos of a
  worn miner's hard hat with a cap lamp (a fibreglass or plastic shell with a brim, a lamp
  bracket on the front, the lamp head with its lens and reflector, a coiled cord down to a
  belt battery box) and get the sizes from a listing. Parts: `Shell` (root), `Lamp` (the head,
  the glow part, maybe tilting on its bracket), the cord and battery on the root. Wear: a Spot
  from the lamp (warm white, narrow, the light that "lights what you look at"), a weak Point
  beside it; motions `SwitchOn` (the lamp's switch turned, the light comes up) and `RunDown`.
  It's a find worn on the head: keep its pivot where it sits on a head and note the fit for
  the game ticket.

- **Nov 15, F-S1 (the night's finds into Studio).** The nine Lights and the RC car are
  templates in `ReplicatedStorage.Props.Finds` (the owner saves the place), made by code: the
  uploader finds every set's FBX and glow mask by itself, and `Finds/Kit.luau`'s `import` makes
  each a jointed Model (CRAFT.md, "Into Studio", step by step). **Holds up in Roblox:** every
  part's pivot and size matched the Luau to 0.001; seen in Studio in a lit unit from the doorway
  and up close, off and on: the desk lamp, blob lamp, moon lamp, lantern, oil lamp and RC car
  read at a glance; the glow masks glow (the moon, the blob lamp's violet, the green stick, the
  night-light's shade); the oil lamp's flame and oil read through its glass. The RC car's Drive,
  posed at 35 per cent, holds together with the right axes (forward is its -Z, it turns right
  and drifts right). **Changed:** the oil lamp's light 1.4/16 to 0.7/10 and the lantern's 1.2/16
  to 0.8/12 (each lit a unit brighter than its bulb); the oil lamp's chimney alpha 0.08/0.06 to
  0.18/0.12 (it vanished). The oil lamp's sheets weren't re-rendered: run `scripts/art.sh set
  lights renders OilLamp` with `ACTIONS=` when next touched. **Not judged:** the desk lamp's spot
  alone, the tea light's jar and the blob lamp's bottle up close (both read from the doorway),
  any motion but the car's Drive played in Roblox (no motion player exists yet: the game's
  ticket writes Motor6D Transforms; scale and stretch need Size). Small finds are specks from a
  doorway when off (`OWNER.md` asks). **The next sets must:** keep lights under the unit's bulb
  and glass at 0.15 a wall or more; after a rebuild, restore the FBX of finds that didn't change
  before uploading; check the textures stage printed `BAKED` (once it printed nothing and baked
  nothing).

- **Nov 15, F-02f and F-02g (the blob lamp judged and fixed; the oil lamp built).** Both in
  `lights/build.py` with README entries. The blob lamp: the lit liquid's glow cut to 0.35 to
  0.15 and a deeper violet, the wax's glow cut by half (it washed out to peach), and its light
  moved down under the wax (at 0.66 it burned the pool white). Its Flow filmstrip reads
  (towers climb on their necks, snap, hang, sink); one nit: in two frames a thin spike pokes
  out of the top of a rising tower (the neck's top, or `Blob4`, through the blob): check with
  `bl_check` and the MP4 when next touched. The oil lamp (`OIL_*` in the
  spec, `ol_*` in the build): see-through glass needs a **dark** colour on every layer (the
  chimney at a pale colour glowed like yellow plastic when lit), and **no dust on glass sides
  a light shines through** (the dust lit up as frost: `keep=` the chimney's sides);
  `ol_chip` knocks a chip out of a lathe's edge (bounded by `rmin`, `zmax`, or it dents the
  whole side). **Kit changes:** renders take `ACTIONS=Light,Burn` (only those actions;
  `ACTIONS=` none, for stills alone); each find renders into its own `out/frames/<Find>/`.
  **Traps:** never run two Blender renders at once: the blob lamp's 384-frame Flow was killed
  (out of memory) beside another render, and before the frames fix one find's render wiped the
  other's frames. A probe of a part's face kinds: load `build.py` with importlib in
  `blender -b --python` and read `shape.bm.faces.layers.int["kind"]`.
  **The disco ball, planned (references not looked at yet):** look at Wikimedia Commons
  "Category:Mirror balls" (three photos: whole, close on the tiles, one lit with its spots on
  a wall) and a listing for size: home balls run 8 to 12 inches with tiles about 10 mm square
  (the catalog row: Rare, "Spin: spots of light race round the walls"). Build it as a `Ball`
  part (tiles in latitude rows, the grout between them in the detailed mesh's normal, mirror
  metal at roughness about 0.05, a few tiles missing or tarnished: found in storage) hanging
  from a small battery motor by a short chain, the `Ball` turning about Z on the motor's
  shaft. The spots: several narrow white Spot lights on the `Ball` part pointing out (they
  turn with it), weak, so they read as moving dots on a unit's walls; `Spin` winds up from
  still to about 1 turn in 6 s and holds, `SpinDown` slows to a stop with a small swing back.

- **Nov 15, F-02f (the blob lamp coded, not judged).** `BLOB_LAMP` in `lights/build.py` (spec
  `BLOB_*`), in `FINDS`; textures baked (1024, 449 texels a stud, 9,652 triangles) and the
  Luau exported; quick sheets rendered but **not looked at**, so it is not ticked. Next: run
  `scripts/art.sh set lights renders BlobLamp` (Flow is 52 s at 8 fps, about 420 frames: run it
  in the background), judge the sheets, fix, write its README entry. Parts: `Base` (spun base,
  sleeve, cord, inline switch, plug), `Rocker`, `Bottle` (clear: the glass and the violet
  liquid in one shell, the glow part), `Cap`, `Pool`, `Mound`, `Neck`, `Blob1` to `Blob4`.
  **Timing, measured** from Commons "Lava lamp (oT) 01 ies.ogv" (pixel rows per second, in the
  browser): a tower climbs about a sixteenth of the bottle a second, slowing near the top; its
  neck snaps about 16 s in; the blob hangs about 6 s, then sinks faster (about twice the
  climb's speed at the end); a sinking blob can tear, its top floating back up. `BL_PLAN` holds
  each blob's keys; `bl_flow()` joins them with a monotone curve and thins them to Linear keys
  (no stop at every key); `bl_check` prints blobs touching each other or the glass. **Look
  for:** a neck that reads (it thins as it stretches, keeping volume), the snap's drop
  (`Blob4`), the liquid's violet not drowning the wax, blobs not grey (each is `alone`).
  **Seen once** (the quick `-offon` sheet, small): it reads as a lava lamp at a glance, off and
  on; lit, the liquid glows near white-lavender and washes the wax to pale pink. First fix:
  the liquid's glow mask in `bl_look` (`C.lights` on `lq`, now 1.0 to 0.5) down to about 0.35
  to 0.15, a deeper violet, and the wax's red-orange kept saturated.
  References: Commons "Category:Lava lamps" ("1990s Mathmos Astro.jpg", "Lava lamp operating.jpg",
  "Lavalamp red.jpg"); sizes from the F-02e note below. **Kit changes:** `Part(alone=True)`
  (baked with nothing else: parts hidden where they're built), `finish(..., keep=mask)` (no dust
  on what's sealed in), a motion's `fps` (previews a long loop at fewer frames).
  **The oil lamp, researched:** a clear glass pedestal lamp (a 6 in foot, a stem, an onion
  fount; about 9.5 in to the collar), a brass collar and #2 Queen Anne burner (prongs holding
  the chimney, a thumbwheel on a spindle out the side), a 10 in chimney (3 in fitter, 4 in
  bulge, 2 in top: Westinghouse via acehardware.com/p/36426; B&P 3 x 10). About 20 in in all,
  2 studs. A flat wick's flame is a fan face on and thin edge on (Commons "kerosene lamp
  flame.jpg"). Fragile: chip the chimney's top rim and the foot's edge. Bing image results for
  "clear glass pedestal oil lamp queen anne #2 burner chimney" show the shapes. **Context:**
  photo grids drawn in the browser cost far more than they look; this session hit 270k before
  judging anything. Look at one photo at a time, small.

- **Nov 15, F-03a (the RC car, taken ahead of the Lights).** Built with its transmitter in a
  new set, `art/finds/figures/` (`scripts/art.sh set figures`; README has references, sizes,
  parts and motions). **Kit changes:** travel channels `x`, `y`, `yaw`, `pitch`, `roll` on any
  part (pose; the Luau writes them in Roblox axes as x, z, yaw, pitch, roll with signs fixed);
  a motion's `follow=part` makes the filmstrip camera ride with that part over a floor with
  saw-cut joints, a tuple `focus` then counts from where that part starts; `Find(drive=...)`
  writes a `Drive` table (types in `Finds/Art.luau`). The car's motions come from `drive()` in
  figures/build.py, a small simulation reduced to keys (`rdp`): reuse it for anything that
  rolls (the die-cast car's Push). **Left for F-03b and polish:** the die-cast car (Common,
  "Push: it rolls off down the hall"); the car's texture is 1024 at 172 texels a stud, its
  islands only 30 per cent of the square (many small pieces, each padded): fewer, bigger low
  pieces would sharpen it; the transmitter's aerial is collapsed and fixed (pulling it out
  before a drive is a nice beat: sections as parts sliding on `move`). Context ran out early
  (about 190k before modelling, from long reads and research images): read less.
- **Nov 15, F-02e (the moon lamp; the blob lamp researched).** The moon lamp is built (README).
  **Its "seam" wasn't the lathe:** the see-through phase shade sits 0.006 studs outside the
  moon's back half at bake time, and the look's grime (an occlusion node, baked into the
  colour) greyed everything under it, with a hard edge where the shade ends. **Kit fix:** for
  a find with clear parts, every channel's bake now hides the clear parts from the solid
  ones (before, only the occlusion channel did). The tea light, fairy lights and lantern keep
  their committed textures; rebuilt, they'd come out a touch lighter under their glass.
  Lathed spheres are fine for the round finds. **Kit pattern:** a detailed mesh can carry
  per-point numbers for its look: `bm.verts.layers.float.new(name)` (made before holding any
  verts: adding a layer frees them), read in the look with an Attribute node (`mn_attr`). The
  moon's maria and rays come from Python that way, so relief, colour and glow agree; its 1,300
  craters are numpy on a 720 x 320 detailed lathe (seconds). Started building at 190k context
  (image-heavy research and sheets): look at fewer, smaller sheets.
  **The blob lamp, ready to build.** References: Wikimedia Commons "Category:Lava lamps"
  (the photo "1990s Mathmos Astro.jpg", the classic shape side on; and 7 videos under "Videos
  of lava lamps" for timing); lavalamp.com model 2089 (14.5 in, 20 oz, glass globe, aluminium
  base and cap, 25 W appliance bulb); Schylling listings (a 4.25 in footprint). No maker's
  name or mark ("lava lamp" is a brand: call it the blob lamp). Measured off the photo at
  14.5 in: the base 5.6 in tall, a cone from 4.3 in across on the floor narrowing to a 1.7 in
  waist 4 in up, then flaring to a 3.2 in collar; the bottle 7.1 in above the collar, 3.2 in
  at the collar, widest (3.7) 1.45 in up, then straight to 2.0 in under the cap; the cap a
  cone 1.8 in tall, 2.1 to 1.75 in. So 1.45 studs tall, 0.43 across. Inside: a wire coil on
  the bottle's floor, the wax pool on it, red-orange wax in tinted liquid, lit from a bulb in
  the base. **Plan:** parts `Base` (root, spun aluminium rings, vent slots at the foot, the
  cord out the back), `Bottle` (clear), `Fluid` (clear, tinted; the glow part), `Cap`, `Pool`
  (the bottom wax; `stretch` sags as blobs leave, swells as they land) and `Blob1` to `Blob4`
  (lofted teardrops, pivots at their middles, each axis a few degrees off upright so they
  drift; `move` along it and `stretch`): a blob necks off the pool (stretched, slow), rises
  as a teardrop, flattens under the cap, lingers, sinks rounder and slower. `Flow`: one long
  loop (its keys end where they start; the README says the game loops it), the blobs out of
  step; `SwitchOn`, `SwitchOff`; found cold, the wax a lump on the bottom. Blob glow: put
  each blob's glow in `lit` and the switch motions. **Time it from a Commons video** (play it
  in the browser pane, read `currentTime` with JavaScript as a blob leaves and arrives):
  published numbers disagree (a student's frame count, about 2.8 cm/s for a small blob, faster
  once free; an idealised Stokes estimate, 0.3 cm/s).

- **Nov 15, F-02d (the camping lantern; the moon lamp half done).** The lantern is built from
  the kit with no kit change (README: guard bars, a ribbed hood, a knob that clicks and dims,
  a bail that lifts; `RunDown` for its 90 seconds' end). Started building at 110k context.
  **The moon lamp is coded but left out of `FINDS`** (`mn_*` in `lights/build.py`, `MOON` and
  `CRADLE` in `spec.py`; add `MOON_LAMP` back to `FINDS` to work on it). References: Bing image
  results for "3D printed moon lamp wooden stand" and "moon lamp wooden stand only replacement
  cross cradle": printed PLA spheres 8 to 20 cm (15 cm usual), a lithophane (lit, the thick
  maria grey, the highlands bright); a white plug in a flat cut at the bottom holds the touch
  switch and USB port; a cradle of two M-shaped pale wood pieces halved into each other. Its
  phases: a dark see-through `Shade` cap just outside the moon (found at `scale` 0, `lit`
  1), turning about the moon's upright axis like the terminator; `Phase` turns it 45 degrees
  a tap (the game adds the phase it was on). What works: the cradle, the shade, the motions.
  **What doesn't: the sphere shows a hard shading seam down one side** (a meridian at -X, where
  the lathe's strip splits), with the look's bump on or off, so it's the game mesh's normals
  or tangents where a lathe's strip splits on a sphere; flatter lathes (the lantern) hide it.
  Look at how `kit.load_low` builds the mesh (`out/MoonLamp.blend` loaded headless showed no
  objects), try `split=1` and a seam at the back, or compare a plain lathe sphere. Also: the
  craters are now in the detailed mesh (420, power-law sizes) but read lumpy: the hills are
  too big, keep a crater's depth under 0.008 studs (a few black specks: rays missing), and
  lit, the maria barely show (glow mask `1 - 0.62 maria`: try 0.35 at the maria, and a
  weaker preview). **Kit trap:** `Shape.merge(bm, kind, M)` with a rotation `M` projects the
  UVs in the wrong frame (faces collapse to a line, bake black): transform the bmesh first and
  merge without `M` (`mn_piece` does). The blob lamp isn't researched.

- **Nov 15, F-02c (the glow sticks and the string fairy lights).** Two finds, built from the
  kit with one small change: a light may give `rgb=(r, g, b)` instead of a colour temperature
  (a green glow stick isn't a filament). This session started building at 100k context and
  wrapped at about 265k, so the camping lantern is next; its research is done:
  **the camping lantern, ready to build.** Reference: a retro LED camping lantern (image
  results for "retro LED camping lantern green metal hood bail handle dimmer knob globe"; the
  clearest was a product shot on media.takealot.com, a "Portable Retro LED Rotary Switch"
  lantern). From that photo, at 7.5 inches body height: an olive-green steel foot flaring like
  a bell (4.1 in across, about 0.6 in tall), a straight green band (3 in across, 1 in tall)
  with a small silver rotary knob on its front, a dark neck and a black seat ring, a clear
  straight globe (3 in across, 3.2 in tall) round a frosted white hourglass diffuser with
  horizontal ribs, a black top ring, a wide olive hood like a flat cone (4.3 in across,
  overhanging), a ribbed steel cap on top, and a chrome wire bail hooked into the hood's sides
  with a black rubber grip, standing about 2 in above the cap. Listings for 3 D-cell lanterns
  give 7 to 11 inches tall (Primus 8.3, Rayovac 7.25, Dorcy 7). Plan: parts Body (root),
  Globe (clear, alpha about 0.1), Diffuser (the glow part), Knob (turns about -Y out of the
  band), Bail (turns about X through its hinges; found fallen back about 108 degrees, resting
  on the hood); motions SwitchOn (the knob clicks, then the light rises as the dimmer turns),
  SwitchOff, RunDown (the 90 seconds end: it flickers and dims), Lift (the bail swings up);
  one Point light in the diffuser, warm (about 3,200 K), Brightness 1.2, Range 16, no
  shadows; olive enamel worn at the edges (`enamel_wear`).
  Traps found: **long thin strips wreck the packing.** A tube is one strip: the fairy lights'
  ten-stud wire packed to 1 per cent; cut a long tube into pieces (`caps=False`) and ask for
  `texels=500` (the kit picks a size from the 1024 packing, then the smaller square's gutters
  eat it: the glow sticks got 178 texels a stud at 256). Hi-only geometry inside a part
  bakes onto whatever low surface's rays reach it first: keep inner pieces (the ampoule) more
  than 0.008 + 0.02 studs from the outer wall's game mesh, or they catch the wall. A part
  bending in the middle (the glow stick's crack) is two parts on a pivot at the convex side's
  surface: nothing opens, the concave side overlaps inside the tube. Both finds' Point lights
  have no shadows; judge in F-S1 whether the glow sticks' small green spot and the fairy
  lights' faint warm wash read on a phone.

- **Nov 15, F-02b (the tea light in a jar).** Built and judged twice (the glass was milky and
  the candle lit the whole jar yellow like a plastic tub: glass wants a dark, glossy colour;
  the bail's arc was faceted; the wire had too many triangles). One find again: this session
  reached 225k context before its first full render (reading the kit's bake, export and render
  code to add glass cost most of it), so start lean and read the kit only by grep. Kit
  changes, all in CRAFT.md's kit list: **glass** (`Part(clear=True)`, `paint(alpha=)`, the
  alpha in the colour PNG, a clear part's own material, occlusion that ignores glass, Gold
  keeping glass), the `scale` and `stretch` channels (stretch is squash and stretch keeping
  volume: F-05's squishies can use it), `lit=` on a Find (how it stands when on), filmstrips
  that keep unmoved parts at rest, and a **first-person held sheet** (the find in your hands
  1.05 studs ahead, the night-light's and the desk lamp's re-rendered with it). A spec for
  `Finds/Art.luau` now exists (`tests/findsart.spec.luau`). Quick sheets for a find with four
  motions take about 5 minutes, full ones about 10: render one find's sheets in the background
  and write notes meanwhile. The tea light is 4,058 triangles; its wire (1,064) could lose its
  eyes' detail on the game mesh if a budget bites. Glass glows dimly from its inside light in
  Cycles; in Roblox it's alpha-blended lighter (docs/STUDIO.md): F-S1 judges the jar there.

- **Nov 15, F-02a (the plug-in night-light).** Built and judged three times (the dome was
  faceted, the lit shade blew out flat white with no hot spot, the shade and base were one
  ivory, and at 4.6 inches it was lost from the doorway, so it's built 1.15 times bigger).
  Only one find: the session started at 120k context. Kit changes, all in CRAFT.md's kit list:
  `Shape.loft` (shells through rings of any shape), `texels=` on a Find, a filmstrip `focus`
  that can be a point plus `distance`, preview lights that honour `shadows=False`, Gold keeping
  every glowing texel whole, and part sizes in the Luau written positive (they came out
  negative on X, the desk lamp's too). The desk lamp's sheets weren't re-rendered after these.
  **The tea light needs see-through glass**, which the kit doesn't do: give `Surface` an alpha,
  bake it into the colour PNG's alpha, and wire it to the material's Alpha so the FBX imports in
  AlphaMode Transparency (docs/STUDIO.md, "AlphaMode Transparency cuts unless the part is a hair
  transparent": the jar part then wants Transparency 0.02 in Studio). Its flame is its own glow
  part; flicker is `glow` keys plus a small `turn` sway (the kit has no scale channel).
  For F-S1: from a unit's doorway a 5 inch find is a speck when off; judge whether small finds
  need help to be seen.

- **Nov 15, F-01 (the kit and the desk lamp).** The kit is in `art/finds/kit/` and CRAFT.md's
  "The kit" says how to use it; the desk lamp (`art/finds/lights/`) proves every piece: parts on
  hinges, the high-to-low bake, glow, two lights, two motions, Gold, the Luau. Its sheets were judged three
  times (framing, the shade made a bell, the nod doubled to 4 degrees, a dark band at the rim
  broken into chips); the switch filmstrips with the bigger nod weren't looked at again.
  Things to know: `quick` sheets take 90 s; look at one composed contact sheet (ffmpeg
  hstack/vstack into the scratchpad), not each PNG, or the context runs out. Triangles came to
  6,564 (the shade 2,272 and the base with its cord 2,276): trim the shade's profile if a medium
  find must stay under 6,000. Packing fills 39 per cent of the square: tighter packing
  (fewer, bigger islands) would buy density. The person in the lineup is the shrink-wrapped
  figure from the unit's sheets. `Finds/Art.luau` has no Lune spec yet: add one (ease ends at 0
  and 1, Back overshoots, a lamp key sampled) when next touched.

## Lights (16) · F-01, F-02

A light set down switched on lights the space round it until it runs down. Whether that holds a Mannequin is a decision.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Plug-in night-light | Common | Switch on (at home): a soft glow by the floor | Frosted ribbed shade | Nov 15, F-02a |
| Tea light in a jar | Common | Light: a small glow for about a minute |  | Nov 15, F-02b |
| Desk lamp | Common | Switch on (at home): a warm pool of light | Needs a socket, so only at home | Nov 15, F-01 |
| Bundle of glow sticks | Common | Crack: one stick lights a small spot for the rest of the floor; three to a bundle | The glow sticks from the Nov 2 draft | Nov 15, F-02c |
| String fairy lights | Uncommon | Switch on: lay them along a hall for a dim line of light |  | Nov 15, F-02c |
| Camping lantern | Uncommon | Switch on: a wide light for 90 seconds |  | Nov 15, F-02d |
| Moon lamp | Uncommon | At home: it glows; tap it to change its phase |  | Nov 15, F-02e |
| Blob lamp | Uncommon | At home: coloured blobs rise and fall |  | Nov 15, F-02f |
| Oil lamp | Rare | Light: warm light that runs down slowly | Fragile | Nov 15, F-02g |
| Disco ball | Rare | Spin: spots of light race round the walls |  | Nov 15, F-02h |
| Neon OPEN sign | Rare | At home: it buzzes and glows pink |  | Nov 15, F-02i |
| Miner's hard hat | Rare | Wear: a lamp on your head lights whatever you look at, for a minute | A light that leaves your hands free | Nov 15, F-02j |
| Jar of fireflies | Epic | Open: fireflies drift out and light the unit for a minute, then they're gone |  | Nov 15, F-02k |
| Theatre spotlight | Epic | At home: point it at your best find | Big find | Nov 15, F-02l |
| Stained-glass lamp | Legendary | At home: it throws coloured patterns on your walls | Fragile | Nov 15, F-02m |
| A lamp that's on when you find it | Secret | It never runs down | Loose only, floor 25 up. In a power cut it's the only light on the floor || Nov 15, F-02n |

## Cars from Figures and models (2 of 14) · F-03

Pulled forward from wave 4 because the owner named the RC car (Nov 14).

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Die-cast car | Common | Push: it rolls off down the hall | Our own late-1960s saloon (D-200) | Nov 15, F-03b |
| Remote-control car | Rare | Drive (at home): round your unit and out into the hall of units | With its transmitter (D-193) | Nov 15, F-03a |

## Wind-ups and noisemakers (14) · F-04

The set that teaches noise. Wind one, drop it, walk away, and see what comes to look.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Kazoo | Common | Blow: a buzzy note |  | Nov 16, F-04f |
| Squeaky rubber duck | Common | Squeeze: a squeak you can hear down the hall |  | Nov 16, F-04e2 |
| Toy siren car | Common | Push: it rolls off, wailing | A noise that moves | Nov 16, F-04e |
| Wind-up chattering teeth | Common | Wind: they chatter off across the floor | Monsters come to look | Nov 15, F-04c |
| Toy drum | Uncommon | Bang: loud |  | Nov 16, F-04f2 |
| Wind-up mouse | Uncommon | Wind: it zips off and squeaks wherever it stops |  | Nov 16, F-04d |
| Wind-up walking robot | Uncommon | Wind: it clanks off in a straight line for 15 seconds | A noise you can send down a hall | Nov 16, F-04c2 |
| Farm-animal spinner | Uncommon | Pull: the arrow spins and an animal noise plays | A throwback toy | |
| Jack-in-the-box | Uncommon | Wind: a tune, then a bang as it pops | The bang comes a few seconds after you let go | Nov 15, F-04b |
| Cymbal monkey | Rare | Wind: it bashes its cymbals for 20 seconds, loud | The strongest lure in the set | Nov 15, F-04a |
| Pull-string cowboy doll | Rare | Pull: it says one of six lines |  | |
| Singing fish plaque | Rare | Press: its head turns and it sings |  | |
| Clockwork tin bird | Epic | Wind: it hops and whistles | An antique tin toy | Nov 16, F-04d2 |
| Wind-up tin carousel | Epic | Wind: it turns and plays a tune |  | |

## Squishies (14) · F-05

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Stress ball with a face | Common | Squeeze: its eyes bulge out |  | |
| Goo ball | Common | Squeeze: it oozes between your fingers and slowly comes back | The craze of 2026 | |
| Squishy butter stick | Common | Squeeze: leaves a dent that slowly fills back in | A 2026 squishy trend | |
| Mochi bun | Common | Squeeze: a soft puff of a sound |  | |
| Paper squishy with a drawn face | Uncommon | Squeeze: it crinkles | Looks homemade; cheap to build | |
| Squishy toast slice | Uncommon | Squeeze: springs back like real bread |  | |
| Gel bead ball | Uncommon | Squeeze: the beads swirl inside |  | |
| Glitter goo ball | Uncommon | Squeeze: glitter swirls, then settles |  | |
| Jumbo slow-rise strawberry | Uncommon | Squeeze: the dent takes ten seconds to rise back |  | |
| Colour-change goo ball | Rare | Squeeze: it changes colour where your fingers pressed |  | |
| Squishy cake slice | Rare | Squeeze: frosting squishes out of the side |  | |
| Squishy capybara | Rare | Squeeze: it lets out a tiny, happy sigh |  | |
| Mega goo ball | Epic | Squeeze: both hands, and a deep squelch that carries | Loud enough to draw a monster | |
| Galaxy goo ball | Legendary | Squeeze: stars drift and swirl inside |  | |

## Plush (16) · F-06

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Small teddy bear | Common | Hug: a tiny squeak |  | |
| Round cat plush | Common | Squish: it flattens and puffs back up |  | |
| Frog plush | Common | Hug: it croaks |  | |
| Mushroom plush | Common | Squish: its cap wobbles |  | |
| Jellyfish plush | Uncommon | Shake: its legs float and drift |  | |
| Axolotl plush | Uncommon | Hug: its frills wiggle |  | |
| Capybara plush | Uncommon | Hug: it shuts its eyes, content |  | |
| Scented strawberry bear | Uncommon | Hug: a little puff of pink |  | |
| Weighted sloth plush | Uncommon | Hug: heavy, and slow to let go | Weighted plush searches rose 22% in a year | |
| Bean plush with its heart tag | Uncommon |  | A 1990s craze; Sealed means the tag still has its plastic cover | |
| Grumpling | Rare | Squeeze: it pulls a rude face | The 2026 ugly-plush craze | |
| Zipper-mouth plush | Rare | Unzip: a tiny find is inside its mouth |  | |
| Toothy monster plush | Rare | Clip: it hangs from your belt | The 2025 bag-charm craze | |
| Giant shark plush | Epic | Hug: it takes both arms |  | |
| Giant carnival bear | Epic | Hug: it takes both arms |  | |
| Antique teddy with a button in its ear | Legendary |  | The first teddy bears are real collectors' treasures | |

## Night Shift Minis (14) and their blind box · F-07

The monsters as collectibles. Five minis and the Secret come out of the Night Shift Minis blind box; the rest turn up loose. Each one does at home a small, harmless version of what its monster does on a floor.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Mannequin keychain | Common | Clip: it swings from your belt as you run |  | |
| Packrat keychain | Common | Clip: it swings from your belt as you run |  | |
| Mannequin mini | Uncommon | At home: it turns its head only while you're looking away | The Mannequin's own rule. Blind box | |
| Packrat mini | Uncommon | At home: it stands holding a tiny lamp | The first thing a player sees it carry. Blind box | |
| Mannequin mini, pointing | Uncommon | At home: it points at whoever walked in last | Blind box | |
| Packrat mini, arms full | Uncommon |  | Blind box | |
| Minis display stand | Uncommon | At home: holds eight minis and lights each one |  | |
| Sleeping Packrat mini | Rare | At home: it snores softly | Blind box | |
| Mannequin plush | Rare | Hug: it goes stiff |  | |
| Packrat plush | Rare | At home: once a day it moves one small find from your shelf into its arms | The Packrat's habit, made cute | |
| Mannequin display hand | Epic | At home: it holds whatever find you put in it |  | |
| Mannequin bust | Epic |  |  | |
| Packrat's pile diorama | Legendary | At home: the pile grows with every find a Packrat has ever taken from you | Turns a loss into a trophy | |
| The one nobody's seen | Secret |  | Only an outline of the next monster; the figure changes when that monster arrives. 1 in 144 boxes | |

## Boxes and tins (14) · F-08

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Shoebox | Common | Open: one small find; now and then a pair of sneakers |  | |
| Banker's box of papers | Common | Open: papers spill out; now and then a page from the old storage company | Leads into the Old company set | |
| Taped moving box | Common | Open: one Common or Uncommon find | The most common find in the game | |
| Cookie tin | Common | Open: never cookies. Buttons and thread, or now and then a roll of old coins | A joke the grown-ups will get | |
| Crate of packing peanuts | Common | Open: foam bits burst out across the floor; something is buried in them |  | |
| Rattling box | Common | Shake: you hear a clink, a thud or a jingle, then decide whether to open it | My idea, untested | |
| Hat box | Uncommon | Open: a hat you can wear |  | |
| Gift-wrapped present | Uncommon | Open: a find one grade better than this floor usually gives | Lethal Company's gift box | |
| Nailed-shut wooden crate | Uncommon | Pry: two tugs and a loud creak, then a Rare or better find | Monsters hear the creak | |
| Jewelry box with a dancer | Rare | Open: a tiny dancer turns to a tune; inside is a piece of jewelry | The tune carries a little | |
| Nesting dolls | Rare | Open: each doll holds a smaller one, five times over; the smallest holds something tiny and good |  | |
| Puzzle box | Rare | Open: slide three panels in the right order, each right one clicks; inside is a Rare or better find | Resident Evil's puzzle boxes (from memory) | |
| Old toy chest | Epic | Open: three toys tumble out, Common to Epic, and you carry what fits |  | |
| Steamer trunk | Epic | Open: old clothes and one antique | Big find | |

## Bags and cases (14) · F-09

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Garbage bag of clothes | Common | Open: clothes, and now and then something left in a pocket |  | |
| Duffel bag | Common | Open: gym clothes and one sports find |  | |
| Backpack | Common | Open: school things. Wear: it rides on your back | Looks only; it never adds a slot | |
| Purse | Common | Open: coins spill out, to spend at the machine in the elevator |  | |
| Fanny pack | Uncommon | Open: one small find. Wear: round your waist |  | |
| Wallet | Uncommon | Open: coins, a photo, and now and then a creature card |  | |
| Makeup case | Uncommon | Open: a puff of glitter and a hand mirror |  | |
| Suitcase with travel stickers | Uncommon | Open: holiday clothes and a souvenir snow globe |  | |
| Tackle box | Uncommon | Open: fishing lures; one in ten is a gold lure |  | |
| Toolbox | Uncommon | Open: one of the game's tools (bolt cutters, padlock, saw, bubble wrap or air horn) | Another way to find a tool, rarer than the machine | |
| Doctor's bag | Rare | Open: old instruments and one antique |  | |
| Guitar case | Rare | Open: a guitar, or a stack of comic books someone hid inside |  | |
| Camera bag | Rare | Open: an instant camera or a camcorder |  | |
| Violin case | Rare | Open: usually sheet music; now and then a concert violin |  | |

## Locked and sealed (8) · F-10

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Piggy bank | Common | Throw: it smashes and coins scatter, loudly | Coins to spend now, or quiet: your choice | |
| Locked diary | Uncommon | Open: its tiny key is taped underneath; inside is a page about the building's past | Its words wait for the story | |
| Coin jar | Uncommon | Tip: coins roll everywhere, loud, and take a while to pick up |  | |
| Padlocked lockbox | Uncommon | Open: needs bolt cutters and uses one cut; inside is a Rare or better find | DOORS' locked chests | |
| Ring box | Rare | Open: the lid creaks up on a ring, Rare to Legendary |  | |
| Combination briefcase | Rare | Open: three dials; the numbers are on its luggage tag, somewhere in the same unit | A small version of the floor codes | |
| Floor safe | Legendary | It opens itself on the results screen, dial spinning, with a Legendary or better inside | Big find. The reveal at results is my idea, untested | |
| Time capsule | Secret | Open (at home): a day after you bring it home; inside is a find from a past season | Grow a Garden's waiting at home | |

## Treasures (14) · F-11

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Roll of old coins | Uncommon | Open: coins to spend in the elevator, and now and then a rare one |  | |
| Silver dollar | Uncommon | Flip: it rings as it spins |  | |
| Old treasure map | Rare | Read: X marks a spot on a floor far above |  | |
| Coin album | Rare | Open: one coin in it is the rare one |  | |
| Silver bar | Rare |  |  | |
| Gold coin | Epic | Flip: it rings as it spins |  | |
| Pirate doubloon | Epic |  |  | |
| Stamp printed upside down | Epic |  | Printing errors are real collectors' treasures | |
| Small treasure chest | Legendary | Open: gold coins pour out, with one Rare or better find |  | |
| First-edition book | Legendary |  |  | |
| Gold bar | Legendary |  | Heavy; it lands with a thud | |
| Diamond the size of a marble | Secret |  |  | |
| Jeweled egg | Secret | Open: a tiny gold surprise inside | A scrap dealer really found one (from memory) | |
| Golden elevator key | Secret |  | Loose only, floor 25 up. What it opens is for later | |

## Big finds, wave 1's eight · F-12

Wave 1 takes these eight of the sixteen (catalog build order); the rest come in wave 4. Each is carried in both hands, the floor's big find.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Phone booth | Epic | At home: now and then it rings |  | |
| Vintage soda machine | Epic | At home: a bottle clunks out once a day |  | |
| Upright piano | Epic | At home: play it |  | |
| Moped | Epic | At home: sit on it; the horn beeps |  | |
| Pinball machine | Legendary | At home: you can play it |  | |
| Arcade cabinet | Legendary | At home: a short game with a high-score board for visitors to beat | Named in the design doc. A decision, because it's a game to build | |
| Jukebox | Legendary | At home: it plays every record you own | Named in the design doc | |
| 1940s motorcycle | Secret | At home: sit on it and it rumbles | A 1940 motorcycle really did turn up in a storage unit | |
