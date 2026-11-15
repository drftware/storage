# The finds to build: wave 1, plus the RC car

Which finds get made next, and which are done. The bar and the method are in `CRAFT.md`; read it
first. The rows come from the catalog doc, "Unit finds: the item catalog"
(https://claude.ai/artifact/29wkaNXM3Yw86xTMb3sjQQ, read with the docs tools, never WebFetch;
don't read it whole, it is 250,000 characters): its wave 1 is 133 finds, built here in the
order below. Each session works from the Next line and moves it on.

**Next:** F-02f, the blob lamp: coded and baked, not judged (the newest note). Render it, judge
it, fix, then the oil lamp (researched in the same note) and the disco ball.

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
| Blob lamp | Uncommon | At home: coloured blobs rise and fall |  | |
| Oil lamp | Rare | Light: warm light that runs down slowly | Fragile | |
| Disco ball | Rare | Spin: spots of light race round the walls |  | |
| Neon OPEN sign | Rare | At home: it buzzes and glows pink |  | |
| Miner's hard hat | Rare | Wear: a lamp on your head lights whatever you look at, for a minute | A light that leaves your hands free | |
| Jar of fireflies | Epic | Open: fireflies drift out and light the unit for a minute, then they're gone |  | |
| Theatre spotlight | Epic | At home: point it at your best find | Big find | |
| Stained-glass lamp | Legendary | At home: it throws coloured patterns on your walls | Fragile | |
| A lamp that's on when you find it | Secret | It never runs down | Loose only, floor 25 up. In a power cut it's the only light on the floor | |

## Cars from Figures and models (2 of 14) · F-03

Pulled forward from wave 4 because the owner named the RC car (Nov 14).

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Die-cast car | Common | Push: it rolls off down the hall |  | |
| Remote-control car | Rare | Drive (at home): round your unit and out into the hall of units | With its transmitter (D-193) | Nov 15, F-03a |

## Wind-ups and noisemakers (14) · F-04

The set that teaches noise. Wind one, drop it, walk away, and see what comes to look.

| Find | Grade | What it does | Notes | Built |
|---|---|---|---|---|
| Kazoo | Common | Blow: a buzzy note |  | |
| Squeaky rubber duck | Common | Squeeze: a squeak you can hear down the hall |  | |
| Toy siren car | Common | Push: it rolls off, wailing | A noise that moves | |
| Wind-up chattering teeth | Common | Wind: they chatter off across the floor | Monsters come to look | |
| Toy drum | Uncommon | Bang: loud |  | |
| Wind-up mouse | Uncommon | Wind: it zips off and squeaks wherever it stops |  | |
| Wind-up walking robot | Uncommon | Wind: it clanks off in a straight line for 15 seconds | A noise you can send down a hall | |
| Farm-animal spinner | Uncommon | Pull: the arrow spins and an animal noise plays | A throwback toy | |
| Jack-in-the-box | Uncommon | Wind: a tune, then a bang as it pops | The bang comes a few seconds after you let go | |
| Cymbal monkey | Rare | Wind: it bashes its cymbals for 20 seconds, loud | The strongest lure in the set | |
| Pull-string cowboy doll | Rare | Pull: it says one of six lines |  | |
| Singing fish plaque | Rare | Press: its head turns and it sings |  | |
| Clockwork tin bird | Epic | Wind: it hops and whistles | An antique tin toy | |
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
