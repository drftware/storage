# Lights

The catalog's Lights (art/finds/WAVES.md), built with the finds kit (art/finds/CRAFT.md, "The
kit"). `scripts/art.sh set lights` rebuilds them; sheets in `art/sheets/<find>-*.png`, motion
clips in `out/`.


**In the place** (F-S1, Nov 15): every find here is a template in
`ReplicatedStorage.Props.Finds.<Find>`, made by `Finds/Kit.luau`'s `import` from the
uploaded FBX (CRAFT.md, "Into Studio"); the place keeps them once the owner saves it.

## Desk lamp (Nov 15, F-01)

- **What it is:** a 1960s-70s spring-balanced desk lamp in oxblood enamel: a two-step round
  cast base on felt, a swivel and yoke, a lower arm of two flat bars with two closed-coil
  springs on pins behind, an upper arm of two plated rods, a bell shade (white enamel inside,
  browned near the bulb) with a push switch on top, a 60 W pearl bulb in a bakelite holder, and
  a braided cloth cord down the arms, off the base and across the floor to a plug. Chipped
  enamel on the edges, faded on top, rust freckles on the plating, dust on what faces up.
- **References** (looked at Nov 15): Wikimedia Commons, Category:Anglepoise lamps (the 1227 in
  cream with its springs and shade switch; the Anglepoise 90's three springs close up); the
  sizes from listings of vintage spring-balanced lamps (Chairish, 1stdibs, design-market:
  bases 13-20 cm, shades 12-20 cm, arms about 30 cm each). No maker's design copied: the base is
  round and stepped, the shade our own bell.
- **Size:** about 37 cm tall at rest, an 18 cm base, a 15 cm shade, arms of 30 and 29 cm: 1.45
  studs tall, 0.72 across the base, 0.6 across the shade (10 inches a stud). Rods a touch bolder
  than life so the arm reads on a phone.
- **Tells:** the bent arm and the bell shade; on, the warm pool under it.
- **Parts** (pivots on the real hinges, axis X): `DeskLamp_Base` (root, the base's middle on the
  floor), `_LowerArm` (shoulder), `_UpperArm` (elbow), `_Head` (wrist), `_Switch` (slides along
  the shade's axis), `_Bulb` (rides the head; carries the glow). 6,564 triangles; one 1024
  texture set at 319 texels a stud.
- **Light:** a Spot from the bulb's tip down the shade (2,700 K, Brightness 2.2, Range 10, 80
  degrees, shadows) and a weak Point fill under the rim (0.5, Range 5) for low graphics; the
  bulb's emissive mask at strength 3, tint (255, 196, 128).
- **Motions:** `SwitchOn` and `SwitchOff` (0.6 s): a thumb on the button: it goes in 0.018,
  clicks, springs back with a little overshoot; the shade nods 4 degrees under the push and
  settles; the arm sways after it; the filament flares warm at the click (on) or drops and fades
  orange (off).
- **Not in the place yet:** upload and insert in F-S1.

## Plug-in night-light (Nov 15, F-02a)

- **What it is:** a C7 night-light of the kind sold for decades: a small ivory plastic base with
  a slide switch in a slot on its front and a polarised plug's two blades out of its back, under
  a frosted, horizontally ribbed shade that rounds over at the top towards the wall. The shade's
  back is a flat plate, so it sits flush on a wall. Yellowed by years of a warm bulb (the shade
  most just over it), scuffed on the base's edges, its blades worn to the brass at the tips
  where a socket gripped them, dust in the ribs.
- **References** (looked at Nov 15): an eBay listing of an incandescent night-light with a
  manual switch and clear ribbed shade (ebay.com/p/1562928426: shade shape, base, switch); a
  Target product photo of a faceted clear C7 night-light (target.scene7.com, image
  GUEST_7d127107...: the shade widest near its rounded top, the narrow base, the switch slot);
  Bing image results for C7 night-lights (Satco S75-062 to 065 frosted and opal shades; bare
  bases with their switches and blades). Sizes from listings: 3.25 to 7 inches tall (Projectpak
  3.25, Atron 5.0, Amertac about 4.5, decorative ones 5.75 to 7), C7 bulbs 7/8 inch across. The
  plug's blades are a real US plug's: half an inch apart, 5/8 inch long, one wider.
- **Choices:** a frosted shade (Satco's kind) rather than a clear one, because clear plastic
  needs see-through glass the kit doesn't have yet and a frosted shade glows whole; built 1.15
  times the 4.6 inch spec (5.3 inches), the size of the bigger plug-in shades, so it reads from a
  doorway.
- **Size:** 5.3 inches tall, 2 across the shade, 1.45 deep plus the blades: 0.53 studs tall,
  0.2 across, 0.22 deep with the blades (10 inches a stud).
- **Tells:** the ribbed pill of a shade on its small square base; on, a warm glow by the floor.
- **Parts:** `NightLight_Base` (root: the middle of the base's back edge, on the floor; the
  blades reach behind it), `_Shade` (rides the base; carries the glow), `_Switch` (the tab,
  slides up along Z). 820 triangles; one 512 texture set at 690 texels a stud (the ribs are 0.016
  studs apart, so the find asks for 500).
- **Light:** a Point at the bulb inside the shade (2,600 K, Brightness 0.7, Range 8, no shadows,
  so it shines out through the shade); the shade's emissive mask is brightest round the bulb and
  dims on the ribs' slopes, strength 2, tint (255, 190, 122).
- **Motions:** `SwitchOn` (0.5 s): a thumb pushes the tab up; it sticks, snaps over its catch to
  the top, knocks back a hair and settles; the bulb warms through orange to full. `SwitchOff`
  (0.55 s): pulled back down; the light drops at the click and the filament's orange fades out.
- **Not in the place yet:** upload and insert in F-S1. From a unit's doorway it's a pale speck
  when off and a small warm point when on: judge in Studio whether small finds need help to be
  seen (WAVES.md).

## Tea light in a jar (Nov 15, F-02b)

- **What it is:** a jam-jar lantern, the kind people make for a garden party: a pint screw-top
  jar with no lid, a heavy galvanised wire wrapped once round its neck under the thread, an
  ear coiled out each side, the wire's two ends twisted together at the back, and a wire bail
  hooked through the ears. A tea light stands on the jar's floor, slid a little off the middle,
  burned about half down. Found: the bail has fallen back against the jar, the glass is
  smudged, dusty on its shoulder and sooted inside above where the flame burns, the wire is
  rusting in spots.
- **References** (looked at Nov 15): HGTV's "Create Glass Lanterns for the Backyard"
  (hgtv.com/decorating/diy/create-glass-lanterns-for-the-backyard: clear screw-top jars, the
  wire wrapped under the thread, a coiled ear each side, a tall bail; how thick the base glass
  looks); Instructables' "How to Make a Homemade Hanging Lantern"
  (instructables.com/How-to-Make-a-Homemade-Hanging-Lantern: a jar lantern lit at night, the
  bail's proportions); guides on cutoutandkeep.net and kippiathome.com (wrap the rim, twist the
  ends with pliers, hook the bail's loops through); IKEA's GLIMMA tea light page and tealight
  cup listings (kerzenkiste.de: 39 x 18 mm; voyageursoapandcandle.com: 37.5 x 20 mm). Sizes:
  a tea light is 38 mm across and 15 to 18 mm deep; a regular-mouth jar's thread is 70 mm
  across and its opening about 60 mm (masonjarlifestyle.com's size chart); a pint jar is
  about 5 inches tall and 3 across.
- **Choices:** a pint jar rather than a half-pint (4 inches), so it reads beside the
  night-light; wire of 2.8 mm, a touch bolder than the 1.3 to 1.6 mm the guides use, so the
  bail shows on a phone; no lid band, so the thread shows; the tea light used before, so the
  cup's wall shows above the wax and the jar has soot.
- **Size:** 5 inches tall, 3 across (0.5 studs tall, 0.3 across; 0.37 deep with the bail hung
  at the back).
- **Tells:** a clear jar with a candle in the bottom and a wire handle; lit, a warm flame
  low in a glowing jar.
- **Parts:** `TeaLight_Jar` (root: the jar's bottom middle on the floor; see-through),
  `_Candle` (the cup, wax and wick, at its spot on the floor), `_Wire` (the wrap, ears and
  twisted tail), `_Bail` (turns about X through both ears; built where it fell, 150 degrees
  back from upright), `_Flame` (on the candle; see-through and glowing; its pivot at the
  flame's foot, turning about Y so it sways side to side). 4,058 triangles (the jar 1,728,
  the wire 1,064); one 512 texture set at 375 texels a stud.
- **Glass:** the first see-through find (CRAFT.md, "Glass"). The jar and the flame are clear
  parts: their alpha rides in the colour map and their material links it, so they import in
  AlphaMode Transparency; in Studio set each to Transparency 0.02 and CastShadow off (or the
  glass blocks the candle's light where shadows are on). The walls are alpha 0.12 (two walls
  seen through), the base, bead, thread and rim up to 0.4 and greener, smudges 0.24, soot
  inside up to 0.62. Roblox draws alpha lighter than Cycles (docs/STUDIO.md): judge in Studio.
- **Light:** a Point in the flame (1,850 K, Brightness 0.9, Range 9, no shadows, so it shines
  out through the glass); the flame's emissive mask is faint in its blue foot and full above,
  strength 3, tint (255, 178, 98).
- **Motions:** found cold, the flame scaled to nothing (`scale` 0; the game hides it, a
  MeshPart can't be size 0). `Light` (1.3 s): the wick catches small, sinks as it melts its
  wax, the flame climbs too tall, wavers and settles. `Flicker` (2 s, played on a loop while it
  burns): the flame stretches, leans and its light breathes. `GoOut` (1.6 s): it gutters twice,
  shrinks and goes out. `Lift` (0.9 s): picked up by the bail, which swings up from where it
  lay, a touch past upright, and settles.
- **Not in the place yet:** upload and insert in F-S1. Unlit from a unit's doorway it's
  nearly invisible (clear glass, 5 inches, in a dim unit); lit it's a warm point. Judge with the
  night-light whether small finds need help to be seen.

## Bundle of glow sticks (Nov 15, F-02c)

- **What it is:** three green 6 inch lightsticks, the emergency kind, held with a tan rubber
  band that has gone powdery and cracked. Two lie on the floor side by side, the third rests
  in the groove on top; they're slid a little along each other and their hooks don't line up.
  Each is a clear tube of pale lime liquid with a glass ampoule floating in it and an air
  bubble along the top, a plug cap at the bottom a touch wider than the tube, and at the top
  the tube domed shut into a flat tab with a hole and an open moulded hook past it.
- **References** (looked at Nov 15): Glowlights' product photo of white 6 inch sticks with hooks
  (glowlights.com/cdn/shop/files/white-6-inch-glow-light-sticks-with-hook-gs6t.jpg: the plug
  cap's length and step, the tab with its hole, the C hook and its gap facing the tab, the
  proportions); Glowtopia's 6 inch premium listing (glowtopia.co.uk: 6 inches by 1.5 cm);
  Varusteleka's MFH light stick (150 by 15 mm); image results for lit and unlit green
  lightsticks (the lit colour, yellow-green and brightest in the liquid, the caps and hook
  dim; unlit, pale tinted liquid). Size: 150 to 152 mm long, 15 mm across.
- **Choices:** all three green, the classic emergency colour: a Roblox glow has one tint per
  find, so a mixed bundle couldn't light each stick its own colour. The ampoule floats a
  little above the tube's floor (a real one lies on it) so the bake doesn't catch the tube
  wall (it's inside the bake's reach of it).
- **Size:** 6 inches long (0.6 studs), the bundle 3 inches across and 1.5 tall.
- **Tells:** green tubes with white caps and hooks, banded together; cracked, one lights up
  bright green.
- **Parts:** `GlowSticks_Band` (root: the bundle's middle on the floor), `_Stick1` (the top
  stick's cap half), `_Stick1Tip` (its hook half; bends about its underside at the middle,
  axis -Y, so it kinks up), `_Stick2` (front) and `_Stick3` (back), whole. The sticks are
  see-through parts (the tube 0.42, the caps and hook 0.78, the ampoule 0.55). 2,962
  triangles; one 512 texture set at 590 texels a stud.
- **Light:** a Point in the top stick (green, (120, 255, 96): the kit's lights now take an
  `rgb` when the light isn't a hot filament; Brightness 0.7, Range 7, no shadows); the liquid
  and ampoule glow full, the caps a third, the hook a little; strength 2, tint the same green.
  Both halves of the top stick glow when it's cracked (`lit`).
- **Motions:** `Crack` (1.8 s): a grip, the top stick bent up against its stiff plastic until
  the ampoule snaps at 34 degrees and it gives, then let go: it drops onto the others, bounces
  twice, and the light comes up from the snap as the liquids mix.
- **For the game:** the action lights one stick; the top stick's two parts are the one to
  clone and set down. Not in the place yet: F-S1.

## String fairy lights (Nov 15, F-02c)

- **What it is:** a battery string of twenty warm-white micro LEDs on copper wire, wound into
  a loose ring for storage and dropped beside its box: a translucent 3 x AA box with a
  sliding battery lid, a black slide switch at its cable end, and three cells showing through
  it, two of one make (deep green, gold band) and one odd one (black, orange band). The wire
  is tarnished in places; each LED is a drop of clear resin with the yellow of its chip
  showing.
- **References** (looked at Nov 15): Lights4fun's 50 warm white micro fairy lights
  (lights4fun.co.uk: how a thin-wire string lies in loose loops); image results for battery
  fairy lights with a battery box (a translucent 3 x AA box with the batteries showing, the
  switch at the cable end, the wire leaving through a grommet; a white box with a round
  button; loose rings of copper string lit warm); listings for LED spacing (2.5 to 10 cm;
  Festive, Luminal Park, Quick Candles) and the box (3 x AA, clear or translucent). No listing
  gave the box's size: it's built round three AA cells (14.5 by 50.5 mm): 70 x 49 x 20 mm.
- **Choices:** the wire twice life (1.1 mm) and the LEDs bolder (5.5 by 3 mm) so they read on
  a phone; LEDs every 10 cm; the switch on top at the cable end, sliding towards it for on.
- **Size:** the ring about 6 inches across, the whole 9.5 by 6 inches (0.95 by 0.6 studs).
- **Tells:** a ring of copper wire dotted with beads, beside a little battery box; lit, a ring
  of warm points.
- **Parts:** `FairyLights_Box` (root: the middle of the whole on the floor; see-through, the
  cells and contacts inside), `_Switch` (slides along the box towards its cable end, 0.014
  studs), `_String` (the wire and its LEDs; the glow part). 4,124 triangles (the string about
  3,200: the wire is cut into short pieces so it packs); one 512 texture set at 485 texels a
  stud.
- **Light:** a Point over the ring's middle (2,900 K, Brightness 0.6, Range 9, no shadows);
  the LEDs glow, brightest at their chips; strength 2.5, tint (255, 184, 116).
- **Motions:** `SwitchOn` (0.7 s): the thumb pushes against the detent, the switch clicks
  over, and the LEDs come on at once, stutter once on a tired battery's contact, and hold.
  `SwitchOff` (0.5 s): clicked back, and they're out.
- **For the game:** "lay them along a hall" is a game ticket; the string's art is the coil.
  Laid out, the game can draw the line itself (a row of small glowing beads and Point lights)
  from these colours. Not in the place yet: F-S1.

## Camping lantern (Nov 15, F-02d)

- **What it is:** a retro LED camping lantern in olive powder coat: a bell-flared steel foot,
  a straight band with a knurled aluminium dimmer knob on a chrome bezel at the front (a
  charging port at the back), a black seat ring, a clear glass globe round a frosted white
  hourglass diffuser ringed with ribs, six black-green guard bars bowed a little outward, a
  black top ring, a wide flat hood pressed with twelve ribs and rolled at its rim, a knurled
  cap, and a chrome wire bail with a black rubber grip, hooked through two lugs on the hood.
  Chipped at the edges, faded on top, rust freckles round the foot, the bars worn to steel
  where hands grab them, smudges on the glass, dust on what faces up.
- **References** (looked at Nov 15): a product shot of a "Portable Retro LED Rotary Switch"
  lantern (media.takealot.com; the clearest: foot, band, knob, globe round an hourglass
  diffuser, hood, bail); Bing image results for "retro LED camping lantern green metal bail
  handle rotary dimmer" (the KUNDGLA and BAMWUAN retro lanterns on Amazon: olive green bodies,
  guard bars round the globe, flat ribbed hoods); olproshop.com's Retro Dimmable Lantern
  (sage green, rotary knob). Sizes from 3 x D cell lantern listings: 7 to 11 inches tall
  (Primus 8.3, Rayovac 7.25, Dorcy 7).
- **Choices:** the guard bars from the KUNDGLA and BAMWUAN lanterns (they make it read as a
  lantern at a glance); the knob off at seven o'clock, turning clockwise, a click on, then 230
  degrees of dimmer; no maker's mark.
- **Size:** 7.1 inches to the cap (4.4 across the hood), 9.1 to the bail's top when it's held
  up: 0.71 studs tall, 0.44 across.
- **Tells:** the wide hood over a glass globe with a glowing column inside it, on a flared
  foot; lit, a warm column and a wide pool on the floor.
- **Parts:** `CampLantern_Body` (root: the foot's middle on the floor; the foot, band, rings,
  bars, hood, lugs, cap and bezel), `_Globe` (see-through), `_Diffuser` (the glow part),
  `_Knob` (turns about Y from the band, positive clockwise seen from the front), `_Bail`
  (turns about X through the lugs; found fallen back 107 degrees, its arms on the hood's rim).
  8,084 triangles (the body 5,516); one 1024 texture set at 463 texels a stud.
- **Light:** a Point in the diffuser's middle (3,200 K, Brightness 1.2, Range 16, no shadows,
  so it shines out through the globe and the bars); the diffuser glows, its grooves a little
  dimmer; strength 3, tint (255, 200, 150).
- **Motions:** `SwitchOn` (1.5 s): the knob clicks on to a faint glow, then turns up and the
  light rises with it. `SwitchOff` (0.9 s): turned down, the light falls, and it clicks off.
  `RunDown` (2.4 s, the 90 seconds' end): it stutters, sags and dies. `Lift` (1 s): the bail
  swings up off the hood, a touch past upright, and settles.
- **For the game:** the 90 seconds and the wide light are a game ticket; the light's Range is
  the find's. Not in the place yet: F-S1.

## Moon lamp (Nov 15, F-02e)

- **What it is:** a 3D-printed moon in ivory PLA on a cradle of two M-shaped pieces of pale
  beech halved into each other. The Moon's own near side faces the front: its maria where the
  Moon has them (Imbrium, Serenitatis, Tranquillitatis, Crisium, Procellarum and the rest), a
  touch low and smooth; the highlands crowded with crisp craters with raised rims, fine pits
  between; Tycho and Copernicus with faint rays. A white plug in a flat cut at the bottom
  holds the touch dot and the USB port. Dust on top, the cradle's edges darkened by hands.
- **References** (looked at Nov 14 and 15): Bing image results for "3D printed moon lamp wooden
  stand", "moon lamp wooden stand only replacement cross cradle" and "3d printed moon lamp
  unlit close up craters white" (an Etsy listing's close-up: dense small craters, smooth grey
  maria); printed moon lamps run 8 to 20 cm, 15 cm the usual. The maria from the Moon's own
  map (their latitudes, longitudes and sizes in `spec.py`).
- **Size:** a 15 cm moon (5.9 inches) whose top stands 7.4 inches off the floor; the cradle's
  feet 4.8 inches across. 0.59 studs across the moon, 0.74 tall.
- **Tells:** a pale cratered ball on a little wooden cradle; lit, the Moon's face, grey maria
  on bright highlands, and a warm pool round its feet.
- **Parts:** `MoonLamp_Cradle` (root: the cradle's middle on the floor), `_Moon` (the glow
  part; pivot its middle, turning about Z), `_Shade` (see-through: the dark phase cap just
  outside the moon, turning about Z with it; found at `scale` 0, on at 1, full moon to start).
  3,700 triangles (the moon 2,496); one 1024 texture set at 554 texels a stud.
- **How it's made:** the detailed moon is a 720 x 320 lathe; numpy pushes in 1,300 craters
  (a power law of sizes, few on the maria) and the maria, and writes `maria` and `ray` on each
  point, which the look reads (`mn_attr`) so the colour and the glow follow the same face.
- **Light:** a Point in the moon's middle (3,000 K, Brightness 0.8, Range 10, no shadows); the
  moon glows, its maria at 0.3 of the highlands; strength 1.6, tint (255, 214, 170).
- **Motions:** `SwitchOn` (1 s): the light swells through the print, a touch too bright, and
  settles. `SwitchOff` (0.7 s). `Phase` (0.9 s, per tap): the shade turns 45 degrees about the
  moon, overshooting a little, as the light blinks; the game adds the phase it was on.
- **For the game:** tapping through the phases is a game ticket. Not in the place yet: F-S1.

## Blob lamp (Nov 15, F-02f)

- **What it is:** the classic wax-in-a-bottle motion lamp: a spun aluminium base (a cone
  narrowing to a waist, then flaring to the collar the bottle stands in), a tapering glass
  bottle of violet liquid with red-orange wax lying in its bottom, a spun cap. The cord leaves
  the back of the foot through a rubber sleeve and runs over the floor through an inline
  rocker switch to a two-pin plug. The aluminium is satin with fine spinning rings, scuffed
  dull in patches with a few dings; fingermarks on the glass; a faint tide mark over the
  liquid where it has stood for years.
- **References** (looked at Nov 15): Wikimedia Commons, "Category:Lava lamps" ("1990s Mathmos
  Astro.jpg", "Lava lamp operating.jpg", "Lavalamp red.jpg"), for the shapes, the colours and
  how the wax looks lit; the motion timed off Commons' "Lava lamp (oT) 01 ies.ogv" (below).
  The classic lamp is 14.5 inches tall, its base about 4.3 inches across.
- **Size:** 14.5 inches tall: 1.45 studs, the base 0.43 studs across.
- **Tells:** the rocket shape (a cone base, a tapering bottle, a pointed cap); lit, coloured
  blobs climbing and falling in glowing violet.
- **Parts:** `BlobLamp_Base` (root: the base, sleeve, cord, switch and plug), `_Rocker` (the
  switch's rocker, turning on its pin), `_Bottle` (see-through: the glass and the liquid in
  one shell, the glow part), `_Cap`, `_Pool` (the wax on the bottle's floor), `_Mound` (the
  hump blobs leave from and land on), `_Neck` (the strand a rising tower draws up) and
  `_Blob1` to `_Blob4`. Each wax part is baked alone, so none is greyed by another's shadow.
  9,652 triangles; one 1024 texture set at 449 texels a stud.
- **How the wax moves:** measured off the video, pixel rows a second: a tower climbs about a
  sixteenth of the bottle a second, slowing near the top; its neck snaps about 16 s in (the
  neck thins as it stretches, keeping its volume); a blob hangs about 6 s, then sinks, faster
  at the end; a sinking blob can tear, its top floating back up. `BL_PLAN` holds each blob's
  keys; `bl_flow()` joins them with a curve that never overshoots and thins them to straight
  runs; `bl_check` prints any blob touching another or the glass.
- **Light:** a Point low in the bottle, under the wax where the bulb is (pink-violet
  (255, 120, 178), Brightness 0.8, Range 10, no shadows; any higher burns the pool white); the liquid glows faintly (0.35 low to 0.15 high), the wax more, its
  glow kept low so lit wax stays a saturated orange-red rather than washing to peach; strength
  2.0, tint (255, 214, 196).
- **Motions:** `SwitchOn` (2.2 s): the rocker clicks, the liquid lights at once, the wax warms
  into colour a beat behind and the pool stirs. `Flow` (48 s, played on a loop; the previews
  at 8 frames a second): two towers climb and snap, one blob tears on the way down, the drops
  left by the snaps fall back in. `SwitchOff` (1.4 s): the light goes, the wax's glow a breath
  after; the blobs stay where they were (the game stops `Flow` there).
- **For the game:** placing it at home and switching it is a game ticket. Not in the place
  yet: F-S1.

## Oil lamp (Nov 15, F-02g)

- **What it is:** a clear pressed-glass pedestal paraffin lamp: a domed foot with a hollow
  under it, a stem with a knop, an onion fount with sixteen pressed panels round its lower
  half and the mould's two seams; a brass collar and a #2 flat-wick burner (a band of twenty
  air holes, a gallery with four prongs holding the chimney, a slotted dome over the wick, a
  knurled thumbwheel on a steel spindle out the right side); a 10 inch blown-glass chimney
  with a fire-polished bead. Old amber paraffin a little over half fills the fount, the flat
  cotton wick hanging into it, soaked from the oil up. Found used: brass tarnished brown in
  patches, soot inside the chimney over the bulge, a tide mark where the oil stood higher,
  fingermarks on the chimney's bulge, dust on its rim and the fount's shoulders.
- **Fragile, so chipped where a chip shows:** a flake off the foot's top edge, front left;
  a chip out of the chimney's rim, front right (`ol_chip` bends the glass in, the look
  frosts the fresh break).
- **References** (looked at Nov 15): Wikimedia Commons "Kerosene lamp CZ modern.jpg" (a clear
  modern lamp lit: the chimney's proportions, the wick visible in the fount, the flame's
  size), "Burner on a kerosene lamp.jpg" (the collar, the pierced air band, the crown and the
  thumbwheel on its long spindle), "Oil Lamp POL-104GR (Poland).jpg" (the burner and the bulge
  chimney on a small fount); sizes from the hardware listings in WAVES.md's F-02f note
  (a #2 chimney: 3 in fitter, 4 in bulge, 2 in top, 10 in tall; Queen Anne #2 burner, 1 in wick).
- **Size:** 20 inches tall (9.5 to the collar, the chimney 10), the foot 6 inches across:
  2.0 studs tall, 0.6 across the foot.
- **Tells:** the tall clear chimney with its bulge over a brass burner, a glass fount of amber
  oil on a foot; lit, a broad yellow flame inside the chimney and the oil glowing.
- **Parts:** `OilLamp_Fount` (root, see-through: the glass, the oil and the wick in one shell;
  the foot's middle on the floor), `_Burner` (the brass and the spindle), `_Wheel` (turning
  about X on the spindle), `_Chimney` (see-through, sliding up its Z to be lifted), `_Flame`
  (see-through, the glow part; pivot at the slot, leaning about Y; found at `scale` 0).
  11,936 triangles; one 1024 texture set at 354 texels a stud.
- **Light:** a Point at the flame (1,900 K, Brightness 0.7, Range 10 (1.4 and 16 lit a whole unit brighter than its bulb in Studio, F-S1), no shadows, so it shines
  out through the glass); strength 3, tint (255, 176, 92).
- **Motions:** `Light` (2.6 s): lit the way a real one is: the chimney lifted off its prongs,
  a flame caught low and lazy, the chimney set back with a small ring of glass on brass, its
  draught pulling the flame up tall, then the wheel winds the wick up to a good flame.
  `Burn` (2.4 s, a loop): under a chimney the flame only breathes. `RunDown` (4 s): the oil
  gone, the flame sinks, gutters twice and goes out. Lit, the wheel stands at 110 degrees.
- **For the game:** "Light: warm light that runs down slowly" is a game ticket: the game holds
  `Burn`, dims the light over the run and plays `RunDown` at the end. Not in the place yet: F-S1.

## Disco ball (Nov 15, F-02h)

- **What it is:** an 8 inch mirror ball sitting in the cup of a tabletop battery motor (a
  black dome on a wide hat-brim skirt, an upright band round its foot with a slide switch at
  the front and a DC jack at the back, a battery door and three rubber feet underneath). The
  ball is 1,100 or so 10 mm glass mirror tiles laid by hand in 29 rows on a foam sphere, each a
  degree or so off true (that is what makes a mirror ball sparkle), with grey grout between;
  a hanging plate and ring at its top pole (the ball hangs as well as sits). Found in storage:
  a little patch of tiles knocked off low on the front left and a few singles gone (bare foam,
  old glue), one tile in twenty dark at the back where the silvering has rotted, fingermarks
  round its middle, dust greying its top.
- **References** (looked at Nov 15): Wikimedia Commons, the search "mirror ball disco"
  (https://commons.wikimedia.org/wiki/File:Mirror_Ball_(47361192).jpeg, from below: the tiles
  in rings, fewer to a ring toward the pole; a ball on a ceiling, whole; a blue-lit ball with
  its spots on the walls); the ADJ tabletop mirror ball motor (M-DCBASE) on
  https://shop.solotech.com/products/adj-american-dj-table-top-mirror-ball-motor (the
  dome-on-cone base; 5 RPM, one D cell, for balls up to 8 in; 7 x 7 x 3.8 in from the
  goknight.com listing). Tile size (10 mm) from mirror ball listings in general, not measured.
- **Size:** the ball 8 in across, the base 7 in across, 12 in tall in all: 0.8 studs across the
  ball, 1.18 studs tall.
- **Tells:** a silver ball of little square mirrors on a black stand; on, white dots sweeping
  the walls and a scatter of tiles flashing.
- **Parts:** `DiscoBall_Base` (root: the base and feet), `_Ball` (the ball, its cup and shaft,
  the plate and ring; turning about Z on the motor's shaft; the glow part), `_Switch` (sliding
  along X). 4,728 triangles; one 1024 texture set at 443 texels a stud.
- **Lights:** six narrow white Spots on the ball (6,500 K, Brightness 1.2, Range 14, Angle 4,
  no shadows), evenly round, each at its own height (4 to 38 degrees up), so they turn with it
  and sweep the walls in bands; a weak Point at its middle (0.25, Range 6) for low graphics.
  The glow: one tile in twenty flashes (strength 2, a cool white). There is no pinspot: a
  real mirror ball needs a light on it; this one makes its own (a game's licence, noted in
  WAVES.md). Spot lights drew nothing in Studio's Edit captures, so the dots on the walls
  are unjudged in Roblox (WAVES.md, F-02h).
- **Motions:** `Spin` (2.4 s): the slide clicks over, the spots come on, the ball takes a second
  to come up to five turns a minute. `Spinning` (12 s, a loop from where `Spin` ends: one
  turn). `SpinDown` (1.2 s): slid off, the motor stops, the ball's weight carries it 5 degrees
  on in its cup and it rocks back a touch. Its turn keys start where `Spin` ends: the game
  adds where the ball stood.
- **For the game:** "Spin: spots of light race round the walls" is a game ticket: it plays
  `Spin`, loops `Spinning` and plays `SpinDown` from the ball's angle.

## Neon OPEN sign (Nov 15, F-02i)

- **What it is:** a real-glass shop sign: OPEN in pink, tall and narrow, inside an aqua border
  with rounded corners, both bent from 10 mm tube, standing an inch off a black acrylic backing
  on fourteen clear posts. Each tube's two ends bend back through the backing, painted black
  there (the blockout, flaking at the bend) and sheathed in black rubber boots; the E's middle
  bar is its own short tube, as on real signs. Behind: the transformer in a black crinkle-paint
  box with a toggle switch on top, its cord out the left end to a two-pin plug on the floor;
  two hanging eyes on the top edge. Found in storage: hairline scratches and scuffs on the
  acrylic, rust at the box's corners, the pink faded paler on the tubes' tops, dust on top.
- **References** (looked at Nov 15): Arter's NS12113-AP "Open" sign, aqua and pink
  (https://restaurantequipment.com/products/neon-sign-open-red-blue-border-10x24-each: the
  letters, the border, the black backing; 10 x 24 x 3 in, real glass, a UL transformer and
  6 ft cord); Wikimedia Commons, the search "neon open sign" (a red OPEN with a blue border
  in a shop window: the tubes standing off the backing, the posts, the ends going back); how
  the tube's ends, blockout and boots are made from neon practice in general.
- **Size:** 24 x 10 in, 3 in deep with the box: 2.4 by 1.0 studs, 0.27 deep.
- **Tells:** the word OPEN in glowing pink tube inside a blue-green frame on black; off, the
  same in pale coloured glass.
- **Parts:** `NeonSign_Backing` (root: the acrylic, posts, boots, box, cord, plug and eyes; it
  stands on its bottom edge), `_Tubes` (every tube, the glow part), `_Toggle` (the switch's
  bat handle on the box's top, turning about X). 6,328 triangles; one 1024 texture set at 326 texels
  a stud (each tube is packed in runs of a stud or less: the border in one strip shrank the
  texture to 195).
- **Light:** a pink Point a few inches in front (255, 92, 182; Brightness 0.6, Range 10, no
  shadows); the glow: strength 2.5, untinted (the tubes' own pink and aqua).
- **Motions:** `SwitchOn` (1.4 s): the toggle snaps over and the tubes strike, a stutter of
  half-lit flashes as the gas catches, then the full glow, a last dip, steady. `Buzz` (2 s, a
  loop, with the buzz's sound): the glow only shivers. `SwitchOff` (0.7 s): the glow drops at
  the click, the pink's coating fading a breath after.
- **For the game:** "At home: it buzzes and glows pink" is a game ticket: `SwitchOn`, then
  `Buzz` on a loop with a mains hum, `SwitchOff`.
