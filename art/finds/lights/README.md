# Lights

The catalog's Lights (art/finds/WAVES.md), built with the finds kit (art/finds/CRAFT.md, "The
kit"). `scripts/art.sh set lights` rebuilds them; sheets in `art/sheets/<find>-*.png`, motion
clips in `out/`.

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
